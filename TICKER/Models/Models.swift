import SwiftUI

// MARK: - Holding
struct Holding: Identifiable, Hashable {
    let id: UUID
    var name: String
    var ticker: String
    var currentPrice: Double
    var change: Double
    var quantity: Int
    var avatarColor: Color
    var sparklineData: [Double]

    var totalValue: Double {
        currentPrice * Double(quantity)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Holding, rhs: Holding) -> Bool {
        lhs.id == rhs.id
    }

    static let sampleData: [Holding] = [
        Holding(
            id: UUID(),
            name: "김철수",
            ticker: "CHUL",
            currentPrice: 15200,
            change: 3.5,
            quantity: 10,
            avatarColor: .blue,
            sparklineData: [100, 105, 103, 108, 112, 110, 115, 118, 120, 122]
        ),
        Holding(
            id: UUID(),
            name: "이영희",
            ticker: "YOUNG",
            currentPrice: 8900,
            change: -1.2,
            quantity: 25,
            avatarColor: .pink,
            sparklineData: [100, 98, 102, 97, 95, 93, 96, 94, 92, 90]
        ),
        Holding(
            id: UUID(),
            name: "박지민",
            ticker: "JIMIN",
            currentPrice: 22000,
            change: 7.8,
            quantity: 5,
            avatarColor: .orange,
            sparklineData: [100, 103, 107, 110, 108, 115, 120, 125, 128, 130]
        ),
        Holding(
            id: UUID(),
            name: "최수진",
            ticker: "SUJIN",
            currentPrice: 12500,
            change: 0.5,
            quantity: 15,
            avatarColor: .green,
            sparklineData: [100, 101, 99, 102, 100, 103, 101, 104, 102, 103]
        ),
        Holding(
            id: UUID(),
            name: "정민호",
            ticker: "MINHO",
            currentPrice: 31000,
            change: -2.3,
            quantity: 8,
            avatarColor: .purple,
            sparklineData: [110, 108, 112, 107, 105, 103, 108, 106, 104, 102]
        ),
    ]
}

// MARK: - FriendListing (a friend's active todo/listing you can invest in)
struct FriendListing: Identifiable, Hashable {
    let id: UUID
    var title: String
    var progress: Double // 0.0 ~ 1.0

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FriendListing, rhs: FriendListing) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Friend
struct Friend: Identifiable, Hashable {
    let id: UUID
    var name: String
    var ticker: String
    var currentPrice: Double
    var change: Double
    var bio: String
    var avatarColor: Color
    var sparklineData: [Double]
    var skills: [String]
    var trustScore: Int
    var isStarred: Bool = false // Default to false
    var listings: [FriendListing]

    var isPositive: Bool { change >= 0 }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Friend, rhs: Friend) -> Bool {
        lhs.id == rhs.id
    }

    static let sampleData: [Friend] = [
        Friend(
            id: UUID(),
            name: "김철수",
            ticker: "CHUL",
            currentPrice: 15200,
            change: 3.5,
            bio: "풀스택 개발자, 매일 코딩에 열정을 쏟는 중",
            avatarColor: .blue,
            sparklineData: [100, 105, 103, 108, 112, 110, 115, 118, 120, 122],
            skills: ["Swift", "React", "Python"],
            trustScore: 95,
            listings: [
                FriendListing(id: UUID(), title: "운동 루틴", progress: 0.80),
                FriendListing(id: UUID(), title: "독서 목표", progress: 0.45),
            ]
        ),
        Friend(
            id: UUID(),
            name: "이영희",
            ticker: "YOUNG",
            currentPrice: 8900,
            change: -1.2,
            bio: "디자이너 겸 프론트엔드 개발자",
            avatarColor: .pink,
            sparklineData: [100, 98, 102, 97, 95, 93, 96, 94, 92, 90],
            skills: ["Figma", "UI/UX", "CSS"],
            trustScore: 88,
            listings: [
                FriendListing(id: UUID(), title: "포트폴리오 리뉴얼", progress: 0.30),
            ]
        ),
        Friend(
            id: UUID(),
            name: "박지민",
            ticker: "JIMIN",
            currentPrice: 22000,
            change: 7.8,
            bio: "AI 연구원, 논문 마스터",
            avatarColor: .orange,
            sparklineData: [100, 103, 107, 110, 108, 115, 120, 125, 128, 130],
            skills: ["ML", "PyTorch", "논문"],
            trustScore: 92,
            listings: [
                FriendListing(id: UUID(), title: "논문 작성", progress: 0.65),
                FriendListing(id: UUID(), title: "캐글 대회 참가", progress: 0.20),
            ]
        ),
        Friend(
            id: UUID(),
            name: "최수진",
            ticker: "SUJIN",
            currentPrice: 12500,
            change: 0.5,
            bio: "백엔드 엔지니어, 클라우드 전문가",
            avatarColor: .green,
            sparklineData: [100, 101, 99, 102, 100, 103, 101, 104, 102, 103],
            skills: ["AWS", "Docker", "Go"],
            trustScore: 90,
            listings: [
                FriendListing(id: UUID(), title: "AWS 자격증 취득", progress: 0.55),
            ]
        ),
        Friend(
            id: UUID(),
            name: "정민호",
            ticker: "MINHO",
            currentPrice: 31000,
            change: -2.3,
            bio: "창업가, 스타트업 대표",
            avatarColor: .purple,
            sparklineData: [110, 108, 112, 107, 105, 103, 108, 106, 104, 102],
            skills: ["경영", "마케팅", "투자"],
            trustScore: 85,
            listings: [
                FriendListing(id: UUID(), title: "투자 유치", progress: 0.40),
                FriendListing(id: UUID(), title: "MVP 출시", progress: 0.70),
                FriendListing(id: UUID(), title: "팀 빌딩", progress: 0.90),
            ]
        ),
    ]
}

