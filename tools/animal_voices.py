"""Свои голоса каждому зверю «Лесного травника» (синтез, без чужих записей).

Для каждого зверя 3 файла:
  audio/av_<id>_0.wav, av_<id>_1.wav — два варианта голоса (зверь подаёт голос сам)
  audio/av_<id>_pet.wav             — довольный звук, когда его гладят
и таблица animal_voices_db.gd (описание голоса для бестиария).

Запуск из папки game:  python tools/animal_voices.py [id ...]
"""
import os
import sys
import wave
import zlib

import numpy as np
from scipy.signal import butter, lfilter

SR = 32000
HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "audio")
DB = os.path.join(HERE, "..", "animal_voices_db.gd")


# ------------------------------------------------------------------ основа

def N(d):
    return max(1, int(SR * d))


def T(n):
    return np.arange(n) / SR


def curve(pts, n):
    return np.interp(np.linspace(0, 1, n), [p[0] for p in pts], [p[1] for p in pts])


def env(n, a=0.01, r=0.1):
    t = T(n)
    d = n / SR
    return np.clip(np.minimum(t / max(a, 1e-4), (d - t) / max(r, 1e-4)), 0, 1) ** 1.3


def decay(n, a, k):
    t = T(n)
    return np.minimum(1, t / max(a, 1e-4)) * np.exp(-t / max(k, 1e-4))


def snoise(n, hz, rng):
    k = max(2, int(SR / hz))
    m = n // k + 3
    return np.interp(np.arange(n) / k, np.arange(m), rng.randn(m))


def _b(kind, f):
    return butter(2, f, kind, fs=SR)


def lowpass(x, f):
    return lfilter(*_b("low", min(f, SR / 2 - 100)), x)


def highpass(x, f):
    return lfilter(*_b("high", f), x)


def bandpass(x, lo, hi):
    return lfilter(*butter(2, [lo, min(hi, SR / 2 - 100)], "band", fs=SR), x)


def reson(x, f, bw):
    f = min(f, SR / 2 - 300)
    r = np.exp(-np.pi * bw / SR)
    w = 2 * np.pi * f / SR
    g = (1 - r * r) / 2
    return lfilter([g, 0, -g], [1, -2 * r * np.cos(w), r * r], x)


VOW = {
    "a": [(750, 130, 1), (1200, 150, 0.6), (2600, 250, 0.25)],
    "o": [(450, 100, 1), (800, 120, 0.5), (2600, 250, 0.12)],
    "u": [(320, 80, 1), (750, 120, 0.3), (2400, 250, 0.06)],
    "e": [(550, 110, 1), (1800, 160, 0.6), (2600, 250, 0.3)],
    "i": [(300, 80, 0.8), (2300, 160, 0.7), (3000, 250, 0.4)],
    "m": [(250, 60, 1), (1200, 300, 0.06)],
    "n": [(500, 150, 1), (1100, 250, 0.7), (2500, 300, 0.5)],
}


def vowel(x, v, sc=1.0):
    return sum(g * reson(x, f * sc, bw * sc) for f, bw, g in VOW[v])


def vowels(x, seq, sc=1.0):
    n = len(x)
    fr = np.linspace(0, 1, n)
    pos = [p for p, _ in seq]
    y = np.zeros(n)
    for i, (_, v) in enumerate(seq):
        w = np.interp(fr, pos, [1.0 if j == i else 0.0 for j in range(len(seq))])
        if w.max() > 0:
            y += vowel(x, v, sc) * w
    return y


def glot(f0, rng, rough=0.0, bright=0.7, breath=0.0, jit=0.01):
    """Голосовые связки: пила с дрожью + хрипота + дыхание."""
    n = len(f0)
    f = f0 * (1 + jit * snoise(n, 40, rng) + rough * 0.08 * snoise(n, 150, rng))
    ph = np.cumsum(f) / SR
    saw = 2 * (ph % 1) - 1
    s = bright * saw + (1 - bright) * np.sin(2 * np.pi * ph)
    if rough > 0:
        s *= 1 + rough * 0.7 * snoise(n, 90, rng)
    return s + breath * rng.randn(n)


def tone(f, harm=(1, 0.3, 0.1)):
    ph = 2 * np.pi * np.cumsum(f) / SR
    return sum(a * np.sin(ph * (i + 1)) for i, a in enumerate(harm))


def seq(parts, gaps):
    """Склеить кусочки с паузами (gaps — секунды после каждого)."""
    out = []
    for p, g in zip(parts, gaps):
        out.append(p)
        out.append(np.zeros(N(g)))
    return np.concatenate(out)


def mix(a, b, at=0.0, gb=1.0):
    i = N(at) if at > 0 else 0
    n = max(len(a), i + len(b))
    y = np.zeros(n)
    y[:len(a)] += a
    y[i:i + len(b)] += b * gb
    return y


def norm(x):
    return x / (np.max(np.abs(x)) + 1e-9)


# ------------------------------------------------------------------ голоса

def moo(rng, p, soft):
    n = N(0.9 if soft else rng.uniform(1.4, 1.9))
    f0 = curve([(0, 95), (0.15, 125), (0.6, 118), (1, 88)], n) * p
    s = glot(f0, rng, rough=0.3, bright=0.85, breath=0.04)
    v = [(0, "m"), (1, "u")] if soft else [(0, "m"), (0.2, "u"), (0.55, "o"), (1, "a")]
    return vowels(s, v, 0.8) * env(n, 0.12, 0.35)


def baa(rng, p, soft, sc=1.0):
    n = N(rng.uniform(0.35, 0.5) if soft else rng.uniform(0.7, 1.0))
    t = T(n)
    tr = np.sin(2 * np.pi * rng.uniform(8, 10) * t)
    f0 = curve([(0, 1.0), (0.2, 1.08), (1, 0.9)], n) * 290 * p * (1 + (0.02 if soft else 0.06) * tr)
    s = glot(f0, rng, rough=0.35, bright=0.9, breath=0.05)
    y = vowels(s, [(0, "m"), (0.15, "e"), (1, "e")], sc)
    am = 0.75 + 0.25 * tr if soft else 0.5 + 0.5 * tr
    return y * am * env(n, 0.05, 0.2)


