# -*- coding: utf-8 -*-
"""Травы: перекраска старых спрайтов игры в стиль яблока (форма и детали сохраняются).
Запуск: python restyle_herbs.py  ->  C:/Claude/herbalist_game/art_apple/herbs/  (+ herbs_compare_x4.png)"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import restyle, up
from PIL import Image, ImageDraw

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple", "herbs"))
DRAWN = os.path.abspath(os.path.join(GAME, "..", "art_apple", "herbs_drawn"))
# эти травы пользователь выбрал в версии, нарисованной заново (herbs.py), а не перекрашенной
KEEP_DRAWN = ("dandelion", "yarrow")


def ids():
    src = open(os.path.join(GAME, "herbs_db.gd"), encoding="utf-8").read()
    return re.findall(r'"([a-z0-9_]+)"', re.search(r'const ORDER\s*[:=][^\[]*\[(.*?)\]', src, re.S).group(1))


def main():
    os.makedirs(OUT, exist_ok=True)
    files = []
    for i in ids():
        for fn in ["herb14_%s.png" % i, "seeds_%s.png" % i] + ["%s_%d.png" % (i, k) for k in range(4)]:
            p = os.path.join(ART, fn)
            if i in KEEP_DRAWN and os.path.exists(os.path.join(DRAWN, fn)):
                Image.open(os.path.join(DRAWN, fn)).save(os.path.join(OUT, fn))
                files.append(fn)
            elif os.path.exists(p):
                restyle(Image.open(p)).save(os.path.join(OUT, fn))
                files.append(fn)
    # сравнение было / стало
    lst = ids(); cols, k = 8, 4
    sheet = Image.new("RGBA", (cols * 70 * k, ((len(lst) + cols - 1) // cols) * 58 * k), (246, 241, 230, 255))
    d = ImageDraw.Draw(sheet)
    for n, i in enumerate(lst):
        fn = "%s_3.png" % i if os.path.exists(os.path.join(ART, "%s_3.png" % i)) else "herb14_%s.png" % i
        x = (n % cols) * 70 * k; y = (n // cols) * 58 * k
        sheet.alpha_composite(up(Image.open(os.path.join(ART, fn)).convert("RGBA"), k), (x + 2 * k, y + 2 * k))
        sheet.alpha_composite(up(Image.open(os.path.join(OUT, fn)).convert("RGBA"), k), (x + 36 * k, y + 2 * k))
        d.text((x + 4 * k, y + 51 * k), i, fill=(60, 40, 40, 255))
    sheet.save(os.path.join(OUT, "..", "herbs_compare_x4.png"))
    print("готово:", len(files), "файлов ->", OUT)


if __name__ == "__main__":
    main()
