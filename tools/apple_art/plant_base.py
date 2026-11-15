# -*- coding: utf-8 -*-
"""Основание растения: мягкая тень-«лунка» сзади и неровный край травы спереди. Серые — игра красит их в цвет
земли биома (plant_ground27.gd), чтобы трава и цветы выглядели выросшими прямо из земли.
v27b: тень без жёстких краёв (прозрачность тает к краю ступеньками), без боковых травинок;
передний край — невысокие пучки с неровным верхом, прячут прямой срез низа растения.
Запуск: python plant_base.py -> game/art/plant_base_back.png, plant_base_front.png"""
import os, random
from PIL import Image

ART = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", "art"))
G = lambda v, a=255: (int(255 * v), int(255 * v), int(255 * v), a)


def back():
    """Тень-лунка: тёмная в середине, к краю тает, края рваные (шахматка), чтобы не было ровного овала."""
    W, H = 28, 9
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); px = im.load()
    cx, cy = W / 2, H / 2 + 0.5
    for y in range(H):
        for x in range(W):
            d = ((x + 0.5 - cx) / 12.5) ** 2 + ((y + 0.5 - cy) / 3.9) ** 2
            if d < 0.35:
                a = 150
            elif d < 0.62:
                a = 110
            elif d < 0.85:
                a = 70
            elif d < 1.0 and (x + y) % 2 == 0:
                a = 40   # рваный край
            else:
                continue
            px[x, y] = G(1.0, a)
    return im


def front():
    """Неровный край травы: сплошная нижняя кромка + пучки разной высоты, светлее к кончикам."""
    W, H = 26, 6
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0)); px = im.load()
    r = random.Random(7)
    # нижняя кромка: от 3 до 22, по краям тоньше
    for x in range(3, 23):
        px[x, H - 1] = G(0.80, 230)
        if 5 <= x <= 20:
            px[x, H - 2] = G(0.86)
    # пучки: (x, высота, наклон)
    for x, h, lean in [(4, 2, -1), (6, 3, 0), (8, 2, 1), (10, 4, -1), (12, 3, 1), (14, 2, 0),
                       (15, 4, 1), (17, 3, -1), (19, 4, 0), (21, 2, 1)]:
        for k in range(h):
            xx = x + (lean if k >= h - 1 and h > 2 else 0)
            yy = H - 1 - k
            if 0 <= xx < W:
                px[xx, yy] = G(0.86 if k < h - 1 else 1.0)
        if h >= 3 and r.random() < 0.6:   # пучок потолще у корня
            px[x + (1 if lean >= 0 else -1), H - 2] = G(0.86)
    return im


if __name__ == "__main__":
    back().save(os.path.join(ART, "plant_base_back.png"))
    front().save(os.path.join(ART, "plant_base_front.png"))
    print("ok")
