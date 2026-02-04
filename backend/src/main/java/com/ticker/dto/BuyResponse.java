package com.ticker.dto;

import lombok.*;

/**
 * 매수 응답 DTO
 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class BuyResponse {
    private Long investmentId;
    private String subjectName;
    private int quantity;
    private long purchasePrice;
    private long totalCost;
    private String message;
}
