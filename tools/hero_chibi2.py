# Героиня-травница, чиби v2 — по референсу (большая широкая голова, широкие глаза-полоски,
# тонкие пряди-линии, тёмный контур 1px, пелеринка, пышная юбка с кружевом, короткие ножки).
# Запуск: python -I hero_chibi2.py  -> herbalist_game/art_apple/hero_chibi/hero_chibi2*.png
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art_apple", "hero_chibi")
W, H = 41, 50
C = 20            # ось симметрии: x и 40-x
OY = 3            # сдвиг вниз (место под пучок)

P = {
    "O": "#3a2230",   # контур (почти чёрный, с оттенком сливы)
    "h": "#e6c592", "H": "#fff3d6", "d": "#cfa36e", "D": "#a7744e",  # волосы
    "s": "#fdeee4", "S": "#f4d4c6", "p": "#f59aa4", "q": "#f9c0c0", "m": "#d8646a",  # кожа, румянец, рот
    "w": "#fdfaf6", "W": "#e2dade", "g": "#c4b6c0",                 # белая ткань
    "t": "#5fc6b6", "T": "#2f8d88", "y": "#b4ecdc", "U": "#226a6c",  # бирюза
    "b": "#7c4a36", "k": "#f2cc64",                                 # пояс, пряжка
    "e": "#2c1828", "1": "#5e2838", "2": "#9a4a56", "3": "#cf7a72", "4": "#f6bc98", "x": "#ffffff",  # глаза
    "B": "#94603e", "n": "#5e3a2c", "M": "#c08a5e",                 # ботинки
    "L": "#6fb64e", "l": "#a6dc72",                                 # листик-заколка
}

g = {}       # (x,y) -> символ палитры
reg = {}     # (x,y) -> имя области (для контура)


def put(x, y, ch, r=None):
    y += OY
    if 0 <= x < W and 0 <= y < H:
        g[(x, y)] = ch
        if r:
            reg[(x, y)] = r


def span(y, x0, x1, ch, r):
    for x in range(x0, x1 + 1):
        put(x, y, ch, r)


def sym(y, x0, ch, r, x1=None):
    """Ряд от x0 до зеркального 40-x0 (или до x1 и зеркально)."""
    if x1 is None:
        span(y, x0, 2 * C - x0, ch, r)
    else:
        span(y, x0, x1, ch, r); span(y, 2 * C - x1, 2 * C - x0, ch, r)


def mput(x, y, ch, r=None):
    put(x, y, ch, r); put(2 * C - x, y, ch, r)


# ---------------- волосы сзади (длинные, расходятся колоколом) ----------------
back = {14: 5, 15: 5, 16: 5, 17: 5, 18: 5, 19: 5, 20: 6, 21: 6, 22: 7, 23: 8, 24: 8, 25: 8, 26: 8,
        27: 7, 28: 7, 29: 6, 30: 6, 31: 5, 32: 5, 33: 5}
for y, x0 in back.items():
    sym(y, x0, "h", "hairB")
# волнистые концы
for y, x0, x1 in ((31, 4, 4), (32, 3, 4), (33, 2, 4), (34, 2, 3), (34, 6, 9), (35, 7, 8), (32, 1, 1)):
    sym(y, x0, "h", "hairB", x1)

# ---------------- ножки и ботинки ----------------
for y in range(37, 41):
    span(y, 16, 18, "s", "leg"); span(y, 22, 24, "s", "leg")
for y in (38, 39, 40):
    ch = "t" if y == 39 else "w"
    span(y, 16, 18, ch, "leg"); span(y, 22, 24, ch, "leg")      # носочки с полоской
for y in range(41, 44):
    span(y, 15, 19, "B", "boot"); span(y, 21, 25, "B", "boot")
span(41, 15, 19, "M", "boot"); span(41, 21, 25, "M", "boot")         # отворот
span(43, 15, 19, "n", "boot"); span(43, 21, 25, "n", "boot")         # подошва

# ---------------- юбка ----------------
skirt = {31: 14, 32: 12, 33: 11, 34: 10, 35: 10}
for y, x0 in skirt.items():
    sym(y, x0, "w", "skirt")
sym(36, 10, "y", "lace")
for x in range(10, 31, 2):
    put(x, 36, "t", "lace")
sym(35, 10, "w", "skirt")
for x in range(11, 30, 2):
    put(x, 35, "W", "skirt")
# складки юбки
for x in (14, 17, 23, 26):
    for y in (33, 34, 35):
        put(x, y, "W", "skirt")
for y in (32, 33, 34, 35):
    put(2 * C - skirt.get(y, 11), y, "W", "skirt")

# ---------------- блузка, рукава, кисти ----------------
for y in range(27, 31):
    sym(y, 15, "w", "blouse")
