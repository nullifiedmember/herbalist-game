"""Бестиарий «Лесного травника»: из data.json (выгружает игра, bestiary24.gd) делает index.html.

Запуск всего бестиария заново:
  godot --headless --path game -- --classic --shot=../screenshots/_tmp.png --v24=bestiary "--out=<папка>"
  python game/tools/bestiary24.py <папка>
"""
import html
import json
import sys
from pathlib import Path

CSS = """
:root { --paper:#f3e6c4; --paper2:#e9d6a8; --ink:#3a2718; --soft:#6b4f36; --faint:rgba(58,39,24,.25); --accent:#7a2a32; }
* { box-sizing:border-box; }
body { margin:0; background:#2b2118; color:var(--ink); font-family:'Palatino Linotype',Georgia,serif; }
header { background:linear-gradient(#3a2a1c,#2b2118); color:#f3e6c4; text-align:center; padding:28px 16px 18px; border-bottom:4px solid #8a6a3a; }
header h1 { font-family:Gabriola,'Palatino Linotype',serif; font-size:64px; margin:0; font-weight:normal; letter-spacing:1px; }
header p { margin:6px 0 14px; color:#d8c39a; font-style:italic; }
#q { width:min(520px,90vw); padding:10px 16px; font-size:18px; border-radius:22px; border:2px solid #8a6a3a; background:#f3e6c4; color:var(--ink); font-family:inherit; }
nav { display:flex; flex-wrap:wrap; justify-content:center; gap:10px; padding:16px; background:#2b2118; position:sticky; top:0; z-index:5; border-bottom:2px solid #5a4028; }
nav a { display:flex; align-items:center; gap:8px; padding:6px 12px 6px 6px; border-radius:10px; background:var(--paper); color:var(--ink); text-decoration:none; font-size:17px; border:2px solid #8a6a3a; }
nav a:hover { background:#fff3d4; }
nav img { width:32px; height:32px; object-fit:contain; image-rendering:pixelated; }
nav small { color:var(--soft); }
main { max-width:1280px; margin:0 auto; padding:18px; }
section.sec { background:var(--paper); border:3px solid #8a6a3a; border-radius:6px; margin:26px 0; padding:22px 28px 30px; box-shadow:0 6px 24px rgba(0,0,0,.45), inset 0 0 60px rgba(150,110,50,.25); }
section.sec > h2 { font-family:Gabriola,'Palatino Linotype',serif; font-weight:normal; font-size:52px; margin:0; text-align:center; }
.intro { text-align:center; font-style:italic; color:var(--soft); max-width:860px; margin:4px auto 14px; }
.orn { text-align:center; color:var(--soft); letter-spacing:6px; margin:-2px 0 8px; }
h3 { font-size:26px; margin:26px 0 4px; border-bottom:1px solid var(--faint); padding-bottom:4px; }
.about { color:var(--soft); font-style:italic; margin:4px 0 10px; }
.grid { display:grid; grid-template-columns:repeat(auto-fill,minmax(280px,1fr)); gap:14px; margin-top:12px; }
.grid.small { grid-template-columns:repeat(auto-fill,minmax(200px,1fr)); gap:8px; }
.card { display:flex; gap:12px; background:rgba(255,250,235,.55); border:1px solid var(--faint); border-radius:6px; padding:10px; }
.card .pic { flex:0 0 96px; height:96px; overflow:visible; box-sizing:border-box; display:flex; align-items:center; justify-content:center; background:radial-gradient(circle,#fff6dc 30%,#ead7a8 100%); border:1px solid var(--faint); border-radius:50%; position:relative; }
.card .pic img { max-width:80px; max-height:80px; image-rendering:pixelated; }
.card .pic img.big { width:62px; height:62px; object-fit:contain; padding:2px; }   /* v27: картинка целиком внутри круга, с отступами */
.card .pic img.f2 { position:absolute; right:-6px; bottom:-6px; width:30px; height:30px; object-fit:contain; background:var(--paper); border-radius:50%; border:1px solid var(--faint); }
.card .pic .walk { display:block; background-repeat:no-repeat; image-rendering:pixelated; animation:walk var(--d,.6s) steps(var(--n)) infinite; }
@keyframes walk { to { background-position-x:calc(var(--w) * var(--n) * -1); } }
.small .card .pic { flex-basis:56px; height:56px; border-radius:8px; }
.small .card .pic img { max-width:48px; max-height:48px; }
.small .card .pic img.big { width:40px; height:40px; }
.card h4 { margin:0; font-size:19px; }
.card .sub { font-style:italic; color:var(--soft); font-size:14px; }
.card p { margin:3px 0 0; font-size:14.5px; line-height:1.3; }
.small .card p { font-size:13px; }
.tag { display:inline-block; font-size:12px; padding:1px 7px; border-radius:9px; background:#5a7a4a; color:#fff; margin-left:4px; vertical-align:middle; }
.rar1 { box-shadow:inset 3px 0 0 #7ab0f0; } .rar2 { box-shadow:inset 3px 0 0 #c890f0; } .rar3 { box-shadow:inset 3px 0 0 #f8c040; background:rgba(255,240,190,.7); }
.hide { display:none !important; }
.snd { display:inline-block; margin:5px 6px 0 0; padding:2px 10px; font-size:14px; font-family:inherit; border-radius:12px; border:1px solid #8a6a3a; background:#fff3d4; color:var(--ink); cursor:pointer; }
.snd:hover { background:#f8e2a8; }
footer { color:#b8a07a; text-align:center; padding:20px; font-style:italic; }
.top { position:fixed; right:18px; bottom:18px; background:var(--paper); border:2px solid #8a6a3a; border-radius:50%; width:48px; height:48px; display:flex; align-items:center; justify-content:center; text-decoration:none; color:var(--ink); font-size:24px; }
"""

