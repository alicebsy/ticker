package com.ticker.dto;

import com.ticker.model.NewsCategory;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 뉴스 글 수정 요청 DTO
 */
@Data
public class UpdateNewsPostRequest {

    @NotBlank(message = "제목을 입력하세요")
    private String title;

    @NotBlank(message = "내용을 입력하세요")
    private String content;

    @NotNull(message = "카테고리를 선택하세요")
    private NewsCategory category;

    private boolean anonymous = false;
}
