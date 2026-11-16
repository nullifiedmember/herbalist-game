# Героиня-травница, чиби v4 (стройнее) — крупнее (x2 к v2: 82x100) и обводка как в референсе:
# тёмная линия 1px только по внешнему силуэту, внутри — цветные линии (тёмный тон своего цвета).
# Формы заданы геометрией в «старых» единицах (1 ед. = пиксель v2), растр x K.
# Запуск: python -I hero_chibi4.py -> herbalist_game/art_apple/hero_chibi/hero_chibi4*.png
import os
from PIL import Image

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "art_apple", "hero_chibi")
K = 2
OY = 5                       # запас сверху в старых единицах (хохолок, пучок)
W, H = 41 * K, (47 + OY) * K
CX = 20.5                    # ось симметрии (старые ед.)


def hx(c):
    return tuple(int(c[i:i + 2], 16) for i in (1, 3, 5))


OUTLINE = hx("#2e1a28")
# область: base, light, shade, deep(цветная внутренняя линия)
PAL = {
    "hair":  ("#e8c794", "#fbe8c4", "#d2a674", "#a8704e"),
    "hairB": ("#d6ad7a", "#e8c794", "#bf8f62", "#93603f"),
    "skin":  ("#fdeee4", "#fff8f2", "#f4d2c4", "#dca092"),
    "white": ("#fdfaf6", "#ffffff", "#e4dade", "#b8a8b4"),
    "teal":  ("#5cc4b4", "#a8ecdc", "#3a9a92", "#23706e"),
    "belt":  ("#7c4a36", "#a06a4c", "#5e3528", "#46261e"),
    "boot":  ("#94603e", "#c08a5e", "#704428", "#52301e"),
    "bun":   ("#ddb684", "#f2d8aa", "#c6976a", "#a06a48"),
    "pouch": ("#b48a56", "#d6ae78", "#8e6a40", "#6a4a2c"),
}
EXTRA = {"D": "#a8704e", "H": "#fff4da", "p": "#f498a4", "q": "#fac4c4", "m": "#d05c66",
         "e": "#2c1426", "0": "#4e2034", "1": "#74304a", "2": "#a24c5a", "3": "#d27a72", "4": "#f6bc98",
         "x": "#ffffff", "k": "#f2cc64", "K": "#c89a40", "L": "#6fb64e", "l": "#a6dc72", "G": "#3f8a3a",
         "f": "#ffffff", "F": "#e8e0d8"}

reg = {}     # (X,Y) -> имя области
col = {}     # (X,Y) -> rgb
grp = {}     # (X,Y) -> палитра области
order = []   # z-порядок имён областей


# ---------------- геометрия ----------------
def mir(pts):
    return [(2 * CX - x, y) for x, y in pts]


def poly_in(pts, u, v):
    inside = False
    j = len(pts) - 1
    for i in range(len(pts)):
        xi, yi = pts[i]; xj, yj = pts[j]
        if (yi > v) != (yj > v) and u < (xj - xi) * (v - yi) / (yj - yi + 1e-9) + xi:
            inside = not inside
        j = i
    return inside


def P(pts):
    return lambda u, v: poly_in(pts, u, v)


def N(pts, f):
    """Сузить фигуру к оси симметрии."""
    return [(CX + (x - CX) * f, y) for x, y in pts]


def Psym(left):
    """Левая половина контура (сверху вниз по оси) + зеркало."""
    pts = left + mir(left[::-1])
    return P(pts)


def E(cx, cy, rx, ry, p=2.0):
    return lambda u, v: abs((u - cx) / rx) ** p + abs((v - cy) / ry) ** p <= 1


def R(x0, y0, x1, y1):
    return lambda u, v: x0 <= u < x1 and y0 <= v < y1


def U(*fs):
    return lambda u, v: any(f(u, v) for f in fs)


def fill(name, f, pal):
    order.append(name)
    for Y in range(H):
        for X in range(W):
            u = (X + 0.5) / K
            v = (Y + 0.5) / K - OY
            if f(u, v):
                reg[(X, Y)] = name
                grp[(X, Y)] = pal
                col[(X, Y)] = hx(PAL[pal][0])


def pix(u, v):
    """Старые координаты -> пиксель."""
    return int(u * K), int((v + OY) * K)


def put(X, Y, c, name=None):
    if 0 <= X < W and 0 <= Y < H:
        col[(X, Y)] = hx(EXTRA.get(c, c)) if isinstance(c, str) else c
        if name:
            reg[(X, Y)] = name