JS = """
let au = null;
document.addEventListener('click', ev => {
  const b = ev.target.closest('.snd'); if (!b) return;
  if (au) au.pause();
  au = new Audio(b.dataset.a); au.play();
});
const q = document.getElementById('q');
q.addEventListener('input', () => {
  const t = q.value.trim().toLowerCase();
  document.querySelectorAll('.card').forEach(c => c.classList.toggle('hide', t && !c.dataset.s.includes(t)));
  document.querySelectorAll('.grp').forEach(g => g.classList.toggle('hide', t && !g.querySelector('.card:not(.hide)')));
  document.querySelectorAll('section.sec').forEach(s => s.classList.toggle('hide', t && !s.querySelector('.card:not(.hide)')));
});
"""

RAR_TAG = {"rar1": "редкое", "rar2": "очень редкое", "rar3": "легендарное"}


def esc(s):
    return html.escape(str(s))


def card(e):
    tags = [t for t in e.get("tags", []) if t]
    cls = "card"
    tag_html = ""
    for t in tags:
        if t.startswith("rar"):
            if t != "rar0":
                cls += " " + t
        else:
            tag_html += f'<span class="tag">{esc(t)}</span>'
    img = f'<img class="big" src="{esc(e["img"])}" alt="" loading="lazy">' if e.get("img") else ""
    if e.get("walk"):   # v28: анимация ходьбы из полоски кадров
        w, h, n = int(e["walk_w"]), int(e["walk_h"]), int(e["walk_n"])
        k = min(66 / w, 66 / h)
        k = max(1, int(k)) if k >= 1 else k   # целый масштаб, чтобы пиксели были чёткими
        dw, dh = round(w * k), round(h * k)
        img = (f'<div class="walk" title="идёт" style="width:{dw}px;height:{dh}px;background-image:url({esc(e["walk"])});'
               f'background-size:{dw * n}px {dh}px;--n:{n};--w:{dw}px"></div>')
    if e.get("img2"):
        img += f'<img class="f2" src="{esc(e["img2"])}" alt="" loading="lazy" title="{esc(e.get("img2_t", "перо"))}">'
    lines = "".join(f"<p>{esc(t)}</p>" for t in e.get("text", []))
    if e.get("voice"):   # голос зверя: послушать крик и довольный звук
        lines += f'<button class="snd" data-a="{esc(e["voice"])}">🔊 голос</button>'
        if e.get("voice_pet"):
            lines += f'<button class="snd" data-a="{esc(e["voice_pet"])}">♥ гладят</button>'

    sub = f'<div class="sub">{esc(e["sub"])}</div>' if e.get("sub") else ""
    search = " ".join([e.get("name", ""), e.get("sub", "")] + e.get("text", [])).lower()
    return (f'<div class="{cls}" data-s="{esc(search)}"><div class="pic">{img}</div>'
            f'<div><h4>{esc(e["name"])}{tag_html}</h4>{sub}{lines}</div></div>')


def build(folder: Path):
    data = json.loads((folder / "data.json").read_text(encoding="utf-8"))
    secs = data["sections"]
    total = sum(len(g["entries"]) for s in secs for g in s["groups"])
    nav = []
    body = []
    for s in secs:
        n = sum(len(g["entries"]) for g in s["groups"])
        icon = f'<img src="{esc(s.get("icon", ""))}" alt="">' if s.get("icon") else ""
        nav.append(f'<a href="#{esc(s["id"])}">{icon}{esc(s["title"])} <small>{n}</small></a>')
        parts = [f'<section class="sec" id="{esc(s["id"])}"><h2>{esc(s["title"])}</h2><div class="orn">❦ ✦ ❦</div>']
        if s.get("intro"):
            parts.append(f'<p class="intro">{esc(s["intro"])}</p>')
        for g in s["groups"]:
            if not g["entries"] and not g.get("about"):
                continue
            small = " small" if g.get("small") else ""
            parts.append(f'<div class="grp"><h3>{esc(g["title"])} <small>({len(g["entries"])})</small></h3>')
            if g.get("about"):
                parts.append(f'<p class="about">{esc(g["about"])}</p>')
            parts.append(f'<div class="grid{small}">' + "".join(card(e) for e in g["entries"]) + "</div></div>")
        parts.append("</section>")
        body.append("".join(parts))
    page = f"""<!DOCTYPE html>
<html lang="ru"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{esc(data["title"])}</title><style>{CSS}</style></head>
<body id="up"><header><h1>{esc(data["title"])}</h1>
<p>Всё, что есть в игре: {total} записей — травы, зелья, звери, птицы, рыбы, монстры, жители и вещи.</p>
<input id="q" type="search" placeholder="Поиск: мята, сова, сонный чай…"></header>
<nav>{"".join(nav)}</nav><main>{"".join(body)}</main>
<footer>Собрано из файлов игры автоматически. Чтобы обновить — запусти выгрузку заново.</footer>
<a class="top" href="#up" title="наверх">↑</a><script>{JS}</script></body></html>"""
    (folder / "index.html").write_text(page, encoding="utf-8")
    print(f"index.html: {total} записей, {len(secs)} разделов")


if __name__ == "__main__":
    build(Path(sys.argv[1] if len(sys.argv) > 1 else "."))
