package com.ticker.service;

import com.ticker.dto.FriendRequest;
import com.ticker.dto.WatchlistResponse;
import com.ticker.model.Friendship;
import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import com.ticker.model.User;
import com.ticker.model.Watchlist;
import com.ticker.repository.FriendshipRepository;
import com.ticker.repository.InvestmentRepository;
import com.ticker.repository.TodoRepository;
import com.ticker.repository.UserRepository;
import com.ticker.repository.WatchlistRepository;
import com.ticker.util.FriendCodeGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;

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

    private static final int SELLABLE_SHARES_PER_USER = 30;

    private final WatchlistRepository watchlistRepository;
    private final FriendshipRepository friendshipRepository;
    private final UserRepository userRepository;
    private final TodoRepository todoRepository;
    private final InvestmentRepository investmentRepository;
    private final FriendCodeGenerator friendCodeGenerator;
    private final NotificationService notificationService;

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

        // ACCEPTED된 친구를 watchlistItems로 표시
        List<Friendship> acceptedFriends = friendshipRepository.findAcceptedFriendsByUserId(userId);
        List<WatchlistResponse.WatchlistItemDto> items = acceptedFriends.stream()
                .map(f -> {
                    // 친구 = 내가 requester면 addressee, 내가 addressee면 requester
                    User friend = f.getRequester().getId().equals(userId)
                            ? f.getAddressee() : f.getRequester();

                    // 오늘 투두 완성률 기반 실제 주가 변동폭 계산
                    LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
                    LocalDateTime endOfDay = LocalDate.now().plusDays(1).atStartOfDay();
                    List<Todo> friendTodos = todoRepository.findByOwnerIdAndCreatedAtToday(friend.getId(), startOfDay, endOfDay);

                    String change;
                    if (!friendTodos.isEmpty()) {
                        long completedCount = friendTodos.stream()
                                .filter(t -> t.getStatus() == TodoStatus.COMPLETED)
                                .count();
                        double ratio = (double) completedCount / friendTodos.size();
                        double changePct;
                        if (ratio >= 1.0) {
                            changePct = 12.5;
                        } else if (ratio >= 0.75) {
                            changePct = 5.0;
                        } else if (ratio >= 0.50) {
                            changePct = 0.0;
                        } else if (ratio >= 0.25) {
                            changePct = -10.0;
                        } else {
                            changePct = -20.0;
                        }
                        change = String.format("%+.2f%%", changePct);
                    } else {
                        change = "— 0.00%";
                    }

                    List<Long> chartData = List.of(
                            friend.getStockPrice(),
                            friend.getStockPrice()
                    );
                    // 매수 가능 잔여 주수 계산
                    long alreadySold = investmentRepository.sumQuantityBySubjectUserId(friend.getId());
                    int remainingShares = SELLABLE_SHARES_PER_USER - (int) alreadySold;

                    return new WatchlistResponse.WatchlistItemDto(
                            friend.getId(),
                            friend.getName(),
                            friend.getProfileImageUrl(),
                            friend.getStockPrice(),
                            change,
                            chartData,
                            remainingShares
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
     * 친구 추가 요청 (friendUserId 또는 friendCode 중 하나로 대상 지정)
     */
    @Transactional
    public void addFriendRequest(Long requesterId, FriendRequest request) {
        Long friendUserId = resolveFriendUserId(request);
        if (friendUserId == null) {
            throw new IllegalArgumentException("친구 ID 또는 친구 코드를 입력하세요");
        }
        addFriendRequestById(requesterId, friendUserId);
    }

    /**
     * 친구 ID로 친구 추가 요청 (내부용)
     */
    @Transactional
    public void addFriendRequestById(Long requesterId, Long friendUserId) {
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

        // 실시간 알림: 요청 받은 사람에게 소켓 발송
        notificationService.notifyFriendRequest(addressee, requester);
    }

    private Long resolveFriendUserId(FriendRequest request) {
        if (request.getFriendUserId() != null) {
            return request.getFriendUserId();
        }
        if (request.getFriendCode() != null && !request.getFriendCode().isBlank()) {
            return userRepository.findByFriendCode(request.getFriendCode().trim().toUpperCase())
                    .map(User::getId)
                    .orElseThrow(() -> new IllegalArgumentException("해당 친구 코드의 사용자를 찾을 수 없습니다"));
        }
        return null;
    }

    /**
     * 내 친구 코드 조회 (없으면 발급 후 반환)
     */
    @Transactional
    public String getOrCreateFriendCode(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        if (user.getFriendCode() != null && !user.getFriendCode().isBlank()) {
            return user.getFriendCode();
        }
        String code = generateUniqueFriendCode();
        user.setFriendCode(code);
        userRepository.save(user);
        return code;
    }

    /**
     * 친구 코드 재발급 (기존 코드 무효화)
     */
    @Transactional
    public String regenerateFriendCode(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        String code = generateUniqueFriendCode();
        user.setFriendCode(code);
        userRepository.save(user);
        return code;
    }

    /**
     * 신규 사용자 생성 시 호출. 유일한 친구 코드 생성 (DB에 아직 저장하지 않음)
     */
    @Transactional(readOnly = true)
    public String generateUniqueFriendCode() {
        for (int i = 0; i < 100; i++) {
            String code = friendCodeGenerator.generate();
            if (!userRepository.existsByFriendCode(code)) {
                return code;
            }
        }
        throw new IllegalStateException("친구 코드 발급에 실패했습니다. 다시 시도해 주세요.");
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

        // 실시간 알림: 요청 보낸 사람에게 수락 알림
        User requester = f.getRequester();
        User accepter = f.getAddressee();
        notificationService.notifyFriendAccepted(requester, accepter);
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

        // 실시간 알림: 요청 보낸 사람에게 거절 알림
        User requester = f.getRequester();
        User rejecter = f.getAddressee();
        notificationService.notifyFriendRejected(requester, rejecter);
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

        notificationService.notifyAddedToWatchlist(watched, user);
    }
}
