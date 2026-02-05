package com.ticker.repository;

import com.ticker.model.BetStatus;
import com.ticker.model.ProphecyBet;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * 예언 배팅 레포지토리
 */
public interface ProphecyBetRepository extends JpaRepository<ProphecyBet, Long> {

    /** 특정 예언에 대한 모든 배팅 */
    List<ProphecyBet> findByProphecyId(Long prophecyId);

    /** 특정 예언에 대한 진행 중인 배팅 */
    List<ProphecyBet> findByProphecyIdAndStatus(Long prophecyId, BetStatus status);

    /** 특정 사용자의 예언 배팅 내역 (최신순) */
    @Query("SELECT pb FROM ProphecyBet pb JOIN FETCH pb.prophecy p JOIN FETCH p.owner WHERE pb.bettor.id = :bettorId ORDER BY pb.createdAt DESC")
    List<ProphecyBet> findByBettorIdWithProphecyAndOwner(Long bettorId);

    /** 특정 예언에 성공 예측으로 건 배팅들 */
    List<ProphecyBet> findByProphecyIdAndPredictSuccessAndStatus(Long prophecyId, Boolean predictSuccess, BetStatus status);

    /** 특정 예언의 성공 배팅 총액 */
    @Query("SELECT COALESCE(SUM(pb.amount), 0) FROM ProphecyBet pb WHERE pb.prophecy.id = :prophecyId AND pb.predictSuccess = true AND pb.status = 'IN_PROGRESS'")
    Long sumSuccessPoolByProphecyId(Long prophecyId);

    /** 특정 예언의 실패 배팅 총액 */
    @Query("SELECT COALESCE(SUM(pb.amount), 0) FROM ProphecyBet pb WHERE pb.prophecy.id = :prophecyId AND pb.predictSuccess = false AND pb.status = 'IN_PROGRESS'")
    Long sumFailurePoolByProphecyId(Long prophecyId);
}
