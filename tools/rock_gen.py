"""Рок-трек для клуба «Старлит» (свой, синтез): барабаны, бас, гитара с перегрузом, соло.
Запуск: python tools/rock_gen.py   -> audio/music_rock.wav (цикл ~30 с)"""
import numpy as np
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import audio_gen as A
from audio_gen import SR, note_hz, add, lowpass, highpass, reverb, loopify

rng = np.random.default_rng(11)
BPM = 132
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 16
TOTAL = BAR * BARS


def kick():
    n = int(0.22 * SR); t = np.arange(n) / SR
    f = 50 + 110 * np.exp(-t * 28)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 14) * 1.1


def snare():
    n = int(0.2 * SR); t = np.arange(n) / SR
    body = np.sin(2 * np.pi * 190 * t) * np.exp(-t * 26) * 0.6
    noise = highpass(rng.normal(0, 1, n), 1800) * np.exp(-t * 22)
    return body + noise * 0.8


def hat(open_=False):
    n = int((0.25 if open_ else 0.05) * SR); t = np.arange(n) / SR
    return highpass(rng.normal(0, 1, n), 7000) * np.exp(-t * (14 if open_ else 70)) * 0.35


def crash():
    n = int(1.2 * SR); t = np.arange(n) / SR
    return highpass(rng.normal(0, 1, n), 4000) * np.exp(-t * 3.2) * 0.5


def power_chord(root, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.zeros(n)
    for iv in (0, 7, 12):
        f = note_hz(root + iv)
        for det in (-0.4, 0.4):
            ph = (f + det) * t
            x += 2 * (ph - np.floor(ph + 0.5))      # пила
    x = np.tanh(x * 1.6)                              # перегруз
    x = lowpass(x, 3400)
    e = np.minimum(1, t * 200) * np.minimum(1, (dur - t) * 40 + 0.0)
    return x * np.clip(e, 0, 1) * 0.30


def bass_note(m, dur):
    n = int(dur * SR); t = np.arange(n) / SR
    f = note_hz(m)
    ph = f * t
    x = 2 * (ph - np.floor(ph + 0.5)) * 0.6 + np.sin(2 * np.pi * f * t)
    x = lowpass(np.tanh(x * 1.3), 700)
    return x * np.clip(np.minimum(1, t * 300) * np.minimum(1, (dur - t) * 40), 0, 1) * 0.45


def lead(m, dur, vib=True):
    n = int(dur * SR); t = np.arange(n) / SR
    f = note_hz(m) * (1 + 0.004 * np.sin(2 * np.pi * 5.5 * t) * np.clip(t * 3, 0, 1) if vib else 1)
    ph = np.cumsum(f) / SR
    x = np.tanh(2.5 * np.sin(2 * np.pi * ph) + 0.6 * np.sin(4 * np.pi * ph))
    x = lowpass(x, 4200)
    return x * np.clip(np.minimum(1, t * 120) * np.minimum(1, (dur - t) * 20), 0, 1) * 0.22


buf = np.zeros(int((TOTAL + 3.0) * SR))
prog = [45, 41, 48, 43]        # A2 F2 C3 G2 (MIDI)
K, S, H = kick(), snare(), hat()
HO = hat(True)

for bar in range(BARS):
    t0 = bar * BAR
    root = prog[bar % 4]
    heavy = bar >= 4
    # барабаны: четыре четверти, снейр на 2 и 4, восьмые хэта
    for b in range(4):
        tb = t0 + b * BEAT
        if b in (0, 2) or (heavy and b == 3 and bar % 2 == 1):
            add(buf, K * 0.9, tb)
        if b in (1, 3):
            add(buf, S * 0.8, tb)
        add(buf, H, tb)
        add(buf, H * 0.7, tb + BEAT / 2)
        if heavy and b == 2:
            add(buf, K * 0.7, tb + BEAT / 2)
    if bar % 4 == 0:
        add(buf, crash(), t0)
    if bar % 4 == 3:
        for k in range(4):
            add(buf, S * 0.55, t0 + 3 * BEAT + k * BEAT / 4)
    # бас: восьмыми
    for e in range(8):
        add(buf, bass_note(root, BEAT / 2 * 0.9), t0 + e * BEAT / 2)
    # гитара: ритм аккордами
    pat = [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5] if heavy else [0, 1.5, 2.0, 3.5]
    for p in pat:
        add(buf, power_chord(root + 12, BEAT * 0.45), t0 + p * BEAT)
    # соло с 9-го такта (пентатоника A минор)
    if bar >= 8:
        pen = [57, 60, 62, 64, 67, 69, 72]
        seq = [[69, 67, 64, 67], [65, 69, 72, 69], [67, 72, 71, 67], [64, 62, 60, 57]][bar % 4]
        for i, m in enumerate(seq):
            add(buf, lead(m, BEAT * 0.95), t0 + i * BEAT)

buf = reverb(buf, 0.8, 0.14)
out = loopify(buf, int(3.0 * SR))
A.write("music_rock", out)
print("ROCK DONE", len(out) / SR)
