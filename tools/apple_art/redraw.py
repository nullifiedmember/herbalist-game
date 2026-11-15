# -*- coding: utf-8 -*-
"""ПЕРЕРИСОВКА неживого в стиль яблока / обычного дерева игры (не просто перекраска).

Как рисует (для каждой картинки):
  1. делит картинку на «материалы» (дерево, камень, ткань, металл...) по цвету без учёта света;
  2. упрощает границы материалов (убирает мелкий шум — пятна становятся крупными, «рисованными»);
  3. каждому материалу строит новую тёплую рампу яблока (блик, свет, основа, тень, глубокая тень);
  4. заново кладёт свет: сверху-слева светлая кромка, снизу-справа тень, внутри 3 ступени
     (крупные пятна, как листва у дерева), старые тёмные линии -> цветные линии своего материала;
  5. внешний контур цветной (светлее сверху-слева, темнее снизу-справа), чёрного нет;
  6. на крупных округлых пятнах — блик, как у яблока.

Запуск:  python redraw.py test            — пробный лист на разных предметах
         python redraw.py nature props ... — группы из art_apple (берёт исходники из game/art)
Выход:   herbalist_game/art_apple_redraw/<группа>/ + <группа>_compare.png (было / перекраска / перерисовка)
"""
import os, sys, colorsys
import numpy as np
from scipy import ndimage
from PIL import Image, ImageDraw
from multiprocessing import Pool

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import _hsv, _rgb, _shift  # noqa: E402

_RC = {}


def ramp(base):
    """Рампа яблока, но мягче: оттенок тени чуть к сиреневому, без перекраски коричневого в красный."""
    if base in _RC:
        return _RC[base]
    h, s, v = _hsv(base)
    YEL, PUR = 0.14, 0.86
    a = 0.01          # коричневые/оранжевые почти не сдвигаем
    tones = [_rgb(_shift(h, YEL, a * 2), s * 0.45, min(1, v + 0.28)),
             _rgb(_shift(h, YEL, a), s * 0.85, min(1, v + 0.12)),
             base,
             _rgb(_shift(h, PUR, a), min(1, s * 1.03 + 0.02), v - 0.13),
             _rgb(_shift(h, PUR, a * 2), min(1, s * 1.05 + 0.04), v - 0.25)]
    vv = max(v, 0.35)
    outline = [_rgb(_shift(h, PUR, a * 2), min(1, s + 0.08), vv * 0.66),
               _rgb(_shift(h, PUR, a * 3), min(1, s + 0.12), vv * 0.51),
               _rgb(_shift(h, PUR, a * 4), min(1, s + 0.15), vv * 0.40)]
    _RC[base] = (tones, outline)
    return _RC[base]


def soften(c):
    h, s, v = _hsv(c)
    if v > 0.55:
        h = _shift(h, 0.14, 0.015); s *= 0.93; v = min(1, v * 1.04 + 0.02)
    else:
        s *= 0.95; v = v * 0.9 + 0.08
    return _rgb(h, s, v)

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
APPLE = os.path.abspath(os.path.join(GAME, "..", "art_apple"))
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple_redraw"))


def _feat(rgb):
    """Признаки цвета без учёта освещения: оттенок*насыщенность + немного яркости."""
    f = rgb.astype(np.float32) / 255.0
    mx, mn = f.max(1), f.min(1)
    v = mx
    s = np.where(mx > 1e-6, (mx - mn) / np.maximum(mx, 1e-6), 0)
    r, g, b = f[:, 0], f[:, 1], f[:, 2]
    h = np.arctan2(np.sqrt(3) * (g - b), 2 * r - g - b)
    w = np.clip(s * 2.2, 0, 1.4) * np.clip(v * 1.5, 0, 1)
    return np.stack([np.cos(h) * w, np.sin(h) * w, v * 0.5, s * 0.35], 1)


