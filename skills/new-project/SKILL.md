---
name: new-project
description: Start a brand-new project with the ysm baseline (AGENTS.md, no-AI-trailer git hook, project-local dependencies, safe settings). Use when the user wants to start, create, scaffold or bootstrap a new project in an empty or new folder. 새 프로젝트 시작, 새 프로젝트 만들기, 프로젝트 초기 세팅, 기획 의도에서 시작.
---

# new-project

빈 폴더(또는 거의 빈 폴더)에서 새 프로젝트를 시작한다. 기존 코드가 있는 폴더면 이 스킬을 쓰지 말고 `adopt-project`를 안내한다.

## 1. 의도를 모은다

사용자의 첫 메시지에서 아래 4가지를 뽑는다. 빠진 것만 묻고, 질문은 한 번에 최대 3개로 묶는다. 이미 말한 것을 다시 묻지 않는다.

- **의도**: 무엇을 왜 만드는가 (한두 문장)
- **사용자**: 누가 어떻게 쓰는가
- **성공 기준**: 어떻게 되면 됐다고 보는가
- **하지 않을 것**: 이번 범위에서 제외할 것

그리고 유형을 판단한다(묻지 말고 추정, 불확실하면 한 번만 확인): 정적 웹 / Node 도구 / Python 스크립트·분석 / 앱 / 기타.

## 2. 베이스라인을 적용한다

```sh
sh <이 스킬 폴더>/../../baseline/apply.sh .
```

플러그인으로 설치된 경우 `${CLAUDE_PLUGIN_ROOT}/baseline/apply.sh`를 쓴다. 스크립트가 없으면 `yimsemin/ysm-skills`를 임시 폴더에 클론해서 쓴다(`gh repo clone`).

이 스크립트는 기존 파일을 덮어쓰지 않는다. 출력의 `DIFFERS` 줄이 있으면 해당 파일을 읽고 베이스라인 내용(`baseline/files/<경로>`)과 비교해 병합한다. 사용자 내용이 우선이다.

## 3. 프로젝트 내용을 채운다

- `AGENTS.md`의 `{{INTENT}}`, `{{USERS}}`, `{{SUCCESS}}`, `{{NON_GOALS}}`에 1단계 내용을 쓴다. `{{RUN_AND_VERIFY}}`는 실제 실행·검증 명령이 정해진 만큼만 쓰고, 아직 없으면 "아직 없음"이라고 쓴다. 지어내지 않는다.
- `AGENTS.md`의 `ysm-baseline` 마커 사이는 수정하지 않는다.
- `README.md`가 없으면 의도 한 단락과 실행 방법만 담은 짧은 README를 만든다.
- 유형에 맞는 런타임 파일만 만든다. Node면 `.node-version`(`mise ls-remote`나 사용자가 쓰는 버전을 확인), Python이면 `uv init`과 `.python-version`. 필요하지 않으면 만들지 않는다.
- 의존성은 프로젝트 안에서만 설치한다(`npm install`, `uv sync`). 전역 설치가 필요해 보이면 하지 말고 사용자에게 먼저 묻는다.

## 4. 검증하고 보고한다

- `git config core.hooksPath`가 `.githooks`이고 `.githooks/commit-msg`가 실행 가능한지 확인한다.
- 만든 파일 목록을 짧게 보고하고, 프로젝트에서 사용자가 정해야 할 것(있다면)을 질문으로 남긴다.
- **commit, push, GitHub 저장소 생성은 하지 않는다.** 사용자가 요청하면 그때 한다(첫 커밋은 `main`에 한다).
