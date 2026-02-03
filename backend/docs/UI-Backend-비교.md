# UI vs 백엔드 비교 (미연동·부족 항목)

## 1. 현재 연동 상태

| 기능 | iOS (UI) | 백엔드 API | 연동 여부 |
|------|----------|------------|-----------|
| 회원가입 | `POST /auth/signup` | ✅ 있음 | ✅ 연동됨 |
| 로그인 (이메일) | `POST /auth/login` | ✅ 있음 | ✅ 연동됨 |
| 카카오 로그인 | OAuth2 + `GET /users/{id}` | ✅ 있음 | ✅ 연동됨 |
| 유저 정보 조회 | `GET /users/{id}` | ✅ 있음 | ✅ 연동됨 |
| **친구/관심종목** | 샘플 데이터 | `GET /api/watchlist`, `/friends`, `POST /friends`, `my-friend-code` 등 | ❌ 미연동 |
| **보유 종목(홀딩)** | 로컬 only | `GET /api/investments`, `POST /buy`, `POST /{id}/sell` | ❌ 미연동 |
| **내 투두/상장** | 로컬 only | `GET /api/listing`, `POST /api/listing`, `POST /{todoId}/complete` | ❌ 미연동 |
| **포트폴리오** | 로컬 계산 | `GET /api/portfolio` | ❌ 미연동 |
| **카지노/베팅** | 로컬 only | `GET /api/casino`, `POST /api/casino/bets` | ❌ 미연동 |
| **뉴스** | 샘플 데이터 | `GET/POST /api/news`, 댓글, 좋아요 | ❌ 미연동 |
| **암시장(스토어)** | 샘플 데이터 | `GET /api/darkmarket`, `POST /api/darkmarket/purchase` | ❌ 미연동 |
| **친구 검색** | (미사용) | `GET /api/users/search` | ❌ 미연동 |

→ **백엔드 API는 대부분 구현되어 있고, iOS 쪽에서 호출만 안 하고 있는 상태입니다.**

---

## 2. 백엔드에서 보완하면 좋은 것 (UI 기준)

### 2-1. 로그인/회원가입 응답에 `stockPrice` 없음
- **UI**: 이메일 로그인 시 `stockPrice`를 1000으로 하드코딩해서 사용 중.
- **백엔드**: `POST /auth/signup`, `POST /auth/login` 응답에 `stockPrice` 필드 없음.
- **제안**: signup/login 응답에 `stockPrice` 추가하면, 카카오 로그인(`UserResponse`)과 동일하게 맞출 수 있음.

### 2-2. 활동 내역(Activity) API 없음
- **UI**: 포트폴리오 등에서 "활동 내역" (매수/매도/베팅/구매/상장 등) 표시.
- **백엔드**: 활동 로그를 저장/조회하는 API 없음.
- **제안**: 필요하면 “활동 로그” 엔티티 + `GET /api/me/activities` 같은 API 추가 검토.

### 2-3. Watchlist → Friend 매핑 시 부족한 필드
- **UI Friend**: `ticker`, `bio`, `avatarColor`, `sparklineData`, `sharesOutstanding`, `todayRecord`, `dailyRecords` 등 사용.
- **백엔드 WatchlistResponse.WatchlistItemDto**: `userId`, `name`, `imageUrl`, `currentPrice`, `changePercent`, `chartData` 정도만 제공.
- **제안**:  
  - “전체 종목” 리스트만 쓴다면 현재 DTO로도 매핑 가능 (부족한 건 앱에서 기본값 처리).  
  - 친구별 상세(투두, 차트 등)가 필요하면 `GET /api/users/{id}` 또는 포트폴리오/리스팅 API로 추가 정보 보강.

### 2-4. 기타
- **암시장 경로**: 백엔드는 ` /api/darkmarket` (소문자 연속). iOS 연동 시 이 경로 그대로 사용하면 됨.
- **요청 시 `X-User-Id`**: 로그인 사용자 구분용으로 대부분 API가 `X-User-Id` 헤더 사용. iOS 연동 시 `currentUser.id` 넣어서 보내면 됨.

---

## 3. 요약

| 구분 | 내용 |
|------|------|
| **백엔드 구현** | 로그인/회원가입, 유저, Watchlist, Listing, Portfolio, Investment, Casino, News, Dark Market, Todo 등 **필요한 API는 거의 다 있음**. |
| **미연동** | **iOS가 샘플/로컬만 쓰고 있어서** 친구, 홀딩, 투두, 포트폴리오, 카지노, 뉴스, 스토어는 전부 **백엔드 호출이 안 된 상태**. |
| **백엔드에서 채우면 좋은 것** | ① signup/login 응답에 `stockPrice` 추가, ② (선택) 활동 내역 API 추가, ③ Watchlist는 현재 구조로 연동 가능, 상세는 기존 API로 보강. |

정리하면, **“UI에 있는데 백엔드에 아예 없는 기능”은 거의 없고**,  
**“백엔드에는 있는데 iOS에서 안 쓰는 부분”이 많고**,  
**“UI와 맞추려면 백엔드에서 조금만 보완하면 되는 부분”**은 위 2번 항목들입니다.
