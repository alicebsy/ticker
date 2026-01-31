package com.ticker.model;

/**
 * 베팅 상태
 * - IN_PROGRESS: 진행 중 (할 일 미완료)
 * - HIT: 적중 (성공 예측 + 성공 / 실패 예측 + 실패)
 * - MISS: 실패 (예측과 반대 결과)
 */
public enum BetStatus {
    IN_PROGRESS,  // 진행 중
    HIT,          // 적중
    MISS          // 실패
}
