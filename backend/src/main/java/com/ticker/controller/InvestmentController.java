package com.ticker.controller;

import com.ticker.dto.HeldStocksResponse;
import com.ticker.dto.InvestRequest;
import com.ticker.model.Investment;
import com.ticker.service.InvestmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 투자(보유 종목) API
 * 매수, 매도, 보유 종목 조회
 */
@RestController
@RequestMapping("/api/investments")
@RequiredArgsConstructor
public class InvestmentController {

    private final InvestmentService investmentService;

    /**
     * 보유 종목 목록 조회
     */
    @GetMapping
    public ResponseEntity<HeldStocksResponse> getHeldStocks(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(investmentService.getHeldStocks(userId));
    }

    /**
     * 매수
     */
    @PostMapping("/buy")
    public ResponseEntity<Investment> buy(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody InvestRequest request) {
        Investment inv = investmentService.buy(userId, request);
        return ResponseEntity.ok(inv);
    }

    /**
     * 매도
     */
    @PostMapping("/{investmentId}/sell")
    public ResponseEntity<Void> sell(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long investmentId,
            @RequestParam(required = false) Integer quantity) {
        investmentService.sell(userId, investmentId, quantity);
        return ResponseEntity.ok().build();
    }
}
