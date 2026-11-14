"""v25: сферы стихий (orb25_<стихия>.png 20x20), алтарь сфер (altar25.png), книга сфер (icon_spellbook25.png),
снаряд-искра (fx_orb25.png). Тем же движком, что звери (fauna25.Canvas).
Запуск из папки game:  python tools/art_v25.py"""
import os, sys, math
import numpy as np
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from fauna25 import Canvas, ramp, stripes, spots  # noqa: E402
ART = os.path.join(HERE, "..", "art")

ELEMENTS = {"water": "4a9ae8", "life": "5ad06a", "shield": "f0c850", "cold": "c8f0ff",
            "lightning": "b070f0", "arcane": "f05ab0", "earth": "a07a4a", "fire": "f07a2a"}


def orb(el, col):
    cv = Canvas(20, 20)
    r = ramp(col, spread=1.2)
    pat = None
    if el == "earth":
        pat = spots(3, 6, 0.8, 1.4, ramp("6a4a2a"), (3, 3, 17, 17))
    elif el == "water":
        pat = stripes(1.3, 0.12, axis="y", thr=0.6)
    elif el == "fire":
        pat = stripes(1.1, 0.0, axis="x", thr=0.7, rmp=ramp("f8d040"))
    elif el == "lightning":
        pat = stripes(2.0, 0.0, axis="x", thr=0.85, rmp=ramp("f8f0ff"))
    elif el == "life":
        pat = spots(5, 4, 0.8, 1.2, ramp("c8f8a0"), (4, 4, 16, 16))
    cv.ell(10, 10, 8, 8, r, pat=pat)
    im = cv.render(noise_seed=2)
    im[5:7, 6:8, :3] = 255
    return Image.fromarray(im, "RGBA")


def altar():
    cv = Canvas(48, 64)
    st = ramp("8a8698")
    cv.ell(24, 60, 18, 4, st)
    cv.limb((24, 58), (24, 34), 7, 6, st, pat=stripes(1.6, 0.12, axis="y", thr=0.7))
    cv.ell(24, 33, 12, 4, st)
    cv.ell(24, 31, 9, 2.6, ramp("a8a4b8"), sep=False)
    for dx in (-12, 12):
        cv.poly([(24 + dx - 2, 58), (24 + dx + 2, 58), (24 + dx, 44)], ramp("6a6680"), (0, -0.5, 1))
    return Image.fromarray(cv.render(noise_seed=4), "RGBA")


def book():
    cv = Canvas(24, 24)
    cv.poly([(3, 6), (20, 4), (21, 19), (4, 21)], ramp("5a3a8a"), (0, -0.2, 1))
    cv.poly([(5, 7), (19, 5), (20, 17), (6, 19)], ramp("6e4aa8"), (0, -0.4, 1), sep=False)
    for i, c in enumerate(["4a9ae8", "5ad06a", "f07a2a", "f0c850"]):
        x = 8 + (i % 2) * 6
        y = 8 + (i // 2) * 6
        cv.ell(x, y, 2.2, 2.2, ramp(c), sep=True)
    return Image.fromarray(cv.render(noise_seed=5), "RGBA")


def spark():
    im = np.zeros((12, 12, 4), np.uint8)
    for y in range(12):
        for x in range(12):
            d = math.hypot(x - 5.5, y - 5.5)
            a = max(0.0, 1.0 - d / 6.0)
            im[y, x] = (255, 255, 255, int(255 * a ** 1.4))
    return Image.fromarray(im, "RGBA")


if __name__ == "__main__":
    for el, c in ELEMENTS.items():
        orb(el, c).save(os.path.join(ART, "orb25_%s.png" % el))
    altar().save(os.path.join(ART, "altar25.png"))
    book().save(os.path.join(ART, "icon_spellbook25.png"))
    spark().save(os.path.join(ART, "fx_orb25.png"))
    prev = Image.new("RGBA", (8 * 22 + 50 + 26, 66), (96, 128, 104, 255))
    for i, el in enumerate(ELEMENTS):
        prev.alpha_composite(Image.open(os.path.join(ART, "orb25_%s.png" % el)), (i * 22, 2))
    prev.alpha_composite(altar(), (8 * 22, 0))
    prev.alpha_composite(book(), (8 * 22 + 50, 2))
    prev.resize((prev.width * 4, prev.height * 4), Image.NEAREST).save(os.path.join(HERE, "..", "..", "screenshots", "art_v25.png"))
    print("ok")
