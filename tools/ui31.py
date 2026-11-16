# -*- coding: utf-8 -*-
"""v31: детали интерфейса в стиле яблока.
Тёплое дерево + пергамент, цветной контур без чёрного, свет сверху-слева.
Те же размеры и поля, что у старых ui_*.png, поэтому подменяют их без правки кода.
Старые копии: herbalist_game/backup_v31_pre/art/.
Запуск: python -I tools/ui31.py   (из папки game)
"""
import os
import sys
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
PREV = os.path.join(HERE, "..", "..", "screenshots")


def hx(s):
    s = s.lstrip("#")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16), 255)


# --- палитра (пастельная, тени к сиреневому, света к жёлтому) ---
WOOD = dict(o=hx("6e4636"), hi=hx("ecc48e"), lt=hx("d9a873"), md=hx("bf8a58"), dk=hx("9c6a48"), dd=hx("845a40"))
GOLD = dict(o=hx("8a5430"), hi=hx("fff0b8"), lt=hx("ffd978"), md=hx("f0b44c"), dk=hx("cf8a3a"), dd=hx("b06e32"))
PAPER = dict(c=hx("f6e9cc"), sh=hx("e9d4ac"), sh2=hx("dcc297"), li=hx("fff7e4"))
SLOT_IN = dict(c=hx("ecdab4"), sh=hx("d8bf92"), sh2=hx("c9ab7e"), li=hx("f8ead0"))
SEL_IN = dict(c=hx("fff1c8"), sh=hx("f4dc9c"), sh2=hx("e8c47a"), li=hx("fffae6"))
LEAF = dict(o=hx("3f6a4a"), lt=hx("a8d47a"), md=hx("74b05a"), dk=hx("4f8a4c"))
T = (0, 0, 0, 0)


def cut_for(r):
    """Профиль скругления угла: сколько пикселей срезать в строках сверху."""
    return {0: [], 1: [1], 2: [2, 1], 3: [3, 1, 1], 4: [4, 2, 1, 1]}[r]


def inside(x, y, w, h, ins, r):
    """Пиксель внутри скруглённого прямоугольника, вдавленного на ins."""
    x0, y0, x1, y1 = ins, ins, w - 1 - ins, h - 1 - ins
    if x < x0 or y < y0 or x > x1 or y > y1:
        return False
    prof = cut_for(max(0, r))
    dy = min(y - y0, y1 - y)
    dx = min(x - x0, x1 - x)
    if dy < len(prof) and dx < prof[dy]:
        return False
    return True


def side(x, y, w, h):
    """Какая сторона ближе: свет сверху-слева, тень снизу-справа."""
    d = {"t": y, "l": x, "b": h - 1 - y, "r": w - 1 - x}
    m = min(d.values())
    for k in ("t", "l", "b", "r"):
        if d[k] == m:
            return k


def framed(w, h, pal, inner, ring=3, r=3, inner_r=1):
    """Рамка: контур, дерево ring px (кромка света / тень), внутренний шов, дно."""
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if not inside(x, y, w, h, 0, r):
                continue
            if not inside(x, y, w, h, 1, r - 1):
                px[x, y] = pal["o"]
                continue
            s = side(x, y, w, h)
            lit = s in ("t", "l")
            if not inside(x, y, w, h, 1 + ring, inner_r):
                # дерево: самая внешняя полоса — кромка света/тени
                outer = not inside(x, y, w, h, 2, max(0, r - 2))
                inner_band = not inside(x, y, w, h, ring, inner_r + 1) and inside(x, y, w, h, ring, inner_r + 1) is False
                if outer:
                    px[x, y] = pal["hi"] if lit else pal["dk"]
                elif not inside(x, y, w, h, ring, inner_r):
                    px[x, y] = pal["lt"] if lit else pal["dk"]
                else:
                    px[x, y] = pal["md"] if lit else pal["dd"]
                continue
            if not inside(x, y, w, h, 2 + ring, max(0, inner_r - 1)):
                px[x, y] = pal["o"]     # шов между деревом и дном
                continue
            # дно (пергамент): у верхней/левой кромки тень от рамки, у нижней/правой — отсвет
            dt = y - (2 + ring)
            dl = x - (2 + ring)
            db = (h - 1 - (2 + ring)) - y
            dr = (w - 1 - (2 + ring)) - x
            if dt == 0 or dl == 0:
                px[x, y] = inner["sh2"]
            elif dt == 1 or dl == 1:
                px[x, y] = inner["sh"]
            elif db == 0 or dr == 0:
                px[x, y] = inner["li"]
            else:
                px[x, y] = inner["c"]
    return im


