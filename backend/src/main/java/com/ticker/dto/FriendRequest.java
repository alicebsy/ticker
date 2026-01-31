package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 친구 추가 요청 DTO
 */
@Data
public class FriendRequest {

    /** 추가할 친구의 사용자 ID */
    @NotNull(message = "친구 ID를 입력하세요")
    private Long friendUserId;
}
