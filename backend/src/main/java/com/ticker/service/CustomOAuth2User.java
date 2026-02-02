package com.ticker.service;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.oauth2.core.user.OAuth2User;

import java.util.Collection;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * OAuth2User 확장 - 우리 서비스 User ID 포함
 */
public class CustomOAuth2User implements OAuth2User {

    private final OAuth2User oauth2User;
    private final Long userId;

    public CustomOAuth2User(OAuth2User oauth2User, Long userId) {
        this.oauth2User = oauth2User;
        this.userId = userId;
    }

    public Long getUserId() {
        return userId;
    }

    @Override
    public Map<String, Object> getAttributes() {
        return oauth2User.getAttributes();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return oauth2User.getAuthorities();
    }

    @Override
    public String getName() {
        return oauth2User.getName();
    }
}