// MARK: - ListingCategory
enum ListingCategory: String, CaseIterable {
    case project = "프로젝트"
    case study = "학습"
    case exercise = "운동"
    case hobby = "취미"
    case social = "사교"

    var icon: String {
        switch self {
        case .project: return "hammer.fill"
        case .study: return "book.fill"
        case .exercise: return "figure.run"
        case .hobby: return "paintbrush.fill"
        case .social: return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .project: return .blue
        case .study: return .green
        case .exercise: return .orange
        case .hobby: return .purple
        case .social: return .pink
        }
    }
}

// MARK: - Listing
struct Listing: Identifiable {
    let id: UUID
    var title: String
    var category: ListingCategory
    var initialPrice: Double
    var currentPrice: Double
    var change: Double
    var progress: Double
    var deadline: Date
    var isActive: Bool

    static let sampleData: [Listing] = [
        Listing(
            id: UUID(),
            title: "iOS 앱 출시하기",
            category: .project,
            initialPrice: 10000,
            currentPrice: 15200,
            change: 5.2,
            progress: 0.65,
            deadline: Date().addingTimeInterval(86400 * 14),
            isActive: true
        ),
        Listing(
            id: UUID(),
            title: "알고리즘 100문제 풀기",
            category: .study,
            initialPrice: 8000,
            currentPrice: 9500,
            change: 1.8,
            progress: 0.42,
            deadline: Date().addingTimeInterval(86400 * 30),
            isActive: true
        ),
        Listing(
            id: UUID(),
            title: "매일 5km 달리기",
            category: .exercise,
            initialPrice: 5000,
            currentPrice: 7200,
            change: 4.4,
            progress: 0.8,
            deadline: Date().addingTimeInterval(86400 * 7),
            isActive: true
        ),
    ]
}

// MARK: - StoreCategory
enum StoreCategory: String, CaseIterable {
    case skill = "스킬"
    case item = "아이템"
    case boost = "부스트"
    case secret = "비밀"
}

// MARK: - ItemRarity
enum ItemRarity: String {
    case common = "일반"
    case rare = "레어"
    case epic = "에픽"
    case legendary = "전설"

    var color: Color {
        switch self {
        case .common: return .gray
        case .rare: return .blue
        case .epic: return .purple
        case .legendary: return .orange
        }
    }
}

// MARK: - StoreItem
struct StoreItem: Identifiable {
    let id: UUID
    var name: String
    var description: String
    var price: Int
    var icon: String
    var rarity: ItemRarity
    var category: StoreCategory

    static let sampleData: [StoreItem] = [
        StoreItem(id: UUID(), name: "주가 조작기", description: "24시간 동안 특정 친구의 주가를 5% 올릴 수 있습니다", price: 25000, icon: "chart.line.uptrend.xyaxis", rarity: .epic, category: .item),
        StoreItem(id: UUID(), name: "스파이 스킬", description: "다른 사람의 포트폴리오를 24시간 동안 열람할 수 있습니다", price: 15000, icon: "eye.fill", rarity: .rare, category: .skill),
        StoreItem(id: UUID(), name: "더블 부스트", description: "다음 거래의 수익을 2배로 증가시킵니다", price: 10000, icon: "bolt.fill", rarity: .rare, category: .boost),
        StoreItem(id: UUID(), name: "익명 거래", description: "거래 내역을 다른 사용자에게 숨길 수 있습니다", price: 30000, icon: "person.fill.questionmark", rarity: .epic, category: .secret),
        StoreItem(id: UUID(), name: "시간 정지", description: "마감일을 하루 연장할 수 있습니다", price: 50000, icon: "clock.arrow.circlepath", rarity: .legendary, category: .item),
        StoreItem(id: UUID(), name: "힐링 포션", description: "하락한 신뢰도를 10점 회복합니다", price: 8000, icon: "heart.fill", rarity: .common, category: .item),
    ]
}

// MARK: - NewsPost
struct NewsPost: Identifiable, Hashable {
    let id: UUID
    var author: String
    var authorTicker: String
    var avatarColor: Color
    var title: String
    var content: String
    var category: NewsCategory
    var likes: Int
    var comments: [NewsComment]
    var timestamp: Date
    var isAnonymous: Bool

