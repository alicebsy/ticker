package com.ticker.repository;

import com.ticker.model.UserSkill;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 사용자 보유 스킬 레포지토리
 */
public interface UserSkillRepository extends JpaRepository<UserSkill, Long> {

    @Query("SELECT us FROM UserSkill us JOIN FETCH us.marketItem WHERE us.user.id = :userId")
    List<UserSkill> findByUserIdWithMarketItem(Long userId);

    Optional<UserSkill> findByUserIdAndMarketItemId(Long userId, Long marketItemId);
}
