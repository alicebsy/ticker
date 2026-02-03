package com.ticker.config;

import com.ticker.model.*;
import com.ticker.repository.*;
import com.ticker.service.WatchlistService;
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
    private final WatchlistService watchlistService;
    private final NewsPostRepository newsPostRepository;
    private final NewsCommentRepository newsCommentRepository;

    @Override
    public void run(String... args) {
        if (userRepository.count() > 0) return;

        // 샘플 사용자 생성 (보유 자산·내 가치 초기값 10만원, 친구 코드 발급)
        User user1 = User.builder()
                .name("김민수")
                .loginId("kim")
                .password("1234")
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L)
                .marketCap(100_000L)
                .totalAssets(200_000L)
                .stockPrice(1_000L)
                .consecutiveUpDays(5)
                .build();
        User user2 = User.builder()
                .name("이지은")
                .loginId("lee")
                .password("1234")
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L)
                .marketCap(100_000L)
                .totalAssets(200_000L)
                .stockPrice(1_000L)
                .build();
        User user3 = User.builder()
                .name("박준혁")
                .loginId("park")
                .password("1234")
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L)
                .marketCap(100_000L)
                .totalAssets(200_000L)
                .stockPrice(1_000L)
                .consecutiveUpDays(3)
                .build();
        User user4 = User.builder()
                .name("최서연")
                .loginId("choi")
                .password("1234")
                .friendCode(watchlistService.generateUniqueFriendCode())
                .cashBalance(100_000L)
                .marketCap(100_000L)
                .totalAssets(200_000L)
                .stockPrice(1_000L)
                .build();

        userRepository.saveAll(List.of(user1, user2, user3, user4));

        // 내 주가 차트용 이력 (user1, 1주당 가격)
        for (int i = 6; i >= 0; i--) {
            StockPriceHistory h = StockPriceHistory.builder()
                    .user(user1)
                    .price(1000L + i * 10L)
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
        MarketItem skill5 = MarketItem.builder()
                .name("투자 취소권")
                .description("한 건의 투자를 원금 회수하며 취소합니다")
                .price(2800L)
                .rarity(ItemRarity.EPIC)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill6 = MarketItem.builder()
                .name("베팅 무효권")
                .description("진행 중인 베팅 하나를 무효 처리합니다 (원금 반환)")
                .price(3200L)
                .rarity(ItemRarity.EPIC)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill7 = MarketItem.builder()
                .name("진행률 부스터")
                .description("할 일 진행률을 한 번에 +20% 올립니다")
                .price(1500L)
                .rarity(ItemRarity.RARE)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill8 = MarketItem.builder()
                .name("베팅 수익 1.5배")
                .description("다음 베팅에서 수익 시 1.5배로 받습니다")
                .price(3500L)
                .rarity(ItemRarity.LEGENDARY)
                .type(MarketItem.MarketItemType.SKILL)
                .build();
        MarketItem skill9 = MarketItem.builder()
                .name("주가 보호권")
                .description("24시간 동안 내 주가 하락을 막습니다")
                .price(5000L)
                .rarity(ItemRarity.LEGENDARY)
                .type(MarketItem.MarketItemType.SKILL)
                .build();

        // 암시장 특수 아이템
        MarketItem special1 = MarketItem.builder()
                .name("미스터리 박스")
                .description("열면 랜덤 스킬 1개를 획득합니다")
                .price(2000L)
                .rarity(ItemRarity.RARE)
                .type(MarketItem.MarketItemType.SPECIAL)
                .build();
        MarketItem special2 = MarketItem.builder()
                .name("럭키 백")
                .description("랜덤 아이템 1~3개가 나옵니다")
                .price(2500L)
                .rarity(ItemRarity.EPIC)
                .type(MarketItem.MarketItemType.SPECIAL)
                .build();

        // 암시장 아이콘 (프로필 꾸미기)
        MarketItem icon1 = MarketItem.builder()
                .name("황금 테두리")
                .description("프로필에 황금 테두리가 적용됩니다")
                .price(800L)
                .rarity(ItemRarity.COMMON)
                .type(MarketItem.MarketItemType.ICON)
                .build();
        MarketItem icon2 = MarketItem.builder()
                .name("VIP 뱃지")
                .description("프로필에 VIP 뱃지가 표시됩니다")
                .price(1200L)
                .rarity(ItemRarity.RARE)
                .type(MarketItem.MarketItemType.ICON)
                .build();

        marketItemRepository.saveAll(List.of(
                skill1, skill2, skill3, skill4, skill5, skill6, skill7, skill8, skill9,
                special1, special2,
                icon1, icon2
        ));

        // 뉴스 샘플 글 (꼰지르기/예측 스타일)
        NewsPost post1 = NewsPost.builder()
                .author(user1)
                .title("강예서 어제 치킨 먹었어요")
                .content("강예서 어제 치킨 먹었어요. 오늘 운동 안 갈 거라고 예측해봅니다. 주가 하락 베팅 각입니다.")
                .category(NewsCategory.ANALYSIS)
                .likes(23)
                .anonymous(false)
                .build();
        NewsPost post2 = NewsPost.builder()
                .author(user2)
                .title("박준혁 주가 급등 예상")
                .content("박준혁 오늘 새벽 5시에 '내일 6시 기상' 투두 올려놨는데 이미 3일 연속 실패한 그 투두예요. 오늘은 진짜 할 거 같아서 성공 베팅 넣었습니다.")
                .category(NewsCategory.ANALYSIS)
                .likes(41)
                .anonymous(false)
                .build();
        NewsPost post3 = NewsPost.builder()
                .author(user3)
                .title("이지은 한강 조깅 3일차")
                .content("이지은 한강 조깅 3일차 달성 중. 내일 비 온대요. 4일차 실패 예측해서 실패 쪽에 5만P 걸었어요 ㅋㅋ")
                .category(NewsCategory.FREE)
                .likes(18)
                .anonymous(false)
                .build();
        NewsPost post4 = NewsPost.builder()
                .author(user4)
                .title("최서연 '책 한 권 읽기' 투두")
                .content("최서연이 '이번 주 책 한 권 읽기' 상장해놨는데 아직 3페이지라고 합니다. 저 내일 주가 떡락 예상... 실패 베팅 추천드려요.")
                .category(NewsCategory.DISCUSSION)
                .likes(33)
                .anonymous(false)
                .build();
        newsPostRepository.saveAll(List.of(post1, post2, post3, post4));
        NewsComment c1 = NewsComment.builder().post(post1).author(user2).content("저도 치킨 먹으면 다음날 운동 100% 스킵해요 ㅋㅋ").build();
        NewsComment c2 = NewsComment.builder().post(post1).author(user3).content("강예서 주가 오늘 털렸다던데").build();
        NewsComment c3 = NewsComment.builder().post(post2).author(user4).content("박준혁 알람 5개 맞춰놨대요 진짜 할 듯").build();
        newsCommentRepository.saveAll(List.of(c1, c2, c3));
    }
}
