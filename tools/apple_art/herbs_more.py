# -*- coding: utf-8 -*-
# Остальные травы. Подключается из herbs.py (exec в его пространстве имён),
# поэтому здесь доступны все помощники: soil, stem, leaf, blade, berry, daisy, star, cup, bush, lumps, frond, bell...

@herb
def h_st_john(c):
    soil(c); tufts(c)
    for dx in (-5, 0, 5):
        stem(c, [(16 + dx * 0.3, 43), (16 + dx, 14)], STEM)
        for i in range(4):
            y = 38 - i * 6
            leaf(c, (16 + dx * (0.3 + i * 0.2), y), (16 + dx * (0.3 + i * 0.2) - 3, y - 2), 1.2, LEAF)
            leaf(c, (16 + dx * (0.3 + i * 0.2), y - 1), (16 + dx * (0.3 + i * 0.2) + 3, y - 3), 1.2, LEAF)
    for (x, y) in ((9, 12), (13, 9), (16, 13), (19, 8), (23, 11), (11, 16), (21, 15)):
        star(c, x, y, 2.4, "#f6c83c", 5, "#e0902c", rot=-18)


@herb
def h_oregano(c):
    soil(c); tufts(c)
    for dx, top in ((-6, 14), (0, 9), (6, 13)):
        stem(c, [(16 + dx * 0.3, 43), (16 + dx, top + 3)], "#7a6a58")
        for i in range(3):
            y = 38 - i * 7
            x = 16 + dx * (0.3 + 0.25 * i)
            c.add(ell(x - 2.4, y, 2.4, 1.5, -20), LEAF, "dome", shine=True)
            c.add(ell(x + 2.4, y - 1, 2.4, 1.5, 20), LEAF, "dome", shine=True)
        lumps(c, [(16 + dx - 2, top + 1, 1.8), (16 + dx + 2, top + 1, 1.8), (16 + dx, top - 1, 2.0)], "#c98ad6")


@herb
def h_lungwort(c):
    soil(c)
    for (b, t, bd) in (((16, 42), (5, 36), -1.5), ((16, 42), (27, 36), 1.5), ((16, 42), (10, 31), -1), ((16, 42), (22, 31), 1)):
        m = leaf(c, b, t, 3.0, "#5e9e58", bend=bd, shine=True)
    for (x, y) in ((8, 36), (11, 33), (22, 33), (24, 36), (12, 37), (20, 37)):
        c.mark(x, y, "#b8dca8")
    stem(c, [(16, 42), (16, 24), (16, 18)], STEM)
    for (x, y, col) in ((14, 16, "#e982b4"), (18, 17, "#7c94ea"), (16, 13, "#e982b4"), (13, 20, "#7c94ea"), (19, 21, "#e982b4")):
        bell(c, x, y, 1.6, col)


@herb
def h_lily_valley(c):
    soil(c)
    leaf(c, (14, 43), (8, 12), 4.2, "#4f9a58", bend=-2, shine=True)
    leaf(c, (18, 43), (24, 14), 4.0, "#5fae5e", bend=2, shine=True)
    stem(c, [(16, 43), (17, 20), (21, 10), (25, 12)], STEM)
    for (x, y) in ((21, 13), (23, 15), (25, 18), (19, 16), (24, 21)):
        bell(c, x, y, 1.5, "#fbf7ee")


@herb
def h_strawberry(c):
    soil(c)
    for (x, y) in ((9, 26), (16, 20), (23, 25)):
        stem(c, [(16, 42), (x, y + 3)], STEM)
        for a in (-35, 0, 35):
            c.add(ell(x + math.sin(math.radians(a)) * 2.6, y - math.cos(math.radians(a)) * 2.4, 2.2, 2.6, a), LEAF, "dome", shine=True)
    star(c, 16, 13, 2.2, "#fbf6ec", 5, "#f2c33c")
    for (x, y) in ((8, 37), (14, 39), (22, 38)):
        stem(c, [(16, 34), (x, y - 2)], STEM)
        c.add(ell(x, y, 2.2, 2.6, 0, 2.2), "#ec4848", "dome", shine=True)
        c.mark(x - 1, y, "#ffd890"); c.mark(x + 1, y + 1, "#ffd890")
        c.add(ell(x, y - 2.6, 1.6, 0.8), LEAF_D, "flat")


@herb
def h_lingonberry(c):
    soil(c)
    bush(c, [(16, 34, 9, 7), (10, 37, 5, 4), (22, 37, 5, 4)], "#3f8a50", "cel")
    for (x, y, a) in ((10, 30, -30), (15, 28, 0), (21, 30, 30), (12, 35, -20), (20, 35, 20), (16, 33, 0)):
        c.add(ell(x, y, 2.0, 1.3, a), "#5aa860", "dome", shine=True, inner=False)
    for (x, y) in ((9, 36), (11, 38), (13, 36), (19, 37), (21, 35), (23, 38), (17, 39)):
        berry(c, x, y, 1.5, "#e2324a")


