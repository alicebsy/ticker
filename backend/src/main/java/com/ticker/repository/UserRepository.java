package com.ticker.repository;

import com.ticker.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

/**
 * 사용자 레포지토리
 */
public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByLoginId(String loginId);

    Optional<User> findByOauthProviderAndOauthId(String provider, String oauthId);

    Optional<User> findByFriendCode(String friendCode);

    boolean existsByLoginId(String loginId);

    boolean existsByFriendCode(String friendCode);
}
