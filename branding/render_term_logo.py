#!/usr/bin/env python3
"""Лого AXON для терминала (fastfetch): полублоки «▀» с 24-битными цветами по настоящей картинке.

Пишет два файла: <out>.ansi — для fastfetch (logo type "file-raw"), <out>.html — для макета.
Использование: render_term_logo.py <ширина в символах> <out без расширения>
"""
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
LOGO = ROOT / "assets/axon-logo.png"


def cells(width):
    img = Image.open(LOGO).convert("RGBA")
    img = img.crop(img.getchannel("A").getbbox())
    # символ терминала примерно вдвое выше ширины; полублок даёт 2 пикселя по высоте
    height = round(width * img.height / img.width / 2) * 2
    img = img.resize((width, height), Image.LANCZOS)
    px = img.load()
    rows = []
    for y in range(0, height, 2):
        row = []
        for x in range(width):
            top, bot = px[x, y], px[x, y + 1]
            row.append((top if top[3] > 110 else None, bot if bot[3] > 110 else None))
        rows.append(row)
    return rows


def to_ansi(rows):
    out = []
    for row in rows:
        s = ""
        for top, bot in row:
            if top and bot:
                s += f"\x1b[38;2;{top[0]};{top[1]};{top[2]}m\x1b[48;2;{bot[0]};{bot[1]};{bot[2]}m▀\x1b[0m"
            elif top:
                s += f"\x1b[38;2;{top[0]};{top[1]};{top[2]}m▀\x1b[0m"
            elif bot:
                s += f"\x1b[38;2;{bot[0]};{bot[1]};{bot[2]}m▄\x1b[0m"
            else:
                s += " "
        out.append(s.rstrip())
    return "\n".join(out) + "\n"


def to_html(rows):
    out = []
    for row in rows:
        s = ""
        for top, bot in row:
            if top and bot:
                s += f'<span style="color:rgb{top[:3]};background:rgb{bot[:3]}">▀</span>'
            elif top:
                s += f'<span style="color:rgb{top[:3]}">▀</span>'
            elif bot:
                s += f'<span style="color:rgb{bot[:3]}">▄</span>'
            else:
                s += " "
        out.append(s)
    return "\n".join(out)


if __name__ == "__main__":
    w, base = int(sys.argv[1]), sys.argv[2]
    rows = cells(w)
    Path(base + ".ansi").write_text(to_ansi(rows))
    Path(base + ".html").write_text(to_html(rows))
    print(f"{w}x{len(rows)}")
