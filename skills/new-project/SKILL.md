---
name: new-project
description: Start a brand-new project with the ysm baseline (AGENTS.md, commit-message and secret hooks, noreply commit email, project-local dependencies). Use when the user wants to start, create, scaffold or bootstrap a new project in an empty or new folder. 새 프로젝트 시작, 새 프로젝트 만들기, 프로젝트 초기 세팅, 기획 의도에서 시작.
---

# new-project

빈 폴더(또는 거의 빈 폴더)에서 새 프로젝트를 시작한다. 대상은 사용자가 에이전트를 연 작업 폴더이고, 베이스라인을 받아 온 임시 폴더가 아니다. 사용자는 형식 없이 자유 문장과 저장소 링크만 줄 수 있으며, 그것으로 충분하다. 기존 코드가 있는 폴더면 이 스킬을 쓰지 말고 `adopt-project`를 안내한다. 규칙의 내용은 베이스라인(`AGENTS.md`의 `ysm-baseline` 구역)이 정본이므로 이 스킬에 다시 쓰지 않는다.

## 0. 준비와 전역 지침 점검

베이스라인은 이 컴퓨터에 저장소가 있다고 가정하지 않는다. 플러그인으로 설치된 경우 그 경로를, 아니면 원격 저장소를 임시 폴더로 받아 쓴다.

<!-- ysm-locate:start -->
```sh
src="${CLAUDE_PLUGIN_ROOT:-}"
if [ ! -f "$src/baseline/apply.sh" ]; then
  src="$(mktemp -d)/ysm-skills"
  gh repo clone yimsemin/ysm-skills "$src" -- --depth 1 -q 2>/dev/null \
    || git clone --depth 1 -q https://github.com/yimsemin/ysm-skills "$src"
fi
```
<!-- ysm-locate:end -->

셸 변수는 명령 호출 사이에 유지되지 않는다. 위 블록과 `$src`를 쓰는 명령은 한 번의 실행으로 묶거나, 출력한 경로를 이후 명령에 직접 적는다.

그다음 `$src/skills/setup-machine/SKILL.md`의 2~5단계를 따라 전역 지침을 점검한다. 최신이면 조용히 넘어가고, 없거나 낡았으면 사용자에게 묻고 승인한 경우에만 갱신한다. 거절하면 건너뛰고 프로젝트만 진행한다.

## 1. 의도를 모은다

사용자의 첫 메시지에서 아래를 뽑는다. 빠진 것만 묻고, 질문은 한 번에 최대 3개로 묶는다. 이미 말한 것을 다시 묻지 않는다.

- **의도**: 무엇을 왜 만드는가 (한두 문장)
- **사용자**: 누가 어떻게 쓰는가
- **성공 기준**: 어떻게 되면 됐다고 보는가
- **하지 않을 것**: 이번 범위에서 제외할 것
- **정해진 것**: 스택, 배포, 공개 여부, 지원 플랫폼 중 사용자가 이미 정한 것

## 2. 스택·구조를 정한다

사용자가 스택을 정하지 않았거나 "추천해줘"라고 했으면, 구현하지 말고 **권장안 하나**를 이유와 함께 짧게 제안한다(대안은 한 줄). 사용자가 확정하면 다음 단계로 간다. 정해져 있으면 제안 없이 진행한다. 유형은 정적 웹 / Node 도구 / Python 스크립트·분석 / 앱 / 기타 중에서 판단한다.

## 3. 베이스라인을 적용한다

```sh
sh "$src/baseline/apply.sh" --noreply-email .
```

저장소를 받을 수 없으면(권한·로그인 없음) 사용자에게 `gh auth login`과 저장소 접근 권한을 안내하고 멈춘다. 베이스라인을 기억에 의존해 재현하지 않는다.

스크립트는 기존 파일을 덮어쓰지 않는다. 출력의 `DIFFERS` 줄이 있으면 해당 파일을 읽고 `$src/baseline/files/<경로>`와 비교해 병합한다. 사용자 내용이 우선이다. `INFO noreply-email SKIPPED`가 나오면 `gh auth login`을 안내한다.

## 4. 프로젝트 내용을 채운다

- `AGENTS.md`의 `{{INTENT}}`, `{{USERS}}`, `{{SUCCESS}}`, `{{NON_GOALS}}`에 1단계 내용을 쓴다. `{{RUN_AND_VERIFY}}`는 실제 명령이 정해진 만큼만 쓰고, 아직 없으면 "아직 없음"이라고 쓴다. 지어내지 않는다.
- `ysm-baseline` 마커 사이는 수정하지 않는다.
- 폴더에 있던 기획·인수인계 같은 입력 문서는 `docs/`로 옮기고 `AGENTS.md`에서는 현재 결정만 요약해 링크한다.
- `README.md`가 없으면 의도 한 단락과 실행 방법만 담은 짧은 README를 만든다.
- 유형에 맞는 런타임 파일만 만든다. Node면 `.node-version`, Python이면 `uv init`과 `.python-version`. 필요하지 않으면 만들지 않는다.

## 5. 검증하고 보고한다

- `git config core.hooksPath`가 `.githooks`이고 `git config user.email`이 noreply인지 확인한다.
- 이 폴더의 GitHub 원격 저장소가 있고 admin 권한이면, "Automatically delete head branches" 설정을 점검하고 켜져 있으면 끈다(`develop` 같은 장기 브랜치가 릴리스 PR 병합 때 지워지는 것을 막기 위함이며, 작업 브랜치 정리는 규칙에 따라 에이전트가 한다). 권한이 없으면 끄지 못했다고 보고한다. 저장소가 아직 없으면 사용자가 생성을 요청할 때 함께 확인한다.

  ```sh
  gh repo view --json deleteBranchOnMerge,viewerPermission
  gh api -X PATCH repos/{owner}/{repo} -F delete_branch_on_merge=false
  ```

- 만든 파일을 짧게 보고하고, 사용자가 정해야 할 것을 질문으로 남긴다. 첫 커밋과 GitHub 저장소 생성은 사용자가 요청할 때 한다(첫 커밋은 `main`, 제목 예: `chore: initialize project`).