for y, x0, x1 in ((28, 11, 13), (29, 10, 13), (30, 9, 13), (31, 8, 12), (32, 8, 11)):
    sym(y, x0, "w", "sleeve", x1)
for (x, y) in ((10, 33), (11, 33), (11, 32)):
    mput(x, y, "s", "hand")
for (x, y) in ((8, 32), (9, 32), (8, 31)):
    mput(x, y, "t", "sleeve")
# пояс
sym(30, 15, "b", "belt")
put(20, 30, "k", "belt")

# ---------------- пелеринка ----------------
cape = {25: (14, 17), 26: (13, 17), 27: (12, 17), 28: (11, 17), 29: (11, 16)}
for y, (x0, x1) in cape.items():
    sym(y, x0, "t", "cape", x1)
for x in (11, 13, 15):
    mput(x, 30, "t", "cape")            # фестончатый край
# бантик на вороте
for (x, y, ch) in ((18, 25, "t"), (19, 25, "y"), (20, 25, "T"), (21, 25, "y"), (22, 25, "t"),
                   (18, 26, "T"), (19, 26, "t"), (20, 26, "U"), (21, 26, "t"), (22, 26, "T"),
                   (19, 27, "t"), (21, 27, "t")):
    put(x, y, ch, "bow")

# ---------------- голова: масса волос ----------------
head = {1: 14, 2: 11, 3: 9, 4: 8, 5: 7, 6: 7, 7: 6, 8: 6, 9: 6, 10: 5, 11: 5, 12: 5, 13: 5}
for y, x0 in head.items():
    sym(y, x0, "h", "hair")
# пучок на макушке
for y, x0 in ((-2, 18), (-1, 17), (0, 17)):
    sym(y, x0, "d", "bun")

# ---------------- лицо ----------------
for y in range(12, 24):
    sym(y, 12, "s", "face")
sym(24, 13, "s", "face")

# ---------------- чёлка (поверх лица), низ «зубчиками» ----------------
bang_bottom = {11: 23, 12: 22, 13: 14, 14: 14, 15: 13, 16: 14, 17: 14, 18: 16, 19: 15, 20: 14,
               21: 15, 22: 16, 23: 14, 24: 14, 25: 13, 26: 14, 27: 14, 28: 22, 29: 23}
for x, yb in bang_bottom.items():
    for y in range(12, yb + 1):
        put(x, y, "h", "hair")
# передние пряди вдоль лица до груди
for y in range(14, 28):
    w0 = 9 if y < 25 else 10
    w1 = 12 if y < 24 else 11
    span(y, w0, w1, "h", "lock"); span(y, 2 * C - w1, 2 * C - w0, "h", "lock")
for x, y in ((10, 28), (11, 28)):
    mput(x, y, "h", "lock")

# ---------------- тени и пряди на волосах ----------------
hair_regs = ("hair", "hairB", "lock", "bun")


def shade_hair():
    for (x, y), r in list(reg.items()):
        if r not in hair_regs:
            continue
        right = reg.get((x + 1, y)) in hair_regs
        down = reg.get((x, y + 1)) in hair_regs
        up = reg.get((x, y - 1)) in hair_regs
        left = reg.get((x - 1, y)) in hair_regs
        if r == "hairB":
            g[(x, y)] = "d"            # задние волосы на тон темнее
        if r == "bun":
            g[(x, y)] = "h"
        if not right or not down:
            g[(x, y)] = "D" if r == "hairB" else "d"
        elif (not up or not left) and r != "hairB":
            g[(x, y)] = "H"


shade_hair()
# блик-дуга на макушке
for x in (12, 13, 14, 16, 17, 25, 26):
    put(x, 4, "H")
for x in (11, 15, 24):
    put(x, 5, "H")
# пряди-линии: чёлка зачёсана набок (кривые 1px, темнее), как в референсе
def line(pts, ch="D"):
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        n = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(n + 1):
            x = round(x0 + (x1 - x0) * i / n); y = round(y0 + (y1 - y0) * i / n)
            if reg.get((x, y + OY)) in ("hair", "lock"):
                put(x, y, ch)


line([(23, 4), (20, 8), (17, 12), (16, 14)])
line([(27, 6), (24, 10), (22, 14), (22, 16)])
line([(18, 5), (15, 9), (13, 13)])
line([(29, 8), (27, 12), (27, 14)])
line([(13, 7), (11, 11), (10, 15)])
line([(31, 10), (30, 13)])
line([(21, 9), (20, 12), (19, 15)], "d")
for x in (12, 13, 14, 16, 17, 25, 26):
    put(x, 4, "H")
