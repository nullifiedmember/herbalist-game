# -*- coding: utf-8 -*-
"""Травы, растущие в мире (herbw_*), — в том же стиле яблока, что и травы в бестиарии (restyle).
Запуск: python restyle_world_herbs.py [--game]  ->  art_apple/herbs_world/; с --game кладёт в game/art
(старые копии — herbalist_game/backup_herbw_20261115)."""
import os, sys, glob, shutil
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import restyle, up
from PIL import Image

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple", "herbs_world"))
BACK = os.path.abspath(os.path.join(GAME, "..", "backup_herbw_20261115"))
SKIP = ("herbw_wt", "herbw_logpile24", "herbw_dun_portal", "herbw_prop")


def main():
    os.makedirs(OUT, exist_ok=True)
    n = 0; pairs = []
    for p in sorted(glob.glob(os.path.join(ART, "herbw_*.png"))):
        name = os.path.basename(p)[:-4]
        if name in SKIP:
            continue
        src = os.path.join(BACK, name + ".png") if os.path.exists(os.path.join(BACK, name + ".png")) else p
        old = Image.open(src).convert("RGBA")
        new = restyle(old)
        new.save(os.path.join(OUT, name + ".png"))
        pairs.append((old, new)); n += 1
        if "--game" in sys.argv:
            os.makedirs(BACK, exist_ok=True)
            if not os.path.exists(os.path.join(BACK, name + ".png")):
                shutil.copy(p, os.path.join(BACK, name + ".png"))
            new.save(p)
    k, cols = 3, 12
    rows = (len(pairs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * 70 * k, rows * 50 * k), (120, 155, 92, 255))
    for i, (o, nw) in enumerate(pairs):
        x, y = (i % cols) * 70 * k, (i // cols) * 50 * k
        sheet.alpha_composite(up(o, k), (x, y)); sheet.alpha_composite(up(nw, k), (x + 34 * k, y))
    sheet.save(os.path.join(OUT, "..", "herbs_world_compare.png"))
    print("травы мира:", n, "->", OUT)


if __name__ == "__main__":
    main()