def neigh(rng, p, soft):
    if soft:   # тихое ржание «ху-ху-ху»
        n = N(0.7)
        t = T(n)
        s = glot(np.full(n, 115 * p), rng, rough=0.3, bright=0.7, breath=0.3)
        y = vowels(s, [(0, "u"), (1, "m")])
        return y * (0.5 + 0.5 * np.sin(2 * np.pi * 9 * t)) ** 2 * env(n, 0.05, 0.25)
    n = N(rng.uniform(1.1, 1.5))
    t = T(n)
    f0 = curve([(0, 700), (0.08, 1100), (0.4, 850), (0.85, 450), (1, 350)], n) * p
    vib = 1 + 0.09 * np.sin(2 * np.pi * 11 * t) * curve([(0, 0.2), (0.4, 1), (1, 1)], n)
    s = glot(f0 * vib, rng, rough=0.4, bright=0.6, breath=0.12)
    y = vowels(s, [(0, "i"), (0.4, "e"), (1, "a")], 1.1)
    y *= (0.6 + 0.4 * np.sin(2 * np.pi * 11 * t)) * env(n, 0.03, 0.3)
    m = N(0.3)   # фырканье в конце
    sn = bandpass(rng.randn(m), 300, 1800) * (0.6 + 0.4 * np.sin(2 * np.pi * 30 * T(m))) * decay(m, 0.01, 0.1)
    return np.concatenate([norm(y), norm(sn) * 0.5])


def bray(rng, p, soft):
    def hee():
        n = N(0.35)
        return vowel(glot(curve([(0, 480), (1, 560)], n) * p, rng, rough=0.6, bright=0.9, breath=0.4), "i") * env(n, 0.04, 0.08)

    def haw():
        n = N(0.45)
        return vowel(glot(curve([(0, 190), (1, 160)], n) * p, rng, rough=0.7, bright=1.0, breath=0.2), "a") * env(n, 0.03, 0.12)
    if soft:
        n = N(0.5)
        return vowels(glot(np.full(n, 150 * p), rng, rough=0.4, breath=0.3), [(0, "m"), (1, "u")]) * env(n, 0.05, 0.2)
    k = 2 if rng.rand() < 0.5 else 3
    parts, gaps = [], []
    for _ in range(k):
        parts += [norm(hee()), norm(haw())]
        gaps += [0.03, 0.08]
    return seq(parts, gaps)


def quack(rng, p, soft, honk=False):
    parts, gaps = [], []
    k = rng.randint(1, 3) if soft else rng.randint(2, 5)
    for _ in range(k):
        d = (0.1 if soft else 0.16) * (1.6 if honk else 1.0)
        n = N(d)
        base = (380 if honk else 250) * p * (0.85 if soft else 1.0)
        f0 = curve([(0, 1.05), (0.4, 1.1), (1, 0.9)], n) * base
        s = glot(f0, rng, rough=0.5, bright=1.0, breath=0.08)
        y = vowels(s, [(0, "n"), (1, "a")], 1.15 if honk else 1.0) * env(n, 0.01, 0.06)
        parts.append(norm(y) * (0.5 if soft else 1.0))
        gaps.append(rng.uniform(0.08, 0.16))
    return seq(parts, gaps)


def cluck(rng, p, soft):
    if soft:   # курочка довольно урчит
        n = N(0.7)
        t = T(n)
        s = glot(np.full(n, 260 * p), rng, rough=0.3, bright=0.8)
        return vowel(s, "o") * (0.5 + 0.5 * np.sin(2 * np.pi * 16 * t)) * env(n, 0.06, 0.2)
    parts, gaps = [], []
    for _ in range(rng.randint(3, 6)):
        n = N(0.07)
        parts.append(norm(vowel(glot(np.full(n, 380 * p), rng, rough=0.4, bright=1), "o") * env(n, 0.005, 0.04)))
        gaps.append(rng.uniform(0.08, 0.18))
    n = N(0.35)
    f0 = curve([(0, 480), (0.3, 820), (1, 600)], n) * p
    parts.append(norm(vowels(glot(f0, rng, rough=0.5, bright=1, breath=0.1), [(0, "o"), (0.3, "a"), (1, "a")]) * env(n, 0.01, 0.12)))
    gaps.append(0.0)
    return seq(parts, gaps)


def grunt(rng, p, soft, base=140, squeal=False, snort=False):
    if squeal:
        n = N(0.6)
        f0 = curve([(0, 900), (0.3, 1350), (1, 1000)], n) * p
        return vowel(glot(f0, rng, rough=0.6, bright=0.9, breath=0.2), "i") * env(n, 0.02, 0.15)
    parts, gaps = [], []
    for _ in range(rng.randint(2, 4)):
        n = N(rng.uniform(0.15, 0.3) * (0.7 if soft else 1))
        t = T(n)
        f0 = curve([(0, 1.0), (1, 0.82)], n) * base * p
        s = glot(f0, rng, rough=0.9, bright=1.0, breath=0.3)
        y = vowels(s, [(0, "n"), (1, "o")], 0.9) * (0.55 + 0.45 * np.sin(2 * np.pi * 34 * t)) * env(n, 0.01, 0.07)
        parts.append(norm(y) * (0.5 if soft else 1.0))
        gaps.append(rng.uniform(0.06, 0.2))
    y = seq(parts, gaps)
    if snort and not soft:
        m = N(0.25)
        sn = bandpass(rng.randn(m), 250, 1500) * (0.5 + 0.5 * np.sin(2 * np.pi * 28 * T(m))) * decay(m, 0.01, 0.08)
        y = np.concatenate([y, norm(sn) * 0.7])
    return y


