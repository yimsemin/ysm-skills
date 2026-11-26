#!/bin/sh
# 베이스라인 훅(baseline/managed/.githooks)이 막아야 할 것을 막고 허용할 것을 허용하는지,
# apply.sh가 훅을 실행 가능하게 설치하는지 임시 저장소에서 확인한다.
# 사용: sh tools/test-hooks.sh   (실패가 있으면 종료 코드 1)
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
fail=0
pass() { echo "ok   $1"; }
bad() { echo "FAIL $1"; fail=1; }
expect() { # 기대(0=통과, 1=막힘) 설명 명령...
  want="$1"; what="$2"; shift 2
  if "$@" >/dev/null 2>&1; then got=0; else got=1; fi
  [ "$got" = "$want" ] && pass "$what" || bad "$what"
}

git init -q --bare "$tmp/remote.git"
git init -q -b main "$tmp/w"
cd "$tmp/w" || exit 1
cp -R "$root/baseline/managed/.githooks" .githooks
chmod +x .githooks/*
git config core.hooksPath .githooks
git config user.email t@example.com
git config user.name t
git config core.autocrlf false
git remote add origin "$tmp/remote.git"
printf '# AGENTS.md\n\n<!-- ysm:commit-lang=en -->\n' > AGENTS.md
c() { echo "$1" >> f.txt; git add -A; git commit -q -m "$2"; }

# commit-msg
expect 0 "첫 커밋은 main에 허용" c 1 "chore: init"
git switch -q -c feat/x
expect 1 "type 없는 제목 차단" c 2 "add file"
expect 1 "마침표로 끝나는 제목 차단" c 3 "feat: add file."
expect 1 "commit-lang=en에서 한국어 제목 차단" c 4 "feat: 파일 추가"
expect 0 "형식에 맞는 제목 허용" c 5 "feat: add file"
echo 6 >> f.txt; git add -A
git commit -q -F - <<'EOF'
feat: add more

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
git log -1 --format=%B | grep -qi 'co-authored-by' && bad "AI co-author 트레일러 제거" || pass "AI co-author 트레일러 제거"

# pre-commit
echo 'TOKEN=x' > .env; git add -f .env
expect 1 ".env 커밋 차단" git commit -q -m "chore: add env"
git rm -q --cached .env; rm .env
echo "k=ghp_$(printf 'a%.0s' $(seq 1 30))" > s.txt; git add s.txt
expect 1 "비밀값 문자열 커밋 차단" git commit -q -m "chore: add s"
git rm -q --cached s.txt; rm s.txt
git config diff.broken.textconv false
echo '*.bin diff=broken' > .git/info/attributes
echo "k=ghp_$(printf 'a%.0s' $(seq 1 30))" > s.txt; echo x > b.bin; git add s.txt b.bin
expect 1 "텍스트 변환이 실패해도 비밀값 커밋 차단" git commit -q -m "chore: add s"
git rm -q --cached s.txt b.bin; rm s.txt b.bin .git/info/attributes

# pre-push
expect 0 "작업 브랜치 푸시 허용" git push -q origin feat/x
git switch -q main
git push -q --no-verify origin main 2>/dev/null
expect 1 "main 직접 커밋 차단" c 7 "fix: on main"
git reset -q --hard
git merge -q --ff-only feat/x
expect 1 "main 직접 푸시 차단" git push -q origin main
git reset -q --hard origin/main
printf '<!-- ysm:direct-main -->\n' >> AGENTS.md
expect 0 "direct-main 선언 시 main 커밋 허용" c 8 "chore: declare direct main"
expect 0 "direct-main 선언 시 main 푸시 허용" git push -q origin main
git reset -q --hard HEAD~1
expect 1 "force push 차단" git push -q -f origin main
expect 0 "YSM_ALLOW_FORCE=1이면 force push 허용" env YSM_ALLOW_FORCE=1 git push -q -f origin main
git tag -a v1 -m v1 HEAD; git push -q origin v1
git switch -q -c chore/tag-move; c 9 "chore: after tag"
git tag -f -a v1 -m v1 HEAD >/dev/null
expect 1 "태그 이동 차단" git push -q -f origin v1
expect 1 "main 삭제 차단" git push -q origin :main

# apply.sh: 실행 권한이 커밋에 남아야 macOS·Linux에서 훅이 실행된다. core.filemode=false는 Windows 동작이다.
modes() { git -C "$tmp/p" ls-files -s -- .githooks | cut -c1-6 | tr '\n' ' '; }
all_exec="100755 100755 100755 "
git init -q -b main "$tmp/p"
git -C "$tmp/p" config core.filemode false
sh "$root/baseline/apply.sh" "$tmp/p" >/dev/null
git -C "$tmp/p" add -A
[ "$(modes)" = "$all_exec" ] && pass "새로 적용한 훅은 실행 권한으로 기록" || bad "새로 적용한 훅은 실행 권한으로 기록"
for h in "$tmp"/p/.githooks/*; do git -C "$tmp/p" update-index --chmod=-x ".githooks/${h##*/}"; done
expect 1 "--check는 실행 권한 없는 훅을 STALE로 판단" sh "$root/baseline/apply.sh" --check "$tmp/p"
echo '# local edit' >> "$tmp/p/.githooks/pre-push"
before="$(git -C "$tmp/p" ls-files -s -- .githooks | cut -d' ' -f2)"
sh "$root/baseline/apply.sh" "$tmp/p" >/dev/null
[ "$(modes)" = "$all_exec" ] && pass "기존 훅의 실행 권한 복구" || bad "기존 훅의 실행 권한 복구"
[ "$(git -C "$tmp/p" ls-files -s -- .githooks | cut -d' ' -f2)" = "$before" ] && pass "권한 복구는 내용 변경을 스테이지하지 않음" || bad "권한 복구는 내용 변경을 스테이지하지 않음"

# apply.sh: 꺼지게 되는 기존 훅을 알린다.
off() { sh "$root/baseline/apply.sh" --dry-run "$1" | grep '꺼지는 훅'; }
git init -q -b main "$tmp/o"
expect 1 "샘플 훅만 있으면 꺼지는 훅 안내 없음" off "$tmp/o"
mkdir -p "$tmp/o/.git/hooks"; echo '#!/bin/sh' > "$tmp/o/.git/hooks/pre-push"
expect 0 ".git/hooks의 훅이 꺼진다고 안내" off "$tmp/o"
rm "$tmp/o/.git/hooks/pre-push"; git -C "$tmp/o" config core.hooksPath .husky/_
expect 0 "다른 core.hooksPath의 훅이 꺼진다고 안내" off "$tmp/o"

[ "$fail" = 0 ] && echo "OK"
exit "$fail"
