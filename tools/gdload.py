"""Мини-читалка констант из .gd-файлов игры (словари и массивы) для скриптов-справочников."""
import re
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent

_NS = {"true": True, "false": False, "null": None,
       "Color": lambda *a: "#" + str(a[0]) if len(a) == 1 else list(a),
       "Vector2": lambda *a: list(a), "Vector2i": lambda *a: list(a), "Rect2": lambda *a: list(a),
       "Vector3": lambda *a: list(a), "PackedStringArray": lambda a=(): list(a),
       "INF": 1e9, "PI": 3.14159}


def _consts_from(text):
    """Простые «const NAME := 5» (номера биомов и т.п.)."""
    out = {}
    for m in re.finditer(r"^const\s+([A-Z_0-9]+)\s*(?::=|=|:\s*\w+\s*=)\s*(-?\d+(?:\.\d+)?)\s*(?:#.*)?$", text, re.M):
        out[m.group(1)] = float(m.group(2)) if "." in m.group(2) else int(m.group(2))
    return out


def _grab(text, start):
    """Вернуть текст выражения, начиная с позиции start (до закрытия скобок)."""
    depth = 0
    i = start
    n = len(text)
    out = []
    in_str = None
    began = False
    while i < n:
        c = text[i]
        if in_str:
            out.append(c)
            if c == "\\":
                out.append(text[i + 1])
                i += 2
                continue
            if c == in_str:
                in_str = None
            i += 1
            continue
        if c in "\"'":
            in_str = c
            out.append(c)
        elif c == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue
        elif c in "[{(":
            depth += 1
            began = True
            out.append(c)
        elif c in "]})":
            depth -= 1
            out.append(c)
            if depth == 0 and began:
                break
        else:
            if c == "\n" and depth == 0:
                break
            out.append(c)
        i += 1
    return "".join(out)


_cache = {}


class _Mod:
    """Псевдо-модуль для preload: WD.GROTTO, W.xxx — берём константы из чужого файла."""
    def __init__(self, fname):
        self.fname = fname

    def __getattr__(self, name):
        return load(self.fname, name)


def load(fname, name):
    path = GAME / fname
    if path not in _cache:
        _cache[path] = path.read_text(encoding="utf-8")
    text = _cache[path]
    m = re.search(r"^const\s+" + re.escape(name) + r"\b[^=\n]*?(?::=|=)\s*", text, re.M)
    if not m:
        raise KeyError(f"{fname}:{name}")
    expr = _grab(text, m.end())
    ns = dict(_NS)
    ns.update(_consts_from(text))
    for pm in re.finditer(r'^const\s+(\w+)\s*(?::=|=)\s*preload\("res://([\w/]+\.gd)"\)', text, re.M):
        ns[pm.group(1)] = _Mod(pm.group(2))
    return eval(expr, {"__builtins__": {}}, ns)
