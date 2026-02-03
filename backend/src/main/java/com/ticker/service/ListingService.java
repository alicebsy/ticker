package com.ticker.service;

import com.ticker.dto.ListingRequest;
import com.ticker.dto.ListingResponse;
import com.ticker.model.*;
import com.ticker.repository.StockPriceHistoryRepository;
import com.ticker.repository.TodoRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
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

        // 기간별 주가 차트 (1D, 7D, 1M)
        LocalDate fromDate = getFromDateByPeriod(period);
        List<StockPriceHistory> history = stockPriceHistoryRepository
                .findByUserIdAndRecordDateAfterOrderByRecordDateAsc(userId, fromDate);

        List<ListingResponse.ChartPointDto> chartData = history.stream()
                .map(h -> new ListingResponse.ChartPointDto(
                        h.getRecordDate().toString(),
                        h.getPrice()
                ))
                .collect(Collectors.toList());

        // 차트 데이터가 없으면 현재 주가로 1점
        if (chartData.isEmpty()) {
            chartData.add(new ListingResponse.ChartPointDto(
                    LocalDate.now().toString(),
                    user.getStockPrice()
            ));
        }

        String changePercent = user.getConsecutiveUpDays() > 0
                ? String.format("+%.2f%%", 3.85)
                : "— 0.00%";
        String status = user.getConsecutiveUpDays() > 0
                ? "연속 " + user.getConsecutiveUpDays() + "일 상승"
                : "";

        ListingResponse.StockChartDto chartDto = new ListingResponse.StockChartDto(
                user.getStockPrice(),
                changePercent,
                status,
                chartData
        );

        // 상장 중인 종목
        List<Todo> todos = todoRepository.findByOwnerIdAndStatusOrderByCreatedAtDesc(userId, TodoStatus.LISTED);
        List<ListingResponse.ListedTodoDto> todoDtos = todos.stream()
                .map(t -> new ListingResponse.ListedTodoDto(
                        t.getId(),
                        t.getName(),
                        t.getDeadline().toString(),
                        t.getRewardPoints(),
                        t.getProgress()
                ))
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
        todoRepository.save(todo);

        // 완료 체크 시 그래프·목록 실시간 반영 (다른 사람들 화면에도 바로 반영)
        notificationService.sendListingUpdate(todo.getOwner().getId(), todoId, 100, true);
        // 해당 할 일에 걸린 베팅 정산 (성공 예측 → 적중 시 배당 지급)
        casinoService.settleBetsForTodo(todoId, true);
    }

    private LocalDate getFromDateByPeriod(String period) {
        LocalDate now = LocalDate.now();
        return switch (period != null ? period.toUpperCase() : "7D") {
            case "1D" -> now.minusDays(1);
            case "1M" -> now.minusMonths(1);
            default -> now.minusDays(7);  // 7D
        };
    }
}
