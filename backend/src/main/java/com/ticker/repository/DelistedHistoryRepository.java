package com.ticker.repository;

import com.ticker.model.DelistedHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * 상장 폐지 내역 레포지토리
 */
public interface DelistedHistoryRepository extends JpaRepository<DelistedHistory, Long> {

    @Query("SELECT d FROM DelistedHistory d JOIN FETCH d.todo WHERE d.user.id = :userId ORDER BY d.delistedDate DESC")
    List<DelistedHistory> findByUserIdWithTodoOrderByDelistedDateDesc(Long userId);
}
