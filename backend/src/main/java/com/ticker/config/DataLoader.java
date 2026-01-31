package com.ticker.config;

import com.ticker.model.*;
import com.ticker.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.CommandLineRunner;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.List;

/**
 * 개발용 초기 데이터 로더
 * 암시장 스킬, 샘플 사용자 등
 */
@Component
@RequiredArgsConstructor
public class DataLoader implements CommandLineRunner {

    private final UserRepository userRepository;
    private final MarketItemRepository marketItemRepository;
    private final StockPriceHistoryRepository stockPriceHistoryRepository;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) return;

        // 샘플 사용자 생성
        User user1 = User.builder()
                .name("김민수")
                .loginId("kim")
                .password("1234")
                .cashBalance(125_000L)
                .totalAssets(125_000L)
                .stockPrice(130L)
                .consecutiveUpDays(5)
                .build();
        User user2 = User.builder()
                .name("이지은")
                .loginId("lee")
                .password("1234")
                .cashBalance(81_700L)
                .totalAssets(81_700L)
                .stockPrice(100L)
                .build();
        User user3 = User.builder()
                .name("박준혁")
                .loginId("park")
                .password("1234")
                .cashBalance(50_000L)
                .totalAssets(50_000L)
                .stockPrice(150L)
                .consecutiveUpDays(3)
                .build();
        User user4 = User.builder()
                .name("최서연")
                .loginId("choi")
                .password("1234")
                .cashBalance(30_000L)
                .totalAssets(30_000L)
                .stockPrice(110L)
                .build();

        userRepository.saveAll(List.of(user1, user2, user3, user4));

        // 내 주가 차트용 이력 (user1)
        for (int i = 6; i >= 0; i--) {
            StockPriceHistory h = StockPriceHistory.builder()
                    .user(user1)
                    .price(100L + i * 5L)
                    .recordDate(LocalDate.now().minusDays(i))
                    .build();
            stockPriceHistoryRepository.save(h);
        }

        // 암시장 스킬 아이템
        MarketItem skill1 = MarketItem.builder()
                .name("도박 취소권")
                .description("진행 중인 베팅을 취소할 수 있습니다")
                .price(3000L)
                .rarity(ItemRarity.EPIC)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill2 = MarketItem.builder()
                .name("할 일 스킵권")
                .description("상장된 할 일 하나를 패널티 없이 취소")
                .price(2500L)
                .rarity(ItemRarity.EPIC)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill3 = MarketItem.builder()
                .name("룰렛 추가 기회권")
                .description("카지노 룰렛을 한 번 더 돌릴 수 있습니다")
                .price(1000L)
                .rarity(ItemRarity.RARE)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill4 = MarketItem.builder()
                .name("손실 방어권")
                .description("다음 손실의 50%를 방어합니다")
                .price(4000L)
                .rarity(ItemRarity.LEGENDARY)
                .type(MarketItem.MarketItemType.SKILL)
                .build();

        marketItemRepository.saveAll(List.of(skill1, skill2, skill3, skill4));
    }
}
