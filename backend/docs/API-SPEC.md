# Ticker API 명세서

기본 URL: `http://localhost:8080`  
공통 헤더: `X-User-Id` — 현재 사용자 ID (기본값: 1)

---

## 인증 (Auth)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| POST | `/api/auth/signup` | 일반 회원가입 | SignupRequest | `{ id, loginId, name, message }` |
| POST | `/api/auth/login` | 일반 로그인 | LoginRequest | `{ id, loginId, name, profileImageUrl, cashBalance, marketCap, totalAssets, message }` |
| GET | `/api/auth/me` | 로그인된 사용자 정보 (OAuth) | - | `{ id, name, loginId, profileImageUrl, oauthProvider }` |
| GET | `/api/auth/kakao/login-url` | 카카오 로그인 URL 안내 | - | `{ url, description }` |
| GET | `/oauth2/authorization/kakao` | 카카오 로그인 (브라우저 리다이렉트) | - | 카카오 로그인 페이지로 이동 |

### SignupRequest (POST /api/auth/signup)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| loginId | string | ○ | 로그인 ID (3~50자) |
| password | string | ○ | 비밀번호 (4자 이상) |
| name | string | ○ | 사용자 이름 (닉네임) |
| profileImageUrl | string | × | 프로필 이미지 URL |

### LoginRequest (POST /api/auth/login)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| loginId | string | ○ | 로그인 ID |
| password | string | ○ | 비밀번호 |

---

## 포트폴리오 (Portfolio)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/portfolio` | 내 포트폴리오 조회 | - | 총 자산, 보유 자산, 내 가치, 투자 중 종목, 보유 스킬, 상장 폐지 내역 |

---

## 상장 (Listing)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/listing` | 상장 화면 (차트 + 상장 중 종목) | `period` (query, 선택): 1D, 7D, 1M | ListingResponse |
| POST | `/api/listing` | 신규 상장 (할 일 등록) | ListingRequest | Todo |
| POST | `/api/listing/{todoId}/complete` | 할 일 완료 (매도/상장 폐지) | - | 200 OK |
| PATCH | `/api/listing/{todoId}/progress` | 진행률 업데이트 | `progress` (query): 0~100 | 200 OK |

### ListingRequest (POST /api/listing)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| name | string | ○ | 종목명 (할 일) |
| deadline | date | ○ | 마감일 (yyyy-MM-dd) |
| rewardPoints | long | × | 공모가 (생략 시 난이도×주가/100 자동 계산) |
| difficulty | enum | × | EASY, NORMAL, HARD (기본: NORMAL) |
| visibility | enum | × | FRIENDS_ONLY, PUBLIC (기본: FRIENDS_ONLY) |

---

## 보유 종목 / 투자 (Investments)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/investments` | 보유 종목 목록 | - | HeldStocksResponse |
| POST | `/api/investments/buy` | 매수 | InvestRequest | Investment |
| POST | `/api/investments/{investmentId}/sell` | 매도 | `quantity` (query, 선택): 판매 수량 (미입력 시 전량) | 200 OK |

### InvestRequest (POST /api/investments/buy)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| todoId | long | ○ | 대상 할 일(종목) ID |
| quantity | int | ○ | 매수 수량 (1 이상) |

---

## 관심 종목 / 친구 (Watchlist)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/watchlist` | 관심 종목 화면 (대기 요청 + 관심 종목 그리드) | - | WatchlistResponse |
| GET | `/api/watchlist/friends` | 친구 목록 | - | User[] |
| POST | `/api/watchlist/friends` | 친구 추가 요청 | FriendRequest | 200 OK |
| POST | `/api/watchlist/friends/{requesterId}/accept` | 친구 요청 수락 | - | 200 OK |
| POST | `/api/watchlist/friends/{requesterId}/reject` | 친구 요청 거절 | - | 200 OK |
| POST | `/api/watchlist/{watchedUserId}` | 관심 종목에 추가 | - | 200 OK |

### FriendRequest (POST /api/watchlist/friends)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| friendUserId | long | ○ | 추가할 친구의 사용자 ID |

---

## 암시장 (Dark Market)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/darkmarket` | 암시장 화면 (아이템 목록, 오늘의 특가) | - | DarkMarketResponse |
| POST | `/api/darkmarket/purchase` | 아이템 구매 | PurchaseRequest | 200 OK |

### PurchaseRequest (POST /api/darkmarket/purchase)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| marketItemId | long | ○ | 구매할 아이템 ID |
| quantity | int | ○ | 구매 수량 (1 이상) |

---

## 카지노 (Casino)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/casino` | 카지노 화면 (베팅 내역) | - | CasinoResponse |
| POST | `/api/casino/bets` | 새 베팅 | BetRequest | Bet |

### BetRequest (POST /api/casino/bets)

| 필드 | 타입 | 필수 | 설명 |
|------|------|------|------|
| todoId | long | ○ | 베팅할 친구의 할 일 ID |
| amount | long | ○ | 베팅 금액 (P) |
| predictSuccess | boolean | ○ | true: 성공 예측, false: 실패 예측 |

---

## 사용자 (Users)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/users/search` | 사용자 검색 | `q` (query): 검색어 | User[] |
| GET | `/api/users/{userId}` | 사용자 프로필 | - | User |

---

## 할 일 (Todos)

| 메서드 | 경로 | 설명 | 요청 | 응답 |
|--------|------|------|------|------|
| GET | `/api/todos` | 상장 중인 할 일 목록 | `ownerId` (query, 선택): 소유자 ID | Todo[] |
| GET | `/api/todos/{todoId}` | 할 일 상세 | - | Todo |

---

## 공통 enum

| enum | 값 |
|------|-----|
| Difficulty | EASY, NORMAL, HARD |
| Visibility | FRIENDS_ONLY, PUBLIC |
| TodoStatus | LISTED, COMPLETED, DELISTED |
| BetStatus | PENDING, WON, LOST |