def leaf(im, x, y, flip_x=False, flip_y=False):
    """Листок-уголок 5x5 (рисунок попиксельно, цветной контур)."""
    # веточка из двух листиков, ягодка у черенка
    pat = [
        ".oo.....",
        "oLLo....",
        "oLMo.oo.",
        ".oMDoLLo",
        "..ooMMDo",
        "...rRoo.",
        "...RR...",
    ]
    cmap = {"o": LEAF["o"], "L": LEAF["lt"], "M": LEAF["md"], "D": LEAF["dk"],
            "r": hx("ff9a8a"), "R": hx("d24a52")}
    px = im.load()
    n = len(pat[0]) - 1
    m = len(pat) - 1
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch == ".":
                continue
            xx = x + (n - i if flip_x else i)
            yy = y + (m - j if flip_y else j)
            px[xx, yy] = cmap[ch]


def berry(im, x, y):
    px = im.load()
    px[x, y] = hx("8a3a40")
    px[x + 1, y] = hx("e05a5c")
    px[x, y + 1] = hx("c8444c")
    px[x + 1, y + 1] = hx("b23a46")
    px[x + 1, y] = hx("ff9a8a")


def make_panel():
    # 40x40, поля 12: всё оформление в углах (12x12), середины рёбер ровные — растягиваются чисто
    im = framed(40, 40, WOOD, PAPER, ring=3, r=3, inner_r=1)
    # веточки с листиками на углах (только в зоне 12x12)
    leaf(im, 0, 0)
    leaf(im, 32, 0, flip_x=True)
    leaf(im, 0, 33, flip_y=True)
    leaf(im, 32, 33, flip_x=True, flip_y=True)
    return im


def make_slot(sel):
    if sel:
        return framed(24, 24, GOLD, SEL_IN, ring=2, r=2, inner_r=1)
    return framed(24, 24, WOOD, SLOT_IN, ring=2, r=2, inner_r=1)


def make_key():
    """Клавиша 22x22: светлый верх, тёмный бок снизу, контур тёплый."""
    w, h = 22, 22
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    o = hx("6e4636")
    face, face_lt, face_sh = hx("f6e9cc"), hx("fffaea"), hx("e6d0a6")
    side_c, side_d = hx("c99e6c"), hx("a87c54")
    for y in range(h):
        for x in range(w):
            if not inside(x, y, w, h, 0, 3):
                continue
            if not inside(x, y, w, h, 1, 2):
                px[x, y] = o
                continue
            if y >= h - 5:               # бок клавиши
                px[x, y] = side_d if y == h - 2 else side_c
                continue
            if y == h - 6:
                px[x, y] = o if x in (1, w - 2) else face_sh
                continue
            if y <= 2 or x <= 2:
                px[x, y] = face_lt
            elif x >= w - 3:
                px[x, y] = face_sh
            else:
                px[x, y] = face
    return im


