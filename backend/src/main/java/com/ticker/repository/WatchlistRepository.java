package com.ticker.repository;

import com.ticker.model.Watchlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 관심 종목 레포지토리
 */
public interface WatchlistRepository extends JpaRepository<Watchlist, Long> {

    @Query("SELECT w FROM Watchlist w JOIN FETCH w.watchedUser WHERE w.user.id = :userId")
    List<Watchlist> findByUserIdWithWatchedUser(Long userId);

    Optional<Watchlist> findByUserIdAndWatchedUserId(Long userId, Long watchedUserId);

    boolean existsByUserIdAndWatchedUserId(Long userId, Long watchedUserId);
}
