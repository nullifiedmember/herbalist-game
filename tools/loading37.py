# Экран загрузки v37: значок «котёл кипит» (8 кадров) в стиле яблока + картинка для boot splash.
# Запуск (из папки game):  python -I tools/loading37.py
# Пишет: art/load37_pot.png (лист 8 кадров по 56x56, пиксель x1; в игре scale 3),
#        art/load37_splash.png (1920x1080: вечерний фон меню + котёл — заставка при запуске exe),
#        tools/_load37_pot_x8.png (крупное превью на прозрачном фоне).
import math, os, sys
sys.path.insert(0, os.path.expanduser("~/.claude/skills/apple-pixel-style/scripts"))
from apple_engine import Canvas, ell, tube, rect, poly, up, hx
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ART = os.path.join(HERE, "..", "art")
W, H, N = 56, 64, 8


def frame(f):
    c = Canvas(W, H)
    ph = f / N
    # --- дрова
    c.add(tube([(13, 59), (28, 56), (43, 59)], 2.4), "#9a6a48")
    c.add(tube([(15, 56), (28, 60), (41, 56)], 2.2), "#b07a52")
    # --- ножки котла
    c.add(tube([(18, 38), (15, 50)], 1.7, 1.2), "#5e5470")
    c.add(tube([(38, 38), (41, 50)], 1.7, 1.2), "#5e5470")
    # --- котёл (выше огня)
    c.add(ell(28, 33, 15, 10, p=2.2), "#6e6488", shine=True)
    c.add(tube([(11, 24), (28, 26), (45, 24)], 2.6), "#867ca0")       # ободок
    # --- огонь под котлом: языки качаются
    for i, (x, hgt, col) in enumerate([(20, 10, "#e8743c"), (36, 10, "#e8743c"), (28, 13, "#f0a040")]):
        k = math.sin((ph + i * 0.33) * 2 * math.pi)
        hh = hgt + k * 2
        c.add(tube([(x, 57), (x + k * 1.5, 57 - hh * 0.55), (x - k * 1.5, 57 - hh)], 3.4, 0.3, profile="drop"),
              col, outline=False)
    for i, x in enumerate((24, 32)):
        k = math.sin((ph + i * 0.5) * 2 * math.pi)
        c.add(tube([(x, 57), (x + k, 53), (x - k, 49 + k)], 2.0, 0.2, profile="drop"), "#f8d878", outline=False)
    # --- зелье: зелёная гладь, чуть колышется
    k = math.sin(ph * 2 * math.pi)
    c.add(ell(28, 23.5 + k * 0.4, 14, 3.0), "#7ccf78", outline=False)
    c.mark(22, 23, "#b8eea0"); c.mark(23, 23, "#b8eea0"); c.mark(33, 24, "#b8eea0")
    # --- пузырьки: маленькие, поднимаются и лопаются
    for i, (bx, sp) in enumerate([(21, 0.0), (29, 0.37), (35, 0.7), (25, 0.55)]):
        t = (ph + sp) % 1.0
        y = 22 - t * 13
        r = 1.0 + t * 1.0
        if t < 0.8:
            c.add(ell(bx + math.sin(t * 6 + i) * 1.2, y, r, r), "#9edc8c", shine=True)
        else:
            for dx, dy in ((-2, 0), (2, 0), (0, -2)):
                c.spark(int(bx + dx), int(y + dy), "#d8f8c0")
    # --- листик-травка кружится над котлом
    a = ph * 2 * math.pi
    lx, ly = 28 + math.cos(a) * 14, 8 + math.sin(a) * 3
    tip = (lx + math.cos(a + 1.2) * 4, ly + math.sin(a + 1.2) * 2.5 - 1)
    c.add(tube([(lx, ly), ((lx + tip[0]) / 2, (ly + tip[1]) / 2 - 1), tip], 2.2, 0.3, profile="leaf"), "#5fae58")
    # --- искорки от огня (сбоку от котла)
    for i in range(2):
        t = (ph * 2 + i * 0.5) % 1.0
        c.spark(int(8 + i * 40 + math.sin(t * 7) * 2), int(54 - t * 12), "#ffe8a0")
    return c.render()


def main():
    frames = [frame(f) for f in range(N)]
    sheet = Image.new("RGBA", (W * N, H), (0, 0, 0, 0))
    for i, im in enumerate(frames):
        sheet.paste(im, (i * W, 0))
    sheet.save(os.path.join(ART, "load37_pot.png"))
    up(sheet, 8).save(os.path.join(HERE, "_load37_pot_x8.png"))
    # gif для осмотра
    big = [up(im, 8) for im in frames]
    big[0].save(os.path.join(HERE, "_load37_pot.gif"), save_all=True, append_images=big[1:],
                duration=110, loop=0, disposal=2)
    # --- заставка exe: вечерний фон меню (2000x1120 -> 1920x1080) + котёл
    bg = Image.open(os.path.join(ART, "menu32_sky_dusk.png")).convert("RGBA")
    for f in ("far", "mid", "near", "front", "windows"):
        p = os.path.join(ART, "menu32_%s.png" % f)
        if os.path.exists(p):
            bg.alpha_composite(Image.open(p).convert("RGBA"))
    bg = up(bg, 2).crop((40, 20, 40 + 1920, 20 + 1080))
    # мягкое затемнение снизу, чтобы надпись читалась
    shade = Image.new("RGBA", bg.size, (0, 0, 0, 0))
    px = shade.load()
    for y in range(700, 1080):
        a = int(150 * ((y - 700) / 380) ** 1.5)
        for x in range(1920):
            px[x, y] = (40, 26, 52, a)
    bg.alpha_composite(shade)
    pot = up(frames[0], 3)
    bg.alpha_composite(pot, (960 - pot.width // 2, 780))
    bg.convert("RGB").save(os.path.join(ART, "load37_splash.png"))
    print("ok: load37_pot.png, load37_splash.png")


if __name__ == "__main__":
    main()
