# -*- coding: utf-8 -*-
"""Стволы деревьев в стиле яблока: без дупла, кора с волокнами, свет слева, цветной мягкий контур вместо чёрного.
Крона и трава у корней не меняются, только тёмная обводка кроны становится цветной (мягче).
Запуск: python trunks.py [--game]  ->  art_apple/trunks/ (+ trunks_compare.png); с --game кладёт в game/art
(старые копии — herbalist_game/backup_flowers_trunks_20261115)."""
import os, sys, shutil, random, math
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from apple_engine import ramp, _hsv, _rgb, _lum, up, LIGHT
from PIL import Image

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
ART = os.path.join(GAME, "art")
OUT = os.path.abspath(os.path.join(GAME, "..", "art_apple", "trunks"))
BACK = os.path.abspath(os.path.join(GAME, "..", "backup_flowers_trunks_20261115"))
TREES = ["tree_a", "tree_b", "tree_c", "tree_d", "tree_apple", "tree_autumn", "tree_autumn2", "tree_blossom",
         "tree_unicorn", "tree_birch"]


def is_leafy(c):
    """Листва/трава/цветы кроны — всё, что не кора: зелёное, розовое, оранжевое и т.п. (кора — тусклая коричневая)."""
    r, g, b = c[:3]
    h, s, v = _hsv((r, g, b))
    if g > r + 6:
        return True
    if s > 0.62 and v > 0.55:      # яркие лепестки, яблоки, осенняя листва
        return True
    if b > r + 8 and v > 0.5:      # сиреневая/голубая листва (единорожье дерево)
        return True
    return False


def soft_outline(px, W, H, x, y):
    """Тёмный пиксель края -> цветной контур по соседнему светлому цвету."""
    best = None
    for rr in (1, 2, 3):
        for dy in range(-rr, rr + 1):
            for dx in range(-rr, rr + 1):
                q = (x + dx, y + dy)
                if 0 <= q[0] < W and 0 <= q[1] < H and px[q][3] == 255 and _lum(px[q]) >= 70:
                    best = px[q][:3]; break
            if best: break
        if best: break
    if best is None:
        return None
    _, ol = ramp(best)
    return ol[1] if x < W / 2 else ol[2]


