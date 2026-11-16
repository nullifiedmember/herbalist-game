# Героиня-травница в чиби-стиле (стиль яблока). Запуск: python -I hero_chibi.py
# Вывод: herbalist_game/art_apple/hero_chibi/ (hero_chibi.png, hero_chibi_x8.png)
import os, sys
sys.path.insert(0, os.path.expanduser(r"~/.claude/skills/apple-pixel-style/scripts"))
from apple_engine import Canvas, ell, poly, rect, tube, up, ramp, hx

OUT = os.path.join(os.path.dirname(__file__), "..", "..", "art_apple", "hero_chibi")
W, H = 44, 54
CX = 22          # ось симметрии (пиксели x и 44-x зеркальны)

HAIR = "#cfa878"   # пшеничные волосы
SKIN = "#f8dccb"
BLOUSE = "#f1ede8"
SKIRT = "#ebe6e0"
CAPE = "#3f9c91"
BELT = "#7c5034"
BOOT = "#8e5d3e"
BOW = "#4fb3a6"


def mir(pts):
    return [(2 * CX - x, y) for x, y in pts]


def draw(blink=False):
    c = Canvas(W, H)
    # плащ сзади
    c.add(poly([(14, 27), (30, 27), (35, 36), (37, 45), (32, 44), (22, 45), (12, 44), (7, 45), (9, 36)]), CAPE)
    # длинные волосы сзади, волнистые концы
    back = [(9, 13), (35, 13), (36, 24), (36.5, 32), (35.5, 37), (33.5, 40), (32, 38), (30.5, 41), (28.5, 37),
            (15.5, 37), (13.5, 41), (12, 38), (10.5, 40), (8.5, 37), (7.5, 32), (8, 24)]
    c.add(poly(back), HAIR, tone_bias=1)
    # ноги и ботинки
    c.add(rect(18, 39, 20, 47), SKIN)
    c.add(rect(24, 39, 26, 47), SKIN)
    c.add(poly([(17, 46.5), (21, 46.5), (21.5, 51), (16.5, 51)]), BOOT)
    c.add(poly([(23, 46.5), (27, 46.5), (27.5, 51), (22.5, 51)]), BOOT)
    # юбка
    c.add(poly([(16, 35), (28, 35), (30, 38), (31, 40.5), (13, 40.5), (14, 38)]), SKIRT)
    # блузка
    c.add(poly([(16.5, 28), (27.5, 28), (28, 36), (16, 36)]), BLOUSE)
    # рукава-фонарики и кисти
    c.add(tube([(16, 29), (13.5, 32.5), (12.5, 35.5)], 3.4, 2.6), BLOUSE)
    c.add(tube(mir([(16, 29), (13.5, 32.5), (12.5, 35.5)]), 3.4, 2.6), BLOUSE)
    c.add(ell(12.5, 37, 1.6, 1.4), SKIN)
    c.add(ell(31.5, 37, 1.6, 1.4), SKIN)
    # пояс
    c.add(rect(16, 35, 28, 36), BELT)
    # шея
    c.add(rect(20, 26, 24, 28), SKIN, tone_bias=1)
    # пучок на макушке
    c.add(ell(22, 3.8, 3.4, 3.2, p=2.0), "#c49a68")
    # масса волос головы
    c.add(ell(22, 16.0, 13.6, 11.6, p=2.4), HAIR)
    # лицо
    c.add(ell(22, 19.5, 9.8, 7.6, p=2.3), SKIN)
    # чёлка с прядками (зубчатый низ)
    bang = [(10, 10), (22, 6), (34, 10), (33, 14), (31, 12), (30, 15), (28, 12), (26, 15), (24, 12),
            (22, 14), (20, 12), (18, 15), (16, 12), (14, 15), (13, 12), (11, 14)]
    c.add(poly(bang), HAIR)
    # пряди по бокам лица, до груди
    c.add(tube([(11.5, 12), (10.8, 22), (12, 29)], 3.0, 1.4), HAIR)
    c.add(tube(mir([(11.5, 12), (10.8, 22), (12, 29)]), 3.0, 1.4), HAIR)

    hair_t, _ = ramp(HAIR)
    # прядки на волосах: линии тени
    for x, y in [(17, 7), (16, 8), (27, 7), (28, 8), (22, 9), (22, 10)]:
        c.mark(x, y, hair_t[3])
    for x, y in [(19, 7), (25, 7)]:
        c.mark(x, y, hair_t[0])
    # пучок: перевязка бантиком
    c.mark(20, 6, "#3e8f86"); c.mark(21, 6, "#5fc0b2"); c.mark(22, 6, "#2f7a72"); c.mark(23, 6, "#5fc0b2"); c.mark(24, 6, "#3e8f86")

    # глаза 4x5: ресницы, радужка (тёмная сверху -> светлая снизу), блик
    LASH, IR0, IR1, IR2, IR3, HI = "#4e2434", "#6a2a3a", "#9a4448", "#c86a54", "#eaa070", "#fffaf2"
    for ex, side in ((15, -1), (26, 1)):
        if blink:
            for x in range(ex, ex + 4):
                c.mark(x, 21, LASH)
            c.mark(ex - 1 if side < 0 else ex + 4, 20, LASH)
            continue
        out = ex - 1 if side < 0 else ex + 4
        for x in range(ex, ex + 4):
            c.mark(x, 17, LASH)
        c.mark(out, 17, LASH)        # хвостик ресниц наружу-вверх
        pat = ["HH00", "H001", "1001", "2222", "3332"]       # блик всегда сверху-слева
        cols = {"H": HI, "0": IR0, "1": IR1, "2": IR2, "3": IR3}
        for dy, row in enumerate(pat):
            r = row if side < 0 else row  # блик слева у обоих глаз (свет сверху-слева)
            for dx, ch in enumerate(r):
                c.mark(ex + dx, 18 + dy, cols[ch])
        c.mark(ex + 3, 21, HI)                                # малый блик снизу-справа
    # брови-чёрточки под чёлкой не видно; румянец, нос, ротик
    for x in (14, 15, 29, 30):
        c.mark(x, 24, "#f4a6a0")
    c.mark(22, 23, "#ecbca8")
    c.mark(21, 25, "#c46058"); c.mark(22, 25, "#d87068")

    # бантик на вороте
    bow_t, bow_o = ramp(BOW)
    for x, y, t in [(20, 28, 1), (21, 29, 2), (22, 29, 3), (23, 29, 2), (24, 28, 1), (20, 29, 2), (24, 29, 3),
                    (21, 30, 3), (23, 30, 3)]:
        c.mark(x, y, bow_t[t])
    c.mark(22, 29, bow_o[0])
    # пряжка
    c.mark(22, 35, "#f0c860"); c.mark(22, 36, "#c89a40")
    # кайма юбки и манжеты бирюзой
    sk_t, _ = ramp(BOW)
    for x in range(14, 31):
        c.mark(x, 40, sk_t[2] if x % 2 else sk_t[1])
    # шнуровка ботинок
    for y in (48, 49):
        c.mark(19, y, "#c89a6a"); c.mark(25, y, "#c89a6a")
    # мешочек с травами на поясе (справа)
    c.add(ell(28.5, 38, 1.8, 2.0), "#a8844e")
    c.mark(28, 35, "#6fae4a"); c.mark(29, 34, "#8ccc5c"); c.mark(27, 35, "#5a9a3e")
    return c.render()


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    img = draw()
    img.save(os.path.join(OUT, "hero_chibi.png"))
    up(img, 8).save(os.path.join(OUT, "hero_chibi_x8.png"))
    bl = draw(blink=True)
    bl.save(os.path.join(OUT, "hero_chibi_blink.png"))
    print("ok", os.path.abspath(OUT))
