"""Дорисовывает новым жительницам вещи поверх готовых листов (80x160, 8 ракурсов x 8 кадров):
охотницам — треуголку, авантюристкам — меч за спиной и посох, оркам — рогатый шлем,
гоблинше — кривой колпак, дворфихе — шахтёрскую каску со свечой.
Запуск из папки game:  python tools/accessorize.py   (после art_gen --only=gothic/knights/orcs/dwarves)
Голову находит сам: по верхнему краю силуэта в каждом кадре.
"""
from PIL import Image, ImageDraw
import os

ART = os.path.join(os.path.dirname(__file__), "..", "art")
OUT = (29, 26, 46, 255)      # тёмный контур, как у зверей и персонажей


def head(cell):
    a = cell.split()[3]
    bb = a.getbbox()
    top = bb[1]
    xs = [x for x in range(cell.width) for y in range(top + 6, top + 16) if a.getpixel((x, y)) > 128]
    return top, (min(xs) + max(xs)) / 2.0, max(xs) - min(xs)


def ell(d, cx, cy, rx, ry, fill):
    d.ellipse([cx - rx, cy - ry, cx + rx, cy + ry], fill=fill, outline=OUT)


def tricorn(d, cx, top, w, row):
    side = row in (2, 3)
    brim_w = 22 if not side else 19
    y = top + 15
    ell(d, cx, y, brim_w, 4.5, (42, 34, 40, 255))
    d.rectangle([cx - 13, top + 1, cx + 13, y - 2], fill=(48, 38, 46, 255), outline=OUT)
    d.line([cx - 12, top + 3, cx + 12, top + 3], fill=(70, 58, 66, 255))
    if not side:
        # загнутые края треуголки
        d.polygon([(cx - brim_w, y), (cx - brim_w + 3, y - 10), (cx - 8, y - 2)], fill=(36, 28, 34, 255), outline=OUT)
        d.polygon([(cx + brim_w, y), (cx + brim_w - 3, y - 10), (cx + 8, y - 2)], fill=(36, 28, 34, 255), outline=OUT)
    d.line([cx - 13, y - 4, cx + 13, y - 4], fill=(150, 120, 70, 255), width=2)   # лента


def horned(d, cx, top, w, row):
    y = top + 14
    d.pieslice([cx - 16, top + 1, cx + 16, y + 12], 180, 360, fill=(110, 110, 120, 255), outline=OUT)
    d.line([cx - 16, y + 5, cx + 16, y + 5], fill=(70, 70, 80, 255), width=3)
    if row not in (2, 3):
        d.polygon([(cx - 14, y), (cx - 26, y - 12), (cx - 19, y + 1)], fill=(236, 226, 206, 255), outline=OUT)
        d.polygon([(cx + 14, y), (cx + 26, y - 12), (cx + 19, y + 1)], fill=(236, 226, 206, 255), outline=OUT)
    else:
        d.polygon([(cx + 4, y), (cx + 16, y - 13), (cx + 11, y)], fill=(236, 226, 206, 255), outline=OUT)


def rag_hat(d, cx, top, w, row):
    y = top + 14
    ell(d, cx, y, 17, 3.6, (96, 76, 46, 255))
    d.polygon([(cx - 12, y - 1), (cx + 11, y - 1), (cx + 20, top), (cx + 4, top + 3)], fill=(112, 90, 54, 255), outline=OUT)
    d.rectangle([cx - 6, y - 7, cx - 2, y - 3], fill=(160, 80, 60, 255))  # заплатка


def miner(d, cx, top, w, row):
    y = top + 14
    d.pieslice([cx - 16, top + 3, cx + 16, y + 12], 180, 360, fill=(200, 160, 50, 255), outline=OUT)
    d.line([cx - 17, y + 5, cx + 17, y + 5], fill=(150, 110, 30, 255), width=3)
    if row not in (1, 5, 7):
        d.rectangle([cx - 3, top, cx + 3, top + 7], fill=(240, 236, 220, 255), outline=OUT)
        d.rectangle([cx - 1, top, cx + 1, top + 1], fill=(255, 200, 80, 255))


def sword_back(d, cx, top, w, row):
    # рукоять меча над левым плечом (на виде сзади — весь меч)
    if row in (1, 5, 7):
        d.line([cx - 10, top + 30, cx + 10, top + 90], fill=(200, 204, 216, 255), width=3)
        d.line([cx - 14, top + 34, cx - 6, top + 28], fill=(200, 160, 50, 255), width=2)
    else:
        d.line([cx + 12, top + 28, cx + 16, top + 18], fill=(80, 50, 30, 255), width=3)
        d.line([cx + 9, top + 29, cx + 17, top + 25], fill=(200, 160, 50, 255), width=2)


def staff(d, cx, top, w, row):
    x = cx + 17 if row not in (2,) else cx - 14
    if row in (1, 5, 7):
        x = cx - 17
    d.line([x, top + 22, x, top + 150], fill=(96, 64, 36, 255), width=3)
    ell(d, x, top + 18, 4, 4, (110, 170, 255, 255))
    d.point((x - 1, top + 16), fill=(230, 245, 255, 255))


