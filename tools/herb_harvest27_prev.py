"""v27: травы для окна сбора (art/herbh_<id>.png): из значка травы (<id>_3.png или herb14_<id>.png)
убираются земля/песок под ней и отдельные пучки травинок у корня — растение растёт прямо из земли одним стеблем.
python tools/herb_harvest27.py [папка-превью]"""
import os, sys, glob
from PIL import Image
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import herb_world24 as hw

ART = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "art")


def is_sand(c):
    r, g, b, a = c
    return a > 0 and r > 170 and g > 140 and b < g - 10 and r >= g


def clean(src):
    im = Image.open(src).convert("RGBA")
    w, h = im.size
    px = im.load()
    y0 = h - int(h * 0.30)
    for y in range(y0, h):
        for x in range(w):
            if hw.is_soil(px[x, y]) or is_sand(px[x, y]) or (px[x, y][3] < 128):
                px[x, y] = (0, 0, 0, 0)
    for _ in range(2):
        rm = []
        for y in range(y0, h):
            for x in range(w):
                if not hw.is_dark(px[x, y]):
                    continue
                if not any(0 <= x + dx < w and 0 <= y + dy < h and px[x + dx, y + dy][3] > 0 and not hw.is_dark(px[x + dx, y + dy])
                           for dx, dy in ((1, 0), (-1, 0), (0, -1), (0, 1))):
                    rm.append((x, y))
        for q in rm:
            px[q] = (0, 0, 0, 0)
    # связные кусочки: маленькие у самого низа — пучки травинок, убрать
    low = max([y for y in range(h) for x in range(w) if px[x, y][3] > 0] or [0])
    seen = set()
    parts = []
    for yy in range(h):
        for xx in range(w):
            if (xx, yy) in seen or px[xx, yy][3] == 0:
                continue
            st = [(xx, yy)]; seen.add((xx, yy)); part = []
            while st:
                c = st.pop(); part.append(c)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        n = (c[0] + dx, c[1] + dy)
                        if 0 <= n[0] < w and 0 <= n[1] < h and n not in seen and px[n][3] > 0:
                            seen.add(n); st.append(n)
            parts.append(part)
    big = max(len(p) for p in parts) if parts else 0
    for part in parts:
        top = min(c[1] for c in part)
        if len(part) < big and len(part) < 45 and top >= low - 8:
            for c in part:
                px[c] = (0, 0, 0, 0)
    finish_bottom(im)
    drop_crumbs(im)
    return im


def drop_crumbs(im):
    """Крошки — кусочки до 6 пикселей, не связанные с растением: убрать."""
    w, h = im.size
    px = im.load()
    seen = set()
    parts = []
    for yy in range(h):
        for xx in range(w):
            if (xx, yy) in seen or px[xx, yy][3] == 0:
                continue
            st = [(xx, yy)]; seen.add((xx, yy)); part = []
            while st:
                c = st.pop(); part.append(c)
                for dy in (-1, 0, 1):
                    for dx in (-1, 0, 1):
                        n = (c[0] + dx, c[1] + dy)
                        if 0 <= n[0] < w and 0 <= n[1] < h and n not in seen and px[n][3] > 0:
                            seen.add(n); st.append(n)
            parts.append(part)
    big = max(len(p) for p in parts) if parts else 0
    low = max((c[1] for p in parts for c in p), default=0)
    for part in parts:
        if len(part) < big and len(part) <= 6 and min(c[1] for c in part) >= low - 10:
            for c in part:
                px[c] = (0, 0, 0, 0)


def finish_bottom(im):
    """Низ растения: убрать рваные остатки (травинки/корешки) и докруглить срезанные листья кончиками вниз."""
    w, h = im.size
    px = im.load()

    def cnt(y):
        return sum(1 for x in range(w) if px[x, y][3] > 0)

    rows = [y for y in range(h) if cnt(y) > 0]
    if not rows:
        return
    low = rows[-1]
    # рваные нижние строки: заметно меньше пикселей, чем строкой выше
    while low > rows[0] + 4 and cnt(low) < cnt(low - 1) * 0.6:
        for x in range(w):
            px[x, low] = (0, 0, 0, 0)
        low -= 1
    # одиночные пиксели в нижней строке без опоры сверху
    for x in range(w):
        if px[x, low][3] > 0 and px[x, low - 1][3] == 0:
            px[x, low] = (0, 0, 0, 0)
    # цвет контура — самый частый тёмный
    darks = {}
    for y in range(h):
        for x in range(w):
            c = px[x, y]
            if c[3] > 0 and sum(c[:3]) < 170:
                darks[c] = darks.get(c, 0) + 1
    ol = max(darks, key=darks.get) if darks else (34, 58, 30, 255)
    # отрезки нижней строки; широкие (листья) — дорисовать кончики вниз
    runs = []
    x = 0
    while x < w:
        if px[x, low][3] > 0:
            x0 = x
            while x < w and px[x, low][3] > 0:
                x += 1
            runs.append((x0, x - 1))
        x += 1
    for a, b in runs:
        width = b - a + 1
        if width < 5:
            continue   # стебель — уходит в землю как есть
        n = max(1, round(width / 6.0))
        seg = width / n
        for k in range(n):
            sa = a + int(round(k * seg))
            sb = a + int(round((k + 1) * seg)) - 1
            for d in (1, 2):
                y = low + d
                if y >= h:
                    break
                xa, xb = sa + d, sb - d
                if xb < xa:
                    break
                for xx in range(xa, xb + 1):
                    src = px[xx, low]
                    if sum(src[:3]) < 170:   # над ним контур — взять цвет листа из строки выше
                        src = px[xx, low - 1] if sum(px[xx, low - 1][:3]) >= 170 else (src[0] + 40, src[1] + 60, src[2] + 30, 255)
                    edge = xx == xa or xx == xb or d == 2 or xb - xa < 2
                    if edge:
                        px[xx, y] = ol
                    else:
                        f = 0.88
                        px[xx, y] = (int(src[0] * f), int(src[1] * f), int(src[2] * f), 255)
            # бока кончика в строке low — контур, чтобы кончики читались отдельно
            if n > 1 and k > 0:
                px[sa, low] = ol


def ids():
    out = {}
    for f in glob.glob(os.path.join(ART, "herb14_*.png")):
        out[os.path.basename(f)[7:-4]] = f
    for f in glob.glob(os.path.join(ART, "*_3.png")):
        hid = os.path.basename(f)[:-6]
        if os.path.exists(os.path.join(ART, "herbw_%s.png" % hid)) or hid in out:
            out[hid] = f
    return out


if __name__ == "__main__":
    prev = sys.argv[1] if len(sys.argv) > 1 else None
    todo = sorted(ids().items())
    if prev:
        sc, cols = 4, 12
        sheet = Image.new("RGBA", (cols * 34 * sc, ((len(todo) + cols - 1) // cols) * 50 * sc), (230, 220, 200, 255))
    for k, (hid, src) in enumerate(todo):
        im = clean(src)
        if im.size != (32, 48):
            continue
        if prev:
            sheet.alpha_composite(im.resize((32 * sc, 48 * sc), Image.NEAREST), ((k % cols) * 34 * sc, (k // cols) * 50 * sc))
        else:
            im.save(os.path.join(ART, "herbh_%s.png" % hid))
    if prev:
        sheet.save(os.path.join(prev, "herbh_preview.png"))
    print("ok", len(todo))
