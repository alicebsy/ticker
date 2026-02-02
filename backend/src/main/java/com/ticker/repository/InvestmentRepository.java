package com.ticker.repository;

import com.ticker.model.Investment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 투자 레포지토리
 */
public interface InvestmentRepository extends JpaRepository<Investment, Long> {

    /** 사용자의 모든 투자 (보유 종목) */
    @Query("SELECT i FROM Investment i JOIN FETCH i.todo t JOIN FETCH t.owner WHERE i.investor.id = :investorId")
    List<Investment> findByInvestorIdWithTodoAndOwner(Long investorId);

    Optional<Investment> findByInvestorIdAndTodoId(Long investorId, Long todoId);
}