    var displayAuthor: String {
        isAnonymous ? "익명" : author
    }

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        return "\(Int(interval / 86400))일 전"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: NewsPost, rhs: NewsPost) -> Bool {
        lhs.id == rhs.id
    }

    static let sampleData: [NewsPost] = [
        NewsPost(
            id: UUID(),
            author: "박지민",
            authorTicker: "JIMIN",
            avatarColor: .orange,
            title: "요즘 AI 관련 상장 많이 하시나요?",
            content: "AI 프로젝트 상장이 요즘 대세인 것 같은데, 다들 어떤 카테고리로 상장하고 계신가요? 저는 논문 작성 위주로 하고 있는데 수익률이 괜찮네요.",
            category: .discussion,
            likes: 12,
            comments: [
                NewsComment(id: UUID(), author: "김철수", content: "저도 AI 쪽 상장 준비 중이에요!", timestamp: Date().addingTimeInterval(-1800)),
                NewsComment(id: UUID(), author: "최수진", content: "프로젝트 카테고리가 수익률이 제일 높은 것 같아요", timestamp: Date().addingTimeInterval(-900)),
            ],
            timestamp: Date().addingTimeInterval(-600),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "김철수",
            authorTicker: "CHUL",
            avatarColor: .blue,
            title: "정민호 주가 왜 이렇게 떨어지나요?",
            content: "정민호 주식 보유하고 있는데 계속 하락 중이네요. 투자 유치 상장 진행 상황 아시는 분?",
            category: .analysis,
            likes: 8,
            comments: [
                NewsComment(id: UUID(), author: "익명", content: "마감일이 가까운데 진행률이 낮아서 그런 듯", timestamp: Date().addingTimeInterval(-3000)),
            ],
            timestamp: Date().addingTimeInterval(-3600),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "최수진",
            authorTicker: "SUJIN",
            avatarColor: .green,
            title: "암시장에서 시간 정지 스킬 살 가치가 있나요?",
            content: "50000P나 하는데... 마감일 연장이 그 정도 가치가 있을까요? 사보신 분 후기 부탁드립니다.",
            category: .tip,
            likes: 15,
            comments: [
                NewsComment(id: UUID(), author: "박지민", content: "마감 직전에 쓰면 인생템이에요", timestamp: Date().addingTimeInterval(-5400)),
                NewsComment(id: UUID(), author: "정민호", content: "차라리 더블 부스트가 가성비 좋아요", timestamp: Date().addingTimeInterval(-4800)),
                NewsComment(id: UUID(), author: "이영희", content: "저는 3개 비축해놨어요 ㅋㅋ", timestamp: Date().addingTimeInterval(-4200)),
            ],
            timestamp: Date().addingTimeInterval(-7200),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "이영희",
            authorTicker: "YOUNG",
            avatarColor: .pink,
            title: "카지노에서 30만P 날렸습니다...",
            content: "룰렛에서 연속으로 잃었네요 ㅠㅠ 카지노 하지 마세요 진심으로... 도박 취소권 없었으면 더 잃을 뻔",
            category: .free,
            likes: 23,
            comments: [
                NewsComment(id: UUID(), author: "김철수", content: "ㅋㅋㅋㅋ 저도요...", timestamp: Date().addingTimeInterval(-10800)),
                NewsComment(id: UUID(), author: "익명", content: "카지노는 집이 항상 이기는 법", timestamp: Date().addingTimeInterval(-9000)),
            ],
            timestamp: Date().addingTimeInterval(-14400),
            isAnonymous: false
        ),
        NewsPost(
            id: UUID(),
            author: "정민호",
            authorTicker: "MINHO",
            avatarColor: .purple,
            title: "이번 주 수익률 TOP 3 예측",
            content: "박지민: 논문 마감 임박 + 높은 진행률로 급등 예상\n김철수: 꾸준한 상승세\n최수진: AWS 자격증 곧 취득할 듯",
            category: .analysis,
            likes: 18,
            comments: [],
            timestamp: Date().addingTimeInterval(-28800),
            isAnonymous: false
        ),
    ]
}

// MARK: - NewsComment
struct NewsComment: Identifiable, Hashable {
    let id: UUID
    var author: String
    var content: String
    var timestamp: Date

    var timeAgo: String {
        let interval = Date().timeIntervalSince(timestamp)
        if interval < 60 { return "방금 전" }
        if interval < 3600 { return "\(Int(interval / 60))분 전" }
        if interval < 86400 { return "\(Int(interval / 3600))시간 전" }
        return "\(Int(interval / 86400))일 전"
    }
}

// MARK: - NewsCategory
enum NewsCategory: String, CaseIterable {
    case all = "전체"
    case free = "자유"
    case analysis = "분석"
    case tip = "꿀팁"
    case discussion = "토론"

    var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .free: return "bubble.left.fill"
        case .analysis: return "chart.bar.fill"
        case .tip: return "lightbulb.fill"
        case .discussion: return "text.bubble.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .gray
        case .free: return .cyan
        case .analysis: return .blue
        case .tip: return .yellow
        case .discussion: return .green
        }
    }
}

// MARK: - BetType
enum BetType: String {
    case success = "성공"
    case failure = "실패"

    var color: Color {
        switch self {
        case .success: return .green
        case .failure: return .red
        }
    }
}
