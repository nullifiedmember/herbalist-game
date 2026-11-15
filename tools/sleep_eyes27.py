"""Закрытые глаза у спящих кроликов/зайцев (кадры сна 10-11 листа зверя).
Тёмные пиксели глаза (внутри головы, не контур) закрашиваются мехом,
нижний ряд глаза становится тёмной «щёлочкой» цвета контура.
Запуск из папки game: python tools/sleep_eyes27.py [--preview out.png]"""
import sys
from PIL import Image

KINDS = ["rabbit", "brown_hare", "lop_rabbit", "jackalope"]
FRAMES = 12
SLEEP = [10, 11]


def lum(c):
    return 0.3 * c[0] + 0.59 * c[1] + 0.11 * c[2]


def comps(px, pts):
    """Связные группы пикселей."""
    left = set(pts)
    out = []
    while left:
        s = left.pop()
        st = [s]
        g = [s]
        while st:
            x, y = st.pop()
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                q = (x + d[0], y + d[1])
                if q in left:
                    left.remove(q)
                    st.append(q)
                    g.append(q)
        out.append(g)
    return out


def fix_frame(im, fx, fw, h):
    px = im.load()
    dark = [(x, y) for y in range(h) for x in range(fx, fx + fw)
            if px[x, y][3] > 200 and lum(px[x, y]) < 60]
    # глаз: компактная тёмная группа 4..80 пикселей, со всех сторон окружённая мехом/телом
    eyes = []
    for g in comps(px, dark):
        if not 4 <= len(g) <= 80:
            continue
        xs = [p[0] for p in g]; ys = [p[1] for p in g]
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        if x1 - x0 > 10 or y1 - y0 > 10:
            continue
        ok = all(px[x, y][3] > 200 for x in range(x0 - 2, x1 + 3) for y in range(y0 - 2, y1 + 3))
        if ok:
            eyes.append((x0, x1, y0, y1))
    # звери смотрят влево: глаз — самая передняя такая группа
    eyes = sorted(eyes)[:1]
    for (x0, x1, y0, y1) in eyes:
        fur = px[x0, y0 - 2]
        # тёмный ободок глаза тоже закрашиваем
        for y in range(y0, y1 + 3):
            for x in range(x0, x1 + 1):
                c = px[x, y]
                if lum(c) < 100:
                    px[x, y] = fur
        line = (0x6e, 0x48, 0x5a, 255)
        by = y1 + 1 if y1 + 1 - y0 >= 3 else y1  # нижний край глаза
        by -= (by - y0 + 1) % 2  # по сетке 2x2
        for y in (by - 1, by):
            for x in range(x0 - 2, x1 + 1):
                px[x, y] = line
        # опущенный уголок спереди
        for y in (by + 1, by + 2):
            for x in (x0 - 2, x0 - 1):
                px[x, y] = line
    return len(eyes)


def run(path):
    im = Image.open(path).convert("RGBA")
    fw = im.width // FRAMES
    n = [fix_frame(im, f * fw, fw, im.height) for f in SLEEP]
    im.save(path)
    return n


if __name__ == "__main__":
    for k in KINDS:
        for suf in ("", "_baby"):
            p = "art/animal_%s%s.png" % (k, suf)
            print(p, run(p))
