#!/bin/sh
# 스킬 형식과 셸 스크립트 문법을 검사한다. 런타임 설치 없이 sh만 쓴다.
set -u
root="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
err() { echo "FAIL $1"; fail=1; }

for d in "$root"/skills/*/; do
  name="$(basename "$d")"
  f="$d/SKILL.md"
  [ -f "$f" ] || { err "$name: SKILL.md 없음"; continue; }
  [ "$(sed -n 1p "$f")" = "---" ] || err "$name: frontmatter 시작(---) 없음"
  fm_name="$(sed -n '2,/^---$/p' "$f" | sed -n 's/^name: *//p' | head -1)"
  [ "$fm_name" = "$name" ] || err "$name: name($fm_name)이 폴더명과 다름"
  sed -n '2,/^---$/p' "$f" | grep -q '^description: .\{20,\}' || err "$name: description 없음 또는 너무 짧음"
done

for s in "$root"/baseline/apply.sh "$root"/baseline/files/.githooks/* "$root"/tools/*.sh; do
  sh -n "$s" 2>/dev/null || err "$s: 셸 문법 오류"
done

# 루트의 baseline 사본이 정본과 같은지 확인한다.
(cd "$root/baseline/files" && find . -type f | sed 's|^\./||') | while IFS= read -r rel; do
  [ -f "$root/$rel" ] && ! cmp -s "$root/baseline/files/$rel" "$root/$rel" && echo "FAIL 루트 사본이 baseline과 다름: $rel (sh baseline/apply.sh . 로 갱신)"
done | grep -q FAIL && { echo "FAIL 루트 사본이 baseline과 다름"; fail=1; }
blk="$(sed -n '/ysm-baseline:start/,/ysm-baseline:end/p' "$root/AGENTS.md" | sed '1d;$d')"
[ "$blk" = "$(cat "$root/baseline/agents-block.md")" ] || err "AGENTS.md의 baseline 구역이 agents-block.md와 다름"

# 스킬마다 ysm-locate 블록이 같아야 한다.
n="$(for f in "$root"/skills/*/SKILL.md; do grep -q 'ysm-locate:start' "$f" && sed -n '/ysm-locate:start/,/ysm-locate:end/p' "$f" | cksum; done | sort -u | wc -l | tr -d ' ')"
[ "$n" -le 1 ] || err "ysm-locate 블록이 스킬마다 다름"

# 공개를 고려해 비밀·회사 자료가 섞이지 않았는지 간단히 확인한다.
if grep -rIlE '(gh[po]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC)? ?PRIVATE KEY-----)' "$root" --exclude-dir=.git --exclude=validate.sh >/dev/null 2>&1; then
  err "비밀값으로 보이는 문자열 발견"
fi

[ "$fail" = 0 ] && echo "OK"
exit "$fail"
