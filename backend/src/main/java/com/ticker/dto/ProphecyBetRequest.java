package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 예언 배팅 요청
 */
@Data
public class ProphecyBetRequest {
    @NotNull(message = "예언 ID를 지정하세요")
    private Long prophecyId;

    @NotNull(message = "배팅 금액을 입력하세요")
    @Positive(message = "배팅 금액은 0보다 커야 합니다")
    private Long amount;

    @NotNull(message = "성공/실패 예측을 선택하세요")
    private Boolean predictSuccess;
}
