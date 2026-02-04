package com.ticker.service;

import com.ticker.dto.*;
import com.ticker.model.NewsCategory;
import com.ticker.model.NewsComment;
import com.ticker.model.NewsPost;
import com.ticker.model.User;
import com.ticker.repository.NewsCommentRepository;
import com.ticker.repository.NewsPostRepository;
import com.ticker.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 뉴스(게시판) 서비스
 */
@Service
@RequiredArgsConstructor
public class NewsService {

    private final NewsPostRepository newsPostRepository;
    private final NewsCommentRepository newsCommentRepository;
    private final UserRepository userRepository;

    /**
     * 뉴스 목록 조회 (카테고리 필터, 전체는 null)
     */
    @Transactional(readOnly = true)
    public List<NewsPostDto> getPosts(NewsCategory category) {
        List<NewsPost> posts = category == null
                ? newsPostRepository.findAllWithAuthorOrderByCreatedAtDesc()
                : newsPostRepository.findByCategoryWithAuthorOrderByCreatedAtDesc(category);
        return posts.stream()
                .map(p -> toListDto(p))
                .collect(Collectors.toList());
    }

    /**
     * 뉴스 상세 조회 (댓글 포함)
     */
    @Transactional(readOnly = true)
    public Optional<NewsPostDto> getPostDetail(Long postId) {
        return newsPostRepository.findByIdWithAuthor(postId)
                .map(p -> {
                    var comments = newsCommentRepository.findByPostIdWithAuthorOrderByCreatedAtAsc(postId);
                    return toDetailDto(p, comments);
                });
    }

    /**
     * 글 작성
     */
    @Transactional
    public NewsPostDto createPost(Long userId, CreateNewsPostRequest request) {
        User author = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        NewsPost post = NewsPost.builder()
                .author(author)
                .title(request.getTitle())
                .content(request.getContent())
                .category(request.getCategory())
                .anonymous(request.isAnonymous())
                .build();
        post = newsPostRepository.save(post);
        return toDetailDto(post, Collections.emptyList());
    }

    /**
     * 댓글 작성
     */
    @Transactional
    public NewsCommentDto addComment(Long userId, Long postId, CreateNewsCommentRequest request) {
        User author = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        NewsPost post = newsPostRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("글을 찾을 수 없습니다"));
        NewsComment comment = NewsComment.builder()
                .post(post)
                .author(author)
                .content(request.getContent())
                .build();
        comment = newsCommentRepository.save(comment);
        return toCommentDto(comment);
    }

    /**
     * 좋아요 (토글 또는 증가만 - 여기서는 단순 +1)
     */
    @Transactional
    public void likePost(Long postId) {
        NewsPost post = newsPostRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("글을 찾을 수 없습니다"));
        post.setLikes(post.getLikes() + 1);
        newsPostRepository.save(post);
    }

    /**
     * 글 수정 (작성자만)
     */
    @Transactional
    public NewsPostDto updatePost(Long userId, Long postId, UpdateNewsPostRequest request) {
        NewsPost post = newsPostRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("글을 찾을 수 없습니다"));
        if (!post.getAuthor().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 글만 수정할 수 있습니다");
        }
        post.setTitle(request.getTitle());
        post.setContent(request.getContent());
        post.setCategory(request.getCategory());
        post.setAnonymous(request.isAnonymous());
        post = newsPostRepository.save(post);
        var comments = newsCommentRepository.findByPostIdWithAuthorOrderByCreatedAtAsc(postId);
        return toDetailDto(post, comments);
    }

    /**
     * 글 삭제 (작성자만)
     */
    @Transactional
    public void deletePost(Long userId, Long postId) {
        NewsPost post = newsPostRepository.findById(postId)
                .orElseThrow(() -> new IllegalArgumentException("글을 찾을 수 없습니다"));
        if (!post.getAuthor().getId().equals(userId)) {
            throw new IllegalArgumentException("본인의 글만 삭제할 수 있습니다");
        }
        newsPostRepository.delete(post);
    }

    private NewsPostDto toListDto(NewsPost p) {
        int commentCount = (int) newsCommentRepository.countByPostId(p.getId());
        return NewsPostDto.builder()
                .id(p.getId())
                .authorId(p.getAuthor().getId())
                .authorName(p.isAnonymous() ? "익명" : p.getAuthor().getName())
                .authorTicker(p.isAnonymous() ? "" : (p.getAuthor().getLoginId() != null ? p.getAuthor().getLoginId() : ""))
                .title(p.getTitle())
                .content(p.getContent())
                .category(p.getCategory())
                .likes(p.getLikes())
                .timestamp(p.getCreatedAt())
                .anonymous(p.isAnonymous())
                .commentCount(commentCount)
                .comments(null)
                .build();
    }

    private NewsPostDto toDetailDto(NewsPost p, List<NewsComment> comments) {
        List<NewsCommentDto> commentDtos = comments != null
                ? comments.stream().map(this::toCommentDto).collect(Collectors.toList())
                : Collections.emptyList();
        return NewsPostDto.builder()
                .id(p.getId())
                .authorId(p.getAuthor().getId())
                .authorName(p.isAnonymous() ? "익명" : p.getAuthor().getName())
                .authorTicker(p.isAnonymous() ? "" : (p.getAuthor().getLoginId() != null ? p.getAuthor().getLoginId() : ""))
                .title(p.getTitle())
                .content(p.getContent())
                .category(p.getCategory())
                .likes(p.getLikes())
                .timestamp(p.getCreatedAt())
                .anonymous(p.isAnonymous())
                .commentCount(commentDtos.size())
                .comments(commentDtos)
                .build();
    }

    private NewsCommentDto toCommentDto(NewsComment c) {
        return NewsCommentDto.builder()
                .id(c.getId())
                .authorId(c.getAuthor().getId())
                .authorName(c.getAuthor().getName())
                .content(c.getContent())
                .timestamp(c.getCreatedAt())
                .build();
    }
}