# --- пиксельные цифры 4x6 (для панели быстрого доступа) ---
GLYPH = {
    "0": [".##.", "#..#", "#..#", "#..#", "#..#", ".##."],
    "1": [".#..", "##..", ".#..", ".#..", ".#..", "###."],
    "2": [".##.", "#..#", "..#.", ".#..", "#...", "####"],
    "3": ["###.", "...#", ".##.", "...#", "...#", "###."],
    "4": ["#..#", "#..#", "#..#", "####", "...#", "...#"],
    "5": ["####", "#...", "###.", "...#", "...#", "###."],
    "6": [".##.", "#...", "###.", "#..#", "#..#", ".##."],
    "7": ["####", "...#", "..#.", ".#..", ".#..", ".#.."],
    "8": [".##.", "#..#", ".##.", "#..#", "#..#", ".##."],
    "9": [".##.", "#..#", "#..#", ".###", "...#", ".##."],
}


def glyph_px(d):
    return {(i, j) for j, row in enumerate(GLYPH[d]) for i, ch in enumerate(row) if ch == "#"}


def make_digit(d):
    """Цифра-счётчик 6x8: кремовая заливка, свет сверху, тёплый контур (не чёрный)."""
    im = Image.new("RGBA", (6, 8), T)
    px = im.load()
    g = {(x + 1, y + 1) for x, y in glyph_px(d)}
    for x, y in g:
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                q = (x + dx, y + dy)
                if q not in g and 0 <= q[0] < 6 and 0 <= q[1] < 8:
                    px[q] = hx("5e3a2c")
    for x, y in g:
        px[x, y] = hx("fff7e4") if y <= 2 else (hx("f2dfb8") if y < 6 else hx("e2c493"))
    return im


def make_tag(d, sel):
    """Бирка с номером ячейки 8x10: дерево (выбранная — мёд), цифра светлая/тёмная."""
    pal = GOLD if sel else WOOD
    w, h = 8, 10
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    for y in range(h):
        for x in range(w):
            if not inside(x, y, w, h, 0, 1):
                continue
            if not inside(x, y, w, h, 1, 0):
                px[x, y] = pal["o"]
            elif y == 1 or x == 1:
                px[x, y] = pal["hi"] if sel else pal["lt"]
            elif y == h - 2 or x == w - 2:
                px[x, y] = pal["dk"]
            else:
                px[x, y] = pal["md"]
    ink = hx("6e3e24") if sel else hx("fff2d6")
    for x, y in glyph_px(d):
        px[x + 2, y + 2] = ink
    return im


# --- детали окон сумки/склада ---
def nails(im, w, h):
    """Латунные гвоздики в углах деревянной рамки."""
    px = im.load()
    for (x, y) in [(2, 2), (w - 4, 2), (2, h - 4), (w - 4, h - 4)]:
        px[x, y] = hx("fff0b8")
        px[x + 1, y] = hx("e0a048")
        px[x, y + 1] = hx("e0a048")
        px[x + 1, y + 1] = hx("9a5e2c")
    return im


def make_islot():
    """Рамка слота снаряжения 16x16 (поля 6, пиксель 2): дерево с гвоздиками, вдавленное дно."""
    return nails(framed(16, 16, WOOD, SLOT_IN, ring=2, r=2, inner_r=1), 16, 16)


def make_islot_hl():
    return nails(framed(16, 16, GOLD, SEL_IN, ring=2, r=2, inner_r=1), 16, 16)


def make_cell(locked=False):
    """Клетка сетки 22x22 (рисуется 44 px): пергамент, тень сверху-слева, шов справа-снизу."""
    w = h = 22
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    c, sh, li, seam = (hx("ecdab4"), hx("dcc39a"), hx("f6e8cc"), hx("cdb085"))
    if locked:
        c, sh, li, seam = (hx("cdb894"), hx("bea681"), hx("d8c4a2"), hx("b0946c"))
    for y in range(h):
        for x in range(w):
            if x == w - 1 or y == h - 1:
                px[x, y] = seam
            elif x == 0 or y == 0:
                px[x, y] = sh
            elif x == w - 2 or y == h - 2:
                px[x, y] = li
            else:
                px[x, y] = c
    # крошечный ромбик в середине — «вышивка» пустой клетки
    if not locked:
        for (x, y) in [(10, 10), (11, 10), (10, 11), (11, 11)]:
            px[x, y] = hx("e3cda4")
    return im


