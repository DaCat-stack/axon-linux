#!/usr/bin/env python3
"""Превью пресетов A/B/C: вырезает три экрана из скриншота макета desktop.html.

Скриншот делается браузером без окна, например:
  "Brave Browser" --headless=new --window-size=1300,2700 --screenshot=desk.png <url макета>
Использование: render_previews.py <desk.png> <каталог look-and-feel>
"""
import sys
from pathlib import Path

from PIL import Image

PAGE_BG = (27, 29, 34)       # #1b1d22 — фон страницы макета
SIZE = (480, 270)


def screens(img):
    """Ищет по центральному столбцу три блока высотой > 300 px, отличные от фона страницы."""
    w, h = img.size
    x = w // 2
    rows = [img.getpixel((x, y))[:3] != PAGE_BG for y in range(h)]
    blocks, start = [], None
    for y, inside in enumerate(rows + [False]):
        if inside and start is None:
            start = y
        elif not inside and start is not None:
            if y - start > 300:
                blocks.append((start, y))
            start = None
    return blocks


def bounds_x(img, y):
    w = img.size[0]
    xs = [x for x in range(w) if img.getpixel((x, y))[:3] != PAGE_BG]
    return xs[0], xs[-1] + 1


def main(shot, lnf_dir):
    img = Image.open(shot).convert("RGB")
    blocks = screens(img)
    if len(blocks) != 3:
        sys.exit(f"нашёл {len(blocks)} экранов вместо 3: {blocks}")
    for v, (y0, y1) in zip("abc", blocks):
        x0, x1 = bounds_x(img, (y0 + y1) // 2)
        out = Path(lnf_dir) / f"org.axon.desktop.{v}/contents/previews/preview.png"
        img.crop((x0, y0, x1, y1)).resize(SIZE, Image.LANCZOS).save(out, optimize=True)
        print(v, (x0, y0, x1, y1), "→", out)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
