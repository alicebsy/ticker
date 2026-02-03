package com.ticker.service;

import com.ticker.dto.DarkMarketResponse;
import com.ticker.dto.PurchaseRequest;
import com.ticker.model.*;
import com.ticker.repository.InvestmentRepository;
import com.ticker.repository.MarketItemRepository;
import com.ticker.repository.UserRepository;
import com.ticker.repository.UserSkillRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

/**
 * 암시장 서비스
 * 스킬/아이콘/특수아이템 구매, 보유 포인트 조회
 */
@Service
@RequiredArgsConstructor
public class DarkMarketService {

    private final MarketItemRepository marketItemRepository;
    private final UserRepository userRepository;
    private final UserSkillRepository userSkillRepository;
    private final InvestmentRepository investmentRepository;

    /**
     * 암시장 화면 데이터 조회
     */
    @Transactional(readOnly = true)
    public DarkMarketResponse getDarkMarket(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));

        List<MarketItem> skills = marketItemRepository.findByType(MarketItem.MarketItemType.SKILL);
        List<MarketItem> icons = marketItemRepository.findByType(MarketItem.MarketItemType.ICON);
        List<MarketItem> specials = marketItemRepository.findByType(MarketItem.MarketItemType.SPECIAL);

        List<DarkMarketResponse.MarketItemDto> skillDtos = toMarketItemDtos(skills);
        List<DarkMarketResponse.MarketItemDto> iconDtos = toMarketItemDtos(icons);
        List<DarkMarketResponse.MarketItemDto> specialDtos = toMarketItemDtos(specials);

        DarkMarketResponse.SpecialDealDto specialDeal = new DarkMarketResponse.SpecialDealDto(
                "미스터리 박스 3개 묶음",
                "30% 할인",
                1500L,
                1050L
        );

        long investing = investmentRepository.findByInvestorIdWithSubjectUser(userId).stream()
                .mapToLong(i -> (long) i.getQuantity() * i.getSubjectUser().getStockPrice())
                .sum();
        return DarkMarketResponse.builder()
                .userPoints(user.getCashBalance() + investing)
                .skills(skillDtos)
                .icons(iconDtos)
                .specialItems(specialDtos)
                .todaySpecial(specialDeal)
                .build();
    }

    /**
     * 아이템 구매
     */
    @Transactional
    public void purchase(Long userId, PurchaseRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("사용자를 찾을 수 없습니다"));
        MarketItem item = marketItemRepository.findById(request.getMarketItemId())
                .orElseThrow(() -> new IllegalArgumentException("아이템을 찾을 수 없습니다"));

        int qty = request.getQuantity() != null ? request.getQuantity() : 1;
        long cost = item.getPrice() * qty;

        long available = user.getCashBalance();
        if (available < cost) {
            throw new IllegalArgumentException("포인트가 부족합니다. 필요: " + cost + "P, 보유: " + available + "P");
        }

        user.setCashBalance(user.getCashBalance() - cost);
        userRepository.save(user);

        Optional<UserSkill> existing = userSkillRepository.findByUserIdAndMarketItemId(userId, item.getId());
        if (existing.isPresent()) {
            UserSkill us = existing.get();
            us.setQuantity(us.getQuantity() + qty);
            userSkillRepository.save(us);
        } else {
            UserSkill us = UserSkill.builder()
                    .user(user)
                    .marketItem(item)
                    .quantity(qty)
                    .build();
            userSkillRepository.save(us);
        }
    }

    private List<DarkMarketResponse.MarketItemDto> toMarketItemDtos(List<MarketItem> items) {
        return items.stream()
                .map(m -> new DarkMarketResponse.MarketItemDto(
                        m.getId(),
                        m.getName(),
                        m.getDescription(),
                        m.getPrice(),
                        m.getRarity().name(),
                        m.getType().name()
                ))
                .collect(Collectors.toList());
    }
}
