package com.ticker.repository;

import com.ticker.model.NewsCategory;
import com.ticker.model.NewsPost;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;

/**
 * 뉴스 글 레포지토리
 */
public interface NewsPostRepository extends JpaRepository<NewsPost, Long> {

    @Query("SELECT p FROM NewsPost p JOIN FETCH p.author ORDER BY p.createdAt DESC")
    List<NewsPost> findAllWithAuthorOrderByCreatedAtDesc();

    @Query("SELECT p FROM NewsPost p JOIN FETCH p.author WHERE p.category = :category ORDER BY p.createdAt DESC")
    List<NewsPost> findByCategoryWithAuthorOrderByCreatedAtDesc(NewsCategory category);

    @Query("SELECT p FROM NewsPost p JOIN FETCH p.author WHERE p.id = :id")
    java.util.Optional<NewsPost> findByIdWithAuthor(Long id);
}
