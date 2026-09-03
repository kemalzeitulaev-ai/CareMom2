#!/bin/bash
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
PNG="$DIR/png"
PORT=8765

if [ ! -d "$PNG" ] || [ -z "$(ls -A "$PNG"/*.png 2>/dev/null)" ]; then
  echo "PNG не найдены. Генерирую…"
  python3 "$DIR/export-figma-screens.py"
fi

echo ""
echo "CareMom → Figma import"
echo "======================"
echo ""
echo "1) Сервер PNG: http://localhost:$PORT"
echo "2) Открой Figma: https://www.figma.com/design/LWMP1WTPVRMCOlsybYWpfe/caremom"
echo "3) Plugins → Development → Import plugin from manifest…"
echo "   Файл: $DIR/figma-plugin/manifest.json"
echo "4) Plugins → Development → CareMom Import Screens → Run"
echo ""
echo "Ctrl+C — остановить сервер"
echo ""

cd "$PNG"
python3 -m http.server "$PORT"
