"""Музыка и звуки «Лесного травника» — всё синтезируется здесь, своё, без чужих записей.
Запуск: python tools/audio_gen.py  (из папки game). Пишет WAV в game/audio/.
Музыка — средневековый фолк в уютном духе: лютня (щипок), флейта, бубен, бас, мягкий пэд, колокольчики.
"""
import os
import numpy as np
from scipy.signal import fftconvolve, butter, lfilter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
os.makedirs(OUT, exist_ok=True)
rng = np.random.default_rng(7)


def write(name, x, stereo=False):
    import wave
    x = np.asarray(x, dtype=np.float64)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.89
    data = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


def note_hz(n):
    """n — MIDI-номер."""
    return 440.0 * 2 ** ((n - 69) / 12.0)


def env(n, a, d, s, r, total):
    """ADSR в сэмплах на длину total."""
    e = np.ones(total) * s
    a, d, r = int(a * SR), int(d * SR), int(r * SR)
    a = max(a, 1)
    e[:a] = np.linspace(0, 1, a)
    if d > 0:
        e[a:a + d] = np.linspace(1, s, len(e[a:a + d]))
    if r > 0 and total > r:
        e[-r:] *= np.linspace(1, 0, r)
    return e


def lowpass(x, hz, order=2):
    b, a = butter(order, hz / (SR / 2), "low")
    return lfilter(b, a, x)


def highpass(x, hz, order=2):
    b, a = butter(order, hz / (SR / 2), "high")
    return lfilter(b, a, x)


# ------------------------------------------------------------------ инструменты

def pluck(f, dur, bright=0.5, damp=0.996):
    """Лютня/арфа: Карплус-Стронг."""
    n = int(dur * SR)
    p = max(2, int(SR / f))
    buf = rng.uniform(-1, 1, p)
    buf = lowpass(np.concatenate([buf, buf]), 1500 + bright * 5000)[:p]
    out = np.zeros(n)
    for i in range(n):
        out[i] = buf[i % p]
        j = i % p
        buf[j] = damp * 0.5 * (buf[j] + buf[(j + 1) % p])
    out *= np.linspace(1, 0.0, n) ** 0.3
    return out


def flute(f, dur, vib=0.006):
    n = int(dur * SR)
    t = np.arange(n) / SR
    vibr = 1 + vib * np.sin(2 * np.pi * 5.2 * t) * np.clip(t * 2, 0, 1)
    ph = 2 * np.pi * f * np.cumsum(vibr) / SR
    x = np.sin(ph) + 0.18 * np.sin(2 * ph) + 0.06 * np.sin(3 * ph)
    breath = lowpass(rng.normal(0, 1, n), 2500) * 0.05
    return (x + breath) * env(n, 0.07, 0.1, 0.8, min(0.12, dur * 0.4), n)


def pad(freqs, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for f in freqs:
        for det in (-0.25, 0.0, 0.3):
            x += np.sin(2 * np.pi * (f + det) * t + rng.uniform(0, 6)) * 0.33
            x += np.sin(2 * np.pi * 2 * (f + det) * t) * 0.06
    return lowpass(x, 1400) * env(n, dur * 0.35, 0, 1, dur * 0.4, n)


def bell(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    for k, (m, a, dec) in enumerate([(1, 1, 2.2), (2.76, 0.4, 3.5), (5.4, 0.2, 6), (8.93, 0.1, 9)]):
        x += a * np.sin(2 * np.pi * f * m * t) * np.exp(-dec * t)
    return x * env(n, 0.002, 0, 1, 0.05, n)


def frame_drum(dur=0.5, low=True):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f0 = 90 if low else 180
    f = f0 * (1 + 0.6 * np.exp(-t * 30))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * (9 if low else 16))
    x += lowpass(rng.normal(0, 1, n), 3000) * np.exp(-t * 40) * 0.35
    return x


def shaker(dur=0.12):
    n = int(dur * SR)
    t = np.arange(n) / SR
    return highpass(rng.normal(0, 1, n), 5000) * np.exp(-t * 35) * 0.5


def bass(f, dur):
    n = int(dur * SR)
    t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) + 0.3 * np.sin(4 * np.pi * f * t)
    return lowpass(x, 600) * env(n, 0.01, 0.2, 0.6, 0.1, n)


