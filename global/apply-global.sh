#!/bin/sh
# 전역 지침(Claude·Codex)과 전역 설정을 점검하고 적용한다. AI 토큰을 쓰지 않는다.
# 사용: apply-global.sh --check|--diff|--apply [--home DIR] [--only claude|codex|settings]
#   --check: 파일마다 `STATUS <MISSING|UNMARKED|OLD|CURRENT|PARTIAL|NOAPP|NEEDS_PYTHON> <경로>`를 출력한다.
#            NOAPP = 그 에이전트 폴더(~/.codex 등)가 없어 건드리지 않는다.
#   --diff : 적용하면 바뀔 내용을 보여 준다.
#   --apply: 마커 구역(ysm-global)과 설정의 확인 규칙만 쓴다. 쓰기 전에 기존 파일을 .bak-시각으로 백업한다.
#   UNMARKED = 마커 없이 사용자 줄만 있는 파일. 구역을 맨 위에 추가하며, 겹치는 옛 줄은 호출한 쪽이 정리한다.
set -eu

mode=""
only=""
home="${HOME}"
while [ $# -gt 0 ]; do
  case "$1" in
    --check) mode=check ;;
    --diff) mode=diff ;;
    --apply) mode=apply ;;
    --home) shift; home="${1:-}" ;;
    --only) shift; only="${1:-}" ;;
    *) echo "usage: apply-global.sh --check|--diff|--apply [--home DIR] [--only claude|codex|settings]" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$mode" ] || { echo "usage: apply-global.sh --check|--diff|--apply [--home DIR]" >&2; exit 2; }

here="$(cd "$(dirname "$0")" && pwd)"
version="$(tr -d '[:space:]' < "$here/VERSION")"
body="$here/agents.md"
start="<!-- ysm-global:start v$version -->"
end="<!-- ysm-global:end -->"
md_targets="$home/.claude/CLAUDE.md $home/.codex/AGENTS.md"
settings="$home/.claude/settings.json"
case "$only" in
  "") ;;
  claude) md_targets="$home/.claude/CLAUDE.md"; settings="" ;;
  codex) md_targets="$home/.codex/AGENTS.md"; settings="" ;;
  settings) md_targets="" ;;
  *) echo "--only는 claude, codex, settings 중 하나" >&2; exit 2 ;;
esac

render() {
  f="$1"
  if [ ! -f "$f" ]; then
    { echo "$start"; cat "$body"; echo "$end"; }
  elif grep -q 'ysm-global:start' "$f"; then
    awk -v start="$start" -v end="$end" -v blk="$body" '
      /ysm-global:start/ { print start; while ((getline l < blk) > 0) print l; skip=1; next }
      /ysm-global:end/ { print end; skip=0; next }
      !skip { print }' "$f"
  else
    { echo "$start"; cat "$body"; echo "$end"; echo; cat "$f"; }
  fi
}

md_status() {
  f="$1"
  if [ ! -f "$f" ] && [ ! -d "$(dirname "$f")" ]; then echo NOAPP
  elif [ ! -f "$f" ]; then echo MISSING
  elif ! grep -q 'ysm-global:start' "$f"; then echo UNMARKED
  elif [ "$(render "$f")" = "$(cat "$f")" ]; then echo CURRENT
  else echo OLD
  fi
}

# 설정: 필요한 ask 규칙이 모두 있는지 확인하고, 없으면 기존 키를 보존한 채 추가한다.
settings_py() {
  python3 - "$1" "$here/settings.json" "$2" <<'PY'
import json, sys, os
path, srcpath, action = sys.argv[1:4]
want = json.load(open(srcpath))["permissions"]["ask"]
cur = {}
if os.path.exists(path):
    cur = json.load(open(path))
have = cur.get("permissions", {}).get("ask", [])
missing = [r for r in want if r not in have]
if action == "status":
    print("MISSING" if not os.path.exists(path) else ("CURRENT" if not missing else "PARTIAL"))
elif action == "diff":
    for r in missing: print("+ permissions.ask: " + r)
elif action == "apply" and missing:
    cur.setdefault("permissions", {}).setdefault("ask", []).extend(missing)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    json.dump(cur, open(path, "w"), indent=2, ensure_ascii=False)
    open(path, "a").write("\n")
PY
}
have_py=0; command -v python3 >/dev/null 2>&1 && have_py=1

backup() { [ -f "$1" ] && cp -p "$1" "$1.bak-$(date +%Y%m%d%H%M%S)" || true; }

for f in $md_targets; do
  s="$(md_status "$f")"
  [ "$s" = NOAPP ] && { [ "$mode" = check ] && echo "STATUS NOAPP $f"; continue; }
  case "$mode" in
    check) echo "STATUS $s $f" ;;
    diff)
      [ "$s" = CURRENT ] && continue
      echo "--- $f ($s)"
      render "$f" | diff -u "$f" - 2>/dev/null | sed '1,2d' || true
      [ -f "$f" ] || render "$f" | sed 's/^/+ /'
      ;;
    apply)
      [ "$s" = CURRENT ] && { echo "CURRENT $f"; continue; }
      mkdir -p "$(dirname "$f")"
      tmp="$(mktemp)"; render "$f" > "$tmp"
      backup "$f"; cat "$tmp" > "$f"; rm -f "$tmp"
      echo "APPLIED $s $f"
      ;;
  esac
done

if [ -z "$settings" ]; then
  :
elif [ "$have_py" = 1 ]; then
  case "$mode" in
    check) echo "STATUS $(settings_py "$settings" status) $settings" ;;
    diff) out="$(settings_py "$settings" diff)"; [ -n "$out" ] && { echo "--- $settings"; echo "$out"; } || true ;;
    apply)
      if [ "$(settings_py "$settings" status)" = CURRENT ]; then echo "CURRENT $settings"
      else backup "$settings"; settings_py "$settings" apply; echo "APPLIED $settings"; fi
      ;;
  esac
else
  echo "STATUS NEEDS_PYTHON $settings"
fi
