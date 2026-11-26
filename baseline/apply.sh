#!/bin/sh
# 베이스라인을 대상 프로젝트에 적용한다.
# 사용: apply.sh [--dry-run] [--noreply-email] <대상 폴더>
#       apply.sh --check <대상 폴더>   낡았는지만 알린다(CURRENT|STALE|UNKNOWN, 최신이 아니면 종료 코드 1)
#   --noreply-email: gh 로그인 계정의 GitHub noreply 주소를 이 프로젝트의 커밋 이메일로 설정하고
#                    pre-commit이 검사하게 한다(새 프로젝트용).
# 파일 종류:
#   managed/ 관리 파일(훅, PR 템플릿). 프로젝트가 고치지 않으므로 정본으로 교체한다.
#            단 git에 커밋되지 않은 변경이 있으면 교체하지 않고 DIFFERS로 알린다(되돌릴 수 없으므로).
#   seed/    시드 파일. 없을 때만 만들고, 다르면 DIFFERS로 알린다(.gitignore만 빠진 줄을 추가).
#   agents-block.md  AGENTS.md의 마커 구역. 통째로 교체하고 시작 마커에 rev(이 파일의 체크섬)를 기록한다.
# 출력(한 줄에 하나): CREATED|SAME|UPDATED|DIFFERS|APPENDED|INFO <경로 또는 메시지>
#   DIFFERS = 덮어쓰지 않았으니 호출한 쪽이 읽고 병합한다.
set -eu

dry=0
noreply=0
check=0
while [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "--noreply-email" ] || [ "${1:-}" = "--check" ]; do
  case "$1" in --dry-run) dry=1 ;; --noreply-email) noreply=1 ;; --check) check=1 ;; esac
  shift
done
target="${1:-}"
[ -n "$target" ] || { echo "usage: apply.sh [--dry-run] [--noreply-email] [--check] <target-dir>" >&2; exit 2; }
[ -d "$target" ] || { echo "not a directory: $target" >&2; exit 2; }

here="$(cd "$(dirname "$0")" && pwd)"
target="$(cd "$target" && pwd)"
rev="$(cksum < "$here/agents-block.md" | cut -d' ' -f1)"
list() { (cd "$here/$1" && find . -type f | sed 's|^\./||' | sort); }

if [ "$check" = 1 ]; then
  have="$(sed -n 's/.*ysm-baseline:start rev=\([0-9][0-9]*\).*/\1/p' "$target/AGENTS.md" 2>/dev/null | sed -n 1p)"
  [ -n "$have" ] || { echo "UNKNOWN 적용 기록(rev)이 없다. apply.sh로 적용하면 기록된다"; exit 1; }
  stale=""
  [ "$have" = "$rev" ] || stale="AGENTS.md 구역"
  for rel in $(list managed); do cmp -s "$here/managed/$rel" "$target/$rel" || stale="${stale:+$stale, }$rel"; done
  [ -z "$stale" ] && { echo "CURRENT"; exit 0; }
  echo "STALE $stale. 갱신하려면 apply.sh를 실행한다"; exit 1
fi

if [ ! -d "$target/.git" ]; then
  echo "INFO git init (main)"
  [ "$dry" = 1 ] || git -C "$target" init -q -b main
fi

copy() { [ "$dry" = 1 ] || { mkdir -p "$(dirname "$2")"; cp -p "$1" "$2"; }; }
# 커밋된 상태 그대로인 파일만 교체해도 git으로 되돌릴 수 있다.
clean() {
  git -C "$target" ls-files --error-unmatch -- "$1" >/dev/null 2>&1 &&
    git -C "$target" diff --quiet HEAD -- "$1" 2>/dev/null
}

