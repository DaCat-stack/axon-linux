#!/usr/bin/env python3
"""Картинки темы GRUB «axon» по макету grub-menu.html (справа, «можно так»).

Использование: render_grub_theme.py <каталог темы>
Шрифты (.pf2) сюда не входят: их делает grub-mkfont при сборке пакета axon-branding.
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageEnhance

ROOT = Path(__file__).resolve().parent.parent
WALL = ROOT / "pkgsrc/axon-branding/usr/share/wallpapers/AXON/contents/images/1920x1080.png"
LOGO = ROOT / "assets/axon-logo.png"
R = 12            # скругление выделенного пункта, px
SS = 4            # сглаживание: рисуем крупнее и уменьшаем


def rounded(size, radius, fill, outline=None, width=1):
    w, h = size
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((0, 0, w * SS - 1, h * SS - 1), radius=radius * SS,
                                          fill=fill, outline=outline, width=width * SS)
    return img.resize((w, h), Image.LANCZOS)


def background(out):
    # обои AXON, затемнённые как rgba(5,8,15,.35) в макете
    img = Image.open(WALL).convert("RGB")
    img = Image.blend(img, Image.new("RGB", img.size, (5, 8, 15)), 0.35)
    img.save(out / "background.png", optimize=True)


def select_pixmaps(out):
    # 9 кусков рамки выделенного пункта: углы R×R, стороны 1 px, центр 1×1
    n = 2 * R + 1
    box = rounded((n, n), R, (255, 255, 255, 31), (255, 255, 255, 56), 1)
    parts = {"nw": (0, 0, R, R), "n": (R, 0, R + 1, R), "ne": (R + 1, 0, n, R),
             "w": (0, R, R, R + 1), "c": (R, R, R + 1, R + 1), "e": (R + 1, R, n, R + 1),
             "sw": (0, R + 1, R, n), "s": (R, R + 1, R + 1, n), "se": (R + 1, R + 1, n, n)}
    for name, crop in parts.items():
        box.crop(crop).save(out / f"select_{name}.png")


def icons(out):
    d = out / "icons"
    d.mkdir(exist_ok=True)
    s = 64
    logo = Image.open(LOGO).convert("RGBA").resize((round(s * 0.66),) * 2, Image.LANCZOS)
    axon = rounded((s, s), 14, (14, 22, 38, 255), (255, 255, 255, 51), 1)
    axon.alpha_composite(logo, ((s - logo.width) // 2, (s - logo.height) // 2))
    axon.save(d / "axon.png")

    win = rounded((s, s), 14, (0, 120, 212, 255))
    dr = ImageDraw.Draw(win)
    p, g = 18, 3                       # окошко Windows: 4 квадрата
    q = (s - 2 * p - g) // 2
    for x in (p, p + q + g):
        for y in (p, p + q + g):
            dr.rectangle((x, y, x + q - 1, y + q - 1), fill=(255, 255, 255, 255))
    win.save(d / "windows.png")

    efi = rounded((s, s), 14, (42, 51, 70, 255))
    dr = ImageDraw.Draw(efi)
    c = s // 2                         # шестерёнка: круг с вырезом и зубцами
    for a in range(8):
        x, y = c + 17 * math.cos(a * math.pi / 4), c + 17 * math.sin(a * math.pi / 4)
        dr.ellipse((x - 4, y - 4, x + 4, y + 4), fill=(207, 216, 230, 255))
    dr.ellipse((c - 14, c - 14, c + 14, c + 14), fill=(207, 216, 230, 255))
    dr.ellipse((c - 6, c - 6, c + 6, c + 6), fill=(42, 51, 70, 255))
    efi.save(d / "efi.png")


def logo(out):
    img = Image.open(LOGO).convert("RGBA").resize((72, 72), Image.LANCZOS)
    img.save(out / "logo.png")


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    background(out)
    select_pixmaps(out)
    icons(out)
    logo(out)


if __name__ == "__main__":
    main(sys.argv[1])