@herb
def h_fern(c):
    soil(c)
    for (tip, bd) in (((3, 22), -3), ((29, 22), 3), ((9, 8), -2), ((23, 8), 2), ((16, 4), 0)):
        frond(c, (16, 42), tip, 2.6, "#5ea84e", bend=bd)


@herb
def h_club_moss(c):
    soil(c)
    for (x, top) in ((8, 16), (12, 10), (16, 6), (20, 9), (24, 14)):
        c.add(tube([(x, 43), (x, top + 6)], 1.6, 1.4), "#3f8a4e", "cel")
        for y in range(top + 8, 42, 2):
            c.mark(x - 1, y, "#6fb070")
        c.add(tube([(x, top + 6), (x, top)], 1.4, 1.0), "#d8c45a", "cel", shine=True)


@herb
def h_heather(c):
    soil(c)
    for dx, top in ((-8, 18), (-4, 12), (0, 8), (4, 11), (8, 17)):
        stem(c, [(16 + dx * 0.3, 43), (16 + dx, top + 8)], "#6e5a48")
        for y in range(int(top + 22), int(top + 9), -3):
            c.mark(16 + dx - 1, y, "#4f8a50"); c.mark(16 + dx + 1, y - 1, "#4f8a50")
        spike(c, 16 + dx, top, top + 8, "#cf72b8", r=1.2, step=1.8)


@herb
def h_rosehip(c):
    soil(c)
    c.add(tube([(16, 43), (15, 28), (11, 14)], 1.2, 0.7), "#8a5a42", "cel")
    c.add(tube([(15, 32), (22, 22), (23, 12)], 1.0, 0.6), "#8a5a42", "cel")
    for (x, y, a) in ((10, 24, -30), (18, 30, 20), (24, 18, 30), (13, 18, -20), (20, 26, 0), (9, 32, -40)):
        c.add(ell(x, y, 2.4, 1.5, a), LEAF, "dome", shine=True)
    for (x, y) in ((11, 11), (23, 9), (17, 20), (8, 18), (25, 25)):
        c.add(ell(x, y, 2.0, 2.6, 0, 2.2), "#ec5a30", "dome", shine=True)
        c.mark(x, int(y - 3), "#5a3a2a")


@herb
def h_sage(c):
    soil(c)
    stem(c, [(16, 43), (16, 8)], SAGE)
    for i in range(5):
        y = 41 - i * 5
        s = 1 - i * 0.14
        leaf(c, (16, y), (16 - 8 * s, y - 3), 2.2 * s + 0.4, SAGE, bend=-0.8, shine=True)
        leaf(c, (16, y - 1), (16 + 8 * s, y - 4), 2.2 * s + 0.4, SAGE, bend=0.8, shine=True)
    spike(c, 16, 4, 12, "#9b78d6", r=1.3, step=1.8)


@herb
def h_valerian(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 14)], STEM)
    stem(c, [(16, 22), (11, 13)], STEM); stem(c, [(16, 22), (21, 13)], STEM)
    for i in range(3):
        y = 38 - i * 5
        c.add(tube([(16, y), (16 - 7 + i, y - 3)], 1.4, 0.5), LEAF)
        c.add(tube([(16, y - 1), (16 + 7 - i, y - 4)], 1.4, 0.5), LEAF)
    for (x, y) in ((11, 11), (16, 10), (21, 11)):
        lumps(c, [(x - 1.6, y + 0.5, 1.6), (x + 1.6, y + 0.5, 1.6), (x, y - 1, 1.8)], "#f4c6da")


@herb
def h_wormwood(c):
    soil(c)
    for dx, top in ((-7, 12), (-2, 6), (3, 8), (8, 13)):
        stem(c, [(16 + dx * 0.3, 43), (16 + dx, top)], "#9aa898")
        for i in range(5):
            y = 40 - i * (40 - top) / 5
            x = 16 + dx * (0.3 + 0.14 * i)
            c.add(tube([(x, y), (x - 3, y - 3)], 0.9, 0.4), "#b9c6bc")
            c.add(tube([(x, y - 1), (x + 3, y - 4)], 0.9, 0.4), "#b9c6bc")
        lumps(c, [(16 + dx, top, 1.3)], "#d8d8a0")


@herb
def h_moonbloom(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 16)], STEM)
    c.add(ell(12, 38, 3.5, 1.8, -10), LEAF_D, "dome"); c.add(ell(20, 38, 3.5, 1.8, 10), LEAF_D, "dome")
    c.add(poly([(16, 6), (21, 11), (16, 16), (11, 11)]), "#c4d8ff", "dome", shine=True)
    c.add(poly([(16, 8), (19, 11), (16, 14), (13, 11)]), "#e6eeff", "dome", shine=True, inner=False)
    c.spark(23, 6, "#d8e6ff"); c.spark(9, 5, "#d8e6ff", 0); c.spark(24, 14, "#d8e6ff", 0)


