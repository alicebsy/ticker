package com.ticker.controller;

import com.ticker.dto.LoginRequest;
import com.ticker.dto.SignupRequest;
import com.ticker.model.User;
import com.ticker.repository.UserRepository;
import com.ticker.service.CustomOAuth2User;
import com.ticker.service.WatchlistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * 인증 API
 * - 일반 회원가입/로그인
 * - 카카오 OAuth2 로그인
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final WatchlistService watchlistService;

    /**
     * 일반 회원가입
     */
    @PostMapping("/signup")
    public ResponseEntity<?> signup(@Valid @RequestBody SignupRequest request) {
        // 중복 체크
        if (userRepository.existsByLoginId(request.getLoginId())) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", "DUPLICATE_LOGIN_ID",
                    "message", "이미 사용 중인 아이디입니다"));
        }

        User user = User.builder()
                .loginId(request.getLoginId())
                .password(request.getPassword()) // TODO: 실서비스에서는 BCrypt 암호화 필수
                .name(request.getName())
                .profileImageUrl(request.getProfileImageUrl())
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L) // 보유 자산 초기 10만원
                .marketCap(100_000L) // 내 가치 초기 10만원
                .totalAssets(200_000L) // 총 자산
                .stockPrice(1000L) // 1주당 1000원
                .build();

        User saved = userRepository.save(user);

        return ResponseEntity.ok(Map.of(
                "id", saved.getId(),
                "loginId", saved.getLoginId(),
                "name", saved.getName(),
                "profileImageUrl", saved.getProfileImageUrl() != null ? saved.getProfileImageUrl() : "",
                "cashBalance", saved.getCashBalance(),
                "marketCap", saved.getMarketCap(),
                "totalAssets", saved.getTotalAssets(),
                "stockPrice", saved.getStockPrice(),
                "friendCode", saved.getFriendCode(),
                "message", "회원가입이 완료되었습니다"));
    }

    /**
     * 일반 로그인
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        return userRepository.findByLoginId(request.getLoginId())
                .map(user -> {
                    // 비밀번호 확인 (TODO: 실서비스에서는 BCrypt 검증)
                    if (!request.getPassword().equals(user.getPassword())) {
                        return ResponseEntity.status(401).body(Map.of(
                                "error", "INVALID_PASSWORD",
                                "message", "비밀번호가 일치하지 않습니다"));
                    }

                    return ResponseEntity.ok(Map.of(
                            "id", user.getId(),
                            "loginId", user.getLoginId(),
                            "name", user.getName(),
                            "profileImageUrl", user.getProfileImageUrl() != null ? user.getProfileImageUrl() : "",
                            "cashBalance", user.getCashBalance(),
                            "marketCap", user.getMarketCap(),
                            "totalAssets", user.getTotalAssets(),
                            "stockPrice", user.getStockPrice(),
                            "friendCode", user.getFriendCode(),
                            "message", "로그인 성공"));
                })
                .orElse(ResponseEntity.status(404).body(Map.of(
                        "error", "USER_NOT_FOUND",
                        "message", "존재하지 않는 아이디입니다")));
    }

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
                        "cashBalance", user.getCashBalance(),
                        "marketCap", user.getMarketCap(),
                        "totalAssets", user.getTotalAssets(),
                        "stockPrice", user.getStockPrice(),
                        "friendCode", user.getFriendCode(),
                        "oauthProvider", user.getOauthProvider() != null ? user.getOauthProvider() : "")))
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
                "description", "이 URL로 이동하면 카카오 로그인 화면이 표시됩니다"));
    }
}
