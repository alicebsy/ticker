package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 베팅 엔티티 (카지노 - 친구 베팅)
 * 친구의 할 일이 "성공"할지 "실패"할지 예측하고 포인트를 걸음
 */
@Entity
@Table(name = "bets")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Bet {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 베팅한 사용자 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "bettor_id", nullable = false)
    private User bettor;

    /** 베팅 대상 할 일 (친구의 종목) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "todo_id", nullable = false)
    private Todo todo;

    /** 베팅 금액 (P) */
    @Column(nullable = false)
    private Long amount;

    /** 성공 예측 vs 실패 예측 */
    @Column(nullable = false)
    private Boolean predictSuccess;  // true: 성공 예측, false: 실패 예측

    /** 베팅 상태: 진행중/적중/실패 */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private BetStatus status = BetStatus.IN_PROGRESS;

    /** 실제 수익/손실 (적중/실패 시 정산된 금액, + 또는 -) */
    private Long profitLoss;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime settledAt;
}
