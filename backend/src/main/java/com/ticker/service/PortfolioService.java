package com.ticker.service;

import com.ticker.dto.PortfolioResponse;
import com.ticker.model.Investment;
import com.ticker.model.User;
import com.ticker.model.UserSkill;
import com.ticker.model.DelistedHistory;
import com.ticker.repository.UserRepository;
import com.ticker.repository.InvestmentRepository;
import com.ticker.repository.UserSkillRepository;
import com.ticker.repository.DelistedHistoryRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 포트폴리오 서비스
 * 총 자산, 투자 중인 종목, 보유 스킬, 상장 폐지 내역 조회
 */
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PortfolioService {

    private final UserRepository userRepository;
    private final InvestmentRepository investmentRepository;
    private final UserSkillRepository userSkillRepository;
    private final DelistedHistoryRepository delistedHistoryRepository;

    /**
     * 사용자 포트폴리오 조회
     */
    public PortfolioResponse getPortfolio(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다: " + userId));

        // 투자 중인 종목(한 사람 주식) 조회
        List<Investment> investments = investmentRepository.findByInvestorIdWithSubjectUser(userId);
        long investingAmount = investments.stream()
                .mapToLong(i -> (long) i.getQuantity() * i.getSubjectUser().getStockPrice())
                .sum();

        List<PortfolioResponse.InvestmentSummaryDto> investmentDtos = investments.stream()
                .map(i -> {
                    User subject = i.getSubjectUser();
                    long value = (long) i.getQuantity() * subject.getStockPrice();
                    return new PortfolioResponse.InvestmentSummaryDto(
                            i.getId(),
                            subject.getName(),
                            subject.getProfileImageUrl(),
                            value,
                            "— 0.00%"
                    );
                })
                .collect(Collectors.toList());

        // 보유 스킬
        List<UserSkill> userSkills = userSkillRepository.findByUserIdWithMarketItem(userId);
        List<PortfolioResponse.SkillSummaryDto> skillDtos = userSkills.stream()
                .map(us -> new PortfolioResponse.SkillSummaryDto(
                        us.getMarketItem().getName(),
                        us.getQuantity()
                ))
                .collect(Collectors.toList());

        // 상장 폐지 내역
        List<DelistedHistory> delisted = delistedHistoryRepository.findByUserIdWithTodoOrderByDelistedDateDesc(userId);
        List<PortfolioResponse.DelistedSummaryDto> delistedDtos = delisted.stream()
                .map(d -> new PortfolioResponse.DelistedSummaryDto(
                        d.getTodo().getName(),
                        d.getDelistedDate().toString(),
                        d.getProfitLoss(),
                        d.getStatus()
                ))
                .collect(Collectors.toList());

        // 일일 변동률 (실제로는 전일 대비 계산, 여기서는 간단히)
        String dailyChange = user.getConsecutiveUpDays() > 0
                ? String.format("+%.2f%%", 3.2)  // 샘플값
                : "— 0.00%";

        return PortfolioResponse.builder()
                .totalAssets(user.getTotalAssets())
                .cashBalance(user.getCashBalance())
                .marketCap(user.getMarketCap())
                .dailyChangePercent(dailyChange)
                .investingAmount(investingAmount)
                .investments(investmentDtos)
                .skills(skillDtos)
                .delistedHistory(delistedDtos)
                .build();
    }
}