def line(pts, c, only=None, w=1):
    for (u0, v0), (u1, v1) in zip(pts, pts[1:]):
        X0, Y0 = pix(u0, v0); X1, Y1 = pix(u1, v1)
        n = max(abs(X1 - X0), abs(Y1 - Y0), 1)
        for i in range(n + 1):
            X = round(X0 + (X1 - X0) * i / n); Y = round(Y0 + (Y1 - Y0) * i / n)
            for dx in range(w):
                if only is None or reg.get((X + dx, Y)) in only:
                    put(X + dx, Y, c)


# ---------------- фигуры, сзади вперёд ----------------
fill("hairB", Psym(N([(20.5, 12), (5, 14), (4.8, 20), (6.4, 23), (7.8, 25.5), (7.4, 28), (6, 30.4), (3.6, 31.8),
                    (1.0, 32.4), (2.0, 34.0), (4.4, 34.4), (5.6, 35.9), (7.6, 34.9), (9.2, 36.3), (10.6, 34.8),
                    (14, 34.2), (20.5, 34.2)], 0.86)), "hairB")
fill("legL", R(17.3, 36, 19.3, 43), "skin"); fill("legR", R(21.7, 36, 23.7, 43), "skin")
fill("bootL", U(R(16.6, 43, 20.0, 45.6), E(18.3, 45.4, 1.7, 0.6)), "boot")
fill("bootR", U(R(21.0, 43, 24.4, 45.6), E(22.7, 45.4, 1.7, 0.6)), "boot")
fill("skirt", Psym(N([(20.5, 30.6), (15, 30.6), (12.2, 32.4), (10.4, 34.4), (9.8, 35.8), (20.5, 35.8)], 0.74)), "white")
fill("lace", Psym(N([(20.5, 35.6), (9.8, 35.6), (9.6, 36.6), (10.4, 37.2), (20.5, 37.2)], 0.74)), "white")
SLV = N([(14, 27.6), (12.0, 28), (10.6, 29.8), (9.4, 32.6), (10.2, 33.4), (12.0, 33.2), (13.4, 31.4)], 0.84)
fill("sleeveL", P(SLV), "white")
fill("sleeveR", P(mir(SLV)), "white")
fill("handL", E(12.3, 33.9, 0.95, 0.9), "skin"); fill("handR", E(28.7, 33.9, 0.95, 0.9), "skin")
fill("blouse", R(16.6, 26.4, 24.4, 30.6), "white")
fill("belt", R(16.6, 29.9, 24.4, 31.0), "belt")
fill("pouch", E(25.2, 32.3, 1.4, 1.6), "pouch")
CAPE = [(18.4, 25.2), (14.2, 25.0), (12.4, 26.4), (11.0, 28.2), (10.6, 30.0), (11.6, 30.9), (12.6, 30.3),
        (13.6, 31.0), (14.6, 30.4), (15.6, 30.8), (16.6, 29.6), (17.6, 27.6), (18.6, 26.4)]
CAPE = N(CAPE, 0.78)
fill("capeL", P(CAPE), "teal"); fill("capeR", P(mir(CAPE)), "teal")
fill("bun", E(20.5, 0.0, 3.0, 2.3, 2.0), "bun")
fill("hair", E(20.5, 13.7, 14.4, 12.8, 2.4), "hair")
fill("face", Psym(N([(20.5, 11.4), (12, 11.4), (12, 22.4), (12.5, 23.8), (13.6, 24.7), (15.6, 25.2), (20.5, 25.3)], 0.93)), "skin")
BANG = [(12.3, 15.4), (13.8, 14.7), (15.3, 15.8), (16.4, 14.8), (18.1, 17.6), (19.1, 15.6), (20.4, 14.9),
        (21.7, 16.6), (22.5, 15.1), (23.6, 14.7), (25.1, 15.8), (26.4, 14.6), (28.7, 15.4)]
BANG = N(BANG, 0.93)
fill("bang", P([(10, 7), (31, 7), (31, 15.6)] + BANG[::-1] + [(10, 15.6)]), "hair")
LOCK = [(9.0, 11.5), (12.9, 11.5), (13.2, 16.5), (12.9, 21), (12.4, 24.2), (11.9, 27), (11.3, 29.4),
        (10.5, 29.9), (10.0, 28.4), (9.4, 26.4), (8.9, 23.5), (8.6, 18)]
