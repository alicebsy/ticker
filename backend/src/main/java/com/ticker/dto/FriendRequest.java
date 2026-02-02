package com.ticker.dto;

import lombok.Data;

/**
 * 친구 추가 요청 DTO
 * friendUserId 또는 friendCode 중 하나만 있으면 됨 (친구 코드로 추가 시 코드 입력)
 */
@Data
public class FriendRequest {

    /** 추가할 친구의 사용자 ID (선택) */
    private Long friendUserId;

    /** 추가할 친구의 개별 인증 코드 (선택, friendUserId 없을 때 사용) */
    private String friendCode;
}
