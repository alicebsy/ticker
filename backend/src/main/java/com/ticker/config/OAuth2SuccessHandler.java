package com.ticker.config;

import com.ticker.service.CustomOAuth2User;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.core.Authentication;
import org.springframework.security.web.authentication.AuthenticationSuccessHandler;
import org.springframework.stereotype.Component;

import java.io.IOException;

/**
 * OAuth2 로그인 성공 시 리다이렉트
 * 프론트엔드 URL로 userId 전달 (Swift 앱의 커스텀 URL 스킴 등)
 */
@Component
@Slf4j
public class OAuth2SuccessHandler implements AuthenticationSuccessHandler {

    /**
     * 로그인 성공 후 리다이렉트할 URL
     * 예: ticker://oauth?userId=1 또는 http://localhost:3000/oauth?userId=1
     */
    @Value("${app.oauth.redirect-uri:}")
    private String redirectUri;

    @Override
    public void onAuthenticationSuccess(HttpServletRequest request, HttpServletResponse response,
                                        Authentication authentication) throws IOException, ServletException {
        Object principal = authentication.getPrincipal();
        Long userId = null;

        if (principal instanceof CustomOAuth2User customUser) {
            userId = customUser.getUserId();
        }

        String targetUrl;
        if (redirectUri != null && !redirectUri.isBlank() && userId != null) {
            String separator = redirectUri.contains("?") ? "&" : "?";
            targetUrl = redirectUri + separator + "userId=" + userId;
        } else {
            // 기본: 로그인 성공 시 사용자 정보 JSON 반환 (웹 테스트용)
            targetUrl = request.getContextPath() + "/api/auth/me";
        }

        log.info("OAuth2 로그인 성공, userId={}, redirect={}", userId, targetUrl);
        response.sendRedirect(targetUrl);
    }
}
