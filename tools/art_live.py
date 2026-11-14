"""Арт клуба «Старлит»: вход-лестница с неоном, комната со сценой, барабаны, усилители, бар.
Запуск: python tools/art_live.py   (пишет PNG в game/art/, потом Godot --import)
Всё рисуется пикселями 1:1 по игровым координатам."""
import os
import random
from PIL import Image, ImageDraw, ImageFont

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art")
R = random.Random(7)


def C(h, a=255):
    h = h.lstrip("#")
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), a)


def shade(c, k):
    return (max(0, min(255, int(c[0] * k))), max(0, min(255, int(c[1] * k))), max(0, min(255, int(c[2] * k))), c[3])


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def new(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x, y, w, h, c):
    ImageDraw.Draw(im).rectangle([x, y, x + w - 1, y + h - 1], fill=c)


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def ell(im, cx, cy, rx, ry, c):
    ImageDraw.Draw(im).ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=c)


def outline(im, col=(20, 14, 24, 255)):
    """Тёмный контур вокруг непрозрачных пикселей."""
    src = im.copy()
    w, h = im.size
    for y in range(h):
        for x in range(w):
            if src.getpixel((x, y))[3] > 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and src.getpixel((nx, ny))[3] > 200:
                    im.putpixel((x, y), col)
                    break


def noise(im, box, k=0.08, seed=1):
    r = random.Random(seed)
    x0, y0, x1, y1 = box
    for y in range(y0, y1):
        for x in range(x0, x1):
            p = im.getpixel((x, y))
            if p[3] == 0:
                continue
            f = 1.0 + (r.random() - 0.5) * 2 * k
            im.putpixel((x, y), shade(p, f))


def font(sz):
    for n in ("ariblk.ttf", "arialbd.ttf", "impact.ttf"):
        try:
            return ImageFont.truetype(os.path.join(os.environ.get("WINDIR", "C:/Windows"), "Fonts", n), sz)
        except OSError:
            pass
    return ImageFont.load_default()


def text_mask(txt, sz, spacing=1):
    f = font(sz)
    dummy = Image.new("L", (400, 60), 0)
    d = ImageDraw.Draw(dummy)
    x = 0
    for ch in txt:
        d.text((x, 0), ch, font=f, fill=255)
        x += int(d.textlength(ch, font=f)) + spacing
    bbox = dummy.getbbox()
    m = dummy.crop(bbox)
    return m.point(lambda v: 255 if v > 110 else 0)


def paste_text(im, txt, sz, x, y, col, spacing=1, glow=None):
    m = text_mask(txt, sz, spacing)
    for yy in range(m.height):
        for xx in range(m.width):
            if m.getpixel((xx, yy)):
                px(im, x + xx, y + yy, col)
    return m.size


# ------------------------------------------------------------------ вход с улицы

