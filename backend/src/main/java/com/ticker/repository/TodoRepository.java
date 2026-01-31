package com.ticker.repository;

import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * 할 일(종목) 레포지토리
 */
public interface TodoRepository extends JpaRepository<Todo, Long> {

    /** 사용자의 상장 중인 할 일 목록 */
    List<Todo> findByOwnerIdAndStatusOrderByCreatedAtDesc(Long ownerId, TodoStatus status);

    /** 사용자의 모든 할 일 (상장중만) */
    List<Todo> findByOwnerIdAndStatus(Long ownerId, TodoStatus status);
}
