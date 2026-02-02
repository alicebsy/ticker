package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * 암시장 API 응답 DTO
 * 카테고리별 아이템 목록, 오늘의 특가
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DarkMarketResponse {

    /** 보유 포인트 */
    private Long userPoints;

    /** 스킬 목록 (선택된 카테고리) */
    private List<MarketItemDto> skills;

    /** 아이콘 목록 */
    private List<MarketItemDto> icons;

    /** 특수 아이템 목록 */
    private List<MarketItemDto> specialItems;

    /** 오늘의 특가 */
    private SpecialDealDto todaySpecial;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MarketItemDto {
        private Long id;
        private String name;
        private String description;
        private Long price;
        private String rarity;   // 에픽, 레어, 레전더리
        private String type;    // ICON, SKILL, SPECIAL
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class SpecialDealDto {
        private String title;       // 미스터리 박스 3개 묶음
        private String description; // 30% 할인
        private Long originalPrice;
        private Long discountedPrice;
    }
}