def squeak(rng, p, soft, f=3500, kmin=2, kmax=5):
    parts, gaps = [], []
    k = rng.randint(1, 3) if soft else rng.randint(kmin, kmax + 1)
    for _ in range(k):
        n = N(rng.uniform(0.05, 0.12))
        a, b = f * p * rng.uniform(0.85, 1.15), f * p * rng.uniform(0.8, 1.25)
        fr = curve([(0, a), (0.5, max(a, b) * 1.05), (1, b)], n) * (0.85 if soft else 1)
        parts.append(tone(fr, (1, 0.25, 0.05)) * env(n, 0.008, 0.03) * (0.5 if soft else 1))
        gaps.append(rng.uniform(0.03, 0.14))
    return seq(parts, gaps)


def chitter(rng, p, soft, f=2500, trill=True):
    parts, gaps = [], []
    k = rng.randint(2, 4) if soft else rng.randint(6, 12)
    rate = rng.uniform(10, 14)
    for _ in range(k):
        n = N(0.035)
        x = bandpass(rng.randn(n), f * p * 0.7, f * p * 1.5) + 0.6 * tone(np.full(n, f * 0.7 * p), (1, 0.4))
        parts.append(x * decay(n, 0.002, 0.012) * (0.5 if soft else 1))
        gaps.append(1 / rate - 0.035)
    y = seq(parts, gaps)
    if trill and not soft:
        n = N(0.3)
        fr = curve([(0, 1.0), (1, 0.75)], n) * f * 0.6 * p
        tr = tone(fr, (1, 0.3)) * (0.5 + 0.5 * np.sin(2 * np.pi * 25 * T(n))) * env(n, 0.01, 0.1)
        y = np.concatenate([y, np.zeros(N(0.05)), tr * 0.8])
    return y


def bark(rng, p, soft):
    if soft:   # поскуливает и дышит
        n = N(0.7)
        f0 = curve([(0, 850), (0.4, 1100), (1, 800)], n) * p
        wh = vowel(glot(f0, rng, bright=0.2, breath=0.05), "i") * env(n, 0.05, 0.2)
        parts = [norm(wh)]
        for _ in range(3):
            m = N(0.12)
            parts.append(norm(bandpass(rng.randn(m), 600, 3000) * env(m, 0.03, 0.06)) * 0.35)
        return seq(parts, [0.1, 0.08, 0.08, 0])
    parts, gaps = [], []
    for _ in range(rng.randint(2, 4)):
        n = N(0.16)
        f0 = curve([(0, 480), (1, 330)], n) * p
        s = glot(f0, rng, rough=0.5, bright=1.0, breath=0.3)
        parts.append(norm(vowels(s, [(0, "a"), (1, "u")], 1.0) * env(n, 0.005, 0.08)))
        gaps.append(rng.uniform(0.12, 0.25))
    return seq(parts, gaps)


def fox(rng, p, soft, var):
    if soft:   # «геккеринг» — частое тихое тявканье
        parts = []
        for _ in range(8):
            n = N(0.05)
            parts.append(norm(vowel(glot(np.full(n, 600 * p), rng, rough=0.7, breath=0.3), "a") * env(n, 0.005, 0.03)) * 0.5)
        return seq(parts, [0.025] * 8)
    if var == 0:   # лисий крик
        n = N(rng.uniform(0.5, 0.7))
        f0 = curve([(0, 900), (0.25, 1200), (1, 700)], n) * p
        return vowel(glot(f0, rng, rough=0.7, bright=0.8, breath=0.35), "a", 1.3) * env(n, 0.02, 0.2)
    parts, gaps = [], []
    for _ in range(3):
        n = N(0.12)
        f0 = curve([(0, 1050), (1, 800)], n) * p
        parts.append(norm(vowel(glot(f0, rng, rough=0.5, bright=0.9, breath=0.25), "a", 1.3) * env(n, 0.005, 0.06)))
        gaps.append(rng.uniform(0.15, 0.3))
    return seq(parts, gaps)


def howl(rng, p, soft, var):
    if soft:   # поскуливание и вздох
        n = N(0.5)
        y = norm(vowel(glot(curve([(0, 720), (1, 600)], n) * p, rng, bright=0.25), "u") * env(n, 0.05, 0.2))
        m = N(0.25)
        return seq([y, norm(bandpass(rng.randn(m), 300, 1500) * env(m, 0.04, 0.15)) * 0.4], [0.05, 0])
    n = N(rng.uniform(2.0, 2.6))
    t = T(n)
    pk = 520 if var == 0 else 600
    f0 = curve([(0, 330), (0.15, pk), (0.7, pk * 1.07), (1, 400)], n) * p * (1 + 0.015 * np.sin(2 * np.pi * 5 * t))
    s = glot(f0, rng, rough=0.08, bright=0.3, breath=0.04)
    return vowels(s, [(0, "u"), (0.3, "o"), (1, "u")]) * env(n, 0.25, 0.6)


def growl(rng, p, soft, var):
    if soft:   # пыхтение «ух-ух»
        parts = []
        for _ in range(3):
            n = N(0.18)
            x = lowpass(rng.randn(n), 700) + 0.6 * vowel(glot(np.full(n, 90 * p), rng, rough=0.6), "o")
            parts.append(norm(x * env(n, 0.02, 0.1)) * 0.6)
        return seq(parts, [0.15, 0.15, 0])
    n = N(rng.uniform(0.9, 1.2))
    t = T(n)
    if var == 0:
        f0 = curve([(0, 120), (0.3, 150), (1, 90)], n) * p
    else:
        f0 = np.full(n, 78 * p) * curve([(0, 0.9), (0.5, 1.05), (1, 0.95)], n)
    s = glot(f0, rng, rough=1.0, bright=1.0, breath=0.4)
    return vowels(s, [(0, "o"), (0.4, "a"), (1, "o")], 0.7) * (0.55 + 0.45 * np.sin(2 * np.pi * 30 * t)) * env(n, 0.08, 0.3)


