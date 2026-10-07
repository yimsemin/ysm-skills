# ysm-skills

에이전트(Claude Code, Codex) 작업환경을 새 프로젝트와 여러 컴퓨터에서 같은 기준으로 세팅하는 스킬과 베이스라인.

## 스킬

| 스킬 | 용도 | 상태 |
|---|---|---|
| `new-project` | 빈 폴더에서 의도부터 시작해 베이스라인 적용 | v0.1 |
| `adopt-project` | 기존 프로젝트 점검 후 승인받아 맞춤 | 예정 |
| `setup-machine` | 새 컴퓨터 전역 설정 | 예정 |
| `sync-project` | 베이스라인 갱신 반영 | 예정 |

## 베이스라인 v0.2

1. 커밋 메시지의 AI 트레일러 제거(`.githooks/commit-msg`, 설정, AGENTS.md)
2. 의존성은 프로젝트 폴더 안에만(전역 설치는 확인 후)
3. `AGENTS.md` 정본 + `CLAUDE.md`는 `@AGENTS.md` 포인터
4. 기본 `.gitignore`, `.editorconfig`, `.gitattributes`
5. commit·push·PR은 요청 시에만

## 설치 (Claude Code)

```
/plugin marketplace add yimsemin/ysm-skills
/plugin install ysm@ysm-skills
```

저장소가 private인 동안은 `gh auth login`이 된 컴퓨터에서만 된다.
