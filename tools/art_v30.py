"""v30: дворик справа от дома прямо в мире — штакетник (как на старом фоне двора), открытая арка-калитка.
Запуск из папки game:  python tools/art_v30.py   -> art/*.png  (потом godot --headless --import)
"""
import os
from PIL import Image

ART = os.path.join(os.path.dirname(__file__), "..", "art")
OL = (52, 34, 24, 255)
WOOD = (201, 158, 102, 255)
WOOD_L = (222, 190, 140, 255)
WOOD_D = (172, 128, 78, 255)
RAIL = (189, 123, 67, 255)
RAIL_L = (208, 150, 96, 255)
KNOT = (189, 123, 67, 255)
T = (0, 0, 0, 0)

H = 30          # высота штакетины (ноги внизу)
PW = 8          # ширина штакетины
STEP = 10       # шаг штакетин


def save(im, name):
    im.save(os.path.join(ART, name + ".png"))
    print("art/" + name + ".png", im.size)


def picket(px, x0, h=H, seed=0):
    """Штакетина: тёмный контур, острый верх, светлый блик слева, пара сучков."""
    top = 3
    for y in range(h):
        for x in range(PW):
            # острый верх: ступенька к центру
            cx = abs(x - (PW - 1) / 2.0)
            if y < top and cx > (y + 0.5) * 1.3:
                continue
            edge = x in (0, PW - 1) or y == h - 1 or (y < top and cx > (y - 0.5) * 1.3) or y == 0
            px[x0 + x, y] = OL if edge else (WOOD_L if (x == 1 and y < h - 3) or (y < top + 1) else (WOOD_D if x == PW - 2 else WOOD))
    for k, (kx, ky) in enumerate([(3, 9 + seed % 5), (4, 20 - seed % 4)]):
        if 0 < kx < PW - 1:
            px[x0 + kx, ky] = KNOT


def fence_h():
    w = STEP * 3
    im = Image.new("RGBA", (w, H), T)
    px = im.load()
    # две перекладины позади штакетин (видны в щелях)
    for ry in (8, 20):
        for x in range(w):
            px[x, ry] = OL
            px[x, ry + 1] = RAIL_L
            px[x, ry + 2] = RAIL
            px[x, ry + 3] = OL
    for i in range(3):
        picket(px, i * STEP + 1, seed=i * 3)
    save(im, "by30_fence_h")


def fence_side():
    """Штакетина боком (для левой и правой стороны забора): острый верх и тень снизу, ставится столбиком
    через 9 px — зубчики видны, как у переднего забора."""
    w = 7
    im = Image.new("RGBA", (w, H), T)
    px = im.load()
    for y in range(H):
        for x in range(w):
            cx = abs(x - 3)
            if y < 3 and cx > y:
                continue
            edge = x in (0, w - 1) or y == H - 1 or (y < 3 and cx >= y) or y == 0
            if edge:
                px[x, y] = OL
            elif y > H - 6:
                px[x, y] = WOOD_D
            else:
                px[x, y] = WOOD_L if x <= 2 else (WOOD_D if x == w - 2 else WOOD)
    # перекладина торцом
    for ry in (9, 21):
        px[0, ry] = RAIL
        px[w - 1, ry] = RAIL
    save(im, "by30_fence_s")


def post():
    """Угловой столбик — потолще, с шапочкой."""
    w, h = 10, H + 3
    im = Image.new("RGBA", (w, h), T)
    px = im.load()
    for y in range(h):
        for x in range(w):
            edge = x in (0, w - 1) or y in (0, h - 1) or (y == 3 and True)
            px[x, y] = OL if edge else (WOOD_L if x <= 2 or y < 3 else (WOOD_D if x >= w - 3 else WOOD))
    save(im, "by30_post")


def arch_open():
    """Арка-калитка с распахнутой створкой: проход пустой, створка прижата к правому столбу."""
    src = Image.open(os.path.join(ART, "by29_gate_front.png")).convert("RGBA")
    w, h = src.size
    im = src.copy()
    px = im.load()
    sp = src.load()
    # где кончаются столбы: ищем внутреннюю границу по строке у самого низа
    y = h - 4
    row = [sp[x, y][3] for x in range(w)]
    xs = [x for x in range(w) if row[x] > 0]
    # столб слева: первые непрерывные непрозрачные пиксели до тёмного шва створки
    left_in, right_in = 9, w - 10
    # убираем доски створки (всё внутри столбов ниже свода)
    arch_top = None
    for yy in range(h):
        if sp[w // 2, yy][3] > 0 and arch_top is None:
            arch_top = yy
    door_top = None
    for yy in range(arch_top + 4, h):
        c = sp[w // 2, yy]
        if c[3] > 0 and c[0] > 150 and c[1] > 110:     # светлое дерево створки
            door_top = yy - 3
            break
    door_top = 22     # верх зубцов створки (по картинке by29_gate_front)
    left_in, right_in = 10, 41
    for yy in range(door_top, h):
        for xx in range(left_in, right_in + 1):
            px[xx, yy] = T
    # распахнутая створка: узкая полоска у правого столба (видна торцом и чуть внутрь)
    dw = 5
    x0 = right_in - dw + 1
    for yy in range(door_top + 4, h):
        for k in range(dw):
            edge = k in (0, dw - 1) or yy in (door_top + 4, h - 1)
            px[x0 + k, yy] = OL if edge else (WOOD_L if k == 1 else WOOD_D if k == dw - 2 else WOOD)
    for ry in (door_top + 12, h - 10):
        for k in range(1, dw - 1):
            px[x0 + k, ry] = RAIL
    save(im, "by30_arch_open")
    print("  ", xs[:3], xs[-3:], "door_top", door_top, "arch_top", arch_top)


if __name__ == "__main__":
    fence_h()
    fence_side()
    post()
    arch_open()
