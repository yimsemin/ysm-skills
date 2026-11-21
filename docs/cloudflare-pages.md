# Cloudflare Pages 배포 기준

이 문서는 Cloudflare Pages 배포의 정본이다. 대상 저장소에는 복사하지 않고, 배포할 때마다 이 저장소에서 읽는다. 절차는 [deploy-cloudflare-pages 스킬](../skills/deploy-cloudflare-pages/SKILL.md)이 따른다. 계정 ID·루트 도메인·프로젝트 이름은 여기에 적지 않고 실행할 때 확인하거나 사용자에게 묻는다. 토큰은 사용자가 자기 Cloudflare 계정에서 발급해 이 저장소를 연 폴더에 둔다는 전제로 쓰였고, Cloudflare는 새 프로젝트에 Workers를 권장하지만 이 표준은 Pages(Git 연동)를 쓴다.

## 표준

| 항목 | 기준 |
|---|---|
| 플랫폼 | Pages (Git 연동 자동 배포). 직접 업로드와 Worker는 쓰지 않는다 |
| 프로젝트 이름 | GitHub 저장소 이름을 소문자 kebab-case로 바꾼 것 |
| 프로덕션 브랜치 | `main` |
| 개발 브랜치 | `develop`. 미리보기 배포는 `develop`만 하고 주소는 `develop.<프로젝트>.pages.dev` |
| 빌드 명령 / 출력 | `npm run build` / `dist`. 빌드가 없는 정적 사이트도 `build` 스크립트가 `dist/`로 복사하게 한다 |
| 루트 디렉터리 | 비움. 단, 워크스페이스는 아래 예외를 따른다 |
| Node 버전 | 저장소의 `.node-version` 한 파일(`.nvmrc` 같은 다른 파일은 두지 않는다) |
| 환경변수·비밀값 | 이름만 저장소의 `.env.example`에 두고 값은 대시보드에 직접 입력한다 |
| 프로덕션 도메인 | 사용자에게 묻고 정한다. 권장 기본값은 `<프로젝트 이름>.<루트 도메인>`. 개발 브랜치는 `pages.dev` 주소만 쓴다 |
| 배포 워크플로 | 저장소에 `wrangler pages deploy`나 `wrangler deploy`를 실행하는 GitHub Actions를 두지 않는다 |

- **패키지 매니저**: 기본은 npm이다. 패키지가 여러 개인 워크스페이스만 pnpm 등을 허용한다. pnpm 워크스페이스에서 검증한 구성은 루트 디렉터리를 앱 폴더(예: `apps/web`), 빌드 명령을 `pnpm --dir ../.. install --frozen-lockfile && pnpm build`, 출력을 `dist`로 두는 것이다.
- **Pages Functions**: `functions/` 폴더는 루트 디렉터리 기준 위치에서만 인식된다. Worker 코드를 옮길 때는 `_worker.js`(고급 모드)와 `_routes.json`(Worker가 처리할 경로만 `include`)을 출력 폴더에 넣고, `wrangler.jsonc`에는 `pages_build_output_dir`을 둔다.
- **`_redirects`**: 상태 코드는 200·301·302·303·307·308만 유효하다(`404`는 무시된다). Pages Functions가 처리하는 요청에는 `_redirects`가 적용되지 않는다.

## 토큰

- **저장소에 넣지 않는다.** 비공개 저장소여도 커밋 이력에 남고, 공개로 바꾸면 노출된다. GitHub Actions 비밀값은 CI만 읽을 수 있어 에이전트가 쓸 수 없다.
- **컴퓨터마다 따로 발급한다.** 이름에 컴퓨터를 적어(예: `ysm-skills-<컴퓨터>`) 분실하면 그 토큰만 폐기한다. 보관은 비밀번호 관리자에 한다.
- **쓰는 위치**: 환경변수 `CLOUDFLARE_API_TOKEN`(셸 설정 등 폴더 밖에 두는 것은 사용자가 고른 경우만)이 우선이고, 없으면 작업 폴더의 `.env`(`.gitignore`로 제외된 파일)를 읽는다. 대화에 붙여넣거나 출력하지 않는다.
- **필요한 권한(계정 토큰, 최소)**: 계정 / Cloudflare Pages / 편집, 영역 / DNS / 편집(루트 도메인 영역만), 영역 / 영역 / 읽기. Worker를 Pages로 옮길 때는 Worker 쪽 도메인 해제가 필요한데, 영역 단위 Workers 경로 권한이 없으면 API가 거절하므로 사용자가 대시보드에서 해제한다. 위 최소 조합 자체는 시험하지 않았다.
- `wrangler login`(브라우저 인증)은 목록 조회·프로젝트 생성/삭제·배포에만 쓰고, 설정 변경에는 쓰지 못한다.

## API 절차

각 셸 호출은 변수를 이어받지 못하므로 블록마다 처음 7줄을 포함한다. 토큰은 출력하지 않는다. `jq`는 설치돼 있지 않을 수 있고 전역 설치도 하지 않으므로 쓰지 않는다. JSON 값은 아래 `jv`로 뽑으며, `python3`·`python`이 둘 다 실행되지 않으면 `uv run python`을 쓴다(Windows의 `python3`는 실행되지 않는 스토어 별칭일 수 있어 실행해 보고 고른다).

