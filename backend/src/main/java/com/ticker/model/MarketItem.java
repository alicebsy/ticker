package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * 암시장 아이템 엔티티
 * 도박 취소권, 할 일 스킵권, 룰렛 추가 기회권, 손실 방어권 등
 */
@Entity
@Table(name = "market_items")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class MarketItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 아이템명 */
    @Column(nullable = false)
    private String name;

    /** 설명 - 예: "진행 중인 베팅을 취소할 수 있습니다" */
    private String description;

    /** 가격 (P) */
    @Column(nullable = false)
    private Long price;

    /** 희귀도 (에픽, 레어, 레전더리 등) */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ItemRarity rarity = ItemRarity.COMMON;

    /** 카테고리: ICON, SKILL, SPECIAL */
    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private MarketItemType type;

    public enum MarketItemType {
        ICON,    // 아이콘
        SKILL,   // 스킬 (도박취소, 스킵, 룰렛 등)
        SPECIAL  // 특수 아이템 (미스터리 박스 등)
    }
}
