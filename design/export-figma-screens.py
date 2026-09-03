#!/usr/bin/env python3
"""Split CareMom-All-Screens.html into individual frames + PNG for Figma import."""

from __future__ import annotations

import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "CareMom-All-Screens.html"
OUT_HTML = ROOT / "screens"
OUT_PNG = ROOT / "png"
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

SINGLE_PAGE_CSS = """
  body {
    margin: 0; padding: 0; background: #E8E4E6;
    display: flex; align-items: center; justify-content: center;
    min-height: 100vh; width: 100vw;
  }
  .screen-wrap { margin: 0; }
  .screen-label { display: none; }
  .phone { box-shadow: none; }
"""


def extract_style(html: str) -> str:
    m = re.search(r"<style>(.*?)</style>", html, re.DOTALL)
    return m.group(1) if m else ""


def extract_screens(html: str) -> list[tuple[str, str]]:
    pattern = re.compile(
        r'<!--\s*(\d+\s+[^-]+?)\s*-->\s*'
        r'(<div class="screen-wrap">.*?</div></div>)',
        re.DOTALL,
    )
    screens: list[tuple[str, str]] = []
    for match in pattern.finditer(html):
        label = match.group(1).strip()
        block = match.group(2)
        screens.append((label, block))
    return screens


def slugify(label: str) -> str:
    name = label.lower()
    name = re.sub(r"^\d+\s*[·.]?\s*", "", name)
    name = re.sub(r"[^a-z0-9]+", "-", name).strip("-")
    return name or "screen"


def write_single_html(style: str, label: str, block: str, path: Path) -> None:
    doc = f"""<!DOCTYPE html>
<html lang="ru">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=390, initial-scale=1.0">
<title>CareMom — {label}</title>
<link rel="preconnect" href="https://fonts.googleapis.com">
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
<style>
{style}
{SINGLE_PAGE_CSS}
</style>
</head>
<body>
{block}
</body>
</html>
"""
    path.write_text(doc, encoding="utf-8")


def screenshot(html_path: Path, png_path: Path, width: int, height: int) -> bool:
    if not CHROME.exists():
        return False
    url = html_path.as_uri()
    cmd = [
        str(CHROME),
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        f"--window-size={width},{height}",
        f"--screenshot={png_path}",
        url,
    ]
    try:
        subprocess.run(cmd, check=True, capture_output=True, timeout=30)
        return png_path.exists()
    except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return False


def frame_size(block: str) -> tuple[int, int]:
    if "widget-frame widget-md" in block:
        return 360, 170
    if "widget-frame" in block:
        return 170, 170
    return 390, 844


def main() -> None:
    html = SOURCE.read_text(encoding="utf-8")
    style = extract_style(html)
    screens = extract_screens(html)
    if not screens:
        raise SystemExit("No screens found in HTML")

    OUT_HTML.mkdir(exist_ok=True)
    OUT_PNG.mkdir(exist_ok=True)

    manifest_lines = [
        "# CareMom — экраны для Figma",
        "",
        f"Figma file: https://www.figma.com/design/LWMP1WTPVRMCOlsybYWpfe/caremom",
        "",
        "## Быстрый импорт (html.to.design)",
        "",
        "1. Открой Figma файл (ссылка выше) и войди в аккаунт",
        "2. Plugins → html.to.design → Run",
        "3. Import from file → выбери файлы из папки `screens/`",
        "4. Импортируй по одному или пачками",
        "",
        "## Или перетащи PNG",
        "",
        "Файлы в `png/` — перетащи в Figma как референс",
        "",
        "| # | Экран | HTML | PNG |",
        "|---|-------|------|-----|",
    ]

    for label, block in screens:
        slug = slugify(label)
        num = re.match(r"(\d+)", label)
        prefix = num.group(1).zfill(2) if num else "00"
        filename = f"{prefix}-{slug}"
        html_path = OUT_HTML / f"{filename}.html"
        png_path = OUT_PNG / f"{filename}.png"
        w, h = frame_size(block)

        write_single_html(style, label, block, html_path)
        ok = screenshot(html_path, png_path, w + 80, h + 80)
        png_cell = f"`png/{filename}.png`" if ok else "—"
        manifest_lines.append(
            f"| {prefix} | {label.split('·', 1)[-1].strip()} | `screens/{filename}.html` | {png_cell} |"
        )
        status = "OK" if ok else "HTML only"
        print(f"{filename}: {status} ({w}x{h})")

    (ROOT / "FIGMA-SCREENS.md").write_text("\n".join(manifest_lines) + "\n", encoding="utf-8")
    print(f"\nDone: {len(screens)} screens → {OUT_HTML} + {OUT_PNG}")


if __name__ == "__main__":
    main()
