#!/bin/sh
# 전역 지침(Claude·Codex)과 전역 설정을 점검하고 적용한다. AI 토큰을 쓰지 않는다.
# 사용: apply-global.sh --check|--diff|--apply [--home DIR] [--only claude|codex|settings]
#   --check: 파일마다 `STATUS <MISSING|UNMARKED|OLD|CURRENT|PARTIAL|NOAPP|NEEDS_PYTHON> <경로>`를 출력한다.
#            NOAPP = 그 에이전트 폴더(~/.codex 등)가 없어 건드리지 않는다.
#   --diff : 적용하면 바뀔 내용을 보여 준다.
#   --apply: 마커 구역(ysm-global)과 설정의 확인 규칙만 쓴다. 쓰기 전에 기존 파일을 .bak-시각으로 백업한다.
#   UNMARKED = 마커 없이 사용자 줄만 있는 파일. 구역을 맨 위에 추가하며, 겹치는 옛 줄은 호출한 쪽이 정리한다.
set -eu

usage="usage: apply-global.sh --check|--diff|--apply [--home DIR] [--only claude|codex|settings]"
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
    *) echo "$usage" >&2; exit 2 ;;
  esac
  shift
done
[ -n "$mode" ] || { echo "$usage" >&2; exit 2; }

here="$(cd "$(dirname "$0")" && pwd)"
body="$here/agents.md"
# 정본 내용의 체크섬. 지침이 바뀔 때만 달라지고, 대상의 시작 마커에 기록한다(baseline/apply.sh와 같은 방식).
rev="$(cksum < "$body" | cut -d' ' -f1)"
start="<!-- ysm-global:start rev=$rev -->"
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
  PYTHONUTF8=1 "$py" - "$1" "$here/settings.json" "$2" <<'PY' | tr -d '\r'
import json, sys, os
path, srcpath, action = sys.argv[1:4]
want = json.load(open(srcpath, encoding="utf-8"))["permissions"]["ask"]
cur = {}
if os.path.exists(path):
    cur = json.load(open(path, encoding="utf-8"))
have = cur.get("permissions", {}).get("ask", [])
missing = [r for r in want if r not in have]
if action == "status":
    print("MISSING" if not os.path.exists(path) else ("CURRENT" if not missing else "PARTIAL"))
elif action == "diff":
    for r in missing: print("+ permissions.ask: " + r)
elif action == "apply" and missing:
    cur.setdefault("permissions", {}).setdefault("ask", []).extend(missing)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(cur, f, indent=2, ensure_ascii=False)
        f.write("\n")
PY
}
# Windows의 python3는 실행되지 않는 스토어 별칭일 수 있어 실제로 실행해 보고 고른다.
py=""; for c in python3 python; do "$c" -c "" >/dev/null 2>&1 && { py="$c"; break; }; done
have_py=0; [ -n "$py" ] && have_py=1

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
