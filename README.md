# ysm-skills

에이전트(Claude Code, Codex)로 새 프로젝트를 시작하고 여러 컴퓨터에서 같은 기준으로 일하기 위한 스킬과 베이스라인. 이 컴퓨터에 폴더가 없어도 원격 저장소(`yimsemin/ysm-skills`)만 있으면 동작한다.

## 처음 한 번 (컴퓨터마다)

1. `gh auth login`으로 GitHub에 로그인한다. 저장소가 private인 동안은 저장소 접근 권한이 있는 계정이어야 한다.
2. (선택) Claude Code 플러그인을 설치하면 `/ysm:new-project` 같은 명령을 쓸 수 있다. 설치하지 않아도 아래 프롬프트의 링크만으로 시작된다.
   ```
   /plugin marketplace add yimsemin/ysm-skills
   /plugin install ysm@ysm-skills
   ```

## 새 프로젝트 시작하기

1. 새 폴더를 만들고(예: `~/Documents/stitch-counter`) 그 폴더에서 에이전트(Claude Code, Codex)를 연다.
2. 만들 것을 자유롭게 쓰고, 마지막 줄에 저장소 링크를 붙인다.

```
뜨개질할 때 현재 행 수를 크게 보여주고 누르면 올라가는 모바일 카운터 앱을 만들고 싶어.
스택은 추천해줘. 로그인이나 서버는 필요 없어.

https://github.com/yimsemin/ysm-skills 참조해서 기본 셋팅해줘
```

에이전트가 이 저장소의 [new-project 스킬](skills/new-project/SKILL.md)을 따라 전역 지침 점검(없거나 낡았으면 물어본 뒤 갱신), 질문, 베이스라인 적용, `AGENTS.md` 작성을 한다. 첫 커밋과 GitHub 저장소 생성은 요청할 때 한다. 플러그인을 설치했다면 `/ysm:new-project 만들 것…`으로 시작해도 같다.

private인 동안 링크는 웹으로 열리지 않으므로 에이전트가 `gh`로 받아 읽는다(위 "처음 한 번" 1번이 필요한 이유).

## Cloudflare Pages 배포하기

Cloudflare 배포와 관리는 **이 저장소 폴더에서만** 한다. 기준은 [docs/cloudflare-pages.md](docs/cloudflare-pages.md)에만 있고 대상 프로젝트로 복사되지 않는다. Cloudflare API 토큰은 이 저장소 폴더의 `.env`(git에서 제외됨) 또는 환경변수에 둔다. 컴퓨터마다 한 번 발급하며 만드는 법과 권한은 그 문서의 "토큰"에 있다.

이 저장소 폴더에서 에이전트를 열고:

```
yimsemin/<대상 저장소>를 Cloudflare Pages 배포해줘
```

에이전트가 [deploy-cloudflare-pages 스킬](skills/deploy-cloudflare-pages/SKILL.md)을 따라 현재 설정을 조회하고, 표준과의 차이와 계획을 보여 준 뒤 승인받은 항목만 실행한다. 이미 배포된 프로젝트를 점검할 때도 같은 요청을 쓴다.

## 스킬

| 스킬 | 용도 | 상태 |
|---|---|---|
| `new-project` | 빈 폴더에서 의도부터 시작해 베이스라인 적용 | 사용 가능 |
| `setup-machine` | 이 컴퓨터의 전역 지침·설정 점검과 갱신(승인 후) | 사용 가능 |
| `deploy-cloudflare-pages` | 프로젝트의 Cloudflare Pages 배포를 표준에 맞춰 만들거나 점검(API, 승인 후) | 사용 가능 |
| `adopt-project` | 기존·인수 프로젝트를 수정 없이 진단한 뒤 승인받아 맞춤(트레일러 차단, 이력 정리 포함) | 예정 |
| `sync-project` | 베이스라인 갱신 반영 | 예정 |
| `audit-docs` | 문서의 낡은 내용·모순·중복·사족 점검 | 예정 |
| `handoff` | 다음 대화방에 붙여 넣을 짧은 인계 프롬프트 작성 | 예정 |
| `review-journey` | 처음 보는 사용자 기준 전면 재점검 | 예정 |

## 규칙이 놓이는 곳

- 전역 지침: 소통·판단·검증처럼 저장소와 무관한 에이전트 작업 규칙. 정본은 [global/agents.md](global/agents.md)이고 `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`의 마커 구역에 똑같이 들어간다.
- 대화용 지침: claude.ai 대화에만 적용되는 짧은 지침. [global/chat.md](global/chat.md)를 계정 설정에 직접 붙여넣는다. 변경 이력은 git 이력이다.
- 베이스라인: 저장소 구조에 따르는 Git·문서·의존성·안전 규칙. 정본은 [baseline/agents-block.md](baseline/agents-block.md)이고 훅·설정 파일은 `baseline/files/`에 있다. `baseline/apply.sh`가 기존 파일을 덮어쓰지 않고 적용한다.

참고한 외부 자료는 [docs/references.md](docs/references.md). 이 저장소를 고칠 때는 [AGENTS.md](AGENTS.md)를 따른다.
