"""v25: звуки новых зверей и заклинаний (синтез, без чужих записей).
Запуск из папки game:  python tools/sfx25.py -> audio/growl.wav, bark, croak, howl, cast_<стихия>.wav, orb_add.wav, spell_fizzle.wav"""
import os, wave, math
import numpy as np
SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "audio")
rng = np.random.RandomState(7)


def save(name, x):
    x = np.clip(x / (np.max(np.abs(x)) + 1e-9) * 0.8, -1, 1)
    d = (x * 32767).astype(np.int16)
    with wave.open(os.path.join(OUT, name + ".wav"), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes())


def env(n, a=0.02, r=0.3):
    t = np.arange(n) / SR
    e = np.minimum(1, t / max(a, 1e-4)) * np.exp(-np.maximum(0, t - a) / max(r, 1e-4))
    return e


def lp(x, k):
    y = np.zeros_like(x); acc = 0.0
    for i in range(len(x)):
        acc += (x[i] - acc) * k; y[i] = acc
    return y


def tone(f0, dur, harm=(1, 0.5, 0.3), vib=0.0):
    n = int(SR * dur); t = np.arange(n) / SR
    f = f0(t) if callable(f0) else np.full(n, f0)
    ph = 2 * np.pi * np.cumsum(f) / SR
    return sum(a * np.sin(ph * (i + 1)) for i, a in enumerate(harm))


def growl():
    n = int(SR * 0.9); t = np.arange(n) / SR
    base = tone(lambda t: 85 + 10 * np.sin(t * 30), 0.9, (1, 0.8, 0.6, 0.5, 0.4))
    am = 0.6 + 0.4 * np.sin(2 * np.pi * 28 * t)
    noise = lp(rng.randn(n), 0.08)
    return (base * am * 0.6 + noise * 0.5) * env(n, 0.08, 0.5)


def bark():
    out = np.zeros(int(SR * 0.6))
    for st in (0.0, 0.26):
        n = int(SR * 0.16); t = np.arange(n) / SR
        b = tone(lambda t: 520 - 900 * t, 0.16, (1, 0.7, 0.5, 0.3)) + lp(rng.randn(n), 0.3) * 0.6
        i = int(st * SR); out[i:i + n] += b * env(n, 0.005, 0.07)
    return out


def croak():
    n = int(SR * 0.5); t = np.arange(n) / SR
    pulse = (np.sin(2 * np.pi * 22 * t) > 0.2).astype(float)
    b = tone(lambda t: 140 - 30 * t, 0.5, (1, 0.9, 0.7, 0.5, 0.4, 0.3))
    return b * pulse * env(n, 0.02, 0.3)


def howl():
    n = int(SR * 2.2); t = np.arange(n) / SR
    f = lambda t: 330 + 160 * np.sin(np.minimum(t / 2.2, 1) * np.pi) + 6 * np.sin(t * 34)
    return tone(f, 2.2, (1, 0.35, 0.15)) * env(n, 0.3, 1.2)


def chime(fs, dur=0.7):
    n = int(SR * dur); out = np.zeros(n)
    for i, f in enumerate(fs):
        out += tone(f, dur, (1, 0.2)) * env(n, 0.005 + i * 0.01, 0.35)
    return out


def noise_burst(dur, k, r):
    n = int(SR * dur)
    return lp(rng.randn(n), k) * env(n, 0.01, r)


if __name__ == "__main__":
    save("growl", growl()); save("bark", bark()); save("croak", croak()); save("howl", howl())
    save("orb_add", chime([880, 1320], 0.35))
    save("spell_fizzle", noise_burst(0.4, 0.05, 0.15))
    save("cast_water", noise_burst(0.7, 0.2, 0.3) + chime([660], 0.7) * 0.3)
    save("cast_life", chime([523, 659, 784, 1046], 1.0))
    save("cast_shield", chime([392, 587, 784], 1.0) + tone(98, 1.0) * env(int(SR), 0.05, 0.5) * 0.5)
    save("cast_cold", chime([1568, 2093, 2637], 0.9) + noise_burst(0.9, 0.5, 0.3) * 0.3)
    save("cast_lightning", noise_burst(0.5, 0.9, 0.12) + noise_burst(0.5, 0.1, 0.4) * 0.8)
    save("cast_arcane", tone(lambda t: 300 + 600 * t, 0.8, (1, 0.5, 0.3)) * env(int(SR * 0.8), 0.05, 0.4))
    save("cast_earth", noise_burst(0.8, 0.03, 0.4) + tone(55, 0.8) * env(int(SR * 0.8), 0.01, 0.3))
    save("cast_fire", noise_burst(0.8, 0.25, 0.4) + noise_burst(0.8, 0.05, 0.5))
    print("ok")
