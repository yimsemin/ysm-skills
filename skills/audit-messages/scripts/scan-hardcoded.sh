#!/bin/sh
# 코드에 직접 쓰인 사용자용 문자열 후보를 찾는다(한글이 든 줄, 카탈로그·문서·테스트 제외).
# 사용: sh scan-hardcoded.sh <폴더> [제외할 카탈로그 경로 패턴]
# 후보 목록일 뿐이며 주석·로그·개발자용 문구는 사람이 걸러야 한다.
set -u
dir="${1:?사용: scan-hardcoded.sh <폴더> [제외 패턴]}"
skip="${2:-__none__}"
grep -rInE '[가-힣]' "$dir" \
  --include='*.js' --include='*.ts' --include='*.tsx' --include='*.jsx' \
  --include='*.py' --include='*.sh' --include='*.html' --include='*.vue' \
  --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=.venv --exclude-dir=dist \
  --exclude-dir=docs --exclude-dir=test --exclude-dir=tests 2>/dev/null |
  grep -vE "$skip" |
  grep -vE '^[^:]+:[0-9]+:[[:space:]]*(//|#|\*|/\*)'
exit 0
