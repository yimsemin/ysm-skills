---
name: audit-docs
description: Audit a project's documents and skills for stale information, duplicates, contradictions and filler, fix them so only the current state remains, and report what was changed per category. Use after a batch of commits, a direction change, a release, or when the user asks to check or clean up docs. 문서 점검, 낡은 정보·중복·모순·사족 정리, 문서 최종본 정리.
---

# audit-docs

문서와 스킬에 **현재 상태만** 남긴다. 큰 변경·커밋 묶음·릴리즈 뒤에는 요청이 없어도 한다.

## 1. 범위

`git ls-files '*.md'`와 프로젝트의 스킬 파일을 본다. 입력 문서·로그·생성물은 제외하고, 사용자가 범위를 줬으면 그것만 본다.

## 2. 점검

코드·설정·명령과 대조해 확인한 것만 판정한다.

- **낡은 정보**: 없어진 파일·명령·옵션, 바뀐 버전·경로, 끝났는데 남은 로드맵 항목.
- **중복**: 같은 규칙·사실이 둘 이상에 있는 것(전역·베이스라인과 겹치는 문장 포함). 한 곳만 남기고 링크한다.
- **모순**: 문서끼리, 또는 문서와 실제 동작이 다른 것. 실제 동작을 확인해 맞는 쪽으로 고친다.
- **사족**: 경위, 폐기한 안, "~하지 않기로 함", 일반론, 반복. 지운다.

문서 위치는 베이스라인 "문서" 구역을 따른다.

## 3. 수정

기본은 고치는 것까지 한다. "있는지 봐줘"처럼 확인만 요청했으면 목록과 제안만 보고한다. 의미가 바뀌는 수정(규칙 삭제, 방향 해석)은 결정 항목으로 남긴다. 커밋은 사용자가 요청할 때 한다.

## 4. 보고

사용자가 결정할 항목을 맨 위에 두고, 이어서 **낡은 정보 / 중복 / 모순 / 사족별로 무엇을 어떻게 고쳤는지** 파일 단위로 쓴다. 해당 없는 분류는 "없음"이라고 쓴다. 확인하지 못한 것과 하지 않은 것도 쓴다.
