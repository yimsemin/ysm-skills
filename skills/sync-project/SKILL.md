---
name: sync-project
description: Bring a project that already follows the ysm baseline up to the current baseline - show what differs from the current baseline, get approval, update the AGENTS.md baseline block and baseline files, merge conflicts, and verify. Use when ysm-skills was updated, or the user asks to sync, update or refresh the ysm rules in a project. ysm 베이스라인 갱신 반영, 프로젝트 규칙 최신화, 차이 확인.
---

# sync-project

이미 베이스라인을 적용한 프로젝트를 현재 베이스라인에 맞춘다. 대상은 사용자가 에이전트를 연 작업 폴더이다. 베이스라인을 처음 적용하는 폴더는 `new-project`(빈 폴더)나 `adopt-project`(기존 프로젝트)를 쓴다. 규칙의 내용은 베이스라인이 정본이므로 이 스킬에 다시 쓰지 않는다.

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

적용 이력을 확인한다. `AGENTS.md`에 `ysm-baseline:start` 마커가 없으면 이 스킬 대상이 아니므로 `adopt-project`로 안내하고 멈춘다.

## 2. 차이 진단 (읽기 전용)

- **변경 목록**: `sh "$src/baseline/apply.sh" --dry-run .`의 CREATED·DIFFERS·UPDATED·APPENDED를 본다. SAME은 건너뛴다. 이 목록과 아래 차이가 모두 비어 있으면 "이미 최신"이라고 보고하고 끝낸다.
- **규칙 변경 내용**: 프로젝트 `AGENTS.md`의 마커 구역과 `$src/baseline/agents-block.md`를 `diff`로 비교해 추가·삭제·수정된 규칙을 문장 단위로 요약한다. 마커 구역은 통째로 교체되므로 프로젝트가 마커 안을 직접 고친 부분이 있으면 따로 표시한다. 그 내용은 교체 전에 마커 밖 프로젝트 구역으로 옮길지 정해야 한다.
- **프로젝트 구역과의 충돌**: 새 규칙과 겹치거나 모순되는 마커 밖 문장.
- **Dependabot**: `$src/baseline/dependabot.yml` 표준이 바뀌었으면 `.github/dependabot.yml`과 차이를 본다. 설정이 없는 보관 저장소는 제외한다.
- **GitHub 설정**(admin 권한일 때): `sh "$src/baseline/repo-settings.sh" <소유자/저장소>`(점검만 한다)의 DIFFERS 목록. 프로젝트 구역에 `ysm:commit-lang` 선언이 없으면 함께 보고한다.
- **전역 지침**: `$src/global/VERSION`이 이 컴퓨터에 적용된 것과 다르면 `$src/skills/setup-machine/SKILL.md`를 따르라고 안내한다. 이 스킬에서 전역을 바꾸지 않는다.
- **미커밋 변경**: 있으면 그 파일은 건드리지 않는다.

## 3. 보고하고 승인받는다

결론(최신 여부, 바뀔 항목 수)을 첫 줄에, 사용자가 결정할 항목을 바로 아래에 쓴다. 항목마다 **무엇이 바뀌는지 / 되돌릴 수 있는지 / 프로젝트에 미치는 영향**을 쓴다. 새 규칙이 기존 코드·문서·구조를 고치게 만드는 경우(예: 새 규칙을 따르려면 기존 문구나 설정을 바꿔야 함)는 규칙 반영과 별도 항목으로 나누고, 이 스킬에서는 목록만 만든다. 승인된 항목만 4단계로 간다.

## 4. 적용 (승인된 항목만)

1. `sh "$src/baseline/apply.sh" .`로 마커 구역과 새 파일을 갱신한다. 기존 파일은 덮어쓰지 않는다. `DIFFERS`는 `$src/baseline/files/<경로>`와 읽어서 병합한다. 훅 파일의 차이가 프로젝트 전용 검사라면 그 부분을 `.githooks/pre-push.local`로 옮기고 훅은 베이스라인 그대로 둔다. 베이스라인을 따르는 것이 기본이고, 프로젝트 내용에 유지할 만한 특별한 이점이 있으면 유지하며, 애매하면 사용자에게 묻는다.
2. 마커 밖 프로젝트 구역에서 새 베이스라인과 겹치는 문장을 지운다. 충돌하면 프로젝트 규칙을 남기고 보고한다.
3. Dependabot 표준이 바뀌었으면 승인받은 만큼 `.github/dependabot.yml`을 맞춘다.
4. GitHub 설정 차이는 승인받으면 `sh "$src/baseline/repo-settings.sh" --apply <소유자/저장소>`로 맞추고, `ysm:commit-lang` 선언이 없으면 최근 커밋으로 언어를 추정해 프로젝트 구역에 추가한다.

## 5. 검증하고 보고한다

- `sh "$src/baseline/apply.sh" --dry-run .`가 SAME만 보이는지, `git config core.hooksPath`가 `.githooks`인지 확인한다.
- 프로젝트의 테스트·빌드 명령을 새로 실행해 반영 때문에 깨지지 않았는지 본다.
- 보고는 "한 일 / 확인하지 못한 것 / 하지 않은 것"으로 나눈다. 새 규칙이 요구하지만 하지 않은 후속 작업(예: 기존 문구 점검)은 목록으로 남긴다. 커밋·푸시는 사용자가 요청할 때 한다.