@herb
def h_unicorn_mane(c):
    soil(c)
    cols = ["#f4a6c8", "#c8a8f0", "#a8e0d0", "#f8e0a0", "#f0b8a8", "#b8d0f8"]
    for k, dx in enumerate((-8, -5, -2, 1, 4, 7)):
        c.add(tube([(16 + dx * 0.4, 43), (16 + dx, 24), (16 + dx * 1.2 + (1 if k % 2 else -1), 6 + (k % 3) * 2)], 1.4, 0.5), cols[k], "cel")
    c.spark(8, 6, "#fff4fa"); c.spark(24, 9, "#fff4fa", 0); c.spark(15, 3, "#fff4fa", 0)


@herb
def h_pink_clover(c):
    soil(c); tufts(c)
    for (x, y) in ((11, 13), (21, 10)):
        stem(c, [(16, 42), (x, y + 8), (x, y + 3)], STEM)
    for (x, y) in ((8, 30), (24, 29), (16, 25)):
        stem(c, [(16, 42), (x, y + 2)], STEM)
        for dx, dy in ((-2, 0), (2, 0), (0, -2)):
            c.add(ell(x + dx, y + dy, 2.2, 1.9), LEAF, "dome", shine=True)
    for (x, y) in ((11, 13), (21, 10)):
        c.add(ell(x, y, 4.2, 4.4, 0, 2.2), "#f49ac4", "dome", shine=True)
        for k in range(4):
            c.mark(x - 2 + k, y - 2 + (k % 2) * 2, "#fbd0e2")


@herb
def h_glowmoss(c):
    soil(c)
    bush(c, [(16, 37, 11, 6.5), (10, 39, 5, 4), (22, 39, 5, 4)], "#48aeb0", "dome")
    lumps(c, [(10, 35, 2.4), (16, 33, 2.8), (22, 35, 2.4)], "#62c4c0")
    for (x, y) in ((8, 37), (12, 33), (17, 31), (21, 36), (14, 38), (24, 38), (19, 34)):
        c.mark(x, y, "#d4fff4")
    c.spark(8, 28, "#bff8ec", 0); c.spark(24, 27, "#bff8ec", 0)


@herb
def h_stonecrop(c):
    soil(c)
    c.add(ell(16, 38, 10, 5, 0, 2.3), "#aaa69e", "dome", shine=True)
    for (x, y) in ((9, 33), (13, 31), (17, 30), (21, 31), (24, 33)):
        c.add(ell(x, y + 1.5, 1.6, 2.0), "#86b06a", "dome")
        star(c, x, y - 0.5, 2.0, "#f8d23c", 5, "#e8a830")


@herb
def h_crystal_root(c):
    soil(c)
    c.add(tube([(10, 43), (13, 38), (16, 34), (21, 37)], 2.4, 1.4), "#c99a68", "cel", shine=True)
    c.add(tube([(16, 36), (20, 42)], 1.4, 0.6), "#c99a68")
    for (x, w, top) in ((12, 3.0, 14), (16, 3.6, 8), (20, 3.0, 13)):
        c.add(poly([(x - w, 34), (x - w, top + 4), (x, top), (x + w, top + 4), (x + w, 34)]), "#b6a2f0", "cel", shine=True)
    c.spark(25, 10, "#ece4ff", 0); c.spark(8, 13, "#ece4ff", 0)


@herb
def h_calamus(c):
    soil(c)
    for (tip, bd) in (((6, 10), -1.5), ((11, 5), -0.8), ((17, 3), 0.2), ((23, 6), 1), ((27, 13), 1.6)):
        blade(c, (16, 43), tip, 1.8, "#5fa85a", bend=bd)
    c.add(tube([(18, 26), (21, 15)], 1.4, 1.0), "#c4a24e", "cel", shine=True)


@herb
def h_marsh_tea(c):
    soil(c)
    for dx, top in ((-6, 14), (0, 9), (6, 13)):
        c.add(tube([(16 + dx * 0.3, 43), (16 + dx, top + 3)], 0.9, 0.6), "#7a5844", "cel")
        for i in range(4):
            y = 38 - i * 6
            x = 16 + dx * (0.3 + 0.2 * i)
            c.add(tube([(x, y), (x - 4, y - 2)], 0.9, 0.4), "#3e7a4c")
            c.add(tube([(x, y - 1), (x + 4, y - 3)], 0.9, 0.4), "#3e7a4c")
        lumps(c, [(16 + dx - 1.6, top + 1, 1.6), (16 + dx + 1.6, top + 1, 1.6), (16 + dx, top - 1, 1.7)], "#f6f2ea")


@herb
def h_sundew(c):
    soil(c)
    stem(c, [(16, 40), (16, 14)], "#c46a62")
    star(c, 16, 12, 2.0, "#fbf4f4", 5, "#f0c0c8")
    for (x, y, a) in ((7, 38, -15), (25, 38, 15), (10, 34, -35), (22, 34, 35), (16, 33, 0)):
        c.add(tube([(16, 41), (x, y)], 0.9, 0.6), "#c46a62")
        c.add(ell(x, y, 2.2, 2.0, a), "#e2564c", "dome", shine=True)
        for dx, dy in ((-2, -2), (2, -2), (0, -3), (-3, 0), (3, 0)):
            c.fx.append((x + dx, y + dy, (255, 236, 220)))


