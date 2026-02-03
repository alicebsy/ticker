package com.ticker.dto;

import com.ticker.model.NewsCategory;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 뉴스 글 응답 DTO (목록/상세 공통 필드, 상세 시 comments 포함)
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class NewsPostDto {

    private Long id;
    private Long authorId;
    private String authorName;
    /** 작성자 표시용 (loginId 또는 익명 시 "익명") */
    private String authorTicker;
    private String title;
    private String content;
    private NewsCategory category;
    private int likes;
    private LocalDateTime timestamp;
    private boolean anonymous;

    /** 목록용: 댓글 개수만. 상세용: 댓글 목록 */
    private Integer commentCount;
    private List<NewsCommentDto> comments;
}
