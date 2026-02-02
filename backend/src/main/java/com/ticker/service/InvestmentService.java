package com.ticker.service;

import com.ticker.dto.HeldStocksResponse;
import com.ticker.dto.InvestRequest;
import com.ticker.model.Investment;
import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import com.ticker.model.User;
import com.ticker.repository.InvestmentRepository;
import com.ticker.repository.TodoRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 투자 서비스
 * 매수/매도, 보유 종목 조회
 */
@Service
@RequiredArgsConstructor
public class InvestmentService {

    private final InvestmentRepository investmentRepository;
    private final TodoRepository todoRepository;
    private final UserRepository userRepository;

    /**
     * 보유 종목 목록 및 요약 조회
     */
    @Transactional(readOnly = true)
    public HeldStocksResponse getHeldStocks(Long userId) {
        List<Investment> investments = investmentRepository.findByInvestorIdWithTodoAndOwner(userId);

        long totalValuation = 0;
        long totalPurchase = 0;

        List<HeldStocksResponse.HeldStockDto> dtos = investments.stream()
                .map(inv -> {
                    Todo todo = inv.getTodo();
                    User owner = todo.getOwner();
                    long valuation = inv.getQuantity() * todo.getCurrentPrice();
                    long purchase = inv.getQuantity() * inv.getPurchasePrice();
                    long profitLoss = valuation - purchase;
                    double profitLossPct = purchase > 0 ? (profitLoss * 100.0 / purchase) : 0;

                    String priceChange = todo.getDailyChangePercent() != null
                            ? String.format("%+.2f%%", todo.getDailyChangePercent())
                            : "— 0.00%";

                    return new HeldStocksResponse.HeldStockDto(
                            inv.getId(),
                            owner.getName(),
                            owner.getProfileImageUrl(),
                            todo.getCurrentPrice(),
                            priceChange,
                            profitLoss,
                            String.format("(%+.2f%%)", profitLossPct),
                            inv.getQuantity(),
                            0  // 보유 비중은 아래에서 재계산
                    );
                })
                .collect(Collectors.toList());

        totalValuation = dtos.stream()
                .mapToLong(d -> d.getCurrentPrice() * d.getQuantity())
                .sum();
        totalPurchase = investments.stream()
                .mapToLong(i -> i.getQuantity() * i.getPurchasePrice())
                .sum();

        long finalTotalValuation = totalValuation;
        dtos.forEach(d -> {
            int ratio = finalTotalValuation > 0
                    ? (int) ((d.getCurrentPrice() * d.getQuantity() * 100) / finalTotalValuation)
                    : 0;
            d.setHoldingRatio(ratio);
        });

        long totalProfitLoss = totalValuation - totalPurchase;
        double returnRate = totalPurchase > 0 ? (totalProfitLoss * 100.0 / totalPurchase) : 0;

        return HeldStocksResponse.builder()
                .totalValuation(totalValuation)
                .totalPurchaseAmount(totalPurchase)
                .totalProfitLoss(totalProfitLoss)
                .totalReturnRate(String.format("%+.2f%%", returnRate))
                .stocks(dtos)
                .build();
    }

    /**
     * 매수
     */
    @Transactional
    public Investment buy(Long userId, InvestRequest request) {
        User investor = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));

        Todo todo = todoRepository.findById(request.getTodoId())
                .orElseThrow(() -> new IllegalArgumentException("종목을 찾을 수 없습니다: " + request.getTodoId()));

        if (todo.getStatus() != TodoStatus.LISTED) {
            throw new IllegalArgumentException("상장 중인 종목만 매수할 수 있습니다");
        }

        int quantity = request.getQuantity() != null ? request.getQuantity() : 1;
        long cost = quantity * todo.getCurrentPrice();

        if (investor.getCashBalance() < cost) {
            throw new IllegalArgumentException("잔액이 부족합니다");
        }

        Optional<Investment> existing = investmentRepository.findByInvestorIdAndTodoId(userId, todo.getId());
        Investment investment;

        if (existing.isPresent()) {
            investment = existing.get();
            int oldQty = investment.getQuantity();
            long oldCost = oldQty * investment.getPurchasePrice();
            int newQty = oldQty + quantity;
            long newCost = oldCost + cost;
            investment.setQuantity(newQty);
            investment.setPurchasePrice(newCost / newQty);  // 평균 단가
        } else {
            investment = Investment.builder()
                    .investor(investor)
                    .todo(todo)
                    .quantity(quantity)
                    .purchasePrice(todo.getCurrentPrice())
                    .build();
            investment = investmentRepository.save(investment);
        }

        investor.setCashBalance(investor.getCashBalance() - cost);
        userRepository.save(investor);

        return investment;
    }

    /**
     * 매도
     */
    @Transactional
    public void sell(Long userId, Long investmentId, Integer sellQuantity) {
        Investment investment = investmentRepository.findById(investmentId)
                .orElseThrow(() -> new IllegalArgumentException("투자 내역을 찾을 수 없습니다"));

        if (!investment.getInvestor().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 투자만 매도할 수 있습니다");
        }

        int qty = sellQuantity != null ? sellQuantity : investment.getQuantity();
        if (qty > investment.getQuantity()) {
            throw new IllegalArgumentException("보유 수량을 초과할 수 없습니다");
        }

        long proceeds = qty * investment.getTodo().getCurrentPrice();
        User investor = investment.getInvestor();
        investor.setCashBalance(investor.getCashBalance() + proceeds);
        userRepository.save(investor);

        if (qty >= investment.getQuantity()) {
            investmentRepository.delete(investment);
        } else {
            investment.setQuantity(investment.getQuantity() - qty);
            investmentRepository.save(investment);
        }
    }
}
