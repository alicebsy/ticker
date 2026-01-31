package com.ticker.controller;

import com.ticker.dto.PortfolioResponse;
import com.ticker.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * 포트폴리오 API
 * 총 자산, 투자 중 종목, 보유 스킬, 상장 폐지 내역
 */
@RestController
@RequestMapping("/api/portfolio")
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;

    /**
     * 내 포트폴리오 조회
     * @param userId 현재 로그인 사용자 ID (실제로는 인증에서 추출)
     */
    @GetMapping
    public ResponseEntity<PortfolioResponse> getPortfolio(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(portfolioService.getPortfolio(userId));
    }
}
