# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

동네 카페 사장님용 운영 대시보드. 사용자와 PRD([PRD.md](PRD.md))는 한국어이고, 화면 문구도 존댓말 한국어다. 빌드, 린트, 테스트 명령은 없다.

## 실행

- 이 PC에는 Python과 Node가 없다. 로컬 서버는 `powershell -File serve.ps1`(기본 포트 8000, PowerShell 전용)이고, `.claude/launch.json`의 `cafe` 설정으로도 띄운다. 다른 세션이 이미 8000번을 쓰고 있으면 `preview_start`가 실패하니, 그 서버가 같은 폴더를 서빙하는지 보고 그대로 쓴다.
- `index.html`을 열면 로그인 화면이 먼저 나온다. 시험할 때는 직원 입장(이름만 입력)이나 관리자 로그인을 쓰면 되고, 다른 페이지 주소를 직접 열면 로그인 화면으로 돌려보낸다.

## 구조

페이지마다 HTML 파일 하나(CSS, JS 인라인, npm 없음). 공유 파일이 없어서 공통 코드는 파일마다 복사해 쓴다.

- `index.html`: 틀. 로그인 화면, 왼쪽 메뉴, 가운데 iframe, 그리고 홈 화면(숫자 카드 4개, 7일 매출 막대그래프, AI 오늘 브리핑)을 직접 가지고 있다.
- `sales.html` 판매 입력과 오늘 판매 / `menu.html` 메뉴·재고 / `reviews.html` 리뷰 목록(5개씩 쪽 나누기)과 AI 분석 / `promo.html` AI 홍보 문구와 직접 쓰기 / `rivals.html` 주변 카페(API 키 없는 구글 지도 퍼가기와 네이버맵 링크).
- 새 페이지를 추가하면 `index.html`의 `PAGES`와 메뉴 버튼, 그리고 아래 공통 항목을 모두 맞춘다.

### 파일마다 같게 유지해야 하는 것

- **디자인 값**: `:root` 색 변수(라이트 21개, 다크 18개, `prefers-color-scheme`)가 다섯 파일에서 값까지 같다. Vapor UI 스타일(흰 표면, 옅은 회색 배경, 1px 선, 파랑 `#2A72E5`, 반경 8px, Pretendard, 굵기 400/500/700만, 그라디언트·블러 없음). 기본 버튼 40px, 목록 안 작은 버튼 36px, 카드 여백 24px(숫자 카드만 20px). 값을 바꿀 때는 모든 페이지를 같이 바꾼다.
- **오류 문구 도우미**: `netFetch`(인터넷 끊김만 `e.network` 표시), `friendly(e, what)`, `aiFriendly(e, what)`가 페이지마다 복사돼 있다. `what`은 "저장하", "불러오", "만들"처럼 "지 못했습니다" 앞에 붙는 어간이다(예: `friendly(e, "메뉴 목록을 불러오")`). 영어 오류 원문을 화면에 그대로 보이지 않는다.
- **날짜는 한국 시간(Asia/Seoul)**: "오늘"은 PC 시간대와 상관없이 `Intl`로 한국 날짜를 계산하고(홈, `sales.html`), 시각·날짜 표시에도 `timeZone: "Asia/Seoul"`을 준다.
- **AI 호출**: 화면은 `AbortSignal.timeout(75_000)`으로 기다리는 시간을 제한한다(함수가 최대 3번 다시 해 보는 시간). `netFetch`는 이 시간 초과를 인터넷 끊김이 아니라 504로 표시한다.
- 서버는 한 번에 1000행까지만 주므로, 많아질 수 있는 목록은 `limit/offset`으로 나눠 받는다(홈의 7일 판매 `apiAll`, 리뷰 5개씩 쪽 나누기).
- 사용자 글(리뷰, 메뉴 이름, AI 답글)은 `textContent`/`el()`로만 넣는다. `innerHTML`을 쓰지 않는다.

## 데이터 (Supabase 프로젝트 `day04-cafe`)

