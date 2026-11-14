# -*- coding: utf-8 -*-
"""Перекраска целой темы игры в стиль яблока (форма и детали те же).

Запуск:  python restyle_theme.py shrooms potions food ...   (или all)
Выход:   C:/Claude/herbalist_game/art_apple/<тема>/  — те же имена файлов, что в game/art
         C:/Claude/herbalist_game/art_apple/<тема>_compare_x4.png — было / стало
Старые картинки игры не трогаются.
"""
import os, re, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import restyle, up
from PIL import Image, ImageDraw

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
ROOT = os.path.abspath(os.path.join(GAME, "..", "art_apple"))


def by_prefix(pre, exclude=()):
    return sorted(f for f in os.listdir(ART) if f.startswith(pre) and f.endswith(".png") and not any(f.startswith(e) for e in exclude))


def gd(name):
    return open(os.path.join(GAME, name), encoding="utf-8").read()


def people():
    src = gd("npc_db.gd")
    body = src[src.index("const PEOPLE: Dictionary = {"):]
    body = body[:body.index("\n}")]
    keys = re.findall(r'^\s*"([a-z0-9_]+)"\s*:', body, re.M)
    return [k + ".png" for k in keys if os.path.exists(os.path.join(ART, k + ".png"))]


def mats():
    src = gd("mats_db.gd")
    tex = set(re.findall(r'^\s*"[a-z0-9_]+"\s*:\s*\[[^\]]*?,[^\]]*?,[^\]]*?,\s*"([a-z0-9_]+)"', src, re.M))
    files = {t + ".png" for t in tex if os.path.exists(os.path.join(ART, t + ".png"))}
    files |= set(by_prefix("icon_", exclude=("icon_feather_",)))
    return sorted(files)


def furniture():
    src = gd("v23_data.gd")
    tex = set(re.findall(r'"tex":\s*"([a-z0-9_]+)"', src))
    return sorted(t + ".png" for t in tex if os.path.exists(os.path.join(ART, t + ".png")))


# тема: (список файлов, сколько кадров по ширине, по высоте)
THEMES = {
    "shrooms":  (lambda: by_prefix("shroom_"), 1, 1),
    "potions":  (lambda: by_prefix("potion_"), 1, 1),
    "food":     (lambda: by_prefix("food_"), 1, 1),
    "animals":  (lambda: by_prefix("animal_"), 12, 1),
    "birds":    (lambda: by_prefix("bird_"), 12, 1),
    "feathers": (lambda: by_prefix("icon_feather_"), 1, 1),
    "fish":     (lambda: by_prefix("fish_"), 1, 1),
    "insects":  (lambda: ["insects.png"], 1, 1),
    "monsters": (lambda: by_prefix("mon_"), 4, 1),
    "people":   (people, 8, 8),
    "mats":     (mats, 1, 1),
    "weapons":  (lambda: by_prefix("gear_"), 1, 1),
    "spells":   (lambda: by_prefix("orb25_"), 1, 1),
    "furniture": (furniture, 1, 1),
}
ORDER = ["shrooms", "potions", "food", "animals", "birds", "feathers", "fish", "insects",
         "monsters", "people", "mats", "weapons", "spells", "furniture"]


def first_frame(im, fx, fy):
    if fx == 1 and fy == 1:
        return im
    w, h = im.width // fx, im.height // fy
    return im.crop((0, 0, w, h))


def run(theme):
    get, fx, fy = THEMES[theme]
    files = get()
    out = os.path.join(ROOT, theme)
    os.makedirs(out, exist_ok=True)
    for f in files:
        restyle(Image.open(os.path.join(ART, f))).save(os.path.join(out, f))
    # сравнение
    pairs = []
    for f in files:
        a = first_frame(Image.open(os.path.join(ART, f)).convert("RGBA"), fx, fy)
        b = first_frame(Image.open(os.path.join(out, f)).convert("RGBA"), fx, fy)
        bb = a.getbbox()
        if bb:
            a, b = a.crop(bb), b.crop(bb)
        pairs.append((f[:-4], a, b))
    cw = max(p[1].width for p in pairs) * 2 + 8
    ch = max(p[1].height for p in pairs) + 12
    k = 4 if cw * 4 < 900 else 2
    cols = max(1, min(len(pairs), 2400 // (cw * k)))
    rows = (len(pairs) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * cw * k, rows * ch * k), (246, 241, 230, 255))
    d = ImageDraw.Draw(sheet)
    for n, (name, a, b) in enumerate(pairs):
        x = (n % cols) * cw * k; y = (n // cols) * ch * k
        sheet.alpha_composite(up(a, k), (x + k, y + k))
        sheet.alpha_composite(up(b, k), (x + (a.width + 4) * k, y + k))
        d.text((x + k, y + (ch - 10) * k), name[:22], fill=(60, 40, 40, 255))
    sheet.save(os.path.join(ROOT, theme + "_compare_x%d.png" % k))
    print(theme, len(files), "файлов")
    return len(files)


if __name__ == "__main__":
    args = sys.argv[1:] or ["all"]
    for t in (ORDER if args == ["all"] else args):
        run(t)
