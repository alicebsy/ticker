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
- `POST /api/watchlist/friends` - 친구 추가 요청
- `POST /api/watchlist/friends/{requesterId}/accept` - 요청 수락
- `POST /api/watchlist/friends/{requesterId}/reject` - 요청 거절
- `POST /api/watchlist/{watchedUserId}` - 관심 종목에 추가

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