LOCK = N(LOCK, 0.9)
fill("lockL", P(LOCK), "hair"); fill("lockR", P(mir(LOCK)), "hair")
fill("bow", U(P([(20.5, 26.3), (18.0, 25.0), (17.7, 27.7)]), P([(20.5, 26.3), (23.0, 25.0), (23.3, 27.7)]),
              E(20.5, 26.4, 0.9, 0.8), P([(20.2, 26.6), (19.0, 28.6), (19.8, 28.8), (20.5, 27.2)]),
              P([(20.8, 26.6), (22.0, 28.6), (21.2, 28.8), (20.5, 27.2)])), "teal")
fill("ahoge", lambda u, v: False, "hair")

HAIRS = ("hair", "bang", "lockL", "lockR", "hairB", "bun")
FACE_ = ("face",)

# ---------------- тени: свет сверху-слева, плоские ступени ----------------
def same(a, b):
    ga = "H" if a in HAIRS else a
    gb = "H" if b in HAIRS else b
    return ga == gb


base_col = dict(col)
for (X, Y), r in list(reg.items()):
    pal = PAL[grp[(X, Y)]]
    n = lambda dx, dy: reg.get((X + dx, Y + dy))
    rb = [n(1, 0), n(0, 1), n(2, 0), n(0, 2), n(1, 1)]
    lt = [n(-1, 0), n(0, -1)]
    if any(q is None or not same(q, r) for q in rb[:2]):
        col[(X, Y)] = hx(pal[2])
    elif any(q is None or not same(q, r) for q in rb[2:]) and r not in FACE_:
        col[(X, Y)] = hx(pal[2])
    elif any(q is None or not same(q, r) for q in lt):
        col[(X, Y)] = hx(pal[1])

# внутренние цветные линии: край передней области на фоне задней = её тёмный тон
z = {name: i for i, name in enumerate(order)}
# низ волос по бокам на тон темнее (объём, как в референсе)
for (X, Y), r in list(reg.items()):
    v = (Y + 0.5) / K - OY
    if r in ("hair", "lockL", "lockR") and v > 19.5 and col[(X, Y)] == hx(PAL["hair"][0]):
        col[(X, Y)] = hx(PAL["hair"][2]) if v > 23 or (X + Y) % 2 == 0 and v > 21.5 else col[(X, Y)]
for (X, Y), r in list(reg.items()):
    for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
        q = reg.get((X + dx, Y + dy))
        if q and z[q] < z[r] and not same(q, r):
            if r in ("bang", "lockL", "lockR") and q == "face":
                col[(X, Y)] = hx(PAL["hair"][3])
            else:
                col[(X, Y)] = hx(PAL[grp[(X, Y)]][3])
            break

# ---------------- волосы: пряди, блики ----------------
HR = ("hair", "bang", "lockL", "lockR")
for pts in ([(23, 4), (20.5, 7.5), (18.3, 11), (17.4, 14)], [(26.5, 5.5), (24.3, 9.5), (22.6, 13.5), (22.2, 15.5)],
            [(18, 4.6), (15.6, 8), (14, 12), (13.6, 14.4)], [(29.5, 7.6), (27.8, 11), (27.2, 14.2)],
            [(13, 6.5), (11.2, 10.4), (10.4, 15), (10.2, 20), (10.6, 26)],
            [(31.6, 9.6), (30.6, 14), (30.4, 20), (30.2, 26)], [(21.2, 8.6), (20.4, 11.6), (19.6, 14.6)],
            [(8.6, 11), (7.4, 16)], [(33.2, 11), (34, 16)], [(25.4, 10.4), (25.2, 14.2)]):
    line(pts, "D", HR)
for pts in ([(22.4, 4.4), (20, 7.8)], [(26, 6), (24, 9.4)], [(17.4, 5), (15.2, 8.2)], [(12.4, 7), (11, 10)],
            [(9.6, 17), (9.6, 24)], [(31.2, 16), (31.4, 23)]):
    line([(a + 0.5, b) for a, b in pts], "H", HR)
# блик-кольцо на макушке (чёрточки)
for (a, b, c2) in ((12.0, 4.6, 13.6), (14.6, 3.6, 16.6), (17.6, 3.0, 19.2), (24.6, 3.4, 26.6), (27.8, 4.4, 29.2)):
    line([(a, b), (c2, b - 0.4)], "H", HR + ("bun",))
# задние волосы: пряди и тёмные концы
for pts in ([(6.4, 24), (6, 30)], [(34.6, 24), (35, 30)], [(4, 32.4), (6.6, 35)], [(37, 32.4), (34.4, 35)],
            [(8.6, 33), (9.4, 35.6)], [(32.4, 33), (31.6, 35.6)]):
    line(pts, hx(PAL["hairB"][3]), ("hairB",))
