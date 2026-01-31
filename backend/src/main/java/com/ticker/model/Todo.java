package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * 할 일(종목) 엔티티
 * 사용자가 "상장"하는 목표/할 일. 친구들이 이 종목에 투자하거나 배팅함.
 * 완료 시 보상(P) 분배, 미완료 시 손실 등이 발생
 */
@Entity
@Table(name = "todos")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Todo {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 할 일 소유자 (상장자) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    /** 종목명 (할 일 내용) - 예: "헬스장 주 3회 가기", "책 1권 완독" */
    @Column(nullable = false)
    private String name;

    /** 마감일 */
    @Column(nullable = false)
    private LocalDate deadline;

    /** 공모가 / 보상 포인트 (완료 시 지급되는 P) */
    @Column(nullable = false)
    private Long rewardPoints;

    /** 난이도 (쉬움/보통/어려움) */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Difficulty difficulty = Difficulty.NORMAL;

    /** 공개 범위 (친구만/전체) */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private Visibility visibility = Visibility.FRIENDS_ONLY;

    /** 진행률 (0~100) - UI 진행률 바에 표시 */
    @Builder.Default
    private Integer progress = 0;

    /** 현재 가격 (투자/배팅에 따라 변동) */
    @Column(nullable = false)
    @Builder.Default
    private Long currentPrice = 500L;

    /** 일일 변동률 (%) - 주가 차트용 */
    private Double dailyChangePercent;

    /** 상태: 상장중/완료/폐지 */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private TodoStatus status = TodoStatus.LISTED;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime completedAt;

    @PreUpdate
    protected void onUpdate() {
        // 필요시 updatedAt 필드 추가
    }
}
