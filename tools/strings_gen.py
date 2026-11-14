"""Музыка v20 — смычковые струнные (скрипки, альты, виолончели, контрабасы) в духе торжественно-печального фэнтези:
медленно, минор, длинные ноты, нарастания и спады, сольная скрипка/виолончель поверх ансамбля. Всё синтезируется здесь.
Пишет в game/audio/: music_menu/day/town/night (стерео, петли), jingle_<место> и jingle_town_<земля> (темы мест, 9-14 с),
сухие звуки интерфейса ui_click / ui_select / pickup (без эха).
Запуск из папки game:  python tools/strings_gen.py [--music] [--themes] [--ui]
"""
import os
import sys
import wave

import numpy as np
from scipy.signal import butter, lfilter, fftconvolve

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
RNG = np.random.default_rng(20)


def write(name, x):
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    # убрать гул ниже 60 Гц и чуть приподнять «воздух» скрипок
    x = np.stack([hp(x[:, 0], 60), hp(x[:, 1], 60)], axis=1)
    x = x + np.stack([hp(x[:, 0], 1800), hp(x[:, 1], 1800)], axis=1) * 0.6
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.88
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def write_mono(name, x):
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.8
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def hz(n):
    return 440.0 * 2 ** ((n - 69) / 12.0)


def lp(x, f, order=2):
    b, a = butter(order, min(0.99, f / (SR / 2)), "low")
    return lfilter(b, a, x)


def hp(x, f, order=2):
    b, a = butter(order, f / (SR / 2), "high")
    return lfilter(b, a, x)


def peak_eq(x, f, gain_db, q):
    A = 10 ** (gain_db / 40)
    w0 = 2 * np.pi * f / SR
    al = np.sin(w0) / (2 * q)
    b = [1 + al * A, -2 * np.cos(w0), 1 - al * A]
    a = [1 + al / A, -2 * np.cos(w0), 1 - al / A]
    return lfilter(b, a, x)


# ---------------------------------------------------------------- смычковый голос
# волновые таблицы пилы без «звона» (ограничены по гармоникам для каждой октавы)
TAB_N = 2048
_tabs = {}


def saw_table(fmax):
    key = int(np.log2(max(20.0, fmax)))
    if key in _tabs:
        return _tabs[key]
    top = 2 ** (key + 1)
    K = max(1, int(9000 / top))
    ph = np.arange(TAB_N) / TAB_N * 2 * np.pi
    t = np.zeros(TAB_N)
    for k in range(1, K + 1):
        # чуть приглушённые верхние гармоники — «смычок», а не жужжание
        t += np.sin(k * ph) / k * (1.0 / (1.0 + (k / 14.0) ** 2))
    t /= np.max(np.abs(t))
    _tabs[key] = t
    return t


def smooth_noise(n, rate_hz, rng):
    m = max(2, int(n * rate_hz / SR) + 2)
    pts = rng.normal(0, 1, m)
    return np.interp(np.linspace(0, m - 1, n), np.arange(m), pts)


