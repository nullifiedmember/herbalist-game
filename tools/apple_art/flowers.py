# -*- coding: utf-8 -*-
"""Луговые цветы мира (flowers_pink/white/blue/yellow, 32x28) — нарисованы заново в стиле яблока.
Запуск: python flowers.py [--game]  ->  art_apple/flowers/ (+ flowers_compare_x6.png); с --game кладёт в game/art
(старые копии — herbalist_game/backup_flowers_trunks_20261115)."""
import os, sys, random, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import Canvas, ell, tube, stroke, ramp, up
from PIL import Image

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple", "flowers"))
BACK = os.path.abspath(os.path.join(GAME, "..", "backup_flowers_trunks_20261115"))

LEAF = "#6fae55"; LEAF_D = "#57964d"; STEM = "#5d9a47"
KINDS = {
    #        лепестки    серединка   форма
    "pink": ("#f29ab8", "#f7d36a", "round"),
    "white": ("#f6f1e6", "#f2c443", "daisy"),
    "blue": ("#7d9cf0", "#f4e7a0", "bell"),
    "yellow": ("#f6cf4f", "#e58a3a", "round"),
}
# головки цветков (x, y) — у каждого вида своя россыпь
HEADS = [(6, 7), (13, 3), (20, 6), (26, 10), (10, 11), (17, 10)]


PAT = {
    "round": [".L.L.", "LLPPP", ".PCP.", "PPPSS", ".S.S."],
    "daisy": [".L.L.", "LLPPP", ".PCP.", "PPPSS", ".S.S."],
    "bell": ["L.L.P", ".LPP.", "LPCPS", ".PPS.", "P.S.S"],
}


def flower(c, x, y, pet, mid, form):
    tones, _ = ramp(pet)
    pat = PAT[form]
    m = {(x - 2 + i, y - 2 + j) for j, row in enumerate(pat) for i, ch in enumerate(row) if ch != "."}
    c.add(m, pet, "flat", inner=False)
    col = {"L": tones[1], "P": tones[2], "S": tones[3], "C": mid}
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch in col:
                c.mark(x - 2 + i, y - 2 + j, col[ch])
    if form == "daisy":
        c.mark(x, y, mid)


def draw(kind):
    pet, mid, form = KINDS[kind]
    c = Canvas(32, 28)
    r = random.Random(kind)
    # листья у земли (сзади)
    for (bx, tx, ty, col, w) in ((15, 3, 21, LEAF_D, 1.7), (17, 29, 20, LEAF_D, 1.7), (14, 7, 17, LEAF, 1.5),
                                 (18, 25, 17, LEAF, 1.5), (16, 12, 19, LEAF, 1.3), (16, 21, 19, LEAF, 1.3)):
        c.add(tube([(bx, 26), ((bx + tx) / 2, (26 + ty) / 2 + 1), (tx, ty)], w, profile="leaf"), col)
    heads = HEADS[:]
    r.shuffle(heads)
    heads = sorted(heads[:5], key=lambda p: p[1])
    for (hx_, hy) in heads:
        base = (13 + r.randint(0, 5), 25)
        c.add(stroke([base, ((base[0] + hx_) / 2, (hy + 25) / 2 + 2), (hx_, hy + 2)]), STEM, "flat")
        if hy < 8:   # листик на высоком стебле
            lx = hx_ + (2 if hx_ < 16 else -2)
            c.add(tube([(hx_ + (hx_ < 16 and 0 or 0), hy + 9), (lx + (1 if hx_ < 16 else -1), hy + 7)], 1.0, profile="leaf"), LEAF)
    for (x, y) in heads:
        flower(c, x, y, pet, mid, form)
    # бутоны
    for (x, y) in ((3, 14), (29, 15)):
        c.add(stroke([(16, 25), (x + (3 if x < 16 else -3), (y + 25) / 2), (x, y + 2)]), STEM, "flat")
        c.add(ell(x + 0.5, y + 0.5, 1.1, 1.6), pet, "cel")
    # травинки спереди у самой земли — будто цветок вырос из луга
    for x in (7, 12, 19, 24):
        c.add(stroke([(x, 27), (x - 1, 23)]), LEAF, "flat", outline=False)
        c.add(stroke([(x + 1, 27), (x + 2, 24)]), LEAF_D, "flat", outline=False)
    return c.render()


def main():
    os.makedirs(OUT, exist_ok=True)
    art = os.path.join(GAME, "art")
    sheet = Image.new("RGBA", (4 * 2 * 36 * 6, 32 * 6), (120, 160, 92, 255))
    for i, k in enumerate(KINDS):
        fn = "flowers_%s.png" % k
        img = draw(k)
        img.save(os.path.join(OUT, fn))
        old = os.path.join(BACK, fn) if os.path.exists(os.path.join(BACK, fn)) else os.path.join(art, fn)
        sheet.alpha_composite(up(Image.open(old).convert("RGBA"), 6), (i * 72 * 6, 2 * 6))
        sheet.alpha_composite(up(img, 6), (i * 72 * 6 + 36 * 6, 2 * 6))
        if "--game" in sys.argv:
            os.makedirs(BACK, exist_ok=True)
            if not os.path.exists(os.path.join(BACK, fn)):
                shutil.copy(os.path.join(art, fn), os.path.join(BACK, fn))
            img.save(os.path.join(art, fn))
    sheet.save(os.path.join(OUT, "..", "flowers_compare_x6.png"))
    print("цветы готовы ->", OUT)


if __name__ == "__main__":
    main()
