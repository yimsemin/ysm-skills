#!/bin/sh
# 저장소의 GitHub 병합 설정과 브랜치 보호를 베이스라인 표준과 비교한다. --apply일 때만 바꾼다.
# 사용: repo-settings.sh [--apply] [소유자/저장소]   (생략하면 현재 폴더의 원격 저장소)
# 표준:
#   병합 방식  squash 허용(커밋 메시지는 PR 제목+본문), rebase 금지, merge commit은 develop이 있을 때만 허용
#   보호 브랜치  main(있으면 develop): PR 필수, 관리자 포함, force push·삭제 금지
#               AGENTS.md에 `<!-- ysm:direct-main -->`가 있으면 main의 PR 필수는 빼고 나머지는 같다
#               이미 걸려 있는 필수 상태 확인(required_status_checks)은 그대로 보존한다
#   브랜치 자동 삭제  끔
# 출력(한 줄에 하나): SAME|DIFFERS|SET|INFO <항목>
#   비공개 저장소의 무료 플랜은 브랜치 보호를 걸 수 없다(INFO). 그 경우 로컬 훅만 작동한다.
set -eu

apply=0
[ "${1:-}" = "--apply" ] && { apply=1; shift; }
repo="${1:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"

info="$(gh api "repos/$repo" --jq '[.permissions.admin, .allow_squash_merge, .allow_merge_commit, .allow_rebase_merge, (.squash_merge_commit_title // "none"), (.squash_merge_commit_message // "none"), .delete_branch_on_merge, .default_branch] | @tsv')"
IFS='	' read -r admin sq mc rb sqt sqm del defb <<EOF
$info
EOF
[ "$admin" = "true" ] || { echo "INFO $repo: admin 권한이 없어 건너뛴다"; exit 0; }
[ "$defb" = "main" ] || echo "INFO 기본 브랜치가 main이 아니다: $defb"

has_develop=false
gh api "repos/$repo/branches/develop" >/dev/null 2>&1 && has_develop=true
direct_main=false
gh api -H "Accept: application/vnd.github.raw" "repos/$repo/contents/AGENTS.md" 2>/dev/null | grep -q '^<!-- ysm:direct-main -->' && direct_main=true

# 1) 병합 방식
want_mc="$has_develop"
diff=0
check() { # 항목 현재값 목표값
  if [ "$2" = "$3" ]; then echo "SAME $1=$2"; else echo "DIFFERS $1: $2 -> $3"; diff=1; fi
}
check allow_squash_merge "$sq" true
check allow_merge_commit "$mc" "$want_mc"
check allow_rebase_merge "$rb" false
check squash_merge_commit_title "$sqt" PR_TITLE
check squash_merge_commit_message "$sqm" PR_BODY
check delete_branch_on_merge "$del" false
if [ "$diff" = 1 ] && [ "$apply" = 1 ]; then
  gh api -X PATCH "repos/$repo" \
    -F allow_squash_merge=true -F "allow_merge_commit=$want_mc" -F allow_rebase_merge=false \
    -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY \
    -F delete_branch_on_merge=false >/dev/null
  echo "SET 병합 방식"
fi

# 2) 브랜치 보호
branches="main"
[ "$has_develop" = true ] && branches="main develop"
for b in $branches; do
  need_pr=true
  [ "$b" = main ] && [ "$direct_main" = true ] && need_pr=false
  cur="$(gh api "repos/$repo/branches/$b/protection" --jq '[.enforce_admins.enabled, .allow_force_pushes.enabled, .allow_deletions.enabled, (.required_pull_request_reviews != null)] | @tsv' 2>&1 || true)"
  case "$cur" in
    *"Upgrade to GitHub Pro"*) echo "INFO $b 보호: 무료 플랜의 비공개 저장소라 걸 수 없다(로컬 훅만 작동)"; continue ;;
    *"Branch not protected"*) cur="none" ;;
    true*|false*) ;;
    *) echo "INFO $b 보호: 조회 실패 - $(printf '%s' "$cur" | head -1 | cut -c1-120)"; continue ;;
  esac
  want="true	false	false	$need_pr"
  if [ "$cur" = "$want" ]; then
    echo "SAME $b 보호"
  else
    echo "DIFFERS $b 보호: 현재 [$(printf '%s' "$cur" | tr '\t' ' ')] 목표 [enforce_admins force_push deletions pr_required = $(printf '%s' "$want" | tr '\t' ' ')]"
    if [ "$apply" = 1 ]; then
      if [ "$need_pr" = true ]; then pr='{"required_approving_review_count":0}'; else pr='null'; fi
      sc="$(gh api "repos/$repo/branches/$b/protection" --jq 'if .required_status_checks then {strict: .required_status_checks.strict, contexts: .required_status_checks.contexts} else null end' 2>/dev/null | tr -d '\n')"
      [ -n "$sc" ] || sc=null
      gh api -X PUT "repos/$repo/branches/$b/protection" --input - >/dev/null <<EOF
{"required_status_checks":$sc,"enforce_admins":true,"required_pull_request_reviews":$pr,"restrictions":null,"allow_force_pushes":false,"allow_deletions":false}
EOF
      echo "SET $b 보호"
    fi
  fi
done
exit 0
