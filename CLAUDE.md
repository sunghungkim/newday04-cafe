# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 현재 상태

아직 코드가 없고 기획 문서 [PRD.md](PRD.md)만 있다. 빌드, 린트, 테스트 명령은 없다. 구현 전에 PRD.md의 "확인이 필요한 항목"(숫자 카드 항목, 테이블 구조와 RLS, AI 모델, 재고 부족 기준)을 사용자와 확정한다. PRD는 한국어로 쓰여 있고 사용자도 한국어로 소통한다.

## 만드는 것

동네 카페 사장님용 운영 대시보드. 페이지 5개, 파일 하나씩:

- `index.html`: 틀. 왼쪽 메뉴 + 가운데 iframe으로 나머지 페이지를 전환하고, 첫 화면에 홈 숫자 카드, 7일 매출 그래프, AI 오늘 브리핑을 둔다.
- `sales.html`: 판매 입력과 매출 내역
- `menu.html`: 메뉴 · 재고 관리
- `reviews.html`: 리뷰 목록과 AI 답글
- `promo.html`: AI 홍보 문구

## 아키텍처 제약

- 프론트엔드는 npm과 빌드 도구 없이 페이지당 HTML 파일 하나(CSS, JS 인라인)로 만든다. 파일을 열기만 해도 동작해야 한다.
- 파일이 서로 독립이라 공통 색과 글꼴은 공유 파일이 없다. 모든 페이지에 같은 값을 복사해 쓰므로, 디자인 값을 바꿀 때는 5개 파일을 모두 맞춘다.
- 디자인은 Vapor UI(구름) 스타일: 흰 표면 + 옅은 회색 배경, 1px 헤어라인, 파란 primary(#2A72E5), 반경 8px, 글꼴 Pretendard(굵기 400/500/700만 사용, 600 없음), 그라디언트·블러 없음, 버튼은 짧은 명령형, 문구는 존댓말. 기준 값은 `index.html`의 `:root` 토큰이고 다크 모드는 `prefers-color-scheme`로 처리한다.
- DB는 사용자의 Supabase 프로젝트 `day04-cafe`. 테이블 초안은 `menus`, `sales`, `reviews`(확정 전).
- AI 기능은 Edge Function `cafe-ai` 하나가 처리한다. 답글, 홍보 문구, 오늘 브리핑은 요청 값으로 구분한다.
- AI 키는 Edge Function의 비밀 값에만 두고, 브라우저 코드에는 Supabase 공개(anon) 키만 쓴다. 로그인이 없으므로 anon 키로 허용할 범위(RLS)를 정해서 적용한다.
- 범위 밖: 로그인, 결제/POS 연동, 외부 리뷰 사이트 자동 수집, SNS 자동 게시, 모바일 앱.

## Git

- 원격 `origin`: https://github.com/sunghungkim/day04-cafe (로컬 브랜치는 `master`, 푸시 전에 원격 기본 브랜치 이름을 확인한다.)
- 이 저장소의 git 사용자 설정은 로컬 설정으로 되어 있다.
