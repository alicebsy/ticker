package com.ticker.controller;

import com.ticker.dto.ActivityDto;
import com.ticker.dto.PortfolioResponse;
import com.ticker.service.ActivityService;
import com.ticker.service.PortfolioService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 포트폴리오 API
 * 총 자산, 투자 중 종목, 보유 스킬, 상장 폐지 내역, 활동 내역
 */
@RestController
@RequestMapping("/api/portfolio")
@RequiredArgsConstructor
public class PortfolioController {

    private final PortfolioService portfolioService;
    private final ActivityService activityService;

    /**
     * 내 포트폴리오 조회
     * @param userId 현재 로그인 사용자 ID (실제로는 인증에서 추출)
     */
    @GetMapping
    public ResponseEntity<PortfolioResponse> getPortfolio(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(portfolioService.getPortfolio(userId));
    }

    /**
     * 활동 내역 조회 (매수/매도/베팅/구매/상장 등, 최근 50건)
     */
    @GetMapping("/activities")
    public ResponseEntity<List<ActivityDto>> getActivities(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @RequestParam(defaultValue = "50") int limit) {
        return ResponseEntity.ok(activityService.getActivities(userId, limit));
    }
}
