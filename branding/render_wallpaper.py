#!/usr/bin/env python3
"""Рисует обои AXON (они же фон окна входа).

Повторяет CSS из макета login-screen.html:
  radial-gradient(60% 70% at 18% 85%, rgba(40,168,168,.55), transparent 60%),
  radial-gradient(55% 65% at 85% 15%, rgba(47,134,240,.55), transparent 60%),
  radial-gradient(40% 50% at 60% 70%, rgba(70,60,200,.35), transparent 60%),
  #0a0f1c  + белый парус 55% ширины, right -6%, bottom -12%, opacity .05

Использование: render_wallpaper.py <ширина> <высота> <out.png>
"""
import sys
from pathlib import Path

from PIL import Image, ImageChops

ASSETS = Path(__file__).resolve().parent.parent / "assets"
BASE = (10, 15, 28)
# (цвет, альфа, центр x, центр y, радиус x, радиус y) — в долях экрана; нижний слой первым
BLOBS = [
    ((70, 60, 200), 0.35, 0.60, 0.70, 0.40, 0.50),
    ((47, 134, 240), 0.55, 0.85, 0.15, 0.55, 0.65),
    ((40, 168, 168), 0.55, 0.18, 0.85, 0.60, 0.70),
]
FADE_AT = 0.60  # «transparent 60%»


def blob_mask(w, h, alpha, cx, cy, rx, ry):
    # radial_gradient: 256x256, 0 в центре, ~255 на расстоянии 128 px
    g = Image.radial_gradient("L")
    peak = round(255 * alpha)
    g = g.point(lambda v: round(peak * max(0.0, 1 - (v / 255) / FADE_AT)))
    ew, eh = round(2 * rx * w), round(2 * ry * h)
    g = g.resize((ew, eh), Image.BICUBIC)
    mask = Image.new("L", (w, h), 0)
    mask.paste(g, (round(cx * w - ew / 2), round(cy * h - eh / 2)))
    return mask


def render(w, h):
    img = Image.new("RGB", (w, h), BASE)
    for color, alpha, cx, cy, rx, ry in BLOBS:
        img = Image.composite(Image.new("RGB", (w, h), color), img, blob_mask(w, h, alpha, cx, cy, rx, ry))

    sail = Image.open(ASSETS / "logo-white.png").convert("RGBA")
    box = round(0.55 * w)
    sail = sail.resize((box, box), Image.LANCZOS)
    sail.putalpha(sail.getchannel("A").point(lambda a: round(a * 0.05)))
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    layer.paste(sail, (round(w * 1.06) - box, round(h * 1.12) - box))
    img = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")

    # лёгкий шум против полос на градиентах
    noise = Image.effect_noise((w, h), 2)  # гаусс вокруг 128
    noise = Image.merge("RGB", [noise] * 3)
    return ImageChops.add(img, noise, offset=-128)


if __name__ == "__main__":
    w, h, out = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    Path(out).parent.mkdir(parents=True, exist_ok=True)
    render(w, h).save(out, optimize=True)
