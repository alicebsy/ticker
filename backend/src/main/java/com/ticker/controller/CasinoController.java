package com.ticker.controller;

import com.ticker.dto.BetRequest;
import com.ticker.dto.CasinoResponse;
import com.ticker.model.Bet;
import com.ticker.service.CasinoService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 카지노 API
 * 친구의 할 일 성공/실패에 베팅
 */
@RestController
@RequestMapping("/api/casino")
@RequiredArgsConstructor
public class CasinoController {

    private final CasinoService casinoService;

    /**
     * 카지노 화면 데이터 (베팅 가능 금액, 베팅 내역)
     */
    @GetMapping
    public ResponseEntity<CasinoResponse> getCasino(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(casinoService.getCasino(userId));
    }

    /**
     * 새 베팅 생성
     */
    @PostMapping("/bets")
    public ResponseEntity<Bet> placeBet(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody BetRequest request) {
        Bet bet = casinoService.placeBet(userId, request);
        return ResponseEntity.ok(bet);
    }
}
