package com.ticker.model;

/**
 * 할 일 난이도
 * 공모가(보상 포인트) 계산 등에 사용
 * 내 몸값 비례형: 기본 난이도 점수 × (내 주가 / 100)
 */
public enum Difficulty {
    EASY(500),    // 쉬움 - 기본 500P
    NORMAL(1000), // 보통 - 기본 1,000P
    HARD(1500);   // 어려움 - 기본 1,500P

    private final long baseScore;

    Difficulty(long baseScore) {
        this.baseScore = baseScore;
    }

    /** 기본 난이도 점수 (공모가 계산용) */
    public long getBaseScore() {
        return baseScore;
    }

    /**
     * 내 몸값 비례형 공모가 계산
     * 공식: 기본 난이도 점수 × (내 주가 / 100)
     * - 주가 50원 → 0.5배 (저평가)
     * - 주가 100원 → 1배
     * - 주가 200원 → 2배 (프리미엄)
     */
    public long calculateIpoPrice(long stockPrice) {
        return baseScore * stockPrice / 100;
    }
}
