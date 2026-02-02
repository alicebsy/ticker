package com.ticker.controller;

import com.ticker.model.Todo;
import com.ticker.model.TodoStatus;
import com.ticker.repository.TodoRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 할 일(종목) API
 * 친구의 상장 중인 종목 조회 (카지노 베팅용 등)
 */
@RestController
@RequestMapping("/api/todos")
@RequiredArgsConstructor
public class TodoController {

    private final TodoRepository todoRepository;

    /**
     * 특정 사용자(친구)의 상장 중인 할 일 목록
     * 카지노 "종목 선택" 드롭다운용
     */
    @GetMapping
    public ResponseEntity<List<Todo>> getListedTodos(
            @RequestParam(required = false) Long ownerId) {
        if (ownerId == null) {
            return ResponseEntity.ok(List.of());
        }
        return ResponseEntity.ok(todoRepository.findByOwnerIdAndStatus(ownerId, TodoStatus.LISTED));
    }

    /**
     * 할 일 상세 조회
     */
    @GetMapping("/{todoId}")
    public ResponseEntity<Todo> getTodo(@PathVariable Long todoId) {
        return todoRepository.findById(todoId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
