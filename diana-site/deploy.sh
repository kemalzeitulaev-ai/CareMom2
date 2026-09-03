#!/bin/bash
# Публикует страницу на бесплатный хостинг и выдаёт ссылку
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
FILE="$DIR/index.html"

deploy() {
  local name="$1" url="$2" extra_args="${3:-}"
  echo "→ Пробую $name..."
  RESPONSE=$(curl -sS -m 30 -X POST "$url" \
    -H "Content-Type: text/html" \
    $extra_args \
    --data-binary @"$FILE" 2>/dev/null) || return 1

  # PageDrop: {"url":"..."}
  LINK=$(echo "$RESPONSE" | python3 -c "
import sys, json, re
raw = sys.stdin.read().strip()
try:
    d = json.loads(raw)
    for k in ('url', 'link', 'publicUrl', 'public_url'):
        if d.get(k):
            print(d[k])
            sys.exit(0)
    if 'data' in d and isinstance(d['data'], dict):
        for k in ('url', 'link'):
            if d['data'].get(k):
                print(d['data'][k])
                sys.exit(0)
except json.JSONDecodeError:
    pass
for m in re.finditer(r'https?://[^\s\"\']+', raw):
    print(m.group(0))
    break
" 2>/dev/null)

  if [ -n "$LINK" ]; then
    echo ""
    echo "✅ Готово! Ссылка:"
    echo "$LINK"
    echo ""
    echo "Отправь её Диане 💕"
    exit 0
  fi
  return 1
}

echo "Публикую страницу..."
echo ""

deploy "PageDrop"   "https://pagedrop.dev/api/deploy" || \
deploy "Hurl"       "https://hurl.page/deploy" || \
deploy "BrewPage"   "https://brewpage.app/api/html" || \
deploy "ZeroDeploy" "https://api.zerodeploy.dev/drop" || {
  echo "❌ Не удалось опубликовать автоматически."
  echo ""
  echo "Альтернатива — GitHub Pages:"
  echo "  1. Создай репозиторий на github.com"
  echo "  2. git remote add origin <url>"
  echo "  3. git add docs/ && git commit -m 'Add diana page' && git push"
  echo "  4. Settings → Pages → Source: main, folder: /docs"
  echo "  5. Ссылка: https://<username>.github.io/<repo>/"
  exit 1
}
