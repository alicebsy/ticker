package com.ticker.service;

import com.ticker.dto.ListingRequest;
import com.ticker.dto.ListingResponse;
import com.ticker.model.*;
import com.ticker.repository.StockPriceHistoryRepository;
import com.ticker.repository.TodoRepository;
import com.ticker.repository.UserRepository;
import com.ticker.repository.InvestmentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 상장(Listing) 서비스
 * 신규 상장(할 일 등록), 내 주가 차트, 상장 중인 종목 조회
 */
@Service
@RequiredArgsConstructor
public class ListingService {

    private final TodoRepository todoRepository;
    private final UserRepository userRepository;
    private final StockPriceHistoryRepository stockPriceHistoryRepository;
    private final NotificationService notificationService;
    private final ActivityService activityService;
    private final CasinoService casinoService;

    /**
     * 신규 상장 - 할 일 등록
     * 내 몸값 비례형: 공모가 = 기본 난이도 점수 × (내 주가 / 100)
     * - 신용 불량(주가 50원) → 저평가
     * - 성실한 유저(주가 200원) → 프리미엄
     */
    @Transactional
    public Todo createTodo(Long userId, ListingRequest request) {
        User owner = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));

        Difficulty difficulty = request.getDifficulty() != null ? request.getDifficulty() : Difficulty.NORMAL;
        // 공모가: 명시된 값이 있으면 사용, 없으면 난이도 × (내 주가/100) 적용
        long ipoPrice = request.getRewardPoints() != null
                ? request.getRewardPoints()
                : difficulty.calculateIpoPrice(owner.getStockPrice());

        Todo todo = Todo.builder()
                .owner(owner)
                .name(request.getName())
                .deadline(request.getDeadline())
                .rewardPoints(ipoPrice)
                .difficulty(difficulty)
                .visibility(request.getVisibility() != null ? request.getVisibility() : Visibility.FRIENDS_ONLY)
                .progress(0)
                .currentPrice(ipoPrice)
                .status(TodoStatus.LISTED)
                .build();

        Todo saved = todoRepository.save(todo);
        notificationService.sendListingUpdate(owner.getId(), saved.getId(), 0, false);
        activityService.addActivity(userId, "LISTING", "오늘의 투두 상장", 0L);
        return saved;
    }

    /**
     * 상장 화면 데이터 조회 (차트 + 상장 중 종목)
     */
    @Transactional(readOnly = true)
    public ListingResponse getListing(Long userId, String period) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));

        // 주가 차트: 회원가입일부터 전체 이력
        LocalDate fromDate = user.getCreatedAt().toLocalDate();
        LocalDate today = LocalDate.now();
        List<StockPriceHistory> history = stockPriceHistoryRepository
                .findByUserIdAndRecordDateAfterOrderByRecordDateAsc(userId, fromDate);

        List<ListingResponse.ChartPointDto> chartData = new java.util.ArrayList<>();

        // 첫 포인트: 회원가입일의 초기 주가 (1,000원)
        boolean hasRegistrationDate = history.stream()
                .anyMatch(h -> h.getRecordDate().equals(fromDate));
        if (!hasRegistrationDate) {
            chartData.add(new ListingResponse.ChartPointDto(
                    fromDate.toString(),
                    1000L));
        }

        // 기존 이력 추가
        history.forEach(h -> chartData.add(new ListingResponse.ChartPointDto(
                h.getRecordDate().toString(),
                h.getPrice())));

        // 오늘 포인트: 현재 주가 (완성률 반영된 예상 주가)
        // 오늘 가입한 유저의 경우 시작점(1000원)과 현재점을 모두 보여주기 위해
        // 같은 날짜라도 별도 포인트로 추가 (시작가 vs 현재가)
        if (fromDate.equals(today)) {
            // 오늘 가입: 첫 포인트(1000원)는 이미 추가됨, 현재가가 다르면 추가 포인트
            if (user.getStockPrice() != 1000L) {
                chartData.add(new ListingResponse.ChartPointDto(
                        today.toString(),
                        user.getStockPrice()));
            }
        } else {
            // 이전에 가입한 유저: 오늘 포인트가 없으면 추가, 있으면 업데이트
            boolean hasTodayPoint = chartData.stream()
                    .anyMatch(p -> p.getDate().equals(today.toString()));
            if (!hasTodayPoint) {
                chartData.add(new ListingResponse.ChartPointDto(
                        today.toString(),
                        user.getStockPrice()));
            } else {
                chartData.stream()
                        .filter(p -> p.getDate().equals(today.toString()))
                        .findFirst()
                        .ifPresent(p -> p.setPrice(user.getStockPrice()));
            }
        }

        // 오늘 투두 완성률 기반 예상 주가 변동폭 계산
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().plusDays(1).atStartOfDay();
        List<Todo> todayTodos = todoRepository.findByOwnerIdAndCreatedAtToday(userId, startOfDay, endOfDay);

        String changePercent;
        if (!todayTodos.isEmpty()) {
            long completedCount = todayTodos.stream()
                    .filter(t -> t.getStatus() == TodoStatus.COMPLETED)
                    .count();
            double ratio = (double) completedCount / todayTodos.size();
            double changePct;
            if (ratio >= 1.0) {
                changePct = 12.5; // +10~15% 중간값
            } else if (ratio >= 0.75) {
                changePct = 5.0;
            } else if (ratio >= 0.50) {
                changePct = 0.0;
            } else if (ratio >= 0.25) {
                changePct = -10.0;
            } else {
                changePct = -20.0;
            }
            changePercent = String.format("%+.2f%%", changePct);
        } else {
            changePercent = "— 0.00%";
        }

        String status = user.getConsecutiveUpDays() > 0
                ? "연속 " + user.getConsecutiveUpDays() + "일 상승"
                : "";

        ListingResponse.StockChartDto chartDto = new ListingResponse.StockChartDto(
                user.getStockPrice(),
                changePercent,
                status,
                chartData);

        // 오늘의 투두 전체 (LISTED + COMPLETED 모두 포함) - 위에서 이미 조회한 todayTodos 재사용
        List<ListingResponse.ListedTodoDto> todoDtos = todayTodos.stream()
                .map(t -> new ListingResponse.ListedTodoDto(
                        t.getId(),
                        t.getName(),
                        t.getDeadline().toString(),
                        t.getRewardPoints(),
                        t.getProgress(),
                        t.getStatus() == TodoStatus.COMPLETED))
                .collect(Collectors.toList());

        return ListingResponse.builder()
                .myStockChart(chartDto)
                .listedTodos(todoDtos)
                .build();
    }

    /**
     * 할 일 진행률 업데이트 (매도 완료 시)
     */
    @Transactional
    public void updateProgress(Long todoId, Integer progress) {
        Todo todo = todoRepository.findById(todoId)
                .orElseThrow(() -> new IllegalArgumentException("할 일을 찾을 수 없습니다: " + todoId));
        int newProgress = Math.min(100, Math.max(0, progress));
        todo.setProgress(newProgress);
        todoRepository.save(todo);

        // 진행률 변경 시 실시간 반영 (그래프·목록 갱신용)
        notificationService.sendListingUpdate(todo.getOwner().getId(), todoId, newProgress, false);
    }

    /**
     * 할 일 완료 (매도/완료) - 상장 폐지
     */
    @Transactional
    public void completeTodo(Long todoId, Long userId) {
        Todo todo = todoRepository.findById(todoId)
                .orElseThrow(() -> new IllegalArgumentException("할 일을 찾을 수 없습니다: " + todoId));
        if (!todo.getOwner().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 할 일만 완료할 수 있습니다");
        }
        todo.setStatus(TodoStatus.COMPLETED);
        todo.setProgress(100);
        todo.setCompletedAt(LocalDateTime.now());
        todoRepository.save(todo);

        // 완료 체크 시 그래프·목록 실시간 반영 (다른 사람들 화면에도 바로 반영)
        notificationService.sendListingUpdate(todo.getOwner().getId(), todoId, 100, true);
        // 해당 할 일에 걸린 베팅 정산 (성공 예측 → 적중 시 배당 지급)
        casinoService.settleBetsForTodo(todoId, true);

        // 완료 시 예상 주가를 즉시 반영
        updateProjectedStockPrice(userId);
    }

    /**
     * 할 일 완료 취소 - 다시 상장 중으로 복원
     */
    @Transactional
    public void uncompleteTodo(Long todoId, Long userId) {
        Todo todo = todoRepository.findById(todoId)
                .orElseThrow(() -> new IllegalArgumentException("할 일을 찾을 수 없습니다: " + todoId));
        if (!todo.getOwner().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 할 일만 수정할 수 있습니다");
        }
        todo.setStatus(TodoStatus.LISTED);
        todo.setProgress(0);
        todo.setCompletedAt(null);
        todoRepository.save(todo);

        notificationService.sendListingUpdate(todo.getOwner().getId(), todoId, 0, false);

        // 취소 시 예상 주가를 즉시 반영
        updateProjectedStockPrice(userId);
    }

    /**
     * 오늘 완성률 기반 예상 주가를 계산하여 즉시 반영 (차트 실시간 업데이트용)
     */
    private final InvestmentRepository investmentRepository;

    private void updateProjectedStockPrice(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        LocalDateTime endOfDay = LocalDate.now().plusDays(1).atStartOfDay();
        List<Todo> todayTodos = todoRepository.findByOwnerIdAndCreatedAtToday(userId, startOfDay, endOfDay);

        if (todayTodos.isEmpty())
            return;

        long completedCount = todayTodos.stream()
                .filter(t -> t.getStatus() == TodoStatus.COMPLETED)
                .count();
        double ratio = (double) completedCount / todayTodos.size();

        // 기준 주가: 어제까지의 가장 최근 기록, 없으면 초기 주가 1000원
        LocalDate today = LocalDate.now();
        List<StockPriceHistory> histories = stockPriceHistoryRepository
                .findByUserIdAndRecordDateAfterOrderByRecordDateAsc(userId, today.minusDays(30));
        // 오늘 이전의 가장 마지막 기록을 기준가로 사용
        long basePrice = 1000L; // 초기 주가 (이전 기록 없을 때 기본값)
        for (StockPriceHistory h : histories) {
            if (h.getRecordDate().isBefore(today)) {
                basePrice = h.getPrice();
            }
        }

        double changePct;
        if (ratio >= 1.0) {
            changePct = 12.5; // 10~15% 중간값
        } else if (ratio >= 0.75) {
            changePct = 5.0;
        } else if (ratio >= 0.50) {
            changePct = 0.0;
        } else if (ratio >= 0.25) {
            changePct = -10.0;
        } else {
            changePct = -20.0;
        }

        long projectedPrice = Math.max(1, (long) (basePrice * (1 + changePct / 100.0)));
        user.setStockPrice(projectedPrice);

        // 시가총액 = 주가 * 100 (발행 주식 수)
        long marketCap = projectedPrice * 100;
        user.setMarketCap(marketCap);

        // 총 자산 = 현금 + (주가 * 70 (창업자 지분)) + 투자 평가액
        List<Investment> investments = investmentRepository.findByInvestorIdWithSubjectUser(userId);
        long investingAmount = investments.stream()
                .mapToLong(i -> (long) i.getQuantity() * i.getSubjectUser().getStockPrice())
                .sum();

        user.setTotalAssets(user.getCashBalance() + (projectedPrice * 70) + investingAmount);

        userRepository.save(user);

        // 실시간 주가 변동 알림
        notificationService.sendStockPriceUpdate(user);
    }

    private LocalDate getFromDateByPeriod(String period) {
        LocalDate now = LocalDate.now();
        return switch (period != null ? period.toUpperCase() : "7D") {
            case "1D" -> now.minusDays(1);
            case "1M" -> now.minusMonths(1);
            default -> now.minusDays(7); // 7D
        };
    }
}
