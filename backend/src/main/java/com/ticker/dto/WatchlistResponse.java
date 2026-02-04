package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 관심 종목(Watchlist) API 응답 DTO
 * 친구 검색, 대기 중인 요청, 관심 종목 그리드
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class WatchlistResponse {

    /** 대기 중인 요청 - 내가 보낸 것 */
    private List<FriendRequestDto> sentRequests;

    /** 대기 중인 요청 - 내가 받은 것 */
    private List<FriendRequestDto> receivedRequests;

    /** 관심 종목 (친구들의 주가) */
    private List<WatchlistItemDto> watchlistItems;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class FriendRequestDto {
        private Long id;
        private String name;
        private String imageUrl;
        private String status;  // "요청 보냄" or 수락/거절 버튼용
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WatchlistItemDto {
        private Long userId;
        private String name;
        private String imageUrl;
        private Long currentPrice;
        private String changePercent;   // +3.50%, -1.20%, — 0.00%
        private List<Long> chartData;   // 미니 차트용 가격 배열
        private int remainingShares;    // 매수 가능 잔여 주수 (30 - 이미 팔린 수)
    }
}
