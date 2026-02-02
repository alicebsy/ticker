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
        private String friendName;    // 김민수
        private String todoName;      // 헬스장 가기
        private String prediction;    // "성공 예측·500P" or "실패 예측·300P"
        private Long amount;
        private Boolean predictSuccess;
        private String status;        // 진행 중, 적중, 실패
        private Long profitLoss;      // 예상 +750P or 실제 +660P / -1000P
        private Boolean isExpected;   // 예상인지 실제 결과인지
    }
}
