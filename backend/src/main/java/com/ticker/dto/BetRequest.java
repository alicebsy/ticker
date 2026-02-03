package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

/**
 * 새 베팅 생성 요청 DTO
 * - todoId: 베팅할 할 일 ID (직접 지정 시)
 * - friendUserId: 베팅할 친구 ID (지정 시 해당 친구의 첫 번째 LISTED 할 일에 베팅)
 * 둘 중 하나만 있으면 됨. friendUserId 우선.
 */
@Data
public class BetRequest {

    /** 베팅할 할 일 ID (friendUserId 없을 때 사용) */
    private Long todoId;

    /** 베팅할 친구 사용자 ID (지정 시 해당 친구의 첫 번째 LISTED 할 일에 베팅) */
    private Long friendUserId;

    /** 베팅 금액 (P) */
    @NotNull(message = "베팅 금액을 입력하세요")
    @Positive(message = "1P 이상 입력하세요")
    private Long amount;

    /** true: 성공 예측, false: 실패 예측 */
    @NotNull(message = "성공/실패 예측을 선택하세요")
    private Boolean predictSuccess;
}
