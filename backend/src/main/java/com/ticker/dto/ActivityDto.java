package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 활동 내역 응답 DTO (UI Activity 타입/설명/금액/시간)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class ActivityDto {

    private Long id;
    private String type;       // BUY, SELL, LISTING, PURCHASE, BET 등
    private String description;
    private Long amount;
    private LocalDateTime timestamp;
}
