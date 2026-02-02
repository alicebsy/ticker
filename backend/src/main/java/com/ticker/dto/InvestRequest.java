package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 매수/매도 요청 DTO
 */
@Data
public class InvestRequest {

    /** 대상 할 일(종목) ID */
    @NotNull(message = "종목을 선택하세요")
    private Long todoId;

    /** 수량 (주) - 매수 시 */
    @Positive(message = "1주 이상 입력하세요")
    private Integer quantity = 1;

    /** 매도 시 판매할 수량 (선택, 전량 매도 시 null) */
    private Integer sellQuantity;
}
