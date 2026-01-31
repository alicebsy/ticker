package com.ticker.controller;

import com.ticker.dto.DarkMarketResponse;
import com.ticker.dto.PurchaseRequest;
import com.ticker.service.DarkMarketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 암시장 API
 * 스킬/아이콘/특수아이템 구매
 */
@RestController
@RequestMapping("/api/darkmarket")
@RequiredArgsConstructor
public class DarkMarketController {

    private final DarkMarketService darkMarketService;

    /**
     * 암시장 화면 데이터 (아이템 목록 + 오늘의 특가)
     */
    @GetMapping
    public ResponseEntity<DarkMarketResponse> getDarkMarket(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(darkMarketService.getDarkMarket(userId));
    }

    /**
     * 아이템 구매
     */
    @PostMapping("/purchase")
    public ResponseEntity<Void> purchase(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody PurchaseRequest request) {
        darkMarketService.purchase(userId, request);
        return ResponseEntity.ok().build();
    }
}
