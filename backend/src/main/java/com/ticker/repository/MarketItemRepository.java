package com.ticker.repository;

import com.ticker.model.MarketItem;
import com.ticker.model.MarketItem.MarketItemType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

/**
 * 암시장 아이템 레포지토리
 */
public interface MarketItemRepository extends JpaRepository<MarketItem, Long> {

    List<MarketItem> findByType(MarketItemType type);
}
