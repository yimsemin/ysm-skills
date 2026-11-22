---
name: release-project
description: Run a project's whole release procedure - decide version, update CHANGELOG, verify, merge the release PR, create an annotated tag and GitHub Release, and clean up branches - when the user asks for a release. Use for "release", "릴리즈", "릴리스", "버전 올려서 배포", not for a plain merge. 릴리즈 절차 전체 진행.
---

# release-project

사용자가 **릴리즈를 요청했을 때** 절차 전체를 끝까지 진행한다. "병합해줘", "main에 반영해줘"는 릴리즈가 아니므로 이 스킬을 쓰지 않는다. 릴리즈 요청에는 이 절차에 필요한 푸시·PR·병합·태그 승인이 포함된다. 절차에 없는 작업(force push 등)은 포함되지 않는다.

## 1. 현재 상태를 확인한다

한 명령으로 묶어 조회한다: 현재 브랜치, 미커밋 변경, `develop`·`main` 존재와 차이, 마지막 태그 이후 커밋, 버전이 적힌 파일(`package.json`·`pyproject.toml`·`VERSION`), CHANGELOG 형식, CI 상태. `develop`이 없으면 `main` 직행 프로젝트로 보고, 4단계의 `develop` → `main` 병합을 건너뛰고 `main`에 태그한다. 미커밋 변경이 있으면 사용자 것인지 확인하고 멈춘다.

## 2. 버전과 내용을 정한다

- 마지막 태그 이후 커밋으로 SemVer 증분을 정한다. 호환을 깨면 major, 기능 추가는 minor, 수정은 patch. 사용자가 버전을 줬으면 그대로 쓰고, 애매하면 권장안과 함께 묻는다.
- CHANGELOG는 베이스라인 "문서" 구역의 규칙대로 쓰고, 내부 정리·문서 오탈자는 넣지 않는다. 병합하며 쌓인 `[Unreleased]` 항목을 `[X.Y.Z] - 릴리즈 날짜` 제목으로 바꾸고 새 `[Unreleased]`를 위에 둔다. 비어 있으면 마지막 태그 이후 커밋으로 채운다.
- 버전 파일과 CHANGELOG 변경은 릴리즈 준비 커밋 하나로 한다(`chore(release): vX.Y.Z`). 보호 브랜치에는 직접 커밋하지 않으므로 작업 브랜치(`chore/release-vX.Y.Z`)에서 만들어 PR로 병합한다. `develop`을 쓰면 `develop`으로, 아니면 `main`으로 간다. `main` 직행을 선언한 프로젝트만 직접 커밋한다.

## 3. 검증한다

프로젝트의 테스트·빌드·검증 명령(`AGENTS.md`의 "실행과 검증")을 새로 실행하고 출력 전체를 읽는다. 실패하면 릴리즈를 멈추고 원인을 보고한다.

## 4. 반영한다

1. 준비 PR을 병합한다(squash). `develop`을 쓰면 이어서 `develop` → `main` 릴리스 PR을 만들어 merge commit으로 병합한다. CI가 있으면 통과를 확인한 뒤 병합한다.
2. 병합된 `main`의 커밋에 annotated 태그 `vX.Y.Z`를 만들어 푸시한다(`git tag -a vX.Y.Z -m "vX.Y.Z"`).
3. 해당 버전의 CHANGELOG 항목을 본문으로 GitHub Release를 만든다(`gh release create`). 태그만 만들고 Release를 빼지 않는다.
4. 병합이 끝난 작업 브랜치를 로컬·원격 모두 지운다(`main`·`develop` 제외).

## 5. 마무리 확인

- 로컬과 원격이 일치하고 미커밋 변경이 없는지, 태그가 원격에 있고 annotated인지(`git cat-file -t vX.Y.Z`가 `tag`), Release가 있는지, 매니페스트 버전·CHANGELOG·태그가 같은 버전인지 확인한다.
- 문서 점검(`audit-docs`)을 한 번 한다.
- 보고는 "한 일 / 확인하지 못한 것 / 하지 않은 것"으로 나누고, 만든 버전·태그·릴리즈 링크를 첫 줄에 쓴다.
