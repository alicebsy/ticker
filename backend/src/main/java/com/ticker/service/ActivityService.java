package com.ticker.service;

import com.ticker.dto.ActivityDto;
import com.ticker.model.Activity;
import com.ticker.model.User;
import com.ticker.repository.ActivityRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

/**
 * 활동 내역 서비스
 * 매수/매도/베팅/구매/상장 시 기록, 포트폴리오에서 조회
 */
@Service
@RequiredArgsConstructor
public class ActivityService {

    private final ActivityRepository activityRepository;
    private final UserRepository userRepository;

    /**
     * 활동 기록 (다른 서비스에서 호출)
     */
    @Transactional
    public void addActivity(Long userId, String type, String description, long amount) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        Activity activity = Activity.builder()
                .user(user)
                .type(type)
                .description(description)
                .amount(amount)
                .build();
        activityRepository.save(activity);
    }

    /**
     * 최근 활동 내역 조회 (최대 50건)
     */
    @Transactional(readOnly = true)
    public List<ActivityDto> getActivities(Long userId, int limit) {
        List<Activity> list = activityRepository.findByUserIdOrderByCreatedAtDesc(
                userId, PageRequest.of(0, Math.min(limit, 100)));
        return list.stream()
                .map(a -> ActivityDto.builder()
                        .id(a.getId())
                        .type(a.getType())
                        .description(a.getDescription())
                        .amount(a.getAmount())
                        .timestamp(a.getCreatedAt())
                        .build())
                .collect(Collectors.toList());
    }
}
