"""v24: шаги по поверхностям — синтез. step_<surf>_<0..3>.wav
Поверхности: grass, stone, wood, gravel, sand, mud, leaves, snow, water.
Шаг = «пятка» + «носок» (две слитные фазы), у каждой поверхности свой материал."""
import os
import numpy as np
from scipy.signal import butter, lfilter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(24)


def write(name, x):
    import wave
    x = np.asarray(x, dtype=np.float64)
    x = x - np.mean(x)
    fade = min(len(x), int(0.004 * SR))
    x[-fade:] *= np.linspace(1, 0, fade)
    peak = np.max(np.abs(x)) + 1e-9
    x = x / peak * 0.85
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def bp(x, lo, hi, order=2):
    b, a = butter(order, [lo / (SR / 2), min(hi / (SR / 2), 0.99)], btype="band")
    return lfilter(b, a, x)


def lp(x, hi, order=2):
    b, a = butter(order, hi / (SR / 2), btype="low")
    return lfilter(b, a, x)


def hp(x, lo, order=2):
    b, a = butter(order, lo / (SR / 2), btype="high")
    return lfilter(b, a, x)


def env(n, att, dec, curve=3.0):
    t = np.arange(n) / SR
    e = np.minimum(1.0, t / max(att, 1e-4)) * np.exp(-np.maximum(0, t - att) * curve / max(dec, 1e-4))
    return e


def noise(n):
    return rng.standard_normal(n)


def thud(n, f0, dec):
    """глухой удар ноги — низкий тон с быстрым спадом высоты"""
    t = np.arange(n) / SR
    f = f0 * (1.0 + 1.5 * np.exp(-t * 60))
    ph = 2 * np.pi * np.cumsum(f) / SR
    return np.sin(ph) * env(n, 0.002, dec, 4.0)


def grains(n, rate, dur_ms, lo, hi, amp_env):
    """россыпь мелких щелчков (гравий, листья, снег)"""
    x = np.zeros(n)
    k = int(rate * n / SR)
    g = int(dur_ms * SR / 1000)
    for _ in range(k):
        p = int(rng.uniform(0, 1) ** 1.6 * (n - g - 1))
        e = env(g, 0.0005, dur_ms / 1000.0, 5.0)
        x[p:p + g] += noise(g) * e * rng.uniform(0.3, 1.0)
    x = bp(x, lo, hi)
    return x * amp_env


def two_phase(make, total=0.26, gap=(0.045, 0.075)):
    """пятка, затем носок (чуть тише)"""
    n = int(total * SR)
    x = np.zeros(n)
    a = make(int(0.16 * SR), 1.0)
    x[:len(a)] += a
    off = int(rng.uniform(*gap) * SR)
    b = make(int(0.14 * SR), 0.55)
    end = min(n, off + len(b))
    x[off:end] += b[:end - off]
    return x


def grass(n, k):
    e = env(n, 0.006, 0.07, 3.0)
    sw = bp(noise(n), 1800, 7000) * e * 0.9           # шорох стеблей
    sw += bp(noise(n), 600, 1800) * env(n, 0.003, 0.05) * 0.5
    sw += grains(n, 900, 3, 2500, 8000, env(n, 0.004, 0.09)) * 0.5   # хруст травинок
    return (sw + thud(n, 70, 0.04) * 0.35) * k


def stone(n, k):
    e = env(n, 0.0008, 0.018, 4.0)
    click = bp(noise(n), 1500, 6000) * e * 1.0           # каблук по камню
    t = np.arange(n) / SR
    ring = (np.sin(2 * np.pi * 2300 * t) * 0.15 + np.sin(2 * np.pi * 3700 * t) * 0.08) * env(n, 0.0005, 0.03)
    scuff = bp(noise(n), 2500, 9000) * env(n, 0.01, 0.04) * 0.25
    return (click + ring + scuff + thud(n, 110, 0.02) * 0.5) * k


def wood(n, k):
    t = np.arange(n) / SR
    body = 0.0
    for f, a, d in ((180, 1.0, 0.07), (390, 0.55, 0.05), (760, 0.25, 0.03)):
        body = body + np.sin(2 * np.pi * f * t + rng.uniform(0, 6)) * a * env(n, 0.001, d, 4.0)
    knock = bp(noise(n), 400, 2500) * env(n, 0.0008, 0.015) * 0.7
    creak = 0.0
    if rng.uniform() < 0.35:
        cf = 600 + 200 * np.sin(2 * np.pi * 9 * t)
        creak = np.sin(2 * np.pi * np.cumsum(cf) / SR) * env(n, 0.02, 0.06) * 0.08
    return (body * 0.7 + knock + creak) * k


def gravel(n, k):
    g = grains(n, 2400, 4, 1200, 7000, env(n, 0.004, 0.10, 2.5))
    return (g + thud(n, 90, 0.03) * 0.3 + bp(noise(n), 300, 1200) * env(n, 0.002, 0.03) * 0.3) * k


def sand(n, k):
    e = env(n, 0.012, 0.10, 2.5)
    return (bp(noise(n), 900, 5000) * e * 0.8 + lp(noise(n), 500) * env(n, 0.004, 0.05) * 0.6 + thud(n, 60, 0.04) * 0.25) * k


def mud(n, k):
    t = np.arange(n) / SR
    e = env(n, 0.01, 0.12, 2.5)
    f = 140 + 260 * np.exp(-t * 18)
    squelch = np.sin(2 * np.pi * np.cumsum(f) / SR) * e * 0.5
    wet = bp(noise(n), 400, 2200) * e * 0.6
    suck = bp(noise(n), 1500, 4000) * env(n, 0.04, 0.05) * 0.25
    return (squelch + wet + suck) * k


def leaves(n, k):
    g = grains(n, 1800, 6, 1500, 9000, env(n, 0.006, 0.12, 2.2))
    return (g + bp(noise(n), 2000, 8000) * env(n, 0.004, 0.08) * 0.4 + thud(n, 70, 0.03) * 0.3) * k


def snow(n, k):
    g = grains(n, 3000, 5, 800, 5000, env(n, 0.01, 0.12, 2.0))
    return (g + lp(noise(n), 700) * env(n, 0.006, 0.06) * 0.5) * k


def water(n, k):
    t = np.arange(n) / SR
    spl = bp(noise(n), 500, 4000) * env(n, 0.004, 0.09, 2.5)
    bub = 0.0
    for _ in range(3):
        f0 = rng.uniform(500, 1100)
        st = rng.uniform(0.0, 0.05)
        tt = np.maximum(0, t - st)
        bub = bub + np.sin(2 * np.pi * np.cumsum(f0 * (1 + 0.8 * np.exp(-tt * 40))) / SR) * env(n, 0.002, 0.03) * (t > st) * 0.3
    return (spl + bub) * k


SURF = {"grass": grass, "stone": stone, "wood": wood, "gravel": gravel, "sand": sand,
        "mud": mud, "leaves": leaves, "snow": snow, "water": water}

if __name__ == "__main__":
    for name, fn in SURF.items():
        for i in range(4):
            x = two_phase(fn)
            write("step_%s_%d" % (name, i), x)
    print("ok", len(SURF) * 4)
