package com.ticker.controller;

import com.ticker.model.User;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 사용자 API
 * 검색, 프로필 조회 (친구 추가 시 검색용)
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

        private final UserRepository userRepository;

        /**
         * 친구 검색 (이름 또는 ID)
         */
        @GetMapping("/search")
        public ResponseEntity<List<User>> search(
                        @RequestParam String q) {
                String query = q.trim();
                System.out.println("🔍 Searching users with query: " + query);
                List<User> users = userRepository.findAll().stream()
                                .filter(u -> u.getName().toLowerCase().contains(query.toLowerCase())
                                                || u.getLoginId().toLowerCase().contains(query.toLowerCase())
                                                || (u.getFriendCode() != null
                                                                && u.getFriendCode().equalsIgnoreCase(query)))
                                .limit(20)
                                .toList();
                return ResponseEntity.ok(users);
        }

        /**
         * 사용자 프로필 조회
         */
        @GetMapping("/{userId}")
        public ResponseEntity<User> getUser(@PathVariable Long userId) {
                return userRepository.findById(userId)
                                .map(ResponseEntity::ok)
                                .orElse(ResponseEntity.notFound().build());
        }
}
