package com.ticker.service;

import com.ticker.dto.WatchlistResponse;
import com.ticker.model.Friendship;
import com.ticker.model.User;
import com.ticker.model.Watchlist;
import com.ticker.repository.FriendshipRepository;
import com.ticker.repository.UserRepository;
import com.ticker.repository.WatchlistRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * 관심 종목(Watchlist) 서비스
 * 친구 추가, 대기 중인 요청, 관심 종목 목록
 */
@Service
@RequiredArgsConstructor
public class WatchlistService {

    private final WatchlistRepository watchlistRepository;
    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;

    /**
     * 관심 종목 화면 데이터 조회
     */
    @Transactional(readOnly = true)
    public WatchlistResponse getWatchlist(Long userId) {
        List<Friendship> sent = friendshipRepository.findSentPendingByRequesterId(userId);
        List<Friendship> received = friendshipRepository.findReceivedPendingByAddresseeId(userId);

        List<WatchlistResponse.FriendRequestDto> sentDtos = sent.stream()
                .map(f -> new WatchlistResponse.FriendRequestDto(
                        f.getAddressee().getId(),
                        f.getAddressee().getName(),
                        f.getAddressee().getProfileImageUrl(),
                        "요청 보냄"
                ))
                .collect(Collectors.toList());

        List<WatchlistResponse.FriendRequestDto> receivedDtos = received.stream()
                .map(f -> new WatchlistResponse.FriendRequestDto(
                        f.getRequester().getId(),
                        f.getRequester().getName(),
                        f.getRequester().getProfileImageUrl(),
                        "대기중"  // 수락/거절 버튼용
                ))
                .collect(Collectors.toList());

        List<Watchlist> watchlists = watchlistRepository.findByUserIdWithWatchedUser(userId);
        List<WatchlistResponse.WatchlistItemDto> items = watchlists.stream()
                .map(w -> {
                    User watched = w.getWatchedUser();
                    String change = String.format("%+.2f%%", 3.5);  // 샘플, 실제로는 전일 대비
                    List<Long> chartData = List.of(9500L, 9600L, 9700L, 9800L, 9800L);  // 샘플
                    return new WatchlistResponse.WatchlistItemDto(
                            watched.getId(),
                            watched.getName(),
                            watched.getProfileImageUrl(),
                            watched.getStockPrice(),
                            change,
                            chartData
                    );
                })
                .collect(Collectors.toList());

        return WatchlistResponse.builder()
                .sentRequests(sentDtos)
                .receivedRequests(receivedDtos)
                .watchlistItems(items)
                .build();
    }

    /**
     * 친구 추가 요청
     */
    @Transactional
    public void addFriendRequest(Long requesterId, Long friendUserId) {
        if (requesterId.equals(friendUserId)) {
            throw new IllegalArgumentException("본인에게 친구 요청을 할 수 없습니다");
        }
        User addressee = userRepository.findById(friendUserId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        User requester = userRepository.findById(requesterId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        if (friendshipRepository.findByRequesterIdAndAddresseeId(requesterId, friendUserId).isPresent()
                || friendshipRepository.findByRequesterIdAndAddresseeId(friendUserId, requesterId).isPresent()) {
            throw new IllegalArgumentException("이미 친구이거나 요청이 있습니다");
        }

        Friendship friendship = Friendship.builder()
                .requester(requester)
                .addressee(addressee)
                .status(Friendship.FriendshipStatus.PENDING)
                .build();
        friendshipRepository.save(friendship);
    }

    /**
     * 친구 요청 수락
     */
    @Transactional
    public void acceptFriendRequest(Long userId, Long requesterId) {
        Friendship f = friendshipRepository.findByRequesterIdAndAddresseeId(requesterId, userId)
                .orElseThrow(() -> new IllegalArgumentException("요청을 찾을 수 없습니다"));
        f.setStatus(Friendship.FriendshipStatus.ACCEPTED);
        friendshipRepository.save(f);
    }

    /**
     * 친구 요청 거절
     */
    @Transactional
    public void rejectFriendRequest(Long userId, Long requesterId) {
        Friendship f = friendshipRepository.findByRequesterIdAndAddresseeId(requesterId, userId)
                .orElseThrow(() -> new IllegalArgumentException("요청을 찾을 수 없습니다"));
        f.setStatus(Friendship.FriendshipStatus.REJECTED);
        friendshipRepository.save(f);
    }

    /**
     * 내 친구 목록 (수락된 친구만)
     */
    @Transactional(readOnly = true)
    public List<User> getFriends(Long userId) {
        List<Friendship> friendships = friendshipRepository.findAcceptedFriendsByUserId(userId);
        List<User> friends = new ArrayList<>();
        for (Friendship f : friendships) {
            if (f.getRequester().getId().equals(userId)) {
                friends.add(f.getAddressee());
            } else {
                friends.add(f.getRequester());
            }
        }
        return friends;
    }

    /**
     * 관심 종목에 추가
     */
    @Transactional
    public void addToWatchlist(Long userId, Long watchedUserId) {
        if (watchlistRepository.existsByUserIdAndWatchedUserId(userId, watchedUserId)) {
            throw new IllegalArgumentException("이미 관심 종목에 있습니다");
        }
        User user = userRepository.findById(userId).orElseThrow();
        User watched = userRepository.findById(watchedUserId).orElseThrow();
        Watchlist w = Watchlist.builder().user(user).watchedUser(watched).build();
        watchlistRepository.save(w);
    }
}
