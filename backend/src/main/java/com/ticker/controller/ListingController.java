package com.ticker.controller;

import com.ticker.dto.ListingRequest;
import com.ticker.dto.ListingResponse;
import com.ticker.model.Todo;
import com.ticker.service.ListingService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 상장(Listing) API
 * 신규 상장(할 일 등록), 내 주가 차트, 상장 중인 종목
 */
@RestController
@RequestMapping("/api/listing")
@RequiredArgsConstructor
public class ListingController {

    private final ListingService listingService;

    /**
     * 상장 화면 데이터 (차트 + 상장 중 종목)
     * @param period 1D, 7D, 1M
     */
    @GetMapping
    public ResponseEntity<ListingResponse> getListing(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @RequestParam(defaultValue = "7D") String period) {
        return ResponseEntity.ok(listingService.getListing(userId, period));
    }

    /**
     * 신규 상장 - 할 일 등록
     */
    @PostMapping
    public ResponseEntity<Todo> createTodo(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody ListingRequest request) {
        Todo todo = listingService.createTodo(userId, request);
        return ResponseEntity.ok(todo);
    }

    /**
     * 할 일 완료 (매도/완료)
     */
    @PostMapping("/{todoId}/complete")
    public ResponseEntity<Void> completeTodo(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long todoId) {
        listingService.completeTodo(todoId, userId);
        return ResponseEntity.ok().build();
    }

    /**
     * 할 일 진행률 업데이트
     */
    @PatchMapping("/{todoId}/progress")
    public ResponseEntity<Void> updateProgress(
            @PathVariable Long todoId,
            @RequestParam Integer progress) {
        listingService.updateProgress(todoId, progress);
        return ResponseEntity.ok().build();
    }
}