TAIL_COL = {
    "fishgirl_marina": [(40, 110, 130), (60, 150, 170), (90, 190, 200), (150, 225, 230)],
    "fishgirl_koral": [(150, 50, 70), (200, 80, 90), (235, 125, 120), (250, 180, 170)],
    "fishgirl_perla": [(70, 90, 150), (100, 130, 190), (150, 180, 225), (210, 225, 245)],
    "fishgirl_tida": [(30, 100, 70), (50, 140, 100), (90, 185, 140), (160, 225, 190)],
}


def fish_tail(d, cx, top, w, row, cell=None, frame=0, name=""):
    """Рыбий хвост вместо ног: качается из кадра в кадр, чешуйки, плавник."""
    col = TAIL_COL.get(name, TAIL_COL["fishgirl_marina"])
    sway = [0, 2, 0, -2, 0, 1, 2, 1][frame % 8]
    side = row in (2, 3, 4, 6)
    y0 = top + 96
    for y in range(y0, top + 148):
        t = (y - y0) / 52.0
        half = 10.0 * (1.0 - t) + 2.5
        x = cx + sway * t * 3 + (t * t * 10 * (1 if row in (3, 6) else -1) if side else 0)
        for xx in range(int(x - half), int(x + half) + 1):
            k = 2 if xx < x else 1
            if (xx + y) % 4 == 0:
                k = 3
            d.point((xx, y), fill=col[k] + (255,))
        d.point((int(x - half) - 1, y), fill=OUT)
        d.point((int(x + half) + 1, y), fill=OUT)
    fx = cx + sway * 3 + ((10 * (1 if row in (3, 6) else -1)) if side else 0)
    fy = top + 148
    d.polygon([(fx, fy - 2), (fx - 14, fy + 9), (fx - 4, fy + 6), (fx, fy + 10), (fx + 4, fy + 6), (fx + 14, fy + 9)], fill=col[2] + (255,), outline=OUT)


def kitsune_tail(d, cx, top, w, row, cell=None, frame=0, name=""):
    """Пушистый лисий хвост с белым кончиком поверх тонкого кошачьего."""
    sway = [0, 1, 0, -1, 0, 1, 1, 0][frame % 8]
    base = (cx + (8 if row in (0, 4, 6) else 0), top + 100)
    fur = {"kitsune_sakura": (230, 140, 70), "kitsune_hana": (240, 225, 210), "kitsune_aka": (60, 52, 66), "kitsune_kuro": (120, 80, 50)}.get(name, (230, 140, 70))
    side = 1 if row in (0, 3, 4, 6, 7) else -1
    tx = cx + side * 13 + sway
    ty = top + 84
    d.ellipse([tx - 8, ty - 14, tx + 8, ty + 14], fill=fur + (255,), outline=OUT)
    d.ellipse([tx + side * 2 - 5, ty + 5, tx + side * 2 + 5, ty + 14], fill=(255, 250, 244, 255), outline=OUT)


JOBS = {
    "hunter_vesna": tricorn, "hunter_morra": tricorn,
    "orc_brakka": horned, "goblin_snik": rag_hat, "dwarf_ingrid": miner,
    "adv_rina": sword_back, "adv_elma": staff,
    # кицунэ и русалки (v13) рисуются целиком в art_gen --only=v13p — здесь их больше нет
}


def main():
    for name, fn in JOBS.items():
        path = os.path.join(ART, name + ".png")
        base = os.path.join(ART, "..", "tools", "accessorize_base", name + ".png")
        os.makedirs(os.path.dirname(base), exist_ok=True)
        # чистый лист без вещей храним отдельно: повторный запуск не рисует шляпу дважды
        if not os.path.exists(base) or os.path.getmtime(path) > os.path.getmtime(base):
            Image.open(path).save(base)
        sheet = Image.open(base).convert("RGBA")
        fw, fh = 80, 160
        rows = sheet.height // fh
        for r in range(rows):
            for f in range(sheet.width // fw):
                box = (f * fw, r * fh, f * fw + fw, r * fh + fh)
                cell = sheet.crop(box)
                if cell.split()[3].getbbox() is None:
                    continue
                top, cx, w = head(cell)
                # вещи на спине рисуем под телом, остальное — поверх
                layer = Image.new("RGBA", cell.size)
                if fn is fish_tail:
                    # ноги убираем: ниже пояса — только хвост
                    px = cell.load()
                    for yy in range(top + 100, cell.height):
                        for xx in range(cell.width):
                            px[xx, yy] = (0, 0, 0, 0)
                if fn in (fish_tail, kitsune_tail):
                    fn(ImageDraw.Draw(layer), cx, top, w, r, cell, f, name)
                else:
                    fn(ImageDraw.Draw(layer), cx, top, w, r)
                if (fn in (sword_back,) and r not in (1, 5, 7)) or (fn is kitsune_tail and r in (0, 2, 3, 4, 6)):
                    out = Image.alpha_composite(layer, cell)
                else:
                    out = Image.alpha_composite(cell, layer)
                sheet.paste(out, box)
        sheet.save(path)
        os.utime(base)   # чистая копия «новее» украшенного листа — пока art_gen не перерисует его
        print("ok", name)


if __name__ == "__main__":
    main()
