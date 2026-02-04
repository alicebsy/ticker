package com.ticker.config;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.Map;

/**
 * 전역 예외 처리
 * API 에러 응답 일관성 유지
 */
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(IllegalArgumentException.class)
    public ResponseEntity<Map<String, String>> handleBadRequest(IllegalArgumentException e) {
        return ResponseEntity
                .status(HttpStatus.BAD_REQUEST)
                .body(Map.of("message", e.getMessage()));
    }

    @ExceptionHandler(org.springframework.dao.DataIntegrityViolationException.class)
    public ResponseEntity<Map<String, String>> handleIntegrityViolation(
            org.springframework.dao.DataIntegrityViolationException e) {
        e.printStackTrace();
        String message = "데이터 무결성 오류가 발생했습니다.";
        String rootMsg = e.getMostSpecificCause().getMessage();
        System.err.println("[DataIntegrityViolation] Root cause: " + rootMsg);
        if (rootMsg != null) {
            if (rootMsg.contains("LOGIN_ID") || rootMsg.contains("loginId") || rootMsg.contains("login_id")) {
                message = "이미 사용 중인 아이디입니다.";
            } else if (rootMsg.contains("FRIEND_CODE") || rootMsg.contains("friendCode") || rootMsg.contains("friend_code")) {
                message = "이미 사용 중인 친구 코드입니다.";
            } else if (rootMsg.contains("NICKNAME") || rootMsg.contains("nickname")) {
                message = "이미 사용 중인 닉네임입니다.";
            }
        }
        return ResponseEntity
                .status(HttpStatus.CONFLICT)
                .body(Map.of("message", message));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneric(Exception e) {
        e.printStackTrace(); // Log the error
        return ResponseEntity
                .status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("message", "서버 오류: " + e.getMessage()));
    }
}
