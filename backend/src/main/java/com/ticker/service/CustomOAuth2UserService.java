package com.ticker.service;

import com.ticker.model.User;
import com.ticker.repository.UserRepository;
import com.ticker.service.WatchlistService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.oauth2.client.userinfo.DefaultOAuth2UserService;
import org.springframework.security.oauth2.client.userinfo.OAuth2UserRequest;
import org.springframework.security.oauth2.core.OAuth2AuthenticationException;
import org.springframework.security.oauth2.core.user.OAuth2User;
import org.springframework.stereotype.Service;

import java.util.Map;

/**
 * 카카오 OAuth2 사용자 정보 로드 및 User 엔티티 생성/조회
 */
@Service
@RequiredArgsConstructor
public class CustomOAuth2UserService extends DefaultOAuth2UserService {

    private final UserRepository userRepository;
    private final WatchlistService watchlistService;

    @Override
    public OAuth2User loadUser(OAuth2UserRequest userRequest) throws OAuth2AuthenticationException {
        OAuth2User oauth2User = super.loadUser(userRequest);
        String provider = userRequest.getClientRegistration().getRegistrationId();
        Map<String, Object> attributes = oauth2User.getAttributes();

        if ("kakao".equals(provider)) {
            // 카카오 사용자 정보 추출
            String oauthId = String.valueOf(attributes.get("id"));
            String name = extractKakaoName(attributes);
            String email = extractKakaoEmail(attributes);
            String profileImageUrl = extractKakaoProfileImage(attributes);

            User user = userRepository.findByOauthProviderAndOauthId(provider, oauthId)
                    .orElseGet(() -> createKakaoUser(oauthId, name, email, profileImageUrl));

            // OAuth2User에 우리 User ID를 attributes에 추가 (SuccessHandler에서 사용)
            return new CustomOAuth2User(oauth2User, user.getId());
        }

        return oauth2User;
    }

    private User createKakaoUser(String oauthId, String name, String email, String profileImageUrl) {
        String loginId = "kakao_" + oauthId;
        if (userRepository.existsByLoginId(loginId)) {
            return userRepository.findByLoginId(loginId).orElseThrow();
        }

        User user = User.builder()
                .name(name != null && !name.isBlank() ? name : "카카오사용자")
                .loginId(loginId)
                .oauthProvider("kakao")
                .oauthId(oauthId)
                .profileImageUrl(profileImageUrl)
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L)   // 보유 자산 초기 10만원
                .marketCap(100_000L)     // 내 가치 초기 10만원
                .totalAssets(200_000L)   // 총 자산 = 보유 + 내 가치
                .stockPrice(1000L)       // 1주당 1000원
                .build();
        return userRepository.save(user);
    }

    @SuppressWarnings("unchecked")
    private String extractKakaoName(Map<String, Object> attributes) {
        Object kakaoAccount = attributes.get("kakao_account");
        if (kakaoAccount instanceof Map) {
            Map<String, Object> account = (Map<String, Object>) kakaoAccount;
            Object profile = account.get("profile");
            if (profile instanceof Map) {
                Object nickname = ((Map<String, Object>) profile).get("nickname");
                if (nickname != null) return nickname.toString();
            }
            Object name = account.get("name");
            if (name != null) return name.toString();
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    private String extractKakaoEmail(Map<String, Object> attributes) {
        Object kakaoAccount = attributes.get("kakao_account");
        if (kakaoAccount instanceof Map) {
            Object email = ((Map<String, Object>) kakaoAccount).get("email");
            if (email != null) return email.toString();
        }
        return null;
    }

    @SuppressWarnings("unchecked")
    private String extractKakaoProfileImage(Map<String, Object> attributes) {
        Object kakaoAccount = attributes.get("kakao_account");
        if (kakaoAccount instanceof Map) {
            Object profile = ((Map<String, Object>) kakaoAccount).get("profile");
            if (profile instanceof Map) {
                Object url = ((Map<String, Object>) profile).get("profile_image_url");
                if (url != null) return url.toString();
                Object thumb = ((Map<String, Object>) profile).get("thumbnail_image_url");
                if (thumb != null) return thumb.toString();
            }
        }
        return null;
    }
}
