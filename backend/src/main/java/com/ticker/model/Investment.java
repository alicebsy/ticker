package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * 투자 엔티티
 * 사용자가 친구의 할 일(종목)에 "매수"한 내역.
 * 보유 종목, 포트폴리오 "투자 중인 종목"에 표시됨
 */
@Entity
@Table(name = "investments")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Investment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 투자자 */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "investor_id", nullable = false)
    private User investor;

    /** 투자 대상 할 일(종목) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "todo_id", nullable = false)
    private Todo todo;

    /** 보유 수량 (주) */
    @Column(nullable = false)
    private Integer quantity;

    /** 매입 단가 (P) */
    @Column(nullable = false)
    private Long purchasePrice;

    /** 현재 평가금액 = quantity * todo.currentPrice (계산 가능) */
    /** 손익 = (현재가 - 매입가) * 수량 (계산 가능) */
}
