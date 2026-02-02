package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 포트폴리오 API 응답 DTO
 * 총 자산, 투자 중 금액, 보유 현금, 투자 중인 종목, 보유 스킬, 상장 폐지 내역
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class PortfolioResponse {

    /** 총 자산 (P) = 보유 자산 + 내 가치 */
    private Long totalAssets;

    /** 보유 자산 (P) - 투자·배팅에 사용 가능 */
    private Long cashBalance;

    /** 내 가치 (P) - 시가총액, 랭킹용, 현금화 불가 */
    private Long marketCap;

    /** 일일 변동률 (%) - "+3.20%" 형태 */
    private String dailyChangePercent;

    /** 투자 중 금액 (P) */
    private Long investingAmount;

    /** 투자 중인 종목 목록 */
    private List<InvestmentSummaryDto> investments;

    /** 보유 스킬 목록 */
    private List<SkillSummaryDto> skills;

    /** 상장 폐지 내역 */
    private List<DelistedSummaryDto> delistedHistory;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class InvestmentSummaryDto {
        private Long id;
        private String ownerName;      // 김민수, 이지은 등
        private String ownerImageUrl;
        private Long currentValue;     // 12,500P
        private String changePercent;  // +5.20%, -2.10%
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SkillSummaryDto {
        private String name;    // 도박 취소권
        private Integer quantity;  // x2
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DelistedSummaryDto {
        private String todoName;   // 프로젝트 A
        private String date;       // 2024-01-15
        private Long profitLoss;   // +2500 또는 -500
        private String status;     // 청산 완료, 손실 처리
    }
}
