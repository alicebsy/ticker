package com.ticker.util;

import org.springframework.stereotype.Component;

import java.security.SecureRandom;

/**
 * 친구 추가용 개별 인증 코드 랜덤 생성
 * 혼동 방지를 위해 0/O, 1/I 제외한 영숫자 8자리
 */
@Component
public class FriendCodeGenerator {

    private static final String CHARS = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private static final int LENGTH = 8;
    private final SecureRandom random = new SecureRandom();

    /**
     * 랜덤 8자리 친구 코드 생성 (유일성은 호출 측에서 DB로 검증)
     */
    public String generate() {
        StringBuilder sb = new StringBuilder(LENGTH);
        for (int i = 0; i < LENGTH; i++) {
            sb.append(CHARS.charAt(random.nextInt(CHARS.length())));
        }
        return sb.toString();
    }
}
