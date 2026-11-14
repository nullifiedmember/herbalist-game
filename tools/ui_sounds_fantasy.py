"""Звуки интерфейса в духе средневекового фэнтези: стекло-колокольчик, арфа, пергамент, магия.
Запуск из папки game:  python tools/ui_sounds_fantasy.py
Перезаписывает ui_click, ui_select, page, pickup, coin (старые лежат в game/audio_old_ui)."""
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
import numpy as np
import audio_gen as A
from audio_gen import SR, lowpass, highpass, reverb, add, write, rng

def tone(parts, dur, decay):
    """Мягкий колокольный тон: список (множитель частоты, громкость, затухание)."""
    n = int(dur * SR); t = np.arange(n) / SR
    return t, n

def glass(f, dur, bright=1.0):
    """Стеклянный/хрустальный колокольчик: неточные обертоны, плавная атака, долгий хвост."""
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.zeros(n)
    for m, a, dec in [(1, 1.0, 5.0), (2.01, 0.35, 7.0), (2.76, 0.28 * bright, 9.0), (4.07, 0.14 * bright, 13.0), (5.43, 0.07 * bright, 18.0)]:
        x += a * np.sin(2 * np.pi * f * m * t + rng.uniform(0, 0.4)) * np.exp(-dec * t)
    att = np.clip(t / 0.004, 0, 1)
    return x * att

def harp(f, dur):
    """Арфа: тёплый щипок с коротким мягким ударом и тёплыми обертонами (без «8-бит»)."""
    n = int(dur * SR); t = np.arange(n) / SR
    x = np.sin(2 * np.pi * f * t) * np.exp(-3.2 * t) + 0.35 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-5 * t) \
        + 0.12 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-8 * t)
    thump = lowpass(rng.normal(0, 1, n), 1200) * np.exp(-t * 120) * 0.15
    return (x + thump) * np.clip(t / 0.003, 0, 1)

def air(dur, hz=(2500, 9000), amp=0.2):
    n = int(dur * SR)
    return highpass(lowpass(rng.normal(0, 1, n), hz[1]), hz[0]) * amp

def sparkle(dur, seed, base=2400):
    r = np.random.default_rng(seed)
    x = np.zeros(int(dur * SR))
    for i in range(int(dur * 22)):
        add(x, glass(base * r.choice([1, 1.25, 1.5, 2, 2.5]), 0.18, 0.5) * r.uniform(0.08, 0.3), r.uniform(0, dur - 0.1))
    return x

def build():
    # клик: деревянный «тук» + тихий хрустальный звон — как касание резной шкатулки
    n = int(0.06 * SR); t = np.arange(n) / SR
    wood = np.sin(2 * np.pi * 320 * (1 - 0.3 * t / 0.06) * t) * np.exp(-t * 70) * 0.8
    wood += lowpass(rng.normal(0, 1, n), 900) * np.exp(-t * 90) * 0.25
    x = np.zeros(int(0.5 * SR)); add(x, wood, 0); add(x, glass(1568, 0.4, 0.6) * 0.35, 0.004)
    write("ui_click", reverb(lowpass(x, 6500), 0.7, 0.18))

    # выбор / подтверждение: восходящий арфовый аккорд в миноре с искрами магии
    x = np.zeros(int(1.6 * SR))
    for i, f in enumerate([392.0, 466.16, 587.33, 783.99]):   # G Bb D G
        add(x, harp(f, 1.0) * 0.8, i * 0.07)
    add(x, glass(1567.98, 1.0) * 0.28, 0.2)
    add(x, sparkle(0.9, 3) * 0.5, 0.2)
    write("ui_select", reverb(lowpass(x, 7500), 1.8, 0.35))

    # страница: шелест пергамента + мягкий шорох переплёта
    n = int(0.45 * SR); t = np.arange(n) / SR
    env = np.sin(np.pi * np.clip(t / 0.4, 0, 1)) ** 1.5
    x = lowpass(highpass(rng.normal(0, 1, n), 1800), 7000) * env * 0.45
    crack = np.zeros(n)
    for _ in range(14):
        k = int(rng.uniform(0, 0.4) * SR); m = 90
        crack[k:k + m] += rng.normal(0, 1, min(m, n - k)) * np.exp(-np.arange(min(m, n - k)) / 18) * rng.uniform(0.2, 0.6)
    x += highpass(crack, 1500) * 0.6
    x += lowpass(rng.normal(0, 1, n), 400) * env * 0.25
    write("page", reverb(x, 0.5, 0.1))

    # подбор предмета: тёплый хрусталь вверх + искра
    x = np.zeros(int(1.0 * SR))
    add(x, harp(587.33, 0.6) * 0.8, 0)
    add(x, harp(880.0, 0.7) * 0.8, 0.09)
    add(x, glass(1760, 0.6) * 0.3, 0.1)
    add(x, sparkle(0.5, 11, 3000) * 0.5, 0.1)
    write("pickup", reverb(lowpass(x, 7500), 1.0, 0.3))

    # монета: золото — глубокий звон с двойным ударом
    x = np.zeros(int(0.9 * SR))
    add(x, glass(1760, 0.8, 1.2) * 0.8, 0)
    add(x, glass(2349, 0.7, 1.2) * 0.7, 0.075)
    add(x, highpass(rng.normal(0, 1, 400), 3500) * np.exp(-np.arange(400) / 60) * 0.15, 0)
    write("coin", reverb(x, 0.8, 0.22))

if __name__ == "__main__":
    build()
    print("DONE")