@herb
def h_cloudberry(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 14)], STEM)
    c.add(ell(10, 34, 5, 3.6, -15), LEAF, "dome", shine=True)
    c.add(ell(22, 32, 5, 3.6, 15), LEAF, "dome", shine=True)
    m = set()
    for dx, dy in ((-1.5, 0), (1.5, 0), (0, -1.5), (0, 1.5), (-1.2, -1.2), (1.2, 1.2), (1.2, -1.2), (-1.2, 1.2), (0, 0)):
        m |= ell(16 + dx, 11 + dy, 1.6, 1.6)
    c.add(m, "#f2a63a", "dome", shine=True)
    for (x, y) in ((15, 10), (17, 12), (14, 12), (17, 9)):
        c.mark(x, y, "#ffd884")
    c.add(ell(16, 7, 2.4, 0.9), LEAF_D, "flat")


@herb
def h_sea_buckthorn(c):
    soil(c)
    c.add(tube([(16, 43), (15, 26), (11, 8)], 1.2, 0.6), "#8a7462", "cel")
    c.add(tube([(15, 30), (22, 18), (23, 6)], 1.0, 0.5), "#8a7462", "cel")
    for (x, y, a) in ((8, 14, -40), (26, 12, 40), (8, 24, -30), (25, 22, 30), (12, 32, -20)):
        c.add(tube([(x + (3 if a < 0 else -3), y + 2), (x, y)], 1.0, 0.4), "#9ab8a0")
    for (x, y) in ((12, 12), (11, 15), (13, 18), (12, 21), (14, 24), (22, 10), (23, 13), (21, 16), (22, 19), (15, 28)):
        berry(c, x, y, 1.4, "#f59a26")


@herb
def h_sea_lavender(c):
    soil(c)
    for dx in (-5, 5):
        leaf(c, (16, 42), (16 + dx * 1.8, 38), 2.2, "#8ea894", bend=dx * 0.2)
    for (tip, br) in (((8, 10), (5, 16)), ((16, 6), (20, 12)), ((24, 11), (27, 17))):
        stem(c, [(16, 42), (16 + (tip[0] - 16) * 0.4, 26), tip], "#8a9a90")
        stem(c, [(16 + (tip[0] - 16) * 0.5, 22), br], "#8a9a90")
        for (x, y) in (tip, br):
            for dx, dy in ((0, 0), (1, 1), (-1, 1), (0, 2)):
                c.add(ell(x + dx, y + dy, 1.0, 1.0), "#b8a0e8", "flat", outline=True)


@herb
def h_sea_kale(c):
    soil(c, "sand")
    stem(c, [(16, 38), (16, 12)], "#8aa8a0")
    lumps(c, [(13, 11, 2.0), (17, 9, 2.2), (20, 12, 1.8), (15, 13, 1.6)], "#f6f4ec")
    for (x, y, rx, a) in ((8, 36, 6.5, -15), (24, 36, 6.5, 15), (16, 32, 5, 0)):
        c.add(ell(x, y, rx, 4.2, a, 2.2), "#7ab0a8", "dome", shine=True)
        c.mark(int(x), int(y), "#5a9088")


@herb
def h_nightshade(c):
    soil(c)
    stem(c, [(16, 43), (16, 10)], "#4a6a48")
    for i in range(4):
        y = 38 - i * 7
        c.add(ell(16 - 4, y, 4, 2.4, -20), "#3f7a4a", "dome", shine=True)
        c.add(ell(16 + 4, y - 2, 4, 2.4, 20), "#3f7a4a", "dome", shine=True)
    bell(c, 16, 8, 2.2, "#8a5ab0")
    for (x, y) in ((10, 20), (22, 18), (9, 30), (23, 28)):
        berry(c, x, y, 1.8, "#3a2a4e")


@herb
def h_mandrake(c):
    soil(c)
    c.add(ell(16, 36, 6.5, 6, 0, 2.3), "#dcb48a", "dome", shine=True)
    c.mark(14, 35, "#5a3a3a"); c.mark(18, 35, "#5a3a3a"); c.mark(16, 38, "#a86a5a")
    c.mark(13, 37, "#f0a8a0"); c.mark(19, 37, "#f0a8a0")
    for (tip, bd) in (((5, 20), -2), ((27, 20), 2), ((11, 16), -1), ((21, 16), 1)):
        leaf(c, (16, 30), tip, 3.2, "#4f9a58", bend=bd, shine=True)
    stem(c, [(16, 30), (16, 13)], STEM)
    c.add(ell(16, 11, 2.4, 2.4), "#a06ac8", "dome", shine=True)


