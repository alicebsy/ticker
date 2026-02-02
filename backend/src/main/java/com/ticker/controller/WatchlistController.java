package com.ticker.controller;

import com.ticker.dto.FriendRequest;
import com.ticker.dto.WatchlistResponse;
import com.ticker.model.User;
import com.ticker.service.WatchlistService;

import java.util.List;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 관심 종목(Watchlist) API
 * 친구 추가, 요청 수락/거절, 관심 종목 관리
 */
@RestController
@RequestMapping("/api/watchlist")
@RequiredArgsConstructor
public class WatchlistController {

    private final WatchlistService watchlistService;

    /**
     * 관심 종목 화면 데이터 (대기 요청 + 관심 종목 그리드)
     */
    @GetMapping
    public ResponseEntity<WatchlistResponse> getWatchlist(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(watchlistService.getWatchlist(userId));
    }

    /**
     * 내 친구 목록 (카지노 친구 선택 등)
     */
    @GetMapping("/friends")
    public ResponseEntity<List<User>> getFriends(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(watchlistService.getFriends(userId));
    }

    /**
     * 친구 추가 요청 (friendUserId 또는 friendCode로 대상 지정)
     */
    @PostMapping("/friends")
    public ResponseEntity<Void> addFriend(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody FriendRequest request) {
        watchlistService.addFriendRequest(userId, request);
        return ResponseEntity.ok().build();
    }

    /**
     * 내 친구 코드 조회 (없으면 자동 발급)
     */
    @GetMapping("/my-friend-code")
    public ResponseEntity<java.util.Map<String, String>> getMyFriendCode(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        String code = watchlistService.getOrCreateFriendCode(userId);
        return ResponseEntity.ok(java.util.Map.of("friendCode", code));
    }

    /**
     * 친구 코드 재발급 (기존 코드 무효화)
     */
    @PostMapping("/regenerate-friend-code")
    public ResponseEntity<java.util.Map<String, String>> regenerateFriendCode(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        String code = watchlistService.regenerateFriendCode(userId);
        return ResponseEntity.ok(java.util.Map.of("friendCode", code));
    }

    /**
     * 친구 요청 수락
     */
    @PostMapping("/friends/{requesterId}/accept")
    public ResponseEntity<Void> acceptFriend(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long requesterId) {
        watchlistService.acceptFriendRequest(userId, requesterId);
        return ResponseEntity.ok().build();
    }

    /**
     * 친구 요청 거절
     */
    @PostMapping("/friends/{requesterId}/reject")
    public ResponseEntity<Void> rejectFriend(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long requesterId) {
        watchlistService.rejectFriendRequest(userId, requesterId);
        return ResponseEntity.ok().build();
    }

    /**
     * 관심 종목에 추가
     */
    @PostMapping("/{watchedUserId}")
    public ResponseEntity<Void> addToWatchlist(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long watchedUserId) {
        watchlistService.addToWatchlist(userId, watchedUserId);
        return ResponseEntity.ok().build();
    }
}
