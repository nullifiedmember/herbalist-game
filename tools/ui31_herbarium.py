# -*- coding: utf-8 -*-
"""v31: засушенные растения для фона сумки (гербарий): движок apple_engine из скилла apple-pixel-style.
Каждое растение — цветной контур, свет сверху-слева, приглушённые тона (как засушенное).
Используется из tools/ui31_inv.py: specimens() -> {имя: PIL RGBA}."""
import os
import sys

SKILL = os.path.join(os.path.expanduser("~"), ".claude", "skills", "apple-pixel-style", "scripts")
sys.path.insert(0, SKILL)
from apple_engine import Canvas, ell, tube  # noqa: E402
from PIL import Image  # noqa: E402

PAPER = (246, 233, 204)


def mute(img, k=0.22):
    """Приглушить к цвету бумаги — растение «засушено», не спорит с вещами."""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a:
                px[x, y] = (int(r + (PAPER[0] - r) * k), int(g + (PAPER[1] - g) * k), int(b + (PAPER[2] - b) * k), a)
    return img


def fern():
    c = Canvas(34, 74)
    for i in range(9):
        y = 10 + i * 6.6
        L = 13 - i * 1.15
        for s in (-1, 1):
            c.add(tube([(17, y), (17 + s * L * 0.55, y - 3), (17 + s * L, y - 1)], 2.2, profile="leaf"), "#7aa868")
    c.add(tube([(17, 72), (16, 40), (17, 4)], 0.9, 0.5), "#8a9a5a")
    return mute(c.render())


def chamomile():
    c = Canvas(30, 58)
    c.add(tube([(15, 56), (13, 36), (15, 14)], 0.8), "#7a9a5a")
    c.add(tube([(14, 40), (8, 34), (4, 36)], 1.8, profile="leaf"), "#86ac6a")
    c.add(tube([(14, 30), (21, 26), (25, 28)], 1.6, profile="leaf"), "#86ac6a")
    for k in range(10):
        import math
        a = k * math.pi / 5
        c.add(ell(15 + math.cos(a) * 6, 11 + math.sin(a) * 5, 2.6, 1.4, ang=math.degrees(a)), "#fbf4e6")
    c.add(ell(15, 11, 3.2, 2.8), "#f0c040", shine=True)
    return mute(c.render(), 0.16)


def maple_leaf():
    c = Canvas(36, 40)
    import math
    for a, L in [(-90, 15), (-140, 12), (-40, 12), (-185, 8), (5, 8)]:
        r = math.radians(a)
        c.add(tube([(18, 22), (18 + math.cos(r) * L * 0.6, 22 + math.sin(r) * L * 0.6), (18 + math.cos(r) * L, 22 + math.sin(r) * L)],
                   5.2 if L > 10 else 4.0, profile="leaf"), "#e09048")
    c.add(ell(18, 21, 6, 5), "#e09048")
    c.add(tube([(18, 38), (18, 30), (18, 22)], 0.8), "#a8643a", outline=False)
    for a, L in [(-90, 13), (-140, 10), (-40, 10)]:
        r = math.radians(a)
        for t in range(2, L, 1):
            c.mark(int(18 + math.cos(r) * t), int(22 + math.sin(r) * t), "#c87038")
    return mute(c.render(), 0.18)


def lavender():
    c = Canvas(24, 60)
    c.add(tube([(12, 58), (11, 36), (13, 18)], 0.7), "#7e9a62")
    c.add(tube([(11, 44), (6, 38), (4, 40)], 1.4, profile="leaf"), "#94a878")
    for i in range(8):
        y = 4 + i * 2.6
        s = -1 if i % 2 else 1
        c.add(ell(13 + s * 1.6, y, 2.2, 1.6), "#9a7ad0")
    c.spark(12, 3, "#d8c8f8")
    return mute(c.render(), 0.18)


def specimens():
    return {"fern": fern(), "chamomile": chamomile(), "maple": maple_leaf(), "lavender": lavender()}


if __name__ == "__main__":
    out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "screenshots", "ui31_herbarium_x6.png")
    sp = specimens()
    W = sum(i.width * 6 + 24 for i in sp.values())
    H = max(i.height * 6 for i in sp.values())
    sheet = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    x = 0
    for i in sp.values():
        sheet.paste(i.resize((i.width * 6, i.height * 6), Image.NEAREST), (x, 0))
        x += i.width * 6 + 24
    sheet.save(out)
    print("ok", {k: v.size for k, v in sp.items()})
