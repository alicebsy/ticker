package com.ticker.repository;

import com.ticker.model.Friendship;
import com.ticker.model.Friendship.FriendshipStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;

/**
 * 친구 관계 레포지토리
 */
public interface FriendshipRepository extends JpaRepository<Friendship, Long> {

    /** 내가 보낸 대기중인 요청 */
    @Query("SELECT f FROM Friendship f JOIN FETCH f.addressee WHERE f.requester.id = :userId AND f.status = 'PENDING'")
    List<Friendship> findSentPendingByRequesterId(Long userId);

    /** 내가 받은 대기중인 요청 */
    @Query("SELECT f FROM Friendship f JOIN FETCH f.requester WHERE f.addressee.id = :userId AND f.status = 'PENDING'")
    List<Friendship> findReceivedPendingByAddresseeId(Long userId);

    /** 수락된 친구 목록 */
    @Query("SELECT f FROM Friendship f JOIN FETCH f.requester JOIN FETCH f.addressee " +
           "WHERE (f.requester.id = :userId OR f.addressee.id = :userId) AND f.status = 'ACCEPTED'")
    List<Friendship> findAcceptedFriendsByUserId(Long userId);

    Optional<Friendship> findByRequesterIdAndAddresseeId(Long requesterId, Long addresseeId);
}
