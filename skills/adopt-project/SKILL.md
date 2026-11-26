---
name: adopt-project
description: Diagnose an existing project without changing it, then, after the user approves, apply or update the ysm baseline (AGENTS.md rules block, hooks, GitHub settings, project-local dependencies, no AI attribution trailers). Covers both first-time adoption of an existing or inherited project and syncing a project that already uses the baseline after ysm-skills changed. Use when a folder already has code or history and the user asks to apply, check, align, sync, update or refresh the ysm rules. 기존 프로젝트에 ysm 규칙 적용·점검·맞추기, 베이스라인 업데이트·최신화, 인수 프로젝트 진단, 트레일러 정리.
---

# adopt-project

코드나 이력이 이미 있는 프로젝트를 현재 베이스라인에 맞춘다. 처음 적용하는 프로젝트와 이미 적용한 프로젝트의 갱신을 모두 다룬다. **진단은 읽기 전용**이고, 사용자가 항목을 승인한 뒤에만 바꾼다. 대상은 사용자가 에이전트를 연 작업 폴더이다. 빈 폴더면 `new-project`를 쓴다. 규칙의 내용은 베이스라인(`ysm-baseline` 구역)이 정본이므로 이 스킬에 다시 쓰지 않는다.

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

셸 변수는 명령 호출 사이에 유지되지 않는다. 위 블록과 `$src`를 쓰는 명령은 한 번의 실행으로 묶거나, 출력한 경로를 이후 명령에 직접 적는다.

`AGENTS.md`에 `ysm-baseline:start` 마커가 있으면 **갱신**, 없으면 **처음 적용**이다. 갱신이고 `sh "$src/baseline/apply.sh" --check .`가 `CURRENT`이며 아래 GitHub 설정에 `DIFFERS`가 없으면 "이미 최신"이라고 보고하고 끝낸다.

## 2. 진단 (읽기 전용)

아무것도 쓰지 않고 한 번에 조회한다. 파일·이력·설정을 바꾸는 명령은 이 단계에서 실행하지 않는다.

모든 경우:

- **베이스라인 차이**: `sh "$src/baseline/apply.sh" --dry-run .`의 `CREATED`·`UPDATED`·`DIFFERS`·`APPENDED`. 관리 파일(훅·PR 템플릿)은 정본으로 교체되므로(`UPDATED`), 프로젝트가 훅에 넣은 전용 검사와, `INFO 꺼지는 훅`이 알리는 다른 위치(`.git/hooks`, husky 등)의 검사를 확인한다. 전용 푸시 검사는 `.githooks/pre-push.local`로 옮길 항목으로 표시하고, 옛 베이스라인 그대로이거나 정본과 겹치는 검사는 옮기지 않는다. 푸시 외의 전용 검사는 옮길 자리가 없으므로 교체·비활성화로 사라진다고 표시한다.
- **규칙 변경 내용**(갱신일 때): 프로젝트 `AGENTS.md`의 마커 구역과 `$src/baseline/agents-block.md`를 `diff`로 비교해 추가·삭제·수정된 규칙을 문장 단위로 요약한다. 프로젝트가 마커 안을 직접 고친 부분은 따로 표시한다(교체 전에 마커 밖으로 옮길지 정한다).
- **프로젝트 구역과의 충돌**: 베이스라인과 겹치거나 모순되는 마커 밖 문장, 프로젝트 구역의 `ysm:commit-lang` 선언 유무(없으면 최근 커밋 제목으로 언어를 추정해 제안).
- **GitHub 설정**(admin 권한일 때): `sh "$src/baseline/repo-settings.sh"`(점검만 한다)의 `DIFFERS`와 `INFO`. 기본 브랜치가 `main`이 아니면 바꾸기 전에 `main`에 필요한 파일(Dependabot 설정, 예약 워크플로)이 있는지 확인할 항목으로 둔다.
- **Dependabot 설정**: `.github/dependabot.yml`이 `$src/baseline/dependabot.yml` 표준과 다른 점(주기, 묶기, PR 한도, 접두사, `target-branch`, 매니페스트에 없는 항목). 매니페스트나 워크플로가 있는데 설정이 없으면 추가 대상이다. `develop`을 쓰면 설정이 릴리스 뒤에야 적용된다는 점도 보고한다.
- **훅 활성화**: 새 클론의 설치 절차가 훅 설정을 건너뛰는지(`npm install --ignore-scripts`처럼 설정 단계를 생략하는 명령).
- **기여 안내**: `CONTRIBUTING.md`가 외부 기여자용 최소 안내인지, `AGENTS.md`와 중복·모순이 있는지. 계정의 `.github` 저장소에 기본 파일이 있으면 프로젝트 파일이 필요한지도 본다(프로젝트 파일이 있으면 기본 파일은 적용되지 않는다).
- **개인 설정**: `git config --local ysm.requireNoreply`가 `true`면 이 클론에서 noreply 이메일 검사가 켜져 있다고 알린다. 선택 설정이므로 사용자가 정하기 전에는 바꾸지 않는다.
- **해당 규칙 준수**: UI·사용자 문구·로컬 서버가 있는 프로젝트면 베이스라인의 해당 구역을 기존 코드가 지키는지 훑어 어긋난 점을 목록으로 만든다(갱신일 때도 한다).
- **미커밋 변경**: 있으면 그 파일은 건드리지 않는다.