def purr(rng, p, soft=True, d=1.2):
    n = N(d)
    t = T(n)
    rate = 26 * p ** 0.3
    pulse = np.clip(np.sin(2 * np.pi * rate * t), 0, 1) ** 2
    half = 0.75 + 0.25 * np.sign(np.sin(2 * np.pi * 0.9 * t))   # вдох/выдох
    x = lowpass(rng.randn(n), 700 * p) + 0.5 * vowel(glot(np.full(n, rate * 4), rng, bright=1), "m")
    return x * pulse * half * env(n, 0.1, 0.2)


def roar(rng, p, soft, var):
    if soft or var == 1:   # «пруханье» — фырканье тигра
        parts = []
        for _ in range(3):
            n = N(0.13)
            x = bandpass(rng.randn(n), 200, 1500) * (0.5 + 0.5 * np.sin(2 * np.pi * 40 * T(n)))
            x += 0.4 * vowel(glot(np.full(n, 110 * p), rng, rough=0.5), "o")
            parts.append(norm(x * env(n, 0.01, 0.08)) * (0.6 if soft else 1))
        y = seq(parts, [0.06, 0.06, 0.1])
        return mix(y, norm(purr(rng, p * 0.7, d=0.8)) * 0.5, 0.5) if soft else y
    n = N(rng.uniform(1.2, 1.6))
    f0 = curve([(0, 140), (0.2, 200), (1, 80)], n) * p
    s = glot(f0, rng, rough=1.0, bright=1.0, breath=0.5)
    return vowels(s, [(0, "a"), (0.5, "a"), (1, "o")], 0.75) * env(n, 0.06, 0.5)


def meow(rng, p, soft, yowl=False):
    if soft:
        return purr(rng, p)
    n = N(rng.uniform(0.8, 1.1) if yowl else rng.uniform(0.45, 0.65))
    f0 = curve([(0, 550), (0.35, 760), (1, 470)], n) * p
    s = glot(f0, rng, rough=0.4 if yowl else 0.12, bright=0.7, breath=0.05)
    return vowels(s, [(0, "i"), (0.4, "a"), (1, "u")], 1.15 * p ** 0.3) * env(n, 0.04, 0.15)


def hiss(rng, p, soft, d=0.9, k=1):
    parts, gaps = [], []
    for _ in range(1 if soft else k):
        n = N(d * (0.4 if soft else rng.uniform(0.8, 1.2)))
        x = bandpass(rng.randn(n), 2500 * p, 9000 * p)
        parts.append(norm(x * env(n, 0.06, 0.3)) * (0.5 if soft else 1))
        gaps.append(0.15)
    return seq(parts, gaps)


def scratch(rng, n_clicks, f=4000, spread=0.6):
    """Короткие щелчки (коготки, клешни, зубы)."""
    n = N(spread + 0.05)
    y = np.zeros(n)
    for _ in range(n_clicks):
        m = N(0.004)
        c = bandpass(rng.randn(m), f * 0.6, f * 1.6) * decay(m, 0.0005, 0.0012)
        i = rng.randint(0, n - m)
        y[i:i + m] += c * rng.uniform(0.4, 1)
    return y


def croak(rng, p, soft, kind="frog"):
    def ribbit(f, d=0.12, rate=70):
        n = N(d)
        t = T(n)
        pulse = np.clip(np.sin(2 * np.pi * rate * t), 0, 1) ** 3
        s = glot(np.full(n, f * p), rng, rough=0.3, bright=1)
        return norm(vowel(s, "o", 1.4) * pulse * env(n, 0.01, 0.04))
    if kind == "toad":
        if soft:
            return ribbit(500, 0.3, 30) * 0.5
        n = N(rng.uniform(1.2, 1.6))
        t = T(n)
        s = tone(np.full(n, 1300 * p), (1, 0.5, 0.2)) * np.clip(np.sin(2 * np.pi * 24 * t), 0, 1) ** 2
        return s * env(n, 0.05, 0.2)
    if kind == "newt":
        return mix(squeak(rng, p, soft, f=4200, kmin=1, kmax=2) * 0.5, scratch(rng, 6, 3000, 0.4) * 0.6)
    if soft:
        return ribbit(420, 0.15, 50) * 0.5
    parts, gaps = [], []
    for _ in range(rng.randint(1, 3)):
        parts += [ribbit(450, 0.1), ribbit(560, 0.14)]
        gaps += [0.05, rng.uniform(0.2, 0.4)]
    return seq(parts, gaps)


def deer(rng, p, soft, var):
    if soft or var == 1:   # тихое блеяние оленёнка
        n = N(0.35)
        f0 = curve([(0, 700), (0.3, 760), (1, 600)], n) * p
        y = vowels(glot(f0, rng, rough=0.15, bright=0.5, breath=0.1), [(0, "e"), (1, "u")], 1.1) * env(n, 0.03, 0.12)
        return y * (0.5 if soft else 1)
    parts, gaps = [], []
    for _ in range(rng.randint(1, 3)):
        n = N(0.28)
        s = glot(curve([(0, 420), (1, 330)], n) * p, rng, rough=0.6, bright=1.0, breath=0.9)
        parts.append(norm(vowel(s, "a") * env(n, 0.005, 0.12)))
        gaps.append(rng.uniform(0.4, 0.7))
    return seq(parts, gaps)


def bellow(rng, p, soft, var, sc=0.7):
    if soft:   # фыркает носом
        m = N(0.35)
        return bandpass(rng.randn(m), 200, 1200) * (0.6 + 0.4 * np.sin(2 * np.pi * 22 * T(m))) * decay(m, 0.02, 0.12) * 0.6
    if var == 1:   # короткие хрюки «ух»
        parts = []
        for _ in range(3):
            n = N(0.2)
            parts.append(norm(vowel(glot(curve([(0, 1.05), (1, 0.9)], n) * 95 * p, rng, rough=0.8, bright=1, breath=0.3), "u", sc) * env(n, 0.01, 0.09)))
        return seq(parts, [0.25, 0.25, 0])
    n = N(rng.uniform(1.1, 1.5))
    f0 = curve([(0, 90), (0.4, 130), (1, 78)], n) * p
    s = glot(f0, rng, rough=0.6, bright=1.0, breath=0.2)
    return vowels(s, [(0, "u"), (0.4, "a"), (1, "o")], sc) * env(n, 0.1, 0.4)


