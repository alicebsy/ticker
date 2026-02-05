package com.ticker.dto;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

/**
 * 예언 종료 (결과 입력) 요청
 */
@Data
public class CloseProphecyRequest {
    @NotNull(message = "결과(성공/실패)를 선택하세요")
    private Boolean success;
}
