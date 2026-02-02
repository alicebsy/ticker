package com.ticker.repository;

import com.ticker.model.Bet;
import com.ticker.model.BetStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * 베팅 레포지토리
 */
public interface BetRepository extends JpaRepository<Bet, Long> {

    @Query("SELECT b FROM Bet b JOIN FETCH b.todo t JOIN FETCH t.owner WHERE b.bettor.id = :bettorId ORDER BY b.createdAt DESC")
    List<Bet> findByBettorIdWithTodoAndOwner(Long bettorId);

    List<Bet> findByBettorIdAndStatus(Long bettorId, BetStatus status);
}
