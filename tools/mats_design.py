"""Материалы v20 — почти как в Террарии: дерево, камень, металлы, самоцветы, волокна, ткани, краски, перья, шерсть...
Одна таблица -> значки art/m20_<id>.png, спрайты мастерских/ловушек/построек/мест добычи и mats_db.gd.
Запуск из папки game:  python tools/mats_design.py [--art] [--write] [--preview путь]
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from px import Canvas, ramp, hx, mix, OUTLINE  # noqa: E402
import birds_design as BD  # noqa: E402

GAME = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(GAME, "art")

HOME, MEADOW, SPIDER, GOTHIC, KNIGHT, ELF, MAGE, ORC, DWARF, CATS = range(10)
UNICORN, GROTTO, BIRCH, PINE, AUTUMN, SWAMP, FIELD, JAPAN, BEACH, SEA = range(10, 20)

MATS = {}      # id -> dict(name, w, price, tpl, col, props, size, stack, cat, icon)
ORDER = []


def add(mid, name, tpl, col, price=2, w=0.3, cat="", props=None, size=(1, 1), stack=10, icon=None):
    MATS[mid] = dict(name=name, tpl=tpl, col=col, price=price, w=w, cat=cat, props=props or {}, size=list(size), stack=stack,
                     icon=icon or ("m20_" + mid))
    ORDER.append(mid)


# ======================================================================== ДЕРЕВО
# порода: [прилагательное ж.р., кора, древесина]
WOODS = {
    "tree_a": ["Дубовая", "6a5a48", "c0905a"], "tree_b": ["Липовая", "7a6e5e", "ecd8ac"], "tree_c": ["Вязовая", "6a5040", "b08860"],
    "tree_d": ["Ясеневая", "8a8478", "e0c898"], "pine_a": ["Сосновая", "9a5a3a", "e8c080"], "pine_b": ["Еловая", "5a4a3a", "e0c890"],
    "tree_blossom": ["Сакуровая", "6a4048", "d8a090"], "tree_autumn": ["Кленовая", "7a5a40", "e4bc84"], "tree_autumn2": ["Рябиновая", "6a5a50", "c89870"],
    "tree_apple": ["Яблоневая", "7a6050", "d0a070"], "tree_birch": ["Берёзовая", "e8e4dc", "f0dcb0"], "tree_unicorn": ["Розовая", "b07a9a", "f0c0d8"],
    "dead": ["Сухая", "5a5250", "a09080"],
}
WOOD_PROPS = {"tree_a": {"Сила": 1}, "tree_b": {"Покой": 1}, "tree_c": {"Исцеление": 1}, "tree_d": {"Свежесть": 1}, "pine_a": {"Свежесть": 1, "Тепло": 1},
              "pine_b": {"Холод": 1}, "tree_blossom": {"Чары": 1}, "tree_autumn": {"Огонь": 1}, "tree_autumn2": {"Жгучесть": 1},
              "tree_apple": {"Свежесть": 1}, "tree_birch": {"Свежесть": 1, "Исцеление": 1}, "tree_unicorn": {"Свет": 1, "Чары": 1}, "dead": {"Тьма": 1}}
for s, (adj, bark, wood) in WOODS.items():
    add("wood_" + s, adj + " чурка", "wood_chunk", [bark, wood], price=3, w=1.2, cat="wood", size=(2, 1), stack=5)
    add("plank_" + s, adj + " доска", "plank", [wood], price=5, w=0.8, cat="wood", size=(2, 1), stack=10)
    add("bark_" + s, adj + " кора", "bark", [bark, wood], price=2, w=0.1, cat="wood", props=WOOD_PROPS[s], stack=10)
add("stick", "Палка", "stick", ["8a6a44"], 1, 0.2, "wood", size=(1, 2), stack=10)
add("twig", "Хворост", "twigs", ["7a5a3a"], 1, 0.1, "wood", stack=10)
add("sawdust", "Опилки", "pile", ["e0c898"], 1, 0.1, "wood", stack=20)
add("charcoal", "Древесный уголь", "chunks", ["3a3438"], 3, 0.3, "wood", props={"Огонь": 1, "Тьма": 1}, stack=20)
add("wood_ash", "Зола", "pile", ["9a9894"], 1, 0.1, "wood", props={"Сила": 1}, stack=20)
add("resin", "Смола", "drop", ["e0a030"], 4, 0.1, "wood", props={"Тепло": 1, "Исцеление": 1}, stack=10)
add("tar", "Дёготь", "pot", ["3a2a20", "1e1a1a"], 6, 0.6, "wood", stack=5)
add("beam", "Брус", "beam", ["b0865a"], 12, 2.5, "wood", size=(3, 1), stack=5)
add("shingle", "Дранка", "shingles", ["a07a50"], 3, 0.2, "wood", stack=20)
add("stave", "Клёпка для бочки", "stave", ["b88a58"], 3, 0.4, "wood", size=(1, 2), stack=10)
add("wood_glue", "Столярный клей", "pot", ["c89040", "f0d080"], 6, 0.4, "wood", stack=5)
add("wood_gear", "Деревянная шестерня", "gear", ["b08050"], 8, 0.5, "wood", stack=5)
add("driftwood", "Плавник", "wood_chunk", ["a8a090", "d8d0c0"], 3, 0.8, "wood", props={"Холод": 1, "Свежесть": 1}, size=(2, 1), stack=5)
add("wicker", "Ивовые прутья", "twigs", ["a89060"], 2, 0.2, "wood", stack=20)

# ======================================================================== КАМЕНЬ И ЗЕМЛЯ
EARTH = [
    ("clay", "Глина", "lump", "a08070", {"Исцеление": 1}), ("red_clay", "Красная глина", "lump", "b05a3a", {"Тепло": 1}),
    ("white_clay", "Белая глина (каолин)", "lump", "e8e0d4", {"Свет": 1}), ("sand", "Песок", "pile", "e8d098", {}),
    ("black_sand", "Чёрный песок", "pile", "4a4448", {"Тьма": 1}), ("quartz_sand", "Кварцевый песок", "pile", "f4f0e8", {"Свет": 1}),
    ("gravel", "Гравий", "pebbles", "8a8680", {}), ("peat", "Торф", "lump", "4a3a2a", {"Огонь": 1, "Тьма": 1}),
    ("loam", "Чернозём", "pile", "3a2e26", {"Сила": 1}), ("salt", "Соль", "crystals", "f4f4f0", {"Свежесть": 1, "Холод": 1}),
    ("sulfur", "Сера", "crystals", "e8d030", {"Огонь": 1, "Жгучесть": 1}), ("saltpeter", "Селитра", "crystals", "e0e8e8", {"Огонь": 1}),
    ("coal", "Каменный уголь", "chunks", "2a2a30", {"Огонь": 1}),
]
for mid, nm, tpl, c, pr in EARTH:
    add(mid, nm, tpl, [c], 2 if mid not in ("sulfur", "saltpeter", "salt") else 4, 0.5, "earth", props=pr, stack=20)
STONES = [
    ("flint", "Кремень", "rock", ["4a4a52", "c8c4b8"], "glass"), ("slate", "Сланец", "rock", ["4a5260"], "layers"),
    ("marble", "Мрамор", "rock", ["eceae4", "a8a8b0"], "veins"), ("granite", "Гранит", "rock", ["a08a82"], "speckle"),
    ("basalt", "Базальт", "rock", ["3a3a40"], "speckle"), ("limestone", "Известняк", "rock", ["d8d0b8"], "pores"),
    ("chalk", "Мел", "rock", ["f4f2ea"], "plain"), ("sandstone", "Песчаник", "rock", ["d8a868"], "layers"),
    ("obsidian", "Обсидиан", "rock", ["1e1a2a", "6a5a9a"], "glass"), ("pumice", "Пемза", "rock", ["c8c0b0"], "pores"),
]
for mid, nm, tpl, c, fx in STONES:
    add(mid, nm, tpl, c + [fx], 3 if mid not in ("marble", "obsidian") else 7, 1.2, "stone", props={"Сила": 1} if mid != "obsidian" else {"Тьма": 1, "Сила": 1}, stack=10)
# изделия из камня и глины
add("brick", "Кирпич", "brick", ["b0603a"], 4, 1.2, "stone", stack=10)
add("red_brick", "Тёмно-красный кирпич", "brick", ["8a3a2a"], 5, 1.2, "stone", stack=10)
add("roof_tile", "Черепица", "tile", ["c0603a"], 3, 0.4, "stone", stack=20)
add("porcelain", "Фарфор", "tile", ["f4f4f8"], 8, 0.4, "stone", stack=10)
add("pot_clay", "Глиняный горшок", "clay_pot", ["b07050"], 6, 1.0, "stone", stack=3)
add("lime", "Известь", "sack", ["e8e4d8", "c8b890"], 4, 1.0, "stone", stack=10)
add("mortar", "Строительный раствор", "sack", ["b0aca0", "8a8070"], 5, 1.5, "stone", stack=10)
add("stone_block", "Тёсаный камень", "block", ["9a9690"], 5, 2.0, "stone", stack=10)
add("marble_block", "Мраморный блок", "block", ["eceae4", "a8a8b0"], 14, 2.0, "stone", stack=10)
add("granite_block", "Гранитный блок", "block", ["a08a82"], 8, 2.0, "stone", stack=10)
add("sandstone_block", "Блок песчаника", "block", ["d8a868"], 6, 2.0, "stone", stack=10)
add("basalt_block", "Базальтовый блок", "block", ["3a3a40"], 7, 2.0, "stone", stack=10)
add("slate_tile", "Сланцевая плитка", "tile", ["4a5260"], 4, 0.5, "stone", stack=20)
add("cobble", "Булыжник", "pebbles", ["7a7670"], 2, 1.0, "stone", stack=20)

# ======================================================================== СТЕКЛО
add("glass", "Стекло", "pane", ["a8d8e0"], 6, 0.6, "glass", stack=10)
add("glass_clear", "Прозрачное стекло", "pane", ["e0f4f8"], 9, 0.6, "glass", props={"Свет": 1}, stack=10)
add("glass_smoky", "Дымчатое стекло", "pane", ["6a6a78"], 9, 0.6, "glass", props={"Тьма": 1}, stack=10)
add("bottle_glass", "Стеклянный флакон", "vial", ["b8e0e8"], 5, 0.3, "glass", stack=5)

# ======================================================================== МЕТАЛЛЫ
METALS = [
    # id, руда (имя), слиток (имя), цвет руды-самородков, цвет металла, биомы руды, цена слитка
    ("copper", "Медная руда", "Медный слиток", "d8783a", "e08a4a", {DWARF: 3, ORC: 2, GROTTO: 2, AUTUMN: 1, MEADOW: 1}, 10),
    ("tin", "Оловянная руда", "Оловянный слиток", "b8bcc4", "c8ccd4", {DWARF: 2, GROTTO: 2, PINE: 1, BIRCH: 1}, 9),
    ("iron", "Железная руда", "", "a86a4a", "9aa0aa", {DWARF: 3, ORC: 3, KNIGHT: 2, PINE: 1, GOTHIC: 1}, 14),
    ("silver", "Серебряная руда", "Серебряный слиток", "d8dce8", "e4e8f0", {GROTTO: 2, MAGE: 2, GOTHIC: 2, PINE: 1}, 24),
    ("gold", "Золотая руда", "Золотой слиток", "f0c030", "f4d04a", {DWARF: 2, FIELD: 1, JAPAN: 1}, 36),
    ("zinc", "Цинковая руда", "Цинковый слиток", "8aa0a8", "a8b8c0", {GROTTO: 2, DWARF: 1, SWAMP: 1}, 10),
    ("lead", "Свинцовая руда", "Свинцовый слиток", "6a6e80", "7a7e90", {GOTHIC: 2, DWARF: 1, SPIDER: 1}, 9),
    ("nickel", "Никелевая руда", "Никелевый слиток", "c8c4a0", "d0d0c0", {PINE: 2, DWARF: 1, GROTTO: 1}, 14),
    ("cobalt", "Кобальтовая руда", "Кобальтовый слиток", "3a5ad0", "5a7ae8", {GROTTO: 2, MAGE: 1, DWARF: 1}, 28),
    ("mithril", "Мифриловая руда", "Мифриловый слиток", "a8e8e0", "c8f4f0", {ELF: 2, MAGE: 1, UNICORN: 1}, 60),
    ("adamant", "Адамантовая руда", "Адамантовый слиток", "d03a6a", "e85a8a", {DWARF: 1, ORC: 1, GROTTO: 1}, 70),
    ("orichalcum", "Орихалковая руда", "Орихалковый слиток", "f08aa8", "f4a8c0", {JAPAN: 2, SEA: 1, BEACH: 1}, 66),
]
ORE_IDS = []
for mid, ore_n, bar_n, oc, mc, bi, price in METALS:
    add("ore_" + mid, ore_n, "ore", ["6a6460", oc], max(3, price // 3), 1.0, "metal", props={"Сила": 1}, stack=5)
    ORE_IDS.append(mid)
    add("nugget_" + mid, ore_n.split()[0].replace("ая", "ый") + " самородок", "nugget", [oc], max(2, price // 5), 0.1, "metal", stack=20)
    if mid != "iron":
        add("bar_" + mid, bar_n, "bar", [mc], price, 1.5, "metal", stack=5)
# сплавы
ALLOYS = [("bronze", "Бронзовый слиток", "c88a3a", [("copper", 3), ("tin", 1)], 4, 16), ("brass", "Латунный слиток", "e8c050", [("copper", 2), ("zinc", 1)], 3, 15),
          ("steel", "Стальной слиток", "b8c0cc", [("iron", 2), ("coal", 1)], 2, 26), ("electrum", "Электрум", "f0e08a", [("silver", 1), ("gold", 1)], 2, 34),
          ("pewter", "Пьютер", "a8acb8", [("tin", 3), ("lead", 1)], 4, 12), ("rose_gold", "Розовое золото", "f0a888", [("gold", 2), ("copper", 1)], 3, 32),
          ("starsteel", "Звёздная сталь", "d0d8ff", [("steel", 2), ("star", 1)], 2, 120)]
for mid, nm, c, ins, outn, price in ALLOYS:
    add("bar_" + mid, nm, "bar", [c], price, 1.5, "metal", stack=5)
# волшебные слитки из волшебных руд (ore_<id> уже есть в игре — mining_db)
MAGIC = [("mana", "Мана-слиток", "8a7aff"), ("frost", "Ледяной слиток", "8ad8ff"), ("ember", "Огненный слиток", "ff6a3a"),
         ("verdant", "Живой слиток", "5ad07a"), ("void", "Слиток бездны", "5a3a8a"), ("moonsilver", "Лунный слиток", "d8e0ff"),
         ("sunstone", "Солнечный слиток", "ffd040")]
MAGIC_PROPS = {"mana": {"Чары": 2}, "frost": {"Холод": 2}, "ember": {"Огонь": 2}, "verdant": {"Исцеление": 2}, "void": {"Тьма": 2},
               "moonsilver": {"Свет": 1, "Сон": 1}, "sunstone": {"Свет": 2}}
for mid, nm, c in MAGIC:
    add("bar_" + mid, nm, "bar", [c], 120, 1.2, "metal", props=MAGIC_PROPS[mid], stack=5)
# детали
add("nail", "Гвозди", "nails", ["9aa0aa"], 1, 0.05, "metal", stack=50)
add("hinge", "Дверная петля", "hinge", ["8a909a"], 4, 0.2, "metal", stack=10)
add("chain", "Цепь", "chain", ["9aa0aa"], 8, 0.8, "metal", stack=5)
add("wire_copper", "Медная проволока", "wire", ["e08a4a"], 5, 0.2, "metal", stack=10)
add("wire_silver", "Серебряная проволока", "wire", ["e4e8f0"], 12, 0.2, "metal", stack=10)
add("wire_gold", "Золотая проволока", "wire", ["f4d04a"], 18, 0.2, "metal", stack=10)
add("sheet_copper", "Медный лист", "sheet", ["e08a4a"], 9, 0.8, "metal", stack=5)
add("sheet_tin", "Жесть", "sheet", ["c8ccd4"], 8, 0.8, "metal", stack=5)
add("sheet_iron", "Железный лист", "sheet", ["9aa0aa"], 13, 1.0, "metal", stack=5)
add("gear_bronze", "Бронзовая шестерня", "gear", ["c88a3a"], 10, 0.4, "metal", stack=10)
add("spring", "Пружина", "spring", ["b8c0cc"], 9, 0.1, "metal", stack=10)
add("needle", "Игла", "needle", ["c8ccd4"], 3, 0.02, "metal", stack=20)
add("bell", "Колокольчик", "bell", ["e8c050"], 12, 0.4, "metal", stack=5)
add("lantern_frame", "Каркас фонаря", "lantern_frame", ["5a5a62"], 10, 0.8, "metal", stack=5)

# ======================================================================== САМОЦВЕТЫ
GEMS = [("amethyst", "Аметист", "9a5ad8", {MAGE: 3, GROTTO: 3, UNICORN: 1}), ("topaz", "Топаз", "f0b030", {DWARF: 2, FIELD: 1, ORC: 1}),
        ("garnet", "Гранат", "a8202a", {GOTHIC: 2, DWARF: 2}), ("opal", "Опал", "e8e0f0", {MAGE: 2, UNICORN: 2}),
        ("jade", "Нефрит", "4aa06a", {JAPAN: 3, ELF: 1}), ("peridot", "Перидот", "a8d040", {ELF: 2, SWAMP: 1, BIRCH: 1}),
        ("citrine", "Цитрин", "f0d040", {FIELD: 1, AUTUMN: 2, DWARF: 1}), ("aquamarine", "Аквамарин", "60d0e0", {BEACH: 2, SEA: 2, PINE: 1}),
        ("moonstone", "Лунный камень", "c8d8f0", {MAGE: 2, UNICORN: 2, GROTTO: 1}), ("onyx", "Оникс", "2a2430", {GOTHIC: 3, SPIDER: 2}),
        ("lapis", "Лазурит", "2a4ab0", {DWARF: 2, MAGE: 1, GROTTO: 1}), ("diamond", "Алмаз", "e8f8ff", {DWARF: 1, GROTTO: 1}),
        ("tourmaline", "Турмалин", "e05a8a", {UNICORN: 2, JAPAN: 1}), ("rose_quartz", "Розовый кварц", "f0b0c8", {UNICORN: 2, CATS: 1, ELF: 1}),
        ("smoky_quartz", "Дымчатый кварц", "7a6a5a", {PINE: 2, GROTTO: 1, AUTUMN: 1}), ("jet", "Гагат", "1a1a20", {GOTHIC: 2, SWAMP: 1}),
        ("amber", "Янтарь", "e89a20", {PINE: 3, BEACH: 2}), ("malachite", "Малахит", "2a9a6a", {DWARF: 2, GROTTO: 1, ORC: 1})]
GEM_PROPS = {"amethyst": {"Чары": 1, "Покой": 1}, "topaz": {"Тепло": 1, "Свет": 1}, "garnet": {"Огонь": 1, "Сила": 1}, "opal": {"Чары": 2},
             "jade": {"Исцеление": 1, "Покой": 1}, "peridot": {"Свежесть": 1, "Исцеление": 1}, "citrine": {"Свет": 1, "Тепло": 1},
             "aquamarine": {"Холод": 1, "Свежесть": 1}, "moonstone": {"Сон": 1, "Свет": 1}, "onyx": {"Тьма": 1, "Сила": 1},
             "lapis": {"Чары": 1, "Холод": 1}, "diamond": {"Свет": 2, "Сила": 1}, "tourmaline": {"Чары": 1, "Жгучесть": 1},
             "rose_quartz": {"Покой": 1, "Исцеление": 1}, "smoky_quartz": {"Тьма": 1, "Покой": 1}, "jet": {"Тьма": 2},
             "amber": {"Тепло": 1, "Исцеление": 1}, "malachite": {"Исцеление": 1, "Сила": 1}}
for mid, nm, c, bi in GEMS:
    price = 40 if mid == "diamond" else 18
    add("gem_raw_" + mid, nm + " (необработанный)", "gem_raw", [c], price // 2, 0.3, "gem", props=GEM_PROPS[mid], stack=5)
    add("gem_" + mid, nm, "gem_cut", [c], price, 0.1, "gem", props=GEM_PROPS[mid], stack=5)

# ======================================================================== ВОЛОКНА И ТКАНИ
add("plant_fiber", "Растительное волокно", "fiber", ["a8a060"], 1, 0.05, "fiber", stack=30)
add("flax", "Лён", "fiber", ["c8b880", "6a8ad0"], 2, 0.1, "fiber", stack=20)
add("hemp", "Конопля (волокно)", "fiber", ["8a9a50"], 2, 0.1, "fiber", stack=20)
add("cotton", "Хлопок", "cotton", ["f8f8f4"], 3, 0.05, "fiber", stack=20)
add("nettle_fiber", "Крапивное волокно", "fiber", ["6a8a4a"], 2, 0.05, "fiber", props={"Жгучесть": 1}, stack=20)
add("reed", "Тростник", "reed", ["c8b060"], 1, 0.1, "fiber", stack=20)
add("straw", "Солома", "fiber", ["e8d070"], 1, 0.05, "fiber", stack=30)
add("silk_cocoon", "Шёлковый кокон", "cocoon", ["f4f0e0"], 6, 0.05, "fiber", props={"Покой": 1, "Сон": 1}, stack=10)
add("spider_silk", "Паучий шёлк", "web", ["e8e8f4"], 5, 0.02, "fiber", props={"Тьма": 1, "Сила": 1}, stack=20)
THREADS = [("thread_linen", "Льняная нить", "e0d8b8"), ("thread_hemp", "Пеньковая нить", "a8a070"), ("thread_cotton", "Хлопковая нить", "f8f8f4"),
           ("thread_silk", "Шёлковая нить", "f8f0d8"), ("thread_spider", "Нить паучьего шёлка", "d8d8f0"), ("thread_nettle", "Крапивная нить", "8aa060")]
for mid, nm, c in THREADS:
    add(mid, nm, "spool", [c], 4 if "silk" not in mid and "spider" not in mid else 10, 0.1, "cloth", stack=10)
CLOTHS = [("linen", "Льняное полотно", "e0d8b8"), ("canvas", "Парусина", "c8b890"), ("cotton_cloth", "Хлопковая ткань", "f4f4f0"),
          ("silk_cloth", "Шёлк", "f8ecd0"), ("spider_cloth", "Паутинная ткань", "d8d8f0"), ("nettle_cloth", "Крапивное полотно", "9aa870"),
          ("wool_cloth", "Шерстяная ткань", "c8b8a0"), ("felt", "Войлок", "a89880")]
for mid, nm, c in CLOTHS:
    add(mid, nm, "cloth", [c], 12 if mid not in ("silk_cloth", "spider_cloth") else 30, 0.6, "cloth", size=(2, 1), stack=5)
add("twine", "Бечёвка", "rope", ["b8a070"], 2, 0.1, "cloth", stack=10)
add("rope", "Верёвка", "rope", ["a08858"], 5, 0.5, "cloth", stack=5)
add("net_mesh", "Сеть", "net", ["b8a070"], 9, 0.6, "cloth", stack=5)
add("straw_mat", "Соломенный мат", "cloth", ["e0c868"], 4, 0.6, "cloth", size=(2, 1), stack=5)
add("basket", "Плетёная корзинка", "basket", ["b08a50"], 6, 0.5, "cloth", stack=3)

# ======================================================================== ЗВЕРИ (без вреда: вычёсывают, подбирают сброшенное)
FUR = [
    ("rabbit_fluff", "Кроличий пух", "fluff", "e8e0d4", {"Покой": 1, "Сон": 1}, 3), ("fox_tuft", "Лисья шерсть", "tuft", "e0782a", {"Огонь": 1, "Чары": 1}, 6),
    ("deer_fur", "Оленья шерсть", "tuft", "a87a50", {"Сила": 1, "Исцеление": 1}, 5), ("antler_shed", "Сброшенный рог оленя", "antler", "d8c8a8", {"Сила": 2}, 14),
    ("boar_bristle", "Кабанья щетина", "bristle", "5a4a3a", {"Сила": 1, "Жгучесть": 1}, 4), ("hedgehog_quill", "Иголки ежа", "quill", "8a7a6a", {"Жгучесть": 2}, 5),
    ("squirrel_fluff", "Беличий пух", "fluff", "c0603a", {"Свежесть": 1, "Тепло": 1}, 5), ("duck_down", "Утиный пух", "fluff", "d8d0b8", {"Покой": 1, "Тепло": 1}, 4),
    ("sapphire_fluff", "Сапфировый пух", "fluff", "5a8ae8", {"Холод": 1, "Чары": 2}, 30), ("unicorn_hair", "Волос из гривы единорога", "hair", "f8d8f0", {"Свет": 2, "Исцеление": 1}, 40),
    ("horn_shaving", "Стружка рога единорога", "pile", "f0e8ff", {"Свет": 2, "Чары": 2}, 60), ("golden_fur", "Золотая шерсть", "tuft", "f0c040", {"Свет": 1, "Тепло": 1}, 30),
    ("golden_antler", "Золотой рог (сброшенный)", "antler", "f0c840", {"Свет": 2, "Сила": 1}, 70), ("ember_tuft", "Угольная шерсть", "tuft", "e8502a", {"Огонь": 2}, 30),
    ("cat_whisker", "Кошачий ус", "whisker", "f4f4f0", {"Чары": 1, "Свет": 1}, 8), ("cat_fur", "Кошачья шерсть", "fluff", "c8a080", {"Покой": 2}, 3),
    ("fish_scale", "Рыбья чешуя", "scale", "b8d0d8", {"Холод": 1, "Свежесть": 1}, 2), ("goose_down", "Гусиный пух", "fluff", "f0ece4", {"Покой": 1, "Сон": 1}, 5),
    ("bat_fluff", "Мех летучей мыши", "fluff", "4a3a48", {"Тьма": 1, "Сон": 1}, 6),
]
for mid, nm, tpl, c, pr, price in FUR:
    add(mid, nm, tpl, [c], price, 0.05, "animal", props=pr, stack=20)
YARNS = [("yarn_rabbit", "Пуховая пряжа", "e8e0d4"), ("yarn_fox", "Рыжая пряжа", "e0782a"), ("yarn_deer", "Оленья пряжа", "a87a50"),
         ("yarn_cat", "Кошачья пряжа", "c8a080"), ("yarn_sapphire", "Сапфировая пряжа", "5a8ae8"), ("yarn_unicorn", "Единорожья пряжа", "f8d8f0"),
         ("yarn_golden", "Золотая пряжа", "f0c040"), ("yarn_ember", "Тлеющая пряжа", "e8502a"), ("yarn_down", "Пряжа из пуха", "f0ece4")]
for mid, nm, c in YARNS:
    add(mid, nm, "yarn", [c], 8 if mid not in ("yarn_sapphire", "yarn_unicorn", "yarn_golden", "yarn_ember") else 45, 0.2, "cloth", stack=10)
# пасека и море
add("honeycomb", "Соты", "comb", ["f0b030"], 6, 0.3, "animal", props={"Тепло": 1, "Исцеление": 1}, stack=10)
add("royal_jelly", "Маточное молочко", "jar", ["f8f0c8"], 30, 0.2, "animal", props={"Исцеление": 2, "Сила": 1}, stack=5)
add("propolis", "Прополис", "lump", ["8a5a2a"], 10, 0.1, "animal", props={"Исцеление": 1, "Жгучесть": 1}, stack=10)
add("shell", "Ракушка", "shell", ["f0d8c8"], 2, 0.1, "sea", props={"Холод": 1}, stack=20)
add("conch", "Рапана", "conch", ["f0b8a0"], 9, 0.4, "sea", props={"Холод": 1, "Покой": 1}, stack=5)
add("sea_glass", "Морское стёклышко", "gem_cut", ["8ad0c0"], 6, 0.05, "sea", props={"Свежесть": 1}, stack=20)
add("coral_piece", "Веточка коралла", "coral", ["f07a7a"], 8, 0.2, "sea", props={"Исцеление": 1, "Холод": 1}, stack=10)
add("pearl", "Жемчужина", "pearl", ["f4f0ec"], 25, 0.02, "sea", props={"Свет": 1, "Покой": 1}, stack=10)
add("starfish", "Морская звезда (сухая)", "star", ["f0904a"], 7, 0.1, "sea", props={"Исцеление": 1}, stack=10)
add("sea_salt", "Морская соль", "crystals", ["e8f4f8"], 4, 0.3, "sea", props={"Холод": 1, "Свежесть": 1}, stack=20)
add("kelp_dried", "Сушёная ламинария", "fiber", ["5a7a4a"], 3, 0.1, "sea", props={"Свежесть": 1, "Исцеление": 1}, stack=20)

# ======================================================================== КРАСКИ, БУМАГА, СВЕЧИ
DYES = [("red", "Красная", "d8302a", "poppy"), ("orange", "Оранжевая", "f0802a", "calendula"), ("yellow", "Жёлтая", "f0d030", "dandelion"),
        ("green", "Зелёная", "4aa040", "nettle"), ("cyan", "Бирюзовая", "40c8c8", "glowmoss"), ("blue", "Синяя", "3a5ad8", "cornflower"),
        ("purple", "Фиолетовая", "8a4ac8", "lavender"), ("pink", "Розовая", "f08ab0", "pink_clover"), ("brown", "Коричневая", "7a4a2a", "bark_tree_a"),
        ("black", "Чёрная", "2a2a30", "charcoal"), ("white", "Белая", "f4f4f0", "chalk"), ("gold", "Золотая", "f0c030", "sunflower_gold")]
for c_id, adj, c, src in DYES:
    add("dye_" + c_id, adj + " краска", "dye", [c], 6 if c_id != "gold" else 30, 0.3, "dye", stack=10)
    add("cloth_" + c_id, adj.replace("ая", "ая") + " ткань", "cloth", [c], 16 if c_id != "gold" else 50, 0.6, "dye", size=(2, 1), stack=5)
for c_id in ("red", "yellow", "green", "blue", "purple", "pink"):
    adj = [d[1] for d in DYES if d[0] == c_id][0]
    add("glass_" + c_id, adj.replace("ая", "ое") + " стекло", "pane", [[d[2] for d in DYES if d[0] == c_id][0]], 12, 0.6, "glass", stack=10)
add("ink", "Чернила", "ink", ["1e1a2a"], 6, 0.3, "paper", props={"Тьма": 1}, stack=5)
add("paper", "Бумага", "paper", ["f4ecd8"], 3, 0.05, "paper", stack=30)
add("book_blank", "Чистая книга", "book", ["7a4a2a"], 25, 0.8, "paper", stack=3)
add("candle", "Свеча", "candle", ["f4ecc8"], 4, 0.2, "paper", props={"Свет": 1}, stack=10)
add("candle_scented", "Душистая свеча", "candle", ["c8a8e8"], 10, 0.2, "paper", props={"Свет": 1, "Покой": 1}, stack=10)
add("soap", "Мыло", "soap", ["f0e0c0"], 5, 0.2, "paper", props={"Свежесть": 1}, stack=10)
add("plant_oil", "Растительное масло", "flask", ["e0c040"], 5, 0.5, "paper", props={"Тепло": 1}, stack=5)
add("lamp_oil", "Лампадное масло", "flask", ["d89a30"], 7, 0.5, "paper", props={"Огонь": 1}, stack=5)
add("varnish", "Лак", "pot", ["a8602a", "d89a50"], 9, 0.5, "paper", stack=5)
add("glue", "Клей", "pot", ["d8c8a0", "f4ecd0"], 5, 0.4, "paper", stack=5)
add("flour", "Мука", "sack", ["f4f0e4", "c8b890"], 3, 1.0, "paper", stack=10)
add("grain", "Зерно", "grains", ["e0c060"], 1, 0.1, "paper", stack=30)
add("seed_mix", "Семена для птиц", "grains", ["c8a060"], 2, 0.1, "paper", stack=30)

# ======================================================================== ВОЛШЕБНОЕ
add("mana_dust", "Мана-пыль", "dust", ["8a7aff"], 20, 0.02, "magic", props={"Чары": 2}, stack=20)
add("star_dust", "Звёздная пыль", "dust", ["f0f0ff"], 40, 0.02, "magic", props={"Свет": 2, "Чары": 1}, stack=20)
add("moon_essence", "Лунная эссенция", "essence", ["b8c8ff"], 45, 0.2, "magic", props={"Сон": 2, "Свет": 1}, stack=5)
add("fairy_dust", "Пыльца фей", "dust", ["ffb8f0"], 35, 0.02, "magic", props={"Чары": 2, "Свежесть": 1}, stack=20)
add("void_dust", "Пыль бездны", "dust", ["6a4a9a"], 40, 0.02, "magic", props={"Тьма": 2, "Чары": 1}, stack=20)
add("ember_dust", "Тлеющая пыль", "dust", ["ff7a3a"], 30, 0.02, "magic", props={"Огонь": 2}, stack=20)
add("frost_dust", "Иней в склянке", "dust", ["a8e8ff"], 30, 0.02, "magic", props={"Холод": 2}, stack=20)
add("rune_blank", "Чистая руна", "rune", ["8a8e9a"], 15, 0.6, "magic", stack=5)
add("rune_lit", "Светящаяся руна", "rune", ["8ab8ff"], 60, 0.6, "magic", props={"Чары": 2, "Свет": 1}, stack=5)
add("crystal_shard", "Осколок кристалла", "gem_raw", ["b89aff"], 12, 0.1, "magic", props={"Чары": 1}, stack=20)

# ======================================================================== ПЕРЬЯ (из birds_design)
for bid in BD.ORDER:
    e = BD.B[bid]
    add("feather_" + bid, "Перо: " + e[0].lower(), "feather", [], int(e[10]), 0.01, "feather", props=e[9], stack=20, icon="icon_feather_" + bid)

# ======================================================================== МАСТЕРСКИЕ И РЕЦЕПТЫ
# рецепт: [что выходит, сколько, {что нужно: сколько}]; "@plank" — любая доска, "@wood" — любая чурка, "@yarn" — любая пряжа,
# "@fur" — любой пух/шерсть, "@dye" — любая краска
R = {}
R["sawmill"] = [["plank_" + s, 2, {"wood_" + s: 1}] for s in WOODS] + [
    ["stick", 4, {"log": 1}], ["plank_tree_a", 2, {"log": 1}], ["beam", 1, {"@plank": 3}], ["shingle", 4, {"@plank": 1}],
    ["stave", 3, {"@plank": 1}], ["wood_gear", 1, {"@plank": 1, "stick": 1}], ["sawdust", 4, {"@wood": 1}], ["twig", 3, {"stick": 1}],
    ["plank_dead", 2, {"driftwood": 1}]]
R["kiln"] = [["brick", 2, {"clay": 2}], ["red_brick", 2, {"red_clay": 2}], ["roof_tile", 3, {"clay": 2}], ["porcelain", 2, {"white_clay": 2}],
             ["pot_clay", 1, {"clay": 3}], ["glass", 1, {"sand": 2}], ["glass_clear", 1, {"quartz_sand": 2}], ["glass_smoky", 1, {"black_sand": 2}],
             ["bottle_glass", 2, {"glass": 1}], ["lime", 2, {"limestone": 1}], ["lime", 1, {"chalk": 1}], ["charcoal", 3, {"log": 1}],
             ["charcoal", 2, {"@wood": 1}], ["wood_ash", 2, {"twig": 2}], ["coal", 1, {"peat": 3}], ["sea_salt", 2, {"water_cold": 1, "salt": 1}]]
R["smelter"] = [["bar_" + m if m != "iron" else "iron_bar", 1, {"ore_" + m: 2, "charcoal": 1}] for m in ORE_IDS] + \
               [["bar_" + m if m != "iron" else "iron_bar", 1, {"nugget_" + m: 5}] for m in ORE_IDS] + \
               [["bar_" + a[0], a[4], dict([(("bar_" + i[0]) if i[0] not in ("iron", "coal", "star") else {"iron": "iron_bar", "coal": "coal", "star": "ore_star"}[i[0]], i[1]) for i in a[3]])] for a in ALLOYS] + \
               [["bar_" + m[0], 1, {"ore_" + m[0]: 2, "coal": 1}] for m in MAGIC] + \
               [["glass", 2, {"sand": 3, "coal": 1}]]
R["anvil"] = [["nail", 8, {"iron_bar": 1}], ["hinge", 2, {"iron_bar": 1}], ["chain", 1, {"iron_bar": 2}], ["wire_copper", 3, {"bar_copper": 1}],
              ["wire_silver", 2, {"bar_silver": 1}], ["wire_gold", 2, {"bar_gold": 1}], ["sheet_copper", 1, {"bar_copper": 1}],
              ["sheet_tin", 1, {"bar_tin": 1}], ["sheet_iron", 1, {"iron_bar": 1}], ["gear_bronze", 2, {"bar_bronze": 1}],
              ["spring", 2, {"bar_steel": 1}], ["needle", 6, {"bar_steel": 1}], ["bell", 1, {"bar_bronze": 2}], ["bell", 1, {"bar_brass": 2}],
              ["lantern_frame", 1, {"iron_bar": 1, "sheet_tin": 1}], ["iron_pot", 1, {"iron_bar": 2}], ["horseshoe", 2, {"iron_bar": 1}]]
R["spinning"] = [["twine", 1, {"plant_fiber": 3}], ["thread_linen", 2, {"flax": 2}], ["thread_hemp", 2, {"hemp": 2}], ["thread_cotton", 2, {"cotton": 2}],
                 ["thread_silk", 2, {"silk_cocoon": 1}], ["thread_spider", 1, {"spider_silk": 3}], ["nettle_fiber", 2, {"nettle": 2}],
                 ["thread_nettle", 1, {"nettle_fiber": 2}], ["yarn_rabbit", 1, {"rabbit_fluff": 3}], ["yarn_fox", 1, {"fox_tuft": 3}],
                 ["yarn_deer", 1, {"deer_fur": 3}], ["yarn_cat", 1, {"cat_fur": 3}], ["yarn_sapphire", 1, {"sapphire_fluff": 3}],
                 ["yarn_unicorn", 1, {"unicorn_hair": 3}], ["yarn_golden", 1, {"golden_fur": 3}], ["yarn_ember", 1, {"ember_tuft": 3}],
                 ["yarn_down", 1, {"duck_down": 2, "goose_down": 1}], ["yarn_rabbit", 1, {"squirrel_fluff": 3}]]
R["loom"] = [["linen", 1, {"thread_linen": 3}], ["canvas", 1, {"thread_hemp": 3}], ["cotton_cloth", 1, {"thread_cotton": 3}],
             ["silk_cloth", 1, {"thread_silk": 3}], ["spider_cloth", 1, {"thread_spider": 3}], ["nettle_cloth", 1, {"thread_nettle": 3}],
             ["wool_cloth", 1, {"@yarn": 3}], ["felt", 1, {"@fur": 4}], ["rope", 1, {"twine": 3}], ["net_mesh", 1, {"rope": 2}],
             ["straw_mat", 1, {"straw": 6}], ["basket", 1, {"wicker": 5}], ["basket", 1, {"reed": 6}]]
R["dye_vat"] = [["dye_" + c[0], 2, {c[3]: 2 if c[3] not in ("charcoal", "chalk", "sunflower_gold") else 1, "water_cold": 1}] for c in DYES] + \
               [["cloth_" + c[0], 1, {"cotton_cloth": 1, "dye_" + c[0]: 1}] for c in DYES] + \
               [["glass_" + c, 1, {"glass": 1, "dye_" + c: 1}] for c in ("red", "yellow", "green", "blue", "purple", "pink")]
R["mason"] = [["stone_block", 1, {"stone_m": 2}], ["stone_block", 3, {"stone_l": 1}], ["marble_block", 1, {"marble": 2}], ["granite_block", 1, {"granite": 2}],
              ["sandstone_block", 1, {"sandstone": 2}], ["basalt_block", 1, {"basalt": 2}], ["slate_tile", 3, {"slate": 1}], ["gravel", 2, {"stone_s": 3}],
              ["cobble", 2, {"stone_m": 1}], ["mortar", 2, {"sand": 1, "lime": 1, "water_cold": 1}], ["rune_blank", 1, {"stone_block": 1}],
              ["sand", 2, {"sandstone": 1}], ["crystal_shard", 2, {"crystal_cluster_piece": 1}]]
R["jeweler"] = [["gem_" + g[0], 1, {"gem_raw_" + g[0]: 1}] for g in GEMS] + [
    ["mana_dust", 2, {"ore_mana": 1}], ["star_dust", 2, {"ore_star": 1}], ["void_dust", 2, {"ore_void": 1}], ["ember_dust", 2, {"ore_ember": 1}],
    ["frost_dust", 2, {"ore_frost": 1}], ["fairy_dust", 1, {"crystal_shard": 1, "pink_clover": 2}], ["moon_essence", 1, {"moon_dew": 1, "ore_moonsilver": 1}],
    ["rune_lit", 1, {"rune_blank": 1, "mana_dust": 2}], ["gem_raw_amber", 1, {"resin": 5}], ["pearl", 1, {"conch": 2}]]
R["press"] = [["plant_oil", 1, {"food_hazelnut": 3}], ["plant_oil", 1, {"food_walnut": 2}], ["plant_oil", 1, {"food_pine_nut": 3}],
              ["plant_oil", 1, {"food_acorn": 5}], ["paper", 3, {"sawdust": 3, "water_cold": 1}], ["paper", 2, {"reed": 3, "water_cold": 1}],
              ["book_blank", 1, {"paper": 8, "thread_linen": 1}], ["candle", 2, {"wax": 1, "twine": 1}], ["candle_scented", 1, {"candle": 1, "lavender": 1}],
              ["soap", 2, {"wood_ash": 2, "plant_oil": 1}], ["varnish", 1, {"plant_oil": 1, "resin": 1}], ["glue", 1, {"resin": 2}],
              ["wood_glue", 1, {"sawdust": 2, "glue": 1}], ["lamp_oil", 1, {"plant_oil": 2}], ["ink", 2, {"charcoal": 1, "bottle": 1}],
              ["honey", 1, {"honeycomb": 2}], ["wax", 1, {"honeycomb": 1}], ["flour", 1, {"grain": 6}], ["seed_mix", 4, {"grain": 3}],
              ["tar", 1, {"@wood": 2}], ["kelp_dried", 2, {"kelp_dried": 1}]]
# лишний рецепт-заглушка убран
R["press"] = [r for r in R["press"] if r[0] != "kelp_dried"]
R["mason"] = [r for r in R["mason"] if "crystal_cluster_piece" not in r[2]]

STATIONS = {
    "sawmill": ["Пилорама", "chop"], "kiln": ["Печь для обжига", "fire"], "smelter": ["Плавильня", "fire"], "anvil": ["Наковальня", "anvil"],
    "spinning": ["Прялка", "loom"], "loom": ["Ткацкий станок", "loom"], "dye_vat": ["Красильный чан", "bubble"], "mason": ["Каменотёсный стол", "pick"],
    "jeweler": ["Стол ювелира", "tinker"], "press": ["Пресс и котелок", "pour"],
}

# ======================================================================== ЛОВУШКИ
# kind: [имя, кого ловит, приманка ("food" — любая еда, "seed" — зерно/семена, "magic" — волшебное), часы до поимки (в среднем)]
TRAPS = {
    "trap_small": ["Клетка для зверьков", ["rabbit", "squirrel", "hedgehog"], "food", 5.0],
    "trap_cage": ["Большая клетка", ["fox", "flat_boar", "duck"], "food", 7.0],
    "trap_pen": ["Ловчий загон", ["deer", "boar"], "food", 10.0],
    "trap_bird": ["Птичья корзинка", ["*bird"], "seed", 3.0],
    "trap_fish": ["Верша", ["*fish"], "food", 4.0],
    "trap_magic": ["Волшебная ловушка", ["sapphire_hare", "unicorn", "golden_deer", "ember_fox"], "magic", 14.0],
    "trap_bat": ["Сетка для летучих мышей", ["*bat"], "food", 6.0],
}
BAIT_MAGIC = ["moon_dew", "food_pink_apple", "food_apple_golden", "mana_dust", "star_dust", "fairy_dust"]
BAIT_SEED = ["seed_mix", "grain", "food_pine_nut", "food_hazelnut", "food_acorn"]
# что даёт пойманный зверь (его вычёсывают / подбирают сброшенное и отпускают)
LOOT = {
    "rabbit": [["rabbit_fluff", 2, 3, 1.0]], "squirrel": [["squirrel_fluff", 1, 2, 1.0]], "hedgehog": [["hedgehog_quill", 2, 4, 1.0]],
    "fox": [["fox_tuft", 1, 3, 1.0]], "flat_boar": [["boar_bristle", 3, 4, 1.0]], "duck": [["duck_down", 2, 3, 1.0]],
    "deer": [["deer_fur", 1, 3, 1.0], ["antler_shed", 1, 1, 0.3]], "boar": [["boar_bristle", 2, 3, 1.0]],
    "sapphire_hare": [["sapphire_fluff", 1, 2, 1.0]], "unicorn": [["unicorn_hair", 1, 2, 1.0], ["horn_shaving", 1, 1, 0.3]],
    "golden_deer": [["golden_fur", 1, 2, 1.0], ["golden_antler", 1, 1, 0.35]], "ember_fox": [["ember_tuft", 1, 2, 1.0]],
    "*fish": [["fish_scale", 2, 4, 1.0]], "*bat": [["bat_fluff", 1, 2, 1.0]],
}

# ======================================================================== МЕСТА ДОБЫЧИ В МИРЕ
# kind: [имя, картинка, {биом: сколько на регион}, [[предмет, от, до, шанс], ...], дней до нового, звук]
NODES = {
    "clay": ["Глиняный берег", "node_clay", {SWAMP: 5, MEADOW: 1, FIELD: 1, HOME: 1}, [["clay", 2, 3, 1.0]], 2, "dig"],
    "red_clay": ["Красная глина", "node_red_clay", {ORC: 4, AUTUMN: 2, DWARF: 2}, [["red_clay", 2, 3, 1.0]], 2, "dig"],
    "white_clay": ["Каолин", "node_white_clay", {GROTTO: 3, MAGE: 2, JAPAN: 2}, [["white_clay", 1, 3, 1.0]], 3, "dig"],
    "sand": ["Песок", "node_sand", {BEACH: 7, FIELD: 1, ORC: 1}, [["sand", 2, 4, 1.0], ["shell", 1, 1, 0.2]], 1, "dig"],
    "black_sand": ["Чёрный песок", "node_black_sand", {BEACH: 2, GROTTO: 2, DWARF: 1}, [["black_sand", 2, 3, 1.0]], 2, "dig"],
    "quartz_sand": ["Кварцевый песок", "node_quartz_sand", {BEACH: 1, GROTTO: 2, MAGE: 1, UNICORN: 1}, [["quartz_sand", 1, 3, 1.0]], 3, "dig"],
    "gravel": ["Осыпь", "node_gravel", {GROTTO: 3, PINE: 2, DWARF: 3, ORC: 1}, [["gravel", 2, 3, 1.0], ["flint", 1, 1, 0.35], ["nugget_copper", 1, 1, 0.12], ["nugget_tin", 1, 1, 0.1]], 2, "dig"],
    "flint": ["Кремни в траве", "node_flint", {MEADOW: 2, FIELD: 2, BIRCH: 1, PINE: 1, HOME: 1}, [["flint", 1, 2, 1.0]], 3, "pick"],
    "peat": ["Торфяник", "node_peat", {SWAMP: 4}, [["peat", 2, 3, 1.0]], 3, "dig"],
    "salt": ["Соляная корка", "node_salt", {BEACH: 3}, [["salt", 1, 3, 1.0]], 2, "pick"],
    "sulfur": ["Серный выход", "node_sulfur", {GROTTO: 2, DWARF: 2, ORC: 1}, [["sulfur", 1, 3, 1.0]], 3, "pick"],
    "saltpeter": ["Селитра на камне", "node_saltpeter", {GROTTO: 1, DWARF: 1, GOTHIC: 1}, [["saltpeter", 1, 2, 1.0]], 4, "pick"],
    "coal": ["Угольный пласт", "node_coal", {DWARF: 3, GROTTO: 2, PINE: 1, ORC: 1}, [["coal", 2, 3, 1.0]], 3, "pick"],
    "obsidian": ["Обсидиановые осколки", "node_obsidian", {DWARF: 2, ORC: 1, GROTTO: 1}, [["obsidian", 1, 2, 1.0]], 5, "pick"],
    "stones": ["Каменная россыпь", "node_stones", {MEADOW: 1, PINE: 2, BIRCH: 1, AUTUMN: 1, GOTHIC: 1, KNIGHT: 1, MAGE: 1},
               [["limestone", 1, 1, 0.4], ["granite", 1, 1, 0.3], ["slate", 1, 1, 0.25], ["chalk", 1, 1, 0.2], ["marble", 1, 1, 0.08]], 3, "pick"],
    "flax": ["Лён", "node_flax", {FIELD: 5, MEADOW: 2, HOME: 1}, [["flax", 2, 4, 1.0]], 3, "scythe"],
    "cotton": ["Хлопчатник", "node_cotton", {FIELD: 3, JAPAN: 2, ORC: 1, CATS: 1}, [["cotton", 2, 3, 1.0]], 3, "scythe"],
    "hemp": ["Дикая конопля", "node_hemp", {MEADOW: 3, ORC: 2, FIELD: 2, KNIGHT: 1}, [["hemp", 2, 3, 1.0]], 3, "scythe"],
    "fiber": ["Сухая осока", "node_fiber", {MEADOW: 4, FIELD: 3, BIRCH: 3, PINE: 2, AUTUMN: 3, SWAMP: 2, HOME: 3, ELF: 2, UNICORN: 2},
              [["plant_fiber", 2, 4, 1.0], ["twig", 1, 2, 0.4]], 1, "scythe"],
    "reeds": ["Тростник", "reeds", {SWAMP: 6, BEACH: 1}, [["reed", 2, 4, 1.0], ["wicker", 1, 2, 0.4]], 2, "scythe"],
    "straw": ["Дикая пшеница", "wheat_patch", {FIELD: 4, KNIGHT: 1}, [["straw", 3, 5, 1.0], ["grain", 2, 4, 1.0]], 3, "scythe"],
    "cocoon": ["Шелкопряды", "node_cocoon", {SPIDER: 3, ELF: 1, JAPAN: 2}, [["silk_cocoon", 1, 2, 1.0]], 3, "pickup"],
    "web": ["Паутина", "web_ground", {SPIDER: 5, GOTHIC: 1}, [["spider_silk", 2, 3, 1.0]], 1, "pickup"],
    "shells": ["Ракушки", "beach_shells", {BEACH: 5}, [["shell", 1, 3, 1.0], ["conch", 1, 1, 0.15], ["sea_glass", 1, 1, 0.25], ["starfish", 1, 1, 0.15], ["pearl", 1, 1, 0.03]], 1, "pickup"],
    "driftwood": ["Плавник", "driftwood", {BEACH: 3, SWAMP: 1}, [["driftwood", 1, 2, 1.0], ["kelp_dried", 1, 2, 0.4]], 3, "pickup"],
    "hive": ["Дикий улей", "node_hive", {BIRCH: 2, MEADOW: 1, FIELD: 2, ELF: 1, HOME: 1, UNICORN: 1}, [["honeycomb", 1, 2, 1.0], ["propolis", 1, 1, 0.3], ["royal_jelly", 1, 1, 0.05]], 3, "pickup"],
    "crystals": ["Кристаллы", "crystal_cluster", {MAGE: 2, GROTTO: 2, UNICORN: 1}, [["crystal_shard", 1, 2, 1.0], ["gem_raw_amethyst", 1, 1, 0.2], ["gem_raw_moonstone", 1, 1, 0.08]], 4, "pick"],
    "amber": ["Смоляной натёк", "node_amber", {PINE: 2, BEACH: 1}, [["resin", 2, 3, 1.0], ["gem_raw_amber", 1, 1, 0.25]], 3, "pickup"],
}

# камни (rocks.gd): что ещё выпадает при раскалывании, по биому — [предмет, шанс]
ROCK_EXTRA = {}
for g in GEMS:
    for b, wgt in g[3].items():
        ROCK_EXTRA.setdefault(b, []).append(["gem_raw_" + g[0], 0.025 * wgt])
for st, bl in [("granite", [PINE, KNIGHT, DWARF]), ("marble", [MAGE, ELF, KNIGHT]), ("basalt", [ORC, DWARF]), ("limestone", [MEADOW, FIELD, CATS, HOME]),
               ("slate", [GOTHIC, SPIDER, PINE]), ("sandstone", [BEACH, FIELD, ORC]), ("chalk", [MEADOW, BIRCH, HOME]), ("pumice", [GROTTO, DWARF]),
               ("flint", [MEADOW, FIELD, AUTUMN, BIRCH])]:
    for b in bl:
        ROCK_EXTRA.setdefault(b, []).append([st, 0.3])
for m in METALS:
    for b, wgt in m[5].items():
        ROCK_EXTRA.setdefault(b, []).append(["nugget_" + m[0], 0.05 * wgt])
# руды новых металлов — как месторождения в rocks.gd (mining_db.ORES)
ORE_DEPOSITS = {m[0]: m[5] for m in METALS}

# рубка: кроме брёвен — чурка породы, кора и смола у хвойных
CHOP_EXTRA = {s: [["wood_" + s, 1, 2, 1.0], ["bark_" + s, 1, 2, 0.6], ["twig", 1, 2, 0.5]] for s in WOODS}
CHOP_EXTRA["pine_a"].append(["resin", 1, 2, 0.6])
CHOP_EXTRA["pine_b"].append(["resin", 1, 2, 0.5])
CHOP_EXTRA["dead_tree_a"] = CHOP_EXTRA.pop("dead")
CHOP_EXTRA["dead_tree_b"] = CHOP_EXTRA["dead_tree_a"]

# ======================================================================== ПОСТРОЙКИ
# kind: [имя, картинка, вес набора, преграда [x,y,w,h], вкладка, {материалы}]
# вкладки: home — хозяйство, work — мастерские, trap — ловушки, bird — для птиц, deco — украшения, wall — ограды и дорожки
BUILD = {
    # старые постройки — теперь за материалы, без монет
    "workbench": ["Верстак", "workbench", 8.0, [-32, -18, 64, 16], "home", {"log": 6}],
    "table": ["Стол", "dp_table_round", 5.0, [-16, -16, 32, 14], "home", {"log": 4}],
    "research": ["Стол изучения трав", "research_table", 7.0, [-30, -18, 60, 16], "home", {"log": 6, "plant_fiber": 6}],
    "pen": ["Загон для зверей", "animal_pen", 10.0, [0, 0, 0, 0], "home", {"log": 10, "twine": 2}],
    "chest": ["Сундук", "dp_chest_small", 5.0, [-14, -12, 28, 12], "home", {"log": 5}],
    "plot": ["Грядка", "", 2.0, [0, 0, 0, 0], "home", {"log": 2}],
    "cauldron": ["Котёл для зелий", "cauldron", 8.0, [-20, -14, 40, 14], "home", {"log": 4, "stone_m": 6, "clay": 2}],
    "outhouse": ["Туалет", "outhouse", 9.0, [-22, -12, 44, 12], "home", {"log": 6}],
    "well": ["Колодец", "well", 10.0, [-30, -28, 60, 28], "home", {"log": 8, "stone_m": 10}],
    "lantern": ["Фонарь", "lantern", 2.0, [-5, -6, 10, 6], "home", {"log": 2, "resin": 1}],
    "fence": ["Забор", "fence", 1.0, [-16, -6, 32, 6], "wall", {"log": 1}],
    "bench": ["Скамейка", "bench", 4.0, [-30, -14, 60, 12], "deco", {"log": 3}],
    "campfire": ["Костёр", "campfire", 3.0, [-12, -8, 24, 8], "home", {"log": 3, "stone_s": 4}],
    "dryer": ["Сушилка для трав", "dryer", 6.0, [-30, -10, 60, 10], "home", {"log": 5, "twine": 2}],
    "stall": ["Лавка зелий", "stall_purple", 8.0, [-44, -14, 88, 14], "home", {"log": 6, "@plank": 4, "linen": 1}],
    "forge": ["Кузница", "forge", 12.0, [-42, -18, 84, 18], "home", {"log": 8, "stone_block": 6, "brick": 6}],
    # мастерские
    "sawmill": ["Пилорама", "st20_sawmill", 10.0, [-34, -16, 68, 16], "work", {"log": 8, "stone_m": 2, "flint": 2}],
    "kiln": ["Печь для обжига", "st20_kiln", 12.0, [-26, -18, 52, 18], "work", {"stone_m": 10, "clay": 8}],
    "smelter": ["Плавильня", "st20_smelter", 14.0, [-28, -20, 56, 20], "work", {"brick": 10, "stone_block": 4, "clay": 4}],
    "anvil": ["Наковальня", "st20_anvil", 10.0, [-18, -10, 36, 10], "work", {"iron_bar": 4, "log": 2}],
    "spinning": ["Прялка", "st20_spinning", 5.0, [-18, -10, 36, 10], "work", {"@plank": 4, "stick": 4, "twine": 1}],
    "loom": ["Ткацкий станок", "loom", 8.0, [-30, -14, 60, 14], "work", {"@plank": 8, "stick": 6, "twine": 4}],
    "dye_vat": ["Красильный чан", "st20_dye_vat", 8.0, [-22, -12, 44, 12], "work", {"stave": 8, "iron_bar": 1, "stone_s": 4}],
    "mason": ["Каменотёсный стол", "st20_mason", 10.0, [-30, -14, 60, 14], "work", {"stone_l": 1, "@plank": 4, "flint": 3}],
    "jeweler": ["Стол ювелира", "st20_jeweler", 6.0, [-26, -14, 52, 14], "work", {"@plank": 6, "glass": 2, "bar_copper": 2}],
    "press": ["Пресс и котелок", "st20_press", 8.0, [-24, -14, 48, 14], "work", {"beam": 2, "@plank": 4, "pot_clay": 1}],
    # ловушки (ставятся где угодно, кроме городов)
    "trap_small": ["Клетка для зверьков", "trap20_small", 2.0, [-10, -6, 20, 6], "trap", {"stick": 6, "twine": 2}],
    "trap_cage": ["Большая клетка", "trap20_cage", 5.0, [-16, -8, 32, 8], "trap", {"@plank": 3, "stick": 8, "rope": 1}],
    "trap_pen": ["Ловчий загон", "trap20_pen", 10.0, [-30, -10, 60, 10], "trap", {"log": 6, "rope": 2, "hinge": 1}],
    "trap_bird": ["Птичья корзинка", "trap20_bird", 1.0, [-8, -4, 16, 4], "trap", {"wicker": 4, "twine": 1}],
    "trap_fish": ["Верша", "trap20_fish", 2.0, [0, 0, 0, 0], "trap", {"wicker": 6, "twine": 2}],
    "trap_magic": ["Волшебная ловушка", "trap20_magic", 4.0, [-14, -8, 28, 8], "trap", {"wire_silver": 2, "gem_moonstone": 1, "@plank": 2}],
    "trap_bat": ["Сетка для летучих мышей", "trap20_bat", 2.0, [-12, -6, 24, 6], "trap", {"net_mesh": 1, "stick": 4}],
    # для птиц
    "bird_feeder": ["Кормушка", "b20_feeder", 2.0, [-6, -4, 12, 4], "bird", {"@plank": 2, "stick": 2}],
    "birdhouse": ["Скворечник", "b20_birdhouse", 2.0, [-5, -4, 10, 4], "bird", {"@plank": 3, "nail": 4}],
    "bird_bath": ["Купалка для птиц", "b20_bath", 4.0, [-12, -6, 24, 6], "bird", {"stone_block": 2, "mortar": 1}],
    "owl_post": ["Присада для сов", "b20_owlpost", 3.0, [-4, -4, 8, 4], "bird", {"log": 2, "rope": 1}],
    # хозяйство
    "beehive": ["Улей", "b20_beehive", 4.0, [-12, -8, 24, 8], "home", {"@plank": 4, "honeycomb": 1, "nail": 4}],
    "compost": ["Компостный ящик", "b20_compost", 4.0, [-16, -10, 32, 10], "home", {"@plank": 4, "nail": 4}],
    "rain_barrel": ["Бочка для дождя", "b20_rain_barrel", 4.0, [-12, -8, 24, 8], "home", {"stave": 6, "iron_bar": 1}],
    "scarecrow": ["Пугало", "b20_scarecrow", 2.0, [-4, -4, 8, 4], "home", {"stick": 3, "straw": 6, "linen": 1}],
    "woodpile": ["Поленница", "woodpile", 6.0, [-30, -12, 60, 12], "home", {"log": 8}],
    "hay": ["Стог сена", "hay_bale", 4.0, [-20, -10, 40, 10], "home", {"straw": 12}],
    "planter": ["Ящик с цветами", "dp_flowerbox", 2.0, [-14, -6, 28, 6], "deco", {"@plank": 2, "loam": 2}],
    "clothesline": ["Бельевая верёвка", "b20_clothesline", 2.0, [-30, -4, 60, 4], "home", {"stick": 4, "rope": 1, "linen": 2}],
    "storage_crate": ["Ящик для материалов", "mine_crate", 4.0, [-14, -10, 28, 10], "home", {"@plank": 4, "nail": 4}],
    "barrel": ["Бочонок", "barrel", 3.0, [-10, -8, 20, 8], "home", {"stave": 6, "hinge": 1}],
    # украшения
    "flower_bed": ["Клумба", "flower_bed", 2.0, [0, 0, 0, 0], "deco", {"loam": 3, "stone_s": 4}],
    "rose_bush": ["Куст роз", "rose_bush", 2.0, [-10, -6, 20, 6], "deco", {"loam": 2, "rosehip": 2}],
    "pot_pink": ["Горшок с цветком", "dp_pot_pink", 1.0, [-6, -4, 12, 4], "deco", {"pot_clay": 1, "loam": 1}],
    "pot_red": ["Горшок с геранью", "dp_pot_red", 1.0, [-6, -4, 12, 4], "deco", {"pot_clay": 1, "loam": 1}],
    "stone_lantern": ["Каменный фонарь", "stone_lantern", 6.0, [-10, -6, 20, 6], "deco", {"stone_block": 3, "candle": 1}],
    "elf_lantern": ["Эльфийский фонарь", "elf_lantern", 3.0, [-5, -4, 10, 4], "deco", {"@plank": 1, "glass_green": 1, "candle": 1}],
    "goth_lamp": ["Кованый фонарь", "goth_lamp", 4.0, [-5, -4, 10, 4], "deco", {"lantern_frame": 1, "glass": 1, "lamp_oil": 1}],
    "sign": ["Указатель", "sign", 1.0, [-4, -3, 8, 3], "deco", {"@plank": 2, "stick": 1}],
    "banner": ["Знамя", "banner_pole", 2.0, [-4, -3, 8, 3], "deco", {"stick": 2, "cloth_red": 1}],
    "fountain": ["Фонтан", "cat_fountain", 20.0, [-40, -20, 80, 20], "deco", {"marble_block": 8, "mortar": 4, "sheet_copper": 2}],
    "pillar": ["Колонна", "pillar", 8.0, [-10, -6, 20, 6], "deco", {"marble_block": 3}],
    "tea_table": ["Чайный столик", "tea_table", 4.0, [-16, -8, 32, 8], "deco", {"@plank": 3, "porcelain": 2}],
    "yarn_basket": ["Корзина с пряжей", "yarn_basket", 1.0, [-6, -4, 12, 4], "deco", {"basket": 1, "@yarn": 2}],
    "star_globe": ["Звёздный глобус", "star_globe", 4.0, [-10, -6, 20, 6], "deco", {"bar_brass": 2, "glass_clear": 1, "star_dust": 1}],
    "rune_stone": ["Рунный камень", "rune_stone", 8.0, [-10, -6, 20, 6], "deco", {"stone_block": 2, "rune_lit": 1}],
    "archery": ["Мишень", "archery_target", 3.0, [-10, -4, 20, 4], "deco", {"straw": 6, "@plank": 2}],
    "torii": ["Тории", "torii", 14.0, [-50, -6, 100, 6], "deco", {"beam": 4, "dye_red": 2}],
    "totem": ["Тотем", "totem", 6.0, [-8, -6, 16, 6], "deco", {"log": 3, "dye_red": 1, "feather_crow": 2}],
    "pumpkins": ["Корзина с зеленью", "dp_basket_greens", 1.0, [-8, -4, 16, 4], "deco", {"basket": 1}],
    # ограды и дорожки
    "stone_wall": ["Каменная стена", "w20_stone_wall", 6.0, [-16, -8, 32, 8], "wall", {"stone_block": 3, "mortar": 1}],
    "brick_wall": ["Кирпичная стена", "w20_brick_wall", 6.0, [-16, -8, 32, 8], "wall", {"brick": 4, "mortar": 1}],
    "hedge": ["Живая изгородь", "w20_hedge", 3.0, [-16, -8, 32, 8], "wall", {"sapling:tree_b": 1, "loam": 2}],
    "wicker_fence": ["Плетень", "w20_wicker", 2.0, [-16, -5, 32, 5], "wall", {"wicker": 4, "stick": 2}],
    "iron_fence": ["Кованая ограда", "iron_fence", 4.0, [-24, -6, 48, 6], "wall", {"iron_bar": 2, "chain": 1}],
    "palisade": ["Частокол", "palisade", 6.0, [-30, -8, 60, 8], "wall", {"log": 6}],
    "path_stone": ["Каменная дорожка", "w20_path_stone", 2.0, [0, 0, 0, 0], "wall", {"cobble": 4}],
    "path_brick": ["Кирпичная дорожка", "w20_path_brick", 2.0, [0, 0, 0, 0], "wall", {"brick": 3}],
    "path_wood": ["Деревянный настил", "w20_path_wood", 2.0, [0, 0, 0, 0], "wall", {"@plank": 3}],
    "path_gravel": ["Гравийная дорожка", "w20_path_gravel", 2.0, [0, 0, 0, 0], "wall", {"gravel": 4}],
    "path_marble": ["Мраморная плитка", "w20_path_marble", 2.0, [0, 0, 0, 0], "wall", {"marble_block": 1}],
}
TABS = ["home", "work", "trap", "bird", "deco", "wall"]
FLAT = ["path_stone", "path_brick", "path_wood", "path_gravel", "path_marble", "flower_bed"]   # лежат на земле, по ним ходят
# расширение участка: материалы на каждый уровень (не деньги — колышки, верёвка, расчистка)
PLOT_NEED = [{"stick": 8, "twine": 2}, {"stick": 12, "rope": 1, "stone_s": 6}, {"log": 6, "rope": 2, "stone_m": 6},
             {"@plank": 8, "rope": 3, "stone_block": 4}, {"beam": 4, "chain": 1, "stone_block": 8}, {"beam": 6, "chain": 2, "brick": 12, "mortar": 4}]


# ======================================================================== РИСОВАНИЕ ЗНАЧКОВ
def R5(c):
    return ramp(c)


def ic_wood_chunk(c, col):
    bark, wood = col
    m = c.mask()
    c.poly([(3, 11), (16, 6), (21, 11), (21, 14), (8, 19), (3, 16)], m)
    c.shade(m, R5(bark))
    end = c.mask()
    c.ellipse(5.5, 14.0, 3.2, 4.2, end)
    c.shade(end, R5(wood), flat=0.5)
    c.dot(5, 14, R5(wood)[1])
    c.dot(6, 13, R5(wood)[1])
    for i, (x, y) in enumerate([(9, 9), (13, 8), (12, 13), (16, 11), (17, 13)]):
        c.dot(x, y, R5(bark)[0 if i % 2 else 3])
    if bark == "e8e4dc":
        for x, y in [(10, 10), (11, 10), (15, 9), (14, 14), (18, 12)]:
            c.dot(x, y, (40, 36, 40, 255))
    c.outline()


def ic_plank(c, col):
    m = c.poly([(2, 15), (17, 6), (22, 9), (7, 18)])
    c.shade(m, R5(col[0]))
    side = c.poly([(2, 15), (7, 18), (7, 20), (2, 17)])
    side |= c.poly([(7, 18), (22, 9), (22, 11), (7, 20)])
    c.shade(side, [mix(x, (30, 20, 30), 0.3) for x in R5(col[0])])
    for k in range(3):
        c.line([(5 + k * 3, 14 - k), (13 + k * 3, 10 - k)], R5(col[0])[1])
    c.outline()


def ic_bark(c, col):
    m = c.poly([(5, 4), (15, 3), (19, 8), (18, 19), (8, 21), (4, 15)])
    c.shade(m, R5(col[0]))
    inner = c.poly([(10, 6), (15, 6), (16, 16), (11, 18)])
    c.shade(inner & m, R5(col[1]), flat=0.4)
    for y in range(5, 20, 3):
        c.line([(5, y), (9, y + 1)], R5(col[0])[0])
    c.outline()


def ic_stick(c, col):
    c.line([(6, 21), (17, 3)], R5(col[0])[2], 2)
    c.line([(7, 21), (18, 3)], R5(col[0])[3], 1)
    c.line([(11, 13), (15, 12)], R5(col[0])[2], 1)
    c.outline()


def ic_twigs(c, col):
    for a, b in [((3, 18), (20, 8)), ((4, 12), (20, 17)), ((6, 20), (16, 5))]:
        c.line([a, b], R5(col[0])[2], 1)
    c.line([(12, 12), (15, 9)], R5(col[0])[3], 1)
    c.outline()


def ic_pile(c, col):
    m = c.poly([(2, 20), (6, 12), (11, 8), (16, 10), (21, 15), (22, 20)])
    c.shade(m, R5(col[0]), gy=0.6)
    r = np.random.default_rng(len(col[0]))
    for i in range(14):
        x, y = r.integers(5, 20), r.integers(11, 20)
        if m[y, x]:
            c.dot(x, y, R5(col[0])[r.integers(0, 5)])
    c.outline()


def ic_lump(c, col):
    m = c.mask()
    c.ellipse(11, 14, 8, 6, m)
    c.ellipse(15, 11, 5, 4.5, m)
    c.shade(m, R5(col[0]))
    c.line([(8, 12), (11, 11)], R5(col[0])[4])
    c.outline()


def ic_chunks(c, col):
    for cx_, cy_, s in [(8, 14, 5), (15, 11, 4.5), (14, 18, 4)]:
        m = c.poly([(cx_ - s, cy_), (cx_ - s * 0.3, cy_ - s), (cx_ + s, cy_ - s * 0.4), (cx_ + s * 0.7, cy_ + s * 0.8), (cx_ - s * 0.5, cy_ + s * 0.7)])
        c.shade(m, R5(col[0]))
    c.dot(15, 9, (200, 200, 220, 255))
    c.outline()


def ic_drop(c, col):
    m = c.poly([(12, 3), (17, 12), (16, 18), (12, 21), (8, 18), (7, 12)])
    c.shade(m, R5(col[0]))
    c.dot(10, 10, (255, 250, 220, 255))
    c.dot(10, 11, R5(col[0])[4])
    c.outline()


def ic_pot(c, col):
    m = c.mask()
    c.ellipse(12, 15, 7, 6, m)
    c.rect(7, 6, 17, 10, m)
    c.shade(m, R5(col[0]))
    top = c.mask()
    c.ellipse(12, 7, 5, 2, top)
    c.shade(top, R5(col[1]), flat=0.5)
    c.line([(6, 9), (18, 9)], R5(col[0])[1])
    c.outline()


def ic_beam(c, col):
    m = c.poly([(1, 14), (18, 5), (23, 8), (6, 18)])
    c.shade(m, R5(col[0]))
    side = c.poly([(6, 18), (23, 8), (23, 12), (6, 22)]) | c.poly([(1, 14), (6, 18), (6, 22), (1, 18)])
    c.shade(side, [mix(x, (30, 20, 30), 0.3) for x in R5(col[0])])
    c.outline()


def ic_shingles(c, col):
    for i, (x, y) in enumerate([(4, 13), (10, 10), (16, 13), (7, 17), (13, 17)]):
        m = c.poly([(x, y), (x + 6, y - 2), (x + 7, y + 3), (x + 1, y + 5)])
        c.shade(m, R5(col[0]))
        c.inner_line(m, R5(col[0])[0])
    c.outline()


def ic_stave(c, col):
    m = c.poly([(8, 3), (13, 3), (15, 12), (13, 21), (8, 21), (10, 12)])
    c.shade(m, R5(col[0]))
    c.line([(11, 5), (12, 19)], R5(col[0])[1])
    c.outline()


def ic_gear(c, col):
    m = c.mask()
    c.ellipse(12, 12, 6.5, 6.5, m)
    for i in range(8):
        a = i * math.pi / 4
        x, y = 12 + math.cos(a) * 8, 12 + math.sin(a) * 8
        c.rect(int(x - 1.5), int(y - 1.5), int(x + 1.5), int(y + 1.5), m)
    hole = c.mask()
    c.ellipse(12, 12, 2.5, 2.5, hole)
    m &= ~hole
    c.shade(m, R5(col[0]))
    c.outline()


def ic_rock(c, col):
    base = col[0]
    fx = col[-1]
    m = c.poly([(3, 15), (7, 7), (14, 4), (20, 8), (21, 16), (14, 20), (6, 19)])
    c.shade(m, R5(base))
    yy, xx = np.mgrid[0:24, 0:24]
    if fx == "speckle":
        c.fill(m & ((xx * 7 + yy * 13) % 9 == 0), R5(base)[0])
        c.fill(m & ((xx * 5 + yy * 3) % 11 == 0), R5(base)[4])
    elif fx == "layers":
        c.fill(m & ((yy + xx // 4) % 4 == 0), R5(base)[1])
    elif fx == "veins":
        c.line([(6, 9), (11, 12), (14, 11), (19, 15)], hx(col[1]) + (255,))
    elif fx == "pores":
        c.fill(m & ((xx * 3 + yy * 5) % 7 == 0), R5(base)[1])
    elif fx == "glass":
        c.line([(8, 8), (13, 6)], R5(col[1] if len(col) > 2 else base)[4])
        c.line([(9, 15), (16, 10)], hx(col[1]) + (255,) if len(col) > 2 else R5(base)[3])
    c.outline()


def ic_brick(c, col):
    m = c.poly([(3, 13), (14, 8), (21, 11), (10, 16)])
    c.shade(m, R5(col[0]), flat=0.3)
    s1 = c.poly([(3, 13), (10, 16), (10, 21), (3, 18)])
    s2 = c.poly([(10, 16), (21, 11), (21, 16), (10, 21)])
    c.shade(s1, [mix(x, (40, 20, 30), 0.25) for x in R5(col[0])], flat=0.5)
    c.shade(s2, [mix(x, (40, 20, 30), 0.45) for x in R5(col[0])], flat=0.5)
    c.dot(8, 12, R5(col[0])[1])
    c.dot(15, 12, R5(col[0])[1])
    c.outline()


def ic_tile(c, col):
    for k in range(2):
        m = c.poly([(4, 10 + k * 5), (12, 6 + k * 5), (20, 10 + k * 5), (12, 14 + k * 5)])
        c.shade(m, R5(col[0]))
        c.inner_line(m, R5(col[0])[0])
    c.outline()


def ic_clay_pot(c, col):
    m = c.mask()
    c.ellipse(12, 15, 7, 6, m)
    c.rect(9, 5, 15, 10, m)
    c.rect(7, 4, 17, 6, m)
    c.shade(m, R5(col[0]))
    c.line([(7, 14), (17, 14)], R5(col[0])[1])
    c.rect(10, 5, 14, 6, c.mask())
    c.dot(11, 5, (40, 30, 30, 255))
    c.dot(12, 5, (40, 30, 30, 255))
    c.outline()


def ic_sack(c, col):
    m = c.mask()
    c.ellipse(12, 15, 8, 6.5, m)
    c.poly([(8, 9), (16, 9), (14, 5), (10, 5)], m)
    c.shade(m, R5(col[1]))
    top = c.mask()
    c.ellipse(12, 8, 3.5, 1.4, top)
    c.shade(top, R5(col[0]), flat=0.6)
    c.line([(9, 9), (15, 9)], R5(col[1])[0])
    c.outline()


def ic_block(c, col):
    top = c.poly([(4, 9), (12, 5), (20, 9), (12, 13)])
    l = c.poly([(4, 9), (12, 13), (12, 21), (4, 17)])
    r = c.poly([(12, 13), (20, 9), (20, 17), (12, 21)])
    rm = R5(col[0])
    c.shade(top, rm, flat=0.6)
    c.shade(l, [mix(x, (30, 30, 40), 0.2) for x in rm], flat=0.6)
    c.shade(r, [mix(x, (30, 30, 40), 0.4) for x in rm], flat=0.6)
    if len(col) > 1:
        c.line([(6, 12), (10, 16), (11, 19)], hx(col[1]) + (255,))
    c.outline()


def ic_pebbles(c, col):
    for cx_, cy_, rx, ry in [(7, 15, 4, 3), (14, 12, 4, 3), (16, 18, 3.5, 2.6), (9, 19, 3, 2.2), (12, 8, 2.6, 2)]:
        m = c.mask()
        c.ellipse(cx_, cy_, rx, ry, m)
        c.shade(m, R5(col[0]))
    c.outline()


def ic_crystals(c, col):
    for x0, h, w in [(6, 9, 3), (11, 14, 4), (16, 10, 3)]:
        m = c.poly([(x0, 20), (x0, 20 - h + 2), (x0 + w / 2, 20 - h), (x0 + w, 20 - h + 2), (x0 + w, 20)])
        c.shade(m, R5(col[0]))
    base = c.mask()
    c.ellipse(12, 20, 9, 2.5, base)
    c.shade(base, R5("8a8070"))
    c.outline()


def ic_pane(c, col):
    m = c.poly([(4, 7), (16, 3), (20, 16), (8, 21)])
    rm = R5(col[0])
    c.fill(m, rm[2][:3] + (200,))
    c.line([(7, 9), (11, 7)], (255, 255, 255, 255))
    c.line([(8, 12), (14, 9)], (255, 255, 255, 230))
    c.inner_line(m, rm[1])
    c.outline()


def ic_vial(c, col):
    m = c.mask()
    c.ellipse(12, 16, 5.5, 5, m)
    c.rect(10, 5, 14, 12, m)
    c.fill(m, R5(col[0])[2][:3] + (210,))
    c.rect(9, 3, 15, 5, c.mask())
    cork = c.rect(10, 3, 14, 6)
    c.shade(cork, R5("a07a50"))
    c.dot(9, 14, (255, 255, 255, 255))
    c.outline()


def ic_ore(c, col):
    m = c.poly([(3, 15), (7, 7), (14, 4), (20, 8), (21, 16), (14, 20), (6, 19)])
    c.shade(m, R5(col[0]))
    for x, y in [(8, 10), (14, 8), (16, 14), (10, 16), (12, 12)]:
        n = c.mask()
        c.ellipse(x, y, 1.8, 1.5, n)
        c.shade(n & m, R5(col[1]), flat=0.2)
    c.outline()


def ic_nugget(c, col):
    m = c.mask()
    c.ellipse(10, 14, 5, 4, m)
    c.ellipse(15, 12, 4, 3.5, m)
    c.shade(m, R5(col[0]))
    c.dot(9, 12, (255, 255, 240, 255))
    c.outline()


def ic_bar(c, col):
    top = c.poly([(5, 10), (15, 6), (21, 9), (11, 13)])
    l = c.poly([(3, 13), (5, 10), (11, 13), (10, 17)])
    r = c.poly([(10, 17), (11, 13), (21, 9), (21, 13)])
    rm = R5(col[0])
    c.shade(top, rm, flat=0.4)
    c.shade(l, [mix(x, (30, 30, 40), 0.25) for x in rm], flat=0.5)
    c.shade(r, [mix(x, (30, 30, 40), 0.45) for x in rm], flat=0.5)
    c.line([(8, 10), (14, 8)], rm[4])
    c.outline()


def ic_nails(c, col):
    for x in (7, 11, 15):
        c.line([(x, 6), (x + 2, 19)], R5(col[0])[3])
        c.line([(x - 1, 6), (x + 2, 5)], R5(col[0])[2])
    c.outline()


def ic_hinge(c, col):
    m = c.rect(5, 6, 11, 18) | c.rect(13, 6, 19, 18)
    c.shade(m, R5(col[0]))
    k = c.rect(11, 6, 13, 18)
    c.shade(k, R5(col[0]), flat=0.7)
    for x, y in [(8, 9), (8, 15), (16, 9), (16, 15)]:
        c.dot(x, y, R5(col[0])[0])
    c.outline()


def ic_chain(c, col):
    for i in range(4):
        m = c.mask()
        c.ellipse(6 + i * 4, 18 - i * 4, 3.2, 2.2, m)
        h = c.mask()
        c.ellipse(6 + i * 4, 18 - i * 4, 1.4, 0.8, h)
        c.shade(m & ~h, R5(col[0]))
    c.outline()


def ic_wire(c, col):
    m = c.mask()
    c.ellipse(12, 13, 8, 6, m)
    h = c.mask()
    c.ellipse(12, 13, 4.5, 3, h)
    m &= ~h
    c.shade(m, R5(col[0]))
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(m & ((xx + yy) % 2 == 0), R5(col[0])[1])
    c.outline()


def ic_sheet(c, col):
    m = c.poly([(3, 12), (13, 6), (21, 11), (11, 17)])
    c.shade(m, R5(col[0]), flat=0.3)
    s = c.poly([(3, 12), (11, 17), (11, 18), (3, 13)]) | c.poly([(11, 17), (21, 11), (21, 12), (11, 18)])
    c.fill(s, R5(col[0])[0])
    c.line([(8, 11), (13, 8)], R5(col[0])[4])
    c.outline()


def ic_spring(c, col):
    for i in range(6):
        c.line([(7, 6 + i * 2.5), (17, 7 + i * 2.5)], R5(col[0])[3 if i % 2 else 2])
    c.outline()


def ic_needle(c, col):
    c.line([(5, 19), (19, 5)], R5(col[0])[3])
    c.dot(17, 7, (30, 24, 38, 255))
    c.outline()


def ic_bell(c, col):
    m = c.poly([(12, 4), (16, 7), (17, 15), (19, 18), (5, 18), (7, 15), (8, 7)])
    c.shade(m, R5(col[0]))
    k = c.mask()
    c.ellipse(12, 19.5, 1.6, 1.6, k)
    c.shade(k, R5(col[0]), flat=0.6)
    c.outline()


def ic_lantern_frame(c, col):
    m = c.rect(7, 7, 17, 19)
    hole = c.rect(9, 9, 15, 17)
    c.shade(m & ~hole, R5(col[0]))
    c.fill(c.poly([(7, 7), (12, 3), (17, 7)]), R5(col[0])[2])
    c.outline()


def ic_gem_raw(c, col):
    for x0, h, w in [(5, 11, 4), (10, 16, 5), (15, 10, 4)]:
        m = c.poly([(x0, 20), (x0, 20 - h + 3), (x0 + w / 2, 20 - h), (x0 + w, 20 - h + 3), (x0 + w, 20)])
        c.shade(m, R5(col[0]))
        c.line([(x0 + 1, 20 - h + 4), (x0 + 1, 18)], R5(col[0])[4])
    rock = c.mask()
    c.ellipse(12, 20.5, 9, 2.5, rock)
    c.shade(rock, R5("6a6460"))
    c.outline()


def ic_gem_cut(c, col):
    rm = R5(col[0])
    top = c.poly([(6, 9), (9, 5), (15, 5), (18, 9)])
    bot = c.poly([(6, 9), (18, 9), (12, 20)])
    c.shade(top, rm, flat=0.2)
    c.shade(bot, rm, flat=0.2)
    c.line([(6, 9), (18, 9)], rm[4])
    c.line([(9, 9), (12, 19)], rm[1])
    c.line([(15, 9), (12, 19)], rm[3])
    c.dot(10, 6, (255, 255, 255, 255))
    c.outline()


def ic_fiber(c, col):
    for i in range(7):
        x = 6 + i * 2
        c.line([(12, 21), (x, 3 + abs(i - 3))], R5(col[0])[2 + (i % 3) - 1])
    c.line([(9, 15), (15, 15)], R5("8a6a3a")[2], 2)
    if len(col) > 1:
        for x, y in [(6, 4), (12, 3), (18, 5)]:
            c.dot(x, y, hx(col[1]) + (255,))
    c.outline()


def ic_cotton(c, col):
    for cx_, cy_ in [(9, 10), (15, 10), (12, 15), (8, 15), (16, 15)]:
        m = c.mask()
        c.ellipse(cx_, cy_, 3.4, 3.2, m)
        c.shade(m, R5(col[0]))
    st = c.poly([(10, 18), (14, 18), (13, 21), (11, 21)])
    c.shade(st, R5("6a5a3a"))
    c.outline()


def ic_reed(c, col):
    for x in (8, 12, 16):
        c.line([(x, 21), (x + 1, 4)], R5(col[0])[2])
        m = c.mask()
        c.ellipse(x + 1, 6, 1.4, 3, m)
        c.shade(m, R5("8a5a2a"))
    c.outline()


def ic_cocoon(c, col):
    m = c.mask()
    c.ellipse(12, 13, 5, 7.5, m)
    c.shade(m, R5(col[0]))
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(m & ((yy + xx // 2) % 3 == 0), R5(col[0])[1])
    c.line([(12, 2), (12, 5)], R5("8a8070")[2])
    c.outline()


def ic_web(c, col):
    for a in range(6):
        ang = a * math.pi / 3
        c.line([(12, 12), (12 + math.cos(ang) * 9, 12 + math.sin(ang) * 9)], R5(col[0])[3])
    for r in (3, 6, 9):
        pts = [(12 + math.cos(a * math.pi / 3) * r, 12 + math.sin(a * math.pi / 3) * r) for a in range(7)]
        c.line(pts, R5(col[0])[2])


def ic_spool(c, col):
    body = c.rect(8, 7, 16, 18)
    c.shade(body, R5(col[0]))
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(body & (yy % 2 == 0), R5(col[0])[1])
    for y in (5, 18):
        m = c.rect(6, y, 18, y + 2)
        c.shade(m, R5("a07a50"))
    c.outline()


def ic_cloth(c, col):
    rm = R5(col[0])
    m = c.poly([(2, 12), (14, 6), (22, 10), (10, 17)])
    c.shade(m, rm, flat=0.3)
    f = c.poly([(2, 12), (10, 17), (10, 21), (2, 16)]) | c.poly([(10, 17), (22, 10), (22, 14), (10, 21)])
    c.shade(f, [mix(x, (30, 20, 40), 0.3) for x in rm], flat=0.4)
    c.line([(4, 15), (10, 18), (22, 12)], rm[1])
    c.outline()


def ic_rope(c, col):
    m = c.mask()
    c.ellipse(12, 13, 8.5, 7, m)
    h = c.mask()
    c.ellipse(12, 13, 4, 3, h)
    m &= ~h
    c.shade(m, R5(col[0]))
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(m & ((xx - yy) % 3 == 0), R5(col[0])[1])
    c.line([(18, 17), (21, 21)], R5(col[0])[2], 2)
    c.outline()


def ic_net(c, col):
    m = c.poly([(3, 6), (21, 6), (19, 20), (5, 20)])
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(m & (((xx + yy) % 4 == 0) | ((xx - yy) % 4 == 0)), R5(col[0])[3])
    c.outline()


def ic_basket(c, col):
    m = c.poly([(4, 10), (20, 10), (18, 20), (6, 20)])
    c.shade(m, R5(col[0]))
    yy, xx = np.mgrid[0:24, 0:24]
    c.fill(m & ((yy % 3 == 0) | ((xx + (yy // 3) * 2) % 4 == 0)), R5(col[0])[1])
    hd = c.line_mask([(6, 10), (8, 4), (16, 4), (18, 10)], 1)
    c.fill(hd, R5(col[0])[2])
    c.outline()


def ic_fluff(c, col):
    m = c.mask()
    r = np.random.default_rng(3)
    for i in range(8):
        c.ellipse(12 + r.uniform(-5, 5), 13 + r.uniform(-4, 4), r.uniform(2.5, 4), r.uniform(2.5, 3.5), m)
    c.shade(m, R5(col[0]))
    for i in range(6):
        c.dot(r.integers(6, 18), r.integers(8, 18), R5(col[0])[4])
    c.outline()


def ic_tuft(c, col):
    for i in range(9):
        x0 = 6 + i * 1.4
        c.line([(x0, 20), (x0 + 3 + (i % 3), 5 + abs(i - 4))], R5(col[0])[1 + i % 4])
    c.line([(5, 20), (17, 20)], R5(col[0])[0], 2)
    c.outline()


def ic_antler(c, col):
    m = c.line_mask([(6, 21), (9, 13), (12, 8), (17, 4)], 2)
    c.line_mask([(9, 13), (5, 9), (4, 5)], 2, m)
    c.line_mask([(12, 8), (14, 3)], 2, m)
    c.line_mask([(10, 11), (16, 11), (19, 8)], 2, m)
    c.shade(m, R5(col[0]))
    c.outline()


def ic_bristle(c, col):
    for i in range(10):
        c.line([(6 + i * 1.3, 19), (5 + i * 1.6, 5 + (i % 3))], R5(col[0])[1 + i % 3])
    c.outline()


def ic_quill(c, col):
    for i, (a, b) in enumerate([((5, 19), (15, 4)), ((9, 20), (19, 6)), ((4, 14), (20, 10))]):
        c.line([a, b], R5(col[0])[3])
        c.dot(b[0], b[1], (240, 236, 220, 255))
    c.outline()


def ic_hair(c, col):
    for i in range(5):
        pts = [(6 + i * 1.5 + 3 * math.sin(t * 0.5), 3 + t) for t in range(0, 19, 2)]
        c.line(pts, R5(col[0])[1 + i % 4])
    c.outline()


def ic_whisker(c, col):
    for a, b in [((4, 17), (20, 12)), ((5, 12), (20, 9)), ((4, 20), (19, 17))]:
        c.line([a, b], R5(col[0])[3])
    c.dot(4, 17, (60, 50, 50, 255))
    c.outline()


def ic_scale(c, col):
    for cx_, cy_ in [(9, 10), (15, 10), (12, 15)]:
        m = c.mask()
        c.ellipse(cx_, cy_, 4.5, 4, m)
        c.fill(m, R5(col[0])[3][:3] + (230,))
        c.inner_line(m, R5(col[0])[1])
    c.dot(8, 8, (255, 255, 255, 255))
    c.outline()


def ic_comb(c, col):
    for i, (x, y) in enumerate([(8, 8), (14, 8), (5, 13), (11, 13), (17, 13), (8, 18), (14, 18)]):
        m = c.poly([(x - 3, y), (x - 1.5, y - 2.6), (x + 1.5, y - 2.6), (x + 3, y), (x + 1.5, y + 2.6), (x - 1.5, y + 2.6)])
        c.shade(m, R5(col[0]))
        c.inner_line(m, R5(col[0])[0])
    c.outline()


def ic_jar(c, col):
    m = c.rect(7, 8, 17, 20)
    c.fill(m, R5(col[0])[2][:3] + (230,))
    lid = c.rect(6, 5, 18, 8)
    c.shade(lid, R5("a07a50"))
    c.dot(9, 11, (255, 255, 255, 255))
    c.outline()


def ic_shell(c, col):
    m = c.poly([(12, 19), (4, 11), (6, 6), (12, 4), (18, 6), (20, 11)])
    c.shade(m, R5(col[0]))
    for x in (7, 10, 14, 17):
        c.line([(12, 18), (x, 6)], R5(col[0])[1])
    c.outline()


def ic_conch(c, col):
    m = c.poly([(4, 16), (8, 7), (14, 4), (20, 8), (18, 14), (10, 20)])
    c.shade(m, R5(col[0]))
    c.line([(8, 12), (12, 9), (16, 9)], R5(col[0])[1])
    inner = c.mask()
    c.ellipse(13, 13, 3, 3.5, inner)
    c.shade(inner & m, R5("f8c0c8"), flat=0.5)
    c.outline()


def ic_coral(c, col):
    m = c.line_mask([(12, 21), (12, 13), (8, 8), (7, 4)], 2)
    c.line_mask([(12, 14), (16, 9), (17, 4)], 2, m)
    c.line_mask([(9, 9), (12, 6)], 2, m)
    c.line_mask([(15, 10), (19, 9)], 2, m)
    c.shade(m, R5(col[0]))
    c.outline()


def ic_pearl(c, col):
    m = c.mask()
    c.ellipse(12, 13, 5.5, 5.5, m)
    c.shade(m, R5(col[0]))
    c.dot(10, 11, (255, 255, 255, 255))
    c.outline()


def ic_star(c, col):
    pts = []
    for i in range(10):
        a = -math.pi / 2 + i * math.pi / 5
        r = 9 if i % 2 == 0 else 3.8
        pts.append((12 + math.cos(a) * r, 13 + math.sin(a) * r))
    m = c.poly(pts)
    c.shade(m, R5(col[0]))
    c.outline()


def ic_dye(c, col):
    m = c.mask()
    c.ellipse(12, 15, 6.5, 5.5, m)
    c.rect(10, 6, 14, 11, m)
    c.fill(m, R5("d8e8ec")[2][:3] + (220,))
    liq = c.mask()
    c.ellipse(12, 16, 5.5, 4.2, liq)
    c.shade(liq & m, R5(col[0]))
    cork = c.rect(10, 4, 14, 7)
    c.shade(cork, R5("8a6a44"))
    c.dot(8, 14, (255, 255, 255, 255))
    c.outline()


def ic_ink(c, col):
    m = c.rect(6, 10, 18, 19)
    c.shade(m, R5("2a2a3a"))
    neck = c.rect(9, 7, 15, 10)
    c.shade(neck, R5("3a3a4a"))
    c.line([(15, 2), (11, 9)], R5("f0ece0")[3], 2)
    c.outline()


def ic_paper(c, col):
    for k in range(3):
        m = c.poly([(4 + k, 8 - k), (18 + k, 5 - k), (20 + k, 17 - k), (6 + k, 20 - k)])
        c.shade(m, R5(col[0]), flat=0.6)
        c.inner_line(m, R5(col[0])[1])
    c.line([(9, 9), (17, 7)], R5("8a8070")[2])
    c.line([(9, 12), (17, 10)], R5("8a8070")[2])
    c.outline()


def ic_book(c, col):
    m = c.poly([(4, 8), (16, 4), (20, 15), (8, 20)])
    c.shade(m, R5(col[0]))
    pg = c.poly([(8, 20), (20, 15), (20, 17), (8, 22)])
    c.shade(pg, R5("f4ecd8"), flat=0.5)
    c.line([(7, 9), (11, 18)], R5(col[0])[0])
    c.outline()


def ic_candle(c, col):
    m = c.rect(9, 8, 15, 20)
    c.shade(m, R5(col[0]))
    flame = c.poly([(12, 2), (14, 6), (12, 8), (10, 6)])
    c.shade(flame, R5("f8c040"))
    c.dot(12, 5, (255, 255, 230, 255))
    base = c.mask()
    c.ellipse(12, 20, 6, 2, base)
    c.shade(base, R5("a07a50"))
    c.outline()


def ic_soap(c, col):
    top = c.poly([(4, 11), (13, 7), (20, 10), (11, 14)])
    side = c.poly([(4, 11), (11, 14), (11, 18), (4, 15)]) | c.poly([(11, 14), (20, 10), (20, 14), (11, 18)])
    c.shade(top, R5(col[0]), flat=0.4)
    c.shade(side, [mix(x, (40, 30, 30), 0.3) for x in R5(col[0])], flat=0.5)
    for x, y in [(15, 5), (18, 3), (12, 4)]:
        b = c.mask()
        c.ellipse(x, y, 1.5, 1.5, b)
        c.fill(b, (220, 240, 255, 200))
    c.outline()


def ic_flask(c, col):
    m = c.mask()
    c.ellipse(12, 15, 6, 6, m)
    c.rect(10, 4, 14, 10, m)
    c.fill(m, R5("d8e8ec")[2][:3] + (210,))
    liq = c.mask()
    c.ellipse(12, 16, 5, 4.5, liq)
    c.shade(liq & m, R5(col[0]))
    c.outline()


def ic_grains(c, col):
    r = np.random.default_rng(9)
    for i in range(14):
        x, y = r.integers(5, 19), r.integers(8, 20)
        m = c.mask()
        c.ellipse(x, y, 1.6, 1.1, m)
        c.shade(m, R5(col[0]), flat=0.3)
    c.outline()


def ic_dust(c, col):
    m = c.mask()
    c.ellipse(12, 15, 6, 5.5, m)
    c.poly([(9, 10), (15, 10), (14, 6), (10, 6)], m)
    c.shade(m, R5("b08a60"))
    t = c.rect(8, 9, 16, 11)
    c.fill(t, R5("8a5a3a")[2])
    for x, y in [(6, 4), (17, 3), (19, 8), (4, 9), (12, 2)]:
        c.dot(x, y, R5(col[0])[4])
        c.dot(x + 1, y, R5(col[0])[2])
    c.outline()
    for x, y in [(10, 15), (14, 17), (13, 13)]:
        c.dot(x, y, R5(col[0])[3])


def ic_essence(c, col):
    m = c.mask()
    c.ellipse(12, 15, 5.5, 5.5, m)
    c.rect(10, 5, 14, 11, m)
    c.shade(m, R5(col[0]))
    c.dot(10, 13, (255, 255, 255, 255))
    st = c.rect(9, 3, 15, 5)
    c.shade(st, R5("c8a050"))
    c.outline()


def ic_rune(c, col):
    m = c.poly([(6, 5), (17, 4), (19, 19), (5, 20)])
    c.shade(m, R5("8a8e9a"))
    c.line([(10, 8), (13, 12), (10, 16)], R5(col[0])[4 if col[0] != "8a8e9a" else 0])
    c.line([(14, 8), (14, 16)], R5(col[0])[4 if col[0] != "8a8e9a" else 0])
    c.outline()


def ic_yarn(c, col):
    m = c.mask()
    c.ellipse(12, 13, 7, 7, m)
    c.shade(m, R5(col[0]))
    for k in range(-2, 3):
        c.line([(7, 13 + k * 2), (17, 11 + k * 2)], R5(col[0])[1])
    c.line([(17, 17), (21, 21)], R5(col[0])[2])
    c.outline()


TPL = {k[3:]: v for k, v in globals().items() if k.startswith("ic_")}


def draw_icon(mid):
    d = MATS[mid]
    if d["tpl"] == "feather":
        return
    c = Canvas(24, 24)
    TPL[d["tpl"]](c, d["col"])
    c.save(os.path.join(ART, d["icon"] + ".png"))


# ======================================================================== СПРАЙТЫ МИРА
def save_canvas(c, name):
    c.save(os.path.join(ART, name + ".png"))


def wood_box(c, x0, y0, x1, y1, col="a07a50", dark=0.0):
    m = c.rect(x0, y0, x1, y1)
    rm = R5(col)
    if dark:
        rm = [mix(x, (30, 20, 30), dark) for x in rm]
    c.shade(m, rm, flat=0.2)
    yy, xx = np.mgrid[0:c.h, 0:c.w]
    c.fill(m & ((yy - y0) % 4 == 3), rm[1])
    return m


def stone_box(c, x0, y0, x1, y1, col="8a8680"):
    m = c.rect(x0, y0, x1, y1)
    rm = R5(col)
    c.shade(m, rm, flat=0.2)
    yy, xx = np.mgrid[0:c.h, 0:c.w]
    joints = m & (((yy - y0) % 6 == 5) | (((xx - x0 + ((yy - y0) // 6) * 5) % 10) == 9))
    c.fill(joints, rm[0])
    return m


def legs(c, xs, y0, y1, col="6a4a30"):
    for x in xs:
        c.shade(c.rect(x, y0, x + 2, y1), R5(col), flat=0.4)


def st_sawmill():
    c = Canvas(72, 48)
    legs(c, [8, 60], 30, 46)
    wood_box(c, 4, 24, 68, 32, "a07a50")
    log = c.mask()
    c.rect(10, 16, 56, 24, log)
    c.shade(log, R5("8a6a48"))
    end = c.mask()
    c.ellipse(10, 20, 3, 4, end)
    c.shade(end, R5("e0c090"), flat=0.5)
    blade = c.mask()
    c.ellipse(40, 18, 9, 9, blade)
    c.fill(blade & ~log, R5("b8c0cc")[2])
    c.inner_line(blade & ~log, R5("b8c0cc")[0])
    for i in range(12):
        a = i * math.pi / 6
        c.dot(40 + math.cos(a) * 9.5, 18 + math.sin(a) * 9.5, R5("b8c0cc")[0])
    c.dot(40, 18, (40, 40, 50, 255))
    pile = c.mask()
    c.ellipse(60, 44, 8, 3, pile)
    c.shade(pile, R5("e0c898"))
    c.outline()
    save_canvas(c, "st20_sawmill")


def st_kiln():
    c = Canvas(56, 56)
    m = c.mask()
    c.ellipse(28, 34, 24, 20, m)
    m &= c.rect(0, 10, 56, 54)
    m |= c.rect(4, 34, 52, 54)
    c.shade(m, R5("b07050"))
    yy, xx = np.mgrid[0:56, 0:56]
    c.fill(m & ((yy % 6 == 0) | (((xx + (yy // 6) * 4) % 9) == 0)), R5("b07050")[1])
    mouth = c.mask()
    c.ellipse(28, 46, 9, 8, mouth)
    mouth &= c.rect(0, 0, 56, 54)
    c.fill(mouth, (40, 20, 20, 255))
    fire = c.mask()
    c.ellipse(28, 50, 6, 3, fire)
    c.shade(fire, R5("f08a2a"))
    chim = c.rect(36, 4, 44, 18)
    c.shade(chim, R5("8a5a40"))
    c.outline()
    save_canvas(c, "st20_kiln")


def st_smelter():
    c = Canvas(60, 60)
    body = stone_box(c, 8, 20, 52, 58, "7a7670")
    chim = stone_box(c, 22, 2, 38, 22, "6a6660")
    mouth = c.rect(22, 38, 38, 52)
    c.fill(mouth, (40, 20, 20, 255))
    fire = c.mask()
    c.ellipse(30, 49, 7, 3, fire)
    c.shade(fire, R5("f8a030"))
    crucible = c.mask()
    c.ellipse(30, 28, 8, 4, crucible)
    c.shade(crucible, R5("4a4448"))
    melt = c.mask()
    c.ellipse(30, 27, 6, 2, melt)
    c.shade(melt, R5("ffb040"), flat=0.4)
    spout = c.rect(46, 30, 58, 33)
    c.shade(spout, R5("5a5658"))
    mold = c.rect(48, 52, 60, 58)
    c.shade(mold, R5("5a5658"))
    c.outline()
    save_canvas(c, "st20_smelter")


def st_anvil():
    c = Canvas(44, 34)
    stump = c.mask()
    c.rect(12, 18, 32, 33, stump)
    c.shade(stump, R5("7a5a3a"))
    top = c.poly([(4, 8), (40, 8), (36, 13), (28, 13), (28, 18), (16, 18), (16, 13), (8, 13)])
    c.shade(top, R5("5a5e68"))
    horn = c.poly([(0, 9), (4, 8), (4, 12)])
    c.shade(horn, R5("5a5e68"))
    c.line([(6, 8), (38, 8)], R5("5a5e68")[4])
    ham = c.rect(30, 2, 34, 8)
    c.shade(ham, R5("7a5a3a"))
    hh = c.rect(27, 0, 37, 3)
    c.shade(hh, R5("6a6e78"))
    c.outline()
    save_canvas(c, "st20_anvil")


def st_spinning():
    c = Canvas(44, 46)
    wheel = c.mask()
    c.ellipse(26, 18, 14, 14, wheel)
    hole = c.mask()
    c.ellipse(26, 18, 12, 12, hole)
    c.shade(wheel & ~hole, R5("9a6a40"))
    for i in range(8):
        a = i * math.pi / 4
        c.line([(26, 18), (26 + math.cos(a) * 12, 18 + math.sin(a) * 12)], R5("8a5a34")[2])
    c.dot(26, 18, R5("5a3a20")[1])
    bench = c.poly([(2, 30), (40, 26), (42, 30), (4, 34)])
    c.shade(bench, R5("a07a50"))
    legs(c, [6, 36], 32, 45, "7a5a3a")
    c.line([(26, 18), (30, 34)], R5("7a5a3a")[2], 2)
    spool = c.mask()
    c.ellipse(8, 24, 4, 3, spool)
    c.shade(spool, R5("e8e0c8"))
    c.outline()
    save_canvas(c, "st20_spinning")


def st_dye_vat():
    c = Canvas(48, 40)
    vat = c.mask()
    c.ellipse(24, 22, 20, 7, vat)
    c.rect(4, 22, 44, 36, vat)
    bot = c.mask()
    c.ellipse(24, 36, 20, 4, bot)
    vat |= bot
    c.shade(vat, R5("8a6a48"))
    yy, xx = np.mgrid[0:40, 0:48]
    c.fill(vat & ((xx % 5) == 0), R5("8a6a48")[1])
    for y in (26, 33):
        c.fill(vat & (yy == y), R5("5a5e68")[2])
    liq = c.mask()
    c.ellipse(24, 22, 17, 5, liq)
    c.shade(liq, R5("6a3ac8"), flat=0.4)
    c.dot(18, 21, (220, 200, 255, 255))
    stick = c.line_mask([(30, 21), (40, 4)], 2)
    c.shade(stick, R5("a07a50"))
    cloth = c.poly([(4, 10), (12, 8), (13, 18), (5, 19)])
    c.shade(cloth, R5("d83a3a"))
    c.outline()
    save_canvas(c, "st20_dye_vat")


def st_mason():
    c = Canvas(64, 46)
    legs(c, [6, 54], 28, 45, "6a5a4a")
    top = wood_box(c, 2, 22, 62, 29, "8a7a68")
    blk = c.mask()
    c.rect(10, 10, 28, 22, blk)
    c.shade(blk, R5("a8a49c"))
    c.inner_line(blk, R5("a8a49c")[1])
    blk2 = c.poly([(34, 22), (38, 12), (50, 10), (56, 22)])
    c.shade(blk2, R5("d8d4cc"))
    c.line([(40, 14), (48, 20)], R5("8a8a94")[2])
    ch = c.line_mask([(30, 8), (36, 2)], 2)
    c.shade(ch, R5("9aa0aa"))
    ml = c.rect(30, 16, 36, 22)
    c.shade(ml, R5("8a6a44"))
    c.outline()
    save_canvas(c, "st20_mason")


def st_jeweler():
    c = Canvas(56, 46)
    legs(c, [6, 46], 28, 45, "5a3a2a")
    wood_box(c, 2, 20, 54, 28, "7a4a3a")
    lamp = c.line_mask([(10, 20), (10, 6), (20, 4)], 2)
    c.shade(lamp, R5("c88a3a"))
    sh = c.poly([(16, 2), (24, 2), (26, 8), (14, 8)])
    c.shade(sh, R5("3a6a4a"))
    glow = c.mask()
    c.ellipse(20, 10, 3, 1.5, glow)
    c.fill(glow, (255, 240, 180, 255))
    loupe = c.mask()
    c.ellipse(34, 15, 4, 4, loupe)
    h = c.mask()
    c.ellipse(34, 15, 2.5, 2.5, h)
    c.shade(loupe & ~h, R5("c8a040"))
    c.fill(h, (200, 230, 255, 180))
    for x, colr in [(42, "9a5ad8"), (46, "e05a8a"), (50, "60d0e0")]:
        g = c.poly([(x, 19), (x + 1.5, 16), (x + 3, 19), (x + 1.5, 21)])
        c.shade(g, R5(colr))
    c.outline()
    save_canvas(c, "st20_jeweler")


def st_press():
    c = Canvas(52, 52)
    for x in (6, 40):
        c.shade(c.rect(x, 8, x + 6, 50), R5("8a6a44"))
    c.shade(c.rect(4, 6, 48, 12), R5("7a5a3a"))
    screw = c.rect(24, 12, 28, 26)
    c.shade(screw, R5("9aa0aa"))
    c.line([(14, 16), (38, 16)], R5("7a5a3a")[2], 2)
    plate = c.rect(14, 26, 38, 30)
    c.shade(plate, R5("a07a50"))
    tub = c.mask()
    c.ellipse(26, 36, 13, 4, tub)
    c.rect(13, 36, 39, 46, tub)
    c.shade(tub, R5("9a7a52"))
    spout = c.rect(38, 42, 46, 44)
    c.shade(spout, R5("9a7a52"))
    jug = c.mask()
    c.ellipse(46, 48, 4, 3.5, jug)
    c.shade(jug, R5("b07050"))
    c.outline()
    save_canvas(c, "st20_press")


def trap(name, w, h, kind):
    c = Canvas(w, h)
    if kind == "cage":
        base = wood_box(c, 1, h - 6, w - 1, h - 1, "8a6a44")
        top = wood_box(c, 1, 2, w - 1, 6, "8a6a44")
        for x in range(2, w - 1, 4):
            c.shade(c.rect(x, 6, x + 1, h - 6), R5("a07a50"), flat=0.5)
        c.outline()
        front = Canvas(w, h)
        for x in range(2, w - 1, 4):
            front.fill(front.rect(x, 6, x + 1, h - 6), R5("8a6a44")[2])
        save_canvas(c, name)
        front.save(os.path.join(ART, name + "_bars.png"))
        return
    if kind == "pen":
        for x in (2, w // 2 - 1, w - 5):
            c.shade(c.rect(x, 4, x + 3, h - 1), R5("7a5a3a"))
        for y in (8, 16):
            c.shade(c.rect(2, y, w - 2, y + 3), R5("9a7a50"))
        gate = c.rect(w // 2 + 4, 6, w - 8, h - 6)
        c.shade(gate & (np.mgrid[0:h, 0:w][1] % 4 == 0), R5("8a6a44"))
        c.outline()
        save_canvas(c, name)
        return
    if kind == "bird":
        bk = c.mask()
        c.ellipse(w / 2, h - 7, w / 2 - 2, 6, bk)
        c.rect(2, h - 7, w - 2, h - 1, bk)
        c.shade(bk, R5("b08a50"))
        yy, xx = np.mgrid[0:h, 0:w]
        c.fill(bk & ((yy % 3 == 0) | ((xx + yy // 3) % 3 == 0)), R5("b08a50")[1])
        c.line([(4, h - 10), (9, 2)], R5("7a5a3a")[2], 1)
        c.line([(9, 2), (9, 6)], R5("e8e0c8")[3], 1)
        c.outline()
        save_canvas(c, name)
        return
    if kind == "fish":
        body = c.mask()
        c.ellipse(w * 0.55, h / 2, w * 0.42, h / 2 - 2, body)
        c.poly([(2, h / 2 - 3), (8, h / 2), (2, h / 2 + 3)], body)
        c.shade(body, R5("a08a58"))
        yy, xx = np.mgrid[0:h, 0:w]
        c.fill(body & ((xx % 4 == 0) | (yy % 3 == 0)), R5("a08a58")[1])
        mouth = c.mask()
        c.ellipse(w - 6, h / 2, 3, 3, mouth)
        c.fill(mouth, (40, 30, 30, 255))
        c.outline()
        save_canvas(c, name)
        return
    if kind == "magic":
        ring = c.mask()
        c.ellipse(w / 2, h - 7, w / 2 - 2, 5, ring)
        h2 = c.mask()
        c.ellipse(w / 2, h - 7, w / 2 - 5, 3, h2)
        c.shade(ring & ~h2, R5("c8ccd4"))
        for x in (5, w - 7):
            c.shade(c.rect(x, 4, x + 2, h - 7), R5("d8dce8"))
        gem = c.poly([(w / 2, 1), (w / 2 + 3, 5), (w / 2, 9), (w / 2 - 3, 5)])
        c.shade(gem, R5("c8d8f0"))
        c.outline()
        save_canvas(c, name)
        return
    if kind == "bat":
        for x in (2, w - 4):
            c.shade(c.rect(x, 2, x + 2, h - 1), R5("6a4a30"))
        net = c.rect(4, 3, w - 4, h - 6)
        yy, xx = np.mgrid[0:h, 0:w]
        c.fill(net & (((xx + yy) % 3 == 0) | ((xx - yy) % 3 == 0)), (210, 210, 220, 200))
        c.outline()
        save_canvas(c, name)


def bird_props():
    # кормушка: столбик и домик-поднос
    c = Canvas(24, 40)
    c.shade(c.rect(11, 16, 13, 39), R5("7a5a3a"))
    tray = c.rect(3, 14, 21, 17)
    c.shade(tray, R5("a07a50"))
    roof = c.poly([(1, 8), (12, 1), (23, 8), (21, 9), (3, 9)])
    c.shade(roof, R5("8a4a3a"))
    for x in (4, 19):
        c.shade(c.rect(x, 9, x + 1, 14), R5("8a6a44"))
    seeds = c.rect(6, 13, 18, 14)
    c.fill(seeds, R5("e0c060")[3])
    c.outline()
    save_canvas(c, "b20_feeder")
    # скворечник на столбе
    c = Canvas(20, 46)
    c.shade(c.rect(9, 20, 11, 45), R5("7a5a3a"))
    box = c.rect(3, 6, 17, 22)
    c.shade(box, R5("b08a5a"))
    roof = c.poly([(1, 7), (10, 0), (19, 7)])
    c.shade(roof, R5("6a8a5a"))
    hole = c.mask()
    c.ellipse(10, 12, 2.5, 2.5, hole)
    c.fill(hole, (40, 28, 30, 255))
    c.dot(10, 17, R5("7a5a3a")[1])
    c.outline()
    save_canvas(c, "b20_birdhouse")
    # купалка
    c = Canvas(32, 26)
    c.shade(c.rect(13, 12, 19, 25), R5("9a9690"))
    bowl = c.mask()
    c.ellipse(16, 10, 14, 5, bowl)
    c.shade(bowl, R5("a8a49c"))
    w = c.mask()
    c.ellipse(16, 9, 11, 3, w)
    c.shade(w, R5("7ac0d8"), flat=0.5)
    c.dot(12, 8, (240, 255, 255, 255))
    c.outline()
    save_canvas(c, "b20_bath")
    # присада для сов
    c = Canvas(30, 56)
    c.shade(c.rect(13, 8, 17, 55), R5("6a4a30"))
    c.shade(c.rect(3, 8, 27, 11), R5("7a5a3a"))
    c.line([(15, 22), (24, 12)], R5("6a4a30")[2], 2)
    c.outline()
    save_canvas(c, "b20_owlpost")
    # улей
    c = Canvas(28, 34)
    legs(c, [4, 22], 26, 33, "6a4a30")
    for i, colr in enumerate(["e8c060", "d8b050", "e8c060"]):
        wood_box(c, 3, 10 + i * 6, 25, 16 + i * 6, colr)
    roof = c.poly([(1, 11), (14, 3), (27, 11)])
    c.shade(roof, R5("8a5a3a"))
    c.fill(c.rect(11, 25, 17, 27), (40, 30, 20, 255))
    c.outline()
    for x, y in [(6, 6), (20, 4), (24, 14)]:
        c.dot(x, y, (250, 220, 60, 255))
        c.dot(x + 1, y, (40, 30, 20, 255))
    save_canvas(c, "b20_beehive")
    # компост
    c = Canvas(36, 28)
    for y in (8, 14, 20):
        wood_box(c, 2, y, 34, y + 5, "8a6a44")
    heap = c.mask()
    c.ellipse(18, 8, 14, 5, heap)
    heap &= c.rect(0, 0, 36, 9)
    c.shade(heap, R5("5a4a2a"))
    for x, y in [(12, 5), (20, 4), (25, 6)]:
        c.dot(x, y, R5("6aa040")[3])
    c.outline()
    save_canvas(c, "b20_compost")
    # бочка для дождя
    c = Canvas(26, 34)
    b = c.mask()
    c.ellipse(13, 18, 11, 14, b)
    b &= c.rect(0, 5, 26, 33)
    c.shade(b, R5("8a6a44"))
    yy, xx = np.mgrid[0:34, 0:26]
    c.fill(b & ((yy == 10) | (yy == 26)), R5("5a5e68")[2])
    top = c.mask()
    c.ellipse(13, 6, 9, 2.5, top)
    c.shade(top, R5("6ab0d0"), flat=0.5)
    c.outline()
    save_canvas(c, "b20_rain_barrel")
    # пугало
    c = Canvas(34, 52)
    c.shade(c.rect(16, 14, 18, 51), R5("7a5a3a"))
    c.shade(c.rect(3, 20, 31, 22), R5("7a5a3a"))
    shirt = c.poly([(9, 19), (25, 19), (27, 36), (7, 36)])
    c.shade(shirt, R5("5a7ab0"))
    patch = c.rect(18, 26, 22, 30)
    c.shade(patch, R5("d0603a"))
    head = c.mask()
    c.ellipse(17, 12, 6, 6, head)
    c.shade(head, R5("e8d8a8"))
    hat = c.poly([(8, 8), (26, 8), (21, 6), (19, 0), (15, 0), (13, 6)])
    c.shade(hat, R5("c8a050"))
    for x in (4, 30):
        c.line([(x, 21), (x + (2 if x < 10 else -2), 26)], R5("e8d070")[3])
    c.dot(15, 12, (40, 30, 30, 255))
    c.dot(19, 12, (40, 30, 30, 255))
    c.outline()
    save_canvas(c, "b20_scarecrow")
    # бельевая верёвка
    c = Canvas(64, 36)
    for x in (2, 60):
        c.shade(c.rect(x, 4, x + 2, 35), R5("7a5a3a"))
    c.line([(3, 6), (32, 10), (61, 6)], R5("e8e0c8")[2])
    for x0, colr in [(10, "f4f4f0"), (24, "d85a5a"), (40, "5a8ad8"), (50, "f0d060")]:
        y0 = 7 + (3 if 18 < x0 < 46 else 1)
        sh = c.poly([(x0, y0), (x0 + 8, y0), (x0 + 8, y0 + 12), (x0, y0 + 12)])
        c.shade(sh, R5(colr))
    c.outline()
    save_canvas(c, "b20_clothesline")


def walls():
    c = Canvas(32, 24)
    stone_box(c, 0, 4, 32, 24, "8a8680")
    c.fill(c.rect(0, 2, 32, 5), R5("a8a49c")[3])
    c.outline()
    save_canvas(c, "w20_stone_wall")
    c = Canvas(32, 24)
    m = c.rect(0, 4, 32, 24)
    c.shade(m, R5("b0603a"), flat=0.3)
    yy, xx = np.mgrid[0:24, 0:32]
    c.fill(m & (((yy - 4) % 4 == 3) | (((xx + ((yy - 4) // 4) * 4) % 8) == 7)), R5("d8d0c0")[1])
    c.fill(c.rect(0, 2, 32, 5), R5("a8a49c")[3])
    c.outline()
    save_canvas(c, "w20_brick_wall")
    c = Canvas(32, 26)
    h = c.mask()
    for x in range(2, 32, 6):
        c.ellipse(x + 2, 12, 6, 9, h)
    h &= c.rect(0, 0, 32, 26)
    c.shade(h, R5("4a8a3a"))
    r = np.random.default_rng(4)
    for i in range(30):
        x, y = r.integers(1, 31), r.integers(4, 22)
        if h[y, x]:
            c.dot(x, y, R5("4a8a3a")[r.integers(0, 5)])
    c.outline()
    save_canvas(c, "w20_hedge")
    c = Canvas(32, 20)
    for x in (2, 15, 28):
        c.shade(c.rect(x, 0, x + 2, 20), R5("7a5a3a"))
    for y in (4, 8, 12):
        c.line([(0, y), (32, y + 1)], R5("b08a50")[2 + (y // 4) % 2], 2)
    c.outline()
    save_canvas(c, "w20_wicker")
    # дорожки — плоские плитки 32x16
    for name, col, kind in [("path_stone", "8a8680", "stone"), ("path_brick", "b0603a", "brick"), ("path_wood", "a07a50", "wood"),
                            ("path_gravel", "9a968c", "gravel"), ("path_marble", "eceae4", "marble")]:
        c = Canvas(32, 16)
        m = c.rect(0, 0, 32, 16)
        rm = R5(col)
        c.fill(m, rm[2])
        yy, xx = np.mgrid[0:16, 0:32]
        if kind == "stone":
            r = np.random.default_rng(1)
            c.fill(m, rm[1])
            for cx_ in range(2, 32, 8):
                for cy_ in range(2, 16, 7):
                    s = c.mask()
                    c.ellipse(cx_ + r.uniform(0, 3), cy_ + r.uniform(0, 2), r.uniform(3, 4), r.uniform(2.4, 3), s)
                    c.shade(s, rm, gy=0.2)
        elif kind == "brick":
            c.fill(m & ((yy % 4 == 3) | (((xx + (yy // 4) * 4) % 8) == 7)), rm[0])
        elif kind == "wood":
            c.fill(m & (xx % 8 == 7), rm[0])
            c.fill(m & (yy % 5 == 2) & (xx % 8 == 3), rm[1])
        elif kind == "gravel":
            r = np.random.default_rng(2)
            for i in range(60):
                c.dot(r.integers(0, 32), r.integers(0, 16), rm[r.integers(0, 5)])
        elif kind == "marble":
            c.fill(m & ((xx % 16 == 15) | (yy % 16 == 15)), rm[1])
            c.line([(3, 3), (9, 8), (14, 7)], R5("a8a8b0")[2])
        save_canvas(c, "w20_" + name)


def nodes():
    r = np.random.default_rng(11)

    def mound(name, col, w=32, h=18, grains=None, crystals=None, water=False):
        c = Canvas(w, h)
        m = c.mask()
        c.ellipse(w / 2, h * 0.62, w / 2 - 1, h * 0.38, m)
        c.ellipse(w * 0.4, h * 0.5, w * 0.25, h * 0.32, m)
        c.shade(m, R5(col), gy=0.5)
        if water:
            p = c.mask()
            c.ellipse(w * 0.62, h * 0.7, w * 0.22, h * 0.15, p)
            c.shade(p & m, R5("6a9ab0"), flat=0.5)
        if grains:
            for i in range(int(w * 0.8)):
                x, y = r.integers(2, w - 2), r.integers(2, h - 2)
                if m[y, x]:
                    c.dot(x, y, R5(grains)[r.integers(0, 5)])
        if crystals:
            for x0 in (w * 0.3, w * 0.5, w * 0.68):
                hh = r.uniform(4, 7)
                cm = c.poly([(x0 - 2, h * 0.55), (x0, h * 0.55 - hh), (x0 + 2, h * 0.55)])
                c.shade(cm, R5(crystals))
        c.outline()
        save_canvas(c, name)

    mound("node_clay", "8a7060", water=True, grains="a08070")
    mound("node_red_clay", "a05a3a", grains="b86a4a")
    mound("node_white_clay", "d8d0c4", grains="e8e0d4")
    mound("node_sand", "e0c890", grains="f0d8a8")
    mound("node_black_sand", "3a3438", grains="5a5458")
    mound("node_quartz_sand", "e8e4dc", grains="ffffff")
    mound("node_peat", "4a3a2a", water=True, grains="5a4a32")
    mound("node_salt", "c8c0b0", crystals="f4f4f0")
    mound("node_sulfur", "6a6460", crystals="e8d030")
    mound("node_saltpeter", "6a6a70", crystals="e8f0f0")
    mound("node_obsidian", "4a4448", crystals="2a2240")
    # гравий и камни
    for name, cols in [("node_gravel", ["8a8680", "9a968c", "7a7670"]), ("node_stones", ["d8d0b8", "a08a82", "4a5260", "f4f2ea"]),
                       ("node_flint", ["4a4a52", "6a6a72"]), ("node_coal", ["2a2a30", "3a3a42", "1e1e24"])]:
        c = Canvas(30, 18)
        for i in range(7 if name != "node_stones" else 5):
            m = c.mask()
            c.ellipse(r.uniform(5, 25), r.uniform(8, 14), r.uniform(2.5, 4.5), r.uniform(2, 3.2), m)
            c.shade(m, R5(cols[i % len(cols)]))
        c.outline()
        save_canvas(c, name)
    # растения: лён, хлопок, конопля, осока
    for name, stem, top, n, hgt in [("node_flax", "7a9a50", "6a8ad8", 9, 28), ("node_hemp", "4a7a3a", "5a9a40", 7, 34), ("node_fiber", "b0a060", None, 12, 20)]:
        c = Canvas(30, hgt + 4)
        for i in range(n):
            x = 4 + i * (22 / n) + r.uniform(-1, 1)
            hh = hgt * r.uniform(0.7, 1.0)
            c.line([(x, hgt + 2), (x + r.uniform(-3, 3), hgt + 2 - hh)], R5(stem)[r.integers(1, 4)])
            if top and name == "node_flax":
                c.dot(x + r.uniform(-2, 2), hgt + 2 - hh, R5(top)[3])
            if name == "node_hemp":
                y0 = hgt + 2 - hh * 0.7
                for s in (-1, 1):
                    c.line([(x, y0), (x + s * 3, y0 - 2)], R5(top)[2])
        c.outline()
        save_canvas(c, name)
    c = Canvas(28, 28)
    bush = c.mask()
    c.ellipse(14, 16, 12, 10, bush)
    c.shade(bush, R5("5a7a40"))
    for x, y in [(8, 10), (16, 8), (20, 14), (11, 17), (17, 20), (6, 18)]:
        b = c.mask()
        c.ellipse(x, y, 2.6, 2.4, b)
        c.shade(b, R5("f8f8f4"))
    c.outline()
    save_canvas(c, "node_cotton")
    # коконы на ветке
    c = Canvas(26, 30)
    c.line([(2, 4), (24, 6)], R5("6a4a30")[2], 2)
    for x in (7, 14, 20):
        k = c.mask()
        c.ellipse(x, 14 + (x % 3), 3, 5, k)
        c.shade(k, R5("f4f0e0"))
        c.line([(x, 6), (x, 9)], R5("d8d8e0")[3])
    c.outline()
    save_canvas(c, "node_cocoon")
    # дикий улей: пень с сотами
    c = Canvas(28, 30)
    st = c.mask()
    c.rect(4, 12, 24, 29, st)
    c.shade(st, R5("7a5a3a"))
    top = c.mask()
    c.ellipse(14, 12, 10, 3, top)
    c.shade(top, R5("c8a070"), flat=0.5)
    hive = c.mask()
    c.ellipse(14, 8, 7, 7, hive)
    c.shade(hive, R5("d8a840"))
    yy, xx = np.mgrid[0:30, 0:28]
    c.fill(hive & (yy % 3 == 0), R5("d8a840")[1])
    c.fill(c.rect(13, 10, 16, 12), (40, 30, 20, 255))
    c.outline()
    save_canvas(c, "node_hive")
    # смоляной натёк на пне
    c = Canvas(26, 24)
    st = c.rect(3, 8, 23, 23)
    c.shade(st, R5("8a5a3a"))
    top = c.mask()
    c.ellipse(13, 8, 10, 3, top)
    c.shade(top, R5("d8b080"), flat=0.5)
    for x, y in [(7, 14), (16, 12), (12, 19)]:
        d = c.mask()
        c.ellipse(x, y, 2.4, 3, d)
        c.shade(d, R5("e89a20"))
        c.dot(x - 1, y - 1, (255, 240, 200, 255))
    c.outline()
    save_canvas(c, "node_amber")


def ore_rocks():
    """Скалы с новыми рудами: берём волшебную скалу ore18_mana и перекрашиваем кристаллы в цвет руды."""
    from PIL import Image
    import colorsys as cs
    for frame in (0, 1):
        src = Image.open(os.path.join(ART, "ore18_mana_%d.png" % frame)).convert("RGBA")
        a = np.array(src)
        for m in METALS:
            out = a.copy()
            tr, tg, tb = hx(m[3])
            th, tl, ts = cs.rgb_to_hls(tr / 255, tg / 255, tb / 255)
            for y in range(a.shape[0]):
                for x in range(a.shape[1]):
                    r_, g_, b_, al = a[y, x]
                    if al == 0:
                        continue
                    h_, l_, s_ = cs.rgb_to_hls(r_ / 255, g_ / 255, b_ / 255)
                    if s_ > 0.35 and 0.55 < h_ < 0.85:
                        nr, ng, nb = cs.hls_to_rgb(th, min(0.95, max(0.08, l_ * (tl / 0.55))), min(1.0, ts * 0.9 + 0.1))
                        out[y, x] = (int(nr * 255), int(ng * 255), int(nb * 255), al)
            Image.fromarray(out).save(os.path.join(ART, "ore18_%s_%d.png" % (m[0], frame)))
    # значки руды для mining_db (icon_ore_<id>) — те же, что m20_ore_<id>
    for m in METALS:
        src = os.path.join(ART, "m20_ore_%s.png" % m[0])
        Image.open(src).save(os.path.join(ART, "icon_ore_%s.png" % m[0]))


# ======================================================================== mats_db.gd
def gd(v):
    return BD.gd_value(v)


def write_db():
    L = ["extends RefCounted",
         "## Материалы, мастерские, ловушки, постройки и места добычи (v20) — СГЕНЕРИРОВАНО tools/mats_design.py.",
         "## Правки — в mats_design.py, потом `python tools/mats_design.py --write` (значки: --art).",
         "## MATS: id -> [имя, вес, цена, значок, раздел, свойства для котла, [ширина, высота] в сумке, стопка]",
         "", "const MATS: Dictionary = {"]
    for mid in ORDER:
        d = MATS[mid]
        L.append("\t%s: [%s, %s, %s, %s, %s, %s, %s, %s]," % (gd(mid), gd(d["name"]), gd(float(d["w"])), gd(int(d["price"])), gd(d["icon"]), gd(d["cat"]),
                                                              gd(d["props"]), gd(d["size"]), gd(int(d["stack"]))))
    L.append("}")
    L.append("const ORDER: Array = %s" % gd(ORDER))
    L.append("## Мастерские: вид -> [название, звук работы]; рецепты RECIPES[вид] = [[что, сколько, {что нужно: сколько}], ...]")
    L.append("## \"@plank\" — любая доска, \"@wood\" — любая чурка, \"@yarn\" — любая пряжа, \"@fur\" — любой пух/шерсть")
    L.append("const STATIONS: Dictionary = %s" % gd(STATIONS))
    L.append("const RECIPES: Dictionary = {")
    for k, v in R.items():
        L.append("\t%s: %s," % (gd(k), gd(v)))
    L.append("}")
    L.append("const GROUPS: Dictionary = {\"@plank\": \"plank_\", \"@wood\": \"wood_\", \"@yarn\": \"yarn_\", \"@dye\": \"dye_\"}")
    L.append("const FUR_IDS: Array = %s" % gd([f[0] for f in FUR if f[0] not in ("antler_shed", "golden_antler", "horn_shaving", "fish_scale", "hedgehog_quill", "boar_bristle", "cat_whisker")]))
    L.append("## Ловушки: вид -> [название, кого ловит, приманка, часов до поимки в среднем]")
    L.append("const TRAPS: Dictionary = %s" % gd(TRAPS))
    L.append("const BAIT_MAGIC: Array = %s" % gd(BAIT_MAGIC))
    L.append("const BAIT_SEED: Array = %s" % gd(BAIT_SEED))
    L.append("## Что даёт пойманный зверь (вычесать / подобрать сброшенное — и отпустить): [[предмет, от, до, шанс]]")
    L.append("const LOOT: Dictionary = %s" % gd(LOOT))
    L.append("## Места добычи: вид -> [название, картинка, {биом: сколько на регион}, [[предмет, от, до, шанс]], дней до нового, звук]")
    L.append("const NODES: Dictionary = {")
    for k, v in NODES.items():
        L.append("\t%s: %s," % (gd(k), gd(v)))
    L.append("}")
    L.append("## Камни: что ещё выпадает по биому [[предмет, шанс]]")
    L.append("const ROCK_EXTRA: Dictionary = %s" % gd(ROCK_EXTRA))
    L.append("## Новые руды для mining_db.ORES: металл -> {биом: вес}; названия руд — в MATS (ore_<металл>)")
    L.append("const ORE_DEPOSITS: Dictionary = %s" % gd(ORE_DEPOSITS))
    L.append("## Рубка: порода -> [[предмет, от, до, шанс]] (кроме брёвен и саженцев)")
    L.append("const CHOP_EXTRA: Dictionary = %s" % gd(CHOP_EXTRA))
    L.append("## Постройки: вид -> [название, картинка, вес набора, преграда [x, y, w, h], вкладка, {материалы}]")
    L.append("const BUILD: Dictionary = {")
    for k, v in BUILD.items():
        L.append("\t%s: %s," % (gd(k), gd(v)))
    L.append("}")
    L.append("const TABS: Array = %s" % gd(TABS))
    L.append("const FLAT: Array = %s" % gd(FLAT))
    L.append("## Расширение участка — материалами (колышки, верёвка, камни), а не деньгами")
    L.append("const PLOT_NEED: Array = %s" % gd(PLOT_NEED))
    L.append(TAIL)
    with open(os.path.join(GAME, "mats_db.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(L))


TAIL = '''

static func has(id: String) -> bool:
	return MATS.has(id)


static func name(id: String) -> String:
	return String((MATS[id] as Array)[0]) if MATS.has(id) else id


static func weight(id: String) -> float:
	return float((MATS[id] as Array)[1])


static func price(id: String) -> int:
	return int((MATS[id] as Array)[2])


static var _icons: Dictionary = {}


static func icon(id: String) -> Texture2D:
	if not _icons.has(id):
		var p: String = "res://art/%s.png" % String((MATS[id] as Array)[3])
		_icons[id] = load(p) if ResourceLoader.exists(p) else load("res://art/icon_pack.png")
	return _icons[id]


static func cat(id: String) -> String:
	return String((MATS[id] as Array)[4])


static func props(id: String) -> Dictionary:
	return ((MATS[id] as Array)[5] as Dictionary).duplicate() if MATS.has(id) else {}


static func is_ingredient(id: String) -> bool:
	return MATS.has(id) and not ((MATS[id] as Array)[5] as Dictionary).is_empty()


static func cell_size(id: String) -> Vector2i:
	var s: Array = (MATS[id] as Array)[6]
	return Vector2i(int(s[0]), int(s[1]))


static func stack(id: String) -> int:
	return int((MATS[id] as Array)[7])


## Подходит ли предмет под «группу» в рецепте (@plank — любая доска и т.п.)
static func in_group(id: String, g: String) -> bool:
	if g == "@fur":
		return FUR_IDS.has(id)
	return GROUPS.has(g) and id.begins_with(String(GROUPS[g])) and MATS.has(id)


## Сколько у героини того, что нужно (с учётом групп)
static func have(inv: Dictionary, need: String) -> int:
	if not need.begins_with("@"):
		return int(inv.get(need, 0))
	var n: int = 0
	for k in inv.keys():
		if in_group(String(k), need):
			n += int(inv[k])
	return n


## Значок для того, что нужно: у группы — первая подходящая вещь (из сумки, если есть)
static func need_icon(inv: Dictionary, need: String) -> String:
	if not need.begins_with("@"):
		return need
	for k in inv.keys():
		if int(inv[k]) > 0 and in_group(String(k), need):
			return String(k)
	match need:
		"@plank":
			return "plank_tree_a"
		"@wood":
			return "wood_tree_a"
		"@yarn":
			return "yarn_rabbit"
		"@fur":
			return "rabbit_fluff"
	return "dye_red"


static func need_name(need: String) -> String:
	return {"@plank": "любые доски", "@wood": "любые чурки", "@yarn": "любая пряжа", "@fur": "любой пух или шерсть", "@dye": "любая краска"}.get(need, need)
'''


def preview(path):
    from PIL import Image
    ids = [m for m in ORDER if MATS[m]["tpl"] != "feather"]
    cols = 24
    rows = (len(ids) + cols - 1) // cols
    big = Image.new("RGBA", (cols * 26, rows * 26), (232, 220, 196, 255))
    for i, mid in enumerate(ids):
        im = Image.open(os.path.join(ART, MATS[mid]["icon"] + ".png"))
        big.paste(im, ((i % cols) * 26 + 1, (i // cols) * 26 + 1), im)
    big = big.resize((big.width * 2, big.height * 2), Image.NEAREST)
    big.save(path)


def preview_world(path):
    from PIL import Image
    names = ["st20_sawmill", "st20_kiln", "st20_smelter", "st20_anvil", "st20_spinning", "st20_dye_vat", "st20_mason", "st20_jeweler", "st20_press",
             "trap20_small", "trap20_cage", "trap20_pen", "trap20_bird", "trap20_fish", "trap20_magic", "trap20_bat",
             "b20_feeder", "b20_birdhouse", "b20_bath", "b20_owlpost", "b20_beehive", "b20_compost", "b20_rain_barrel", "b20_scarecrow", "b20_clothesline",
             "w20_stone_wall", "w20_brick_wall", "w20_hedge", "w20_wicker", "w20_path_stone", "w20_path_brick", "w20_path_wood", "w20_path_gravel", "w20_path_marble",
             "node_clay", "node_red_clay", "node_white_clay", "node_sand", "node_black_sand", "node_quartz_sand", "node_gravel", "node_flint", "node_peat",
             "node_salt", "node_sulfur", "node_saltpeter", "node_coal", "node_obsidian", "node_stones", "node_flax", "node_cotton", "node_hemp", "node_fiber",
             "node_cocoon", "node_hive", "node_amber", "ore18_copper_0", "ore18_gold_0", "ore18_cobalt_0"]
    big = Image.new("RGBA", (12 * 76, ((len(names) + 11) // 12) * 66), (120, 150, 90, 255))
    for i, n in enumerate(names):
        im = Image.open(os.path.join(ART, n + ".png"))
        big.paste(im, ((i % 12) * 76 + 2, (i // 12) * 66 + 64 - im.height), im)
    big = big.resize((big.width * 2, big.height * 2), Image.NEAREST)
    big.save(path)


if __name__ == "__main__":
    a = sys.argv[1:]
    allp = not any(x in a for x in ("--art", "--write", "--preview", "--preview2"))
    if allp or "--art" in a:
        for mid in ORDER:
            draw_icon(mid)
        st_sawmill(); st_kiln(); st_smelter(); st_anvil(); st_spinning(); st_dye_vat(); st_mason(); st_jeweler(); st_press()
        trap("trap20_small", 22, 18, "cage"); trap("trap20_cage", 34, 26, "cage"); trap("trap20_pen", 64, 28, "pen")
        trap("trap20_bird", 18, 16, "bird"); trap("trap20_fish", 30, 14, "fish"); trap("trap20_magic", 30, 22, "magic"); trap("trap20_bat", 26, 30, "bat")
        bird_props(); walls(); nodes(); ore_rocks()
        print("art", len(ORDER))
    if allp or "--write" in a:
        write_db()
        print("mats_db.gd", len(ORDER), "материалов,", sum(len(v) for v in R.values()), "рецептов,", len(BUILD), "построек")
    if "--preview" in a:
        preview(a[a.index("--preview") + 1])
    if "--preview2" in a:
        preview_world(a[a.index("--preview2") + 1])
    print("MATS DONE")
