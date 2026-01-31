package com.ticker.model;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

/**
 * 사용자 엔티티
 * Human Stock Market의 회원으로, 할 일을 상장하고 친구들의 할 일에 투자/배팅할 수 있음
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 사용자 이름 (예: 김민수, 이지은) */
    @Column(nullable = false)
    private String name;

    /** 로그인 ID (이메일, 유저네임, 또는 kakao_{카카오ID}) */
    @Column(unique = true, nullable = false)
    private String loginId;

    /** 비밀번호 (실제 운영시 암호화 필수, OAuth 사용자는 null) */
    private String password;

    /** OAuth 제공자 (kakao, naver 등) */
    private String oauthProvider;

    /** OAuth 제공자 회원번호 */
    private String oauthId;

    /** 프로필 이미지 URL */
    private String profileImageUrl;

    /** 보유 현금 (P 포인트) - 투자하지 않은 자유 자금 */
    @Column(nullable = false)
    @Builder.Default
    private Long cashBalance = 0L;

    /** 총 자산 = 투자 중 금액 + 보유 현금 (계산 필드로도 사용) */
    @Column(nullable = false)
    @Builder.Default
    private Long totalAssets = 0L;

    /** 내 주가 (해당 사용자의 할 일 완료율 등으로 계산되는 "가치") */
    @Column(nullable = false)
    @Builder.Default
    private Long stockPrice = 100L;

    /** 연속 상승일 수 (주가 차트 "연속 N일 상승" 표시용) */
    @Builder.Default
    private Integer consecutiveUpDays = 0;

    @Column(nullable = false)
    @Builder.Default
    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime updatedAt;

    @PreUpdate
    protected void onUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}
