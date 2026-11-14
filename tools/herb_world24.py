"""v24: травы в мире без коричневой «кочки» земли под ними. Из art/herb14_<id>.png и art/<id>_3.png делает
art/herbw_<id>.png: земля и её контур убираются, у корня — несколько травинок, чтобы растение «росло из травы».
python tools/herb_world24.py"""
import os
import glob
import random
from PIL import Image

ART = os.path.join(os.path.dirname(__file__), "..", "art")


def is_soil(c):
    r, g, b, a = c
    if a == 0:
        return False
    # коричневые/землистые: красный заметно больше зелёного, синий маленький
    return r > g + 12 and r > b + 18 and g < 140


def is_dark(c):
    r, g, b, a = c
    return a > 0 and r + g + b < 150


def clean(src, dst, seed):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    # нижняя зона, где лежит кочка
    zone = int(h * 0.30)
    y0 = h - zone
    soil_rows = 0
    for y in range(y0, h):
        if sum(1 for x in range(w) if is_soil(px[x, y])) >= 3:
            soil_rows += 1
    if soil_rows == 0:
        im.save(dst)
        return False
    # убрать землю
    for y in range(y0, h):
        for x in range(w):
            if is_soil(px[x, y]):
                px[x, y] = (0, 0, 0, 0)
    # убрать тёмный контур, который остался висеть от земли (тёмный пиксель без зелёного соседа сверху)
    for _ in range(2):
        rm = []
        for y in range(y0, h):
            for x in range(w):
                if not is_dark(px[x, y]):
                    continue
                n_solid = 0
                for dx, dy in ((1, 0), (-1, 0), (0, -1), (0, 1)):
                    q = (x + dx, y + dy)
                    if 0 <= q[0] < w and 0 <= q[1] < h and px[q][3] > 0 and not is_dark(px[q]):
                        n_solid += 1
                if n_solid == 0:
                    rm.append((x, y))
        for p in rm:
            px[p] = (0, 0, 0, 0)
    # где кончается растение (нижний непрозрачный ряд)
    bottom = 0
    for y in range(h):
        if any(px[x, y][3] > 0 for x in range(w)):
            bottom = y
    # травинки у корня: светлая/тёмная зелень с тёмным краем, разной высоты
    rnd = random.Random(seed)
    g1, g2, g3, ol = (98, 160, 72, 255), (68, 124, 56, 255), (130, 190, 92, 255), (34, 58, 30, 255)
    base_y = min(h - 2, bottom + 1)
    cx = w // 2
    for i in range(rnd.randint(5, 8)):
        x = cx + rnd.randint(-9, 9)
        hh = rnd.randint(2, 6)
        lean = rnd.choice((-1, 0, 0, 1))
        for k in range(hh):
            xx = x + (lean if k > hh // 2 else 0)
            yy = base_y - k
            if 0 <= xx < w and 0 <= yy < h and px[xx, yy][3] == 0:
                px[xx, yy] = g3 if k == hh - 1 else (g1 if i % 2 else g2)
                if 0 <= xx + 1 < w and px[xx + 1, yy][3] == 0:
                    px[xx + 1, yy] = ol
    # тень-штрих у корня (полупрозрачная), чтобы стояло на земле, а не висело
    for x in range(cx - 7, cx + 8):
        if 0 <= x < w and px[x, base_y + 1 if base_y + 1 < h else base_y][3] == 0:
            yy = base_y + 1 if base_y + 1 < h else base_y
            px[x, yy] = (30, 50, 30, 70)
    im.save(dst)
    return True


if __name__ == "__main__":
    n = 0
    seen = set()
    for f in sorted(glob.glob(os.path.join(ART, "herb14_*.png"))):
        hid = os.path.basename(f)[7:-4]
        seen.add(hid)
        if clean(f, os.path.join(ART, "herbw_%s.png" % hid), hash(hid) & 0xffff):
            n += 1
    for f in sorted(glob.glob(os.path.join(ART, "*_3.png"))):
        hid = os.path.basename(f)[:-6]
        if "_" in hid and hid.split("_")[0] in ("sapling", "icon", "fx", "ui"):
            continue
        if clean(f, os.path.join(ART, "herbw_%s.png" % hid), hash(hid) & 0xffff):
            n += 1
    print("ok", n)
