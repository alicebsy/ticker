# Ticker API 명세서 (노션 데이터베이스용)

**기본 URL:** `http://localhost:8080`  
**공통 헤더:** `X-User-Id` — 현재 사용자 ID (기본값: 1)

---

## 사용 방법

1. 노션에서 **/table** 또는 **/database** 입력 → 새 테이블/데이터베이스 생성
2. 아래 표 내용 **전체 선택** 후 복사
3. 노션 테이블의 **첫 번째 셀** 클릭 → 붙여넣기 (Cmd+V / Ctrl+V)
4. 탭으로 구분된 데이터가 컬럼별로 자동 입력됨

---

## 1. API 전체 목록

`API-SPEC-NOTION-DB.tsv` 파일을 열어 **전체 내용 복사** → 노션에 붙여넣기

또는 아래 블록 전체 복사:

```
구분	메서드	경로	설명	요청	응답
인증	GET	/api/auth/me	로그인된 사용자 정보	-	{ id, name, loginId, profileImageUrl, oauthProvider }
인증	GET	/api/auth/kakao/login-url	카카오 로그인 URL 안내	-	{ url, description }
인증	GET	/oauth2/authorization/kakao	카카오 로그인 (브라우저 리다이렉트)	-	카카오 로그인 페이지로 이동
포트폴리오	GET	/api/portfolio	내 포트폴리오 조회	-	총 자산, 보유 자산, 내 가치, 투자 중 종목, 보유 스킬, 상장 폐지 내역
상장	GET	/api/listing	상장 화면 (차트 + 상장 중 종목)	period (query): 1D, 7D, 1M	ListingResponse
상장	POST	/api/listing	신규 상장 (할 일 등록)	ListingRequest	Todo
상장	POST	/api/listing/{todoId}/complete	할 일 완료 (매도/상장 폐지)	-	200 OK
상장	PATCH	/api/listing/{todoId}/progress	진행률 업데이트	progress (query): 0~100	200 OK
투자	GET	/api/investments	보유 종목 목록	-	HeldStocksResponse
투자	POST	/api/investments/buy	매수	InvestRequest	Investment
투자	POST	/api/investments/{investmentId}/sell	매도	quantity (query, 선택): 판매 수량	200 OK
관심종목	GET	/api/watchlist	관심 종목 화면 (대기 요청 + 관심 종목 그리드)	-	WatchlistResponse
관심종목	GET	/api/watchlist/friends	친구 목록	-	User[]
관심종목	POST	/api/watchlist/friends	친구 추가 요청	FriendRequest	200 OK
관심종목	POST	/api/watchlist/friends/{requesterId}/accept	친구 요청 수락	-	200 OK
관심종목	POST	/api/watchlist/friends/{requesterId}/reject	친구 요청 거절	-	200 OK
관심종목	POST	/api/watchlist/{watchedUserId}	관심 종목에 추가	-	200 OK
암시장	GET	/api/darkmarket	암시장 화면 (아이템 목록, 오늘의 특가)	-	DarkMarketResponse
암시장	POST	/api/darkmarket/purchase	아이템 구매	PurchaseRequest	200 OK
카지노	GET	/api/casino	카지노 화면 (베팅 내역)	-	CasinoResponse
카지노	POST	/api/casino/bets	새 베팅	BetRequest	Bet
사용자	GET	/api/users/search	사용자 검색	q (query): 검색어	User[]
사용자	GET	/api/users/{userId}	사용자 프로필	-	User
할일	GET	/api/todos	상장 중인 할 일 목록	ownerId (query, 선택): 소유자 ID	Todo[]
할일	GET	/api/todos/{todoId}	할 일 상세	-	Todo
```

> ⚠️ 위 블록의 컬럼 구분자는 **탭(Tab)** 입니다.  
> 마크다운에서 복사하면 탭이 공백으로 바뀔 수 있으므로, **`API-SPEC-NOTION-DB.tsv`** 파일을 직접 열어 복사하는 것을 권장합니다.

---

## TSV 파일 목록 (탭 구분, 노션 붙여넣기 최적화)

| 파일 | 내용 |
|------|------|
| `API-SPEC-NOTION-DB.tsv` | API 전체 목록 (구분, 메서드, 경로, 설명, 요청, 응답) |
| `API-REQUEST-Listing.tsv` | POST /api/listing 요청 바디 필드 |
| `API-REQUEST-Invest.tsv` | POST /api/investments/buy 요청 바디 필드 |
| `API-REQUEST-Friend.tsv` | POST /api/watchlist/friends 요청 바디 필드 |
| `API-REQUEST-Purchase.tsv` | POST /api/darkmarket/purchase 요청 바디 필드 |
| `API-REQUEST-Bet.tsv` | POST /api/casino/bets 요청 바디 필드 |
| `API-ENUM.tsv` | 공통 enum 값 |

각 `.tsv` 파일을 열어 **Ctrl+A → Ctrl+C** 한 뒤 노션 테이블에 붙여넣으면 됩니다.
