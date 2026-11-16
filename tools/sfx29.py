"""v29: звуки погоды и огорода — дождь (петля), гроза-гром, мотыга, лейка, «плинк» семечка.
python tools/sfx29.py -> audio/rain29.wav, thunder29.wav, hoe29.wav, sprinkle29.wav, seed29.wav"""
import wave, numpy as np, os
SR = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "audio")
rg = np.random.default_rng(29)

def save(name, x):
    x = np.clip(x / max(1e-6, np.abs(x).max()) * 0.85, -1, 1)
    d = (x * 32767).astype(np.int16)
    w = wave.open(os.path.join(OUT, name + ".wav"), "wb")
    w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(d.tobytes()); w.close()
    print("audio/" + name + ".wav", round(len(x) / SR, 2), "с")

def lp(x, a):
    y = np.zeros_like(x); s = 0.0
    for i in range(len(x)):
        s += a * (x[i] - s); y[i] = s
    return y

def env(n, att, dec):
    t = np.arange(n) / SR
    return np.minimum(1, t / max(att, 1e-4)) * np.exp(-t / dec)

# дождь: розовый шум + тысячи капель; петля бесшовная (кроссфейд хвоста в начало)
n = SR * 8
white = rg.standard_normal(n + SR)
hiss = lp(white, 0.35) - lp(white, 0.02)
rain = hiss * 0.35
for k in range(2600):
    p = int(rg.integers(0, n + SR - 400))
    L = int(rg.integers(60, 300))
    f = rg.uniform(1800, 5200)
    t = np.arange(L) / SR
    rain[p:p + L] += np.sin(t * f * 6.283) * np.exp(-t * rg.uniform(120, 300)) * rg.uniform(0.1, 0.6)
fade = np.linspace(0, 1, SR)
rain[:SR] = rain[:SR] * fade + rain[n:n + SR] * (1 - fade)
save("rain29", rain[:n])

# гром: низкий рокот с раскатами
n = int(SR * 4.5)
x = lp(rg.standard_normal(n), 0.015) * 6
e = np.zeros(n)
for (st, a, d) in [(0.0, 1.0, 0.25), (0.25, 0.7, 0.9), (0.9, 0.5, 1.4), (1.8, 0.35, 1.5)]:
    i = int(st * SR); e[i:] += a * env(n - i, 0.02, d)
crack = lp(rg.standard_normal(n), 0.4) * env(n, 0.002, 0.08) * 0.6
save("thunder29", x * e + crack)

# мотыга: глухой удар в землю + шорох комьев
n = int(SR * 0.4)
thud = np.sin(np.arange(n) / SR * 6.283 * 90) * env(n, 0.003, 0.06)
dirt = lp(rg.standard_normal(n), 0.25) * env(n, 0.01, 0.12) * 0.7
save("hoe29", thud + dirt)

# лейка: струйки (шум с журчанием)
n = int(SR * 0.7)
x = lp(rg.standard_normal(n), 0.3) - lp(rg.standard_normal(n), 0.05)
gurgle = 1 + 0.5 * np.sin(np.arange(n) / SR * 6.283 * 11)
save("sprinkle29", x * gurgle * env(n, 0.05, 0.5))

# семечко: короткий деревянный «плинк» (высота меняется в игре — нота комбо)
n = int(SR * 0.22)
t = np.arange(n) / SR
save("seed29", (np.sin(t * 6.283 * 880) + 0.4 * np.sin(t * 6.283 * 1760)) * env(n, 0.002, 0.05))
