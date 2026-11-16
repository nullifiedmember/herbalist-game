"""v31: грядки как на фото — тёмная земля длинной полосой и соломенные дорожки между рядами.
Плитка 44x32 (шаг сетки грядок): сверху 11 px и снизу 7 px соломы, посередине 14 px земли.
Соседние грядки по x сливаются в сплошной ряд, соседние ряды по y делят соломенную дорожку 12 px.
Варианты: s — одинокая, l/m/r — левый конец / середина / правый конец ряда.
Запуск из папки game:  python tools/art_v31.py  (потом godot --headless --import)
"""
import math, os
import numpy as np
from PIL import Image

ART = os.path.join(os.path.dirname(__file__), "..", "art")
W, H = 44, 32


def hx(s, a=255):
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), a)


STRAW = [hx("f3e3a6"), hx("e6cf86"), hx("d6b868"), hx("b99a52"), hx("a98a48")]


def make(kind, variant, seed):
    rg = np.random.default_rng(seed)
    im = np.zeros((H, W, 4), np.uint8)
    wet = kind == "wet"
    left = variant in ("l", "s")
    right = variant in ("r", "s")
    # --- солома: вся плитка
    for y in range(H):
        for x in range(W):
            im[y, x] = STRAW[1] if rg.random() < 0.55 else STRAW[2]
    # соломинки-штрихи, по x по кругу (чтобы плитки стыковались)
    for _ in range(150):
        x0, y0 = int(rg.integers(0, W)), int(rg.integers(0, H))
        ln = int(rg.integers(3, 7))
        dy = int(rg.integers(-1, 2))
        col = STRAW[int(rg.choice([0, 0, 1, 3, 4]))]
        for k in range(ln):
            xx = (x0 + k) % W
            yy = y0 + (k * dy) // 2
            if 0 <= yy < H:
                im[yy, xx] = col
    # --- земля: волнистая граница, по x период 44
    ph = rg.uniform(0, math.tau)
    base = hx("3a2a1f") if not wet else hx("2a1d16")
    mid = hx("4a3626") if not wet else hx("352619")
    hi = hx("5e4631") if not wet else hx("443122")
    lo = hx("2b1e16") if not wet else hx("1e1510")
    x_lo = 4 if left else -1
    x_hi = W - 5 if right else W
    for x in range(W):
        if x < x_lo or x > x_hi:
            continue
        # скругление концов ряда
        cut = 0
        if left and x < x_lo + 3:
            cut = (x_lo + 3) - x
        if right and x > x_hi - 3:
            cut = max(cut, x - (x_hi - 3))
        top = 11 + int(round(1.1 * math.sin(2 * math.tau * x / W + ph))) + cut
        bot = 24 + int(round(1.1 * math.sin(2 * math.tau * x / W + ph + 2.0))) - cut
        for y in range(top, bot + 1):
            t = (y - top) / max(1, bot - top)
            c = mid
            if y == top:
                c = lo
            elif y == bot:
                c = lo
            elif y == top + 1:
                c = hi
            elif (y - top) % 5 == 3:
                c = base       # борозда
            elif (y - top) % 5 == 1:
                c = hi if rg.random() < 0.5 else mid   # гребень
            if rg.random() < 0.10:
                c = hi if rg.random() < 0.5 else lo      # комочки
            if wet and rg.random() < 0.04:
                c = hx("7f95a3")                         # блеск воды
            im[y, x] = c
    # рваные края ряда: на концах солома не ровная
    for y in range(H):
        if left and rg.random() < 0.5:
            im[y, 0] = (0, 0, 0, 0)
        if left and rg.random() < 0.25:
            im[y, 1] = (0, 0, 0, 0)
        if right and rg.random() < 0.5:
            im[y, W - 1] = (0, 0, 0, 0)
        if right and rg.random() < 0.25:
            im[y, W - 2] = (0, 0, 0, 0)
    return Image.fromarray(im, "RGBA")


def main():
    for kind in ("till", "wet"):
        for v in ("s", "l", "m", "r"):
            seed = 31 + (0 if kind == "till" else 7)
            img = make(kind, v, seed)
            img.save(os.path.join(ART, "by29_soil_%s_%s.png" % (kind, v)))
            print("art/by29_soil_%s_%s.png" % (kind, v))
    # старые имена (значок в бестиарии и справочнике) — теперь новая грядка
    make("till", "s", 31).save(os.path.join(ART, "by29_soil_till.png"))
    make("wet", "s", 38).save(os.path.join(ART, "by29_soil_wet.png"))


main()
