package com.ticker.service;

import com.ticker.dto.NewsCommentDto;
import com.ticker.dto.NotificationDto;
import com.ticker.model.User;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Objects;

/**
 * WebSocket 실시간 알림 발송
 * 특정 유저에게 /topic/user/{userId}/notifications 로 전송
 */
@Service
@RequiredArgsConstructor
public class NotificationService {

    private static final String USER_TOPIC_PREFIX = "/topic/user/";
    private static final String NOTIFICATIONS_SUFFIX = "/notifications";
    private static final DateTimeFormatter FORMAT = DateTimeFormatter.ISO_LOCAL_DATE_TIME;

    private final SimpMessagingTemplate messagingTemplate;

    /**
     * 특정 유저에게 알림 전송
     * 클라이언트는 /topic/user/{userId}/notifications 구독
     */
    public void sendToUser(Long userId, NotificationDto notification) {
        if (notification.getTimestamp() == null) {
            notification.setTimestamp(LocalDateTime.now().format(FORMAT));
        }
        String destination = USER_TOPIC_PREFIX + userId + NOTIFICATIONS_SUFFIX;
        messagingTemplate.convertAndSend(destination, notification);
    }

    /** 친구 요청 알림 (요청 받은 사람에게) */
    public void notifyFriendRequest(User addressee, User requester) {
        String name = Objects.requireNonNullElse(requester.getName(), "알 수 없음");
        sendToUser(addressee.getId(), NotificationDto.builder()
                .type(NotificationDto.TYPE_FRIEND_REQUEST)
                .message(name + "님이 친구 요청을 보냈습니다.")
                .fromUserId(requester.getId())
                .fromUserName(name)
                .fromUserImageUrl(requester.getProfileImageUrl())
                .build());
    }

    /** 친구 수락 알림 (요청 보낸 사람에게) */
    public void notifyFriendAccepted(User requester, User accepter) {
        String name = Objects.requireNonNullElse(accepter.getName(), "알 수 없음");
        sendToUser(requester.getId(), NotificationDto.builder()
                .type(NotificationDto.TYPE_FRIEND_ACCEPTED)
                .message(name + "님이 친구 요청을 수락했습니다.")
                .fromUserId(accepter.getId())
                .fromUserName(name)
                .fromUserImageUrl(accepter.getProfileImageUrl())
                .build());
    }

    /** 친구 거절 알림 (요청 보낸 사람에게) */
    public void notifyFriendRejected(User requester, User rejecter) {
        String name = Objects.requireNonNullElse(rejecter.getName(), "알 수 없음");
        sendToUser(requester.getId(), NotificationDto.builder()
                .type(NotificationDto.TYPE_FRIEND_REJECTED)
                .message(name + "님이 친구 요청을 거절했습니다.")
                .fromUserId(rejecter.getId())
                .fromUserName(name)
                .fromUserImageUrl(rejecter.getProfileImageUrl())
                .build());
    }

    private static final String STOCK_TOPIC_PREFIX = "/topic/stock/";

    /**
     * 주가 변동 알림 (해당 유저 주가를 보고 있는 모든 클라이언트에 실시간 반영)
     * 구독: /topic/stock/{userId}
     */
    public void sendStockPriceUpdate(User user) {
        NotificationDto dto = NotificationDto.builder()
                .type(NotificationDto.TYPE_STOCK_PRICE_UPDATED)
                .message("주가가 변동되었습니다.")
                .userId(user.getId())
                .stockPrice(user.getStockPrice())
                .marketCap(user.getMarketCap())
                .totalAssets(user.getTotalAssets())
                .timestamp(LocalDateTime.now().format(FORMAT))
                .build();
        messagingTemplate.convertAndSend(STOCK_TOPIC_PREFIX + user.getId(), dto);
    }

    /**
     * 상장/할 일 변동 알림 (완료 체크, 진행률 변경 → 그래프·목록 실시간 반영)
     * 구독: /topic/stock/{ownerUserId}
     */
    public void sendListingUpdate(Long ownerUserId, Long todoId, Integer progress, boolean completed) {
        NotificationDto dto = NotificationDto.builder()
                .type(NotificationDto.TYPE_LISTING_UPDATED)
                .message(completed ? "할 일이 완료되었습니다." : "진행률이 업데이트되었습니다.")
                .userId(ownerUserId)
                .todoId(todoId)
                .progress(progress)
                .completed(completed)
                .timestamp(LocalDateTime.now().format(FORMAT))
                .build();
        messagingTemplate.convertAndSend(STOCK_TOPIC_PREFIX + ownerUserId, dto);
    }

    /**
     * 내 주식 매수/매도 발생 (해당 유저 주가 화면 보고 있는 사람들 실시간 반영)
     * 구독: /topic/stock/{subjectUserId}
     */
    public void sendInvestmentChange(Long subjectUserId, String message, Integer remainingShares) {
        NotificationDto dto = NotificationDto.builder()
                .type(NotificationDto.TYPE_INVESTMENT_CHANGED)
                .message(message != null ? message : "주식 거래가 있었습니다.")
                .userId(subjectUserId)
                .remainingShares(remainingShares)
                .timestamp(LocalDateTime.now().format(FORMAT))
                .build();
        messagingTemplate.convertAndSend(STOCK_TOPIC_PREFIX + subjectUserId, dto);
    }

    /** 내 할 일에 누가 베팅함 (할 일 소유자에게) */
    public void notifyBetPlaced(User todoOwner, User bettor, com.ticker.model.Todo todo) {
        String bettorName = Objects.requireNonNullElse(bettor.getName(), "알 수 없음");
        String todoName = Objects.requireNonNullElse(todo.getName(), "할 일");
        sendToUser(todoOwner.getId(), NotificationDto.builder()
                .type(NotificationDto.TYPE_BET_PLACED)
                .message(bettorName + "님이 '" + todoName + "'에 베팅했습니다.")
                .fromUserId(bettor.getId())
                .fromUserName(bettorName)
                .fromUserImageUrl(bettor.getProfileImageUrl())
                .todoId(todo.getId())
                .build());
    }

    /** 나를 관심 종목에 추가함 (추가당한 사람에게) */
    public void notifyAddedToWatchlist(User watchedUser, User whoAdded) {
        String name = Objects.requireNonNullElse(whoAdded.getName(), "알 수 없음");
        sendToUser(watchedUser.getId(), NotificationDto.builder()
                .type(NotificationDto.TYPE_ADDED_TO_WATCHLIST)
                .message(name + "님이 당신을 관심 종목에 추가했습니다.")
                .fromUserId(whoAdded.getId())
                .fromUserName(name)
                .fromUserImageUrl(whoAdded.getProfileImageUrl())
                .build());
    }

    private static final String NEWS_COMMENTS_TOPIC_PREFIX = "/topic/news/";
    private static final String NEWS_COMMENTS_TOPIC_SUFFIX = "/comments";

    /**
     * 뉴스 댓글 실시간 브로드캐스트 (해당 글 상세 보는 모든 클라이언트에 반영)
     * 구독: /topic/news/{postId}/comments
     */
    public void broadcastNewsComment(Long postId, NewsCommentDto comment) {
        String destination = NEWS_COMMENTS_TOPIC_PREFIX + postId + NEWS_COMMENTS_TOPIC_SUFFIX;
        messagingTemplate.convertAndSend(destination, comment);
    }
}
