# Ticker — Human Stock Market

---

## 1. 프로젝트 개요 (Project Overview)

> **"가장 높은 가치는 당신의 오늘로부터."**

TICKER는 개인의 생산성을 자산 가치로 평가하는 **현실 기반 인적 자본 시장(Human Stock Market)** 플랫폼입니다.

단순한 기록형 To-Do 서비스나 휘발성 SNS를 넘어, 개인의 성취를 실시간 주가(Stock Price)로 동기화합니다. 사용자는 서로의 가능성에 직접 투자하며 함께 성장하고 경쟁하는 독창적인 **Social-Fi(Social + Finance)** 생태계를 지향합니다.

- **백엔드**: Spring Boot (Java 17) + H2 DB + STOMP WebSocket  
- **클라이언트**: SwiftUI (macOS 앱, iOS 시뮬레이터 호환)

---

## 2. 기획 배경 (Background)

기존의 자기계발 앱은 ‘실패해도 리스크가 없고’, ‘성취의 보상이 추상적’이라는 한계로 인해 장기적인 동기부여에 실패해 왔습니다.

TICKER는 이 정적인 구조를 타파하기 위해 **자본주의적 피드백 시스템**을 도입했습니다.

- **손실의 공포:** 나의 나태함이 내 가치를 하락시키고,
- **수익의 희열:** 나의 성실함이 나를 믿어준 투자자(친구)에게 실제 수익을 안겨주는

이 강력한 이해관계의 연결을 통해, 단순한 의지를 넘어선 **강제된 성장 동력**을 제공합니다.

---

## 목차

