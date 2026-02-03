package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 매수/매도 요청 DTO (한 사람 주식)
 */
@Data
public class InvestRequest {

    /** 매수 대상 사용자 ID (이 사람의 주식을 삼) */
    @NotNull(message = "대상 사용자를 선택하세요")
    private Long subjectUserId;

    /** 수량 (주) - 매수 시 */
    @Positive(message = "1주 이상 입력하세요")
    private Integer quantity = 1;

    /** 매도 시 판매할 수량 (선택, 전량 매도 시 null) */
    private Integer sellQuantity;
}
