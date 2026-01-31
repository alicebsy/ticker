package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 관심 종목 (Watchlist) 엔티티
 * 친구를 관심 종목에 추가하면 해당 친구의 "주가"를 모니터링
 */
@Entity
@Table(name = "watchlists", uniqueConstraints = {
        @UniqueConstraint(columnNames = {"user_id", "watched_user_id"})
})
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Watchlist {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 관심 목록 소유자 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** 관심 대상 사용자 (친구) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "watched_user_id", nullable = false)
    private User watchedUser;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
