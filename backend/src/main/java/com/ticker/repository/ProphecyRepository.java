package com.ticker.repository;

import com.ticker.model.Prophecy;
import com.ticker.model.ProphecyStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 예언 레포지토리
 */
public interface ProphecyRepository extends JpaRepository<Prophecy, Long> {

    /** 특정 사용자의 예언 목록 (최신순) */
    List<Prophecy> findByOwnerIdOrderByCreatedAtDesc(Long ownerId);

    /** 특정 사용자의 진행 중인 예언 */
    List<Prophecy> findByOwnerIdAndStatusOrderByCreatedAtDesc(Long ownerId, ProphecyStatus status);

    /** 진행 중인 모든 예언 (배팅 가능한 것들) */
    @Query("SELECT p FROM Prophecy p JOIN FETCH p.owner WHERE p.status = :status ORDER BY p.createdAt DESC")
    List<Prophecy> findAllByStatusWithOwner(ProphecyStatus status);

    /** 예언 상세 (소유자 정보 포함) */
    @Query("SELECT p FROM Prophecy p JOIN FETCH p.owner WHERE p.id = :id")
    Optional<Prophecy> findByIdWithOwner(Long id);

    /** 친구들의 진행 중인 예언 조회 */
    @Query("SELECT p FROM Prophecy p JOIN FETCH p.owner WHERE p.owner.id IN :friendIds AND p.status = :status ORDER BY p.createdAt DESC")
    List<Prophecy> findByOwnerIdInAndStatusWithOwner(List<Long> friendIds, ProphecyStatus status);
}
