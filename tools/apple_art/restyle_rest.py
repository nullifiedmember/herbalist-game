# -*- coding: utf-8 -*-
"""Перекраска в стиль яблока ВСЕГО, что осталось в game/art после 14 тем бестиария
(герой, лица, коты, деревья/трава, камни, здания, обстановка, интерфейс и т.д.).

Запуск:  python restyle_rest.py            — все группы
         python restyle_rest.py hero cats   — только эти группы
         python restyle_rest.py --list      — показать, что в какую группу попадёт
Выход:   C:/Claude/herbalist_game/art_apple/<группа>/ — те же имена, что в game/art
         C:/Claude/herbalist_game/art_apple/<группа>_compare.png — было / стало
Старые картинки игры не трогаются. Уже сделанное в art_apple (по имени файла) пропускается.
"""
import os, re, sys
from multiprocessing import Pool
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import restyle
from PIL import Image, ImageDraw

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
ROOT = os.path.abspath(os.path.join(GAME, "..", "art_apple"))

GROUPS = {
    "hero": "player hero hand bust",
    "faces": "faces",
    "cats": "cat26 cat",
    "creatures": "swim villager spider bat mimic",
    "nature": ("herbw sapling tree grass leaf leafw flowers flower bush willow pine palm trunk24 stump "
               "logpile24 reeds cattails bamboo wheat coral kelp mushrooms rose driftwood shell pearl "
               "anemone branch log hay bog swamp sea seabed tide beach puddle web cocoon egg giant koi dead"),
    "stones": "ore18 rock18 node ore rock crystal stone iron cliff cave",
    "buildings": ("house shop tavern palace prison pr18 mine st10 st stall town base shelter tent warehouse "
                  "bakery observatory crypt grave well torii pier palisade fence tilt outhouse goth jp w20 wt "
                  "world live realm dun room interior alch ground boundary plot pony elf goblin dwarf orc mage knight hermit"),
    "ui": "ui inv fx need hp price ord wind glow light bubble pour star moon coin magic poo dp",
}
TOKEN = {t: g for g, s in GROUPS.items() for t in s.split()}
ORDER = list(GROUPS) + ["props"]


OVERRIDE = {"spider_nest.png": "nature"}
SKIP = ("wind_",)  # маски ветра — это данные, не рисунок


def group_of(f):
    if f in OVERRIDE:
        return OVERRIDE[f]
    m = re.match(r"[a-z]+\d*", f)
    return TOKEN.get(m.group(0) if m else "", "props")


def todo():
    done = set()
    for dp, _, fs in os.walk(ROOT):
        done |= {f for f in fs if f.endswith(".png")}
    res = {}
    for f in sorted(os.listdir(ART)):
        if f.endswith(".png") and f not in done and not f.startswith(SKIP):
            res.setdefault(group_of(f), []).append(f)
    return res


def work(args):
    g, f = args
    out = os.path.join(ROOT, g, f)
    if not os.path.exists(out):
        restyle(Image.open(os.path.join(ART, f))).save(out)
    return f


def thumb(im, f, box=96):
    if f.startswith("player") or f.startswith("swim"):
        fw = 80 if f.startswith("player") else min(im.width, im.height)
        im = im.crop((0, 0, min(fw, im.width), min(160, im.height)))
    bb = im.getbbox()
    if bb:
        im = im.crop(bb)
    k = min(box / im.width, box / im.height)
    if k >= 2:
        k = int(min(k, 4))
        return im.resize((im.width * k, im.height * k), Image.NEAREST)
    if k < 1:
        return im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.BOX)
    return im


def compare(g, files):
    box = 96
    cw, ch = box * 2 + 12, box + 18
    cols = max(1, min(len(files), 2400 // cw))
    per = cols * 12
    for page in range(0, len(files), per):
        part = files[page:page + per]
        rows = (len(part) + cols - 1) // cols
        sheet = Image.new("RGBA", (cols * cw, rows * ch), (246, 241, 230, 255))
        d = ImageDraw.Draw(sheet)
        for n, f in enumerate(part):
            a = Image.open(os.path.join(ART, f)).convert("RGBA")
            b = Image.open(os.path.join(ROOT, g, f)).convert("RGBA")
            ta, tb = thumb(a, f, box), thumb(b, f, box)
            x = (n % cols) * cw; y = (n // cols) * ch
            sheet.alpha_composite(ta, (x + 2, y + 2))
            sheet.alpha_composite(tb, (x + box + 8, y + 2))
            d.text((x + 2, y + ch - 14), f[:-4][:30], fill=(60, 40, 40, 255))
        suf = "" if page == 0 else "_%d" % (page // per + 1)
        sheet.save(os.path.join(ROOT, "%s_compare%s.png" % (g, suf)))


if __name__ == "__main__":
    groups = todo()
    args = sys.argv[1:]
    if args == ["--list"]:
        for g in ORDER:
            fs = groups.get(g, [])
            print(g, len(fs), " ".join(fs[:12]), "..." if len(fs) > 12 else "")
        sys.exit()
    sel = args or ORDER
    jobs, plan = [], {}
    for g in sel:
        fs = groups.get(g, [])
        plan[g] = fs
        os.makedirs(os.path.join(ROOT, g), exist_ok=True)
        jobs += [(g, f) for f in fs]
    # большие листы — первыми, чтобы процессы не простаивали в конце
    jobs.sort(key=lambda j: -os.path.getsize(os.path.join(ART, j[1])))
    with Pool(max(1, (os.cpu_count() or 2) - 1)) as pool:
        for i, f in enumerate(pool.imap_unordered(work, jobs), 1):
            if i % 50 == 0:
                print(i, "/", len(jobs), flush=True)
    for g, fs in plan.items():
        if fs:
            compare(g, fs)
            print(g, len(fs), "файлов")