def _kmeans(X, k, it=12, seed=1):
    rng = np.random.default_rng(seed)
    if len(X) <= k:
        return np.arange(len(X)), X.copy()
    # k-means++
    C = [X[rng.integers(len(X))]]
    for _ in range(k - 1):
        d = np.min(((X[:, None, :] - np.array(C)[None]) ** 2).sum(2), 1)
        if d.sum() <= 0:
            break
        C.append(X[rng.choice(len(X), p=d / d.sum())])
    C = np.array(C)
    for _ in range(it):
        lab = np.argmin(((X[:, None, :] - C[None]) ** 2).sum(2), 1)
        for j in range(len(C)):
            m = lab == j
            if m.any():
                C[j] = X[m].mean(0)
    lab = np.argmin(((X[:, None, :] - C[None]) ** 2).sum(2), 1)
    return lab, C


def _mode_filter(lab, mask, n_lab, passes=2, C=None):
    """Сглаживание пятен: пиксель берёт самый частый материал вокруг (3x3)."""
    for _ in range(passes):
        cnt = np.zeros((n_lab,) + lab.shape, np.int16)
        for j in range(n_lab):
            cnt[j] = ndimage.uniform_filter(((lab == j) & mask).astype(np.float32), 3, mode="constant") * 9 + 0.01 * (lab == j)
        new = cnt.argmax(0)
        if C is not None:
            close = ((C[lab.clip(0)] - C[new]) ** 2).sum(-1) < 0.04
            new = np.where(close, new, lab)
        lab = np.where(mask, new, lab)
    return lab


