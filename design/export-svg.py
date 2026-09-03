#!/usr/bin/env python3
"""Export CareMom screens as SVG (PNG embedded — valid for Figma/Illustrator)."""

from __future__ import annotations

import base64
import html
import importlib.util
import re
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent
SCREENS = ROOT / "screens"
PNG_DIR = ROOT / "png"
OUT_SVG = ROOT / "svg"
SOURCE = ROOT / "CareMom-All-Screens.html"


def _exp_mod():
    spec = importlib.util.spec_from_file_location(
        "export_figma_screens", ROOT / "export-figma-screens.py"
    )
    mod = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(mod)
    return mod


def ensure_screens() -> None:
    if SCREENS.exists() and any(SCREENS.glob("*.html")):
        return
    exp = _exp_mod()
    html_text = SOURCE.read_text(encoding="utf-8")
    style = exp.extract_style(html_text)
    SCREENS.mkdir(exist_ok=True)
    for label, block in exp.extract_screens(html_text):
        slug = exp.slugify(label)
        num = re.match(r"(\d+)", label)
        prefix = num.group(1).zfill(2) if num else "00"
        exp.write_single_html(style, label, block, SCREENS / f"{prefix}-{slug}.html")


def frame_size(stem: str) -> tuple[int, int]:
    if stem.endswith("widget-medium"):
        return 360, 170
    if stem.endswith("widget-small"):
        return 170, 170
    return 390, 844


def build_svg(png_path: Path, width: int, height: int, title: str) -> str:
    data = base64.b64encode(png_path.read_bytes()).decode("ascii")
    return f"""<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"
     width="{width}" height="{height}" viewBox="0 0 {width} {height}">
  <title>{html.escape(title)}</title>
  <image width="{width}" height="{height}" preserveAspectRatio="xMidYMid meet"
         xlink:href="data:image/png;base64,{data}"/>
</svg>
"""


def main() -> None:
    ensure_screens()
    PNG_DIR.mkdir(exist_ok=True)
    OUT_SVG.mkdir(exist_ok=True)

    # Regenerate PNG if missing
    if not any(PNG_DIR.glob("*.png")):
        subprocess.run(["python3", str(ROOT / "export-figma-screens.py")], check=True)

    files = sorted(SCREENS.glob("*.html"))
    for path in files:
        png_path = PNG_DIR / f"{path.stem}.png"
        if not png_path.exists():
            print(f"{path.stem}: skip (no PNG)")
            continue
        w, h = frame_size(path.stem)
        title = path.stem.replace("-", " ").title()
        svg_path = OUT_SVG / f"{path.stem}.svg"
        svg_path.write_text(build_svg(png_path, w, h, title), encoding="utf-8")
        ok = ET.parse(svg_path) is not None
        print(f"{path.stem}.svg: {'OK' if ok else 'FAIL'} ({w}x{h})")

    zip_path = ROOT / "CareMom-Screens-SVG.zip"
    subprocess.run(
        ["zip", "-j", str(zip_path), *[str(p) for p in sorted(OUT_SVG.glob("*.svg"))]],
        check=True,
    )
    print(f"\nDone: {len(list(OUT_SVG.glob('*.svg')))} SVG → {OUT_SVG}")
    print(f"ZIP: {zip_path}")


if __name__ == "__main__":
    main()
