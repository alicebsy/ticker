package com.ticker.dto;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

/**
 * 예언 응답 DTO
 */
@Data
@Builder
public class ProphecyDto {
    private Long id;
    private Long ownerId;
    private String ownerName;
    private String content;
    private String status;        // OPEN, CLOSED
    private Boolean result;       // null(미정), true(성공), false(실패)
    private Long successPool;     // 성공에 건 총액
    private Long failurePool;     // 실패에 건 총액
    private Long totalPool;       // 총 배팅금
    private LocalDateTime createdAt;
    private LocalDateTime closedAt;
}
