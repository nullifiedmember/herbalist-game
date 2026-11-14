"""v24: звуки — треск падающего дерева, удар ствола о землю, хруст веток.
python tools/sfx24.py -> audio/tree_crack.wav, tree_thud.wav, branch_snap.wav"""
import os
import numpy as np
from steps_gen import write, bp, lp, hp, env, noise, SR, rng


def crack():
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    x = np.zeros(n)
    # скрип волокон: всё чаще щелчки
    clicks = 0
    p = 0.0
    while p < 1.25:
        i = int(p * SR)
        g = int(0.004 * SR)
        if i + g < n:
            x[i:i + g] += noise(g) * env(g, 0.0003, 0.004, 5.0) * (0.4 + p * 0.5)
        p += max(0.012, 0.11 * (1.0 - p / 1.3))
        clicks += 1
    x = bp(x, 600, 5000)
    # низкий стон дерева
    f = 90 + 40 * np.sin(2 * np.pi * 1.3 * t)
    groan = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.3, 0.9, 1.5) * 0.25
    groan = lp(groan, 400)
    # финальный треск
    i0 = int(1.15 * SR)
    g2 = n - i0
    snap = bp(noise(g2), 400, 6000) * env(g2, 0.001, 0.08, 4.0) * 1.6
    x[i0:] += snap
    return x + groan


def thud():
    n = int(1.2 * SR)
    t = np.arange(n) / SR
    f = 48 * (1 + 0.8 * np.exp(-t * 18))
    boom = np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.003, 0.35, 3.0)
    body = lp(noise(n), 300) * env(n, 0.002, 0.12, 3.0) * 1.2
    leaves = bp(noise(n), 2000, 8000) * env(n, 0.02, 0.5, 2.0) * 0.35   # шелест кроны
    twigs = np.zeros(n)
    for _ in range(40):
        i = int(rng.uniform(0.02, 0.5) * SR)
        g = int(0.006 * SR)
        twigs[i:i + g] += noise(g) * env(g, 0.0003, 0.005, 5.0) * rng.uniform(0.2, 0.7)
    twigs = bp(twigs, 1500, 7000)
    return boom * 1.3 + body + leaves + twigs * 0.6


def snap():
    n = int(0.5 * SR)
    x = np.zeros(n)
    for k in range(6):
        i = int(rng.uniform(0.0, 0.3) * SR)
        g = int(0.01 * SR)
        x[i:i + g] += noise(g) * env(g, 0.0005, 0.008, 5.0) * rng.uniform(0.5, 1.0)
    x = bp(x, 1200, 7000)
    x += bp(noise(n), 2500, 8000) * env(n, 0.01, 0.2, 2.5) * 0.3
    return x


if __name__ == "__main__":
    write("tree_crack", crack())
    write("tree_thud", thud())
    write("branch_snap", snap())
    print("ok")
