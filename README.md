# ysm-skills

에이전트(Claude Code, Codex)로 새 프로젝트를 시작하고 여러 컴퓨터에서 같은 기준으로 일하기 위한 스킬과 베이스라인. 이 컴퓨터에 폴더가 없어도 원격 저장소(`yimsemin/ysm-skills`)만 있으면 동작한다.

## 처음 한 번 (컴퓨터마다)

1. `gh auth login`으로 GitHub에 로그인한다. 저장소가 private인 동안은 저장소 접근 권한이 있는 계정이어야 한다.
2. Claude Code에서 플러그인을 설치한다.
   ```
   /plugin marketplace add yimsemin/ysm-skills
   /plugin install ysm@ysm-skills
   ```
   플러그인을 쓸 수 없는 환경(Codex 등)은 아래 프롬프트의 "다른 에이전트용" 변형을 쓴다.

## 새 프로젝트 시작하기

1. 새 폴더를 만들고(예: `~/Documents/stitch-counter`) 그 폴더에서 에이전트(Claude Code, Codex)를 연다.
2. 만들 것을 자유롭게 쓰고, 마지막 줄에 저장소 링크를 붙인다.

```
뜨개질할 때 현재 행 수를 크게 보여주고 누르면 올라가는 모바일 카운터 앱을 만들고 싶어.
스택은 추천해줘. 로그인이나 서버는 필요 없어.

https://github.com/yimsemin/ysm-skills 참조해서 기본 셋팅해줘
```

에이전트가 이 저장소의 [new-project 스킬](skills/new-project/SKILL.md)을 따라 부족한 것만 묻고(필요하면 스택을 제안하고) 베이스라인을 적용한 뒤 `AGENTS.md`를 채운다. 첫 커밋과 GitHub 저장소 생성은 요청할 때 한다. 플러그인을 설치했다면 `/ysm:new-project 만들 것…`으로 시작해도 같다.

private인 동안 링크는 웹으로 열리지 않으므로 에이전트가 `gh`로 받아 읽는다(위 "처음 한 번" 1번이 필요한 이유).

## 스킬

| 스킬 | 용도 | 상태 |
|---|---|---|
| `new-project` | 빈 폴더에서 의도부터 시작해 베이스라인 적용 | 사용 가능 |
| `adopt-project` | 기존·인수 프로젝트를 수정 없이 진단한 뒤 승인받아 맞춤(트레일러 차단, 이력 정리 포함) | 예정 |
| `setup-machine` | 새 컴퓨터 전역 설정과 전역 설치물 점검 | 예정 |
| `sync-project` | 베이스라인 갱신 반영 | 예정 |
| `audit-docs` | 문서의 낡은 내용·모순·중복·사족 점검 | 예정 |
| `handoff` | 다음 대화방에 붙여 넣을 짧은 인계 프롬프트 작성 | 예정 |
| `review-journey` | 처음 보는 사용자 기준 전면 재점검 | 예정 |

## 베이스라인

프로젝트로 복사되는 정본은 `baseline/`이다. 규칙 본문은 [baseline/agents-block.md](baseline/agents-block.md) 한 곳에만 있고, 훅·설정 파일은 `baseline/files/`에 있다. 적용은 `baseline/apply.sh`가 하며 기존 파일을 덮어쓰지 않는다.

## 이 저장소 고치기

규칙은 `baseline/`에서만 고친다. 고친 뒤 `baseline/VERSION`을 올리고, 루트 사본은 `sh baseline/apply.sh .`로 갱신한다. `sh tools/validate.sh`가 형식·사본 일치·비밀값을 검사한다.
