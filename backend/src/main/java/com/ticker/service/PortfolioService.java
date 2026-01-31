package com.ticker.service;

import com.ticker.dto.PortfolioResponse;
import com.ticker.model.*;
import com.ticker.repository.*;
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

        // 투자 중인 종목 조회
        List<Investment> investments = investmentRepository.findByInvestorIdWithTodoAndOwner(userId);
        long investingAmount = investments.stream()
                .mapToLong(i -> i.getQuantity() * i.getTodo().getCurrentPrice())
                .sum();

        // DTO 변환
        List<PortfolioResponse.InvestmentSummaryDto> investmentDtos = investments.stream()
                .map(i -> {
                    Todo todo = i.getTodo();
                    User owner = todo.getOwner();
                    long value = i.getQuantity() * todo.getCurrentPrice();
                    String change = todo.getDailyChangePercent() != null
                            ? String.format("%+.2f%%", todo.getDailyChangePercent())
                            : "— 0.00%";
                    return new PortfolioResponse.InvestmentSummaryDto(
                            i.getId(),
                            owner.getName(),
                            owner.getProfileImageUrl(),
                            value,
                            change
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
                .dailyChangePercent(dailyChange)
                .investingAmount(investingAmount)
                .cashBalance(user.getCashBalance())
                .investments(investmentDtos)
                .skills(skillDtos)
                .delistedHistory(delistedDtos)
                .build();
    }
}