- [주요 기능](#주요-기능)
- [계산 로직](#계산-로직)
- [기술 스택](#기술-스택)
- [프로젝트 구조](#프로젝트-구조)
- [실행 방법](#실행-방법)
- [앱 구성과 플로우](#앱-구성과-플로우)
- [API·WebSocket 요약](#apiwebsocket-요약)
- [설정 및 환경](#설정-및-환경)

---

## 주요 기능

### 로그인

- **이메일**: 회원가입·로그인 (`/api/auth/signup`, `/api/auth/login`)
- **카카오 OAuth2**: 브라우저에서 카카오 로그인 후 앱으로 복귀 (`ticker://oauth?userId=...`), 백엔드에서 유저 정보 조회 후 세션 처리

### 사이드바·공통

- **총 자산**: 보유 현금 + 내 가치(주가×70주) + 투자 평가액. 랭킹·암시장 구매 가능 금액의 기준.
- **장 상태**: 장 열림/닫힘 표시
- **다크/라이트 모드**: `@AppStorage("isDarkMode")`로 저장
- **로그아웃**: WebSocket 연결 해제 후 로그인 화면으로

### 탭별 기능

| 탭 | 화면 | 설명 |
|----|------|------|
| **포트폴리오** | `PortfolioView` | 총 자산 카드, 투자 중인 종목(친구 주식), 최근 활동, 랭킹, 보유 스킬(암시장 구매분), 뉴스 미리보기. 공개/비공개 전환 |
| **상장** | `ListingView` | 내 주가 차트, 오늘의 할 일 등록·완료·진행률 업데이트, 주가 변동 규칙 안내. WebSocket으로 주가·진행률 실시간 반영 |
| **보유 종목** | `HoldingsView` | 친구 주식 매수/매도, 수익률·평균 단가·보유 수량·손익 |
| **모든 종목** | `AllStocksView` | 친구 코드 검색, 친구 요청 수락/거절, 관심 종목 그리드. 카드 선택 시 `PersonDetailView`에서 매수/매도·차트·할 일 확인 |
| **암시장** | `StoreView` | 스킬/아이콘/특수 아이템 목록(카테고리 필터), 오늘의 특가. 구매 시 **보유 현금**에서 차감 |
| **카지노** | `CasinoView` | 친구의 할 일 성공/실패 예측 베팅, 베팅 내역·적중 시 배당 |
| **뉴스** | `NewsView` | 카테고리별 게시판(자유/분석/팁/토론), 글쓰기·수정·삭제·좋아요·댓글. 글 상세는 캐시로 유지해 탭 전환 후에도 댓글 유지. WebSocket으로 댓글 실시간 반영 |

### 실시간 (WebSocket)

- **연결**: 로그인 성공 시 `WebSocketManager.shared.connect(userId)` → SockJS + STOMP
- **구독**: `/topic/user/{userId}/notifications`, `/topic/stock/{userId}`, (뉴스 상세 진입 시) `/topic/news/{postId}/comments`
- **처리**: 주가 변동 시 차트·그리드 갱신, 할 일 완료/진행률 시 데이터 재조회, 뉴스 댓글 수신 시 해당 글의 댓글 목록에 추가

---

## 계산 로직

앱 내 모든 금액·비율은 아래 규칙으로 일관되게 계산됩니다.

### 1. 사람 = 1종목 (주식 구조)

- **총 발행 주식**: 100주  
  - **창업자 지분**: 70주 (매도 불가, “내 가치” 계산에만 사용)  
  - **매물**: 30주만 친구들이 매수/매도 가능  
- **1주 가격**: 해당 유저의 `stockPrice` (단위: P). 초기값 1,000P.  
- **시가총액** (표시용): `stockPrice × 100`  
- **내 가치** (총 자산 계산용): `stockPrice × 70` (창업자 70주 기준)

### 2. 총 자산

```
총 자산 = 보유 현금(cashBalance) + (주가 × 70) + 투자 평가액
투자 평가액 = Σ (보유 수량 × 해당 친구의 현재 주가)
```

- 랭킹·암시장 “포인트” 안내 등에는 이 총 자산 개념이 쓰이고, 실제 **암시장 구매·베팅·매수**는 **보유 현금**만 차감/입금됩니다.

### 3. 주가 변동 (오늘 투두 성공률)

- **조건**: “오늘” 생성된 할 일이 **4개 이상**일 때만 변동 적용. 4개 미만이면 변동 없음.
- **성공률**: `완료된 개수 / 오늘 투두 전체 개수` (진행률 100%인 것도 완료로 간주)
- **변동률** (일괄 반영은 스케줄/수동 호출 시, 실시간 반영은 할 일 완료/진행률 반영 시):

| 성공률       | 주가 변동      |
|-------------|----------------|
| 100%        | +10% ~ +15% (랜덤) |
| 75% ~ 99%   | +5%            |
| 50% ~ 74%   | 0%             |
| 25% ~ 49%   | -10%           |
| 0% ~ 24%    | -20%           |

- **적용 식**: `새 주가 = max(1, 기존 주가 × (1 + 변동률/100))`  
- 그 후 **시가총액** = 새 주가 × 100, **총 자산**은 위 식으로 다시 계산해 저장.

### 4. 상장 (할 일 등록) — 공모가

- **공모가(보상 포인트)** = 난이도 기본 점수 × (내 주가 / 100)  
  - 쉬움: 500 × (주가/100)  
  - 보통: 1,000 × (주가/100)  
  - 어려움: 1,500 × (주가/100)  
- 주가가 높을수록 같은 난이도도 공모가가 비싸게 책정됩니다.

### 5. 투자 (매수 / 매도)

- **매수 단가**: 그 순간 해당 유저의 `stockPrice`.  
  **매수 비용** = 수량 × 단가 → **보유 현금**에서 차감.  
  한 유저당 매물 30주 한도 내에서만 매수 가능.
- **매도**  
  - **매도 대금** = 매도 수량 × 해당 유저의 **현재** 주가 → **보유 현금**에 입금.  
  - **손익** = (현재 주가 − 매입 단가) × 수량  
  - **수익률** = 손익 / (매입 단가 × 수량) × 100%

### 6. 카지노 베팅

- 베팅 시 **베팅 금액**만큼 **보유 현금**에서 차감.
- 할 일이 **완료(성공)** 또는 **미완료(실패)**로 확정되면 해당 Todo에 걸린 베팅이 정산됩니다.
  - **적중**: 성공 예측 후 실제 완료, 또는 실패 예측 후 실제 미완료  
    → **원금 + 원금의 50%**를 보유 현금에 지급.  
  - **실패**: 예측과 결과가 다름  
    → 베팅 금액 전액 손실 (추가 입금 없음).

### 7. 암시장 (스토어)

- **구매 가능 금액**: 보유 현금만 사용 (투자 평가액은 표시용 포인트 개념).
- **구매**: 아이템 단가 × 수량만큼 **보유 현금** 차감 후, 해당 스킬/아이템 보유 수량 증가.

---

## 기술 스택

| 구분 | 기술 |
|------|------|
| **백엔드** | Java 17, Spring Boot 3.2, Spring Data JPA, H2 (file DB), Spring Security + OAuth2, STOMP WebSocket (SockJS) |
| **프론트** | Swift 5, SwiftUI, `URLSession` (REST), `URLSessionWebSocketTask` (STOMP 수동 파싱) |
| **기타** | Kakao OAuth2, H2 Console |

---

## 프로젝트 구조

```
ticker/
├── backend/                          # Spring Boot API
│   ├── src/main/java/com/ticker/
│   │   ├── config/                   # Security, WebSocket, CORS, DataLoader, OAuth2
│   │   ├── controller/               # Auth, Portfolio, Listing, Investment, Watchlist,
│   │   │                             #   News, DarkMarket, Casino, User, Todo
│   │   ├── service/                  # 비즈니스 로직 + NotificationService(WebSocket 발송)
│   │   ├── repository/               # JPA Repository
│   │   ├── model/                    # User, Todo, Investment, NewsPost, NewsComment, ...
│   │   ├── dto/                      # 요청/응답 DTO
│   │   └── TickerApplication.java
│   ├── src/main/resources/
│   │   └── application.yml          # H2 URL, OAuth2, 서버 포트
│   ├── data/                         # H2 DB 파일 (ticker_db.mv.db)
│   └── README.md                     # API·테스트 상세
│
├── TICKER/                           # SwiftUI 앱
│   ├── App/
│   │   └── TickerApp.swift           # @main, AppState(전역 상태·API·WebSocket 연동)
│   ├── Views/
│   │   ├── ContentView.swift         # 로그인 여부 → LoginView / NavigationSplitView(Sidebar + Detail)
│   │   ├── LoginView.swift           # 카카오·이메일 로그인
│   │   ├── SignupView.swift, EmailLoginView.swift
│   │   ├── PortfolioView.swift
│   │   ├── ListingView.swift
│   │   ├── HoldingsView.swift
│   │   ├── AllStocksView.swift
│   │   ├── PersonDetailView.swift    # 친구 상세(매수/매도, 차트, 할 일)
│   │   ├── StoreView.swift
│   │   ├── CasinoView.swift
│   │   └── NewsView.swift
│   ├── Components/
│   │   ├── StockCardView.swift       # 친구/종목 카드
│   │   ├── ZoomableChartView.swift, PriceBadgeView.swift, StatRow.swift
│   ├── Services/
│   │   ├── NetworkManager.swift      # REST (baseURL, X-User-Id), Auth/User/News/...
│   │   └── WebSocketManager.swift    # STOMP connect/subscribe, 뉴스 댓글·알림 수신
│   ├── Models/
│   │   └── Models.swift              # User, Holding, Friend, NewsPost, DTO 변환 등
│   ├── Theme/
│   │   └── Theme.swift               # AppTheme, CardStyle, SparklineView, AvatarView
│   ├── Info.plist, TICKER.entitlements
│   └── Assets.xcassets
│
├── TICKER.xcodeproj
├── TICKERTests/, TICKERUITests/
├── ticker.code-workspace
└── README.md
```

---

## 실행 방법

### 1. 백엔드

```bash
cd backend
./gradlew bootRun
```

- 서버: **http://localhost:8080**
- H2 콘솔: http://localhost:8080/h2-console  
  (JDBC URL: `jdbc:h2:file:./data/ticker_db`, 사용자명: `sa`, 비밀번호 없음)
- DB 파일: `backend/data/ticker_db.mv.db` (한 프로세스만 접근 가능하므로, 다른 `bootRun`이 있으면 종료 후 실행)

### 2. 프론트엔드 (TICKER 앱)

1. Xcode에서 **TICKER.xcodeproj** 열기  
2. 스킴 **TICKER**, 디바이스 **My Mac** 또는 **iPhone 시뮬레이터** 선택  
3. **⌘R** 로 빌드·실행  

앱이 백엔드와 통신하려면 **서버 주소**가 맞아야 합니다.

- **NetworkManager.swift**: `baseURL`  
- **WebSocketManager.swift**: `url`  

로컬에서만 쓸 경우 `localhost` 또는 본인 PC IP로 바꾸세요. 시뮬레이터는 `localhost` 사용 가능합니다.

### 3. 카카오 로그인 (선택)

- [Kakao Developers](https://developers.kakao.com)에서 앱 생성, Redirect URI 등록  
  - 웹: `http://localhost:8080/login/oauth2/code/kakao`  
  - 앱 복귀: `ticker://oauth`
- `application.yml`(또는 환경변수)에 `client-id`, `client-secret` 설정
- 앱에서 카카오 로그인 시 브라우저 → 로그인 후 `ticker://oauth?userId=...` 로 돌아오면 앱이 `handleKakaoOAuthCallback`으로 유저 조회 후 로그인 처리

---

## 앱 구성과 플로우

1. **앱 진입**  
   - `ContentView`: `appState.isLoggedIn` → `false`면 `LoginView`, `true`면 `NavigationSplitView`(사이드바 + 상세).

2. **로그인**  
   - 이메일: `SignupView` / `EmailLoginView` → `AppState.login` / `signup` → `handleAuthResponse` → `setupWebSocket`, `fetchMyData`.  
   - 카카오: Safari 등에서 `/oauth2/authorization/kakao` 이동 → 로그인 후 `ticker://oauth?userId=...` → `onOpenURL` → `handleKakaoOAuthCallback` → 동일하게 WebSocket 연결·데이터 로드.

3. **메인**  
   - 사이드바: `SidebarTab` 선택 → `DetailView`에서 해당 탭에 맞는 View 표시 (PortfolioView, ListingView, …).  
   - 모든 탭은 `@EnvironmentObject var appState: AppState`로 동일한 상태 공유.

4. **데이터**  
   - 포트폴리오·보유·관심 종목·친구 요청 등: `fetchMyData()` (REST).  
   - 뉴스: `fetchNews`, 글 선택 시 `loadNewsPostDetail`로 상세(댓글 포함) 로드 후 `newsPostDetailCache`에 저장·`subscribeToNewsComments`. 탭 전환 후에도 캐시로 댓글 유지.  
   - 실시간: WebSocket 수신 시 `handleRealTimeNotification`, `appendNewsCommentFromSocket` 등으로 `@Published` 갱신 → UI 자동 반영.

5. **테마**  
   - `AppTheme`: 다크/라이트 배경·카드·텍스트 색, `SparklineView`, `PriceBadgeView`, `AvatarView` 등 공통 UI.

---

## API·WebSocket 요약

- **인증**: 대부분 API에 `X-User-Id` 헤더로 사용자 ID 전달 (기본값 1).  
  카카오는 OAuth2 세션 쿠키로 처리.
- **REST**:  
  - Auth: signup, login, `/users/{id}`  
  - Portfolio: `/portfolio`  
  - Listing: 상장 목록, 신규 상장, 완료, 진행률  
  - Investment: 보유 종목, 매수/매도  
  - Watchlist: 친구 코드, 친구 요청/수락/거절, 관심 종목  
  - News: 목록, 상세, 글쓰기/수정/삭제, 댓글, 좋아요  
  - DarkMarket: 암시장 목록, 구매  
  - Casino: 베팅  
- **WebSocket** (SockJS + STOMP, `ws://{host}:8080/ws`)  
  - `/topic/user/{userId}/notifications`: 친구 요청/수락/거절, 베팅·관심 종목 알림  
  - `/topic/stock/{userId}`: 주가·할 일 완료/진행률·매수/매도  
  - `/topic/news/{postId}/comments`: 뉴스 댓글 실시간  

엔드포인트·curl·테스트 방법은 **[backend/README.md](backend/README.md)** 참고.

---

## 설정 및 환경

| 항목 | 위치 | 설명 |
|------|------|------|
| **H2 DB** | `application.yml` | `jdbc:h2:file:./data/ticker_db;DB_CLOSE_DELAY=-1;DB_CLOSE_ON_EXIT=FALSE` |
| **서버 포트** | `application.yml` | `server.port` (기본 8080), `SERVER_PORT` 환경변수 가능 |
| **카카오** | `application.yml` | `spring.security.oauth2.client.registration.kakao`, `KAKAO_CLIENT_SECRET` 등 |
| **앱 API 주소** | `NetworkManager.swift` | `baseURL` |
| **앱 WebSocket 주소** | `WebSocketManager.swift` | `url` |
| **다크 모드** | 앱 내 저장 | `@AppStorage("isDarkMode")` (기본 true) |

---

## 라이선스·기여

교육·팀 프로젝트용입니다. 문의·기여는 저장소 이슈/PR을 이용해 주세요.
