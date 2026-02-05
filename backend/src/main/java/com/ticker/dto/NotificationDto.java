package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * WebSocket 실시간 알림 DTO
 * 친구 요청, 수락, 거절 등
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NotificationDto {

    /** 알림 타입 */
    private String type;

    /** 메시지 (화면에 표시용) */
    private String message;

    /** 관련 사용자 ID (요청자/수락자 등) */
    private Long fromUserId;

    /** 관련 사용자 이름 */
    private String fromUserName;

    /** 관련 사용자 프로필 이미지 URL */
    private String fromUserImageUrl;

    /** 타임스탬프 */
    private String timestamp;

    /** 주가 변동 시: 해당 유저 ID, 주가, 시가총액, 총 자산 */
    private Long userId;
    private Long stockPrice;
    private Long marketCap;
    private Long totalAssets;

    /** 할 일/상장 변동 시: todo ID, 진행률, 완료 여부 */
    private Long todoId;
    private Integer progress;
    private Boolean completed;

    /** 투자 변동 시: 남은 매물 주 수 (30주 중) */
    private Integer remainingShares;

    public static final String TYPE_FRIEND_REQUEST = "FRIEND_REQUEST";
    public static final String TYPE_FRIEND_ACCEPTED = "FRIEND_ACCEPTED";
    public static final String TYPE_FRIEND_REJECTED = "FRIEND_REJECTED";
    /** 주가 변동 (다른 사람들 그래프/주가 실시간 반영) */
    public static final String TYPE_STOCK_PRICE_UPDATED = "STOCK_PRICE_UPDATED";
    /** 상장/할 일 변동 (완료 체크, 진행률 변경 → 그래프·목록 실시간 반영) */
    public static final String TYPE_LISTING_UPDATED = "LISTING_UPDATED";
    /** 내 주식 매수/매도 발생 (남은 매물 등 실시간 반영) */
    public static final String TYPE_INVESTMENT_CHANGED = "INVESTMENT_CHANGED";
    /** 내 할 일에 베팅이 걸림 (할 일 소유자에게) */
    public static final String TYPE_BET_PLACED = "BET_PLACED";
    /** 나를 관심 종목에 추가함 */
    public static final String TYPE_ADDED_TO_WATCHLIST = "ADDED_TO_WATCHLIST";
    /** 예언 종료됨 (예언 등록자에게) */
    public static final String TYPE_PROPHECY_CLOSED = "PROPHECY_CLOSED";
    /** 예언 배팅 결과 (배팅 참여자에게) */
    public static final String TYPE_PROPHECY_BET_RESULT = "PROPHECY_BET_RESULT";
}
