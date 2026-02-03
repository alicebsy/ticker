package com.ticker.repository;

import com.ticker.model.Activity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * 활동 내역 레포지토리
 */
public interface ActivityRepository extends JpaRepository<Activity, Long> {

    List<Activity> findByUserIdOrderByCreatedAtDesc(Long userId, org.springframework.data.domain.Pageable pageable);
}
