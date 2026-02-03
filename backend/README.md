# Ticker Backend

Human Stock Market - 주식 컨셉 투두리스트 백엔드  
친구들이 서로의 할 일에 배팅하고 투자하는 Spring Boot API

## 실행 방법

```bash
# Gradle
./gradlew bootRun

# 또는 JAR 빌드 후 실행
./gradlew build
java -jar build/libs/ticker-0.0.1-SNAPSHOT.jar
```

서버: `http://localhost:8080`  
H2 Console: `http://localhost:8080/h2-console`

## API 엔드포인트

모든 API에서 `X-User-Id` 헤더로 현재 사용자 ID 전달 (기본값: 1)

### 포트폴리오
- `GET /api/portfolio` - 내 포트폴리오 (총 자산, 투자 중 종목, 보유 스킬, 상장 폐지 내역)

### 상장 (Listing)
- `GET /api/listing?period=7D` - 상장 화면 (내 주가 차트, 상장 중인 종목)
- `POST /api/listing` - 신규 상장 (할 일 등록)
- `POST /api/listing/{todoId}/complete` - 할 일 완료
- `PATCH /api/listing/{todoId}/progress?progress=66` - 진행률 업데이트

### 보유 종목 (투자)
- `GET /api/investments` - 보유 종목 목록
- `POST /api/investments/buy` - 매수
- `POST /api/investments/{id}/sell?quantity=5` - 매도

### 관심 종목 (Watchlist)
- `GET /api/watchlist` - 관심 종목 화면 (대기 요청, 관심 종목 그리드)
- `GET /api/watchlist/friends` - 친구 목록
- `GET /api/watchlist/my-friend-code` - 내 친구 코드 조회 (없으면 자동 발급)
- `POST /api/watchlist/regenerate-friend-code` - 친구 코드 재발급
- `POST /api/watchlist/friends` - 친구 추가 요청 (body: `friendUserId` 또는 `friendCode`)
- `POST /api/watchlist/friends/{requesterId}/accept` - 요청 수락
- `POST /api/watchlist/friends/{requesterId}/reject` - 요청 거절
- `POST /api/watchlist/{watchedUserId}` - 관심 종목에 추가

### WebSocket (실시간 알림)
- **연결**: `ws://localhost:8080/ws` (SockJS + STOMP)
- **구독 1 — 유저 알림**: `/topic/user/{userId}/notifications`  
  - 친구 요청/수락/거절 알림  
  - `type`: FRIEND_REQUEST, FRIEND_ACCEPTED, FRIEND_REJECTED
- **구독 2 — 주가·상장 실시간**: `/topic/stock/{userId}`  
  - **주가 변동**: STOCK_PRICE_UPDATED, `userId`, `stockPrice`, `marketCap`, `totalAssets`  
  - **할 일 완료/진행률/신규 상장**: LISTING_UPDATED, `userId`, `todoId`, `progress`, `completed`  
  - **내 주식 매수/매도**: INVESTMENT_CHANGED, `userId`, `remainingShares` (남은 매물 주 수)  
- **유저 알림** (`/topic/user/{userId}/notifications`) 추가 타입:  
  - BET_PLACED: 내 할 일에 베팅이 걸림 (`fromUserId`, `todoId`)  
  - ADDED_TO_WATCHLIST: 나를 관심 종목에 추가함

### 암시장
- `GET /api/darkmarket` - 암시장 화면 (아이템 목록, 오늘의 특가)
- `POST /api/darkmarket/purchase` - 아이템 구매

### 카지노
- `GET /api/casino` - 카지노 화면 (베팅 내역)
- `POST /api/casino/bets` - 새 베팅

### 사용자 / 할 일
- `GET /api/users/search?q=김` - 친구 검색
- `GET /api/users/{id}` - 사용자 프로필
- `GET /api/todos?ownerId=2` - 친구의 상장 중인 할 일 목록