def whistle(rng, p, soft, f=2600, k=(1, 2), d=0.18):
    parts, gaps = [], []
    for _ in range(rng.randint(k[0], k[1] + 1)):
        n = N(d * (0.6 if soft else 1))
        fr = curve([(0, 1.0), (0.2, 1.04), (1, 0.92)], n) * f * p * (0.85 if soft else 1)
        parts.append(tone(fr, (1, 0.15)) * env(n, 0.004, 0.05) * (0.45 if soft else 1))
        gaps.append(rng.uniform(0.25, 0.5))
    return seq(parts, gaps)


def sweeps(rng, p, soft, f=2000, k=(4, 6)):
    """Щебечущие трели (выдра, красная панда)."""
    parts, gaps = [], []
    for _ in range(rng.randint(2, 3) if soft else rng.randint(k[0], k[1] + 1)):
        n = N(rng.uniform(0.06, 0.1))
        fr = curve([(0, f), (1, f * 1.5)], n) * p
        parts.append(tone(fr, (1, 0.2)) * env(n, 0.005, 0.03) * (0.5 if soft else 1))
        gaps.append(rng.uniform(0.04, 0.1))
    return seq(parts, gaps)


def thump(rng, k=2):
    parts = []
    for _ in range(k):
        n = N(0.12)
        f = curve([(0, 110), (1, 45)], n)
        parts.append(norm(tone(f, (1, 0.3)) * decay(n, 0.002, 0.03) + 0.2 * lowpass(rng.randn(n), 500) * decay(n, 0.001, 0.01)))
    return seq(parts, [0.18] * k)


def rabbit(rng, p, soft, var):
    if soft:   # «зубное мурлыканье» — тихий скрежет зубками
        return scratch(rng, 40, 2500, 0.8) * 0.5
    if var == 0:
        return mix(thump(rng, rng.randint(2, 4)), squeak(rng, p, False, 2400, 1, 1) * 0.3, 0.5)
    return grunt(rng, p * 3.2, True, 140) + 0  # короткое хрюканье-фырк


def hum(rng, p, soft, var):
    if var == 1 and not soft:   # тревожный крик «ви-ви»
        parts = []
        for _ in range(3):
            n = N(0.18)
            parts.append(norm(vowel(glot(curve([(0, 800), (1, 950)], n) * p, rng, rough=0.6, breath=0.4), "i") * env(n, 0.01, 0.06)))
        return seq(parts, [0.1, 0.1, 0])
    n = N(0.5 if soft else 0.8)
    f0 = curve([(0, 220), (0.6, 260), (1, 210)], n) * p
    return vowel(glot(f0, rng, bright=0.5, breath=0.02), "m") * env(n, 0.08, 0.2) * (0.6 if soft else 1)


def snuffle(rng, p, soft, k=(6, 10)):
    parts, gaps = [], []
    for _ in range(rng.randint(3, 5) if soft else rng.randint(k[0], k[1] + 1)):
        n = N(rng.uniform(0.03, 0.06))
        parts.append(norm(bandpass(rng.randn(n), 800 * p, 3200 * p) * env(n, 0.005, 0.02)) * rng.uniform(0.5, 1) * (0.5 if soft else 1))
        gaps.append(rng.uniform(0.06, 0.14))
    return seq(parts, gaps)


def bubbles(rng, k=6, d=0.6):
    n = N(d)
    y = np.zeros(n)
    for _ in range(k):
        m = N(0.025)
        b = tone(curve([(0, 500), (1, 1600)], m) * rng.uniform(0.7, 1.4), (1,)) * env(m, 0.002, 0.012)
        i = rng.randint(0, n - m)
        y[i:i + m] += b
    return y


def splash(rng):
    n = N(0.5)
    th = tone(curve([(0, 120), (1, 50)], n), (1, 0.2)) * decay(n, 0.002, 0.05)
    sp = bandpass(rng.randn(n), 800, 6000) * decay(n, 0.005, 0.15)
    return th + sp * 0.7


def screech(rng, p, soft):
    n = N(rng.uniform(0.7, 0.9))
    t = T(n)
    f0 = curve([(0, 2000), (0.15, 2400), (1, 1700)], n) * p * (1 + 0.04 * np.sin(2 * np.pi * 18 * t))
    s = glot(f0, rng, rough=0.4, bright=0.35, breath=0.1)
    return vowel(s, "i", 1.6) * env(n, 0.02, 0.3)


# ------------------------------------------------------------------ волшебные добавки

def chimes(rng, d=1.2, base=1800, k=4, bell=False):
    n = N(d + 0.8)
    y = np.zeros(n)
    scale = [1, 9 / 8, 5 / 4, 3 / 2, 5 / 3, 2]
    for i in range(k):
        f = base * scale[rng.randint(0, len(scale))]
        m = N(1.2 if bell else 0.7)
        part = (1, 2.76, 5.4) if bell else (1, 2.0, 3.0)
        x = sum(a * np.sin(2 * np.pi * f * h * T(m)) for h, a in zip(part, (1, 0.4, 0.2)))
        x *= decay(m, 0.002, 0.35 if bell else 0.18)
        st = int(i * (d / max(k, 1)) * SR * rng.uniform(0.7, 1.1))
        y[st:st + m] += x[:len(y) - st]
    return y


def crackle(rng, d=1.0, dens=40):
    n = N(d)
    y = np.zeros(n)
    for _ in range(int(dens * d)):
        m = N(0.006)
        c = bandpass(rng.randn(m), 1200, 7000) * decay(m, 0.0004, 0.0015)
        i = rng.randint(0, n - m)
        y[i:i + m] += c * rng.uniform(0.2, 1)
    return y * env(n, 0.1, 0.3)


