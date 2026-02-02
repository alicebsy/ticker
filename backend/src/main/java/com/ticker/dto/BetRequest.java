package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 새 베팅 생성 요청 DTO
 */
@Data
public class BetRequest {

    /** 베팅할 친구의 할 일 ID */
    @NotNull(message = "종목을 선택하세요")
    private Long todoId;

    /** 베팅 금액 (P) */
    @NotNull(message = "베팅 금액을 입력하세요")
    @Positive(message = "1P 이상 입력하세요")
    private Long amount;

    /** true: 성공 예측, false: 실패 예측 */
    @NotNull(message = "성공/실패 예측을 선택하세요")
    private Boolean predictSuccess;
}
