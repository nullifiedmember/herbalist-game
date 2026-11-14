"""Крупное превью: python tools/fauna25_view.py id1 id2 ... -> screenshots/fauna25_view.png (кадры 0,2,4,7,10 x4)"""
import sys, os
from PIL import Image
HERE = os.path.dirname(os.path.abspath(__file__))
ids = sys.argv[1:]
rows = []
for sid in ids:
    im = Image.open(os.path.join(HERE, "..", "art", "animal_%s.png" % sid))
    w = im.width // 12; h = im.height
    row = Image.new("RGBA", (w * 5 + 10, h + 4), (96, 128, 104, 255))
    for i, f in enumerate((0, 2, 4, 7, 10)):
        row.alpha_composite(im.crop((f * w, 0, f * w + w, h)), (i * w + 2, 2))
    rows.append(row)
W = max(r.width for r in rows); H = sum(r.height for r in rows)
out = Image.new("RGBA", (W, H), (96, 128, 104, 255))
y = 0
for r in rows:
    out.alpha_composite(r, (0, y)); y += r.height
sc = max(1, min(4, 1500 // W))
out = out.resize((W * sc, H * sc), Image.NEAREST)
out.save(os.path.join(HERE, "..", "..", "screenshots", "fauna25_view.png"))
