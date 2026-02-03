package com.ticker.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 뉴스 댓글 응답 DTO
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NewsCommentDto {

    private Long id;
    private Long authorId;
    private String authorName;
    private String content;
    private LocalDateTime timestamp;
}
