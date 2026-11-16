# -*- coding: utf-8 -*-
"""v31: пиксельный растровый шрифт игры «herb16» из букв DotGothic16 (OFL, fonts/OFL_DotGothic16.txt).
В DotGothic16 русские буквы по японской привычке во всю клетку (16 px), а латиница — в половину (8 px),
из-за этого русский текст выглядит «в разрядку». Здесь каждая буква рисуется на сетке 16 px,
обрезается по краям рисунка и ставится через 1 пиксель — расстановка плотная и ровная.
Набор букв: ASCII + все символы, что встречаются в текстах игры (*.gd, *.json, *.txt в game/).
Выход: fonts/herb16.fnt + fonts/herb16.png (формат BMFont, Godot читает сам).
Запуск: python -I tools/font31.py  (из папки game)
"""
import glob
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
GAME = os.path.normpath(os.path.join(HERE, ".."))
SRC = os.path.join(GAME, "fonts", "DotGothic16.ttf")
OUT_FNT = os.path.join(GAME, "fonts", "herb16.fnt")
OUT_PNG = os.path.join(GAME, "fonts", "herb16.png")
SIZE = 16
GAP = 1          # промежуток между буквами
SPACE = 5        # ширина пробела


def charset():
    cs = set(chr(c) for c in range(32, 127))
    for c in "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя«»—–…№°×·•„“”‘’":
        cs.add(c)
    for pat in ("**/*.gd", "**/*.json", "**/*.txt", "**/*.cfg"):
        for p in glob.glob(os.path.join(GAME, pat), recursive=True):
            if os.sep + ".godot" + os.sep in p:
                continue
            try:
                t = open(p, encoding="utf-8").read()
            except (UnicodeDecodeError, OSError):
                continue
            for ch in t:
                o = ord(ch)
                if o >= 0xA0 and o < 0x3000 and not (0xD800 <= o <= 0xDFFF):
                    cs.add(ch)
    return sorted(cs)


def main():
    font = ImageFont.truetype(SRC, SIZE)
    asc, desc = font.getmetrics()
    lh = asc + desc
    notdef = font.getmask("￿").getbbox()
    glyphs = []
    for ch in charset():
        if ch == " " or ch == " ":
            glyphs.append((ch, None, SPACE))
            continue
        im = Image.new("L", (SIZE * 2, lh), 0)
        ImageDraw.Draw(im).text((0, 0), ch, font=font, fill=255, fontmode="1")
        box = im.getbbox()
        if box is None:
            continue
        # буквы, которых в шрифте нет, PIL рисует пустым прямоугольником .notdef — пропускаем
        if font.getmask(ch).getbbox() == notdef and ch not in "□▯":
            continue
        g = im.crop((box[0], 0, box[2], lh))
        glyphs.append((ch, g, g.width + GAP))
    # упаковка в атлас по строкам
    aw = 512
    x = y = 0
    places = []
    for ch, g, adv in glyphs:
        w = g.width if g else 0
        if x + w + 1 > aw:
            x = 0
            y += lh + 1
        places.append((ch, g, adv, x, y))
        x += w + 1
    ah = y + lh + 1
    atlas = Image.new("RGBA", (aw, ah), (0, 0, 0, 0))
    for ch, g, adv, gx, gy in places:
        if g:
            white = Image.new("RGBA", g.size, (255, 255, 255, 255))
            atlas.paste(white, (gx, gy), g)
    atlas.save(OUT_PNG)
    lines = [
        'info face="herb16" size=%d bold=0 italic=0 charset="" unicode=1 stretchH=100 smooth=0 aa=1 padding=0,0,0,0 spacing=1,1 outline=0' % SIZE,
        "common lineHeight=%d base=%d scaleW=%d scaleH=%d pages=1 packed=0 alphaChnl=0 redChnl=4 greenChnl=4 blueChnl=4" % (lh, asc, aw, ah),
        'page id=0 file="herb16.png"',
        "chars count=%d" % len(places),
    ]
    for ch, g, adv, gx, gy in places:
        w = g.width if g else 0
        h = lh if g else 0
        lines.append("char id=%d x=%d y=%d width=%d height=%d xoffset=0 yoffset=0 xadvance=%d page=0 chnl=15"
                     % (ord(ch), gx, gy, w, h, adv))
    open(OUT_FNT, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")
    # превью
    prev = Image.new("RGBA", (900, 60), (246, 233, 204, 255))
    d = ImageDraw.Draw(prev)
    xx = 6
    for ch in "Огород: мотыгой (ЛКМ) копай грядки где хочешь, по пустой — засыпать. 10:00":
        for c2, g, adv, gx, gy in places:
            if c2 == ch:
                if g:
                    ink = Image.new("RGBA", g.size, (58, 39, 24, 255))
                    prev.paste(ink, (xx, 8), g)
                xx += adv
                break
    prev.resize((prev.width * 2, prev.height * 2), Image.NEAREST).save(
        os.path.join(GAME, "..", "screenshots", "font31_preview_x2.png"))
    print("ok herb16:", len(places), "glyphs, atlas", atlas.size, "lineHeight", lh, "base", asc)


if __name__ == "__main__":
    main()
