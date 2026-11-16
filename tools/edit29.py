"""v29: точечные правки скриптов (сохраняет CRLF/LF файла). Каждая пара должна найтись ровно один раз."""
import sys, json, pathlib

def apply(path, pairs):
    p = pathlib.Path(path)
    raw = p.read_bytes().decode("utf-8")
    crlf = "\r\n" in raw
    txt = raw.replace("\r\n", "\n")
    for old, new in pairs:
        n = txt.count(old)
        if n != 1:
            print("FAIL", path, "найдено", n, "раз:", old[:80].replace("\n", "\\n"))
            sys.exit(1)
        txt = txt.replace(old, new)
    if crlf:
        txt = txt.replace("\n", "\r\n")
    p.write_bytes(txt.encode("utf-8"))
    print("ok", path, len(pairs))

if __name__ == "__main__":
    spec = json.loads(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"))
    for f, pairs in spec.items():
        apply(f, pairs)
