package com.ticker.repository;

import com.ticker.model.NewsComment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * 뉴스 댓글 레포지토리
 */
public interface NewsCommentRepository extends JpaRepository<NewsComment, Long> {

    List<NewsComment> findByPostIdOrderByCreatedAtAsc(Long postId);

    @Query("SELECT c FROM NewsComment c JOIN FETCH c.author WHERE c.post.id = :postId ORDER BY c.createdAt ASC")
    List<NewsComment> findByPostIdWithAuthorOrderByCreatedAtAsc(Long postId);

    long countByPostId(Long postId);
}
