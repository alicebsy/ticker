package com.ticker.controller;

import com.ticker.dto.*;
import com.ticker.service.ProphecyService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 예언 API
 * - 예언 등록/조회/종료
 * - 예언 배팅
 */
@RestController
@RequestMapping("/api/prophecies")
@RequiredArgsConstructor
public class ProphecyController {

    private final ProphecyService prophecyService;

    // ==================== 예언 관리 ====================

    /**
     * 나의 예언 등록
     */
    @PostMapping
    public ResponseEntity<ProphecyDto> createProphecy(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody CreateProphecyRequest request) {
        return ResponseEntity.ok(prophecyService.createProphecy(userId, request));
    }

    /**
     * 나의 예언 목록
     */
    @GetMapping("/my")
    public ResponseEntity<List<ProphecyDto>> getMyProphecies(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(prophecyService.getMyProphecies(userId));
    }

    /**
     * 배팅 가능한 예언 목록 (친구들의 OPEN 예언)
     */
    @GetMapping("/bettable")
    public ResponseEntity<List<ProphecyDto>> getBettableProphecies(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(prophecyService.getBettableProphecies(userId));
    }

    /**
     * 예언 상세 조회
     */
    @GetMapping("/{prophecyId}")
    public ResponseEntity<ProphecyDto> getProphecy(@PathVariable Long prophecyId) {
        return ResponseEntity.ok(prophecyService.getProphecy(prophecyId));
    }

    /**
     * 예언 종료 (결과 입력 및 정산)
     */
    @PostMapping("/{prophecyId}/close")
    public ResponseEntity<ProphecyDto> closeProphecy(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long prophecyId,
            @Valid @RequestBody CloseProphecyRequest request) {
        return ResponseEntity.ok(prophecyService.closeProphecy(userId, prophecyId, request));
    }

    // ==================== 배팅 ====================

    /**
     * 예언에 배팅하기
     */
    @PostMapping("/bets")
    public ResponseEntity<ProphecyBetDto> placeBet(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody ProphecyBetRequest request) {
        return ResponseEntity.ok(prophecyService.placeBet(userId, request));
    }

    /**
     * 나의 예언 배팅 내역
     */
    @GetMapping("/bets/my")
    public ResponseEntity<List<ProphecyBetDto>> getMyProphecyBets(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId) {
        return ResponseEntity.ok(prophecyService.getMyProphecyBets(userId));
    }
}