def redraw(img):
    img = img.convert("RGBA")
    a = np.array(img)
    H, W = a.shape[:2]
    mask = a[:, :, 3] > 0
    n = int(mask.sum())
    if n == 0:
        return img
    rgb = a[:, :, :3].astype(np.float32)
    lum = rgb @ np.array([0.299, 0.587, 0.114], np.float32)

    # --- 1. линии старого рисунка (тёмный контур и тёмные штрихи) ---
    loc = ndimage.uniform_filter(np.where(mask, lum, 0), 5) / np.maximum(ndimage.uniform_filter(mask.astype(np.float32), 5), 1e-3)
    line = mask & (lum < 70) & (lum < loc - 22)
    body = mask & ~line
    if body.sum() < max(4, n * 0.15):
        body = mask.copy(); line[:] = False

    # --- 2. материалы ---
    X = _feat(rgb[body])
    nuniq = len(np.unique(a[body][:, :3], axis=0))
    k = int(np.clip(round(np.sqrt(nuniq) / 1.4), 3, 14))
    sub = X if len(X) < 6000 else X[np.random.default_rng(0).choice(len(X), 6000, replace=False)]
    _, C = _kmeans(sub, k)
    # редкие цвета (мох, лианы, огонь, камешки) — свои материалы, чтобы не пропали
    for _ in range(2):
        d = np.min(((X[:, None, :] - C[None]) ** 2).sum(2), 1)
        out_ = X[d > 0.03]
        if len(out_) < 3:
            break
        _, C2 = _kmeans(out_[:4000], int(np.clip(len(out_) // 40, 1, 5)), seed=2)
        C = np.vstack([C, C2])
    lab = np.full((H, W), -1, np.int32)
    lab[body] = np.argmin(((X[:, None, :] - C[None]) ** 2).sum(2), 1)
    # линии -> материал ближайшего соседа
    if line.any():
        _, (iy, ix) = ndimage.distance_transform_edt(~body, return_indices=True)
        lab[line] = lab[iy[line], ix[line]]
    lab = _mode_filter(np.where(mask, lab, 0), mask, len(C), passes=1 if n < 400 else 2, C=C)
    lab[~mask] = -1

    # --- 3. рампы материалов ---
    ramps = {}
    for j in range(len(C)):
        m = body & (lab == j)
        if not m.any():
            m = mask & (lab == j)
        if not m.any():
            continue
        cols = rgb[m]
        L = lum[m]
        sm_ = ndimage.uniform_filter(lum, 3)[m]
        mid = cols[np.abs(sm_ - np.median(sm_)) <= max(6, np.std(sm_) * 0.4)]
        base = tuple(int(v) for v in np.median(mid if len(mid) else cols, 0))
        ramps[j] = ramp(soften(base))

    # --- 4. свет ---
    out = np.zeros_like(a)
    inside = lambda dy, dx: np.roll(np.roll(lab, dy, 0), dx, 1)
    # границы картинки — «снаружи»
    def nb(dy, dx):
        r = inside(dy, dx)
        if dy > 0: r[:dy] = -1
        if dy < 0: r[dy:] = -1
        if dx > 0: r[:, :dx] = -1
        if dx < 0: r[:, dx:] = -1
        return r
    up_, lf_ = nb(1, 0), nb(0, 1)            # сосед сверху / слева
    dn_, rt_ = nb(-1, 0), nb(0, -1)          # снизу / справа
    dn2, rt2 = nb(-2, 0), nb(0, -2)
    dr_ = nb(-1, -1)
    # ступени по старой яркости внутри материала: 3 ступени (крупные пятна)
    k_arr = np.full((H, W), 2, np.int32)
    for j in ramps:
        m = (lab == j) & body
        if m.sum() < 3:
            continue
        sm = ndimage.uniform_filter(lum, 3)
        L = sm[m]
        Lb = max(np.median(L), 1.0)
        r = L / Lb
        kk = np.where(r < 0.62, 4, np.where(r < 0.86, 3, np.where(r < 1.12, 2, np.where(r < 1.4, 1, 0))))
        k_arr[m] = kk
    if n > 900:   # крупные пятна, как листва у дерева
        k_arr = np.where(mask, ndimage.median_filter(k_arr, 3), k_arr)
    rimL = (up_ != lab) | (lf_ != lab)
    rimD = (dn_ != lab) | (rt_ != lab)
    k_arr = np.where(rimD & (k_arr < 3), 3, k_arr)
    k_arr = np.where(rimL & ~rimD & (k_arr == 2), 1, k_arr)
    # старые линии внутри — глубокая тень своего материала (цветная линия)
    k_arr = np.where(line, np.maximum(k_arr, 4), k_arr)

    # --- 5. внешний контур ---
    edge = mask & ~ndimage.binary_erosion(mask, np.ones((3, 3)), border_value=0)
    cy, cx = ndimage.center_of_mass(mask)
    yy, xx = np.mgrid[0:H, 0:W]
    dx, dy = xx - cx, yy - cy
    dl = np.hypot(dx, dy) + 1e-6
    s = (dx * -0.62 + dy * -0.78) / dl
    ok = np.where(s > 0.35, 0, np.where(s > -0.3, 1, 2))

    for j, (tones, oln) in ramps.items():
        T = np.array(tones, np.uint8); O = np.array(oln, np.uint8)
        m = lab == j
        out[m, :3] = T[np.clip(k_arr[m], 0, 4)]
        e = m & edge & (n > 30)
        out[e, :3] = O[ok[e]]
    out[:, :, 3] = a[:, :, 3]

    # --- 6. блики на крупных пятнах ---
    for j, (tones, _) in ramps.items():
        comp, nc = ndimage.label((lab == j) & ~edge)
        if nc == 0:
            continue
        sizes = ndimage.sum(np.ones_like(comp), comp, range(1, nc + 1))
        for ci in np.nonzero(sizes >= 40)[0]:
            ys, xs = np.nonzero(comp == ci + 1)
            h, w = ys.max() - ys.min() + 1, xs.max() - xs.min() + 1
            if min(h, w) < 6 or sizes[ci] < 0.55 * h * w:
                continue
            by = ys.min() + max(1, int(h * 0.2)); bx = xs.min() + max(1, int(w * 0.24))
            for py, px in ((by, bx), (by, bx + 1), (by + 1, bx)):
                if 0 <= py < H and 0 <= px < W and comp[py, px] == ci + 1:
                    out[py, px, :3] = tones[0]
    return Image.fromarray(out, "RGBA")


# ---------------------------------------------------------------- вывод
def thumb(im, box=110):
    bb = im.getbbox()
    if bb:
        im = im.crop(bb)
    k = min(box / im.width, box / im.height)
    if k >= 2:
        k = int(min(k, 5)); return im.resize((im.width * k, im.height * k), Image.NEAREST)
    if k < 1:
        return im.resize((max(1, int(im.width * k)), max(1, int(im.height * k))), Image.BOX)
    return im


def sheet(rows, path, box=110):
    """rows: [(name, [img, img, ...])]"""
    ncol = len(rows[0][1])
    cw, ch = (box + 6) * ncol + 10, box + 18
    cols = max(1, 2400 // cw)
    R = (len(rows) + cols - 1) // cols
    sh = Image.new("RGBA", (cols * cw, R * ch), (246, 241, 230, 255))
    d = ImageDraw.Draw(sh)
    for i, (name, ims) in enumerate(rows):
        x0, y0 = (i % cols) * cw, (i // cols) * ch
        for j, im in enumerate(ims):
            t = thumb(im.convert("RGBA"), box)
            sh.alpha_composite(t, (x0 + j * (box + 6) + 2, y0 + 2 + box - t.height))
        d.text((x0 + 2, y0 + ch - 14), name[:34], fill=(60, 40, 40, 255))
    sh.save(path)


def work(args):
    g, f = args
    dst = os.path.join(OUT, g, f)
    if not os.path.exists(dst):
        redraw(Image.open(os.path.join(ART, f))).save(dst)
    return f


TEST = ["house.png", "barrel.png", "cauldron.png", "dun_chest_wood.png", "rock18_a.png", "lantern.png", "bush_a.png",
        "goblin_hut_a.png", "in9_crystal_ball.png", "st20_anvil.png", "elf_house.png", "knight_castle.png",
        "workbench.png", "campfire.png", "dun_floor_cave.png", "coin.png", "ui_panel.png", "sapling_oak_0.png"]

if __name__ == "__main__":
    args = sys.argv[1:] or ["test"]
    if args == ["test"]:
        rows = []
        for f in TEST:
            p = os.path.join(ART, f)
            if not os.path.exists(p):
                cand = [x for x in os.listdir(ART) if x.startswith(f.split(".")[0].rsplit("_", 1)[0]) and x.endswith(".png")]
                if not cand:
                    continue
                f = cand[0]; p = os.path.join(ART, f)
            src = Image.open(p)
            rows.append((f[:-4], [src, redraw(src), Image.open(r"C:\Claude\herbalist_game\game\art\tree_a.png")]))
        os.makedirs(OUT, exist_ok=True)
        sheet(rows, os.path.join(OUT, "_test_compare.png"))
        print("ok", len(rows))
        sys.exit()
    jobs = []
    for g in args:
        os.makedirs(os.path.join(OUT, g), exist_ok=True)
        jobs += [(g, f) for f in sorted(os.listdir(os.path.join(APPLE, g))) if f.endswith(".png")]
    with Pool(max(1, (os.cpu_count() or 2) - 1)) as pool:
        for i, _ in enumerate(pool.imap_unordered(work, jobs), 1):
            if i % 100 == 0:
                print(i, "/", len(jobs), flush=True)
    for g in args:
        fs = sorted(f for f in os.listdir(os.path.join(OUT, g)) if f.endswith(".png"))
        rows = [(f[:-4], [Image.open(os.path.join(ART, f)), Image.open(os.path.join(OUT, g, f))]) for f in fs]
        per = 150
        for p in range(0, len(rows), per):
            sheet(rows[p:p + per], os.path.join(OUT, "%s_compare%s.png" % (g, "" if p == 0 else "_%d" % (p // per + 1))))
        print(g, len(fs))
