package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 주가 이력 엔티티
 * "내 주가 차트" - 1D, 7D, 1M 기간별 차트 데이터
 */
@Entity
@Table(name = "stock_price_histories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class StockPriceHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** 해당 일자의 주가 (P) */
    @Column(nullable = false)
    private Long price;

    /** 기록일 */
    @Column(nullable = false)
    private LocalDate recordDate;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
