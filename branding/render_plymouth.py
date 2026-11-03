#!/usr/bin/env python3
"""Готовит картинки для Plymouth-темы axon.

Всё рисуется на холсте 512x512 (логотип целиком), скрипт темы масштабирует
под экран. Пропорции взяты из макета boot-animation-v2.html, где лого 190 px.

Использование: render_plymouth.py <каталог темы>
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ASSETS = Path(__file__).resolve().parent.parent / "assets"
S = 512                      # размер холста логотипа
K = S / 190                  # 1 px макета → px холста
BLUE = (47, 134, 240)
GLOW_PAD = 160               # запас вокруг лого под свечение
SHEEN_FRAMES = 12


def part(name):
    return Image.open(ASSETS / name).convert("RGBA").resize((S, S), Image.LANCZOS)


def glow(logo):
    # drop-shadow(0 0 26px rgba(47,134,240,.8)): blur 26 px ≈ σ 13 px макета
    canvas = Image.new("L", (S + 2 * GLOW_PAD, S + 2 * GLOW_PAD), 0)
    canvas.paste(logo.getchannel("A"), (GLOW_PAD, GLOW_PAD))
    a = canvas.filter(ImageFilter.GaussianBlur(13 * K)).point(lambda v: round(v * 0.8))
    out = Image.new("RGBA", canvas.size, BLUE + (0,))
    out.putalpha(a)
    return out


def sheen_frame(logo_alpha, i):
    # полоса под 105° едет справа налево: центр от 1.2 до −0.2 ширины
    t = i / (SHEEN_FRAMES - 1)
    cx = (1.2 - 1.4 * t) * S
    half = 0.18 * S
    slope = math.tan(math.radians(15))   # 105° от вертикали ≈ наклон 15°
    band = Image.new("L", (S, S), 0)
    px = band.load()
    for y in range(S):
        shift = (y - S / 2) * slope
        for x in range(S):
            d = abs(x - cx + shift) / half
            if d < 1:
                px[x, y] = round(255 * 0.6 * (1 - d) ** 2)
    out = Image.new("RGBA", (S, S), (255, 255, 255, 0))
    out.putalpha(ImageChops.multiply(band, logo_alpha))
    return out


def dot():
    d = round(7 * K) * 4
    img = Image.new("RGBA", (d, d), (0, 0, 0, 0))
    ImageDraw.Draw(img).ellipse((0, 0, d - 1, d - 1), fill=BLUE + (255,))
    return img.resize((d // 4, d // 4), Image.LANCZOS)


def field():
    # поле пароля: 240x34 px макета, скругление, полупрозрачная заливка
    w, h = round(240 * K), round(34 * K)
    img = Image.new("RGBA", (w * 4, h * 4), (0, 0, 0, 0))
    ImageDraw.Draw(img).rounded_rectangle((0, 0, w * 4 - 1, h * 4 - 1), radius=h * 2,
                                          fill=(255, 255, 255, 36), outline=(255, 255, 255, 46), width=4)
    return img.resize((w, h), Image.LANCZOS)


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    blue, white = part("logo-blue.png"), part("logo-white.png")
    logo = Image.alpha_composite(blue, white)
    blue.save(out / "blue.png", optimize=True)
    white.save(out / "white.png", optimize=True)
    glow(logo).save(out / "glow.png", optimize=True)
    dot().save(out / "dot.png")
    field().save(out / "field.png")
    for i in range(SHEEN_FRAMES):
        sheen_frame(logo.getchannel("A"), i).save(out / f"sheen-{i:02d}.png", optimize=True)


if __name__ == "__main__":
    main(sys.argv[1])
