package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 예언 엔티티 - 사용자가 등록하는 "나의 예언"
 * 예: "오늘 내가 헬스장에 간다", "커피 3잔 안 마시기" 등
 */
@Entity
@Table(name = "prophecies")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Prophecy {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 예언 등록자 (수행자) */
    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "owner_id", nullable = false)
    private User owner;

    /** 예언 내용 */
    @Column(nullable = false, length = 500)
    private String content;

    /** 예언 상태: OPEN(배팅 가능), CLOSED(종료됨) */
    @Enumerated(EnumType.STRING)
    @Builder.Default
    private ProphecyStatus status = ProphecyStatus.OPEN;

    /** 결과: null(미정), true(성공), false(실패) */
    private Boolean result;

    /** 성공에 걸린 총 배팅금 */
    @Builder.Default
    private Long successPool = 0L;

    /** 실패에 걸린 총 배팅금 */
    @Builder.Default
    private Long failurePool = 0L;

    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime closedAt;

    /** 총 배팅 풀 */
    public Long getTotalPool() {
        return successPool + failurePool;
    }
}
