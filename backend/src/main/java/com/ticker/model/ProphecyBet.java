package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 예언 배팅 엔티티
 * 다른 사람의 예언에 성공/실패 배팅
 */
@Entity
@Table(name = "prophecy_bets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ProphecyBet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 배팅한 사용자 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bettor_id", nullable = false)
    private User bettor;

    /** 배팅 대상 예언 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "prophecy_id", nullable = false)
    private Prophecy prophecy;

    /** 배팅 금액 (P) */
    @Column(nullable = false)
    private Long amount;

    /** 성공 예측 vs 실패 예측 */
    @Column(nullable = false)
    private Boolean predictSuccess;  // true: 성공 예측, false: 실패 예측

    /** 배팅 상태 */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private BetStatus status = BetStatus.IN_PROGRESS;

    /** 정산된 수익/손실 */
    private Long profitLoss;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime settledAt;
}