@herb
def h_elf_leaf(c):
    soil(c)
    for (tip, bd, col) in (((4, 16), -3, "#3fa088"), ((28, 16), 3, "#3fa088"), ((10, 6), -2, "#4fb898"), ((22, 6), 2, "#4fb898")):
        leaf(c, (16, 43), tip, 4.6, col, bend=bd, shine=True)
    c.spark(16, 4, "#f8e8a0"); c.spark(6, 8, "#f8e8a0", 0); c.spark(26, 8, "#f8e8a0", 0)


@herb
def h_shiso(c):
    soil(c)
    stem(c, [(16, 43), (16, 6)], "#6a4070")
    for i in range(6):
        y = 41 - i * 5.6
        s = 1 - i * 0.13
        c.add(ell(16 - 4.5 * s, y - 1, 4.6 * s, 2.6 * s, -18), "#7c4a8e", "dome", shine=True)
        c.add(ell(16 + 4.5 * s, y - 2, 4.6 * s, 2.6 * s, 18), "#7c4a8e", "dome", shine=True)
    c.add(ell(16, 6, 2.0, 2.6), "#9a62aa", "dome", shine=True)


@herb
def h_ginseng(c):
    soil(c)
    c.add(tube([(16, 40), (13, 44), (11, 46)], 1.4, 0.6), "#e0c69a")
    c.add(tube([(16, 40), (19, 44), (21, 46)], 1.4, 0.6), "#e0c69a")
    stem(c, [(16, 41), (16, 12)], STEM)
    for a in (-60, -20, 20, 60):
        x = 16 + math.sin(math.radians(a)) * 6; y = 24 - math.cos(math.radians(a)) * 3
        leaf(c, (16, 26), (x, y), 2.0, LEAF, shine=True)
    for (x, y) in ((15, 9), (17, 9), (16, 7), (14, 11), (18, 11)):
        berry(c, x, y, 1.4, "#e8343a")


@herb
def h_fire_pepper(c):
    soil(c)
    bush(c, [(16, 36, 9, 5), (11, 38, 5, 3.5), (21, 38, 5, 3.5)], "#4f9a4e", "dome")
    for (x, top, a) in ((10, 14, -10), (16, 10, 0), (22, 15, 10)):
        c.add(tube([(x, 31), (x + a * 0.1, (31 + top) / 2), (x + a * 0.25, top)], 2.6, profile="drop"), "#f0642a", "cel", shine=True)
        c.add(tube([(x, 30), (x + a * 0.2, top + 6)], 1.2, profile="drop"), "#ffb24a", "cel", inner=False)
    c.spark(6, 12, "#ffd070", 0); c.spark(26, 10, "#ffd070", 0)


@herb
def h_catnip(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 10)], STEM)
    for i in range(4):
        y = 39 - i * 6
        s = 1 - i * 0.15
        c.add(ell(16 - 3.6 * s, y, 3.6 * s, 2.2 * s, -20), "#8cbc86", "dome", shine=True)
        c.add(ell(16 + 3.6 * s, y - 1, 3.6 * s, 2.2 * s, 20), "#8cbc86", "dome", shine=True)
    spike(c, 16, 4, 11, "#ece2f4", r=1.4, step=1.8)


@herb
def h_star_bell(c):
    soil(c); tufts(c)
    stem(c, [(16, 43), (16, 22), (14, 8)], STEM)
    for (x, y, sx) in ((14, 10, -4), (14, 16, 4), (15, 22, -4), (16, 28, 4)):
        stem(c, [(15, y), (15 + sx, y + 1)], STEM)
        bell(c, 15 + sx, y + 3, 2.2, "#5a80ea")
    for dx in (-4, 4):
        leaf(c, (16, 42), (16 + dx * 1.8, 36), 2.0, LEAF, bend=dx * 0.2)
    c.spark(23, 7, "#e8f0ff", 0)


@herb
def h_web_grass(c):
    soil(c)
    for (tip, bd) in (((5, 14), -1.5), ((10, 8), -1), ((16, 5), 0), ((22, 8), 1), ((27, 14), 1.5)):
        blade(c, (16, 43), tip, 1.6, "#8aa890", bend=bd)
    for (a, b) in (((7, 20), (25, 20)), ((9, 28), (23, 28)), ((10, 14), (22, 14)), ((8, 20), (16, 6)), ((24, 20), (16, 6)), ((10, 28), (22, 14)), ((22, 28), (10, 14))):
        for (x, y) in stroke([a, b]):
            c.fx.append((x, y, (246, 244, 250)))


@herb
def h_arnica(c):
    soil(c); tufts(c)
    for (x, y, s) in ((10, 13, -1), (21, 10, 1)):
        stem(c, [(16 + s, 43), (16 + s * 2, 28), (x, y + 2)], STEM)
    for dx in (-6, 6):
        leaf(c, (16, 42), (16 + dx * 1.5, 34), 2.6, LEAF, bend=dx * 0.2, shine=True)
    for (x, y) in ((10, 13), (21, 10)):
        star(c, x, y, 4.2, "#f8c43a", 10, "#e88a2a")


