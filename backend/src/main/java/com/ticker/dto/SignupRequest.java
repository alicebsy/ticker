package com.ticker.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 일반 회원가입 요청 DTO
 */
@Data
public class SignupRequest {

    /** 로그인 ID (이메일 또는 아이디) */
    @NotBlank(message = "아이디를 입력하세요")
    @Size(min = 3, max = 50, message = "아이디는 3~50자로 입력하세요")
    private String loginId;

    /** 비밀번호 */
    @NotBlank(message = "비밀번호를 입력하세요")
    @Size(min = 4, max = 100, message = "비밀번호는 4자 이상 입력하세요")
    private String password;

    /** 사용자 이름 (닉네임) */
    @NotBlank(message = "이름을 입력하세요")
    @Size(min = 1, max = 50, message = "이름은 1~50자로 입력하세요")
    private String name;

    /** 프로필 이미지 URL (선택) */
    private String profileImageUrl;
}
