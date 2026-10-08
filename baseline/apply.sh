#!/bin/sh
# 베이스라인을 대상 프로젝트에 적용한다. 기존 파일은 덮어쓰지 않는다.
# 사용: apply.sh [--dry-run] [--noreply-email] <대상 폴더>
#   --noreply-email: gh 로그인 계정의 GitHub noreply 주소를 이 프로젝트의 커밋 이메일로 설정하고
#                    pre-commit이 검사하게 한다(새 프로젝트용).
# 출력(한 줄에 하나): CREATED|SAME|DIFFERS|APPENDED|UPDATED|INFO <경로 또는 메시지>
#   DIFFERS = 같은 경로에 다른 내용이 이미 있음. 덮어쓰지 않았으니 호출한 쪽이 병합한다.
set -eu

dry=0
noreply=0
while [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "--noreply-email" ]; do
  case "$1" in --dry-run) dry=1 ;; --noreply-email) noreply=1 ;; esac
  shift
done
target="${1:-}"
[ -n "$target" ] || { echo "usage: apply.sh [--dry-run] [--noreply-email] <target-dir>" >&2; exit 2; }
[ -d "$target" ] || { echo "not a directory: $target" >&2; exit 2; }

here="$(cd "$(dirname "$0")" && pwd)"
target="$(cd "$target" && pwd)"
version="$(tr -d '[:space:]' < "$here/VERSION")"

if [ ! -d "$target/.git" ]; then
  echo "INFO git init (main)"
  [ "$dry" = 1 ] || git -C "$target" init -q -b main
fi

# 1) 일반 파일: 없으면 복사, 같으면 SAME, 다르면 DIFFERS. .gitignore는 빠진 줄만 추가한다.
(cd "$here/files" && find . -type f | sed 's|^\./||' | sort) | while IFS= read -r rel; do
  src="$here/files/$rel"
  dst="$target/$rel"
  if [ ! -e "$dst" ]; then
    echo "CREATED $rel"
    if [ "$dry" = 0 ]; then
      mkdir -p "$(dirname "$dst")"
      cp -p "$src" "$dst"
    fi
  elif cmp -s "$src" "$dst"; then
    echo "SAME $rel"
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
  else
    echo "DIFFERS $rel"
  fi
done

# 2) AGENTS.md: 베이스라인 구역(마커 사이)만 만들거나 교체한다. 프로젝트 고유 내용은 건드리지 않는다.
agents="$target/AGENTS.md"
start="<!-- ysm-baseline:start -->"
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
  echo "UPDATED AGENTS.md (baseline block)"
  if [ "$dry" = 0 ]; then
    tmp="$(mktemp)"
    awk -v start="$start" -v end="$end" -v blk="$here/agents-block.md" '
      /ysm-baseline:start/ { print start; while ((getline l < blk) > 0) print l; skip=1; next }
      /ysm-baseline:end/ { print end; skip=0; next }
      !skip { print }
    ' "$agents" > "$tmp" && cat "$tmp" > "$agents"
    rm -f "$tmp"
  fi
else
  echo "APPENDED AGENTS.md (baseline block)"
  if [ "$dry" = 0 ]; then
    { printf '\n%s\n' "$start"; cat "$here/agents-block.md"; printf '%s\n' "$end"; } >> "$agents"
  fi
fi

# 3) 훅 활성화와 기반 버전 기록(.env.baseline은 .gitignore의 .env.*에 걸려 커밋되지 않는다)
if [ "$dry" = 0 ]; then
  [ -d "$target/.githooks" ] && chmod +x "$target"/.githooks/* 2>/dev/null || true
  git -C "$target" config core.hooksPath .githooks
  printf 'ysm-baseline=%s\n' "$version" > "$target/.env.baseline"
  rm -f "$target/.ysm-baseline"
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
echo "INFO hooksPath=.githooks based-on=$version (.env.baseline)"
