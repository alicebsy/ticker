package com.ticker.service;

import com.ticker.dto.BetRequest;
import com.ticker.dto.CasinoResponse;
import com.ticker.model.Bet;
import com.ticker.model.BetStatus;
import com.ticker.model.Todo;
import com.ticker.model.User;
import com.ticker.repository.BetRepository;
import com.ticker.repository.TodoRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 카지노 서비스
 * 친구의 할 일 성공/실패에 베팅
 */
@Service
@RequiredArgsConstructor
public class CasinoService {

    private final BetRepository betRepository;
    private final TodoRepository todoRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    /**
     * 카지노 화면 데이터 (베팅 가능 금액, 베팅 내역)
     */
    @Transactional(readOnly = true)
    public CasinoResponse getCasino(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        List<Bet> bets = betRepository.findByBettorIdWithTodoAndOwner(userId);
        List<CasinoResponse.BetHistoryDto> dtos = bets.stream()
                .map(b -> {
                    String pred = b.getPredictSuccess() ? "성공 예측" : "실패 예측";
                    String prediction = pred + "·" + b.getAmount() + "P";
                    String statusStr = switch (b.getStatus()) {
                        case IN_PROGRESS -> "진행 중";
                        case HIT -> "적중";
                        case MISS -> "실패";
                    };
                    Long profitLoss = b.getProfitLoss();
                    if (profitLoss == null && b.getStatus() == BetStatus.IN_PROGRESS) {
                        profitLoss = b.getPredictSuccess() ? b.getAmount() + (b.getAmount() / 2) : -b.getAmount();
                    }
                    return new CasinoResponse.BetHistoryDto(
                            b.getId(),
                            b.getTodo().getOwner().getName(),
                            b.getTodo().getName(),
                            prediction,
                            b.getAmount(),
                            b.getPredictSuccess(),
                            statusStr,
                            profitLoss != null ? profitLoss : 0L,
                            b.getStatus() == BetStatus.IN_PROGRESS
                    );
                })
                .collect(Collectors.toList());

        return CasinoResponse.builder()
                .bettingBalance(user.getCashBalance())
                .betHistory(dtos)
                .build();
    }

    /**
     * 새 베팅 생성
     */
    @Transactional
    public Bet placeBet(Long userId, BetRequest request) {
        User bettor = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        Todo todo = todoRepository.findById(request.getTodoId())
                .orElseThrow(() -> new IllegalArgumentException("종목을 찾을 수 없습니다"));

        if (bettor.getCashBalance() < request.getAmount()) {
            throw new IllegalArgumentException("베팅 가능 금액이 부족합니다");
        }

        bettor.setCashBalance(bettor.getCashBalance() - request.getAmount());
        userRepository.save(bettor);

        Bet bet = Bet.builder()
                .bettor(bettor)
                .todo(todo)
                .amount(request.getAmount())
                .predictSuccess(request.getPredictSuccess())
                .status(BetStatus.IN_PROGRESS)
                .build();
        Bet saved = betRepository.save(bet);
        notificationService.notifyBetPlaced(todo.getOwner(), bettor, todo);
        return saved;
    }
}
