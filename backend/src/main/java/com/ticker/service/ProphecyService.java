package com.ticker.service;

import com.ticker.dto.*;
import com.ticker.model.*;
import com.ticker.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 예언 서비스
 * - 예언 등록/조회/종료
 * - 예언 배팅/정산
 */
@Service
@RequiredArgsConstructor
public class ProphecyService {

    private final ProphecyRepository prophecyRepository;
    private final ProphecyBetRepository prophecyBetRepository;
    private final UserRepository userRepository;
    private final WatchlistRepository watchlistRepository;
    private final ActivityService activityService;

    // ==================== 예언 관리 ====================

    /**
     * 나의 예언 등록
     */
    @Transactional
    public ProphecyDto createProphecy(Long userId, CreateProphecyRequest request) {
        User owner = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        Prophecy prophecy = Prophecy.builder()
                .owner(owner)
                .content(request.getContent())
                .status(ProphecyStatus.OPEN)
                .successPool(0L)
                .failurePool(0L)
                .build();

        prophecy = prophecyRepository.save(prophecy);
        activityService.addActivity(userId, "PROPHECY", "예언 등록: " + request.getContent(), 0);

        return toDto(prophecy);
    }

    /**
     * 나의 예언 목록 조회
     */
    @Transactional(readOnly = true)
    public List<ProphecyDto> getMyProphecies(Long userId) {
        return prophecyRepository.findByOwnerIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 배팅 가능한 예언 목록 (친구들의 OPEN 상태 예언)
     */
    @Transactional(readOnly = true)
    public List<ProphecyDto> getBettableProphecies(Long userId) {
        // 친구 ID 목록 가져오기
        List<Long> friendIds = watchlistRepository.findByUserIdWithWatchedUser(userId)
                .stream()
                .map(w -> w.getWatchedUser().getId())
                .collect(Collectors.toList());

        if (friendIds.isEmpty()) {
            return List.of();
        }

        return prophecyRepository.findByOwnerIdInAndStatusWithOwner(friendIds, ProphecyStatus.OPEN)
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    /**
     * 예언 상세 조회
     */
    @Transactional(readOnly = true)
    public ProphecyDto getProphecy(Long prophecyId) {
        Prophecy prophecy = prophecyRepository.findByIdWithOwner(prophecyId)
                .orElseThrow(() -> new IllegalArgumentException("예언을 찾을 수 없습니다"));
        return toDto(prophecy);
    }

    /**
     * 예언 종료 및 정산 (수행자가 결과 입력)
     *
     * 정산 로직:
     * - 승리자에게 돌아갈 금액 = 본인 배팅금 + (상대측 배팅 총액 / 승리자 수)
     */
    @Transactional
    public ProphecyDto closeProphecy(Long userId, Long prophecyId, CloseProphecyRequest request) {
        Prophecy prophecy = prophecyRepository.findByIdWithOwner(prophecyId)
                .orElseThrow(() -> new IllegalArgumentException("예언을 찾을 수 없습니다"));

        if (!prophecy.getOwner().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 예언만 종료할 수 있습니다");
        }

        if (prophecy.getStatus() == ProphecyStatus.CLOSED) {
            throw new IllegalArgumentException("이미 종료된 예언입니다");
        }

        boolean success = request.getSuccess();
        prophecy.setStatus(ProphecyStatus.CLOSED);
        prophecy.setResult(success);
        prophecy.setClosedAt(LocalDateTime.now());

        // 정산 실행
        settleProphecyBets(prophecyId, success);

        prophecyRepository.save(prophecy);
        activityService.addActivity(userId, "PROPHECY",
                "예언 종료 (" + (success ? "성공" : "실패") + "): " + prophecy.getContent(), 0);

        return toDto(prophecy);
    }

    // ==================== 배팅 관리 ====================

    /**
     * 예언에 배팅하기
     */
    @Transactional
    public ProphecyBetDto placeBet(Long userId, ProphecyBetRequest request) {
        User bettor = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        Prophecy prophecy = prophecyRepository.findByIdWithOwner(request.getProphecyId())
                .orElseThrow(() -> new IllegalArgumentException("예언을 찾을 수 없습니다"));

        if (prophecy.getStatus() != ProphecyStatus.OPEN) {
            throw new IllegalArgumentException("이미 종료된 예언입니다");
        }

        if (prophecy.getOwner().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 예언에는 배팅할 수 없습니다");
        }

        if (bettor.getCashBalance() < request.getAmount()) {
            throw new IllegalArgumentException("잔액이 부족합니다. 보유: " + bettor.getCashBalance() + "P");
        }

        // 잔액 차감
        bettor.setCashBalance(bettor.getCashBalance() - request.getAmount());
        userRepository.save(bettor);

        // 예언 풀에 금액 추가
        if (request.getPredictSuccess()) {
            prophecy.setSuccessPool(prophecy.getSuccessPool() + request.getAmount());
        } else {
            prophecy.setFailurePool(prophecy.getFailurePool() + request.getAmount());
        }
        prophecyRepository.save(prophecy);

        // 배팅 생성
        ProphecyBet bet = ProphecyBet.builder()
                .bettor(bettor)
                .prophecy(prophecy)
                .amount(request.getAmount())
                .predictSuccess(request.getPredictSuccess())
                .status(BetStatus.IN_PROGRESS)
                .build();

        bet = prophecyBetRepository.save(bet);

        String predType = request.getPredictSuccess() ? "성공" : "실패";
        activityService.addActivity(userId, "BET",
                prophecy.getOwner().getName() + "의 예언에 '" + predType + "' 배팅", request.getAmount());

        return toBetDto(bet);
    }

    /**
     * 나의 예언 배팅 내역 조회
     */
    @Transactional(readOnly = true)
    public List<ProphecyBetDto> getMyProphecyBets(Long userId) {
        return prophecyBetRepository.findByBettorIdWithProphecyAndOwner(userId)
                .stream()
                .map(this::toBetDto)
                .collect(Collectors.toList());
    }

    // ==================== 정산 로직 ====================

    /**
     * 예언 배팅 정산
     *
     * 정산 공식:
     * - 승리 풀: 맞춘 쪽의 총 배팅액
     * - 패배 풀: 틀린 쪽의 총 배팅액
     * - 승리자 수: 맞춘 쪽 배팅자 수
     * - 각 승리자 수익 = 본인 배팅금 + (패배 풀 / 승리자 수)
     */
    private void settleProphecyBets(Long prophecyId, boolean success) {
        List<ProphecyBet> bets = prophecyBetRepository.findByProphecyIdAndStatus(prophecyId, BetStatus.IN_PROGRESS);

        if (bets.isEmpty()) return;

        // 승리자/패배자 분리
        List<ProphecyBet> winners = bets.stream()
                .filter(b -> b.getPredictSuccess() == success)
                .collect(Collectors.toList());

        List<ProphecyBet> losers = bets.stream()
                .filter(b -> b.getPredictSuccess() != success)
                .collect(Collectors.toList());

        // 패배 풀 계산
        long loserPool = losers.stream().mapToLong(ProphecyBet::getAmount).sum();

        // 승리자가 없으면 모두 패배 처리
        if (winners.isEmpty()) {
            for (ProphecyBet loser : losers) {
                loser.setStatus(BetStatus.MISS);
                loser.setProfitLoss(-loser.getAmount());
                loser.setSettledAt(LocalDateTime.now());
                prophecyBetRepository.save(loser);
            }
            return;
        }

        // 승리자에게 배분할 금액 = 패배 풀 / 승리자 수
        long bonusPerWinner = loserPool / winners.size();

        // 승리자 정산: 본인 배팅금 + 보너스
        for (ProphecyBet winner : winners) {
            long payout = winner.getAmount() + bonusPerWinner;
            winner.setStatus(BetStatus.HIT);
            winner.setProfitLoss(bonusPerWinner);  // 수익 = 보너스 금액
            winner.setSettledAt(LocalDateTime.now());
            prophecyBetRepository.save(winner);

            // 잔액에 지급
            User bettor = winner.getBettor();
            bettor.setCashBalance(bettor.getCashBalance() + payout);
            userRepository.save(bettor);
        }

        // 패배자 정산
        for (ProphecyBet loser : losers) {
            loser.setStatus(BetStatus.MISS);
            loser.setProfitLoss(-loser.getAmount());
            loser.setSettledAt(LocalDateTime.now());
            prophecyBetRepository.save(loser);
        }
    }

    // ==================== DTO 변환 ====================

    private ProphecyDto toDto(Prophecy p) {
        return ProphecyDto.builder()
                .id(p.getId())
                .ownerId(p.getOwner().getId())
                .ownerName(p.getOwner().getName())
                .content(p.getContent())
                .status(p.getStatus().name())
                .result(p.getResult())
                .successPool(p.getSuccessPool())
                .failurePool(p.getFailurePool())
                .totalPool(p.getTotalPool())
                .createdAt(p.getCreatedAt())
                .closedAt(p.getClosedAt())
                .build();
    }

    private ProphecyBetDto toBetDto(ProphecyBet b) {
        Prophecy p = b.getProphecy();
        return ProphecyBetDto.builder()
                .id(b.getId())
                .prophecyId(p.getId())
                .prophecyContent(p.getContent())
                .ownerId(p.getOwner().getId())
                .ownerName(p.getOwner().getName())
                .amount(b.getAmount())
                .predictSuccess(b.getPredictSuccess())
                .status(b.getStatus().name())
                .profitLoss(b.getProfitLoss())
                .createdAt(b.getCreatedAt())
                .settledAt(b.getSettledAt())
                .build();
    }
}