@herb
def h_fire_lily(c):
    soil(c); tufts(c)
    stem(c, [(14, 43), (12, 26), (11, 14)], STEM)
    stem(c, [(18, 43), (21, 30), (23, 20)], STEM)
    for dx in (-5, 5):
        leaf(c, (16, 41), (16 + dx * 1.6, 32), 1.8, LEAF, bend=dx * 0.2)
    star(c, 11, 12, 5.0, "#f2582c", 6, "#ffc04a", rot=-90)
    star(c, 23, 19, 3.4, "#f2582c", 6, "#ffc04a", rot=-90)
    c.spark(5, 6, "#ffcf6a", 0); c.spark(18, 5, "#ffcf6a", 0); c.spark(27, 12, "#ffcf6a", 0)


@herb
def h_frost_lotus(c):
    soil(c)
    c.add(ell(16, 38, 11, 3.4, 0, 2.2), "#4e9a7a", "dome", shine=True)
    for (x, y, rx, ry, col) in ((10, 31, 3.4, 4.6, "#cfe2f8"), (22, 31, 3.4, 4.6, "#cfe2f8"), (13, 28, 3.2, 5.4, "#e2eefc"),
                                (19, 28, 3.2, 5.4, "#e2eefc"), (16, 26, 3.0, 6.0, "#f2f8ff")):
        c.add(ell(x, y, rx, ry, 0, 2.0), col, "dome", shine=True)
    c.spark(6, 18, "#e8f4ff"); c.spark(26, 16, "#e8f4ff", 0); c.spark(16, 13, "#e8f4ff", 0)


@herb
def h_shadow_orchid(c):
    soil(c)
    stem(c, [(16, 43), (15, 28), (11, 14)], "#3a3448")
    stem(c, [(16, 34), (21, 22), (22, 12)], "#3a3448")
    for dx in (-5, 5):
        leaf(c, (16, 42), (16 + dx * 1.6, 34), 2.6, "#3a5a48", bend=dx * 0.2)
    for (x, y) in ((11, 12), (22, 10), (16, 20)):
        star(c, x, y, 3.4, "#5a3a86", 5, "#d8a8f0", rot=-90)
    c.spark(6, 8, "#c8a8f0", 0); c.spark(27, 6, "#c8a8f0", 0)


@herb
def h_sunflower_gold(c):
    soil(c)
    c.add(tube([(16, 43), (16, 16)], 1.2, 1.0), STEM)
    leaf(c, (16, 34), (6, 28), 3.0, LEAF, bend=-1, shine=True)
    leaf(c, (16, 30), (26, 24), 3.0, LEAF, bend=1, shine=True)
    star(c, 16, 11, 7.0, "#f8c832", 14)
    c.add(ell(16, 11, 3.6, 3.6), "#8a5a34", "dome", shine=True)
    for (x, y) in ((15, 10), (17, 12), (16, 9), (14, 12)):
        c.mark(x, y, "#5e3a26")


@herb
def h_dragon_root(c):
    soil(c)
    c.add(tube([(5, 41), (9, 36), (14, 40), (20, 33), (27, 28)], 2.4, 1.0), "#e0703a", "cel", shine=True)
    c.add(ell(26, 28, 2.6, 2.0, -30), "#e0703a", "dome", shine=True)
    c.mark(27, 27, "#4a2a2a")
    for (x, y) in ((9, 34), (15, 37), (20, 31)):
        c.mark(x, y, "#ffc070")
    c.spark(12, 22, "#ffb050", 0); c.spark(22, 18, "#ffb050", 0)


@herb
def h_void_bloom(c):
    soil(c)
    stem(c, [(16, 43), (16, 20)], "#3a3048")
    for dx in (-5, 5):
        leaf(c, (16, 42), (16 + dx * 1.6, 34), 2.4, "#3c3450", bend=dx * 0.2)
    star(c, 16, 14, 6.0, "#3e2c5e", 8, None)
    c.add(ell(16, 14, 2.2, 2.2), "#b06af0", "dome", shine=True)
    c.spark(7, 8, "#c890ff"); c.spark(25, 6, "#c890ff", 0); c.spark(26, 20, "#c890ff", 0)


@herb
def h_phoenix_grass(c):
    soil(c)
    cols = ["#f8c440", "#f48a30", "#e8502c", "#f48a30", "#f8c440"]
    for k, (tip, bd) in enumerate((((4, 18), -2), ((9, 9), -1), ((16, 5), 0), ((23, 9), 1), ((28, 18), 2))):
        c.add(tube([(16, 42), ((16 + tip[0]) / 2 + bd, (42 + tip[1]) / 2), tip], 3.0, profile="drop"), cols[k], "cel", shine=True)
    c.spark(16, 2, "#ffe080", 0); c.spark(4, 10, "#ffe080", 0); c.spark(28, 10, "#ffe080", 0)


