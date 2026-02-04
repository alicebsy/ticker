package com.ticker.controller;

import com.ticker.dto.ListingRequest;
import com.ticker.dto.ListingResponse;
import com.ticker.model.Todo;
import com.ticker.service.ListingService;
import com.ticker.service.StockPriceUpdateService;
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
    private final StockPriceUpdateService stockPriceUpdateService;

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
     * 다른 유저(친구)의 상장 화면 데이터 조회
     * 친구 프로필에서 투두 항목 + 주가 변동률을 보기 위한 엔드포인트
     */
    @GetMapping("/user/{targetUserId}")
    public ResponseEntity<ListingResponse> getUserListing(
            @PathVariable Long targetUserId,
            @RequestParam(defaultValue = "7D") String period) {
        return ResponseEntity.ok(listingService.getListing(targetUserId, period));
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
     * 할 일 완료 취소 (다시 상장 중으로 복원)
     */
    @PostMapping("/{todoId}/uncomplete")
    public ResponseEntity<Void> uncompleteTodo(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long todoId) {
        listingService.uncompleteTodo(todoId, userId);
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

    /**
     * 일일 주가 갱신 (성공률 반영)
     * 오늘 투두 4개 이상 기준 완료율에 따라 한 사람 단위 주가 변동.
     * 스케줄러 10시 호출 또는 수동 트리거용.
     */
    @PostMapping("/daily-stock-update")
    public ResponseEntity<Void> runDailyStockUpdate() {
        stockPriceUpdateService.updateDailyStockPrices();
        return ResponseEntity.ok().build();
    }
}
