package com.ticker.service;

import com.ticker.model.StockPriceHistory;
import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import com.ticker.model.User;
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
import java.util.concurrent.ThreadLocalRandom;

/**
 * 한 사람 단위 주가 변동
 * 아침 10시 장 열림 → 오늘 투두 4개 이상 작성 시, 성공률(완료/총개수)에 따라 주가 변동
 * - 100%: +10~15%, 75~99%: +5%, 50~74%: 0%, 25~49%: -10%, 0~24%: -20%
 * 시가총액(내 가치) = 주가 × 100주, 총 자산 = 보유 자산 + 내 가치
 */
@Service
@RequiredArgsConstructor
public class StockPriceUpdateService {

    private static final int MIN_TODOS_FOR_UPDATE = 4;
    private static final int TOTAL_SHARES = 100;

    private final UserRepository userRepository;
    private final TodoRepository todoRepository;
    private final StockPriceHistoryRepository stockPriceHistoryRepository;
    private final NotificationService notificationService;

    /**
     * 모든 유저에 대해 오늘의 성공률을 반영해 주가 갱신.
     * (스케줄러로 10시에 호출하거나, 수동 API로 호출)
     */
    @Transactional
    public void updateDailyStockPrices() {
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();

        List<User> users = userRepository.findAll();
        for (User user : users) {
            List<Todo> todayTodos = todoRepository.findByOwnerIdAndCreatedAtToday(user.getId(), startOfDay, endOfDay);
            double changePercent = computeChangePercent(todayTodos);
            applyStockPriceChange(user, changePercent, today);
        }
    }

    /**
     * 단일 유저에 대해 오늘 성공률 반영 (테스트/수동 반영용)
     */
    @Transactional
    public void updateStockPriceForUser(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        LocalDate today = LocalDate.now();
        LocalDateTime startOfDay = today.atStartOfDay();
        LocalDateTime endOfDay = today.plusDays(1).atStartOfDay();
        List<Todo> todayTodos = todoRepository.findByOwnerIdAndCreatedAtToday(userId, startOfDay, endOfDay);
        double changePercent = computeChangePercent(todayTodos);
        applyStockPriceChange(user, changePercent, today);
    }

    private double computeChangePercent(List<Todo> todayTodos) {
        if (todayTodos == null || todayTodos.size() < MIN_TODOS_FOR_UPDATE) {
            return 0.0; // 4개 미만이면 변동 없음
        }
        long completed = todayTodos.stream()
                .filter(t -> t.getStatus() == TodoStatus.COMPLETED
                        || (t.getProgress() != null && t.getProgress() >= 100))
                .count();
        double ratio = (double) completed / todayTodos.size();
        double pct;
        if (ratio >= 1.0) {
            pct = 10.0 + ThreadLocalRandom.current().nextDouble(0, 5.0); // 10~15%
        } else if (ratio >= 0.75) {
            pct = 5.0;
        } else if (ratio >= 0.50) {
            pct = 0.0;
        } else if (ratio >= 0.25) {
            pct = -10.0;
        } else {
            pct = -20.0;
        }
        return pct;
    }

    private final InvestmentRepository investmentRepository;

    private void applyStockPriceChange(User user, double changePercent, LocalDate recordDate) {
        long oldPrice = user.getStockPrice();
        long newPrice = Math.max(1, (long) (oldPrice * (1 + changePercent / 100.0)));
        user.setStockPrice(newPrice);

        // 시가총액 = 주가 * 100
        long marketCap = newPrice * TOTAL_SHARES;
        user.setMarketCap(marketCap);

        // 총 자산 = 현금 + (주가 * 70) + 투자 평가액
        List<com.ticker.model.Investment> investments = investmentRepository
                .findByInvestorIdWithSubjectUser(user.getId());
        long investingAmount = investments.stream()
                .mapToLong(i -> (long) i.getQuantity() * i.getSubjectUser().getStockPrice())
                .sum();

        user.setTotalAssets(user.getCashBalance() + (newPrice * 70) + investingAmount);

        userRepository.save(user);

        StockPriceHistory history = StockPriceHistory.builder()
                .user(user)
                .price(newPrice)
                .recordDate(recordDate)
                .build();
        stockPriceHistoryRepository.save(history);

        // 주가 변동 시 다른 사람들에게 실시간 반영 (구독: /topic/stock/{userId})
        notificationService.sendStockPriceUpdate(user);
    }
}
