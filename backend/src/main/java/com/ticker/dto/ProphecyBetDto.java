package com.ticker.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 예언 배팅 응답 DTO
 */
@Data
@Builder
public class ProphecyBetDto {
    private Long id;
    private Long prophecyId;
    private String prophecyContent;
    private Long ownerId;
    private String ownerName;
    private Long amount;
    private Boolean predictSuccess;
    private String status;         // IN_PROGRESS, HIT, MISS
    private Long profitLoss;
    private LocalDateTime createdAt;
    private LocalDateTime settledAt;
}