# хохолок
line([(21.4, -2.6), (22.2, -3.6), (23.4, -4.4), (24.8, -4.2), (25.6, -3.4)], hx(PAL["hair"][0]), None, 1)
for pts in [[(21.4, -2.6), (22.2, -3.6), (23.4, -4.4), (24.8, -4.2), (25.6, -3.4)]]:
    for (u, v) in pts:
        X, Y = pix(u, v); reg[(X, Y)] = "ahoge"; grp[(X, Y)] = "hair"
for (X, Y), c in list(col.items()):
    pass
# пучок: перевязка-ленточка
for i, X in enumerate(range(pix(16.6, 0)[0], pix(24.6, 0)[0])):
    Y = pix(0, 1.2)[1]
    put(X, Y, "#5cc4b4" if i % 3 else "#a8ecdc"); put(X, Y + 1, "#3a9a92")
for (u, v) in ((16.2, 0.4), (15.8, 1.0), (24.8, 0.4), (25.2, 1.0)):
    X, Y = pix(u, v); put(X, Y, "#5cc4b4", "bow2"); grp[(X, Y)] = "teal"
# цветок-ромашка в волосах слева
fx, fy = pix(10.6, 8.0)
FL = ["..ff.ff..",
      ".fffffff.",
      "ffffkffff",
      ".ffkkKff.",
      "ffffKffFF",
      ".fffFFFF.",
      "..fF.FF..",
      "LL.....lL",
      ".GL...LG."]
flower = []
for j, row in enumerate(FL):
    for i, ch in enumerate(row):
        if ch != ".":
            flower.append((i - 4, j - 4, ch))
for dx, dy, c in flower:
    put(fx + dx, fy + dy, c, "flower"); grp[(fx + dx, fy + dy)] = "white"

# ---------------- лицо ----------------
# тень от чёлки на лбу
for (X, Y), r in list(reg.items()):
    if r == "face" and reg.get((X, Y - 1)) in ("bang",):
        put(X, Y, hx(PAL["skin"][2]))
EYE = [".eeeeeeee.",
       "eeeeeeeeee",
       "e00000000e",
       "0xx00000x0",
       "0xxx000010",
       "1x11000111",
       "1111001111",
       "2222222222",
       "2222222xx2",
       "3333333x33",
       "3444444443",
       ".44444444."]
for side, ex in ((-1, 13.4), (1, 22.6)):
    X0, Y0 = pix(ex, 15.0)
    for j, row in enumerate(EYE):
        for i, ch in enumerate(row):
            if ch != ".":
                put(X0 + i, Y0 + j, ch, "eye")
    # хвостик ресниц наружу-вверх
    ox = X0 - 1 if side < 0 else X0 + 10
    sx = -1 if side < 0 else 1
    for (a, b) in ((0, 0), (0, 1), (sx, -1), (sx, 0)):
        put(ox + a, Y0 + b, "e")
    # нижнее веко (тонкий тёплый штрих)
    for i in range(2, 8):
        put(X0 + i, Y0 + 12, hx(PAL["skin"][3]) if i in (2, 7) else hx(PAL["skin"][2]))
# румянец штриховкой
for side, ex in ((-1, 13.0), (1, 23.2)):
    X0, Y0 = pix(ex, 21.6)
    for i in range(10):
        put(X0 + i, Y0, "q" if i % 2 else "p")
        if 1 <= i <= 8:
            put(X0 + i, Y0 + 1, "p" if i % 2 else "q")
X, Y = pix(20.3, 20.6); put(X, Y, hx(PAL["skin"][3]))          # нос
X, Y = pix(20.0, 22.8); put(X, Y, "m"); put(X + 1, Y, "m"); put(X, Y + 1, hx(PAL["skin"][3])); put(X + 1, Y + 1, "#e88a8e")

# ---------------- одежда: детали ----------------
# воротничок-рюшь
for i, X in enumerate(range(pix(17.6, 0)[0], pix(23.4, 0)[0])):
    put(X, pix(0, 27.6)[1], "#ffffff" if i % 2 else hx(PAL["white"][2]))
# пуговки
for v in (28.6, 29.4):
    X, Y = pix(20.5, v); put(X, Y, "#3a9a92"); put(X - 1, Y, "#5cc4b4")
# пряжка
X, Y = pix(20.0, 30.0)
for dx in range(3):
    put(X + dx, Y, "k"); put(X + dx, Y + 1, "K")
