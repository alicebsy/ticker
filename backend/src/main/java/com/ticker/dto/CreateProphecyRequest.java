package com.ticker.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 예언 생성 요청
 */
@Data
public class CreateProphecyRequest {
    @NotBlank(message = "예언 내용을 입력하세요")
    @Size(max = 500, message = "예언은 500자 이내로 입력하세요")
    private String content;
}
