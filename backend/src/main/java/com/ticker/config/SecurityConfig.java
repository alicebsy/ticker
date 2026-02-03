package com.ticker.config;

import com.ticker.service.CustomOAuth2UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.web.SecurityFilterChain;

/**
 * Spring Security 설정
 * - 카카오 OAuth2 로그인
 * - API는 인증 없이 허용 (X-User-Id 헤더 사용, 추후 JWT 등으로 전환 가능)
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final CustomOAuth2UserService customOAuth2UserService;
    private final OAuth2SuccessHandler oauth2SuccessHandler;

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
                .csrf(AbstractHttpConfigurer::disable)
                .authorizeHttpRequests(auth -> auth
                        // OAuth2 로그인 엔드포인트
                        .requestMatchers("/login/**", "/oauth2/**").permitAll()
                        // 인증 API (회원가입, 로그인은 모두 허용)
                        .requestMatchers("/api/auth/signup", "/api/auth/login").permitAll()
                        .requestMatchers("/api/auth/kakao/login-url").permitAll()
                        .requestMatchers("/api/auth/me").authenticated()
                        // WebSocket (친구 알림 등)
                        .requestMatchers("/ws", "/ws/**").permitAll()
                        // H2 콘솔 (개발용)
                        .requestMatchers("/h2-console/**").permitAll()
                        // 그 외 API는 모두 허용 (실제 서비스에서는 인증 적용)
                        .anyRequest().permitAll()
                )
                .oauth2Login(oauth2 -> oauth2
                        .userInfoEndpoint(userInfo -> userInfo
                                .userService(customOAuth2UserService)
                        )
                        .successHandler(oauth2SuccessHandler)
                );

        // H2 콘솔용
        http.headers(headers -> headers.frameOptions(frame -> frame.sameOrigin()));

        return http.build();
    }
}