### 카카오 로그인
- `GET /oauth2/authorization/kakao` - 카카오 로그인 (브라우저에서 접속)
- `GET /api/auth/me` - 로그인된 사용자 정보 (OAuth 세션 필요)
- `GET /api/auth/kakao/login-url` - 카카오 로그인 URL 안내

**설정 방법 (Kakao Developers)**
1. [Kakao Developers](https://developers.kakao.com) 에서 앱 생성
2. 카카오 로그인 활성화, Redirect URI 등록: `http://localhost:8080/login/oauth2/code/kakao`
3. 환경변수 또는 application.yml에 설정:
   - `KAKAO_REST_API_KEY`: REST API 키
   - `KAKAO_CLIENT_SECRET`: 보안키 (활성화 시)
   - `OAUTH_REDIRECT_URI`: 로그인 후 이동할 URL (예: `ticker://oauth` for Swift)

---

## 백엔드 테스트 방법

### 1. 서버 실행

**필수:** MySQL이 `localhost:3306`에서 실행 중이어야 합니다. (또는 `application.yml`에서 URL/계정 수정)

```bash
cd backend
./gradlew bootRun
```

정상 기동 시 터미널에 `Started TickerApplication` 이 보이고, 포트는 기본 **8080** 입니다.

### 2. Swagger UI로 테스트 (추천)

브라우저에서 아래 주소로 접속하면 API 목록과 "Try it out"으로 요청을 보낼 수 있습니다.

- **Swagger UI:** http://localhost:8080/swagger-ui.html  
- **API 스펙(JSON):** http://localhost:8080/v3/api-docs

대부분 API는 인증 없이 호출 가능하고, `X-User-Id` 헤더로 사용자 ID를 넘깁니다. (Swagger에서 헤더 추가 가능)

### 3. curl로 빠르게 확인

서버가 떠 있는 상태에서 터미널에서 실행해 보세요.

```bash
# 기본 헤더 (사용자 ID=1 로 테스트)
H="X-User-Id: 1"
BASE="http://localhost:8080"

# 헬스 체크 (서버 살아있는지)
curl -s -o /dev/null -w "%{http_code}" $BASE/api/portfolio -H "$H"

# 내 친구 코드 조회 (없으면 자동 발급)
curl -s $BASE/api/watchlist/my-friend-code -H "$H"

# 관심 종목 화면 (대기 요청, 관심 종목)
curl -s $BASE/api/watchlist -H "$H"

# 친구 추가 (친구 코드로)
# curl -X POST $BASE/api/watchlist/friends -H "$H" -H "Content-Type: application/json" -d '{"friendCode":"상대방친구코드"}'

# 친구 추가 (사용자 ID로)
# curl -X POST $BASE/api/watchlist/friends -H "$H" -H "Content-Type: application/json" -d '{"friendUserId":2}'

# 회원가입 테스트
# curl -X POST $BASE/api/auth/signup -H "Content-Type: application/json" -d '{"loginId":"test1","password":"1234","name":"테스트"}'

# 로그인 테스트
# curl -X POST $BASE/api/auth/login -H "Content-Type: application/json" -d '{"loginId":"test1","password":"1234"}'
```

### 4. DataLoader로 DB에 사용자 있는 경우

`userRepository.count() == 0` 일 때만 DataLoader가 샘플 유저(kim, lee, park, choi)를 넣습니다.  
처음 한 번은 DB를 비우고 서버를 켜면 1~4번 사용자와 친구 코드가 생깁니다.

- 사용자 1(kim)의 친구 코드: `GET /api/watchlist/my-friend-code` (X-User-Id: 1)
- 사용자 2(lee)를 사용자 1이 친구 코드로 추가:  
  `POST /api/watchlist/friends` body: `{"friendCode":"2번유저의친구코드"}` + X-User-Id: 1

이렇게 하면 서버 실행 → Swagger 또는 curl로 백엔드 동작을 확인할 수 있습니다.