def bowed(f, dur, dyn=None, vib=0.0055, attack=0.35, release=0.5, rng=None, bright=1.0, legato=False):
    """Одна смычковая нота. dyn — огибающая громкости (массив 0..1) или None (мягкое нарастание и спад)."""
    rng = rng or RNG
    n = int(dur * SR)
    t = np.arange(n) / SR
    vr = rng.uniform(4.6, 5.8)
    vamt = vib * np.clip((t - 0.18) / 0.45, 0, 1)
    fm = 1 + vamt * np.sin(2 * np.pi * vr * t + rng.uniform(0, 6.28)) + 0.0012 * smooth_noise(n, 3.0, rng)
    ph = np.cumsum(f * fm) / SR
    tab = saw_table(f * 1.02)
    idx = (ph % 1.0) * TAB_N
    i0 = idx.astype(int) % TAB_N
    fr = idx - np.floor(idx)
    x = tab[i0] * (1 - fr) + tab[(i0 + 1) % TAB_N] * fr
    if dyn is None:
        a = min(attack, dur * 0.45)
        r = min(release, dur * 0.45)
        dyn = np.ones(n)
        na, nr = int(a * SR), int(r * SR)
        if na > 0:
            dyn[:na] = np.linspace(0, 1, na) ** (1.6 if not legato else 1.0)
        if nr > 0:
            dyn[-nr:] *= np.linspace(1, 0, nr) ** 1.2
        # лёгкое «дыхание» смычка
        dyn *= 0.92 + 0.08 * np.sin(np.pi * np.clip(t / max(dur, 0.01), 0, 1))
    # громче — ярче: динамический фильтр по огибающей (две полосы смешиваются)
    dark = lp(x, 900 + 600 * bright)
    br = lp(x, 3200 + 2400 * bright)
    x = dark * (1 - dyn * 0.75) + br * (dyn * 0.75)
    bow = hp(lp(rng.normal(0, 1, n), 5000), 1800) * 0.025 * dyn
    return (x + bow) * dyn


def body(x, kind):
    """Корпус инструмента: резонансы скрипки / альта / виолончели."""
    if kind == "violin":
        for f, g, q in [(290, 4, 1.4), (550, 2, 1.2), (2800, 4, 1.0), (4500, -6, 0.8)]:
            x = peak_eq(x, f, g, q)
    elif kind == "viola":
        for f, g, q in [(230, 4, 1.4), (440, 3, 1.2), (1800, 3, 1.0), (3800, -6, 0.8)]:
            x = peak_eq(x, f, g, q)
    else:  # cello / bass
        for f, g, q in [(110, 4, 1.2), (220, 4, 1.4), (1100, 2, 1.0), (2600, -7, 0.8)]:
            x = peak_eq(x, f, g, q)
    return x


def section(f, dur, voices=4, detune=0.006, **kw):
    """Группа инструментов в унисон: несколько чуть расстроенных голосов с разным вибрато и сдвигом."""
    n = int(dur * SR)
    out = np.zeros(n + int(0.03 * SR))
    for v in range(voices):
        r = np.random.default_rng(int(f * 13) + v * 101 + int(dur * 7))
        d = 1 + r.uniform(-detune, detune)
        x = bowed(f * d, dur, rng=r, **kw)
        off = int(r.uniform(0, 0.025) * SR)
        out[off:off + len(x)] += x
    return out[:n] / np.sqrt(voices)


# ---------------------------------------------------------------- зал (стерео)
def hall_ir(dur=3.0, seed=4):
    r = np.random.default_rng(seed)
    n = int(dur * SR)
    t = np.arange(n) / SR
    irs = []
    for ch in range(2):
        noise = r.normal(0, 1, n)
        # высокие гаснут быстрее низких
        low = lp(noise, 700) * np.exp(-t * 2.0)
        mid = hp(lp(noise, 3000), 700) * np.exp(-t * 2.9)
        hi = hp(noise, 3000) * np.exp(-t * 5.5) * 0.4
        ir = low + mid + hi
        # ранние отражения
        for k in range(12):
            d = int(r.uniform(0.008, 0.08) * SR)
            ir[d] += r.uniform(-1, 1) * 2.5
        ir[: int(0.012 * SR)] *= np.linspace(0, 1, int(0.012 * SR))
        ir /= np.sqrt(np.sum(ir ** 2))
        irs.append(ir)
    return irs


IR = None


def hall(x, wet=0.3, width=0.6):
    """x: (n,2) -> с залом."""
    global IR
    if IR is None:
        IR = hall_ir()
    out = np.zeros((len(x) + len(IR[0]) - 1, 2))
    mono = x.mean(axis=1)
    for ch in range(2):
        w = fftconvolve(mono * width + x[:, ch] * (1 - width), IR[ch])
        out[: len(w), ch] += w * wet * 2.2
        out[: len(x), ch] += x[:, ch] * (1 - wet)
    return out


