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

        // redirectUri가 "ticker" 스킴인 경우(앱) HTML 랜딩 페이지 제공
        if (targetUrl.startsWith("ticker://")) {
            response.setContentType("text/html;charset=UTF-8");
            response.getWriter().write(
                    "<!DOCTYPE html>" +
                            "<html>" +
                            "<head>" +
                            "  <meta charset='UTF-8'>" +
                            "  <meta name='viewport' content='width=device-width, initial-scale=1.0'>" +
                            "  <title>로그인 성공</title>" +
                            "</head>" +
                            "<body style='text-align: center; font-family: -apple-system, BlinkMacSystemFont, \"Segoe UI\", Roboto, sans-serif; padding-top: 50px;'>"
                            +
                            "  <h2>로그인 완료</h2>" +
                            "  <p>Ticker 앱으로 돌아가는 중입니다...</p>" +
                            "  <p>자동으로 이동하지 않으면 아래 버튼을 눌러주세요.</p>" +
                            "  <a href='" + targetUrl
                            + "' style='display: inline-block; padding: 12px 24px; background-color: #00C73C; color: white; text-decoration: none; border-radius: 8px; font-weight: bold; margin-top: 20px;'>앱 열기</a>"
                            +
                            "  <script>" +
                            "    setTimeout(function() { window.location.href = '" + targetUrl + "'; }, 100);" +
                            "  </script>" +
                            "</body>" +
                            "</html>");
        } else {
            response.sendRedirect(targetUrl);
        }
    }
}