```sh
T="${CLOUDFLARE_API_TOKEN:-$(grep -m1 '^CLOUDFLARE_API_TOKEN=' .env 2>/dev/null | cut -d= -f2- | tr -d "\"'\r")}"
H="Authorization: Bearer $T"; B=https://api.cloudflare.com/client/v4; J="Content-Type: application/json"
PY=$(for c in python3 python; do "$c" -c "" >/dev/null 2>&1 && { echo $c; break; }; done); export PYTHONUTF8=1
jv(){ "$PY" -I -c "import sys,json;d=json.load(sys.stdin);print($1)" | tr -d '\r'; }  # 사용: ... | jv "d['result'][0]['id']"
AID=$(curl -s -H "$H" $B/accounts | jv "d['result'][0]['id']")                    # 계정이 둘 이상이면 사용자에게 묻는다
ZID=$(curl -s -H "$H" "$B/zones?name=<루트 도메인>" | jv "d['result'][0]['id']")  # 영역은 같은 계정에 있어야 한다
P=<프로젝트>
```

- **조회**: `GET $B/accounts/$AID/pages/projects`(목록, 빌드·소스·도메인), `.../projects/$P`(하나), `GET $B/zones/$ZID/dns_records?per_page=100`.
- **생성(Git 연동)**: `POST .../pages/projects`, 본문은 아래. 생성만으로는 첫 배포가 시작되지 않는다.
  ```json
  {"name":"<프로젝트>","production_branch":"main",
   "source":{"type":"github","config":{"owner":"<소유자>","repo_name":"<저장소>","production_branch":"main",
     "pr_comments_enabled":false,"deployments_enabled":true,"production_deployments_enabled":true,
     "preview_deployment_setting":"custom","preview_branch_includes":["develop"],"preview_branch_excludes":[]}},
   "build_config":{"build_command":"npm run build","destination_dir":"dist","root_dir":""}}
  ```
- **설정 변경**: `PATCH .../projects/$P`. 소스 설정은 기존 값을 읽어 필요한 필드만 바꿔 `{"source":...}` 전체를 보낸다(파이썬으로 `d['result']['source']['config'][...]=...` 후 `json.dumps`). 빌드 설정은 `{"build_config":{...}}`만 보내도 된다.
- **첫 배포·재배포**: `POST .../projects/$P/deployments`에 `-F branch=main`. 상태는 `GET .../deployments/<id>`의 `.result.latest_stage`(`queued`→`clone_repo`→`build`→`deploy`), 로그는 `.../deployments/<id>/history/logs`.
- **도메인**: `POST .../projects/$P/domains`에 `{"name":"<도메인>"}`, 그다음 `POST $B/zones/$ZID/dns_records`에 `{"type":"CNAME","name":"<도메인>","content":"<프로젝트>.pages.dev","proxied":true}`. 상태는 `GET .../domains/<도메인>`(인증서 발급 중에는 `pending`이어도 접속된다).
- **삭제**: `DELETE .../projects/$P`. 같은 이름이 필요해 지우기 전에는 임시 이름으로 같은 설정을 만들어 빌드와 응답을 확인한다.
- **GitHub 브랜치 생성**: `gh api repos/<소유자>/<저장소>/git/refs -f ref=refs/heads/develop -f sha=<main의 커밋>`.

## 알아 둘 제약

- 직접 업로드 프로젝트를 Git 연동으로 바꾸는 방법은 확인하지 못했다. 같은 이름이 필요하면 삭제 후 새로 만들고, 삭제 전에 사용자 승인을 받는다.
- 비공개 저장소여도 `develop`의 미리보기 주소는 기본적으로 누구나 열 수 있다. 제한하려면 Cloudflare Access를 따로 설정한다.
- Git 연동 생성에는 Cloudflare의 GitHub 앱이 해당 저장소에 권한을 가져야 한다. API가 이를 거절하면 대시보드에서 저장소 연결을 한 번 승인해야 한다.
- 도메인을 Worker에서 Pages로 옮길 때는 Worker 쪽 연결을 풀어야 Worker가 만든 읽기 전용 DNS 레코드가 사라지고 CNAME을 만들 수 있다. 전환 중 잠깐 끊긴다. 로컬 DNS 캐시 때문에 몇 분간 이 컴퓨터에서만 안 열릴 수 있으며 `dig @1.1.1.1`로 확인한다.
- 커스텀 도메인 DNS의 루트 영역에 메일 등 다른 레코드가 있으면 건드리지 않는다.
- 프로젝트 목록 조회에 `per_page`를 붙이지 않는다(50은 거절된다). 한 페이지는 10개이므로 `result_info.total_pages`를 읽는다.
- `<프로젝트>.pages.dev`는 개발이 아니라 프로덕션(`main`)과 같은 내용이다. 개발은 `develop.<프로젝트>.pages.dev`다. 이름이 이미 쓰이면 `my-app-sample-1tj`처럼 접미사가 붙으므로 실제 주소는 프로젝트의 `subdomain` 필드로 확인한다.
- 미리보기 배포는 같은 저장소의 브랜치·PR에서만 만들어지고 포크 PR에는 만들어지지 않는다.
- 빌드 명령에 `npm ci`를 붙이지 않는다. Pages가 빌드 전에 `npm clean-install`을 자동 실행한다.
- 저장소와 GitHub 앱 권한이 정상인데 클론 단계가 `Repository not found`로 실패하면 같은 브랜치를 재배포한다. 재배포로 풀리는 경우가 있다.

## 확인 항목

배포가 끝났다고 말하기 전에 API로 다시 조회해 아래를 확인한다.

1. 프로덕션 브랜치가 `main`이고, 미리보기가 `custom`·`["develop"]`이다.
2. 빌드 명령·출력·루트 디렉터리가 이 표준과 같고 최신 프로덕션 배포의 `deploy` 단계가 `success`다.
3. 프로덕션 도메인이 200으로 응답한다(필요하면 `curl --resolve`로 Cloudflare DNS 기준 확인).
4. 대상 저장소에 `.node-version`, `build` 스크립트, `develop` 브랜치가 있고 배포용 GitHub Actions가 없다.
