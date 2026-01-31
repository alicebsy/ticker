package com.ticker.model;

/**
 * 할 일(종목)의 진행 상태
 * - LISTED: 상장 중 (진행 중)
 * - COMPLETED: 완료 (매도/청산됨)
 * - DELISTED: 상장 폐지 (실패 또는 취소)
 */
public enum TodoStatus {
    LISTED,     // 상장 중
    COMPLETED,  // 완료 (성공)
    DELISTED    // 상장 폐지 (실패/취소)
}