def whoosh(rng, d=0.6):
    n = N(d)
    sweep = curve([(0, 300), (0.5, 1200), (1, 500)], n)
    x = rng.randn(n)
    y = np.zeros(n)
    for a in range(0, n, N(0.05)):     # полоса, плывущая по частоте
        b = min(n, a + N(0.05))
        f = sweep[a]
        y[a:b] = bandpass(x[max(0, a - 200):b], f * 0.6, f * 1.6)[-(b - a):]
    return y * env(n, 0.15, 0.3)


def wings(rng, k=3):
    parts = []
    for _ in range(k):
        n = N(0.14)
        parts.append(norm(bandpass(rng.randn(n), 250, 1400) * env(n, 0.03, 0.08)))
    return seq(parts, [0.12] * k)


def echo(x, delay=0.22, fb=0.45, k=4):
    d = N(delay)
    y = np.concatenate([x, np.zeros(d * k)])
    for i in range(1, k + 1):
        y[d * i:d * i + len(x)] += x * fb ** i
    return y


def boing(rng):
    n = N(0.45)
    t = T(n)
    f = 300 + 250 * np.sin(2 * np.pi * 14 * t) * np.exp(-t * 6) + 100 * t
    return tone(f, (1, 0.3)) * decay(n, 0.005, 0.15)


# ------------------------------------------------------------------ таблица зверей
# id: (функция(rng, вар, мягко) -> звук, описание голоса для бестиария)

def S(*a):   # сумма с нормировкой слоёв: S((звук, громкость, сдвиг), ...)
    y = np.zeros(1)
    for x, g, at in a:
        y = mix(y, norm(x), at, g)
    return y


