# -*- coding: utf-8 -*-
"""Основание растения: тень-«лунка» сзади и травинки спереди. Серые — игра красит их в цвет земли биома
(plant_ground27.gd), чтобы трава и цветы выглядели выросшими прямо из земли.
Запуск: python plant_base.py -> game/art/plant_base_back.png, plant_base_front.png"""
import os, random
from PIL import Image

ART = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "art"))
G = lambda v, a=255: (int(255 * v), int(255 * v), int(255 * v), a)


def back():
    W, H = 30, 10
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); px = im.load()
    cx, cy = W / 2, H / 2 + 1
    for y in range(H):
        for x in range(W):
            d = ((x + 0.5 - cx) / 13.5) ** 2 + ((y + 0.5 - cy) / 3.6) ** 2
            if d <= 1.0:
                px[x, y] = G(0.50 if d < 0.55 else 0.62, 175 if d < 0.55 else 110)
    r = random.Random(3)
    # травинки сзади (выше, видны по бокам)
    for x in (3, 5, 8, 21, 24, 26):
        h = r.randint(3, 5)
        for k in range(h):
            yy = H - 3 - k; xx = x + (k // 2) * (1 if x > 15 else -1)
            if 0 <= xx < W and 0 <= yy < H:
                px[xx, yy] = G(0.78 if k < h - 1 else 0.95)
    return im


def front():
    """Три-четыре пучка травинок веером (не ровный ряд)."""
    W, H = 30, 7
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); px = im.load()
    clumps = [(4, 3), (11, 2), (19, 3), (26, 3)]
    for cx, n in clumps:
        blades = [(-1, 3, -1), (0, 5, 0), (1, 4, 1)] if n == 3 else [(-1, 3, -1), (1, 4, 1)]
        for dx, h, lean in blades:
            for k in range(h):
                xx = cx + dx + (lean if k >= h // 2 + 1 else 0); yy = H - 1 - k
                if 0 <= xx < W:
                    px[xx, yy] = G(0.62 if k == 0 else 0.82 if k < h - 1 else 1.0)
    return im


if __name__ == "__main__":
    back().save(os.path.join(ART, "plant_base_back.png"))
    front().save(os.path.join(ART, "plant_base_front.png"))
    print("ok")
