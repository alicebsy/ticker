package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 상장 폐지 내역 엔티티
 * 완료 또는 실패로 "상장 폐지"된 할 일의 결과 기록
 * 청산 완료, 손실 처리 등
 */
@Entity
@Table(name = "delisted_histories")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class DelistedHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 해당 할 일(종목) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "todo_id", nullable = false)
    private Todo todo;

    /** 이 기록의 소유자 (투자자 관점에서 본 손익) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    /** 폐지일 */
    @Column(nullable = false)
    private LocalDate delistedDate;

    /** 손익 (P) - 양수: 수익, 음수: 손실 */
    private Long profitLoss;

    /** 상태: 청산완료, 손실처리 등 */
    @Column(nullable = false)
    private String status;  // "청산 완료", "손실 처리" 등

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();
}