V = {
    # --- дикие (старые)
    "rabbit": (lambda r, v, s: rabbit(r, 1.0, s, v), "стучит лапкой по земле «тук-тук», тихо фыркает; когда гладят — скрежещет зубками"),
    "fox": (lambda r, v, s: fox(r, 1.0, s, v), "звонко кричит «ва-а-ау» и тявкает; довольная — часто «гекает»"),
    "deer": (lambda r, v, s: deer(r, 0.9, s, v), "хрипло лает «бах!», когда насторожится; тихо блеет"),
    "boar": (lambda r, v, s: grunt(r, 1.0, s, 95, snort=True), "низко хрюкает и громко фыркает пятачком"),
    "flat_boar": (lambda r, v, s: S((grunt(r, 1.25, s, 120), 1, 0), (boing(r), 0.6, 0.3)), "сплющенно хрюкает и смешно пружинит «буэнь»"),
    "hedgehog": (lambda r, v, s: S((snuffle(r, 1.0, s), 1, 0), (squeak(r, 0.8, True, 3000), 0.4, 0.4)), "пыхтит и сопит «пф-пф-пф», иногда пискнет"),
    "squirrel": (lambda r, v, s: chitter(r, 1.0, s, 2600), "цокает «цок-цок-цок» и стрекочет трелью"),
    "duck": (lambda r, v, s: quack(r, 1.0, s), "крякает «кря-кря»; довольная — тихо бормочет"),
    "chicken": (lambda r, v, s: cluck(r, 1.0, s), "квохчет «ко-ко-ко-кудах!»; на руках — тихо урчит"),
    "cow": (lambda r, v, s: moo(r, 1.0 if v == 0 else 0.92, s), "протяжно мычит «му-у-у»; когда гладят — тихо «мм-м»"),
    "sheep": (lambda r, v, s: baa(r, 1.0, s), "блеет дрожащим «бе-е-е»"),
    "goat": (lambda r, v, s: baa(r, 1.25, s, 1.1), "высоко и дерзко блеет «ме-е-е»"),
    "pig": (lambda r, v, s: grunt(r, 1.0, s, 140, squeal=(v == 1 and not s)), "хрюкает «хрю-хрю», иногда визжит"),
    "goose": (lambda r, v, s: quack(r, 1.0, s, honk=True), "громко гогочет «га-га-га»"),
    # --- волшебные (старые)
    "sapphire_hare": (lambda r, v, s: S((rabbit(r, 1.2, s, v), 1, 0), (chimes(r, 0.8, 2400, 4), 0.5, 0.1)), "стучит лапкой, и в воздухе звенят хрустальные колокольчики"),
    "golden_deer": (lambda r, v, s: S((deer(r, 1.0, s, v), 1, 0), (chimes(r, 1.0, 900, 3, bell=True), 0.6, 0.15)), "трубит, и ему отвечает тихий золотой колокол"),
    "ember_fox": (lambda r, v, s: S((fox(r, 0.95, s, v), 1, 0), (crackle(r, 1.0), 0.5, 0)), "тявкает, а шерсть потрескивает искрами, как костёр"),
    "unicorn": (lambda r, v, s: S((neigh(r, 1.15, s), 1, 0), (chimes(r, 1.2, 2000, 5), 0.55, 0.1)), "звонко ржёт, а вокруг рассыпается звон колокольчиков"),
    # --- v25 лесные
    "wolf": (lambda r, v, s: howl(r, 1.0, s, v), "протяжно воет «у-у-у-о-у»; когда гладят — поскуливает"),
    "snow_fox": (lambda r, v, s: fox(r, 1.15, s, v), "лает высоко и коротко «тяв-тяв», по-песцовому"),
    "raccoon": (lambda r, v, s: S((chitter(r, 0.8, s, 2000), 1, 0), (purr(r, 1.3, d=0.6), 0.5, 0.6)) if not s else purr(r, 1.4, d=0.9), "чирикает и курлычет трелью; довольный — мурлычет"),
    "badger": (lambda r, v, s: S((growl(r, 2.0, s, 1), 0.7, 0), (snuffle(r, 0.8, s), 1, 0.3)) if not s else purr(r, 1.5), "ворчит и сопит носом; довольный — урчит"),
    "lynx": (lambda r, v, s: meow(r, 0.7, s, yowl=True), "протяжно и хрипло мяучит «мя-а-ау»; гладят — мурлычет"),
    "wildcat": (lambda r, v, s: meow(r, 1.05, s), "мяукает «мяу»; довольный — мурлычет"),
    "bear": (lambda r, v, s: growl(r, 1.0, s, v), "рычит «р-р-ро-о-ар»; довольный — пыхтит «ух-ух»"),
    "elk": (lambda r, v, s: bellow(r, 0.85, s, v), "стонет низким «о-ах» и коротко ухает"),
    "roe_deer": (lambda r, v, s: deer(r, 1.15, s, v), "резко лает «бяу!», как маленькая собачка"),
    "marten": (lambda r, v, s: chitter(r, 0.85, s, 2200, trill=False), "стрекочет «кхе-кхе-кхе»"),
    "ermine": (lambda r, v, s: S((chitter(r, 1.2, s, 2400, trill=False), 1, 0), (squeak(r, 1.0, s, 3600, 1, 2), 0.6, 0.4)), "тихо стрекочет и пищит"),
    "chipmunk": (lambda r, v, s: whistle(r, 1.0, s, 4200, (5, 9), 0.035), "часто и мерно пищит «чип-чип-чип»"),
    "flying_squirrel": (lambda r, v, s: squeak(r, 1.8, s, 3500, 3, 6), "пищит так тонко, что еле слышно"),
    "horse": (lambda r, v, s: neigh(r, 1.0 if v == 0 else 0.93, s), "громко ржёт «и-го-го» и фыркает; гладят — тихо «ху-ху-ху»"),
    "pony": (lambda r, v, s: neigh(r, 1.3, s), "звонко ржёт тонким голоском"),
    "donkey": (lambda r, v, s: bray(r, 1.0, s), "кричит «иа-иа!»"),
    "bison": (lambda r, v, s: bellow(r, 0.7, s, v, 0.6), "глухо ревёт и тяжело хрюкает"),
    "brown_hare": (lambda r, v, s: rabbit(r, 1.1, s, v) if v == 0 or s else squeak(r, 0.5, False, 2200, 1, 2), "стучит лапами, а испугавшись — пищит"),
    "mole": (lambda r, v, s: S((squeak(r, 1.3, s, 3200, 2, 4), 1, 0), (scratch(r, 25, 2500, 0.6), 0.5, 0)), "тоненько пищит и шуршит коготками"),
    "vole": (lambda r, v, s: squeak(r, 1.5, s, 3600, 3, 6), "часто пищит «пи-пи-пи»"),
    "hamster": (lambda r, v, s: S((squeak(r, 1.2, s, 3400, 2, 4), 1, 0), (scratch(r, 20, 3000, 0.5), 0.4, 0.2)), "пищит и щёлкает зубками"),
    "lop_rabbit": (lambda r, v, s: rabbit(r, 0.95, s, v) * 0.8, "тихонько фыркает и стучит лапкой"),
    "dog": (lambda r, v, s: bark(r, 1.0, s), "лает «гав-гав!»; когда гладят — поскуливает и дышит"),
    "snail": (lambda r, v, s: S((bubbles(r, 5 if s else 9), 1, 0), (lowpass(r.randn(N(0.6)), 900) * env(N(0.6), 0.1, 0.3), 0.4, 0)), "тихо чмокает и пускает пузырьки"),
    "alpaca": (lambda r, v, s: hum(r, 1.0, s, v), "мурлычет-напевает «мм-м»; встревожится — визжит «ви-ви»"),
    "ibex": (lambda r, v, s: baa(r, 0.8, s, 0.95), "низко и отрывисто блеет"),
    "ram": (lambda r, v, s: baa(r, 0.62, s, 0.85), "басовито блеет «бэ-э»"),
    "yak": (lambda r, v, s: grunt(r, 1.0, s, 85) if v == 0 else bellow(r, 0.8, s, 1), "хрюкает, как огромная свинья (его зовут «хрюкающий бык»)"),
    "marmot": (lambda r, v, s: whistle(r, 1.0, s, 2700), "пронзительно свистит «фьить!»"),
    "beaver": (lambda r, v, s: (splash(r) if v == 0 else hum(r, 3.0, False, 0) * 0.8) if not s else hum(r, 2.6, True, 0), "шлёпает хвостом по воде и тихо хнычет"),
    "otter": (lambda r, v, s: sweeps(r, 1.0, s, 2100), "щебечет и посвистывает"),
    "capybara": (lambda r, v, s: S((scratch(r, 30 if not s else 15, 1500, 0.7), 1, 0), (hum(r, 1.2, s, 0), 0.6, 0.1)), "щёлкает и тихо мурлычет-гудит"),
    "turtle": (lambda r, v, s: hiss(r, 0.5, s, 0.6), "сердито шипит «хсс»"),
    "tortoise": (lambda r, v, s: hiss(r, 0.4, s, 0.7) if v == 0 or s else bellow(r, 2.2, False, 1), "шипит и тихо кряхтит"),
    "frog": (lambda r, v, s: croak(r, 1.0, s, "frog"), "квакает «ква-ква»"),
    "toad": (lambda r, v, s: croak(r, 1.0, s, "toad"), "долго звенит трелью «урр-р-р»"),
    "newt": (lambda r, v, s: croak(r, 1.0, s, "newt"), "почти беззвучно попискивает"),
    "grass_snake": (lambda r, v, s: hiss(r, 1.0, s, 0.5, 2), "коротко шипит «пш-пш»"),
    "adder": (lambda r, v, s: hiss(r, 0.85, s, 1.2), "громко и долго шипит"),
    "lizard": (lambda r, v, s: S((scratch(r, 25, 4500, 0.5), 1, 0), (hiss(r, 1.2, True, 0.4), 0.4, 0.2)), "шуршит коготками и чуть шипит"),
    "crab": (lambda r, v, s: S((scratch(r, 12 if s else 30, 4500, 0.7), 1, 0), (bubbles(r, 4), 0.4, 0.1)), "щёлкает клешнями «клац-клац» и пускает пузыри"),
    "seal": (lambda r, v, s: (bark(r, 0.6, False) if v == 0 else howl(r, 0.65, False, 0)[:N(1.2)]) if not s else snuffle(r, 0.7, True), "гавкает «арф-арф» и протяжно стонет"),
    "porcupine": (lambda r, v, s: S((scratch(r, 30, 3500, 0.6), 1, 0), (snuffle(r, 1.4, s, (10, 16)), 0.7, 0)) if not s else hum(r, 2.2, True, 0), "стучит зубами и трещит иглами; довольный — тихо напевает"),
    "red_panda": (lambda r, v, s: S((bark(r, 0.75, False)[:N(0.3)], 0.8, 0), (sweeps(r, 1.4, s, 2800, (3, 5)), 1, 0.3)) if not s else sweeps(r, 1.3, True, 2600), "фыркает «хаф» и щебечет, как птичка"),
    "tanuki": (lambda r, v, s: bark(r, 1.15, True) if s or v == 1 else S((growl(r, 1.8, False, 1), 0.6, 0), (bark(r, 1.2, True), 1, 0.4)), "поскуливает и тихо ворчит"),
    # --- v25 волшебные
    "pegasus": (lambda r, v, s: S((neigh(r, 1.1, s), 1, 0), (wings(r, 3), 0.7, 0.2 if not s else 0)), "ржёт и хлопает крыльями"),
    "kirin": (lambda r, v, s: S((neigh(r, 0.85, s), 1, 0), (chimes(r, 1.2, 700, 3, bell=True), 0.6, 0.1), (crackle(r, 1.0, 20), 0.3, 0)), "ржёт глубоко, и звенят храмовые колокольчики"),
    "nightmare": (lambda r, v, s: echo(S((neigh(r, 0.68, s), 1, 0), (growl(r, 1.0, True, 0), 0.3, 0))), "ржёт низко и гулко, будто из-под земли"),
    "moon_wolf": (lambda r, v, s: echo(S((howl(r, 1.05, s, v), 1, 0), (chimes(r, 1.8, 2600, 6), 0.35, 0.3)), 0.3, 0.4, 3), "воет на луну, и вой звенит серебром"),
    "forest_stag": (lambda r, v, s: S((bellow(r, 0.95, s, v), 1, 0), (chimes(r, 1.3, 500, 3, bell=True), 0.5, 0.2), (bandpass(r.randn(N(1.2)), 2000, 8000) * env(N(1.2), 0.3, 0.6), 0.15, 0)), "трубит, а вокруг шелестит листва и гудят деревянные колокола"),
    "jackalope": (lambda r, v, s: S((rabbit(r, 1.2, s, v), 1, 0), (squeak(r, 1.1, s, 3000, 1, 2), 0.6, 0.3), (chimes(r, 0.6, 3000, 2), 0.35, 0.2)), "стучит лапкой, пищит и звенит рожками"),
    "griffin": (lambda r, v, s: S((screech(r, 1.0, s), 1, 0), (roar(r, 1.3, False, 0), 0.6, 0.2)) if not s else S((purr(r, 1.3), 1, 0), (cluck(r, 0.8, True), 0.4, 0.2)), "клекочет, как орёл, с рыком льва; довольный — урчит"),
    "dragonling": (lambda r, v, s: S((roar(r, 2.3, False, 0)[:N(0.8)], 1, 0), (whoosh(r, 0.7), 0.5, 0.25), (crackle(r, 0.8), 0.4, 0.3)) if not s else S((purr(r, 1.6), 1, 0), (crackle(r, 0.6, 15), 0.3, 0.2)), "рычит тоненько и пыхает огнём; довольный — урчит и дымит"),
    "salamander": (lambda r, v, s: S((hiss(r, 0.8, s, 0.7), 1, 0), (crackle(r, 1.0), 0.7, 0)), "шипит и потрескивает пламенем"),
    "crystal_tortoise": (lambda r, v, s: S((hiss(r, 0.4, True, 0.8), 0.5, 0), (chimes(r, 1.4, 1500, 5), 1, 0.1)), "вздыхает, и звенят хрустальные пластинки панциря"),
    "white_tiger": (lambda r, v, s: roar(r, 0.95, s, v), "рычит «р-р-а-а-ар» и фыркает «пф-пф»; гладят — мурлычет"),
}


