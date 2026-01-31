package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 보유 종목 API 응답 DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class HeldStocksResponse {

    /** 총 평가금액 */
    private Long totalValuation;

    /** 총 매입금액 */
    private Long totalPurchaseAmount;

    /** 총 손익 */
    private Long totalProfitLoss;

    /** 총 수익률 (%) */
    private String totalReturnRate;

    /** 보유 종목 목록 */
    private List<HeldStockDto> stocks;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class HeldStockDto {
        private Long id;
        private String ownerName;
        private String ownerImageUrl;
        private Long currentPrice;
        private String priceChangePercent;   // +5.20%, -2.10%
        private Long profitLoss;             // 손익
        private String profitLossPercent;    // (+25.00%)
        private Integer quantity;            // 보유 수량 (주)
        private Integer holdingRatio;        // 보유 비중 (%)
    }
}