처음 적용일 때만 더 본다:

- **Git 상태**: 현재·기본 브랜치, `develop` 유무(Cloudflare Pages 배포나 사용자 요청이 아니면 폐지 후보), 원격, 훅 경로, 커밋 이메일이 noreply인지, 최근 `main` 직접 커밋·force push 여부.
- **의존성·환경**: 프로젝트 밖에 설치·캐시가 있는지(전역 node·pip, 홈의 캐시), `mise.toml`, `.node-version`·`.python-version`, `package.json`의 `devDependencies`, `uv`·`.venv` 사용 여부, 도구 소비형 계약(`runtime-pins.json`, `.uv-*` 경로) 파일과 계약 금지 파일(`pyproject.toml`·`.venv`·`.python-version`)이 섞여 있는지. 섞여 있으면 어느 쪽인지 묻는다. 전역 도구는 삭제하지 말고 목록만 만든다.
- **AI 표식**: 이력에 `Co-Authored-By: Claude`·`Generated with` 같은 표식이 있는지(`git log --grep`), `gh api repos/{owner}/{repo}/contributors`에 AI 계정이 있는지, 원격에 푸시된 커밋인지.
- **공개 안전**: 추적 파일의 비밀값·개인 절대경로·`.env` 추적 여부, `.gitignore` 상태.
- **문서**: 루트에 있는 기획·인수인계 문서, 기존 `AGENTS.md`·`CLAUDE.md` 내용.

## 3. 보고하고 승인받는다

결론(처음 적용·갱신, 바뀔 항목 수와 위험)을 첫 줄에, 사용자가 결정할 항목을 바로 아래에 쓴다. 항목마다 **무엇이 바뀌는지 / 되돌릴 수 있는지 / 위험**을 쓰고 권장안을 밝힌다. 새 규칙 때문에 기존 코드·문서·구조를 고쳐야 하는 경우는 규칙 반영과 별도 항목으로 나누고 목록만 만든다. 이력 재작성과 force push는 되돌릴 수 없으므로 별도 항목으로 분리하고, 사용자가 그 대화에서 직접 요청하기 전에는 실행하지 않는다. 승인된 항목만 4단계로 간다.

## 4. 적용 (승인된 항목만)

1. **베이스라인**: 2단계에서 옮기기로 한 전용 푸시 검사가 있으면 먼저 `.githooks/pre-push.local`로 옮긴다. 그다음 `sh "$src/baseline/apply.sh" .`(처음 적용이고 커밋 이메일을 noreply로 맞추려면 `--noreply-email`). `DIFFERS`는 읽어서 `$src/baseline/seed/<경로>`(관리 파일이면 `managed/`)와 병합한다. 베이스라인을 따르는 것이 기본이고, 프로젝트 내용에 유지할 만한 특별한 이점이 있으면 유지하며, 애매하면 묻는다.
2. **프로젝트 구역**: 프로젝트 고유 내용은 마커 밖에 두고 베이스라인과 겹치는 문장은 지운다. 충돌하는 문장은 베이스라인 구역 첫 단락의 기준으로 정하고 보고한다. `ysm:commit-lang` 선언이 없으면 추가한다.
3. **GitHub 설정**: `sh "$src/baseline/repo-settings.sh" --apply`. 이미 있는 PR 흐름이 깨지지 않는지(`develop` 유무에 따른 merge commit 허용) 먼저 확인한다. 기본 브랜치 변경은 `gh api -X PATCH repos/{owner}/{repo} -f default_branch=main`으로 따로 한다.
4. **Dependabot**: `$src/baseline/dependabot.yml`을 `.github/dependabot.yml`로 복사하거나 표준에 맞춰 병합하고, 그 파일 머리의 안내대로 고친다. 보관했거나 1년 넘게 커밋이 없는 저장소는 설정 파일을 만들지 않는다.
5. **의존성**(처음 적용): 프로젝트 안으로 옮길 수 있는 것만 옮기고(`.node-version`, `devDependencies`, `uv sync`, 도구 소비형은 계약 파일) 검증한다. 전역 설치물 삭제는 사용자 몫이다.
6. **문서 위치**(처음 적용): 루트의 입력·기획 문서를 `docs/`로 옮기고 링크를 고친다.
7. **AI 표식 정리**(승인·직접 요청된 경우만): 먼저 백업 브랜치 또는 태그를 만든다. 로컬 이력에서 표식을 제거하고, 원격 반영(force push)은 사용자가 그 대화에서 명시적으로 요청했을 때만 한다. contributors 목록은 GitHub 캐시 때문에 바로 사라지지 않을 수 있으므로 반영 뒤 다시 조회해 결과를 그대로 보고한다.

## 5. 검증하고 보고한다

- `sh "$src/baseline/apply.sh" --check .`가 `CURRENT`인지, `--dry-run`이 `SAME` 또는 의도한 `DIFFERS`만 보이는지, `git config core.hooksPath`가 `.githooks`인지 확인한다.
- 프로젝트의 테스트·빌드 명령을 새로 실행해 반영 때문에 깨지지 않았는지 본다.
- 보고는 "한 일 / 확인하지 못한 것 / 하지 않은 것"으로 나눈다. 새 규칙이 요구하지만 하지 않은 후속 작업(예: 기존 문구 점검)은 목록으로 남긴다. 커밋·푸시는 사용자가 요청할 때 한다.
