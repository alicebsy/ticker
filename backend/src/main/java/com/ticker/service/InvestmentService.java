package com.ticker.service;

import com.ticker.dto.HeldStocksResponse;
import com.ticker.dto.InvestRequest;
import com.ticker.model.Investment;
import com.ticker.model.User;
import com.ticker.repository.InvestmentRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

/**
 * 투자 서비스
 * 한 사람 단위 주가: 100주 중 30주만 매물, 1주당 가격 = 해당 유저의 stockPrice.
 * 보유 자산으로만 매수 가능, 매도 시 보유 자산에 반영.
 */
@Service
@RequiredArgsConstructor
public class InvestmentService {

    /** 사람당 매물로 내놓을 수 있는 주식 수 (100주 - 창업자 70주) */
    private static final int SELLABLE_SHARES_PER_USER = 30;

    private final InvestmentRepository investmentRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    private final ActivityService activityService;

    @Transactional(readOnly = true)
    public HeldStocksResponse getHeldStocks(Long userId) {
        List<Investment> investments = investmentRepository.findByInvestorIdWithSubjectUser(userId);

        long totalValuation = 0;
        long totalPurchase = 0;

        List<HeldStocksResponse.HeldStockDto> dtos = investments.stream()
                .map(inv -> {
                    User subject = inv.getSubjectUser();
                    long currentPrice = subject.getStockPrice();
                    long valuation = inv.getQuantity() * currentPrice;
                    long purchase = inv.getQuantity() * inv.getPurchasePrice();
                    long profitLoss = valuation - purchase;
                    double profitLossPct = purchase > 0 ? (profitLoss * 100.0 / purchase) : 0;

                    return new HeldStocksResponse.HeldStockDto(
                            inv.getId(),
                            subject.getName(),
                            subject.getProfileImageUrl(),
                            currentPrice,
                            "— 0.00%",  // 일일 변동은 주가 이력에서 계산 가능
                            profitLoss,
                            String.format("(%+.2f%%)", profitLossPct),
                            inv.getQuantity(),
                            0
                    );
                })
                .toList();

        totalValuation = dtos.stream()
                .mapToLong(d -> d.getCurrentPrice() * d.getQuantity())
                .sum();
        totalPurchase = investments.stream()
                .mapToLong(i -> (long) i.getQuantity() * i.getPurchasePrice())
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

    @Transactional
    public Investment buy(Long userId, InvestRequest request) {
        User investor = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));
        User subjectUser = userRepository.findById(request.getSubjectUserId())
                .orElseThrow(() -> new IllegalArgumentException("대상 사용자를 찾을 수 없습니다: " + request.getSubjectUserId()));

        if (investor.getId().equals(subjectUser.getId())) {
            throw new IllegalArgumentException("본인 주식은 매수할 수 없습니다");
        }

        int quantity = request.getQuantity() != null ? request.getQuantity() : 1;
        long pricePerShare = subjectUser.getStockPrice();
        long cost = quantity * pricePerShare;

        long alreadySold = investmentRepository.sumQuantityBySubjectUserId(subjectUser.getId());
        if (alreadySold + quantity > SELLABLE_SHARES_PER_USER) {
            throw new IllegalArgumentException("매물 한도(30주)를 초과합니다. 남은 주: " + (SELLABLE_SHARES_PER_USER - alreadySold) + "주");
        }

        if (investor.getCashBalance() < cost) {
            throw new IllegalArgumentException("잔액이 부족합니다. 필요: " + cost + "P, 보유: " + investor.getCashBalance() + "P");
        }

        Optional<Investment> existing = investmentRepository.findByInvestorIdAndSubjectUserId(userId, subjectUser.getId());
        Investment investment;

        if (existing.isPresent()) {
            investment = existing.get();
            int oldQty = investment.getQuantity();
            long oldCost = (long) oldQty * investment.getPurchasePrice();
            int newQty = oldQty + quantity;
            long newCost = oldCost + cost;
            investment.setQuantity(newQty);
            investment.setPurchasePrice(newCost / newQty);
        } else {
            investment = Investment.builder()
                    .investor(investor)
                    .subjectUser(subjectUser)
                    .quantity(quantity)
                    .purchasePrice(pricePerShare)
                    .build();
            investment = investmentRepository.save(investment);
        }

        investor.setCashBalance(investor.getCashBalance() - cost);
        userRepository.save(investor);

        int remainingShares = SELLABLE_SHARES_PER_USER - (int) investmentRepository.sumQuantityBySubjectUserId(subjectUser.getId());
        notificationService.sendInvestmentChange(subjectUser.getId(), "주식 매수가 체결되었습니다.", remainingShares);
        activityService.addActivity(userId, "BUY", subjectUser.getName() + " " + quantity + "주 매수", cost);

        return investment;
    }

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

        long pricePerShare = investment.getSubjectUser().getStockPrice();
        long proceeds = qty * pricePerShare;
        User investor = investment.getInvestor();
        investor.setCashBalance(investor.getCashBalance() + proceeds);
        userRepository.save(investor);

        User subjectUser = investment.getSubjectUser();
        if (qty >= investment.getQuantity()) {
            investmentRepository.delete(investment);
        } else {
            investment.setQuantity(investment.getQuantity() - qty);
            investmentRepository.save(investment);
        }
        int remainingShares = SELLABLE_SHARES_PER_USER - (int) investmentRepository.sumQuantityBySubjectUserId(subjectUser.getId());
        notificationService.sendInvestmentChange(subjectUser.getId(), "주식 매도가 체결되었습니다.", remainingShares);
        activityService.addActivity(userId, "SELL", subjectUser.getName() + " " + qty + "주 매도", proceeds);
    }
}
