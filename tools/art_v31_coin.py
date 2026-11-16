# -*- coding: utf-8 -*-
"""v31: монета травницы 20x20 в стиле яблока — золотой диск с ободком и выпуклым ростком травы (три листика).
Тёплый цветной контур, свет сверху-слева. Заменяет art/coin.png (старая: backup_v31_pre/art/coin.png).
Запуск: python -I tools/art_v31_coin.py (из папки game)
"""
import math
import os
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
PREV = os.path.join(HERE, "..", "..", "screenshots")


def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


O = hx("8a5430")        # контур
RIM_L, RIM_D = hx("ffe28c"), hx("c8862e")
FACE, FACE_L, FACE_D = hx("f2b84e"), hx("f8cf6e"), hx("e0a03e")
GROOVE_D, GROOVE_L = hx("cf8e34"), hx("fff0b0")
EMB, EMB_L, EMB_D = hx("c27a2a"), hx("fff0b0"), hx("a8641e")
SHINE = hx("fffbe6")

# росток: s — стебель, L — лист, l — светлая кромка листа (выпуклость), d — тень листа
SPRIG = [
    ".....l.....",
    "....lLd....",
    "...lLLd....",
    "....Lds....",
    ".ll..s..ll.",
    "lLLd.s.lLLd",
    ".lLLds.LLd.",
    "..ddss.dd..",
    ".....s.....",
    ".....s.....",
    "....sss....",
]


def main():
    W = H = 20
    im = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    px = im.load()
    c = 9.5
    for y in range(H):
        for x in range(W):
            d = math.hypot(x - c, y - c)
            lit = (x - c) + (y - c) < 0
            if d > 9.6:
                continue
            if d > 8.6:
                px[x, y] = O
            elif d > 7.4:
                px[x, y] = RIM_L if lit else RIM_D           # ободок
            elif d > 6.5:
                px[x, y] = GROOVE_D if lit else GROOVE_L     # вдавленная канавка (свет падает наоборот)
            else:
                px[x, y] = FACE_L if (x - c) + (y - c) < -6 else (FACE_D if (x - c) + (y - c) > 6 else FACE)
    # листья — зелёная эмаль на золоте (сразу видно, что это травка), стебель — тёмное золото
    cm = {"s": EMB_D, "L": hx("7cb35a"), "l": hx("bfe58e"), "d": hx("4f8a4c")}
    for j, row in enumerate(SPRIG):
        for i, ch in enumerate(row):
            if ch != ".":
                px[4 + i, 4 + j] = cm[ch]
    # блик на ободке сверху-слева
    for (x, y) in [(5, 3), (4, 4), (3, 5)]:
        px[x, y] = SHINE
    im.save(os.path.join(ART, "coin.png"))
    im.resize((W * 12, H * 12), Image.NEAREST).save(os.path.join(PREV, "v31_coin_x12.png"))
    print("ok coin")


if __name__ == "__main__":
    main()