@herb
def h_world_leaf(c):
    soil(c)
    stem(c, [(16, 43), (16, 36)], "#6a5a3a")
    leaf(c, (16, 38), (16, 4), 8.0, "#8ccc6a", shine=True)
    for (x, y) in stroke([(16, 36), (16, 8)]):
        c.mark(x, y, "#e8d070")
    for y in (14, 20, 26, 31):
        for (x, yy) in stroke([(16, y + 2), (11, y - 2)]) | stroke([(16, y + 2), (21, y - 2)]):
            c.mark(x, yy, "#d8d070")
    c.spark(6, 6, "#fff0a0"); c.spark(27, 12, "#fff0a0", 0)


# ---- морские (на песке) ----
@herb
def h_sea_lettuce(c):
    soil(c, "sand")
    bush(c, [(16, 34, 11, 7), (9, 38, 5, 4), (23, 38, 5, 4)], "#4fae76", "dome")
    for (x, y, r) in ((9, 30, 3.4), (16, 27, 4.0), (23, 30, 3.4)):
        c.add(ell(x, y, r, r * 0.8), "#6cc48a", "dome", shine=True)
    c.spark(6, 22, "#d8fff0", 0); c.spark(26, 22, "#d8fff0", 0)


@herb
def h_eelgrass(c):
    soil(c, "sand")
    for (tip, bd) in (((5, 6), -2), ((10, 4), 1), ((15, 3), -1), ((19, 5), 1.5), ((24, 4), -1), ((28, 9), 2)):
        blade(c, (16 + (tip[0] - 16) * 0.2, 43), tip, 1.1, "#4fb08e", bend=bd)


@herb
def h_kelp_gold(c):
    soil(c, "sand")
    c.add(tube([(16, 43), (15, 24), (16, 6)], 1.0, 0.8), "#a07a34", "cel")
    for i, (side, y) in enumerate(((-1, 34), (1, 28), (-1, 22), (1, 16), (-1, 10))):
        c.add(ell(16 + side * 4.6, y, 4.2, 2.2, side * -25), "#c9a040", "dome", shine=True)
    c.add(ell(16, 5, 2.0, 2.8), "#c9a040", "dome", shine=True)


@herb
def h_sea_grape(c):
    soil(c, "sand")
    for (x0, x1, top) in ((12, 9, 8), (18, 23, 5)):
        c.add(tube([(16, 43), (x0, 26), (x1, top)], 0.8, 0.6), "#5ca66e", "cel")
        for k in range(7):
            t = k / 6
            x = 16 + (x0 - 16) * 2 * t * (1 - t) * 2 + (x1 - 16) * t * t if False else (16 * (1 - t) ** 2 + 2 * x0 * t * (1 - t) + x1 * t * t)
            y = 43 * (1 - t) ** 2 + 2 * 26 * t * (1 - t) + top * t * t
            if y < 40:
                berry(c, x + (1.6 if k % 2 else -1.6), y, 2.0, "#82d48e")


@herb
def h_storm_weed(c):
    soil(c, "sand")
    for (tip, bd) in (((6, 8), -1.5), ((12, 4), -0.5), ((20, 4), 0.5), ((26, 8), 1.5)):
        stem(c, [(16, 43), ((16 + tip[0]) / 2 + bd, 24), tip], "#7a8a4a")
        berry(c, tip[0], tip[1], 1.8, "#c9a03c")
        berry(c, (16 + tip[0]) / 2 + bd, 24, 1.5, "#c9a03c")
    blade(c, (16, 43), (12, 30), 1.6, "#6f9a52", bend=-1); blade(c, (16, 43), (20, 30), 1.6, "#6f9a52", bend=1)


@herb
def h_sea_anemone(c):
    soil(c, "sand")
    c.add(tube([(16, 43), (16, 26)], 3.0, 2.2), "#e888a0", "cel", shine=True)
    for a in range(-80, 81, 16):
        r = math.radians(a - 90)
        c.add(tube([(16, 24), (16 + math.cos(r) * 11, 24 + math.sin(r) * 13)], 1.3, 0.6), "#f07a3c", "cel")
    c.add(ell(16, 24, 5.0, 2.0), "#e05a34", "dome")


@herb
def h_pearl_moss(c):
    soil(c, "sand")
    bush(c, [(16, 37, 11, 6), (10, 39, 5, 4), (22, 39, 5, 4)], "#6cc49a", "dome")
    for (x, y) in ((9, 35), (14, 33), (19, 32), (23, 36), (16, 37), (11, 39)):
        berry(c, x, y, 1.4, "#f6f2f8")


@herb
def h_coral_bloom(c):
    soil(c, "sand")
    br = [((16, 43), (16, 22)), ((16, 30), (9, 20)), ((16, 26), (23, 16)), ((9, 22), (6, 10)), ((9, 22), (12, 8)),
          ((23, 18), (20, 6)), ((23, 18), (27, 8)), ((16, 22), (16, 10))]
    m = set()
    for a, b in br:
        m |= tube([a, b], 1.6, 1.2)
    c.add(m, "#ee8a9a", "cel")
    for a, b in br[3:]:
        c.add(ell(b[0], b[1], 1.6, 1.6), "#f8b0bc", "dome", shine=True, inner=False)