def make_lock():
    """Замочек 14x14: медная дужка, медовый корпус, тёмная скважина."""
    pat = [
        "....oooooo....",
        "...oSSSSSSo...",
        "...oSo..oSo...",
        "...oSo..oSo...",
        "...oSo..oSo...",
        ".oooooooooooo.",
        ".oHHHHHHHHHHo.",
        ".oHLLLLLLLLMo.",
        ".oLLLLkkLLLMo.",
        ".oLLLLkkLLLMo.",
        ".oLLLLLkLLLMo.",
        ".oMMMMMMMMMDo.",
        ".oDDDDDDDDDDo.",
        "..oooooooooo..",
    ]
    cm = {"o": hx("7a4a2c"), "S": hx("c9a27a"), "H": GOLD["hi"], "L": GOLD["lt"], "M": GOLD["md"],
          "D": GOLD["dk"], "k": hx("5e3a2c")}
    im = Image.new("RGBA", (14, 14), T)
    px = im.load()
    for j, row in enumerate(pat):
        for i, ch in enumerate(row):
            if ch != ".":
                px[i, j] = cm[ch]
    return im


def make_close():
    """Крестик 16x16: круглая красная «ягодка» с кремовым крестом и бликом."""
    w = h = 16
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    o, hi, lt, md, dk = hx("8a3038"), hx("ffb0a0"), hx("f07a6e"), hx("d8505a"), hx("b03c4a")
    for y in range(h):
        for x in range(w):
            dx, dy = x - 7.5, y - 7.5
            d = (dx * dx + dy * dy) ** 0.5
            if d > 7.6:
                continue
            if d > 6.6:
                px[x, y] = o
            elif dx + dy < -5:
                px[x, y] = lt
            elif dx + dy > 5:
                px[x, y] = dk
            else:
                px[x, y] = md
    px[4, 4] = hi
    px[5, 3] = hi
    px[3, 5] = hi
    cream, csh = hx("fff4dc"), hx("e8c8b0")
    for i in range(6):
        for (x, y) in [(5 + i, 5 + i), (10 - i, 5 + i)]:
            px[x, y] = cream
            if y + 1 < h and px[x, y + 1] != cream:
                px[x, y + 1] = csh
    return im


def make_sign():
    """Табличка с названием окна 130x22: дерево, пергамент, веточки по краям."""
    im = framed(130, 22, WOOD, PAPER, ring=2, r=3, inner_r=1)
    leaf(im, 0, 0)
    leaf(im, 122, 0, flip_x=True)
    leaf(im, 0, 15, flip_y=True)
    leaf(im, 122, 15, flip_x=True, flip_y=True)
    return im


def make_btn(state):
    """Кнопка 16x16 (поля 5): кремовая клавиша с боком; hover — медовая, pressed — нажата."""
    w = h = 16
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    o = hx("6e4636")
    if state == "hover":
        face, lt, sh, side_c, side_d = hx("ffe9b0"), hx("fff6d8"), hx("f0cf86"), hx("d8a258"), hx("b88040")
    else:
        face, lt, sh, side_c, side_d = hx("f6e9cc"), hx("fffaea"), hx("e6d0a6"), hx("c99e6c"), hx("a87c54")
    depth = 1 if state == "pressed" else 3
    top = 2 if state == "pressed" else 0
    for y in range(h):
        for x in range(w):
            yy = y - top
            if yy < 0:
                continue
            if not inside(x, yy, w, h - top, 0, 2):
                continue
            if not inside(x, yy, w, h - top, 1, 1):
                px[x, y] = o
                continue
            if y >= h - 1 - depth:
                px[x, y] = side_d if y == h - 2 else side_c
            elif yy <= 2 or x <= 2:
                px[x, y] = lt
            elif x >= w - 3 or y == h - 2 - depth:
                px[x, y] = sh
            else:
                px[x, y] = face
    return im


