# ysm-skills

> 여러 컴퓨터와 프로젝트에서 에이전트(Claude Code, Codex) 작업환경을 같은 기준으로 맞추는 스킬과 규칙 모음

## 할 수 있는 것

- **새 프로젝트 기본 세팅**: 빈 폴더에서 의도를 정리하고 공통 규칙(`AGENTS.md`), Git 훅(커밋 메시지·비밀값·보호 브랜치 검사), 에이전트 설정을 한 번에 적용한다.
- **기존 프로젝트 맞추기와 갱신**: 바꾸기 전에 진단해 보고하고 승인한 항목만 맞춘다. 공통 규칙이 바뀌면 차이를 보여 주고 갱신한다.
- **컴퓨터 전역 지침**: Claude Code·Codex의 전역 지침(소통·판단·검증 방식)을 GitHub 최신본과 비교해 점검하고 승인한 뒤 설치한다.
- **점검·운영**: 문서·코드·테스트·문구 점검, 릴리즈 절차, Cloudflare Pages 배포, 교훈 공유, 일러스트 제작.

에이전트에게 "yimsemin/ysm-skills 저장소를 보고 ~해줘"라고 요청하면 된다. Claude Code 플러그인으로 설치하면 스킬 이름으로 직접 부를 수도 있다([아래](#고급-claude-code-플러그인)).

## 대표 사용 예시
### 새 프로젝트 시작하기
```
~를 만들거야

yimsemin/ysm-skills 저장소를 보고 기본 셋팅해줘
```

### 문서 / 코드 / 테스트 점검
```
yimsemin/ysm-skills 저장소를 보고 문서 최적화 해줘
```

```
yimsemin/ysm-skills 저장소를 보고 코드 최적화 해줘
```

```
yimsemin/ysm-skills 저장소를 보고 테스트 최적화 해줘
```

### 일러스트 제작

```
yimsemin/ysm-skills 저장소의 riso-illustration으로 "팀이 함께 퍼즐을 맞추는 장면" 웹사이트 메인용 일러스트 만들어줘
```

### 컴퓨터 전역 지침 점검·갱신

어느 폴더에서 요청해도 된다. 프로젝트 스킬은 전역 지침을 건드리지 않으므로, 새 컴퓨터를 세팅하거나 이 저장소가 갱신됐을 때 직접 요청한다.

```
yimsemin/ysm-skills 저장소를 보고 전역 지침 업데이트 해줘
```

### Cloudflare Pages 배포

이 저장소를 받은 폴더에서 에이전트를 열고 요청한다. 본인 Cloudflare API 토큰이 필요하다([docs/cloudflare-pages.md](docs/cloudflare-pages.md)의 "토큰").

```
<소유자>/<대상 저장소>를 Cloudflare Pages로 배포해줘
```


## 스킬

어느 프로젝트에서나 쓰는 스킬(플러그인으로 배포, `skills/`):

| 스킬 | 용도 |
|---|---|
| `new-project` | 빈 폴더에서 의도부터 시작해 베이스라인 적용 |
| `adopt-project` | 기존 프로젝트에 처음 적용하거나, 이미 적용한 프로젝트를 최신 베이스라인으로 갱신. 수정 없이 진단해 보고한 뒤 승인한 항목만 맞춤 |
| `setup-machine` | 이 컴퓨터의 전역 지침·설정을 GitHub 최신본과 비교해 점검하고 갱신(승인 후) |
| `audit-docs` | 문서의 낡은 내용·모순·중복·사족 점검 |
| `write-readme` | README를 첫 방문자 기준 소개 페이지로 작성·개선(첫 화면이 무엇인지·필요한지·시작법에 답하게) |
| `tidy-code` | 동작을 바꾸지 않고 미사용 코드·CSS 삭제, 중복·구조 정리, 테스트 축소 |
| `audit-messages` | 사용자·에이전트 문구의 오류·모순·용어 흐트러짐 점검, 오류 종류 코드·카탈로그 구조 개선 |
| `release-project` | 릴리즈 요청 시 버전·CHANGELOG·검증·병합·태그·브랜치 정리까지 전체 절차 |
| `share-lesson` | 해결한 문제의 교훈을 다른 프로젝트에 붙여 넣을 블록으로 정리하고 행선지(붙여넣기·베이스라인·스킬 후보) 제안 |
| `riso-illustration` | 투컬러 리소그래프 화풍으로 후보 여러 장 생성 → 선택 → 부분 수정(이미지 생성 도구가 있을 때 생성, 없으면 프롬프트만) |

스킬은 요청이 설명과 맞으면 에이전트가 고른다. 예: "문서 점검해줘", "코드 정리해줘", "문구 점검해줘", "릴리즈 진행해줘", "일러스트 후보 4장 만들어줘", "이 프로젝트에 ysm 규칙 적용해줘". 이름이 `-project`로 끝나는 스킬은 프로젝트만, `-machine`으로 끝나는 스킬은 이 컴퓨터의 전역 파일만 바꾼다.

이 저장소 폴더에서만 쓰는 스킬(`.agents/skills/`, Claude Code용 사본은 `.claude/skills/`):

| 스킬 | 용도 |
|---|---|
| `deploy-cloudflare-pages` | Cloudflare Pages 배포를 표준에 맞춰 만들거나 점검(API, 승인 후) |


## 규칙

규칙은 세 곳에 나뉘어 놓이고, 적용 방식이 서로 다르다.

| 구분 | 놓이는 곳 | 정본 |
|---|---|---|
| 베이스라인 | 프로젝트의 `AGENTS.md`(`ysm-baseline` 마커 구역)와 훅·설정 파일 | [baseline/agents-block.md](baseline/agents-block.md), `baseline/managed/`(교체), `baseline/seed/`(처음만 생성) |
| 전역 지침 | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`(`ysm-global` 마커 구역), `~/.claude/settings.json`의 확인 규칙 | [global/agents.md](global/agents.md) |
| 대화용 지침 | claude.ai·ChatGPT 계정 설정(직접 붙여넣기) | [global/chat-claude.md](global/chat-claude.md), [global/chat-chatgpt.md](global/chat-chatgpt.md) |

베이스라인은 저장소 구조에 따르는 Git·문서·의존성·안전 규칙이고, 전역 지침은 저장소 없이도 성립하는 소통·판단·검증 규칙이다. 같은 규칙을 양쪽에 두지 않는다.

```
yimsemin/ysm-skills 저장소를 보고 이 프로젝트에 베이스라인 적용해줘      (처음 적용하는 기존 프로젝트)
yimsemin/ysm-skills 저장소를 보고 베이스라인 업데이트 해줘               (이미 적용한 프로젝트)
```

### 기존 규칙을 덮어쓰는가

`AGENTS.md`·`CLAUDE.md` 같은 지침 파일은 **마커 구역만** 만들거나 교체한다. 마커(`<!-- ysm-baseline:start rev=… -->`, `<!-- ysm-global:start rev=… -->`) 밖에 쓴 내용은 건드리지 않는다. 시작 마커의 `rev`는 적용한 정본의 체크섬이고, 최신 여부는 이 값으로 판단한다(베이스라인은 `apply.sh --check <폴더>`, 전역 지침은 `apply-global.sh --check`).

- 베이스라인: 훅과 PR 템플릿(관리 파일)은 프로젝트가 고치지 않는 파일이라 정본으로 교체한다. 커밋되지 않은 변경이 있으면 교체하지 않고 알린다. 프로젝트 전용 푸시 검사는 `.githooks/pre-push.local`에 둔다. 훅이 macOS·Linux에서도 실행되도록 필요하면 실행 권한을 git 인덱스에 기록하며, 이때 해당 파일이 스테이지된다. 나머지 설정 파일(시드 파일)은 없을 때만 만들고, 내용이 다르면 에이전트가 읽어서 병합한다(`.gitignore`만 빠진 줄을 추가한다). 모두 사용자에게 보고하고 승인받은 뒤에 적용한다.
- 전역 지침: 승인한 뒤에만 쓰고, 쓰기 전에 기존 파일을 `.bak-시각`으로 백업한다. `settings.json`은 필요한 확인 규칙만 추가하고 기존 설정은 그대로 둔다. 마커가 없는 기존 파일에는 구역을 맨 위에 추가한다.
- 강제되는 것: 베이스라인의 훅(커밋 메시지 형식·언어, 비밀값 검사, noreply 커밋 이메일(설정한 프로젝트만), 보호 브랜치 직접 커밋·푸시·force push)은 설치되면 실제로 막는다. GitHub 쪽 병합 방식·브랜치 보호·보안 설정은 `baseline/repo-settings.sh`가 점검하고(`--apply`로 맞춤), 비공개 저장소는 무료 플랜이라 훅만 작동한다. 이때 쓰기 권한을 받은 사람은 누구나 병합과 `main` 변경을 할 수 있고, 점검 스크립트가 그 인원을 알린다. 나머지 규칙은 에이전트가 따르는 지침이다.
- 프로젝트가 바꿀 수 있는 Git 규칙은 프로젝트 구역의 선언뿐이다: `main` 직행(쓰기 권한자가 한 명인 저장소만), 커밋 제목 언어.
- 커밋 이메일을 GitHub noreply 주소로 제한하는 검사는 선택이며, 켠 사람의 클론에만 적용된다(`apply.sh --noreply-email`).

### 외부 기여 안내와 이슈 템플릿

베이스라인은 에이전트가 따르는 작업 규칙을 맡는다. 사람이 읽는 기여 안내와 이슈 템플릿은 GitHub 계정의 공개 `.github` 저장소([yimsemin/.github](https://github.com/yimsemin/.github))에 두며, 같은 종류의 파일이 없는 그 계정의 저장소에 [기본값으로 적용](https://docs.github.com/en/communities/setting-up-your-project-for-healthy-contributions/creating-a-default-community-health-file)된다. 다른 계정에서 쓰려면 그 계정에 `.github` 저장소를 만든다.

### 규칙이 충돌하면

- 베이스라인과 프로젝트 고유 규칙: 베이스라인을 따르는 것이 기본이다. 프로젝트 규칙에 유지할 만한 특별한 이점이 있으면 프로젝트 규칙을 남기고, 이점이 분명하지 않으면 사용자에게 묻는다. 적용 때 겹치거나 모순되는 문장이 있으면 에이전트가 목록으로 보고한다.
- 전역 지침과 프로젝트 규칙: 겹치지 않게 나눠 두었고, 우선순위를 따로 정하지 않았다. 부딪히면 사용자에게 묻는 것이 기본이다.

### 붙여 넣은 규칙을 수정하면

- **마커 구역 안**을 고치면 다음 업데이트 때 정본 내용으로 교체되어 사라진다. 베이스라인은 교체 전에 구역 안을 직접 고친 부분을 표시하고, 마커 밖으로 옮길지 묻는다. 전역 지침은 적용 전에 `--diff`로 바뀔 내용을 볼 수 있다.
- **마커 구역 밖**에 쓴 개인·프로젝트 규칙은 업데이트해도 그대로 남는다. 공통 규칙 자체를 바꾸려면 이 저장소에 요청한다. 내 기준으로 바꿔 쓰려면 이 저장소를 포크해 정본을 고친다.
- 대화용 지침은 자동 갱신이 없다. 바뀌면 다시 붙여넣는다.
- 업데이트는 요청할 때만 하고 승인 후에 적용한다.

## 고급: Claude Code 플러그인

플러그인을 설치하면 `/ysm:new-project 만들 것…`, `/ysm:audit-docs`처럼 스킬 이름으로 직접 부를 수 있다. 설치하지 않아도 위 방식으로 모두 동작한다.

```
/plugin marketplace add yimsemin/ysm-skills
/plugin install ysm@ysm-skills
```

## 라이선스
[MIT](LICENSE)
