---
name: setup-machine
description: Check and install the ysm global instructions (Claude ~/.claude/CLAUDE.md, Codex ~/.codex/AGENTS.md) and the global issue-write confirmation setting on this computer, only after asking the user. Works from any folder and always compares against the latest ysm-skills on GitHub. Use when setting up a new computer, or when the user asks to check or update the global instructions. 새 컴퓨터 전역 설정, 전역 지침 점검·갱신·업데이트.
---

# setup-machine

이 컴퓨터의 전역 지침과 전역 설정을 점검하고, 사용자에게 묻고, 갱신한다. 파일은 스크립트가 쓰고 에이전트는 판단과 안내만 한다. 전역 파일은 프로젝트 밖이므로 승인 없이 바꾸지 않는다. 어느 폴더에서 실행해도 되고, 현재 프로젝트의 파일은 건드리지 않는다.

## 1. 정본 받기

설치된 플러그인 사본은 낡았을 수 있으므로 플러그인 경로를 쓰지 않고, 항상 GitHub의 최신본을 임시 폴더로 받는다.

```sh
src="$(mktemp -d)/ysm-skills"
gh repo clone yimsemin/ysm-skills "$src" -- --depth 1 -q 2>/dev/null \
  || git clone --depth 1 -q https://github.com/yimsemin/ysm-skills "$src"
```

셸 변수는 명령 호출 사이에 유지되지 않는다. 위 블록과 `$src`를 쓰는 명령은 한 번의 실행으로 묶거나, 출력한 경로를 이후 명령에 직접 적는다. 받지 못하면(네트워크·권한) 그 사실을 알리고 멈춘다.

## 2. 점검

```sh
sh "$src/global/apply-global.sh" --check
```

| 상태 | 뜻 | 처리 |
|---|---|---|
| `CURRENT` | 최신 | 최신이라고 한 줄로 알리고 끝낸다 |
| `MISSING` | 파일 없음 | 3단계 |
| `OLD` | 구역이 낡음 | 3단계 |
| `UNMARKED` | 사용자 줄만 있고 구역 없음 | 3단계 |
| `PARTIAL` | 설정에 규칙 일부 없음 | 3단계 |
| `NOAPP` | 그 에이전트 폴더가 없음 | 건드리지 않는다 |
| `NEEDS_PYTHON` | 설정 병합에 Python(`python3` 또는 `python`) 필요 | 설정은 건너뛰고 지침만 진행한다고 한 줄로 알린다 |

## 3. 사용자에게 묻는다

`sh "$src/global/apply-global.sh" --diff`로 바뀔 내용을 파일별 한 줄로 요약하고, 전역 파일을 바꾼다는 사실과 경로를 밝혀 "적용 / 건너뛰기"를 묻는다.

## 4. 적용

승인하면 `sh "$src/global/apply-global.sh" --apply`를 실행한다. 기존 파일은 `.bak-시각`으로 백업된다.

`UNMARKED`였던 파일은 새 구역 아래에 옛 사용자 줄이 남는다. 구역과 내용이 겹치는 옛 줄을 골라 보여 주고, 사용자가 승인하면 그 줄만 지운다. 겹치지 않는 사용자 줄은 그대로 둔다.

## 5. 보고

`--check`를 다시 실행해 결과를 확인하고, 바뀐 파일, 백업 위치, 건너뛴 항목을 보고한다.
