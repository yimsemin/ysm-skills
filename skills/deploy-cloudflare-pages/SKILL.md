---
name: deploy-cloudflare-pages
description: Set up, audit or fix a project's Cloudflare Pages deployment (GitHub-connected, main for production, develop for previews, npm build to dist, custom domain) using the Cloudflare API with a standard that lives only in this repository. Use when the user asks to deploy to Cloudflare Pages, connect a repo to Pages, align Pages settings, or add a custom domain. 클라우드플레어 페이지 배포, 페이지 설정 맞추기, 커스텀 도메인 연결, 배포 설정 점검.
---

# deploy-cloudflare-pages

프로젝트의 Cloudflare Pages 설정을 이 저장소의 표준에 맞춘다. 표준·API 절차·제약의 정본은 `docs/cloudflare-pages.md`이고 이 스킬에 다시 쓰지 않는다.

## 실행 위치

**Cloudflare 배포와 관리는 이 저장소 폴더에서만 한다.** Cloudflare API 토큰이 이 저장소의 `.env`(또는 환경변수)에만 있기 때문이다. 다른 프로젝트 폴더에서 이 저장소를 참조해 배포하는 방식은 쓰지 않는다. 그런 요청이 오면 이 저장소 폴더에서 다시 요청하라고 안내하고 멈춘다.

사용자는 이 폴더에서 "(소유자/대상 저장소)를 Cloudflare Pages 배포해줘"라고 한다. 대상 저장소는 `gh api`로만 읽고, 코드 변경이 필요하면 직접 고치지 않는다(4단계). 이 스킬이나 표준 문서의 내용·링크를 대상 저장소의 `AGENTS.md`·`README.md`·베이스라인에 복사하지 않는다.

## 0. 준비

`docs/cloudflare-pages.md`를 끝까지 읽는다.

## 1. 자격을 확인한다

`docs/cloudflare-pages.md`의 "토큰"에 따라 `CLOUDFLARE_API_TOKEN`이 환경변수나 작업 폴더 `.env`에 있는지 값을 출력하지 않고 확인하고, `GET /accounts`와 Pages 목록 조회가 되는지 본다.

- 토큰이 없거나 권한이 부족하면(인증 오류) 만드는 순서를 구체적으로 안내하고 멈춘다: 대시보드 프로필 → API 토큰 → 사용자 지정 토큰, 문서의 권한 목록, 저장 위치(`.env` 또는 환경변수). 토큰을 대화에 붙여넣게 하지 않는다. 토큰을 저장소에 쓰거나 커밋하지 않는다.
- 계정이 둘 이상이거나 루트 도메인 영역이 같은 계정에 없으면 사용자에게 묻는다.

## 2. 대상 저장소의 사실을 모은다

`gh api`로 읽는다. 값을 지어내지 않는다.

- 기본 브랜치, 브랜치 목록(`main`, `develop` 유무), 이미 있는 PR 흐름.
- `package.json`의 `build` 스크립트와 패키지 매니저(락파일), 워크스페이스 여부, 빌드 출력 폴더(`vite.config`, `scripts` 등), `.node-version`·`.nvmrc`·`engines`.
- 정적 사이트인지, `functions/`나 Worker 코드(`wrangler.*`)가 있는지, `_redirects`·`_headers` 유무, `.github/workflows`에 배포 단계가 있는지.

## 3. 현재 Cloudflare 상태를 조회하고 계획을 세운다

Pages 프로젝트 목록과 대상 이름의 프로젝트(있다면 `GET .../projects/<이름>`), 같은 이름의 Worker, DNS 레코드를 조회한다. 표준 표와 비교해 **차이 목록**을 만들고, 아래 유형으로 계획을 정리한다.

- 프로젝트가 없다 → 새로 만든다. 있고 Git 연동이다 → 차이만 PATCH한다. 있고 직접 업로드다 / Worker다 → 삭제 후 새로 만들기(문서의 제약 참고).
- 저장소 쪽 선행 변경이 필요한 것(`develop` 브랜치, `build` 스크립트, `.node-version`, 배포 워크플로 제거, 워크스페이스 설정).
- 프로덕션 도메인: **사용자에게 묻는다.** 권장 기본값과 루트 도메인을 함께 제시한다.

계획을 먼저 보여 준다. 아래는 사용자가 이번 요청에서 승인했거나 계획에 명시해 승인받은 것만 실행한다: Pages 프로젝트 생성·삭제, 설정 변경, 도메인 연결과 DNS 레코드, GitHub `develop` 브랜치 생성. 같은 이름 삭제처럼 되돌릴 수 없는 것은 반드시 별도로 확인한다. 계획 단계에서는 읽기만 한다.

## 4. 저장소 쪽 변경

저장소 쪽 선행 변경이 있으면 Cloudflare 프로젝트를 만들기 전에 끝낸다(첫 빌드가 `main`의 상태로 돈다).

대상 저장소를 이 폴더에서 고치지 않는다. 필요한 변경과 이유를 짧은 프롬프트로 써서 사용자가 대상 저장소에서 실행하게 하거나, 사용자가 시키면 클라우드 세션(`start_session`의 `target: "cloud"`와 `repository`)으로 맡긴다. 프롬프트에는 대상 브랜치, 바꿀 파일, 확인 명령, "커밋 후 푸시까지만, PR·병합 금지"를 적는다.

## 5. Cloudflare 쪽 실행

`docs/cloudflare-pages.md`의 "API 절차"대로 한 단계씩 실행하고 매 응답의 `success`를 읽는다. 순서는 (필요하면) 브랜치 생성 → 프로젝트 생성 또는 PATCH → 첫 배포 요청 → 빌드 결과 확인 → 도메인 추가와 CNAME. 같은 이름을 삭제해야 하면 임시 이름으로 같은 설정을 먼저 만들어 빌드와 응답이 정상인 것을 확인한 뒤에 삭제하고 다시 만들고, 임시 프로젝트는 지운다. 빌드가 실패하면 빌드 로그 끝부분을 읽어 원인을 사용자에게 보고하고, 기존 프로젝트를 지우지 않는다.

폴링은 한 번의 호출에서 `sleep` 루프로 하고, 오래 걸리면 백그라운드로 돌린다. 매번 전체 목록을 다시 읽지 않고 필요한 필드만 문서의 `jv`로 뽑는다(`jq`는 쓰지 않는다).

## 6. 검증하고 보고한다

문서의 "확인 항목"을 API로 새로 조회해 하나씩 확인하고, 도메인은 실제로 `curl`한다. 보고는 한 일 / 확인하지 못한 것 / 하지 않은 것으로 나누고, 사용자가 해야 할 일(토큰 권한, GitHub 앱 승인, 인증서 대기, 푸시·병합)을 맨 위에 적는다. 대상 저장소에 이 표준에 대한 문서를 추가하지 않는다.