def pan(x, p):
    """p: -1 лево .. 1 право (равная мощность)."""
    a = (p + 1) * np.pi / 4
    return np.stack([x * np.cos(a), x * np.sin(a)], axis=1)


def place(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[: j - i]


# ---------------------------------------------------------------- гармония
AEOL = [0, 2, 3, 5, 7, 8, 10]
DOR = [0, 2, 3, 5, 7, 9, 10]
HARM = [0, 2, 3, 5, 7, 8, 11]
ION = [0, 2, 4, 5, 7, 9, 11]


def deg(root, mode, d):
    o, k = divmod(d, 7)
    return root + 12 * o + mode[k]


def chord(root, mode, d):
    return [deg(root, mode, d), deg(root, mode, d + 2), deg(root, mode, d + 4)]


def melody_line(rng, prog, root, mode, beats_per_bar, start_deg=7):
    """Мелодия по аккордам: длинные ноты (2-4 доли), шаги по ступеням, фразы по 4 такта: подъём к вершине и спуск,
    в конце фразы — опора на звук аккорда. Возвращает [(доля, длительность, midi)]."""
    out = []
    d = start_deg
    for b, ch in enumerate(prog):
        tones = [ch % 7, (ch + 2) % 7, (ch + 4) % 7]
        phrase_pos = b % 4
        t = 0.0
        while t < beats_per_bar - 0.01:
            if phrase_pos == 3:
                dur = beats_per_bar - t
            else:
                dur = float(rng.choice([1.0, 2.0, 2.0, 3.0, 1.5])) if beats_per_bar >= 4 else float(rng.choice([1.0, 2.0, 3.0]))
                dur = min(dur, beats_per_bar - t)
            # направление: первая половина фразы — вверх, вторая — вниз
            up = phrase_pos < 2
            step = int(rng.choice([1, 1, 2, 0, -1] if up else [-1, -1, -2, 0, 1]))
            d = int(np.clip(d + step, 4, 13))
            # на сильной доле — к ближайшему звуку аккорда
            if t == 0.0 or phrase_pos == 3:
                cands = [x + 7 * o for x in tones for o in (0, 1, 2)]
                d = min(cands, key=lambda c: abs(c - d))
            out.append((b * beats_per_bar + t, dur, deg(root, mode, d)))
            t += dur
    return out


# ---------------------------------------------------------------- пьесы
def piece(name, bpm, root, mode, prog, beats, style, seed, mel_inst="violin", mel_from=4, tail=3.5):
    rng = np.random.default_rng(seed)
    beat = 60.0 / bpm
    bars = len(prog)
    total = bars * beats * beat
    n = int((total + tail) * SR)
    mix = np.zeros((n, 2))
    # контрабасы и виолончели: корень аккорда, длинно (на две доли — у городского вальса)
    for b, ch in enumerate(prog):
        t0 = b * beats * beat
        c = chord(root - 24, mode, ch)
        bar_len = beats * beat
        if style == "waltz":
            for k in range(beats):
                note = c[0] if k == 0 else c[1 + (k % 2)] + 12
                x = body(bowed(hz(note), beat * 0.9, attack=0.05, release=0.2, rng=rng, bright=0.6), "cello") * (0.5 if k == 0 else 0.28)
                place(mix, pan(x, -0.35 if k == 0 else 0.25), t0 + k * beat)
        else:
            x = body(section(hz(c[0]), bar_len + 0.25, voices=3, attack=0.5, release=0.7, bright=0.5), "cello") * 0.3
            place(mix, pan(x, -0.3), t0)
            if style == "menu" and b % 2 == 1:
                # виолончели: медленное движение квинта-тоника
                x2 = body(section(hz(c[2] - 12), bar_len * 0.5 + 0.2, voices=2, attack=0.3, bright=0.7), "cello") * 0.35
                place(mix, pan(x2, -0.45), t0 + bar_len * 0.5)
    # альты и вторые скрипки: аккорд долгим нарастанием
    for b, ch in enumerate(prog):
        t0 = b * beats * beat
        c = chord(root, mode, ch)
        bar_len = beats * beat
        sw = np.sin(np.pi * np.linspace(0, 1, int((bar_len + 0.4) * SR))) ** 0.8 * 0.85 + 0.15
        for i, note in enumerate([c[0], c[1], c[2] + (12 if style == "night" else 0)]):
            inst = "viola" if i < 2 else "violin"
            amp = 0.22 if style != "night" else 0.16
            x = section(hz(note), bar_len + 0.4, voices=4, attack=0.6, release=0.6, bright=0.45 if style == "night" else 0.6)
            x = body(x * sw[: len(x)], inst) * amp
            place(mix, pan(x, [-0.15, 0.2, 0.45][i]), t0)
    # соло: скрипка (или виолончель) — мелодия с середины
    mel = melody_line(rng, prog, root + (12 if mel_inst == "violin" else 0), mode, beats, start_deg=7 if mel_inst != "cello" else 5)
    for (st, du, m) in mel:
        if st < mel_from * beats:
            continue
        f = hz(m - (12 if mel_inst == "cello" else 0))
        x = bowed(f, du * beat + 0.25, attack=0.18 if du > 1 else 0.08, release=0.35, vib=0.0075, bright=1.0, rng=rng, legato=True)
        x = body(x, mel_inst) * (0.42 if style != "night" else 0.3)
        place(mix, pan(x, 0.05), st * beat)
    # ночью — высокие флажолеты скрипок, едва слышно
    if style == "night":
        for b, ch in enumerate(prog):
            if b % 2 == 0:
                c = chord(root + 24, mode, ch)
                x = body(section(hz(c[2]), beats * beat * 2, voices=3, attack=1.5, release=1.5, bright=0.3, vib=0.003), "violin") * 0.07
                place(mix, pan(x, 0.5), b * beats * beat)
    out = hall(mix, wet=0.32 if style != "waltz" else 0.24)
    # петля: хвост зала переносится в начало — шва нет
    L = int(total * SR)
    body_ = out[:L].copy()
    tail_ = out[L:]
    k = min(len(tail_), L)
    body_[:k] += tail_[:k]
    write(name, body_)
    print("  ", name, round(L / SR), "c")


def music():
    # меню: ре минор, медленно и торжественно — ансамбль, потом соло скрипки
    piece("music_menu", 58, 62, AEOL, [0, 5, 2, 6, 0, 3, 4, 4, 5, 2, 6, 0, 3, 5, 4, 0], 4, "menu", 7, "violin", mel_from=4)
    # день: ля дорийский, светлее, соло альта
    piece("music_day", 64, 57, DOR, [0, 3, 6, 4, 0, 2, 3, 0, 5, 3, 6, 4, 0, 2, 4, 0], 4, "day", 23, "viola", mel_from=2)
    # город: фа мажор, на три доли — тёплый «вальс» смычками
    piece("music_town", 84, 65, ION, [0, 3, 4, 0, 5, 3, 1, 4, 0, 3, 4, 5, 3, 1, 4, 0], 3, "waltz", 31, "violin", mel_from=0)
    # ночь: ми минор, очень тихо — виолончель поёт
    piece("music_night", 50, 52, AEOL, [0, 5, 3, 4, 0, 5, 6, 4], 4, "night", 41, "cello", mel_from=1)


# ---------------------------------------------------------------- темы мест (при первом входе)
THEMES = {
    # место: (тоника, лад, мотив (ступени), инструмент соло, темп долей/нота, характер)
    "home": (62, ION, [4, 5, 7, 9, 7, 5, 4], "violin", 0.62, "warm"),
    "meadow": (67, ION, [2, 4, 5, 7, 9, 7], "violin", 0.55, "warm"),
    "forest": (62, DOR, [0, 2, 3, 5, 4, 2], "viola", 0.6, "dark"),
    "unicorn": (72, ION, [4, 7, 9, 11, 9, 7, 11], "violin", 0.48, "bright"),
    "grotto": (64, AEOL, [0, 4, 3, 7, 5, 4], "viola", 0.7, "mystic"),
    "swamp": (55, AEOL, [0, 1, 0, -1, -3, -2], "cello", 0.8, "dark"),
    "cats": (69, ION, [7, 9, 11, 12, 11, 9, 14], "violin", 0.42, "bright"),
    "spider": (57, HARM, [0, 2, 3, 6, 4, 3], "viola", 0.65, "mystic"),
    "gothic": (57, HARM, [0, 3, 2, 6, 4, 3, 0], "cello", 0.75, "grim"),
    "knights": (62, ION, [0, 4, 7, 9, 11, 9, 7], "violin", 0.5, "noble"),
    "elves": (66, DOR, [4, 6, 7, 9, 11, 9, 7], "violin", 0.55, "bright"),
    "mages": (64, DOR, [0, 4, 7, 9, 8, 7], "viola", 0.6, "mystic"),
    "orcs": (52, AEOL, [0, 0, 3, 2, 0, -2], "cello", 0.5, "grim"),
    "goblins": (60, DOR, [4, 2, 5, 3, 6, 4], "viola", 0.38, "warm"),
    "dwarves": (55, DOR, [0, 2, 4, 5, 7, 5], "cello", 0.55, "noble"),
    "japan": (69, [0, 1, 5, 7, 8, 12, 13], [0, 1, 3, 4, 3, 1, 0], "violin", 0.6, "mystic"),
    "sea": (62, ION, [4, 7, 9, 11, 9, 7, 4], "violin", 0.62, "bright"),
    "birch": (67, ION, [7, 6, 4, 6, 8, 7], "violin", 0.55, "warm"),
    "taiga": (57, AEOL, [0, 2, 3, 4, 3, 0], "cello", 0.65, "dark"),
    "autumn": (64, AEOL, [7, 6, 4, 3, 4, 7], "viola", 0.6, "warm"),
    "flowers": (72, ION, [4, 5, 7, 9, 11, 12], "violin", 0.45, "bright"),
    "beach": (67, ION, [0, 4, 7, 6, 4, 9], "violin", 0.55, "warm"),
    "opensea": (62, DOR, [0, 4, 7, 11], "viola", 0.9, "mystic"),
    "under": (74, ION, [0, 4, 2, 7, 5, 9, 7], "violin", 0.5, "mystic"),
}


def theme(name, root, mode, motif, inst, step, char, town=False):
    rng = np.random.default_rng(sum(map(ord, name)))
    notes = list(motif)
    if town:
        # город: тот же мотив, но шире и с ответом в конце (каданс)
        notes = notes + notes[-2::-1][:3] + [7]
    n_len = len(notes) * step + 4.5
    n = int((n_len + 3.0) * SR)
    mix = np.zeros((n, 2))
    # аккорд-подложка: нарастает, держится и гаснет; к концу — разрешение в тонику
    tonic = chord(root - 12, mode if len(mode) == 7 else AEOL, 0)
    pre = chord(root - 12, mode if len(mode) == 7 else AEOL, 4 if char in ("noble", "warm", "bright") else 5)
    half = len(notes) * step * 0.5
    for part, (c, t0, d) in enumerate([(tonic, 0.0, half + 0.6), (pre, half, half + 0.4), (tonic, len(notes) * step, 3.6)]):
        for i, m in enumerate(c):
            inst_pad = "viola" if i < 2 else "violin"
            x = body(section(hz(m), d, voices=4, attack=min(1.2, d * 0.4), release=min(1.4, d * 0.45), bright=0.55), inst_pad) * 0.22
            place(mix, pan(x, [-0.25, 0.1, 0.4][i]), t0)
        x = body(section(hz(c[0] - 12), d, voices=3, attack=0.6, release=0.9, bright=0.4), "cello") * (0.28 if char != "grim" else 0.4)
        place(mix, pan(x, -0.35), t0)
    if char == "grim":
        # тремоло низких струн: тревожно
        tr = section(hz(root - 12), len(notes) * step, voices=3, attack=0.4, bright=0.8)
        tr *= 0.6 + 0.4 * np.sin(2 * np.pi * 7 * np.arange(len(tr)) / SR) ** 2
        place(mix, pan(body(tr, "cello") * 0.12, -0.2), 0.0)
    # соло
    md = mode if len(mode) == 7 else AEOL
    for i, d in enumerate(notes):
        m = deg(root, md, d) if len(mode) == 7 else root + mode[d % 7] + 12 * (d // 7)
        if inst == "cello":
            m -= 12
        du = step * (2.2 if i == len(notes) - 1 else 1.08)
        x = bowed(hz(m), du, attack=0.12, release=0.3 if i < len(notes) - 1 else 1.2, vib=0.008, bright=1.0, rng=rng, legato=True)
        place(mix, pan(body(x, inst) * 0.5, 0.05), 0.35 + i * step)
    if char in ("bright", "mystic"):
        # высокие скрипки-флажолеты: блеск
        x = body(section(hz(deg(root + 24, md, 4)), len(notes) * step + 2.0, voices=3, attack=1.2, release=1.5, bright=0.3, vib=0.003), "violin") * 0.06
        place(mix, pan(x, 0.55), 0.6)
    out = hall(mix, wet=0.33)
    # мягкое окончание
    fade = int(1.5 * SR)
    out[-fade:] *= np.linspace(1, 0, fade)[:, None]
    write(("jingle_town_" if town else "jingle_") + name, out)


def themes():
    for k, (root, mode, mot, inst, step, ch) in THEMES.items():
        theme(k, root, mode, mot, inst, step, ch)
    for land in ["cats", "spider", "gothic", "knights", "elves", "mages", "orcs", "goblins", "dwarves", "japan"]:
        root, mode, mot, inst, step, ch = THEMES[land]
        theme(land, root, mode, mot, inst, step * 0.92, ch, town=True)
    print("  тем мест:", len(THEMES) + 10)


# ---------------------------------------------------------------- интерфейс: сухо, мягко, без эха
def ui():
    def env(n, a, r):
        e = np.ones(n)
        e[:a] = np.linspace(0, 1, a)
        e[-r:] *= np.linspace(1, 0, r) ** 2
        return e

    # щелчок: мягкий деревянный «ток»
    n = int(0.06 * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * 820 * t) * np.exp(-t * 90) * 0.7 + np.sin(2 * np.pi * 1640 * t) * np.exp(-t * 160) * 0.15
    x += lp(RNG.normal(0, 1, n), 2500) * np.exp(-t * 400) * 0.25
    write_mono("ui_click", lp(x, 3500))
    # выбор: два тихих тона вверх (как деревянные колокольчики, коротко)
    n = int(0.22 * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for i, (f, at) in enumerate([(660, 0.0), (990, 0.07)]):
        k = int(at * SR)
        tt = t[: n - k]
        x[k:] += (np.sin(2 * np.pi * f * tt) + 0.2 * np.sin(4 * np.pi * f * tt)) * np.exp(-tt * 28) * (0.8 if i else 0.6)
    write_mono("ui_select", lp(x, 4000) * env(n, 40, 600))
    # подобрала: тихий «плюх» вверх и шорох
    n = int(0.16 * SR)
    t = np.arange(n) / SR
    f = 480 + 520 * (t / t[-1]) ** 0.6
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 22) * 0.6
    x += hp(lp(RNG.normal(0, 1, n), 5000), 1500) * np.exp(-t * 45) * 0.18
    write_mono("pickup", x * env(n, 30, 800))


if __name__ == "__main__":
    a = sys.argv[1:]
    allp = not any(x in a for x in ("--music", "--themes", "--ui"))
    if allp or "--ui" in a:
        ui()
        print("ui")
    if allp or "--themes" in a:
        themes()
    if allp or "--music" in a:
        music()
    print("STRINGS DONE")
