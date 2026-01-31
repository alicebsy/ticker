package com.ticker.controller;

import com.ticker.model.User;
import com.ticker.repository.UserRepository;
import com.ticker.service.CustomOAuth2User;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 인증 API
 * - 로그인된 사용자 정보 조회
 * - 카카오 로그인 진입점 URL 안내
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;

    /**
     * 현재 로그인된 사용자 정보 (OAuth2 로그인 후)
     */
    @GetMapping("/me")
    public ResponseEntity<?> me(@AuthenticationPrincipal OAuth2User principal) {
        if (principal == null) {
            return ResponseEntity.status(401).body(Map.of("message", "로그인이 필요합니다"));
        }

        Long userId = null;
        if (principal instanceof CustomOAuth2User customUser) {
            userId = customUser.getUserId();
        }

        if (userId == null) {
            return ResponseEntity.status(401).body(Map.of("message", "사용자 정보를 찾을 수 없습니다"));
        }

        return userRepository.findById(userId)
                .map(user -> ResponseEntity.ok(Map.of(
                        "id", user.getId(),
                        "name", user.getName(),
                        "loginId", user.getLoginId(),
                        "profileImageUrl", user.getProfileImageUrl() != null ? user.getProfileImageUrl() : "",
                        "oauthProvider", user.getOauthProvider() != null ? user.getOauthProvider() : ""
                )))
                .orElse(ResponseEntity.status(404).build());
    }

    /**
     * 카카오 로그인 URL (웹/앱에서 리다이렉트용)
     * GET /api/auth/kakao/login -> 302 redirect to /oauth2/authorization/kakao
     */
    @GetMapping("/kakao/login-url")
    public ResponseEntity<Map<String, String>> kakaoLoginUrl() {
        return ResponseEntity.ok(Map.of(
                "url", "/oauth2/authorization/kakao",
                "description", "이 URL로 이동하면 카카오 로그인 화면이 표시됩니다"
        ));
    }
}
