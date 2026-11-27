# ysm-skills

**Claude Code나 Codex로 만든 앱을 처음 보는 사람도 바로 실행하고 쓸 수 있게 돕습니다.**

프로젝트를 시작하고 관리할 때 쓰는 공통 작업 규칙과 스킬 모음입니다. 새 프로젝트에 Git과 문서 관리 기준을 한 번에 적용하거나, 기존 프로젝트를 같은 기준으로 맞출 수 있습니다.

![실무자가 청록색 AI의 도움을 받아 새 프로젝트 폴더에 공통 체크리스트를 넣는 모습](docs/images/readme-hero.png)

## 시작하기

작업할 프로젝트 폴더를 Claude Code나 Codex에서 열고, 아래 예시를 채팅에 붙여 넣으세요. 저장소 이름과 하고 싶은 일만 말하면 에이전트가 맞는 스킬을 고릅니다. 플러그인 없이도 쓸 수 있습니다.

프로젝트 설정에는 Git과 `sh`가 필요합니다(Windows에서는 Git Bash에 포함됩니다).

### 새 프로젝트 시작

빈 폴더에서 요청하세요. 에이전트가 무엇을 만들지 확인하고 공통 규칙과 Git 설정을 적용합니다.

```text
ysm-skills 저장소를 참고해서 새 프로젝트 기본 설정을 해줘.
```

[`new-project`](skills/new-project/SKILL.md) 스킬이 사용됩니다.

### 기존 프로젝트 점검·갱신

처음 적용할 때와 이미 적용한 규칙을 갱신할 때 모두 아래처럼 요청하세요. 에이전트가 먼저 바뀔 파일과 설정을 보여 주고, 승인한 항목만 적용합니다.

```text
ysm-skills 저장소를 참고해서 이 프로젝트의 공통 규칙을 점검해줘.
```

[`adopt-project`](skills/adopt-project/SKILL.md) 스킬이 사용됩니다.

### 이 컴퓨터의 작업 지침 점검·갱신

어느 폴더에서든 요청할 수 있습니다. 에이전트가 이 컴퓨터의 소통·검증 지침을 GitHub 최신본과 비교하고, 승인하면 기존 파일을 백업한 뒤 갱신합니다.

```text
ysm-skills 저장소를 참고해서 이 컴퓨터의 작업 지침을 점검해줘.
```

[`setup-machine`](skills/setup-machine/SKILL.md) 스킬이 사용됩니다.

## 적용하면 무엇이 바뀌나요?

- **프로젝트**의 `AGENTS.md`에 공통 규칙을 추가하고 Git 훅과 설정 파일을 적용합니다. Git 훅은 커밋하거나 푸시할 때 제목 형식, 비밀값, 보호 브랜치 등을 자동으로 검사합니다. 설치 중 훅 파일이 다음 커밋에 포함할 목록에 추가될 수 있습니다.
- **프로젝트 규칙을 갱신할 때**는 공통 규칙 구역과 관리 파일인 Git 훅·PR 템플릿이 교체될 수 있습니다. 프로젝트 고유 지침은 공통 규칙 구역 밖에 작성하세요. [공통 작업 규칙](baseline/agents-block.md)
- **이 컴퓨터**에는 Claude Code와 Codex의 전역 지침을 적용합니다. 프로젝트와 별도로 위의 전역 지침 점검을 요청하면 됩니다. 채팅 계정에도 지침을 쓰려면 [Claude용](global/chat-claude.md) 또는 [ChatGPT용](global/chat-chatgpt.md) 문구를 계정 설정에 붙여 넣으세요.

## 다른 작업에 쓰기

| 하고 싶은 일 | 스킬 |
| --- | --- |
| README 작성·개선, 문서의 오류·중복 점검 | [write-readme](skills/write-readme/SKILL.md), [audit-docs](skills/audit-docs/SKILL.md) |
| 코드·테스트 정리, 화면·오류 문구 점검 | [tidy-code](skills/tidy-code/SKILL.md), [audit-messages](skills/audit-messages/SKILL.md) |
| 프로젝트 릴리스, 해결 방법을 다른 프로젝트와 공유 | [release-project](skills/release-project/SKILL.md), [share-lesson](skills/share-lesson/SKILL.md) |
| 화풍과 캐릭터가 일관된 리소그래프풍 일러스트 제작 | [riso-illustration](skills/riso-illustration/SKILL.md) |

표에서 하고 싶은 일을 골라 “ysm-skills 저장소를 참고해서 ~해줘”라고 요청해 보세요.

**Cloudflare Pages 배포**는 `ysm-skills`를 내려받은 폴더에서 에이전트를 열고, 배포할 GitHub 저장소 주소를 알려 주세요. 필요한 API 토큰 권한과 보관 위치를 먼저 확인하세요. [Cloudflare Pages 배포 안내](docs/cloudflare-pages.md#토큰)

## Claude Code 플러그인 설치 (선택)

스킬을 자주 쓴다면 터미널에서 Claude Code를 열고 아래 두 명령을 한 줄씩 입력하세요. 설치 후 `/ysm:new-project`, `/ysm:audit-docs`처럼 스킬 이름으로 부를 수 있습니다.

```text
/plugin marketplace add yimsemin/ysm-skills
/plugin install ysm@ysm-skills
```

설치한 스킬을 최신으로 유지하려면 `/plugin`의 **Marketplaces**에서 `ysm-skills`를 선택해 자동 업데이트를 켜세요. 바로 갱신하려면 같은 메뉴에서 **Update marketplace**를 선택하세요.

## 라이선스

[MIT](LICENSE)
