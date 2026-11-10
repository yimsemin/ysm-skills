---
name: adopt-project
description: Diagnose an existing or inherited project without changing it, then, after the user approves, align it with the ysm baseline (AGENTS.md rules, hooks, project-local dependencies, no AI attribution trailers or contributors). Use when a folder already has code or history and the user asks to apply, check or align the ysm rules. 기존 프로젝트에 ysm 규칙 적용·점검·맞추기, 인수 프로젝트 진단, 트레일러·contributors 정리.
---

# adopt-project

코드나 이력이 이미 있는 프로젝트를 베이스라인에 맞춘다. **진단은 읽기 전용**이고, 사용자가 항목을 승인한 뒤에만 바꾼다. 대상은 사용자가 에이전트를 연 작업 폴더이다. 빈 폴더면 `new-project`를 쓴다. 규칙의 내용은 베이스라인(`ysm-baseline` 구역)이 정본이므로 이 스킬에 다시 쓰지 않는다.

## 1. 준비

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

셸 변수는 명령 호출 사이에 유지되지 않는다. 위 블록과 `$src`를 쓰는 명령은 한 번의 실행으로 묶거나, 출력한 경로를 이후 명령에 직접 적는다. 전역 지침 점검은 `$src/skills/setup-machine/SKILL.md`의 2~5단계를 따른다(없거나 낡았으면 묻고, 거절하면 건너뛴다).

## 2. 진단 (읽기 전용)

아무것도 쓰지 않고 아래를 한 번에 조회한다. 파일·이력·설정을 바꾸는 명령은 이 단계에서 실행하지 않는다.

- **베이스라인 차이**: `sh "$src/baseline/apply.sh" --dry-run .`의 CREATED·DIFFERS·UPDATED·APPENDED 목록.
- **Git 상태**: 미커밋 변경(사용자 작업 중인 파일은 건드리지 않는다), 현재·기본 브랜치, `develop` 유무, 원격, 훅 경로, 커밋 이메일이 noreply인지.
- **의존성·환경**: 프로젝트 밖에 설치·캐시가 있는지(전역 node·pip, 홈의 캐시), `mise.toml`, `.node-version`·`.python-version`, `package.json`의 `devDependencies`, `uv`·`.venv` 사용 여부. 전역 도구는 삭제하지 말고 목록만 만든다.
- **AI 표식**: 이력에 `Co-Authored-By: Claude`·`Generated with` 같은 표식이 있는지(`git log --grep`), `gh api repos/{owner}/{repo}/contributors`에 AI 계정이 있는지, 원격에 푸시된 커밋인지.
- **공개 안전**: 추적 파일의 비밀값·개인 절대경로·`.env` 추적 여부, `.gitignore` 상태.
- **문서**: 루트에 있는 기획·인수인계 문서, 기존 `AGENTS.md`·`CLAUDE.md` 내용과 충돌하는 규칙.
- **GitHub 설정**(admin 권한일 때): 기본 브랜치(`main`이어야 함), "Automatically delete head branches", 공개 저장소의 외부 기여 방어 설정, Dependabot 보안 알림. 점검 방법은 `$src/skills/new-project/SKILL.md` 5단계와 같다. 기본 브랜치가 `main`이 아니면 `gh api -X PATCH repos/{owner}/{repo} -f default_branch=main`으로 바꾸되, `main`에 필요한 파일(Dependabot 설정, 예약 워크플로)이 있는지 먼저 확인하고 승인받는다.
- **Dependabot 설정**: `.github/dependabot.yml`이 `$src/baseline/dependabot.yml` 표준과 다른 점(주기, 묶기, PR 한도, 접두사, `target-branch`, 매니페스트에 없는 항목). 기본 브랜치가 `main`이고 `develop`을 쓰면 설정이 릴리스 뒤에야 적용된다는 점도 보고한다.

## 3. 진단을 보고하고 승인받는다

결론(맞춤 필요 항목 수와 위험)을 첫 줄에, 사용자가 결정할 항목을 바로 아래에 쓴다. 항목마다 **무엇을 바꾸는지 / 되돌릴 수 있는지 / 위험**을 쓰고 권장안을 밝힌다. 이력 재작성과 force push는 되돌릴 수 없으므로 별도 항목으로 분리하고, 사용자가 그 대화에서 직접 요청하기 전에는 실행하지 않는다. 승인된 항목만 4단계로 간다.

## 4. 적용 (승인된 항목만)

1. **베이스라인**: `sh "$src/baseline/apply.sh" .` 기존 파일은 덮어쓰지 않는다. `DIFFERS`는 읽어서 `$src/baseline/files/<경로>`와 병합한다. 베이스라인을 따르는 것이 기본이고, 프로젝트 내용에 유지할 만한 특별한 이점이 있으면 프로젝트 내용을 유지하며, 이점이 분명하지 않거나 애매하면 사용자에게 묻는다. 새 프로젝트처럼 커밋 이메일을 noreply로 맞추려면 `--noreply-email`을 붙인다.
2. **프로젝트 구역**: 기존 `AGENTS.md`의 프로젝트 고유 내용은 `ysm-baseline` 마커 밖에 유지하고, 베이스라인과 겹치는 문장은 지운다. 프로젝트 규칙이 베이스라인과 충돌하면 프로젝트 규칙을 남기고 그 사실을 보고한다.
3. **의존성**: 프로젝트 안으로 옮길 수 있는 것만 옮기고(`.node-version`, `devDependencies`, `uv sync`), 검증한 뒤에 보고한다. 전역 설치물 삭제는 사용자 몫이다.
4. **Dependabot**: `$src/baseline/dependabot.yml`을 `.github/dependabot.yml`로 복사하고(기존 파일이 있으면 표준에 맞춰 병합) 그 파일 머리의 안내대로 고친다. 보관했거나 1년 넘게 커밋이 없는 저장소는 설정 파일을 만들지 않는다.
5. **문서 위치**: 루트의 입력·기획 문서를 `docs/`로 옮기고 링크를 고친다.
6. **AI 표식 정리(승인·직접 요청된 경우만)**: 먼저 백업 브랜치 또는 태그를 만든다. 로컬 이력에서 표식을 제거하고, 원격 반영(force push)은 사용자가 그 대화에서 명시적으로 요청했을 때만 한다. contributors 목록은 GitHub 캐시 때문에 바로 사라지지 않을 수 있으므로, 반영 뒤 `gh api`로 다시 조회해 결과를 그대로 보고한다.

## 5. 검증하고 보고한다

- `sh "$src/baseline/apply.sh" --dry-run .`가 SAME 또는 의도한 차이만 보이는지, `git config core.hooksPath`가 `.githooks`인지 확인한다.
- 프로젝트의 테스트·빌드 명령을 새로 실행해 맞춤 때문에 깨지지 않았는지 본다.
- 보고는 "한 일 / 확인하지 못한 것 / 하지 않은 것"으로 나누고, 커밋·푸시는 사용자가 요청할 때 한다.
