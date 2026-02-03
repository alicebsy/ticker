package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

/**
 * 투자 엔티티
 * 사용자가 "한 사람"의 주식을 매수한 내역.
 * 대상 유저는 100주 중 창업자 70주 제외, 30주만 매물로 판매 가능. 1주당 가격 = 해당 유저의 stockPrice.
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

    /** 투자 대상 사용자 (이 사람의 주식을 산 것) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "subject_user_id", nullable = false)
    private User subjectUser;

    /** 보유 수량 (주) */
    @Column(nullable = false)
    private Integer quantity;

    /** 매입 단가 (P/주) */
    @Column(nullable = false)
    private Long purchasePrice;

    /** 현재 평가금액 = quantity * subjectUser.stockPrice, 손익 = (현재가 - 매입가) * 수량 */
}