put(X + 1, Y, "#7c4a36")
# складки юбки
for u in (15.2, 17.8, 20.5, 23.2, 25.8):
    line([(u + (u - 20.5) * 0.02, 32.0), (u + (u - 20.5) * 0.12, 35.4)], hx(PAL["white"][2]), ("skirt",))
# кружево: бирюзовые точки и фестоны
X0, _ = pix(12, 0); X1, _ = pix(29, 0); Y = pix(0, 36.0)[1]
for i, X in enumerate(range(X0, X1)):
    if reg.get((X, Y)) == "lace":
        put(X, Y, "#5cc4b4" if i % 3 == 1 else "#ffffff")
        put(X, Y + 1, "#a8ecdc" if i % 3 != 1 else "#ffffff")
        if i % 3 == 0 and reg.get((X, Y + 2)) == "lace":
            put(X, Y + 2, hx(PAL["white"][2]))
# манжеты бирюзой
for nm in ("sleeveL", "sleeveR"):
    for (X, Y), r in list(reg.items()):
        if r == nm and reg.get((X, Y + 1)) != nm:
            put(X, Y, "#3a9a92"); put(X, Y - 1, "#5cc4b4")
# кант пелеринки
for nm in ("capeL", "capeR"):
    for (X, Y), r in list(reg.items()):
        if r == nm and reg.get((X, Y + 1)) != nm and reg.get((X, Y - 1)) == nm:
            put(X, Y - 1, "#a8ecdc")
# мешочек с травками
X, Y = pix(25.2, 30.6)
for dx, dy, c in ((-1, 0, "L"), (0, -1, "l"), (1, 0, "G"), (0, 0, "L"), (2, -1, "l")):
    put(X + dx, Y + dy, c)
for dx in range(-2, 3):
    put(X + dx, Y + 2, "#6a4a2c")
# носочки с полосками
for nm in ("legL", "legR"):
    for (X, Y), r in list(reg.items()):
        if r == nm:
            v = (Y + 0.5) / K - OY
            if v >= 38.5:
                c = "#5cc4b4" if 39.5 <= v < 40.5 else "#fdfaf6"
                if reg.get((X + 1, Y)) != nm:
                    c = "#3a9a92" if c == "#5cc4b4" else "#e4dade"
                put(X, Y, c)
# ботинки: шнуровка, подошва
for nm, cu in (("bootL", 18.3), ("bootR", 22.7)):
    X, Y = pix(cu, 43.4)
    put(X - 1, Y + 1, "k"); put(X, Y + 2, "k"); put(X - 1, Y + 3, "k")
    for (Xp, Yp), r in list(reg.items()):
        if r == nm and reg.get((Xp, Yp + 1)) != nm:
            put(Xp, Yp, hx(PAL["boot"][3]))

# ---------------- внешний контур: 1px, только снаружи силуэта ----------------
filled = set(col)
outline = set()
for Y in range(H):
    for X in range(W):
        if (X, Y) in filled:
            continue
        if any((X + dx, Y + dy) in filled for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
            outline.add((X, Y))


def render(blink=False):
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    for (X, Y), c in col.items():
        im.putpixel((X, Y), c + (255,))
    for (X, Y) in outline:
        im.putpixel((X, Y), OUTLINE + (255,))
    if blink:
        sk = hx(PAL["skin"][0])
        for side, ex in ((-1, 13.4), (1, 22.6)):
            X0, Y0 = pix(ex, 15.0)
            for j in range(-1, 13):
                for i in range(-2, 12):
                    if im.getpixel((X0 + i, Y0 + j))[:3] != OUTLINE and \
                            reg.get((X0 + i, Y0 + j)) in ("eye", "face"):
                        im.putpixel((X0 + i, Y0 + j), sk + (255,))
            for i in range(10):
                d = 1 if i in (0, 9) else 0
                im.putpixel((X0 + i, Y0 + 8 - d), hx(EXTRA["e"]) + (255,))
                if 2 <= i <= 7:
                    im.putpixel((X0 + i, Y0 + 9), hx(EXTRA["e"]) + (255,))
    return im


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    a = render()
    a.save(os.path.join(OUT, "hero_chibi4.png"))
    a.resize((W * 6, H * 6), Image.NEAREST).save(os.path.join(OUT, "hero_chibi4_x6.png"))
    render(True).save(os.path.join(OUT, "hero_chibi4_blink.png"))
    print("ok", W, H, os.path.abspath(OUT))
