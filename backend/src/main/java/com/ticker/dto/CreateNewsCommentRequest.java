package com.ticker.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 뉴스 댓글 작성 요청 DTO
 */
@Data
public class CreateNewsCommentRequest {

    @NotBlank(message = "댓글 내용을 입력하세요")
    private String content;
}