def render(aid, var, soft):
    seed = zlib.crc32(f"{aid}:{var}:{int(soft)}".encode()) & 0x7FFFFFFF
    rng = np.random.RandomState(seed)
    y = np.asarray(V[aid][0](rng, var, soft), dtype=float)
    y = highpass(y, 45)
    y = lowpass(y, 11000)
    f = min(N(0.005), len(y) // 4)
    y[:f] *= np.linspace(0, 1, f)
    y[-f:] *= np.linspace(1, 0, f)
    return norm(y) * (0.6 if soft else 0.85)


def save(name, x):
    d = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(d.tobytes())


def main():
    ids = sys.argv[1:] or list(V)
    for aid in ids:
        save(f"av_{aid}_0", render(aid, 0, False))
        save(f"av_{aid}_1", render(aid, 1, False))
        save(f"av_{aid}_pet", render(aid, 0, True))
        print("ok", aid)
    lines = ["extends RefCounted", "## Голоса зверей (генерирует tools/animal_voices.py — руками не править).",
             "## Файлы: audio/av_<id>_0.wav, av_<id>_1.wav (голос), av_<id>_pet.wav (когда гладят).", "",
             "const VOICE: Dictionary = {"]
    for aid, (_, desc) in V.items():
        lines.append(f'\t"{aid}": "{desc}",')
    lines.append("}")
    with open(DB, "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines) + "\n")
    print(len(V), "зверей, таблица", DB)


if __name__ == "__main__":
    main()
