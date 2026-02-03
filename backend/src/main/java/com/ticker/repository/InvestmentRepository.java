package com.ticker.repository;

import com.ticker.model.Investment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 투자 레포지토리 (한 사람 주식 매수/매도)
 */
public interface InvestmentRepository extends JpaRepository<Investment, Long> {

    /** 사용자의 모든 투자 (보유 종목 = 산 사람들) */
    @Query("SELECT i FROM Investment i JOIN FETCH i.subjectUser WHERE i.investor.id = :investorId")
    List<Investment> findByInvestorIdWithSubjectUser(Long investorId);

    Optional<Investment> findByInvestorIdAndSubjectUserId(Long investorId, Long subjectUserId);

    /** 특정 유저에게 팔린 주식 수 합계 (30주 한도 체크용) */
    @Query("SELECT COALESCE(SUM(i.quantity), 0L) FROM Investment i WHERE i.subjectUser.id = :subjectUserId")
    long sumQuantityBySubjectUserId(Long subjectUserId);
}
