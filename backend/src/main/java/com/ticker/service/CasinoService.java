package com.ticker.service;

import com.ticker.dto.BetRequest;
import com.ticker.dto.CasinoResponse;
import com.ticker.model.Bet;
import com.ticker.model.BetStatus;
import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import com.ticker.model.User;
import com.ticker.repository.BetRepository;

import java.time.LocalDateTime;
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
    private final ActivityService activityService;

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
                    String friendName = b.getTodo().getOwner().getName();
                    String pred = b.getPredictSuccess() ? "성공 예측" : "실패 예측";
                    String prediction = pred + "·" + b.getAmount() + "P";
                    String typeStr = b.getPredictSuccess() ? "성공" : "실패";
                    String statusStr = switch (b.getStatus()) {
                        case IN_PROGRESS -> "진행 중";
                        case HIT -> "적중";
                        case MISS -> "실패";
                    };
                    String resultStr = switch (b.getStatus()) {
                        case IN_PROGRESS -> "pending";
                        case HIT -> "win";
                        case MISS -> "lose";
                    };
                    Long profitLoss = b.getProfitLoss();
                    if (profitLoss == null && b.getStatus() == BetStatus.IN_PROGRESS) {
                        profitLoss = 0L;
                    } else if (profitLoss == null) {
                        profitLoss = 0L;
                    }
                    return new CasinoResponse.BetHistoryDto(
                            b.getId(),
                            friendName,
                            friendName,
                            b.getTodo().getName(),
                            typeStr,
                            prediction,
                            b.getAmount(),
                            b.getPredictSuccess(),
                            resultStr,
                            statusStr,
                            profitLoss,
                            profitLoss,
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
     * friendUserId가 있으면 해당 친구의 첫 번째 LISTED 할 일에 베팅, 없으면 todoId로 베팅
     */
    @Transactional
    public Bet placeBet(Long userId, BetRequest request) {
        User bettor = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        Todo todo = resolveTodo(request);
        if (todo == null) {
            throw new IllegalArgumentException("베팅할 종목을 지정하세요 (todoId 또는 friendUserId)");
        }

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
        String typeStr = request.getPredictSuccess() ? "성공" : "실패";
        activityService.addActivity(userId, "BET", todo.getOwner().getName() + "에게 '" + typeStr + "' 베팅", request.getAmount());
        return saved;
    }

    /** friendUserId 우선 → 해당 친구의 첫 LISTED 할 일, 없으면 todoId로 조회 */
    private Todo resolveTodo(BetRequest request) {
        if (request.getFriendUserId() != null) {
            List<Todo> list = todoRepository.findByOwnerIdAndStatusOrderByCreatedAtDesc(request.getFriendUserId(), TodoStatus.LISTED);
            if (!list.isEmpty()) return list.get(0);
            throw new IllegalArgumentException("해당 친구에게 베팅 가능한 상장 중인 할 일이 없습니다");
        }
        if (request.getTodoId() != null) {
            return todoRepository.findById(request.getTodoId())
                    .orElseThrow(() -> new IllegalArgumentException("종목을 찾을 수 없습니다"));
        }
        return null;
    }

    /**
     * 할 일 완료/폐지 시 해당 Todo에 걸린 진행 중 베팅 정산
     * @param todoId 할 일 ID
     * @param success true=완료(성공), false=폐지(실패)
     */
    @Transactional
    public void settleBetsForTodo(Long todoId, boolean success) {
        List<Bet> bets = betRepository.findByTodo_IdAndStatus(todoId, BetStatus.IN_PROGRESS);
        for (Bet bet : bets) {
            boolean hit = (bet.getPredictSuccess() && success) || (!bet.getPredictSuccess() && !success);
            long profitLoss = hit ? bet.getAmount() + (bet.getAmount() / 2) : -bet.getAmount();
            bet.setStatus(hit ? BetStatus.HIT : BetStatus.MISS);
            bet.setProfitLoss(profitLoss);
            bet.setSettledAt(LocalDateTime.now());
            betRepository.save(bet);
            if (hit) {
                User bettor = bet.getBettor();
                bettor.setCashBalance(bettor.getCashBalance() + bet.getAmount() + (bet.getAmount() / 2));
                userRepository.save(bettor);
            }
        }
    }
}