def make_tip():
    """Подсказка 18x18 (поля 6): тёмная ореховая дощечка в светлой рамке — светлый текст читается."""
    dark = dict(c=hx("4a3428"), sh=hx("3a2820"), sh2=hx("30211a"), li=hx("5a4232"))
    return framed(18, 18, WOOD, dark, ring=2, r=2, inner_r=1)


def make_wpanel():
    """Рамка большого окна 64x64 (поля 12, середина плиткой): резное дерево с прожилками,
    латунные уголки с листом и ягодкой, бумага с волокнами. Рёбра и середина бесшовные — тянутся плиткой."""
    import random
    r = random.Random(7)
    w = h = 64
    FR = 9
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    paper = [hx("ead6ae"), hx("f1e0bd"), hx("f6e9cc"), hx("fbf1dc")]
    bay = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]
    for y in range(h):
        for x in range(w):
            if not inside(x, y, w, h, 0, 4):
                continue
            d = min(x, y, w - 1 - x, h - 1 - y)
            sd = min((y, "t"), (x, "l"), (h - 1 - y, "b"), (w - 1 - x, "r"))[1]
            lit = sd in ("t", "l")
            if d >= FR:
                # бумага: ровный тон, у рамы тень, редкие волокна (одиночные пиксели — плитка без швов)
                v = (bay[y % 4][x % 4] + r.random() * 6) / 22.0
                c = paper[2] if v < 0.72 else (paper[3] if v < 0.86 else paper[1])
                if d == FR and (y == FR or x == FR):
                    c = hx("dcc297")
                elif d == FR + 1 and (y == FR + 1 or x == FR + 1):
                    c = hx("e6cfa6")
                elif d == FR and lit is False:
                    c = paper[3]
                px[x, y] = c
                continue
            if not inside(x, y, w, h, 1, 3):
                c = WOOD["o"]
            elif d == 1:
                c = WOOD["hi"] if lit else WOOD["dk"]
            elif d == 5:
                c = WOOD["dk"] if lit else WOOD["dd"]
            elif d == 6:
                c = WOOD["lt"] if lit else WOOD["hi"]
            elif d == 7:
                c = WOOD["dd"]
            elif d == 8:
                c = WOOD["o"]
            else:
                c = WOOD["lt"] if (lit and d == 2) else WOOD["md"]
                # прожилки вдоль ребра: повторяются с шагом 16 — шов плитки не виден
                k = (x if sd in ("t", "b") else y) % 16
                if d in (3, 4) and ((d == 3 and 3 <= k <= 8) or (d == 4 and 10 <= k <= 14)):
                    c = WOOD["dk"] if lit else WOOD["dd"]
            px[x, y] = c
    pat = [
        "ooooooooooo.",
        "oHHHHHHHHHo.",
        "oHLLLLLLLMDo",
        "oHLnLLgLLMDo",
        "oHLLLggGLMDo",
        "oHLLgGGgLMDo",
        "oHLLLgGLLMDo",
        "oHLgLLLLnMDo",
        "oHLLLLLLLMDo",
        "oHMMMMMMMMDo",
        "ooDDDDDDDDDo",
        ".ooooooooooo",
    ]
    cm = {"o": hx("7a4a2c"), "H": GOLD["hi"], "L": GOLD["lt"], "M": GOLD["md"], "D": GOLD["dk"],
          "g": hx("cf8a3a"), "G": hx("b06e32"), "n": hx("fff8d8")}
    for (fx, fy) in [(False, False), (True, False), (False, True), (True, True)]:
        for j, row in enumerate(pat):
            for i, ch in enumerate(row):
                if ch == ".":
                    continue
                xx = (w - 1 - i) if fx else i
                yy = (h - 1 - j) if fy else j
                px[xx, yy] = cm[ch]
    return im


