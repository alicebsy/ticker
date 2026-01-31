package com.ticker.repository;

import com.ticker.model.StockPriceHistory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDate;
import java.util.List;

/**
 * 주가 이력 레포지토리 (내 주가 차트용)
 */
public interface StockPriceHistoryRepository extends JpaRepository<StockPriceHistory, Long> {

    @Query("SELECT s FROM StockPriceHistory s WHERE s.user.id = :userId AND s.recordDate >= :fromDate ORDER BY s.recordDate ASC")
    List<StockPriceHistory> findByUserIdAndRecordDateAfterOrderByRecordDateAsc(Long userId, LocalDate fromDate);
}
