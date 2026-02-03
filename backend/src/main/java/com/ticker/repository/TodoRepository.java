package com.ticker.repository;

import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 할 일(종목) 레포지토리
 */
public interface TodoRepository extends JpaRepository<Todo, Long> {

    /** 사용자의 상장 중인 할 일 목록 */
    List<Todo> findByOwnerIdAndStatusOrderByCreatedAtDesc(Long ownerId, TodoStatus status);

    /** 사용자의 모든 할 일 (상장중만) */
    List<Todo> findByOwnerIdAndStatus(Long ownerId, TodoStatus status);

    /** 오늘 작성한 할 일 (성공률 계산용: 자기가 쓴 오늘의 투두) */
    @Query("SELECT t FROM Todo t WHERE t.owner.id = :ownerId AND t.createdAt >= :startOfDay AND t.createdAt < :endOfDay")
    List<Todo> findByOwnerIdAndCreatedAtToday(Long ownerId, LocalDateTime startOfDay, LocalDateTime endOfDay);
}
