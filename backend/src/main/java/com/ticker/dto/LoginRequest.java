package com.ticker.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 일반 로그인 요청 DTO
 */
@Data
public class LoginRequest {

    /** 로그인 ID */
    @NotBlank(message = "아이디를 입력하세요")
    private String loginId;

    /** 비밀번호 */
    @NotBlank(message = "비밀번호를 입력하세요")
    private String password;
}