for (x, y) in ((9, 13), (9, 14), (9, 15), (9, 16), (10, 17), (10, 18), (31, 13), (31, 14), (31, 15), (31, 16),
               (30, 17), (30, 18), (7, 18), (7, 19), (7, 20), (7, 21), (33, 18), (33, 19), (33, 20), (33, 21),
               (7, 28), (7, 29), (7, 30), (33, 28), (33, 29), (33, 30)):
    put(x, y, "D")
# тень под чёлкой на лбу/лице
for x in range(13, 28):
    yb = bang_bottom.get(x)
    if yb is not None and yb < 20 and g.get((x, yb + 1 + OY)) == "s":
        put(x, yb + 1, "S")

# ---------------- глаза: широкие, полосами ----------------
EYE = ["eeeee", "1x111", "12221", "22222", "33333", "44444"]
for ex, outer in ((13, 12), (23, 28)):
    for dy, row in enumerate(EYE):
        for dx, ch in enumerate(row):
            put(ex + dx, 15 + dy, ch, "eye")
    put(outer, 15, "e"); put(outer, 14, "e")        # хвостик ресниц наружу-вверх
    put(ex + 3, 18, "4")                                                # малый блик-отсвет
# румянец полоской прямо под глазами
for x in (13, 14, 15, 16, 24, 25, 26, 27):
    put(x, 21, "q")
for x in (14, 15, 25, 26):
    put(x, 21, "p")
for x in (14, 15, 25, 26):
    pass
put(20, 20, "S")                  # нос-точка
put(20, 22, "m")                  # ротик

# ---------------- листик-заколка в волосах слева и бирюзовая ленточка на пучке ----------------
for (x, y, ch) in ((8, 7, "w"), (9, 6, "w"), (10, 7, "w"), (9, 8, "w"), (9, 7, "k"), (8, 9, "L"), (10, 9, "l"),
                   (7, 8, "W"), (11, 8, "L")):
    put(x, y, ch, "clip")
for (x, y, ch) in ((16, 1, "t"), (17, 0, "y"), (17, 1, "T"), (18, 1, "t"), (19, 1, "U"), (20, 1, "t"),
                   (21, 1, "t"), (22, 1, "U"), (23, 1, "t"), (24, 1, "T"), (24, 0, "y"), (25, 1, "t"),
                   (19, 2, "t"), (22, 2, "t")):
    put(x, y, ch, "bow")
# хохолок
for (x, y) in ((22, -3), (23, -4), (24, -4), (25, -3)):
    put(x, y, "h", "bun")

# ---------------- тени одежды (свет сверху-слева) ----------------
SH = {"w": "W", "t": "T", "B": "n", "s": "S", "y": "t"}
LI = {"t": "y", "B": "M"}
for (x, y), r in list(reg.items()):
    if r in ("blouse", "sleeve", "skirt", "cape", "boot", "leg", "hand"):
        ch = g[(x, y)]
        if reg.get((x + 1, y)) != r or reg.get((x, y + 1)) != r:
            g[(x, y)] = SH.get(ch, ch)
        elif (reg.get((x - 1, y)) != r or reg.get((x, y - 1)) != r) and ch in LI:
            g[(x, y)] = LI[ch]

# ---------------- контур: снаружи и между частями одежды ----------------
INNER = {("skirt", "leg"), ("cape", "blouse"), ("cape", "sleeve"),
         ("sleeve", "blouse"), ("belt", "skirt"), ("skirt", "hairB"), ("cape", "hairB"), ("sleeve", "hairB"),
         ("face", "hair"), ("lock", "cape"), ("lock", "blouse"), ("hand", "hairB"), ("lock", "face")}


def outline():
    out = {}
    for y in range(H):
        for x in range(W):
            if (x, y) in g:
                continue
            if any((x + dx, y + dy) in g for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                out[(x, y)] = "O"
    g.update(out)


outline()


def inner():
    out = []
    for (x, y), r in reg.items():
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            r2 = reg.get((x + dx, y + dy))
            if r2 and (r, r2) in INNER and g.get((x, y)) != "O":
                out.append((x, y)); break
    for q in out:
        g[q] = "O"


inner()


def render(blink=False, sx=1):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (x, y), ch in g.items():
        im.putpixel((x, y), tuple(int(P[ch][i:i + 2], 16) for i in (1, 3, 5)) + (255,))
    if blink:
        for ex in (13, 23):
            for dy in range(5):
                for dx in range(5):
                    im.putpixel((ex + dx, 15 + dy + OY), (253, 238, 228, 255))
            for dx in range(5):
                im.putpixel((ex + dx, 18 + OY), (44, 24, 40, 255))
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    a = render()
    a.save(os.path.join(OUT, "hero_chibi2.png"))
    a.resize((W * 8, H * 8), Image.NEAREST).save(os.path.join(OUT, "hero_chibi2_x8.png"))
    render(True).save(os.path.join(OUT, "hero_chibi2_blink.png"))
    print("ok", os.path.abspath(OUT))
