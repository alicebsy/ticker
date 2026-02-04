package com.ticker.controller;

import com.ticker.dto.*;
import com.ticker.model.NewsCategory;
import com.ticker.service.NewsService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 뉴스(게시판) API
 * - 목록/상세/글작성/댓글작성/좋아요
 */
@RestController
@RequestMapping("/api/news")
@RequiredArgsConstructor
public class NewsController {

    private final NewsService newsService;

    /**
     * 뉴스 목록 (쿼리: category = FREE, ANALYSIS, TIP, DISCUSSION 중 하나, 없으면 전체)
     */
    @GetMapping
    public ResponseEntity<List<NewsPostDto>> getPosts(
            @RequestParam(required = false) NewsCategory category) {
        return ResponseEntity.ok(newsService.getPosts(category));
    }

    /**
     * 뉴스 상세 (댓글 포함)
     */
    @GetMapping("/{postId}")
    public ResponseEntity<NewsPostDto> getPostDetail(@PathVariable Long postId) {
        return newsService.getPostDetail(postId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 글 작성
     */
    @PostMapping
    public ResponseEntity<NewsPostDto> createPost(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @Valid @RequestBody CreateNewsPostRequest request) {
        return ResponseEntity.ok(newsService.createPost(userId, request));
    }

    /**
     * 댓글 작성
     */
    @PostMapping("/{postId}/comments")
    public ResponseEntity<NewsCommentDto> addComment(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long postId,
            @Valid @RequestBody CreateNewsCommentRequest request) {
        return ResponseEntity.ok(newsService.addComment(userId, postId, request));
    }

    /**
     * 좋아요
     */
    @PostMapping("/{postId}/like")
    public ResponseEntity<Void> likePost(@PathVariable Long postId) {
        newsService.likePost(postId);
        return ResponseEntity.noContent().build();
    }

    /**
     * 글 수정 (본인만)
     */
    @PutMapping("/{postId}")
    public ResponseEntity<NewsPostDto> updatePost(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long postId,
            @Valid @RequestBody UpdateNewsPostRequest request) {
        return ResponseEntity.ok(newsService.updatePost(userId, postId, request));
    }

    /**
     * 글 삭제 (본인만)
     */
    @DeleteMapping("/{postId}")
    public ResponseEntity<Map<String, String>> deletePost(
            @RequestHeader(value = "X-User-Id", defaultValue = "1") Long userId,
            @PathVariable Long postId) {
        newsService.deletePost(userId, postId);
        return ResponseEntity.ok(Map.of("message", "삭제되었습니다"));
    }
}
