"""v29: голос героини — короткие синтезированные звуки (ох, хм, смешок, вздох, ой, ура).
Запуск из папки game: python tools/hero_voice29.py  -> audio/hero_*.wav
Формант-синтез: гортанный тон + два форманта гласной, лёгкий выдох, плавная высота.
"""
import os
import wave
import numpy as np
from scipy.signal import butter, lfilter

SR = 32000
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rng = np.random.default_rng(29)


def write(name, x):
    x = np.asarray(x, dtype=np.float64)
    x = x / (np.max(np.abs(x)) + 1e-9) * 0.8
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())


def band(x, lo, hi):
    b, a = butter(2, [lo / (SR / 2), hi / (SR / 2)], "band")
    return lfilter(b, a, x)


def vowel(dur, f0s, f1, f2, breath=0.12, vib=0.012):
    """Гласный: f0s — кривая высоты (начало, середина, конец), f1/f2 — форманты."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    f0 = np.interp(np.linspace(0, 1, n), np.linspace(0, 1, len(f0s)), f0s) * (1 + vib * np.sin(2 * np.pi * 5.5 * t))
    ph = 2 * np.pi * np.cumsum(f0) / SR
    src = sum(np.sin(k * ph) / k for k in range(1, 14))
    v = band(src, f1 * 0.8, f1 * 1.25) + 0.6 * band(src, f2 * 0.85, f2 * 1.2)
    v = v + breath * band(rng.normal(0, 1, n), 1500, 6000)
    e = np.minimum(1, t / 0.03) * np.minimum(1, (dur - t) / (dur * 0.45))
    return v * e


def gap(d):
    return np.zeros(int(d * SR))


def cat(*p):
    return np.concatenate(p)


# «ох» — усталость/вздох
write("hero_sigh", cat(vowel(0.55, [300, 280, 220], 520, 1000, breath=0.35)))
# «хм» — недовольство
write("hero_hm", cat(vowel(0.28, [230, 250, 235], 400, 1200, breath=0.05)))
# «ой» — удивление
write("hero_oh", cat(vowel(0.18, [380, 520, 480], 700, 1200), vowel(0.22, [480, 430, 360], 450, 2000)))
# смешок «хи-хи»
write("hero_giggle", cat(vowel(0.1, [520, 600, 560], 420, 2200, breath=0.2), gap(0.06), vowel(0.1, [560, 640, 600], 420, 2200, breath=0.2), gap(0.06), vowel(0.14, [580, 660, 520], 420, 2200, breath=0.2)))
# радостное «ура!»
write("hero_yay", cat(vowel(0.12, [380, 420, 420], 350, 800), vowel(0.28, [420, 560, 520], 760, 1300)))
# «ай» — ушиблась
write("hero_ouch", cat(vowel(0.16, [560, 640, 620], 800, 1300), vowel(0.2, [620, 520, 400], 600, 2100)))
print("ok")
