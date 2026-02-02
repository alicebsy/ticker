package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * 사용자 보유 스킬 엔티티
 * 암시장에서 구매한 스킬을 보유하고 있음 (예: 도박 취소권 x2, 할 일 스킵권 x1)
 */
@Entity
@Table(name = "user_skills", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "market_item_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class UserSkill {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "market_item_id", nullable = false)
    private MarketItem marketItem;

    /** 보유 수량 */
    @Column(nullable = false)
    @Builder.Default
    private Integer quantity = 1;
}