# 1) 관리 파일
for rel in $(list managed); do
  src="$here/managed/$rel"; dst="$target/$rel"
  if [ ! -e "$dst" ]; then echo "CREATED $rel"; copy "$src" "$dst"
  elif cmp -s "$src" "$dst"; then echo "SAME $rel"
  elif clean "$rel"; then
    echo "UPDATED $rel"
    case "$rel" in
      .githooks/*) echo "INFO $rel: 교체되는 훅에 프로젝트 전용 검사가 있었는지 이전 내용(git show HEAD:$rel)과 비교한다. 전용 푸시 검사는 .githooks/pre-push.local 로 옮긴다" ;;
    esac
    copy "$src" "$dst"
  else echo "DIFFERS $rel (관리 파일인데 커밋되지 않은 변경이 있다)"
  fi
done

# 2) 시드 파일
for rel in $(list seed); do
  src="$here/seed/$rel"; dst="$target/$rel"
  if [ ! -e "$dst" ]; then echo "CREATED $rel"; copy "$src" "$dst"
  elif cmp -s "$src" "$dst"; then echo "SAME $rel"
  elif [ "$rel" = ".gitignore" ]; then
    added=0
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      case "$line" in \#*) continue ;; esac
      if ! grep -qxF -- "$line" "$dst"; then
        [ "$dry" = 1 ] || printf '%s\n' "$line" >> "$dst"
        added=1
      fi
    done < "$src"
    [ "$added" = 1 ] && echo "APPENDED $rel" || echo "SAME $rel"
  else echo "DIFFERS $rel"
  fi
done

# 3) AGENTS.md: 베이스라인 구역(마커 사이)만 만들거나 교체한다. 프로젝트 고유 내용은 건드리지 않는다.
agents="$target/AGENTS.md"
start="<!-- ysm-baseline:start rev=$rev -->"
end="<!-- ysm-baseline:end -->"
if [ ! -e "$agents" ]; then
  echo "CREATED AGENTS.md"
  if [ "$dry" = 0 ]; then
    awk -v start="$start" -v end="$end" -v blk="$here/agents-block.md" '
      /ysm-baseline:start/ { print start; while ((getline l < blk) > 0) print l; next }
      /ysm-baseline:end/ { print end; next }
      { print }
    ' "$here/agents-skeleton.md" > "$agents"
  fi
elif grep -q 'ysm-baseline:start' "$agents"; then
  tmp="$(mktemp)"
  awk -v start="$start" -v end="$end" -v blk="$here/agents-block.md" '
    /ysm-baseline:start/ { print start; while ((getline l < blk) > 0) print l; skip=1; next }
    /ysm-baseline:end/ { print end; skip=0; next }
    !skip { print }
  ' "$agents" > "$tmp"
  if cmp -s "$tmp" "$agents"; then
    echo "SAME AGENTS.md (baseline block)"
  else
    echo "UPDATED AGENTS.md (baseline block)"
    [ "$dry" = 1 ] || cat "$tmp" > "$agents"
  fi
  rm -f "$tmp"
else
  echo "APPENDED AGENTS.md (baseline block)"
  if [ "$dry" = 0 ]; then
    { printf '\n%s\n' "$start"; cat "$here/agents-block.md"; printf '%s\n' "$end"; } >> "$agents"
  fi
fi

# 4) 훅 활성화
if [ "$dry" = 0 ]; then
  [ -d "$target/.githooks" ] && chmod +x "$target"/.githooks/* 2>/dev/null || true
  git -C "$target" config core.hooksPath .githooks
fi
if [ "$noreply" = 1 ]; then
  login="$(gh api user -q .login 2>/dev/null || true)"
  uid="$(gh api user -q .id 2>/dev/null || true)"
  if [ -n "$login" ] && [ -n "$uid" ]; then
    if [ "$dry" = 0 ]; then
      git -C "$target" config --local user.email "$uid+$login@users.noreply.github.com"
      git -C "$target" config --local ysm.requireNoreply true
    fi
    echo "INFO commit email -> $uid+$login@users.noreply.github.com"
  else
    echo "INFO noreply-email SKIPPED: gh 로그인(gh auth login) 후 다시 실행한다"
  fi
fi
echo "INFO hooksPath=.githooks"
