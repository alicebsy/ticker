package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 카지노 API 응답 DTO
 * 베팅 가능 금액, 베팅 내역
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CasinoResponse {

    /** 베팅 가능 금액 (P) */
    private Long bettingBalance;

    /** 베팅 내역 */
    private List<BetHistoryDto> betHistory;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class BetHistoryDto {
        private Long id;
        /** UI RecentBetRow용: 친구 이름 (target) */
        private String target;
        private String friendName;    // target과 동일, 호환용
        private String todoName;      // 헬스장 가기
        /** UI용: "성공" / "실패" (BetType) */
        private String type;
        private String prediction;    // "성공 예측·500P" or "실패 예측·300P"
        private Long amount;
        private Boolean predictSuccess;
        /** UI용: "win" / "lose" / "pending" (BetResult) */
        private String result;
        private String status;        // 진행 중, 적중, 실패
        /** UI RecentBetRow용: 수익/손실 (적중 시 +, 실패 시 -, 진행 중 0) */
        private Long profit;
        private Long profitLoss;      // profit과 동일, 호환용
        private Boolean isExpected;   // 예상인지 실제 결과인지
    }
}