def up(im, k):
    return im.resize((im.width * k, im.height * k), Image.NEAREST)


def main():
    out = {
        "ui_panel": make_panel(),
        "ui_slot": make_slot(False),
        "ui_slot_sel": make_slot(True),
        "ui_key": make_key(),
    }
    for n, im in out.items():
        im.save(os.path.join(ART, n + ".png"))
    win = {
        "ui31_islot": make_islot(), "ui31_islot_hl": make_islot_hl(),
        "ui31_cell": make_cell(False), "ui31_cell_lock": make_cell(True),
        "ui31_lock": make_lock(), "ui31_close": make_close(), "ui31_sign": make_sign(),
        "ui31_btn": make_btn("normal"), "ui31_btn_hover": make_btn("hover"), "ui31_btn_pressed": make_btn("pressed"),
        "ui31_tip": make_tip(),
    }
    for n, im in win.items():
        im.save(os.path.join(ART, n + ".png"))
    # заранее увеличенные ×2 — для StyleBoxTexture кнопок и всплывающих меню (Godot не масштабирует их сам)
    for n in ("ui31_btn", "ui31_btn_hover", "ui31_btn_pressed"):
        up(win[n], 2).save(os.path.join(ART, n + "_x2.png"))
    up(out["ui_panel"], 2).save(os.path.join(ART, "ui31_panel_x2.png"))
    up(win["ui31_tip"], 2).save(os.path.join(ART, "ui31_tip_x2.png"))
    wp = make_wpanel()
    wp.save(os.path.join(ART, "ui31_wpanel.png"))
    up(wp, 2).save(os.path.join(ART, "ui31_wpanel_x2.png"))
    up(wp, 6).save(os.path.join(PREV, "ui31_wpanel_x6.png"))
    ims = [up(im, 6) for im in win.values()]
    ws = Image.new("RGBA", (sum(i.width + 18 for i in ims), max(i.height for i in ims)), T)
    x = 0
    for i in ims:
        ws.paste(i, (x, 0))
        x += i.width + 18
    ws.save(os.path.join(PREV, "ui31_win_parts_x6.png"))
    # цифры: ui31_dg_0..9 (счётчик), ui31_tag_1..9 и ui31_tag_1..9_sel (номер ячейки)
    dig = []
    for d in "0123456789":
        im = make_digit(d)
        im.save(os.path.join(ART, "ui31_dg_%s.png" % d))
        dig.append(im)
        if d != "0":
            make_tag(d, False).save(os.path.join(ART, "ui31_tag_%s.png" % d))
            make_tag(d, True).save(os.path.join(ART, "ui31_tag_%s_sel.png" % d))
    ds = Image.new("RGBA", (10 * 56, 72 + 2 * 68), T)
    for i, d in enumerate("0123456789"):
        ds.paste(up(dig[i], 8), (i * 56, 0))
        if d != "0":
            ds.paste(up(make_tag(d, False), 6), (i * 56, 72))
            ds.paste(up(make_tag(d, True), 6), (i * 56, 72 + 68))
    ds.save(os.path.join(PREV, "ui31_digits_x8.png"))
    # превью ×8 на прозрачном фоне + пример растянутой панели ×2
    ims = [up(im, 8) for im in out.values()]
    W = sum(i.width + 24 for i in ims)
    H = max(i.height for i in ims)
    sheet = Image.new("RGBA", (W, H), T)
    x = 0
    for i in ims:
        sheet.paste(i, (x, 0))
        x += i.width + 24
    sheet.save(os.path.join(PREV, "ui31_parts_x8.png"))
    print("ok", list(out.keys()))


if __name__ == "__main__":
    sys.exit(main())