def entrance():
    W, H = 260, 250
    im = new(W, H)
    d = ImageDraw.Draw(im)
    # правая стена из тёмного кирпича, левая — сине-зелёная плитка
    brick = C("5a3a34")
    for y in range(40, 190):
        for x in range(0, W):
            pass
    # здание: фасад
    rect(im, 8, 30, W - 16, 160, C("6e4a40"))
    # плитка слева (как в оригинале: бирюзово-серая)
    for y in range(30, 190):
        for x in range(8, 100):
            t = C("7ea4a4") if ((x // 10 + y // 10) % 2 == 0) else C("6c9494")
            if x % 10 == 0 or y % 10 == 0:
                t = C("4e6e6e")
            px(im, x, y, t)
    # кирпич справа
    for y in range(30, 190):
        for x in range(160, W - 8):
            row = (y - 30) // 8
            off = 8 if row % 2 else 0
            line = (y - 30) % 8 == 0 or (x + off) % 16 == 0
            base = C("78504a") if (row + x // 16) % 3 else C("6a443e")
            px(im, x, y, C("3a2420") if line else base)
    # карниз
    rect(im, 4, 22, W - 8, 10, C("3a3036"))
    rect(im, 4, 22, W - 8, 3, C("5a4c58"))
    rect(im, 4, 30, W - 8, 2, C("1e161e"))
    # проём
    rect(im, 100, 60, 60, 130, C("160e18"))
    rect(im, 98, 58, 64, 4, C("2a2430"))
    # дверь-внизу в тени: тёмный проём с цифрами/афишей внутри
    rect(im, 110, 96, 40, 94, C("0c0710"))
    rect(im, 112, 98, 36, 90, C("1c1220"))
    for i in range(3):
        rect(im, 116 + i * 11, 110 + i * 3, 8, 12, C(["e0507a", "50a0e0", "f0d040"][i]))
    # ступени вниз (вид сверху-спереди): каждая ниже и темнее
    for i in range(10):
        y = 190 - i * 9 - 9
        wdt = 60 + (i - 5) * 0
        k = 1.0 - i * 0.075
        rect(im, 100, y + 3, 60, 6, shade(C("9a98a2"), k))
        rect(im, 100, y, 60, 3, shade(C("c4c2cc"), k))
    # стенки лестницы
    rect(im, 94, 60, 6, 134, C("4a3a44"))
    rect(im, 160, 60, 6, 134, C("4a3a44"))
    # поручень справа
    for y in range(80, 196):
        px(im, 168, y, C("b8bcc4"))
        px(im, 169, y, C("7a7e88"))
    for y in range(80, 196, 24):
        rect(im, 167, y, 4, 4, C("8a8e98"))
    # козырёк и неоновая вывеска STARLIT (в проёме)
    rect(im, 96, 40, 68, 20, C("1a1220"))
    rect(im, 96, 40, 68, 2, C("3a2a48"))
    sz = paste_text(im, "STARLIT", 12, 103, 46, C("ff4fa0"), 0)
    # звёзды-огоньки вокруг
    for sx, sy, col in ((99, 42, "ffe040"), (161, 56, "40c8ff"), (99, 56, "40c8ff"), (161, 42, "ffe040")):
        rect(im, sx, sy, 2, 2, C(col))
    # окна в плитке слева
    rect(im, 24, 74, 44, 52, C("1a1620"))
    rect(im, 26, 76, 40, 48, C("2a3a5a"))
    for i in range(4):
        px(im, 30 + i * 8, 80, C("5a7aa8"))
    rect(im, 45, 76, 2, 48, C("1a1620"))
    # правая стена: афиша
    rect(im, 188, 80, 38, 54, C("e8dcc0"))
    rect(im, 190, 82, 34, 50, C("1a1830"))
    rect(im, 194, 88, 26, 14, C("e84a7a"))
    ell(im, 207, 112, 8, 8, C("f6d04a"))
    rect(im, 196, 126, 22, 2, C("f0f0f0"))
    # низ: тротуар и цоколь
    rect(im, 0, 190, W, 6, C("5a5560"))
    rect(im, 0, 196, W, 54, (0, 0, 0, 0))
    # зелёная грядка-ящик справа у лестницы
    rect(im, 178, 186, 70, 20, C("6a5a52"))
    rect(im, 178, 186, 70, 3, C("8a7a70"))
    rect(im, 180, 192, 66, 12, C("4a3a34"))
    r = random.Random(3)
    for i in range(70):
        x = 180 + r.randint(0, 64)
        y = 176 + r.randint(0, 14)
        g = r.choice(["3a8a3a", "4aa844", "62c04e", "2e7a34"])
        rect(im, x, y, 3, 4, C(g))
        if r.random() < 0.2:
            px(im, x + 1, y, C("ffe8a0"))
    # доска-меню слева на тротуаре
    rect(im, 14, 170, 4, 24, C("4a3020"))
    rect(im, 50, 170, 4, 24, C("4a3020"))
    rect(im, 12, 148, 46, 34, C("3a2418"))
    rect(im, 14, 150, 42, 30, C("22252a"))
    rect(im, 18, 154, 12, 8, C("e0507a"))
    rect(im, 32, 154, 12, 8, C("40a0e0"))
    rect(im, 18, 165, 12, 8, C("f0d040"))
    rect(im, 32, 165, 12, 8, C("8ae0a0"))
    for i in range(3):
        rect(im, 46, 155 + i * 7, 7, 2, C("e8e8e8"))
    # низ спрайта — только цоколь; всё ниже 196 прозрачно -> подрезаем
    im = im.crop((0, 0, W, 210))
    # ступени «выходят» вперёд на тротуар: нижний край
    rect(im, 100, 196, 60, 10, C("7a7884"))
    rect(im, 100, 196, 60, 2, C("b8b6c0"))
    rect(im, 100, 204, 60, 6, C("3a3844"))
    noise(im, (0, 30, 100, 190), 0.05, 4)
    noise(im, (160, 30, 252, 190), 0.07, 5)
    outline(im)
    im.save(os.path.join(OUT, "live_entrance.png"))


# ------------------------------------------------------------------ комната

def room_bg():
    W, H = 640, 360
    im = Image.new("RGBA", (W, H), C("1a1220"))
    # задняя стена
    for y in range(0, 150):
        for x in range(W):
            t = 0.8 + 0.2 * (y / 150.0)
            c = shade(C("3a2e4a"), t)
            if (y // 12 + x // 24) % 2 == 0:
                c = shade(c, 1.06)
            px(im, x, y, c)
    # кирпичная нижняя часть стены
    for y in range(100, 150):
        for x in range(W):
            row = (y - 100) // 7
            off = 8 if row % 2 else 0
            line = (y - 100) % 7 == 0 or (x + off) % 16 == 0
            px(im, x, y, C("2a1c22") if line else (C("4a2e32") if (x // 16 + row) % 3 else C("3e262a")))
    rect(im, 0, 148, W, 4, C("160e18"))
    # занавес за сценой (бежево-розовый, складками, как на афише)
    for x in range(110, 530):
        w = (x - 110) % 28
        k = 0.78 + 0.22 * abs(((w / 28.0) * 2 - 1))
        for y in range(8, 128):
            c = shade(C("e8d0b8"), k * (0.86 + 0.14 * (1 - y / 128.0)))
            px(im, x, y, c)
    rect(im, 106, 4, 428, 6, C("5a2a30"))
    rect(im, 106, 8, 428, 2, C("8a4a50"))
    # пол: тёмный бетон + клетка у сцены
    for y in range(152, H):
        for x in range(W):
            t = (y - 152) / 208.0
            c = shade(C("3a3640"), 0.85 + 0.2 * (1 - t))
            if ((x // 20) + (y // 20)) % 2 == 0:
                c = shade(c, 1.07)
            px(im, x, y, c)
    noise(im, (0, 152, W, H), 0.04, 9)
    # сцена: помост
    rect(im, 96, 98, 448, 56, C("2a1e22"))
    for x in range(98, 542, 22):
        rect(im, x, 100, 1, 36, C("22161a"))
    for y in range(100, 136):
        for x in range(98, 542):
            c = C("7a4a2e") if ((x // 22 + y // 6) % 2 == 0) else C("6a3e28")
            if (y - 100) % 6 == 0:
                c = C("4a2a1c")
            px(im, x, y, c)
    rect(im, 96, 98, 448, 3, C("a06a40"))
    # передняя панель сцены
    for y in range(136, 156):
        for x in range(96, 544):
            c = C("3a2a2e") if (x // 8) % 2 == 0 else C("32242a")
            px(im, x, y, c)
    rect(im, 96, 136, 448, 3, C("a06a40"))
    rect(im, 96, 154, 448, 2, C("120a10"))
    # гирлянда звёзд над сценой
    for x in range(100, 544, 16):
        y = 12 + int(3 * (1 - abs(((x - 100) % 64) / 32.0 - 1)))
        px(im, x, y, C("ffe08a"))
        px(im, x + 1, y, C("ffe08a"))
    # плинтус/тени по бокам
    for x in range(0, 8):
        rect(im, x, 0, 1, H, shade(C("1a1220"), 0.5 + x * 0.05))
    for x in range(632, 640):
        rect(im, x, 0, 1, H, shade(C("1a1220"), 0.5 + (639 - x) * 0.05))
    for y in range(H):
        for x in range(W):
            r, g, b, a = im.getpixel((x, y))
            im.putpixel((x, y), (min(255, int(r * 1.45 + 10)), min(255, int(g * 1.4 + 8)), min(255, int(b * 1.45 + 14)), a))
    im.save(os.path.join(OUT, "live_room.png"))


def neon_interior():
    im = new(120, 26)
    paste_text(im, "STARLIT", 20, 4, 3, C("ff4fa0"), 2)
    for x, y in ((0, 2), (112, 20), (0, 20), (112, 2)):
        rect(im, x, y, 3, 3, C("ffe040"))
    im.save(os.path.join(OUT, "live_neon.png"))


def drums():
    W, H = 120, 78
    im = new(W, H)
    red, red_d = C("c4283a"), C("7a1424")
    # тарелки на стойках
    for cx, cy, rx in ((22, 10, 20), (100, 14, 18), (60, 6, 14)):
        ell(im, cx, cy, rx, 4, C("c8a038"))
        ell(im, cx, cy - 1, rx - 2, 3, C("f0d060"))
        px(im, cx, cy - 2, C("fff0a0"))
        rect(im, cx, cy + 4, 1, 18, C("6a6a74"))
    # хай-хэт
    # бочка
    ell(im, 60, 54, 26, 22, C("e8e0d8"))
    ell(im, 60, 54, 23, 19, red)
    ell(im, 60, 54, 12, 10, red_d)
    ell(im, 60, 54, 6, 5, C("1a0a10"))
    for a in range(0, 360, 30):
        import math
        px(im, int(60 + 24 * math.cos(math.radians(a))), int(54 + 20 * math.sin(math.radians(a))), C("c8c8d0"))
    # шипы как на афише
    for i in range(8):
        import math
        a = math.radians(200 + i * 20)
        x = int(60 + 28 * math.cos(a))
        y = int(54 + 24 * math.sin(a))
        rect(im, x, y, 3, 3, C("e0e0e8"))
    # том-томы
    for cx in (40, 80):
        ell(im, cx, 36, 11, 7, C("e8e0d8"))
        ell(im, cx, 35, 9, 5, C("f4f0e8"))
        rect(im, cx - 10, 36, 20, 7, red)
        ell(im, cx, 43, 10, 3, red_d)
    # малый барабан
    ell(im, 36, 62, 12, 5, C("e8e0d8"))
    rect(im, 24, 62, 24, 8, red)
    ell(im, 36, 70, 12, 3, red_d)
    # табурет
    ell(im, 90, 66, 8, 3, C("2a2a34"))
    rect(im, 89, 68, 3, 8, C("5a5a64"))
    outline(im)
    im.save(os.path.join(OUT, "live_drums.png"))


def amp(name, w, h, col, grill):
    im = new(w, h)
    rect(im, 0, 0, w, h, shade(C(col), 0.7))
    rect(im, 2, 2, w - 4, h - 4, C(col))
    # решётка
    gh = h - 14
    for y in range(6, 6 + gh):
        for x in range(4, w - 4):
            c = C(grill) if (x + y) % 2 == 0 else shade(C(grill), 0.8)
            px(im, x, y, c)
    for cx, cy in ((w // 2, 6 + gh // 2),):
        ell(im, cx, cy, w // 4, w // 4, shade(C(grill), 0.45))
        ell(im, cx, cy, w // 10, w // 10, shade(C(grill), 0.25))
    # панель ручек
    rect(im, 4, h - 8, w - 8, 5, C("1a1a20"))
    for i in range(5):
        rect(im, 7 + i * ((w - 14) // 5), h - 7, 3, 3, C("e0c060"))
    rect(im, w - 12, h - 7, 3, 3, C("e04040"))
    outline(im)
    im.save(os.path.join(OUT, name))


def mic_stand():
    im = new(18, 62)
    rect(im, 8, 14, 2, 46, C("5a5a64"))
    rect(im, 3, 58, 12, 3, C("3a3a44"))
    rect(im, 8, 58, 2, 3, C("7a7a84"))
    rect(im, 8, 10, 8, 2, C("5a5a64"))
    ell(im, 15, 8, 3, 3, C("30303a"))
    ell(im, 14, 7, 1, 1, C("9a9aa8"))
    outline(im)
    im.save(os.path.join(OUT, "live_mic.png"))


def guitar_stand():
    im = new(22, 52)
    wood = C("8a5a2e")
    ell(im, 11, 38, 8, 8, C("c43a3a"))
    ell(im, 11, 28, 6, 6, C("c43a3a"))
    ell(im, 11, 38, 3, 3, C("5a1414"))
    rect(im, 10, 6, 3, 24, wood)
    rect(im, 8, 2, 7, 6, C("4a2a14"))
    rect(im, 4, 46, 14, 2, C("3a3a44"))
    rect(im, 10, 44, 2, 4, C("5a5a64"))
    outline(im)
    im.save(os.path.join(OUT, "live_guitar.png"))


def monitor():
    im = new(30, 18)
    for y in range(18):
        t = y / 18.0
        w = 30 - int(t * 6)
        rect(im, (30 - w) // 2, y, w, 1, shade(C("2a2a34"), 1.0 - t * 0.3))
    rect(im, 5, 3, 20, 9, C("14141a"))
    for x in range(6, 24, 2):
        px(im, x, 6, C("3a3a46"))
        px(im, x, 9, C("3a3a46"))
    outline(im)
    im.save(os.path.join(OUT, "live_monitor.png"))


def bar():
    W, H = 150, 64
    im = new(W, H)
    # полки с бутылками
    rect(im, 4, 0, W - 8, 24, C("2a1a20"))
    rect(im, 4, 12, W - 8, 2, C("6a4a30"))
    r = random.Random(11)
    for row in (0, 1):
        for x in range(8, W - 10, 9):
            h = r.randint(7, 10)
            col = r.choice(["3a8a5a", "c8783a", "d8c8a0", "4a60b8", "a83a5a"])
            y0 = 11 - h + row * 12
            rect(im, x, y0, 4, h, C(col))
            rect(im, x + 1, y0 - 3, 2, 3, shade(C(col), 0.7))
    # стойка
    rect(im, 0, 28, W, 36, C("5a3420"))
    for x in range(0, W, 14):
        rect(im, x, 32, 1, 28, C("3e2214"))
    rect(im, 0, 24, W, 6, C("a06a40"))
    rect(im, 0, 24, W, 2, C("d09a60"))
    rect(im, 0, 58, W, 6, C("2a160c"))
    # кружки и кассовый аппарат
    rect(im, 20, 16, 6, 8, C("e8e0d8"))
    rect(im, 26, 18, 2, 4, C("e8e0d8"))
    rect(im, 100, 14, 16, 10, C("3a3a44"))
    rect(im, 102, 16, 12, 4, C("8ae0a0"))
    outline(im)
    im.save(os.path.join(OUT, "live_bar.png"))


def table():
    im = new(44, 34)
    ell(im, 22, 18, 17, 8, C("2a1a14"))
    ell(im, 22, 16, 17, 8, C("8a5a3a"))
    ell(im, 22, 15, 14, 6, C("a8744a"))
    rect(im, 20, 22, 4, 10, C("4a2a1a"))
    rect(im, 12, 31, 20, 2, C("3a2014"))
    # свеча
    rect(im, 21, 8, 3, 6, C("f0e8d0"))
    px(im, 22, 6, C("ffd860"))
    px(im, 22, 7, C("ff9a30"))
    outline(im)
    im.save(os.path.join(OUT, "live_table.png"))


def stool():
    im = new(14, 18)
    ell(im, 7, 5, 6, 3, C("c43a5a"))
    rect(im, 1, 5, 12, 3, C("8a2a42"))
    rect(im, 3, 8, 2, 9, C("5a5a64"))
    rect(im, 9, 8, 2, 9, C("5a5a64"))
    outline(im)
    im.save(os.path.join(OUT, "live_stool.png"))


def poster(name, cols):
    im = new(30, 42)
    rect(im, 0, 0, 30, 42, C("e8dcc0"))
    rect(im, 2, 2, 26, 38, C(cols[0]))
    ell(im, 15, 16, 8, 8, C(cols[1]))
    rect(im, 5, 28, 20, 3, C("f0f0f0"))
    rect(im, 8, 33, 14, 2, C(cols[2]))
    outline(im)
    im.save(os.path.join(OUT, name))


def stairs_up():
    im = new(70, 44)
    for i in range(7):
        y = i * 6
        k = 0.55 + i * 0.07
        rect(im, 0, y + 2, 70, 4, shade(C("9a98a2"), k))
        rect(im, 0, y, 70, 2, shade(C("c4c2cc"), k))
    rect(im, 0, 0, 5, 44, C("4a3a44"))
    rect(im, 65, 0, 5, 44, C("4a3a44"))
    outline(im)
    im.save(os.path.join(OUT, "live_stairs.png"))


def spot():
    """Мягкое пятно света для прожекторов (белое, радиальное)."""
    import math
    im = new(96, 96)
    for y in range(96):
        for x in range(96):
            d = math.hypot(x - 48, y - 48) / 48.0
            a = max(0.0, 1.0 - d)
            im.putpixel((x, y), (255, 255, 255, int(255 * a * a)))
    im.save(os.path.join(OUT, "live_spot.png"))


def main():
    os.makedirs(OUT, exist_ok=True)
    entrance()
    room_bg()
    neon_interior()
    drums()
    amp("live_amp_a.png", 40, 56, "2a2a34", "5a5a66")
    amp("live_amp_b.png", 34, 44, "4a2a2a", "7a5a4a")
    mic_stand()
    guitar_stand()
    monitor()
    bar()
    table()
    stool()
    poster("live_poster_a.png", ("1a1830", "e84a7a", "f0d040"))
    poster("live_poster_b.png", ("2a1a3a", "40a0e0", "e84a4a"))
    stairs_up()
    spot()
    print("LIVE ART DONE")


if __name__ == "__main__":
    main()