- 브라우저는 REST로 직접 읽고 쓴다. 주소와 공개용(publishable) 키는 각 페이지에 상수로 들어 있고, 비밀 키는 어디에도 두지 않는다.
- 테이블: `menus`(이름, 분류, 가격, 재고), `sales`(menu_id, menu_name, quantity, amount, sold_at), `reviews`(rating 1~5, content, sentiment, reply, written_at). `reviews.sentiment`는 `좋음`/`보통`/`아쉬움`만 허용한다(CHECK).
- 로그인 없이 쓰도록 anon에 전체 권한과 RLS 정책(`using (true)`)을 줬다. 의도된 설계다.
- 판매 입력은 DB 함수 `record_sale(p_menu_id, p_quantity)`(RPC)가 판매 기록과 재고 차감을 한 번에 처리하고 판매 행을 돌려준다. 재고가 모자라면 `out_of_stock` 오류.
- **테이블 정의와 `record_sale`은 이 저장소에 파일로 없다.** Supabase에만 있으니 바꾸면 Supabase 커넥터(`apply_migration`)로 하고, 필요하면 `supabase/migrations/`에 SQL을 남긴다.
- 지금 들어 있는 데이터는 대부분 시험용 가짜 데이터다(메뉴 19개, 판매 400여 건, 리뷰 40건).

## AI: Edge Function `cafe-ai`

- 소스는 `supabase/functions/cafe-ai/index.ts`이고, 배포는 Supabase 커넥터의 `deploy_edge_function`(`verify_jwt` 꺼짐)으로 한다. **파일을 고치면 같은 내용으로 다시 배포해야 한다.** 저장소 파일과 배포본이 어긋나지 않게 한다.
- 요청의 `type`으로 구분한다: `review`(감정과 답글 초안), `promo`(문구 3개), `brief`(세 줄 브리핑, 선택으로 `weekly` 7일 매출).
- 모델은 `openrouter/free`, 키는 Secrets의 `OPENROUTER_API_KEY`에서만 읽는다. 무료 라우터라 요청마다 다른 모델이 걸려 느리거나 형식이 틀린 답이 올 수 있다. 읽지 못하면(502) 최대 3번 다시 시도하고, 한도 초과(429)는 다시 시도하지 않고 바로 알린다.
- **무료 사용량이 빠듯하다.** 시험 호출을 많이 하면 429가 나서 한동안 AI가 안 된다. 같은 요청을 동시에 여러 개 보내는 방식(`COPIES`)은 사용량을 그만큼 더 쓰므로 1로 둔다.

## 로그인 (화면 잠금, 실제 보안 아님)

- 직원은 이름만 넣고 입장하고, 관리자는 아이디·비밀번호를 확인한다. 비밀번호는 코드에 해시(SHA-256 "아이디:비밀번호")로만 있고, 이 문서나 다른 곳에 값을 적지 않는다. 5번 실패하면 30초 잠긴다.
- 로그인 상태는 `sessionStorage`의 `cafe-session`(`{role, name}`)이다. 각 페이지 `<head>`의 짧은 스크립트가 로그인 없이 열린 페이지를 `index.html`로 보낸다.
- 권한: 직원은 `menu.html`에서 재고만 고칠 수 있고, 메뉴 추가·삭제·가격 수정은 관리자만 한다. 이것도 화면에서만 막는 것이라, 코드를 보거나 DB를 직접 호출하면 우회된다. 진짜로 막으려면 Supabase Auth와 RLS가 필요하다.

## 도구

- `.claude/agents/code-reviewer.md`: 코드를 읽고 버그, 키 노출, 에러 처리, 페이지 간 차이를 보고만 하는 서브에이전트(Read/Grep/Glob). 세션 도중에 만든 에이전트는 그 세션에서 불러와지지 않을 수 있다.

## Git

- 원격 `origin`: https://github.com/sunghungkim/newday04-cafe.git, 브랜치는 `master`. 이 저장소의 git 사용자 설정은 로컬 설정이다.
