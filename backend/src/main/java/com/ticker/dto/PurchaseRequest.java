package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 암시장 아이템 구매 요청 DTO
 */
@Data
public class PurchaseRequest {

    @NotNull(message = "아이템 ID를 입력하세요")
    private Long marketItemId;

    @NotNull(message = "수량을 입력하세요")
    @Positive(message = "1개 이상 구매하세요")
    private Integer quantity = 1;
}
