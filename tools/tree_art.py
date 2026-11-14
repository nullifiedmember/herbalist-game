# -*- coding: utf-8 -*-
"""Листья деревьев v17: значки предметов art/leaf_<дерево>.png (32x32) и повороты листа для окна веточек
art/leafw_<дерево>.png (8 поворотов по 28 px в ряд, лист смотрит вверх-вправо и вращается), ветка art/twig_bg.png не нужна (рисуется кодом).
Запуск (из папки game):  python tools/tree_art.py
"""
import os, math, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from PIL import Image
from food_design import ramp, hexc, shade, OUTLINE, hsh

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(os.path.dirname(HERE), "art")

# дерево: (форма, основной цвет, цвет жилки)
LEAVES = {
    "tree_a": ("oak", "5f8f2f", "35591b"),
    "tree_b": ("heart", "6fa83a", "3f6d22"),
    "tree_c": ("elm", "568a35", "30581f"),
    "tree_d": ("ash", "7aa83e", "466d22"),
    "pine_a": ("needles", "3f7a4a", "224a2e"),
    "pine_b": ("needles", "2f6a58", "1a4036"),
    "tree_blossom": ("petal", "f4a8c4", "c46a92"),
    "tree_autumn": ("maple", "e07a28", "9a3c12"),
    "tree_autumn2": ("ash", "d8602a", "8a2c12"),
    "tree_apple": ("oval", "7ab83a", "46751f"),
    "tree_birch": ("birch", "9ac848", "5a8a2a"),
    "tree_unicorn": ("heart", "f08cc0", "a84a86"),
}
NAMES = {
    "tree_a": "Дубовый лист", "tree_b": "Липовый лист", "tree_c": "Вязовый лист", "tree_d": "Ясеневый лист",
    "pine_a": "Сосновая хвоя", "pine_b": "Еловая хвоя", "tree_blossom": "Лепесток сакуры", "tree_autumn": "Кленовый лист",
    "tree_autumn2": "Рябиновый лист", "tree_apple": "Яблоневый лист", "tree_birch": "Берёзовый лист", "tree_unicorn": "Розовый лист",
}


def inside(shape, u, v):
    """u вдоль листа 0..1 (черенок..кончик), v поперёк -0.5..0.5 -> (внутри, глубина 0..1 от середины)"""
    if u < 0 or u > 1:
        return False, 0
    s = math.sin(math.pi * u)
    if shape == "oval":
        w = 0.40 * s ** 0.8
    elif shape == "heart":
        w = 0.46 * s ** 0.7 * (1.0 - 0.35 * u)
        if u > 0.9:
            w *= 0.6
    elif shape == "elm":
        w = 0.36 * math.sin(math.pi * min(1.0, u ** 0.8)) * (1.0 + 0.1 * math.sin(u * 30))
    elif shape == "oak":
        w = 0.28 * s ** 0.6 * (1.0 + 0.5 * math.sin(u * math.pi * 6.0 + 0.4))
    elif shape == "ash":
        w = 0.20 * s ** 0.7
    elif shape == "birch":
        w = 0.34 * s ** 0.8 * (1.0 + 0.12 * math.sin(u * 46))
    elif shape == "petal":
        w = 0.46 * s ** 0.55
        if u > 0.93:
            return False, 0
    elif shape == "maple":
        # пять лопастей: расходятся от середины
        cx, cy = 0.5, 0.0
        dx, dy = (u - cx), v
        ang = math.atan2(dy, dx)
        r = math.hypot(dx, dy * 1.0)
        lobe = 0.5 * (0.55 + 0.45 * abs(math.cos(2.5 * ang))) * (0.8 + 0.2 * math.cos(5 * ang))
        if u < 0.18 and abs(v) < 0.03:
            return True, 0.8
        return (r < lobe * 0.92), min(1.0, r / (lobe + 1e-6))
    elif shape == "needles":
        d = 1.0
        for off in (-0.16, 0.0, 0.16):
            vc = off * (0.2 + 0.8 * u)
            if abs(v - vc) < 0.032 and 0.05 < u < 0.97:
                return True, abs(v - vc) / 0.032
        return False, 0
    else:
        w = 0.4 * s
    if abs(v) <= w:
        return True, abs(v) / (w + 1e-6)
    return False, 0


def draw_leaf(size, shape, col, vein, angle, scale=1.0):
    """лист, повёрнутый на angle (рад): картинка size×size, пиксель-арт 4 тона + жилка + обводка"""
    rp = ramp(col)
    rv = shade(hexc(vein), 0.0)
    L = size * 0.86 * scale
    cx = size * 0.5 - math.cos(angle) * L * 0.5
    cy = size * 0.5 + math.sin(angle) * L * 0.5
    ca, sa = math.cos(angle), math.sin(angle)
    grid = [[None] * size for _ in range(size)]
    for y in range(size):
        for x in range(size):
            px, py = x + 0.5 - cx, y + 0.5 - cy
            u = (px * ca - py * sa) / L
            v = (px * sa + py * ca) / L
            ok, depth = inside(shape, u, v)
            if not ok:
                continue
            # свет сверху-слева: по поперечной координате относительно света
            lx = (-0.6 * (px / L) - 0.8 * (py / L))
            d = lx * 1.8 - depth * 0.5 + 0.35
            lvl = 3 if d > 0.55 else (2 if d > 0.1 else (1 if d > -0.35 else 0))
            c = rp[lvl]
            if shape not in ("needles", "petal") and abs(v) < 0.9 / L and 0.12 < u < 0.82:
                c = rv
            grid[y][x] = c
    im = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    q = im.load()
    for y in range(size):
        for x in range(size):
            if grid[y][x] is not None:
                q[x, y] = grid[y][x]
    for y in range(size):
        for x in range(size):
            if grid[y][x] is None:
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < size and 0 <= ny < size and grid[ny][nx] is not None:
                        q[x, y] = OUTLINE
                        break
    return im


def build():
    for tex, (shape, col, vein) in LEAVES.items():
        icon = draw_leaf(32, shape, col, vein, math.radians(38), 1.0)
        icon.save(os.path.join(ART, "leaf_%s.png" % tex))
        strip = Image.new("RGBA", (28 * 8, 28), (0, 0, 0, 0))
        for i in range(8):
            fr = draw_leaf(28, shape, col, vein, math.radians(i * 45 + 20), 1.0)
            strip.alpha_composite(fr, (i * 28, 0))
        strip.save(os.path.join(ART, "leafw_%s.png" % tex))
    # лист всех
    names = list(LEAVES.keys())
    sh = Image.new("RGBA", (len(names) * 44, 44 + 28 * 2), (214, 190, 150, 255))
    for i, t in enumerate(names):
        sh.alpha_composite(Image.open(os.path.join(ART, "leaf_%s.png" % t)), (i * 44 + 6, 6))
        sh.alpha_composite(Image.open(os.path.join(ART, "leafw_%s.png" % t)).crop((28, 0, 56, 28)), (i * 44 + 8, 46))
    sh = sh.resize((sh.width * 3, sh.height * 3), Image.NEAREST)
    sh.save(os.path.join(os.path.dirname(HERE), "screenshots", "v17_leaves.png"))


if __name__ == "__main__":
    build()
    print("листьев:", len(LEAVES))