def reverb(x, size=2.2, mix=0.3):
    n = int(size * SR)
    t = np.arange(n) / SR
    ir = rng.normal(0, 1, n) * np.exp(-t * 3.2 / size)
    ir = lowpass(ir, 4500)
    ir /= np.sqrt(np.sum(ir ** 2))
    wet = fftconvolve(x, ir)[:len(x)]
    return x * (1 - mix) + wet * mix * 1.6


def add(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[:j - i]


def loopify(x, tail):
    """Хвост реверба после конца переносится в начало — трек зацикливается без шва."""
    body = x[:-tail].copy()
    body[:tail] += x[-tail:]
    return body


# ------------------------------------------------------------------ композиция

DORIAN = [0, 2, 3, 5, 7, 9, 10]
AEOLIAN = [0, 2, 3, 5, 7, 8, 10]


def scale_note(root, mode, deg):
    o, d = divmod(deg, 7)
    return root + 12 * o + mode[d]


def melody(rng_m, bars, beats, mode, start=7):
    """Мелодия: плавные ходы по ступеням, фразы по 4 такта, конец фразы на устойчивой ступени."""
    notes = []
    deg = start
    for bar in range(bars):
        t = 0.0
        while t < beats - 0.01:
            dur = rng_m.choice([0.5, 0.5, 1.0, 1.0, 1.5, 2.0])
            dur = min(dur, beats - t)
            step = rng_m.choice([-2, -1, -1, 0, 1, 1, 2, 3, -3])
            deg = int(np.clip(deg + step, 3, 12))
            if bar % 4 == 3 and t + dur >= beats - 0.01:
                deg = rng_m.choice([7, 9, 11])
                dur = beats - t
            rest = rng_m.random() < 0.12 and t > 0
            notes.append((bar * beats + t, dur, None if rest else deg))
            t += dur
    return notes


def song(name, bpm, root, mode, prog, bars, style, seed):
    rm = np.random.default_rng(seed)
    beat = 60.0 / bpm
    beats = 3 if style == "waltz" else 4
    total = bars * beats * beat
    tail = 3.0
    buf = np.zeros(int((total + tail) * SR))
    lead = np.zeros_like(buf)
    # две темы: A и B, форма A A B A
    themeA = melody(rm, 4, beats, mode)
    themeB = melody(rm, 4, beats, mode, start=9)
    form = (["A", "A", "B", "A"] * 8)[: bars // 4]
    for bar in range(bars):
        ch = prog[bar % len(prog)]
        chord = [scale_note(root - 12, mode, ch + k) for k in (0, 2, 4)]
        t0 = bar * beats * beat
        # бас
        add(buf, bass(note_hz(chord[0] - 12), beats * beat * 0.95) * 0.5, t0)
        # пэд
        if style != "waltz" or bar % 2 == 0:
            add(buf, pad([note_hz(c) for c in chord], beats * beat * (1 if style != "waltz" else 2)) * 0.12, t0)
        # лютня: перебор
        arp = [0, 1, 2, 1, 2, 3, 2, 1] if beats == 4 else [0, 1, 2, 3, 2, 1]
        for i, k in enumerate(arp):
            n = chord[k % 3] + (12 if k == 3 else 0) + 12
            add(buf, pluck(note_hz(n), beat * 1.8, bright=0.4) * 0.28, t0 + i * beat * beats / len(arp))
        # ударные
        if style == "folk":
            add(buf, frame_drum(0.5, True) * 0.45, t0)
            add(buf, frame_drum(0.4, False) * 0.25, t0 + 2.5 * beat)
            for h in range(8):
                add(buf, shaker() * (0.25 if h % 2 else 0.12), t0 + h * beat / 2)
        elif style == "waltz":
            add(buf, frame_drum(0.6, True) * 0.3, t0)
        # колокольчики в загадочных треках
        if style in ("mystic", "night") and bar % 2 == 1:
            add(buf, bell(note_hz(chord[2] + 24), 2.5) * 0.12, t0 + beat * rm.integers(0, beats))
    # мелодия (флейта / колокольчики ночью)
    sec = 0
    for part in form:
        th = themeA if part == "A" else themeB
        for (st, du, deg) in th:
            if deg is None:
                continue
            f = note_hz(scale_note(root, mode, deg))
            at = (sec * 4 * beats + st) * beat
            if style == "night":
                add(lead, bell(f, du * beat + 1.5) * 0.35, at)
            else:
                add(lead, flute(f, du * beat * 0.95) * 0.3, at)
                if style == "folk" and part == "B":
                    add(lead, pluck(f * 2, du * beat + 0.5, bright=0.8) * 0.12, at)
        sec += 1
    mix = buf + lead
    mix = reverb(mix, size=2.4 if style != "folk" else 1.6, mix=0.32 if style != "folk" else 0.22)
    mix = loopify(mix, int(tail * SR))
    write(name, mix)
    print("  ", name, round(len(mix) / SR), "s")


def music():
    # меню: бодрый фолк, ре дорийский, ~ «ступка и пестик»
    song("music_menu", 100, 62, DORIAN, [0, 0, 3, 4, 0, 6, 3, 4], 32, "folk", 11)
    # день: спокойный загадочный, ля эолийский
    song("music_day", 72, 57, AEOLIAN, [0, 5, 3, 6, 0, 3, 4, 4], 32, "mystic", 23)
    # вальс в городах
    song("music_town", 120, 60, DORIAN, [0, 3, 4, 0, 5, 3, 4, 4], 48, "waltz", 31)
    # ночь: колокольчики и пэд
    song("music_night", 58, 52, AEOLIAN, [0, 5, 3, 4], 24, "night", 41)


# ------------------------------------------------------------------ звуки

def chirp(f0, f1, dur, wob=0.0):
    n = int(dur * SR)
    t = np.arange(n) / SR
    f = np.linspace(f0, f1, n) * (1 + wob * np.sin(2 * np.pi * 40 * t))
    x = np.sin(2 * np.pi * np.cumsum(f) / SR)
    return x * np.sin(np.pi * np.linspace(0, 1, n)) ** 0.7


def sfx():
    # птицы: несколько разных трелей
    for k in range(5):
        r = np.random.default_rng(100 + k)
        x = np.zeros(int(1.6 * SR))
        t = 0.0
        base = r.uniform(2600, 4200)
        for i in range(r.integers(3, 8)):
            d = r.uniform(0.05, 0.14)
            add(x, chirp(base * r.uniform(0.9, 1.3), base * r.uniform(0.7, 1.5), d, wob=r.uniform(0, 0.05)) * r.uniform(0.5, 1), t)
            t += d + r.uniform(0.02, 0.12)
        write("bird_%d" % k, reverb(x, 0.8, 0.2))
    # сова: «у-ху ху-ху»
    x = np.zeros(int(2.2 * SR))
    for i, (st, f, d) in enumerate([(0.0, 420, 0.35), (0.55, 380, 0.18), (0.8, 400, 0.22), (1.1, 370, 0.4)]):
        n = int(d * SR)
        tt = np.arange(n) / SR
        tone = np.sin(2 * np.pi * f * tt * (1 - 0.05 * tt / d)) * np.sin(np.pi * tt / d) ** 1.5
        add(x, lowpass(tone + rng.normal(0, 0.05, n), 900), st)
    write("owl", reverb(x, 1.5, 0.35))
    # сверчки (петля)
    n = int(4 * SR)
    t = np.arange(n) / SR
    pulses = (np.sin(2 * np.pi * 28 * t) > 0.6) * (np.sin(2 * np.pi * 0.9 * t) > -0.2)
    x = np.sin(2 * np.pi * 4600 * t) * pulses * 0.5 + np.sin(2 * np.pi * 5100 * t + 1) * np.roll(pulses, 9000) * 0.3
    write("crickets", lowpass(x, 7000))
    # шелест листвы / ветер (петля)
    n = int(6 * SR)
    t = np.arange(n) / SR
    x = lowpass(rng.normal(0, 1, n), 900) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.17 * t) ** 2)
    x[:SR // 2] *= np.linspace(0, 1, SR // 2)
    x[-SR // 2:] *= np.linspace(1, 0, SR // 2)
    write("wind", x)
    # «бормотание» разговора: короткие слоги разной высоты
    for v, base in enumerate([520, 380, 640, 300]):
        x = np.zeros(int(0.09 * SR))
        n = len(x)
        tt = np.arange(n) / SR
        f = base * (1 + 0.15 * np.sin(np.pi * tt / 0.09))
        tone = np.sin(2 * np.pi * np.cumsum(f) / SR) + 0.4 * np.sin(4 * np.pi * np.cumsum(f) / SR)
        write("talk_%d" % v, lowpass(tone, 2500) * np.sin(np.pi * tt / 0.09))
    # шаги по траве и по камню
    for k in range(3):
        n = int(0.12 * SR)
        tt = np.arange(n) / SR
        x = lowpass(rng.normal(0, 1, n), 1800 + k * 300) * np.exp(-tt * 35)
        write("step_grass_%d" % k, x)
        x2 = lowpass(rng.normal(0, 1, n), 3500) * np.exp(-tt * 55) + np.sin(2 * np.pi * 180 * tt) * np.exp(-tt * 60) * 0.5
        write("step_stone_%d" % k, x2)
    # монета
    x = np.zeros(int(0.5 * SR))
    add(x, bell(1800, 0.4), 0)
    add(x, bell(2400, 0.4), 0.07)
    write("coin", x)
    # сбор травы / предмета
    px_ = pluck(880, 0.3) * 0.5
    add(px_, chirp(500, 1100, 0.15) * 0.8, 0)
    write("pickup", reverb(px_, 0.6, 0.2))
    # клик меню и выбор
    write("ui_click", pluck(1200, 0.08, 0.9) * 0.8)
    write("ui_select", reverb(np.concatenate([pluck(784, 0.12, 0.8), pluck(1175, 0.3, 0.8)]), 0.6, 0.2))
    # дверь (скрип + стук)
    n = int(0.7 * SR)
    tt = np.arange(n) / SR
    creak = np.sin(2 * np.pi * np.cumsum(220 + 60 * np.sin(2 * np.pi * 3 * tt)) / SR) * (np.sin(2 * np.pi * 37 * tt) > 0) * np.exp(-tt * 3)
    x = lowpass(creak, 1500) * 0.4
    add(x, frame_drum(0.3, True) * 0.8, 0.55)
    write("door", x)
    # вода
    n = int(0.5 * SR)
    tt = np.arange(n) / SR
    x = highpass(rng.normal(0, 1, n), 800) * np.exp(-tt * 8) * 0.5
    for i in range(6):
        add(x, chirp(rng.uniform(600, 1400), rng.uniform(1200, 2400), 0.04) * 0.4, rng.uniform(0, 0.35))
    write("water", x)
    # глоток / еда
    write("gulp", lowpass(chirp(200, 380, 0.12), 1200))
    write("munch", lowpass(rng.normal(0, 1, int(0.25 * SR)) * (np.sin(np.linspace(0, 12 * np.pi, int(0.25 * SR))) > 0.3), 2000) * 0.6)
    # мимик клацает
    x = np.zeros(int(0.6 * SR))
    for k in range(3):
        add(x, frame_drum(0.15, False) * 0.8, k * 0.15)
        add(x, shaker(0.1), k * 0.15)
    write("chomp", x)
    # костёр (петля)
    n = int(4 * SR)
    x = lowpass(rng.normal(0, 1, n), 600) * 0.3
    for i in range(70):
        add(x, highpass(rng.normal(0, 1, 300), 2000) * rng.uniform(0.3, 1) * np.exp(-np.arange(300) / 60), rng.uniform(0, 3.9))
    write("fire", x)
    # кабан хрюкает, заяц пищит, ёжик фыркает
    n = int(0.35 * SR)
    tt = np.arange(n) / SR
    grunt = np.sin(2 * np.pi * np.cumsum(110 + 30 * np.sin(2 * np.pi * 9 * tt)) / SR) * (1 + 0.8 * rng.normal(0, 1, n)) * np.sin(np.pi * tt / 0.35)
    write("grunt", lowpass(grunt, 700))
    write("squeak", chirp(1500, 2600, 0.1))
    write("sniff", highpass(rng.normal(0, 1, int(0.2 * SR)), 1500) * np.sin(np.linspace(0, 6 * np.pi, int(0.2 * SR))) ** 2)
    # волшебный звон (мифические звери, редкие грибы)
    x = np.zeros(int(1.5 * SR))
    for i, f in enumerate([1318, 1568, 1976, 2637]):
        add(x, bell(f, 1.2) * 0.5, i * 0.08)
    write("magic", reverb(x, 1.5, 0.4))
    # «уходи» стражи: строгий низкий слог
    write("guard", lowpass(chirp(260, 180, 0.25), 1200))
    # наковальня: звонкий удар
    x = np.zeros(int(0.8 * SR))
    add(x, bell(1250, 0.7) * 0.6, 0)
    add(x, bell(1980, 0.5) * 0.3, 0)
    nn = int(0.05 * SR)
    add(x, highpass(rng.normal(0, 1, nn), 2000) * np.exp(-np.arange(nn) / 200.0), 0)
    write("anvil", x)


def noise(dur):
    return rng.normal(0, 1, int(dur * SR))


def sfx2():
    """Звуки занятий, кошек и зверей (v9)."""
    # мяу: голос скользит вверх и вниз, «м» в начале, «у» в конце
    for k, (f0, f1, f2, d) in enumerate([(520, 820, 560, 0.55), (600, 980, 620, 0.42), (460, 720, 420, 0.7), (700, 1100, 800, 0.3)]):
        n = int(d * SR)
        tt = np.arange(n) / SR
        ph = tt / d
        f = np.where(ph < 0.4, f0 + (f1 - f0) * ph / 0.4, f1 + (f2 - f1) * (ph - 0.4) / 0.6)
        base = np.cumsum(f) / SR * 2 * np.pi
        voice = np.sin(base) + 0.5 * np.sin(2 * base) + 0.25 * np.sin(3 * base) + 0.12 * np.sin(4 * base)
        form = lowpass(voice, 1400 + 1600 * float(np.sin(np.pi * 0.5)))
        e = np.sin(np.pi * np.clip(ph * 1.1, 0, 1)) ** 0.6
        write("meow_%d" % k, reverb(form * e, 0.5, 0.15))
    # мурчание: низкое рокотание 26 раз в секунду, вдох-выдох
    n = int(2.4 * SR)
    tt = np.arange(n) / SR
    rumble = lowpass(noise(2.4), 300) * (0.5 + 0.5 * np.sin(2 * np.pi * 26 * tt)) ** 3
    breath = 0.35 + 0.65 * np.abs(np.sin(np.pi * tt / 1.2))
    write("purr", rumble * breath * np.sin(np.pi * tt / 2.4) ** 0.3)
    # шипение
    n = int(0.6 * SR)
    write("hiss", highpass(noise(0.6), 2500) * np.sin(np.pi * np.arange(n) / n) ** 0.5)
    # выпечка: потрескивание печи + звонкий противень
    x = lowpass(noise(1.2), 500) * 0.25
    for i in range(14):
        add(x, highpass(noise(0.01), 2500) * rng.uniform(0.3, 0.8), rng.uniform(0, 1.1))
    add(x, bell(2200, 0.4) * 0.35, 0.2)
    add(x, bell(2900, 0.3) * 0.2, 0.24)
    write("bake", x)
    # серп по колосьям
    n = int(0.35 * SR)
    tt = np.arange(n) / SR
    x = highpass(noise(0.35), 1800) * np.sin(np.pi * tt / 0.35) ** 2
    add(x, lowpass(noise(0.15), 3000) * np.exp(-np.arange(int(0.15 * SR)) / 900) * 0.4, 0.2)
    write("scythe", x)
    # венчик: быстрые мягкие удары по миске
    x = np.zeros(int(0.8 * SR))
    for i in range(12):
        add(x, bandish(rng.uniform(2200, 2600), 0.03) * 0.6, i * 0.06)
    write("whisk", x)
    # спицы: тихие щелчки
    x = np.zeros(int(0.7 * SR))
    for i in range(6):
        add(x, bell(3200 + rng.uniform(-200, 200), 0.05) * 0.4, i * 0.11)
    write("knit", x)
    # меч: свист + звон
    x = np.zeros(int(0.7 * SR))
    add(x, highpass(chirp(900, 300, 0.18) * noise(0.18)[:int(0.18 * SR)], 1500) * 0.6, 0)
    add(x, bell(1700, 0.5) * 0.5, 0.16)
    add(x, bell(2550, 0.4) * 0.25, 0.16)
    write("sword", x)
    # точило: вжжж
    n = int(0.7 * SR)
    tt = np.arange(n) / SR
    x = highpass(noise(0.7), 3000) * (0.6 + 0.4 * np.sin(2 * np.pi * 14 * tt)) * np.sin(np.pi * tt / 0.7)
    write("grind", x)
    # котёл: буль-буль
    x = np.zeros(int(1.2 * SR))
    for i in range(7):
        add(x, chirp(rng.uniform(180, 300), rng.uniform(500, 800), 0.06) * 0.6, rng.uniform(0, 1.1))
    write("bubble", lowpass(x, 1500))
    # топор по полену
    x = np.zeros(int(0.5 * SR))
    add(x, frame_drum(0.3, True) * 0.9, 0)
    add(x, highpass(noise(0.08), 1200) * np.exp(-np.arange(int(0.08 * SR)) / 400) * 0.8, 0)
    add(x, bell(620, 0.25) * 0.2, 0.01)
    write("chop", x)
    # лук: тетива + стрела в мишень
    x = np.zeros(int(0.8 * SR))
    add(x, pluck(196, 0.3, 0.3) * 0.8, 0)
    add(x, highpass(noise(0.15), 2000) * np.linspace(1, 0, int(0.15 * SR)) * 0.3, 0.05)
    add(x, frame_drum(0.15, False) * 0.7, 0.45)
    write("bow", x)
    # ткацкий станок: деревянный стук-стук
    x = np.zeros(int(0.6 * SR))
    for i, f in enumerate([700, 520]):
        add(x, bell(f, 0.12) * 0.5 + lowpass(noise(0.12), 1500)[:int(0.12 * SR)] * 0.3 * np.exp(-np.arange(int(0.12 * SR)) / 300), i * 0.25)
    write("loom", x)
    # страница книги
    n = int(0.4 * SR)
    tt = np.arange(n) / SR
    write("page", highpass(noise(0.4), 1800) * np.sin(np.pi * tt / 0.4) ** 3 * 0.7)
    # барабан орков
    x = np.zeros(int(0.6 * SR))
    add(x, frame_drum(0.5, True), 0)
    add(x, lowpass(chirp(90, 55, 0.4), 300) * 1.2, 0)
    write("drum", x)
    # мастерская гоблинши: дзынь-клац
    x = np.zeros(int(0.7 * SR))
    for i in range(4):
        add(x, bell(rng.uniform(1500, 3500), 0.15) * 0.4, rng.uniform(0, 0.5))
    add(x, shaker(0.1), 0.3)
    write("tinker", x)
    # лопата / копание
    x = np.zeros(int(0.5 * SR))
    add(x, lowpass(noise(0.25), 1200) * np.exp(-np.arange(int(0.25 * SR)) / 1800), 0)
    add(x, bell(900, 0.15) * 0.2, 0)
    write("dig", x)
    # эль льётся в кружку
    n = int(1.0 * SR)
    tt = np.arange(n) / SR
    x = lowpass(noise(1.0), 2500) * 0.5 * np.sin(np.pi * tt) ** 0.5
    for i in range(10):
        add(x, chirp(rng.uniform(700, 1100), rng.uniform(1200, 1800), 0.03) * 0.3, rng.uniform(0, 0.9))
    write("pour", x)
    # кирка о камень
    x = np.zeros(int(0.6 * SR))
    add(x, bell(2300, 0.4) * 0.5, 0)
    add(x, highpass(noise(0.06), 1500) * np.exp(-np.arange(int(0.06 * SR)) / 250), 0)
    add(x, lowpass(noise(0.2), 900) * np.exp(-np.arange(int(0.2 * SR)) / 1200) * 0.5, 0.02)
    write("pick", x)
    # кря-кря
    x = np.zeros(int(0.6 * SR))
    for i in range(2):
        n = int(0.14 * SR)
        tt = np.arange(n) / SR
        f = 420 * (1 - 0.3 * tt / 0.14)
        b = np.cumsum(f) / SR * 2 * np.pi
        q = np.sign(np.sin(b)) * 0.5 + np.sin(3 * b) * 0.3
        add(x, lowpass(q, 1800) * np.sin(np.pi * tt / 0.14), i * 0.2)
    write("quack", x)
    # ржание единорога + звон
    n = int(1.0 * SR)
    tt = np.arange(n) / SR
    f = 600 + 300 * np.sin(2 * np.pi * 7 * tt) * np.exp(-tt * 1.5) - 200 * tt
    b = np.cumsum(f) / SR * 2 * np.pi
    x = lowpass(np.sin(b) + 0.4 * np.sin(2 * b), 2000) * np.sin(np.pi * tt) ** 0.6 * 0.6
    add(x, bell(1976, 0.8) * 0.3, 0.3)
    write("neigh", reverb(x, 1.0, 0.25))


def jingles():
    """Короткие мелодии при входе в место (2-3 с): у каждого края свой инструмент и лад."""
    J = {
        "home": ("pluck", [67, 71, 74, 79], 0.22, "pad"),
        "meadow": ("flute", [72, 74, 76, 79, 76], 0.2, None),
        "forest": ("flute", [62, 65, 69, 67, 65], 0.26, "pad"),
        "unicorn": ("bell", [84, 88, 91, 96, 91, 88], 0.14, "pad"),
        "grotto": ("bell", [64, 71, 67, 74], 0.3, "pad"),
        "swamp": ("flute", [55, 58, 57, 53], 0.34, None),
        "cats": ("pluck", [76, 79, 81, 84, 81, 88], 0.13, "bells"),
        "spider": ("bell", [69, 72, 76, 75, 72], 0.24, "pad"),
        "gothic": ("pad1", [57, 60, 64, 63, 57], 0.32, "bells"),
        "knights": ("flute", [67, 72, 76, 79, 79, 84], 0.16, "drum"),
        "elves": ("flute", [74, 78, 81, 86, 85, 81], 0.2, "pad"),
        "mages": ("bell", [72, 79, 84, 88, 86, 79], 0.2, "pad"),
        "orcs": ("drumtune", [45, 45, 52, 48], 0.24, "drum"),
        "goblins": ("pluck", [72, 70, 73, 68, 75], 0.12, None),
        "dwarves": ("pluck", [55, 60, 62, 64, 67], 0.18, "drum"),
        "japan": ("pluck", [69, 71, 72, 76, 77, 76], 0.2, "bells"),   # лад «мияко-буси»
        "sea": ("bell", [74, 79, 83, 86, 83, 79], 0.22, "pad"),
        # v13: у каждого края — своя
        "birch": ("flute", [76, 74, 72, 74, 79, 76], 0.2, "pad"),
        "taiga": ("flute", [57, 60, 62, 64, 62, 57], 0.3, "drum"),
        "autumn": ("pluck", [69, 67, 64, 62, 64, 69], 0.22, "pad"),
        "flowers": ("pluck", [79, 81, 84, 86, 88, 91], 0.14, "bells"),
        "beach": ("pluck", [67, 72, 76, 74, 72, 79], 0.18, "bells"),
        "opensea": ("pad1", [62, 66, 69, 74], 0.4, "pad"),
        "under": ("bell", [74, 81, 78, 86, 83, 90, 86], 0.18, "pad"),
    }
    for name, (inst, notes, step, extra) in J.items():
        x = np.zeros(int((len(notes) * step + 2.0) * SR))
        for i, n in enumerate(notes):
            f = note_hz(n)
            t = i * step
            if inst == "pluck":
                add(x, pluck(f, 0.9, 0.6) * 0.7, t)
            elif inst == "flute":
                add(x, flute(f, step * 1.6) * 0.6, t)
            elif inst == "bell":
                add(x, bell(f, 1.0) * 0.5, t)
            elif inst == "pad1":
                add(x, pad([f, f * 1.5], step * 2.0) * 0.5, t)
            elif inst == "drumtune":
                add(x, frame_drum(0.3, True) * 0.9, t)
                add(x, bass(f, step * 1.5) * 0.6, t)
        if extra == "pad":
            add(x, pad([note_hz(notes[0] - 12), note_hz(notes[0] - 5)], len(notes) * step + 1.0) * 0.25, 0)
        elif extra == "bells":
            add(x, bell(note_hz(notes[-1] + 12), 1.2) * 0.3, len(notes) * step)
        elif extra == "drum":
            for k in range(len(notes)):
                add(x, frame_drum(0.2, k % 2 == 0) * 0.5, k * step)
        write("jingle_" + name, reverb(x, 1.4, 0.3))
    # города: тот же лад, что у земли, но мелодия «вверх-вниз», бас и звон колокольчиков в конце
    for land in ["cats", "spider", "gothic", "knights", "elves", "mages", "orcs", "goblins", "dwarves", "japan"]:
        inst, notes, step, extra = J[land]
        mel = notes + notes[-2::-1][:3] + [notes[0] + 12]
        st = step * 0.9
        x = np.zeros(int((len(mel) * st + 2.4) * SR))
        for i, nn in enumerate(mel):
            f = note_hz(nn)
            t = i * st
            if inst in ("pluck", "drumtune"):
                add(x, pluck(f, 0.9, 0.6) * 0.6, t)
            elif inst == "flute":
                add(x, flute(f, st * 1.5) * 0.55, t)
            else:
                add(x, bell(f, 1.0) * 0.45, t)
            if i % 2 == 0:
                add(x, bass(note_hz(notes[0] - 24 + (7 if i % 4 == 2 else 0)), st * 1.8) * 0.35, t)
        for k in range(3):
            add(x, bell(note_hz(mel[-1] + 12 + [0, 4, 7][k]), 1.3) * 0.22, len(mel) * st + k * 0.08)
        if extra == "drum":
            for k in range(len(mel)):
                add(x, frame_drum(0.18, k % 2 == 0) * 0.4, k * st)
        write("jingle_town_" + land, reverb(x, 1.6, 0.32))


def bandish(f, dur):
    n = int(dur * SR)
    tt = np.arange(n) / SR
    return np.sin(2 * np.pi * f * tt) * np.exp(-tt * 90) + highpass(rng.normal(0, 1, n), 3000) * np.exp(-tt * 120) * 0.4


if __name__ == "__main__":
    import sys
    print("music")
    if "--sfx" not in sys.argv and "--sfx2" not in sys.argv and "--jingles" not in sys.argv:
        music()
    if "--jingles" in sys.argv:
        jingles()
        print("AUDIO DONE")
        sys.exit(0)
    if "--sfx2" in sys.argv:
        sfx2()
        print("AUDIO DONE")
        sys.exit(0)
    print("sfx")
    sfx()
    sfx2()
    jingles()
    print("AUDIO DONE")