def redo(name):
    img = Image.open(os.path.join(BACK if os.path.exists(os.path.join(BACK, name + ".png")) else ART, name + ".png")).convert("RGBA")
    W, H = img.size
    px = img.load()
    out = img.copy(); po = out.load()
    solid = lambda x, y: 0 <= x < W and 0 <= y < H and px[x, y][3] == 255
    # строки кроны: много листвы. Ствол — ниже самой широкой части кроны, от низа кроны до травы
    # низ кроны — самая нижняя строка, где картинка шире половины (ниже — только ствол и трава у корней)
    widths = [sum(1 for x in range(W) if solid(x, y)) for y in range(H)]
    crown_mid = max(y for y in range(int(H * 0.85)) if widths[y] > W * 0.5) + 1
    # кора: непрозрачные не-листья в нижней части, связные с центром низа
    bark = set()
    for y in range(crown_mid, H):
        for x in range(W):
            if solid(x, y) and not is_leafy(px[x, y]):
                bark.add((x, y))
    # самая большая связная группа коры — это ствол (остальное — тени/корни-камешки)
    seen = set(); groups = []
    for p0 in bark:
        if p0 in seen:
            continue
        st = [p0]; seen.add(p0); g = []
        while st:
            q = st.pop(); g.append(q)
            for d in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                r = (q[0] + d[0], q[1] + d[1])
                if r in bark and r not in seen:
                    seen.add(r); st.append(r)
        groups.append(g)
    trunk = set(max(groups, key=len)) if groups else set()
    browns = [px[p][:3] for p in trunk if _lum(px[p]) > 70]
    browns.sort(key=_lum)
    base = browns[len(browns) // 2] if browns else (120, 80, 50)
    birch = _lum(base) > 170
    h0, s0, v0 = _hsv(base)
    groove = _rgb(h0 + 0.01, min(1, s0 * 0.95 + 0.05), 0.36)     # бороздка коры — тёмно-коричневая, не чёрная
    rim_d = _rgb(h0 + 0.015, min(1, s0 * 0.9 + 0.08), 0.30)      # контур в тени (справа)
    rim_l = _rgb(h0, s0 * 0.9, min(1, v0 * 0.78))                 # контур на свету (слева)
    trunk_dark = {p for p in trunk if _lum(px[p]) < 60}
    # дупло: тёмные пиксели не у края, у которых много тёмных соседей (тонкие бороздки остаются)
    hole = set()
    for (x, y) in trunk_dark:
        if not (solid(x - 1, y) and solid(x + 1, y)):
            continue
        n = sum(1 for dx in (-1, 0, 1) for dy in (-1, 0, 1) if (dx or dy) and (x + dx, y + dy) in trunk_dark)
        if n >= 3:
            hole.add((x, y))
    # расширяем дупло на соседние тёмные (края дырки)
    for _ in range(2):
        hole |= {(x + dx, y + dy) for (x, y) in hole for dx in (-1, 0, 1) for dy in (-1, 0, 1)
                 if (x + dx, y + dy) in trunk_dark and solid(x + dx - 1, y + dy) and solid(x + dx + 1, y + dy)}
    for (x, y) in trunk:
        c = px[x, y][:3]
        left_edge = not solid(x - 1, y)
        right_edge = not solid(x + 1, y)
        if birch:
            if _lum(c) < 60 and (left_edge or right_edge):
                cc = soft_outline(px, W, H, x, y)
                if cc:
                    po[x, y] = cc + (255,)
            continue
        if (x, y) in hole:
            # закрасить корой: цвет ближайшего не-дупла в той же строке (слева, потом справа), со сдвигом вверх-вниз
            fill = None
            for d in range(1, 8):
                for q in ((x - d, y), (x + d, y), (x, y - d), (x, y + d)):
                    if q in trunk and q not in hole and _lum(px[q]) >= 60:
                        fill = px[q][:3]; break
                if fill: break
            po[x, y] = (fill or base) + (255,)
        elif right_edge:
            po[x, y] = rim_d + (255,)
        elif left_edge and _lum(c) < 70:
            po[x, y] = rim_l + (255,)
        elif _lum(c) < 45:
            po[x, y] = groove + (255,)
        elif not solid(x - 2, y) and _lum(c) >= 60 and y % 7 not in (0, 1):
            hh, ss, vv = _hsv(c)   # светлая кромка слева — свет падает сверху-слева, как на яблоке
            po[x, y] = _rgb(hh + 0.01, ss * 0.85, min(1, vv * 1.14 + 0.03)) + (255,)
    # обводка кроны: только внешний край (рядом прозрачное), чёрное -> цветное, светлее
    for y in range(H):
        for x in range(W):
            if (x, y) in trunk or px[x, y][3] < 255 or _lum(px[x, y]) >= 52:
                continue
            if all(solid(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                continue
            cc = soft_outline(px, W, H, x, y)
            if cc:
                h1, s1, v1 = _hsv(cc)
                po[x, y] = _rgb(h1, s1, max(v1, 0.30)) + (255,)
    return img, out
    top = ys[0]
    for y in ys:
        xs = sorted(p[0] for p in trunk if p[1] == y)
        x0, x1 = xs[0], xs[-1]
        wdt = max(1, x1 - x0)
        for x in xs:
            # прозрачный или листва рядом слева/справа — край
            left_edge = not solid(x - 1, y)
            right_edge = not solid(x + 1, y)
            if birch:
                if _lum(px[x, y]) < 60 and (left_edge or right_edge):
                    c = soft_outline(px, W, H, x, y)
                    if c:
                        po[x, y] = c + (255,)
                continue
            t = (x - x0) / wdt
            k = 1 if t < 0.22 else 2 if t < 0.58 else 3 if t < 0.84 else 4
            # тень от кроны сверху
            if y - top < 5:
                k = min(4, k + 1)
            # волокна: тёмные полоски, слегка волнистые
            fx = x + int(round(math.sin((y + x * 7) * 0.21) * 0.8))
            if fx % 4 == 1 and 0.12 < t < 0.9 and rnd.random() < 0.85:
                k = min(4, k + 1)
            elif fx % 4 == 3 and t < 0.45 and rnd.random() < 0.5:
                k = max(0, k - 1)
            c = tones[k]
            if left_edge:
                c = ol[0]
            elif right_edge:
                c = ol[2] if t > 0.5 else ol[1]
            po[x, y] = c + (255,)
    # обводка кроны и всего прочего: чёрное -> цветное (мягче)
    for y in range(H):
        for x in range(W):
            if (x, y) in trunk or px[x, y][3] < 255:
                continue
            if _lum(px[x, y]) < 52:
                c = soft_outline(px, W, H, x, y)
                if c:
                    po[x, y] = c + (255,)
    return img, out


def main():
    os.makedirs(OUT, exist_ok=True)
    pairs = []
    for n in TREES:
        if not os.path.exists(os.path.join(ART, n + ".png")):
            continue
        old, new = redo(n)
        new.save(os.path.join(OUT, n + ".png"))
        pairs.append((old, new))
        if "--game" in sys.argv:
            os.makedirs(BACK, exist_ok=True)
            if not os.path.exists(os.path.join(BACK, n + ".png")):
                shutil.copy(os.path.join(ART, n + ".png"), os.path.join(BACK, n + ".png"))
            new.save(os.path.join(ART, n + ".png"))
    k = 3
    Wt = sum(o.width for o, _ in pairs) * k
    Ht = max(o.height for o, _ in pairs) * k
    sheet = Image.new("RGBA", (Wt, Ht * 2), (120, 155, 92, 255))
    x = 0
    for o, nw in pairs:
        sheet.alpha_composite(up(o, k), (x, 0)); sheet.alpha_composite(up(nw, k), (x, Ht)); x += o.width * k
    sheet.save(os.path.join(OUT, "..", "trunks_compare.png"))
    print("стволы готовы ->", OUT)


if __name__ == "__main__":
    main()