@herb
def h_ice_algae(c):
    soil(c, "sand")
    for (tip, bd) in (((4, 18), -2), ((9, 8), -1), ((16, 4), 0), ((23, 8), 1), ((28, 18), 2)):
        c.add(tube([(16, 42), ((16 + tip[0]) / 2 + bd, (42 + tip[1]) / 2), tip], 3.2, profile="drop"), "#7cbce8", "cel", shine=True)
    c.spark(16, 1, "#eef8ff", 0); c.spark(6, 10, "#eef8ff", 0); c.spark(27, 11, "#eef8ff", 0)


@herb
def h_star_coral(c):
    soil(c, "sand")
    c.add(ell(16, 35, 11, 8, 0, 2.2), "#f4c08a", "dome", shine=True)
    for (x, y) in ((10, 33), (15, 30), (20, 32), (13, 37), (19, 38), (24, 36), (8, 38)):
        for dx, dy in ((0, 0), (1, 0), (-1, 0), (0, 1), (0, -1)):
            c.mark(x + dx, y + dy, "#fde6c8" if (dx, dy) != (0, 0) else "#e09a5a")


@herb
def h_glow_algae(c):
    soil(c, "sand")
    for (tip, bd) in (((7, 6), -2), ((13, 4), 1.5), ((19, 5), -1.5), ((25, 8), 2)):
        c.add(tube([(16 + (tip[0] - 16) * 0.3, 43), ((16 + tip[0]) / 2 + bd, 24), tip], 1.3, 0.6), "#5ed8b0", "cel")
    for (x, y) in ((9, 14), (14, 10), (20, 16), (24, 12), (12, 24), (21, 26)):
        berry(c, x, y, 1.2, "#c8fff0", shine=False)
    c.spark(5, 18, "#d8fff4", 0); c.spark(27, 20, "#d8fff4", 0)


@herb
def h_mermaid_hair(c):
    soil(c, "sand")
    for k, x0 in enumerate((6, 10, 14, 18, 22, 26)):
        c.add(tube([(16 + (x0 - 16) * 0.3, 43), (x0 - 3, 30), (x0 + 3, 18), (x0 - 1, 5 + (k % 2) * 3)], 1.1, 0.5),
              "#4fb6b8" if k % 2 else "#68c8c4", "cel")


@herb
def h_abyss_kelp(c):
    soil(c, "sand")
    for (tip, bd) in (((6, 10), -1.5), ((12, 4), -0.5), ((20, 4), 0.5), ((26, 10), 1.5)):
        c.add(tube([(16, 43), ((16 + tip[0]) / 2 + bd, 24), tip], 3.2, profile="drop"), "#2e3e7a", "cel", shine=True)
    for (x, y) in ((10, 20), (13, 12), (19, 14), (22, 22), (16, 30)):
        c.mark(x, y, "#9ab0f0")


@herb
def h_siren_lily(c):
    soil(c, "sand")
    c.add(ell(16, 38, 10, 3.2, 0, 2.2), "#4e9a7a", "dome", shine=True)
    stem(c, [(16, 37), (16, 24)], STEM)
    star(c, 16, 22, 8.0, "#a07ad8", 6, "#f0d8ff", rot=-90)
    c.add(ell(16, 22, 2.4, 2.4), "#f4e4ff", "dome", shine=True)
    c.spark(8, 14, "#e8d8ff"); c.spark(24, 12, "#e8d8ff", 0); c.spark(16, 10, "#e8d8ff", 0)


@herb
def h_tide_orchid(c):
    soil(c, "sand")
    stem(c, [(16, 43), (15, 28), (11, 14)], STEM)
    stem(c, [(16, 34), (21, 22), (22, 12)], STEM)
    for dx in (-5, 5):
        leaf(c, (16, 42), (16 + dx * 1.6, 34), 2.6, "#3f9a7a", bend=dx * 0.2)
    for (x, y) in ((11, 12), (22, 10), (17, 20)):
        star(c, x, y, 3.2, "#5cc8e0", 5, "#f0fcff", rot=-90)
    c.spark(6, 6, "#e0f8ff", 0); c.spark(27, 4, "#e0f8ff", 0)


@herb
def h_pearl_flower(c):
    soil(c, "sand")
    stem(c, [(16, 43), (16, 26)], STEM)
    c.add(ell(11, 36, 4, 2, -15), LEAF, "dome"); c.add(ell(21, 36, 4, 2, 15), LEAF, "dome")
    for (x, y, rx, ry, col) in ((10, 20, 4, 4.2, "#f0dcec"), (22, 20, 4, 4.2, "#f0dcec"), (16, 17, 4.6, 5.2, "#fbeef8")):
        c.add(ell(x, y, rx, ry), col, "dome", shine=True)
    berry(c, 16, 21, 2.4, "#ffffff")
    c.spark(7, 10, "#fff6fc"); c.spark(25, 9, "#fff6fc", 0)
