"""Птицы v20: 50 видов. Одна таблица -> спрайты (art/bird_<id>.png, 12 кадров), значки перьев (art/icon_feather_<id>.png),
голоса (audio/bird_<id>.wav, свои для каждого вида) и birds_db.gd для игры.
Запуск из папки game:  python tools/birds_design.py [--art] [--audio] [--write]   (без флагов — всё).
"""
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(__file__))
from px import Canvas, ramp, hx, sheet, OUTLINE, mix  # noqa: E402

GAME = os.path.join(os.path.dirname(__file__), "..")
ART = os.path.join(GAME, "art")
AUD = os.path.join(GAME, "audio")

# Биомы (как в world_data.gd)
HOME, MEADOW, SPIDER, GOTHIC, KNIGHT, ELF, MAGE, ORC, DWARF, CATS = range(10)
UNICORN, GROTTO, BIRCH, PINE, AUTUMN, SWAMP, FIELD, JAPAN, BEACH, SEA = range(10, 20)

# размеры кадра по классу
FRAME = {"s": (24, 20), "m": (32, 26), "l": (44, 36), "xl": (52, 54)}

# Свойства котла (как в recipes_db.gd PROPS)
P = ["Сила", "Тепло", "Покой", "Исцеление", "Свежесть", "Холод", "Чары", "Огонь", "Жгучесть", "Свет", "Тьма", "Сон"]

# id: [имя, размер, форма, цвета, биомы {биом: вес}, когда (day/night/dusk), голос, пугливость 0..1, редкость 0..1 (1 — часто),
#      свойства пера, цена пера, где держится (ground/tree/water)]
# цвета: back, belly, head, wing, tail, beak, legs + необязательные: cap, cheek, throat, breast, mask, bar, ring, crest, spots, eye
B = {
    "sparrow": ["Воробей", "s", "song", dict(back="8a6a4a", belly="c8bca8", head="7a6a5e", cap="8a7a6a", cheek="d8d0c0", throat="3a3030", wing="6e5038", bar="e0d8c8", tail="5e4a38", beak="4a4038", legs="a07a62"),
                {HOME: 6, MEADOW: 4, CATS: 6, FIELD: 4, KNIGHT: 4, ORC: 2, DWARF: 2}, "day", "sparrow", 0.45, 1.0, {"Сила": 1}, 2, "ground"],
    "great_tit": ["Большая синица", "s", "song", dict(back="7a8a5a", belly="f0d040", head="2a2a32", cheek="f4f4f0", wing="5a6a7a", bar="e8eef0", tail="4a5a6a", beak="2a2a30", legs="6a7080", stripe="2a2a32"),
                  {HOME: 4, MEADOW: 3, BIRCH: 5, AUTUMN: 3, ELF: 3}, "day", "tit", 0.35, 0.9, {"Свежесть": 1, "Сила": 1}, 3, "tree"],
    "blue_tit": ["Лазоревка", "s", "song", dict(back="8aa070", belly="f0dc50", head="f4f4f0", cap="4a8ad0", mask="2a3a6a", wing="4a7ac0", bar="f0f4f8", tail="3a6ab0", beak="2a2a30", legs="6a7890"),
                 {BIRCH: 5, MEADOW: 2, ELF: 3, HOME: 2}, "day", "blue_tit", 0.35, 0.8, {"Холод": 1, "Свежесть": 1}, 3, "tree"],
    "robin": ["Зарянка", "s", "song", dict(back="7a6a4e", belly="ece4d4", head="7a6a4e", throat="e87830", breast="e87830", wing="6a5a40", tail="6a5a40", beak="2e2a28", legs="8a6a5a"),
              {HOME: 4, BIRCH: 3, AUTUMN: 4, PINE: 2, ELF: 2}, "day", "robin", 0.3, 0.85, {"Тепло": 1, "Исцеление": 1}, 3, "ground"],
    "chaffinch": ["Зяблик", "s", "song", dict(back="8a6a50", belly="e0a090", head="6a7e9a", cap="5a6e8e", throat="d88a7a", breast="d88a7a", wing="3a3438", bar="f4f0e8", tail="3a3438", beak="8a8a90", legs="9a7a70"),
                  {BIRCH: 4, PINE: 3, MEADOW: 3, HOME: 2, AUTUMN: 3}, "day", "chaffinch", 0.4, 0.9, {"Свежесть": 1, "Тепло": 1}, 3, "tree"],
    "goldfinch": ["Щегол", "s", "song", dict(back="b08a5a", belly="f0e4d0", head="f4f0e8", mask="d82a2a", cap="2a2a2a", wing="2a2a2a", bar="f0d020", tail="2a2a2a", beak="e8d8c8", legs="b09080"),
                  {FIELD: 5, MEADOW: 4, HOME: 2}, "day", "goldfinch", 0.45, 0.6, {"Свет": 1, "Чары": 1}, 6, "tree"],
    "bullfinch": ["Снегирь", "s", "song", dict(back="8a8a96", belly="e85a4a", head="e85a4a", cap="1e1e24", wing="2a2a30", bar="f0f0f0", tail="1e1e24", beak="2a2a30", legs="5a5a60", throat="1e1e24"),
                  {PINE: 5, BIRCH: 2, MAGE: 2}, "day", "bullfinch", 0.3, 0.6, {"Холод": 1, "Тепло": 1}, 5, "tree"],
    "wren": ["Крапивник", "s", "wren", dict(back="8a5e3a", belly="b89068", head="8a5e3a", wing="7a4e2e", bar="5a3a20", tail="7a4e2e", beak="5a4a3a", legs="b0806a", spots="5a3a20"),
             {PINE: 3, AUTUMN: 3, SPIDER: 3, SWAMP: 2, ELF: 2}, "day", "wren", 0.55, 0.6, {"Сила": 2}, 4, "ground"],
    "nightingale": ["Соловей", "s", "song", dict(back="8a6a4a", belly="d8ccb4", head="8a6a4a", wing="7a5a3a", tail="a0603a", beak="6a5a4a", legs="b09080", ring="e8e0d0"),
                    {BIRCH: 3, MEADOW: 2, ELF: 4, CATS: 2, HOME: 2}, "dusk", "nightingale", 0.6, 0.45, {"Покой": 1, "Сон": 1}, 8, "tree"],
    "lark": ["Жаворонок", "s", "lark", dict(back="9a7a54", belly="e0d0b4", head="9a7a54", crest="8a6a44", wing="7a5a3a", bar="c0a07a", tail="6a4e34", beak="b09070", legs="c0a08a", spots="6a4e34"),
             {FIELD: 6, MEADOW: 4, KNIGHT: 2}, "day", "lark", 0.5, 0.75, {"Свет": 1, "Свежесть": 1}, 4, "ground"],
    "swallow": ["Ласточка", "s", "swallow", dict(back="22306a", belly="f0e8e0", head="22306a", throat="b8402a", wing="1a2450", tail="1a2450", beak="1a1a20", legs="2a2a30"),
                {FIELD: 4, MEADOW: 4, HOME: 3, CATS: 3, KNIGHT: 2}, "day", "swallow", 0.6, 0.7, {"Свежесть": 1, "Свет": 1}, 4, "ground"],
    "starling": ["Скворец", "s", "song", dict(back="2a3a3a", belly="2a2e3a", head="2a3e36", wing="3a3040", tail="2a2a30", beak="e0c040", legs="c08a7a", spots="e8e0c0"),
                 {HOME: 4, MEADOW: 4, CATS: 4, FIELD: 3, KNIGHT: 3}, "day", "starling", 0.45, 0.85, {"Чары": 1, "Тьма": 1}, 3, "ground"],
    "thrush": ["Певчий дрозд", "s", "song", dict(back="8a6e50", belly="f0e4cc", head="8a6e50", wing="7a5e40", tail="7a5e40", beak="5a4a3a", legs="c0a08a", spots="5a3e28"),
               {BIRCH: 3, AUTUMN: 4, PINE: 3, ELF: 2, HOME: 2}, "day", "thrush", 0.45, 0.75, {"Исцеление": 1, "Покой": 1}, 4, "ground"],
    "blackbird": ["Чёрный дрозд", "s", "song", dict(back="24222a", belly="2a282e", head="24222a", wing="1e1c22", tail="1e1c22", beak="f0a020", legs="4a3a2a", ring="f0b030"),
                  {HOME: 4, BIRCH: 3, AUTUMN: 3, GOTHIC: 4, CATS: 2}, "day", "blackbird", 0.4, 0.8, {"Тьма": 1, "Покой": 1}, 4, "ground"],
    "wagtail": ["Трясогузка", "s", "song", dict(back="8a8e96", belly="f4f4f4", head="f4f4f4", cap="1e1e22", throat="1e1e22", wing="3a3a3e", bar="f4f4f4", tail="1e1e22", beak="1e1e22", legs="1e1e22"),
                {SWAMP: 3, BEACH: 3, MEADOW: 3, HOME: 2, CATS: 2}, "day", "wagtail", 0.5, 0.7, {"Свежесть": 2}, 3, "ground", {"tail": 1.6}],
    "oriole": ["Иволга", "s", "oriole", dict(back="f0c820", belly="f4d830", head="f0c820", mask="2a2a2a", wing="1e1e1e", bar="f0d040", tail="1e1e1e", beak="c86a6a", legs="6a6a70"),
               {AUTUMN: 4, BIRCH: 3, ELF: 3}, "day", "oriole", 0.65, 0.35, {"Свет": 2, "Тепло": 1}, 10, "tree"],
    "waxwing": ["Свиристель", "s", "song", dict(back="b08a7a", belly="d4b4a0", head="c09a88", crest="b08a7a", mask="1e1a1e", throat="1e1a1e", wing="5a4a50", bar="e83a2a", tail="4a4048", tailtip="f0d020", beak="2a2a2a", legs="2a2a2a"),
                 {PINE: 3, AUTUMN: 3, MAGE: 2, BIRCH: 2}, "day", "waxwing", 0.35, 0.45, {"Холод": 1, "Чары": 1}, 7, "tree"],
    "kingfisher": ["Зимородок", "s", "kingfisher", dict(back="1ab0d0", belly="f08a3a", head="2a80c0", cheek="f08a3a", throat="f4f0e8", wing="1a70b0", bar="40c8e8", tail="1aa0c8", beak="2a2a2a", legs="e05a3a", spots="60d8f0"),
                   {SWAMP: 4, MEADOW: 1, BEACH: 2, JAPAN: 2}, "day", "kingfisher", 0.7, 0.3, {"Холод": 1, "Свет": 1, "Свежесть": 1}, 12, "water", {"beak": 1.6, "tail": 0.6}],
    "hoopoe": ["Удод", "m", "hoopoe", dict(back="d8a070", belly="e8b888", head="d8a070", crest="e09050", cresttip="1e1e1e", wing="1e1e1e", bar="f4f0e8", tail="1e1e1e", beak="3a3030", legs="5a5050"),
               {FIELD: 4, ORC: 3, MEADOW: 2, BEACH: 1}, "day", "hoopoe", 0.55, 0.35, {"Огонь": 1, "Сила": 1}, 9, "ground", {"beak": 1.5, "crest": 2.0}],
    "jay": ["Сойка", "m", "jay", dict(back="c09a88", belly="d8b8a8", head="c8a898", cap="e0d0c8", mask="1e1e22", wing="2a2a30", bar="3a7ad0", tail="1e1e22", beak="2a2a2a", legs="a08070", spots="f4f4f4"),
            {AUTUMN: 4, PINE: 3, BIRCH: 2, ELF: 2, GOTHIC: 2}, "day", "jay", 0.6, 0.6, {"Чары": 1, "Холод": 1}, 6, "tree"],
    "magpie": ["Сорока", "m", "magpie", dict(back="1e1e26", belly="f4f4f4", head="1e1e26", wing="1e2440", bar="f4f4f4", tail="1e2a3e", beak="1e1e1e", legs="1e1e1e"),
               {HOME: 3, MEADOW: 3, CATS: 3, FIELD: 3, KNIGHT: 3, ORC: 2}, "day", "magpie", 0.55, 0.8, {"Чары": 1, "Тьма": 1}, 4, "ground", {"tail": 2.2}],
    "crow": ["Серая ворона", "m", "crow", dict(back="8a8a90", belly="8a8a90", head="1e1e22", throat="1e1e22", wing="1e1e22", tail="1e1e22", beak="1e1e22", legs="1e1e22"),
             {GOTHIC: 5, HOME: 2, ORC: 4, CATS: 2, KNIGHT: 2, DWARF: 2, FIELD: 2}, "day", "crow", 0.5, 0.85, {"Тьма": 1, "Сила": 1}, 2, "ground"],
    "raven": ["Ворон", "l", "raven", dict(back="1e1c26", belly="22202a", head="1e1c26", wing="181620", bar="2a2a40", tail="181620", beak="1a1a1e", legs="1a1a1e"),
              {GOTHIC: 5, PINE: 2, SPIDER: 3, DWARF: 2}, "day", "raven", 0.6, 0.45, {"Тьма": 2, "Чары": 1}, 8, "ground", {"beak": 1.3}],
    "cuckoo": ["Кукушка", "m", "cuckoo", dict(back="7a7e8a", belly="e8e4dc", head="7a7e8a", wing="6a6e7a", tail="5a5e6a", beak="3a3a3a", legs="e0c040", ring="f0c040", bars="4a4a52"),
               {BIRCH: 4, PINE: 3, AUTUMN: 3, ELF: 2}, "day", "cuckoo", 0.7, 0.4, {"Сон": 1, "Чары": 1}, 7, "tree", {"tail": 1.6}],
    "woodpecker": ["Пёстрый дятел", "m", "woodpecker", dict(back="1e1e22", belly="f0ece4", head="f0ece4", cap="1e1e22", nape="d82a2a", mask="1e1e22", wing="1e1e22", bar="f4f4f4", tail="1e1e22", vent="d82a2a", beak="4a4a4a", legs="5a5a5a"),
                   {PINE: 4, BIRCH: 4, AUTUMN: 3, ELF: 2}, "day", "woodpecker", 0.5, 0.6, {"Сила": 2}, 5, "tree", {"beak": 1.4}],
    "dove": ["Горлица", "m", "dove", dict(back="b8a8a0", belly="e0ccc8", head="c8b8b8", throat="e0d0d0", wing="a8988a", tail="9a8a80", beak="3a3030", legs="d07070", collar="2a2a2a", spots="6a5a50"),
             {CATS: 5, JAPAN: 3, HOME: 3, KNIGHT: 3, MEADOW: 2, ELF: 2}, "day", "dove", 0.4, 0.8, {"Покой": 2}, 3, "ground"],
    "pheasant": ["Фазан", "l", "pheasant", dict(back="c06a2a", belly="a04a20", head="2a5a4a", mask="d82a2a", collar="f4f4f4", wing="c08a4a", tail="a07040", beak="d0c0a0", legs="8a7a6a", spots="2a1a10", bars="5a3a20"),
                 {FIELD: 3, AUTUMN: 4, MEADOW: 2, KNIGHT: 2}, "day", "pheasant", 0.6, 0.4, {"Огонь": 1, "Тепло": 1, "Сила": 1}, 9, "ground", {"tail": 2.6}],
    "quail": ["Перепел", "s", "quail", dict(back="a07a50", belly="d8b890", head="8a6a48", cap="5a3e28", throat="e8dcc8", wing="8a6a48", tail="7a5a3a", beak="5a4a3a", legs="c0a08a", spots="4a3020", bars="e8dcc8"),
              {FIELD: 6, MEADOW: 3}, "day", "quail", 0.5, 0.6, {"Сила": 1, "Тепло": 1}, 4, "ground", {"tail": 0.4}],
    "partridge": ["Серая куропатка", "m", "partridge", dict(back="8a7a6a", belly="a8a4a0", head="d0884a", throat="d0884a", wing="7a6a58", tail="b0603a", beak="7a7a7a", legs="b0a090", bars="5a4a40", breastpatch="6a3a2a"),
                  {FIELD: 4, MEADOW: 3, AUTUMN: 2, ORC: 2}, "day", "partridge", 0.5, 0.5, {"Тепло": 1, "Сила": 1}, 5, "ground", {"tail": 0.5}],
    "heron": ["Серая цапля", "xl", "heron", dict(back="9aa0aa", belly="e8e8ec", head="f0f0f4", mask="1e1e22", crest="1e1e22", throat="e8e8ec", wing="7a8090", bar="2a2a30", tail="8a909a", beak="e0b040", legs="b09a60", spots="2a2a30"),
              {SWAMP: 6, BEACH: 2, JAPAN: 2, MEADOW: 1}, "day", "heron", 0.65, 0.4, {"Холод": 1, "Покой": 1, "Свежесть": 1}, 8, "water", {"beak": 2.2, "neck": 2.0, "leg": 2.4}],
    "crane": ["Японский журавль", "xl", "crane", dict(back="f4f4f6", belly="f4f4f6", head="f4f4f6", cap="d82a2a", throat="1e1e22", mask="1e1e22", wing="f4f4f6", bar="1e1e22", tail="1e1e22", beak="8a9a7a", legs="2a2a30"),
              {JAPAN: 5, SWAMP: 1}, "day", "crane", 0.7, 0.25, {"Чары": 1, "Покой": 1, "Свет": 1}, 18, "water", {"beak": 1.8, "neck": 2.2, "leg": 2.6}],
    "swan": ["Лебедь-шипун", "l", "swan", dict(back="f6f6f8", belly="f0f0f4", head="f6f6f8", wing="eaeaf0", tail="eaeaf0", beak="f07a2a", knob="1e1e22", legs="2a2a2a"),
             {SWAMP: 3, KNIGHT: 2, ELF: 2, UNICORN: 2}, "day", "swan", 0.5, 0.35, {"Свет": 1, "Покой": 1, "Исцеление": 1}, 14, "water", {"neck": 2.4}],
    "goose": ["Серый гусь", "l", "goose", dict(back="8a8270", belly="c8c0b0", head="9a9280", wing="7a7260", bar="d8d0c0", tail="6a6250", beak="f09060", legs="f09080", bars="b0a890"),
              {MEADOW: 3, SWAMP: 4, FIELD: 2, KNIGHT: 2}, "day", "goose", 0.45, 0.55, {"Сила": 1, "Тепло": 1}, 5, "ground", {"neck": 1.4}],
    "gull": ["Чайка", "m", "gull", dict(back="a8b0bc", belly="f6f6f8", head="f6f6f8", wing="98a2b0", bar="1e1e22", tail="f6f6f8", beak="f0c030", legs="f0a080"),
             {BEACH: 8, SEA: 6, SWAMP: 1}, "day", "gull", 0.45, 0.9, {"Свежесть": 1, "Холод": 1}, 3, "ground"],
    "sandpiper": ["Кулик-перевозчик", "s", "song", dict(back="8a7a62", belly="f4f0e8", head="8a7a62", wing="7a6a52", bar="f4f0e8", tail="6a5a42", beak="3a3430", legs="a0a070", ring="f4f0e8", spots="5a4a38"),
                  {BEACH: 6, SWAMP: 4}, "day", "sandpiper", 0.55, 0.7, {"Свежесть": 1}, 3, "ground", {"beak": 1.4, "leg": 1.4}],
    "bee_eater": ["Золотистая щурка", "s", "bee_eater", dict(back="b05a2a", belly="40b0b0", head="b05a2a", throat="f0d020", mask="1e1e22", wing="5aa040", bar="d0a030", tail="40a070", beak="1e1e22", legs="5a5040"),
                  {FIELD: 3, ORC: 3, BEACH: 2, AUTUMN: 1}, "day", "bee_eater", 0.6, 0.35, {"Огонь": 1, "Свет": 1, "Жгучесть": 1}, 11, "tree", {"beak": 1.4, "tail": 1.4}],
    "crossbill": ["Клёст-еловик", "s", "song", dict(back="d0503a", belly="e06a4a", head="d0503a", wing="5a3a30", bar="7a5a40", tail="4a3028", beak="4a4040", legs="5a4a40"),
                  {PINE: 6, DWARF: 2}, "day", "crossbill", 0.35, 0.5, {"Огонь": 1, "Холод": 1}, 6, "tree"],
    "nuthatch": ["Поползень", "s", "song", dict(back="7a8eaa", belly="e8b890", head="7a8eaa", throat="f4f0e8", mask="1e1e26", wing="6a7e9a", tail="5a6e8a", beak="3a3a40", legs="a08a70", vent="c86a3a"),
                 {BIRCH: 3, AUTUMN: 4, ELF: 3, PINE: 2}, "day", "nuthatch", 0.3, 0.6, {"Сила": 1, "Свежесть": 1}, 4, "tree", {"beak": 1.3, "tail": 0.6}],
    "white_eye": ["Белоглазка мэдзиро", "s", "song", dict(back="9ab040", belly="e8e4c8", head="a8bc4a", throat="e8d040", wing="7a9030", tail="6a8028", beak="3a3a3a", legs="5a6a5a", ring="fafafa"),
                  {JAPAN: 7, UNICORN: 1}, "day", "white_eye", 0.35, 0.7, {"Свежесть": 1, "Чары": 1}, 6, "tree"],
    "rosefinch": ["Розовый чечевичник", "s", "song", dict(back="c86a8a", belly="f0a8c0", head="e05a8a", wing="8a4a5e", bar="f0c8d8", tail="7a3e50", beak="8a6a6a", legs="9a7a70"),
                  {UNICORN: 6, ELF: 2, MAGE: 1}, "day", "rosefinch", 0.4, 0.5, {"Чары": 1, "Исцеление": 1}, 9, "tree"],
    "mandarin_duck": ["Утка-мандаринка", "m", "mandarin", dict(back="6a4a3a", belly="f4f0f0", head="2a6a5a", cap="c84a2a", cheek="f4e8d8", mask="f4f4f4", throat="e08a3a", breast="6a2a5a", wing="5a4a6a", bar="e0802a", tail="3a3a3a", beak="e83a3a", legs="e0a050"),
                      {JAPAN: 4, SWAMP: 3, ELF: 1}, "day", "mandarin", 0.4, 0.3, {"Чары": 1, "Тепло": 1, "Свет": 1}, 12, "water"],
    "nightjar": ["Козодой", "m", "nightjar", dict(back="7a6a54", belly="9a8a70", head="7a6a54", wing="6a5a44", bar="d8d0b8", tail="6a5a44", beak="3a3028", legs="6a5a44", spots="3a2e22", bars="b0a080"),
                 {PINE: 3, MEADOW: 2, FIELD: 2, GOTHIC: 2}, "night", "nightjar", 0.55, 0.4, {"Сон": 2, "Тьма": 1}, 9, "ground", {"beak": 0.6, "tail": 1.3}],
    # совы — ночью
    "tawny_owl": ["Серая неясыть", "m", "owl", dict(back="8a6a4a", belly="c8a880", head="8a6a4a", disc="b89a74", rim="5a3e28", wing="7a5a3a", tail="6a4e34", beak="d8c8a0", legs="d8c8a8", eye="1e1418", spots="4a3020", bars="5a3e28"),
                  {BIRCH: 4, PINE: 4, AUTUMN: 4, ELF: 3, HOME: 2, MEADOW: 2, GOTHIC: 3, SPIDER: 3}, "night", "tawny_owl", 0.45, 0.8, {"Сон": 1, "Тьма": 1, "Покой": 1}, 6, "tree", {"tufts": 0}],
    "eagle_owl": ["Филин", "l", "owl", dict(back="9a6e44", belly="d8b080", head="9a6e44", disc="c09a6a", rim="3a2a1e", wing="8a5e38", tail="7a5432", beak="2a2a2a", legs="e0c898", eye="f08a20", spots="3a2618", bars="5a3e28"),
                  {GOTHIC: 4, PINE: 3, DWARF: 3, GROTTO: 3, SPIDER: 2}, "night", "eagle_owl", 0.55, 0.45, {"Тьма": 2, "Сила": 1}, 12, "tree", {"tufts": 2}],
    "barn_owl": ["Сипуха", "m", "owl", dict(back="d8a868", belly="f8f0e0", head="d8a868", disc="fafaf4", rim="a0784a", wing="c8985a", tail="d8b080", beak="e8d8c8", legs="f0e4d0", eye="1e1418", spots="7a7a80", heart=1),
                 {FIELD: 4, GOTHIC: 4, MEADOW: 3, KNIGHT: 3, CATS: 2, HOME: 2}, "night", "barn_owl", 0.45, 0.6, {"Сон": 1, "Свет": 1, "Покой": 1}, 8, "tree", {"tufts": 0}],
    "scops_owl": ["Сплюшка", "s", "owl", dict(back="8a8270", belly="b0a890", head="8a8270", disc="a09a84", rim="4a4438", wing="7a7260", tail="6a6250", beak="5a5248", legs="b0a890", eye="f0c020", spots="3a342a", bars="4a4438"),
                  {AUTUMN: 4, JAPAN: 4, ORC: 2, BIRCH: 2, ELF: 2}, "night", "scops_owl", 0.35, 0.55, {"Сон": 2}, 7, "tree", {"tufts": 1}],
    "snowy_owl": ["Белая сова", "l", "owl", dict(back="f4f4f6", belly="fafafc", head="f4f4f6", disc="fafafc", rim="d8d8e0", wing="eaeaf0", tail="eaeaf0", beak="2a2a2a", legs="fafafc", eye="f0d020", spots="5a5a66", bars="8a8a96"),
                  {PINE: 2, MAGE: 3, GROTTO: 2, UNICORN: 1}, "night", "snowy_owl", 0.6, 0.2, {"Холод": 2, "Свет": 1}, 16, "ground", {"tufts": 0}],
    # волшебные
    "firebird": ["Жар-птица", "l", "firebird", dict(back="f08a1a", belly="f8c030", head="f8a020", crest="f8e060", wing="e8601a", bar="f8e060", tail="e8401a", tailtip="f8e060", beak="f8e8a0", legs="c87a2a", ring="f8f0a0", glow="ffb040"),
                 {DWARF: 2, ORC: 2, AUTUMN: 1, MAGE: 1}, "day", "firebird", 0.75, 0.08, {"Огонь": 2, "Свет": 2, "Исцеление": 1}, 60, "tree", {"tail": 2.6, "crest": 1.6}],
    "moon_finch": ["Лунный вьюрок", "s", "song", dict(back="7a8ad8", belly="c8d4f8", head="9aa8f0", cap="d8e0ff", wing="5a6ac0", bar="f0f4ff", tail="4a5ab0", beak="e8ecff", legs="8a96d0", glow="a8c0ff"),
                   {MAGE: 4, UNICORN: 3, GROTTO: 3}, "night", "moon_finch", 0.5, 0.2, {"Чары": 2, "Свет": 1, "Холод": 1}, 30, "tree"],
    "fairy_wren": ["Фейный крапивник", "s", "wren", dict(back="5ad0e8", belly="e0f8ff", head="3ab8f0", cap="7ae8ff", mask="1a2a6a", wing="2a5ab0", tail="2a70d0", beak="1e1e2a", legs="5a6a8a", glow="a0f0ff"),
                   {ELF: 5, UNICORN: 3}, "day", "fairy_wren", 0.6, 0.2, {"Чары": 2, "Свежесть": 1}, 26, "ground", {"tail": 1.8}],
    "shadow_crow": ["Теневой ворон", "m", "crow", dict(back="2a1e3a", belly="2e2240", head="22182e", wing="1e1428", bar="6a3a9a", tail="1e1428", beak="140e1a", legs="140e1a", ring="b06aff", glow="8a4ad0"),
                    {GOTHIC: 4, SPIDER: 3, GROTTO: 1}, "dusk", "shadow_crow", 0.6, 0.15, {"Тьма": 3, "Чары": 1}, 34, "ground"],
}

ORDER = list(B.keys())


# ======================================================================== рисование
def _ell_pts(cx, cy, rx, ry, ang=0.0, n=28):
    ca, sa = math.cos(ang), math.sin(ang)
    out = []
    for i in range(n):
        t = 2 * math.pi * i / n
        x, y = rx * math.cos(t), ry * math.sin(t)
        out.append((cx + x * ca - y * sa, cy + x * sa + y * ca))
    return out


def _c(d, k, fallback):
    return d.get(k, d.get(fallback, "808080")) if isinstance(d.get(k, d.get(fallback)), str) else d.get(fallback, "808080")


class BirdDraw:
    """Параметрическая птица в профиль (смотрит вправо), вид чуть сверху."""

    def __init__(self, bid):
        e = B[bid]
        self.id = bid
        self.size = e[1]
        self.shape = e[2]
        self.col = e[3]
        self.extra = e[12] if len(e) > 12 else {}
        self.W, self.H = FRAME[self.size]
        k = {"s": 1.0, "m": 1.35, "l": 1.8, "xl": 1.8}[self.size]
        self.k = k
        self.tail_k = self.extra.get("tail", 1.0)
        self.beak_k = self.extra.get("beak", 1.0)
        self.neck_k = self.extra.get("neck", 0.0)
        self.leg_k = self.extra.get("leg", 1.0)
        self.crest_k = self.extra.get("crest", 0.0) or (1.0 if "crest" in self.col else 0.0)

    def R(self, key, fb="back"):
        v = self.col.get(key)
        if not isinstance(v, str):
            v = self.col.get(fb, "808080")
        return ramp(v)

    def frame(self, pose):
        if self.shape == "owl":
            return self.owl(pose)
        W, H, k = self.W, self.H, self.k
        c = Canvas(W, H)
        ground = H - 2
        fly = pose in ("fly0", "fly1", "fly2", "fly3")
        hop = pose == "hop0"
        peck = pose in ("peck0", "peck1")
        sing = pose in ("sing0", "sing1")
        long_legs = self.leg_k > 1.8
        water = self.shape in ("swan", "mandarin")
        # корпус
        bw, bh = 6.0 * k, 4.2 * k
        if self.shape in ("heron", "crane"):
            bw, bh = 9.0, 6.0
        if self.shape in ("swan", "goose"):
            bw, bh = 9.5 * k / 1.8 * 1.4, 6.0 * k / 1.8 * 1.3
        if self.shape == "pheasant":
            bw, bh = 9.0, 6.4
        leg_len = (2.5 * k) * self.leg_k
        if self.shape in ("heron", "crane"):
            leg_len = 15.0 if self.shape == "heron" else 17.0
        if water:
            leg_len = 0.5
        cx = W * 0.47
        cy = ground - leg_len - bh * 0.85
        if hop:
            cy -= 2 * (k if k < 1.5 else 1.5)
        if fly:
            cy = H * 0.5
            bh *= 0.8
        ang = -0.18
        if self.shape in ("heron", "crane"):
            ang = -0.32
        if peck:
            ang = 0.25 if pose == "peck1" else 0.1
        if sing:
            ang = -0.3
        if fly:
            ang = -0.05
        body = c.mask()
        c.poly(_ell_pts(cx, cy, bw, bh, ang), body)
        # хвост
        tl = (4.0 * k) * self.tail_k
        tail = c.mask()
        tx0 = cx - bw * 0.75 * math.cos(ang)
        ty0 = cy - bw * 0.75 * math.sin(ang) * -1 + 0.5
        tdir = 0.35 if not fly else 0.08
        if self.shape in ("magpie", "pheasant", "firebird", "wagtail", "cuckoo"):
            tdir = 0.15
        if peck:
            tdir = -0.2
        tw = 1.6 * k
        ex = tx0 - tl * math.cos(tdir)
        ey = ty0 + tl * math.sin(tdir)
        if self.shape == "swallow" or self.shape == "bee_eater":
            c.poly([(tx0, ty0 - tw), (ex, ey - tw * 1.4), (ex + 2, ey), (ex, ey + tw * 1.2), (tx0, ty0 + tw)], tail)
        else:
            c.poly([(tx0 + 1, ty0 - tw), (ex, ey - tw * 0.9), (ex - 0.5, ey + tw * 0.6), (tx0 + 1, ty0 + tw * 1.1)], tail)
        # шея и голова
        hr = 3.2 * (k if k < 1.6 else 1.45)
        if self.size == "s":
            hr = 3.7
        elif self.size == "m":
            hr = 4.2
        hx_ = cx + bw * 0.78
        hy_ = cy - bh * 0.75
        neck = c.mask()
        if self.neck_k > 0:
            nl = self.neck_k * 5.0 * (1.0 if self.size != "xl" else 1.3)
            if self.shape == "swan":
                pts = [(cx + bw * 0.6, cy - 1), (cx + bw * 0.85, cy - nl * 0.4), (cx + bw * 0.55, cy - nl * 0.85), (cx + bw * 0.75, cy - nl * 1.1)]
            else:
                pts = [(cx + bw * 0.6, cy - 1), (cx + bw * 0.95, cy - nl * 0.45), (cx + bw * 0.75, cy - nl * 0.8), (cx + bw * 0.95, cy - nl * 1.05)]
            if peck:
                pts = [(cx + bw * 0.6, cy), (cx + bw * 1.1, cy + 1), (cx + bw * 1.4, cy + nl * 0.3), (cx + bw * 1.6, ground - 4)]
            if fly:
                pts = [(cx + bw * 0.6, cy - 1), (cx + bw * 1.1, cy - 2), (cx + bw * 1.4, cy - 3), (cx + bw * 1.7, cy - 3)]
                if self.shape == "heron":
                    pts = [(cx + bw * 0.6, cy - 1), (cx + bw * 0.9, cy - 4), (cx + bw * 1.05, cy - 3), (cx + bw * 1.25, cy - 4)]
            c.line_mask(pts, width=max(2, int(1.9 * k)), m=neck)
            hx_, hy_ = pts[-1]
            hr = 3.0 if self.size == "xl" else 3.2 * k / 1.4
        else:
            if peck:
                hx_ += 2.5 * k * 0.6
                hy_ += (bh * 1.2 if pose == "peck1" else bh * 0.6)
            if sing:
                hy_ -= 1
            if fly:
                hx_ += 1.5
                hy_ += 1.2
        head = c.mask()
        c.ellipse(hx_, hy_, hr, hr * 0.95, head)
        # клюв
        bl = (2.2 + 0.6 * k) * self.beak_k
        bt = 1.2 * (k if k < 1.4 else 1.3)
        bdir = 0.2 if not peck else 1.0
        if sing:
            bdir = -0.25
        if self.neck_k > 0 and peck:
            bdir = 1.3
        bx0 = hx_ + hr * 0.8
        by0 = hy_ + 0.3
        bx1 = bx0 + bl * math.cos(bdir)
        by1 = by0 + bl * math.sin(bdir)
        beak = c.mask()
        nx, ny = -math.sin(bdir), math.cos(bdir)
        if self.shape in ("crossbill",):
            c.poly([(bx0, by0 - bt), (bx1, by1 + 0.5), (bx0, by0 + bt)], beak)
        elif self.shape in ("raven", "crow", "shadow_crow"):
            c.poly([(bx0 - 0.5, by0 - bt * 1.1), (bx1, by1 + 0.3), (bx1 - 0.6, by1 + 0.9), (bx0 - 0.5, by0 + bt)], beak)
        elif self.shape in ("mandarin", "goose", "swan"):
            c.poly([(bx0 - 0.5, by0 - bt), (bx1, by1 - 0.2), (bx1, by1 + 0.9), (bx0 - 0.5, by0 + bt)], beak)
        else:
            c.poly([(bx0 - 0.5, by0 - bt), (bx1, by1), (bx0 - 0.5, by0 + bt * 0.9)], beak)
        if sing and pose == "sing1":
            # клюв открыт: нижняя половина опускается
            c.poly([(bx0 - 0.5, by0 + 0.3), (bx0 + bl * 0.8, by0 + bl * 0.55), (bx0 - 0.5, by0 + bt + 0.4)], beak)
        # хохолок
        crest = c.mask()
        if self.crest_k > 0:
            ck = self.crest_k
            if self.shape == "hoopoe":
                for i in range(5):
                    a = -2.2 + i * 0.35
                    c.line_mask([(hx_ - 0.5, hy_ - hr * 0.5), (hx_ + math.cos(a) * hr * 2.2 * ck * 0.7, hy_ + math.sin(a) * hr * 2.0 * ck * 0.7)], width=2, m=crest)
            else:
                c.poly([(hx_ - hr * 0.6, hy_ - hr * 0.4), (hx_ - hr * (1.3 + 0.5 * ck), hy_ - hr * (1.1 + 0.6 * ck)), (hx_ + hr * 0.2, hy_ - hr * 0.85)], crest)
        # крыло (сложенное) или машущее
        wing = c.mask()
        far = c.mask()
        if fly:
            ph = {"fly0": -1.0, "fly1": -0.45, "fly2": 1.0, "fly3": 0.25}[pose]
            span = min(cy - 1.0, 8.0 * k * (1.25 if self.size == "xl" else 1.0))
            wx0, wy0 = cx + bw * 0.05, cy - bh * 0.25
            tipx, tipy = wx0 - span * 0.55, wy0 + span * ph
            # крыло сужается к кончику: широкое у тела, острое на конце
            mid = ((wx0 + tipx) / 2.0 + bw * 0.25, (wy0 + tipy) / 2.0)
            c.poly([(wx0 + bw * 0.4, wy0), mid, (tipx, tipy), (tipx - 1.5, tipy + (1.5 if ph < 0 else -1.5)),
                    ((wx0 + tipx) / 2.0 - bw * 0.3, (wy0 + tipy) / 2.0 + (1.0 if ph < 0 else -1.0)), (wx0 - bw * 0.55, wy0 + 0.5)], wing)
            # дальнее крыло — темнее, торчит чуть впереди
            c.poly([(wx0 + bw * 0.3, wy0 - 0.5), (tipx + span * 0.45, tipy + (1 if ph < 0 else -1)), (tipx + span * 0.3, tipy + (2 if ph < 0 else -2)), (wx0 - bw * 0.1, wy0)], far)
        else:
            c.poly(_ell_pts(cx - bw * 0.22, cy - bh * 0.2, bw * 0.64, bh * 0.52, ang + 0.15), wing)
            wing &= body
        # ноги
        legs = c.mask()
        if not fly and not water:
            lx1 = cx + bw * 0.12
            lx2 = cx - bw * 0.15
            top = cy + bh * 0.6
            lw = 1 if self.size in ("s", "m") or self.shape in ("heron", "crane") else 2
            if hop:
                c.line_mask([(lx1, top), (lx1 + 1, top + 2)], lw, legs)
                c.line_mask([(lx2, top), (lx2 + 1, top + 2)], lw, legs)
            else:
                c.line_mask([(lx1, top), (lx1, ground)], lw, legs)
                c.line_mask([(lx2, top), (lx2 - 0.5, ground)], lw, legs)
                c.line_mask([(lx1 - 1, ground), (lx1 + 2, ground)], 1, legs)
                c.line_mask([(lx2 - 1.5, ground), (lx2 + 1.5, ground)], 1, legs)
        # ---------- краска: дальнее крыло, хвост, ноги, тело, крыло, голова, клюв
        col = self.col
        c.shade(far, [mix(x, (20, 20, 30), 0.35) for x in self.R("wing")])
        c.shade(tail, self.R("tail"))
        if self.tail_k >= 2.0:
            yy0, xx0 = np.mgrid[0:H, 0:W]
            c.fill(tail & ((xx0 % 3) == 0), self.R("tail")[0])
        if "tailtip" in col:
            tip = c.mask()
            c.ellipse(ex, ey, 2.0 * k, 2.4 * k, tip)
            c.shade(tip & tail, ramp(col["tailtip"]))
        c.shade(legs, self.R("legs"), flat=0.6)
        c.shade(body, self.R("back"))
        # живот: нижняя половина тела
        yy, xx = np.mgrid[0:H, 0:W]
        below = (yy - cy) * math.cos(ang) - (xx - cx) * math.sin(ang) > -0.5
        c.shade(body & below, self.R("belly"))
        if "breast" in col:
            br = c.mask()
            c.ellipse(cx + bw * 0.55, cy + 0.5, bw * 0.45, bh * 0.75, br)
            c.shade(br & body, ramp(col["breast"]))
        if "breastpatch" in col:
            bp = c.mask()
            c.ellipse(cx + bw * 0.25, cy + bh * 0.5, bw * 0.3, bh * 0.35, bp)
            c.shade(bp & body, ramp(col["breastpatch"]))
        if "bars" in col:
            bars = body & below & (((yy + xx // 3) % 3) == 0)
            c.fill(bars, ramp(col["bars"])[2])
        if "spots" in col:
            r0 = np.random.default_rng(sum(map(ord, self.id)) % 1000)
            for i in range(int(6 * k)):
                sx = cx + r0.uniform(-0.2, 0.75) * bw
                sy = cy + r0.uniform(-0.1, 0.8) * bh
                if body[int(min(H - 1, max(0, sy))), int(min(W - 1, max(0, sx)))]:
                    c.dot(sx, sy, ramp(col["spots"])[1])
        if "vent" in col:
            vt = c.mask()
            c.ellipse(cx - bw * 0.55, cy + bh * 0.55, bw * 0.3, bh * 0.35, vt)
            c.shade(vt & body, ramp(col["vent"]))
        if "glow" in col:
            pass
        c.shade(neck, self.R("throat", "head") if self.neck_k > 0 else self.R("head"))
        c.shade(wing, self.R("wing"))
        if "bar" in col and not fly:
            wb = c.mask()
            c.line_mask([(cx - bw * 0.6, cy - bh * 0.05), (cx + bw * 0.25, cy - bh * 0.35)], 1, wb)
            c.fill(wb & wing, ramp(col["bar"])[3])
        elif "bar" in col and fly:
            wb2 = wing & ~c.poly(_ell_pts(cx, cy, bw * 0.9, bh * 1.6, ang))
            c.fill(wb2 & ((yy + xx) % 2 == 0), ramp(col["bar"])[2])
        # маховые: тёмные кончики на крыле
        c.inner_line(wing, mix(self.R("wing")[0], (20, 18, 28), 0.4))
        c.shade(head, self.R("head"))
        if "cap" in col:
            cap = c.mask()
            c.ellipse(hx_ - 0.3, hy_ - hr * 0.55, hr * 1.05, hr * 0.62, cap)
            c.shade(cap & head, ramp(col["cap"]))
        if "nape" in col:
            np_ = c.mask()
            c.ellipse(hx_ - hr * 0.85, hy_ - hr * 0.2, hr * 0.45, hr * 0.5, np_)
            c.shade(np_ & head, ramp(col["nape"]))
        if "cheek" in col:
            ch = c.mask()
            c.ellipse(hx_ - 0.2, hy_ + hr * 0.3, hr * 0.65, hr * 0.45, ch)
            c.shade(ch & head, ramp(col["cheek"]), flat=0.4)
        if "throat" in col and self.neck_k == 0:
            th = c.mask()
            c.ellipse(hx_ + hr * 0.5, hy_ + hr * 0.85, hr * 0.55, hr * 0.5, th)
            c.shade(th & (head | body), ramp(col["throat"]))
        if "collar" in col:
            cl = c.mask()
            c.line_mask([(hx_ - hr * 0.6, hy_ + hr * 0.8), (hx_ + hr * 0.3, hy_ + hr * 1.1)], 1, cl)
            c.fill(cl & (head | body | neck), ramp(col["collar"])[2])
        if "stripe" in col:
            st = c.mask()
            c.line_mask([(hx_ + hr * 0.3, hy_ + hr), (cx + bw * 0.4, cy + bh * 0.9)], 1, st)
            c.fill(st & body, ramp(col["stripe"])[1])
        c.shade(crest, self.R("crest", "head"))
        if "cresttip" in col:
            c.fill(crest & ~c.ellipse(hx_, hy_, hr * 1.9, hr * 1.9), ramp(col["cresttip"])[1])
        c.shade(beak, self.R("beak"), flat=0.3)
        if "knob" in col:
            c.dot(bx0, by0 - 1, ramp(col["knob"])[1])
        # маска через глаз
        ex_, ey_ = int(round(hx_ + hr * 0.35)), int(round(hy_ - hr * 0.15))
        if "mask" in col:
            mk = c.mask()
            c.line_mask([(hx_ - hr * 0.7, ey_ + 0.3), (bx0, ey_ + 0.3)], max(1, int(hr * 0.45)), mk)
            c.fill(mk & head, ramp(col["mask"])[1])
        # глаз
        if "ring" in col:
            for dx, dy in ((-1, 0), (1, 0), (0, -1), (0, 1)):
                c.dot(ex_ + dx, ey_ + dy, ramp(col["ring"])[3])
        blink = pose == "idle1"
        c.dot(ex_, ey_, (24, 18, 26, 255) if not blink else ramp(col["head"])[1])
        if self.size != "s" and not blink:
            c.dot(ex_ + 1, ey_, (24, 18, 26, 255))
        if not blink and self.size in ("l", "xl"):
            c.dot(ex_, ey_ - 1, (24, 18, 26, 255))
        c.outline()
        # блик в глазу поверх обводки не нужен — только у крупных
        if not blink and self.size in ("m", "l", "xl"):
            c.dot(ex_, ey_, (24, 18, 26, 255))
            c.dot(ex_ + (1 if self.size != "m" else 0), ey_ - (1 if self.size != "m" else 0), (250, 248, 240, 255))
        if "glow" in col:
            # волшебные: светлая кайма-сияние (полупрозрачная)
            a = c.alpha()
            g = np.zeros_like(a)
            g[1:, :] |= a[:-1, :]
            g[:-1, :] |= a[1:, :]
            g[:, 1:] |= a[:, :-1]
            g[:, :-1] |= a[:, 1:]
            g &= ~a
            gc = hx(col["glow"])
            c.px[g] = (gc[0], gc[1], gc[2], 110)
        return c

    def owl(self, pose):
        W, H, k = self.W, self.H, self.k
        c = Canvas(W, H)
        col = self.col
        ground = H - 2
        fly = pose.startswith("fly")
        hoot = pose in ("sing0", "sing1")
        blink = pose == "idle1"
        turn = {"peck0": -1, "peck1": 1}.get(pose, 0)
        bw, bh = 5.2 * k, 6.6 * k
        cx = W * 0.5
        cy = ground - 1.6 * k - bh
        if pose == "hop0":
            cy -= 2
        if hoot:
            bw *= 1.08
        if fly:
            cy = H * 0.55
            bh *= 0.8
        body = c.mask()
        c.poly(_ell_pts(cx, cy, bw, bh, 0.0), body)
        tail = c.mask()
        c.poly([(cx - bw * 0.4, cy + bh * 0.7), (cx + bw * 0.4, cy + bh * 0.7), (cx + bw * 0.2, cy + bh * 1.15), (cx - bw * 0.2, cy + bh * 1.15)], tail)
        hr = 4.6 * k * 0.92
        hx_, hy_ = cx + turn * 0.6, cy - bh * 0.9
        if hoot:
            hy_ -= 0.6
        head = c.mask()
        c.poly(_ell_pts(hx_, hy_, hr * 1.06, hr * 0.92, 0.0), head)
        tufts = c.mask()
        tk = self.extra.get("tufts", 0)
        if tk:
            for s in (-1, 1):
                c.poly([(hx_ + s * hr * 0.35, hy_ - hr * 0.6), (hx_ + s * hr * (0.75 + 0.1 * tk), hy_ - hr * (1.25 + 0.15 * tk)), (hx_ + s * hr * 0.85, hy_ - hr * 0.45)], tufts)
        wings = c.mask()
        if fly:
            ph = {"fly0": -1.0, "fly1": -0.2, "fly2": 0.7, "fly3": -0.2}[pose]
            span = 12.0 * k * 0.8
            for s in (-1, 1):
                c.poly([(cx + s * bw * 0.4, cy - bh * 0.4), (cx + s * span, cy + span * ph * 0.6 - 2), (cx + s * span * 0.9, cy + span * ph * 0.6 + 2), (cx + s * bw * 0.6, cy + bh * 0.3)], wings)
        else:
            for s in (-1, 1):
                c.poly(_ell_pts(cx + s * bw * 0.62, cy + bh * 0.08, bw * 0.45, bh * 0.82, s * 0.12), wings)
        legs = c.mask()
        if not fly:
            for s in (-1, 1):
                c.rect(int(cx + s * bw * 0.35 - 1), int(cy + bh * 0.85), int(cx + s * bw * 0.35 + 1), ground + 1, legs)
        c.shade(tail, self.R("tail"))
        c.shade(legs, self.R("legs"), flat=0.5)
        c.shade(body, self.R("belly"))
        if "bars" in col or "spots" in col:
            yy, xx = np.mgrid[0:H, 0:W]
            r0 = np.random.default_rng(sum(map(ord, self.id)) % 1000)
            for i in range(int(10 * k)):
                sx = cx + r0.uniform(-0.6, 0.6) * bw
                sy = cy + r0.uniform(-0.5, 0.75) * bh
                if body[int(min(H - 1, max(0, sy))), int(min(W - 1, max(0, sx)))]:
                    c.dot(sx, sy, ramp(col.get("spots", col.get("bars")))[1])
                    if self.size != "s":
                        c.dot(sx, sy + 1, ramp(col.get("spots", col.get("bars")))[2])
        c.shade(wings, self.R("wing"))
        c.inner_line(wings, mix(self.R("wing")[0], (20, 18, 28), 0.3))
        if "bars" in col and not fly:
            yy, xx = np.mgrid[0:H, 0:W]
            c.fill(wings & ((yy % 3) == 0) & ((xx + yy) % 2 == 0), ramp(col["bars"])[3])
        c.shade(tufts, self.R("head"))
        c.shade(head, self.R("head"))
        # лицевой диск
        disc = c.mask()
        dcx = hx_ + turn * hr * 0.25
        if col.get("heart"):
            c.poly([(dcx, hy_ - hr * 0.55), (dcx + hr * 0.8, hy_ - hr * 0.7), (dcx + hr * 0.85, hy_ + hr * 0.2), (dcx, hy_ + hr * 0.85), (dcx - hr * 0.85, hy_ + hr * 0.2), (dcx - hr * 0.8, hy_ - hr * 0.7)], disc)
        else:
            c.ellipse(dcx - hr * 0.38, hy_ + hr * 0.05, hr * 0.5, hr * 0.55, disc)
            c.ellipse(dcx + hr * 0.38, hy_ + hr * 0.05, hr * 0.5, hr * 0.55, disc)
        disc &= head
        c.shade(disc, ramp(col["disc"]), flat=0.5)
        c.inner_line(disc, ramp(col["rim"])[2])
        # глаза
        eye_c = hx(col["eye"]) + (255,)
        er = max(1, int(round(hr * 0.22)))
        for s in (-1, 1):
            ex_ = int(round(dcx + s * hr * 0.38))
            ey_ = int(round(hy_ - hr * 0.02))
            if blink:
                c.line([(ex_ - er, ey_), (ex_ + er, ey_)], (30, 24, 30, 255))
                continue
            em = c.mask()
            c.ellipse(ex_ + 0.5, ey_ + 0.5, er + 0.6, er + 0.6, em)
            c.fill(em, (30, 24, 30, 255))
            if col["eye"] != "1e1418":
                inner = c.mask()
                c.ellipse(ex_ + 0.5, ey_ + 0.5, er + 0.1, er + 0.1, inner)
                c.fill(inner, eye_c)
                c.dot(ex_, ey_, (24, 16, 20, 255))
            c.dot(ex_ - (1 if er > 1 else 0), ey_ - (1 if er > 1 else 0), (250, 248, 236, 255))
        # клюв
        bk = c.mask()
        by = hy_ + hr * 0.3
        c.poly([(dcx - 1, by - 1), (dcx + 1.2, by - 1), (dcx + 0.2, by + 1.6 + (1 if hoot else 0))], bk)
        c.shade(bk, ramp(col["beak"]), flat=0.4)
        c.outline()
        return c


POSES = ["idle0", "idle1", "peck0", "peck1", "hop0", "idle0", "fly0", "fly1", "fly2", "fly3", "sing0", "sing1"]


def draw_bird(bid):
    d = BirdDraw(bid)
    frames = [d.frame(p) for p in POSES]
    sheet(frames, os.path.join(ART, "bird_%s.png" % bid))
    return frames


def draw_feather(bid):
    """Значок пера 24x24: стержень по диагонали, опахало в цветах птицы."""
    col = B[bid][3]
    c = Canvas(24, 24)
    main = col.get("wing", col["back"])
    tail = col.get("tail", main)
    accent = col.get("bar", col.get("tailtip", col.get("belly")))
    if bid in ("firebird",):
        main, accent = col["tail"], col["tailtip"]
    if B[bid][2] == "owl":
        main, accent = col["wing"], col.get("bars", col.get("spots"))
    vane = c.mask()
    # опахало: вытянутый лист вдоль диагонали (снизу-слева вверх-вправо)
    pts = []
    n = 18
    for i in range(n + 1):
        t = i / n
        x = 5 + t * 14
        y = 19 - t * 14
        w = math.sin(math.pi * min(1.0, t * 1.15)) * 4.2 * (1.0 if t > 0.12 else 0.4)
        pts.append((x - w * 0.7, y - w * 0.7))
    for i in range(n, -1, -1):
        t = i / n
        x = 5 + t * 14
        y = 19 - t * 14
        w = math.sin(math.pi * min(1.0, t * 1.15)) * 3.4 * (1.0 if t > 0.12 else 0.4)
        pts.append((x + w * 0.7, y + w * 0.7))
    c.poly(pts, vane)
    c.shade(vane, ramp(main), gy=0.1)
    # рисунок пера
    yy, xx = np.mgrid[0:24, 0:24]
    diag = (xx + yy)
    if "bars" in col or B[bid][2] == "owl":
        c.fill(vane & ((diag // 2) % 3 == 0), ramp(accent)[1])
    elif "spots" in col:
        c.fill(vane & ((xx * 7 + yy * 3) % 11 == 0), ramp(col["spots"])[3])
    if accent:
        tip = c.mask()
        c.ellipse(17.5, 6.5, 3.6, 3.6, tip)
        c.shade(vane & tip, ramp(accent if bid not in ("crane",) else "1e1e22"))
    if "glow" in col:
        c.fill(vane & ((xx * 5 + yy * 7) % 13 == 0), (255, 252, 230, 255))
    # бородки — светлые насечки
    for i in range(4):
        t = 0.35 + i * 0.14
        x, y = 5 + t * 14, 19 - t * 14
        c.dot(x - 2, y - 1, ramp(main)[4])
    c.outline()
    # стержень поверх (светлый) и очин снизу
    shaft = [(3, 21), (19, 5)]
    c.line(shaft, ramp(col.get("belly", "e0e0e0"))[4])
    c.dot(3, 21, ramp("d8c8a8")[3])
    c.dot(4, 20, ramp("d8c8a8")[3])
    c.save(os.path.join(ART, "icon_feather_%s.png" % bid))


# ======================================================================== голоса
SR = 32000


def _env(n, a=0.01, r=0.03):
    e = np.ones(n)
    na, nr = max(1, min(n // 2, int(a * SR))), max(1, min(n // 2, int(r * SR)))
    e[:na] = np.linspace(0, 1, na)
    e[-nr:] *= np.linspace(1, 0, nr)
    return e


def tone(f0, f1, dur, harm=(1.0,), vib=0.0, vibf=30.0, a=0.005, r=0.02, curve=1.0):
    n = max(8, int(dur * SR))
    t = np.linspace(0, 1, n) ** curve
    f = f0 + (f1 - f0) * t
    if vib:
        f = f * (1 + vib * np.sin(2 * np.pi * vibf * np.arange(n) / SR))
    ph = 2 * np.pi * np.cumsum(f) / SR
    x = np.zeros(n)
    for i, h in enumerate(harm):
        x += h * np.sin((i + 1) * ph)
    return x * _env(n, a, r)


def noise_burst(dur, lo=500, hi=3000, a=0.005, r=0.05):
    from scipy.signal import butter, lfilter
    n = int(dur * SR)
    x = np.random.default_rng(5).normal(0, 1, n)
    b, a2 = butter(2, [lo / (SR / 2), min(0.98, hi / (SR / 2))], "band")
    return lfilter(b, a2, x) * _env(n, a, r)


def put(buf, x, at):
    i = int(at * SR)
    j = min(len(buf), i + len(x))
    if i < len(buf):
        buf[i:j] += x[:j - i]


def song(bid, kind):
    r = np.random.default_rng(sum(map(ord, bid)) * 7 % 10000)
    dur = 2.6
    buf = np.zeros(int(dur * SR))
    t = 0.05
    if kind == "sparrow":
        for i in range(r.integers(4, 7)):
            f = r.uniform(3000, 4200)
            put(buf, tone(f, f * r.uniform(0.75, 0.9), 0.08, (1, 0.3), vib=0.02), t)
            t += r.uniform(0.14, 0.24)
    elif kind in ("tit",):
        for i in range(3):
            put(buf, tone(5200, 5000, 0.09, (1, 0.2)), t)
            put(buf, tone(3900, 3700, 0.12, (1, 0.25)), t + 0.13)
            t += 0.34
    elif kind == "blue_tit":
        for i in range(2):
            put(buf, tone(6200, 6000, 0.06), t)
            t += 0.1
        for i in range(8):
            put(buf, tone(5200, 4800, 0.035), t)
            t += 0.05
    elif kind == "robin":
        for i in range(7):
            f = r.uniform(3200, 6500)
            put(buf, tone(f, f * r.uniform(0.8, 1.25), r.uniform(0.06, 0.16), (1, 0.15), vib=0.03, vibf=r.uniform(40, 80)), t)
            t += r.uniform(0.09, 0.2)
    elif kind == "chaffinch":
        for i in range(9):
            put(buf, tone(4800 - i * 150, 4500 - i * 160, 0.05), t)
            t += 0.07 - i * 0.002
        put(buf, tone(5200, 3200, 0.22, (1, 0.3)), t + 0.02)
    elif kind == "goldfinch":
        for i in range(14):
            f = r.uniform(3500, 6500)
            put(buf, tone(f, f * r.uniform(0.85, 1.2), 0.05, (1, 0.25), vib=0.05, vibf=90), t)
            t += r.uniform(0.05, 0.1)
    elif kind == "bullfinch":
        for i in range(3):
            put(buf, tone(1500, 1350, 0.22, (1, 0.35, 0.1), a=0.04, r=0.08), t)
            t += 0.6
    elif kind == "wren" or kind == "fairy_wren":
        base = 5200 if kind == "wren" else 6800
        for i in range(5):
            put(buf, tone(base + r.uniform(-500, 500), base + r.uniform(-900, 300), 0.05), t)
            t += 0.07
        for i in range(16):
            put(buf, tone(base * 0.9, base * 0.82, 0.025), t)
            t += 0.035
        for i in range(4):
            put(buf, tone(base * 1.1, base * 0.95, 0.06), t)
            t += 0.08
        if kind == "fairy_wren":
            for i in range(4):
                put(buf, tone(8000 + i * 400, 8200 + i * 400, 0.25, (1, 0.5), a=0.002, r=0.2) * 0.25, 0.2 + i * 0.3)
    elif kind == "nightingale":
        for i in range(6):
            put(buf, tone(1800, 1900, 0.18, (1, 0.2), a=0.06, r=0.04), t)
            t += 0.2 - i * 0.015
        for i in range(18):
            put(buf, tone(3600, 2400, 0.03), t)
            t += 0.04
        put(buf, tone(5000, 2200, 0.15, (1, 0.3)), t + 0.05)
    elif kind == "lark":
        dur = 3.2
        buf = np.zeros(int(dur * SR))
        while t < dur - 0.2:
            f = r.uniform(2800, 6200)
            d = r.uniform(0.03, 0.09)
            put(buf, tone(f, f * r.uniform(0.8, 1.3), d, (1, 0.2), vib=0.04, vibf=70), t)
            t += d + r.uniform(0.005, 0.03)
    elif kind == "swallow":
        for i in range(16):
            f = r.uniform(3000, 5500)
            put(buf, tone(f, f * r.uniform(0.7, 1.3), r.uniform(0.03, 0.07), (1, 0.4), vib=0.08, vibf=120), t)
            t += r.uniform(0.05, 0.11)
        put(buf, noise_burst(0.25, 2500, 5000) * 0.3, t)
    elif kind == "starling":
        for i in range(10):
            f = r.uniform(1800, 6000)
            put(buf, tone(f, f * r.uniform(0.5, 1.6), r.uniform(0.04, 0.14), (1, 0.6, 0.3), vib=0.1, vibf=r.uniform(20, 200)), t)
            t += r.uniform(0.07, 0.18)
        put(buf, tone(5500, 2500, 0.3, (1, 0.2)), t)
    elif kind == "thrush":
        for p in range(3):
            f = r.uniform(2400, 4200)
            for rep in range(3):
                put(buf, tone(f, f * 1.1, 0.07, (1, 0.3)), t)
                put(buf, tone(f * 1.25, f * 0.95, 0.06, (1, 0.3)), t + 0.08)
                t += 0.18
            t += 0.12
    elif kind == "blackbird":
        notes = [r.uniform(1600, 2600) for _ in range(6)]
        for f in notes:
            d = r.uniform(0.12, 0.26)
            put(buf, tone(f, f * r.uniform(0.9, 1.15), d, (1, 0.25, 0.08), a=0.03, r=0.05), t)
            t += d + 0.03
        put(buf, tone(4800, 4200, 0.1) * 0.4, t)
    elif kind == "wagtail":
        for i in range(5):
            put(buf, tone(4200, 5200, 0.04), t)
            put(buf, tone(5000, 3800, 0.05), t + 0.05)
            t += 0.22
    elif kind == "oriole":
        for f in (1500, 2100, 1700, 2500):
            put(buf, tone(f, f * 1.05, 0.16, (1, 0.3), a=0.03, r=0.05), t)
            t += 0.17
        t += 0.4
        for f in (1500, 2100, 1700, 2500):
            put(buf, tone(f, f * 1.05, 0.16, (1, 0.3), a=0.03, r=0.05), t)
            t += 0.17
    elif kind == "waxwing":
        for i in range(8):
            put(buf, tone(6800, 6800, 0.18, (1,), vib=0.06, vibf=40, a=0.03, r=0.05) * 0.6, t)
            t += 0.25
    elif kind == "kingfisher":
        for i in range(4):
            put(buf, tone(6200, 5600, 0.12, (1, 0.15)), t)
            t += 0.3
    elif kind == "hoopoe":
        for i in range(3):
            put(buf, tone(560, 500, 0.12, (1, 0.5, 0.2), a=0.02, r=0.05), t)
            t += 0.17
        t += 0.4
        for i in range(3):
            put(buf, tone(560, 500, 0.12, (1, 0.5, 0.2), a=0.02, r=0.05), t)
            t += 0.17
    elif kind == "jay":
        for i in range(2):
            put(buf, noise_burst(0.3, 1200, 4500) * 0.7 + 0 * buf[:1].sum(), t)
            put(buf, tone(1600, 1200, 0.3, (1, 0.6, 0.5, 0.4)) * 0.3, t)
            t += 0.55
    elif kind == "magpie":
        for i in range(10):
            put(buf, noise_burst(0.06, 1500, 5500) * 0.8, t)
            put(buf, tone(1800, 1600, 0.06, (1, 0.7, 0.5)) * 0.25, t)
            t += 0.09
    elif kind in ("crow", "shadow_crow"):
        for i in range(3):
            x = tone(700, 560, 0.32, (1, 0.8, 0.6, 0.5, 0.4, 0.3), vib=0.04, vibf=55, a=0.02, r=0.08) * 0.5 + noise_burst(0.32, 600, 2500) * 0.4
            if kind == "shadow_crow":
                x = x * 0.7 + tone(1400, 900, 0.32, (1, 0.3), a=0.02, r=0.1) * 0.25
            put(buf, x, t)
            t += 0.55
    elif kind == "raven":
        for i in range(2):
            put(buf, tone(420, 360, 0.36, (1, 0.9, 0.7, 0.5, 0.4), vib=0.05, vibf=40, a=0.02, r=0.1) * 0.6 + noise_burst(0.36, 400, 1800) * 0.25, t)
            t += 0.7
        put(buf, tone(900, 950, 0.12, (1, 0.4)) * 0.4, t)
    elif kind == "cuckoo":
        for i in range(3):
            put(buf, tone(740, 720, 0.18, (1, 0.12), a=0.02, r=0.06), t)
            put(buf, tone(600, 580, 0.28, (1, 0.12), a=0.02, r=0.1), t + 0.24)
            t += 0.8
    elif kind == "woodpecker":
        x = np.zeros(int(0.6 * SR))
        for i in range(14):
            put(x, noise_burst(0.015, 400, 2500), i * 0.04)
            put(x, tone(900, 700, 0.015) * 0.5, i * 0.04)
        put(buf, x, 0.05)
        put(buf, tone(4200, 3800, 0.05, (1, 0.4)) * 0.6, 1.2)
        put(buf, x * 0.8, 1.6)
    elif kind == "dove":
        for p in range(2):
            put(buf, tone(520, 560, 0.25, (1, 0.25), a=0.05, r=0.06), t)
            put(buf, tone(600, 600, 0.35, (1, 0.25), a=0.05, r=0.08), t + 0.3)
            put(buf, tone(560, 480, 0.3, (1, 0.25), a=0.05, r=0.1), t + 0.7)
            t += 1.2
    elif kind == "pheasant":
        put(buf, tone(1100, 900, 0.18, (1, 0.8, 0.6, 0.4), a=0.01, r=0.05) * 0.7 + noise_burst(0.18, 800, 3500) * 0.4, t)
        put(buf, tone(1000, 850, 0.2, (1, 0.8, 0.6, 0.4), a=0.01, r=0.05) * 0.7 + noise_burst(0.2, 800, 3500) * 0.4, t + 0.25)
        for i in range(12):
            put(buf, noise_burst(0.03, 100, 600) * 0.6, t + 0.6 + i * 0.05)
    elif kind == "quail":
        for p in range(2):
            put(buf, tone(2600, 2800, 0.08, (1, 0.3)), t)
            put(buf, tone(3000, 2500, 0.12, (1, 0.3)), t + 0.2)
            put(buf, tone(2900, 2400, 0.12, (1, 0.3)), t + 0.36)
            t += 1.0
    elif kind == "partridge":
        for i in range(3):
            put(buf, noise_burst(0.2, 1000, 3500) * 0.6 + tone(1800, 1400, 0.2, (1, 0.5, 0.3)) * 0.3, t)
            t += 0.45
    elif kind == "heron":
        put(buf, tone(380, 300, 0.4, (1, 0.9, 0.8, 0.6, 0.5), vib=0.06, vibf=45, a=0.01, r=0.1) * 0.5 + noise_burst(0.4, 300, 2000) * 0.5, t)
    elif kind == "crane":
        for i in range(2):
            put(buf, tone(980, 900, 0.5, (1, 0.7, 0.4, 0.2), vib=0.05, vibf=25, a=0.05, r=0.15) * 0.6, t)
            put(buf, tone(1200, 1100, 0.4, (1, 0.6, 0.3), vib=0.05, vibf=25, a=0.05, r=0.15) * 0.45, t + 0.1)
            t += 1.0
    elif kind == "swan":
        for i in range(2):
            put(buf, tone(700, 620, 0.35, (1, 0.6, 0.3), a=0.05, r=0.15) * 0.5, t)
            t += 0.8
    elif kind == "goose":
        for i in range(4):
            put(buf, tone(600, 700, 0.18, (1, 0.9, 0.7, 0.5, 0.3), a=0.01, r=0.05) * 0.5 + noise_burst(0.18, 600, 2200) * 0.2, t)
            t += 0.3
    elif kind == "gull":
        put(buf, tone(1300, 1900, 0.15, (1, 0.6, 0.4)) * 0.5, t)
        t += 0.25
        for i in range(5):
            put(buf, tone(1700, 1300, 0.12, (1, 0.6, 0.4), a=0.01, r=0.04) * 0.5, t)
            t += 0.16
    elif kind == "sandpiper":
        for i in range(6):
            put(buf, tone(5200, 4400, 0.06), t)
            t += 0.12
    elif kind == "bee_eater":
        for i in range(5):
            put(buf, tone(2400, 2200, 0.09, (1, 0.6), vib=0.15, vibf=110), t)
            t += 0.3
    elif kind == "crossbill":
        for i in range(6):
            put(buf, tone(4000, 3600, 0.05, (1, 0.3)), t)
            put(buf, tone(4200, 3800, 0.05, (1, 0.3)), t + 0.08)
            t += 0.3
    elif kind == "nuthatch":
        for i in range(10):
            put(buf, tone(2900, 2700, 0.07, (1, 0.2)), t)
            t += 0.1
    elif kind == "white_eye":
        for i in range(12):
            f = r.uniform(4500, 7500)
            put(buf, tone(f, f * r.uniform(0.85, 1.15), 0.05), t)
            t += r.uniform(0.06, 0.12)
    elif kind == "rosefinch":
        for f in (3200, 3800, 3500, 4200):
            put(buf, tone(f, f * 1.1, 0.14, (1, 0.25), a=0.02), t)
            t += 0.18
    elif kind == "mandarin":
        for i in range(4):
            put(buf, tone(2400, 1900, 0.09, (1, 0.5, 0.3)), t)
            t += 0.35
    elif kind == "nightjar":
        dur = 2.6
        x = tone(1000, 1000, 2.2, (1, 0.6, 0.3), a=0.1, r=0.2)
        n = len(x)
        x *= (0.5 + 0.5 * np.sign(np.sin(2 * np.pi * 38 * np.arange(n) / SR)))
        put(buf, x * 0.5, 0.1)
    elif kind == "tawny_owl":
        dur = 3.2
        buf = np.zeros(int(dur * SR))
        put(buf, tone(420, 400, 0.45, (1, 0.12), a=0.05, r=0.12), 0.05)
        put(buf, tone(400, 380, 0.12, (1, 0.1), a=0.02, r=0.05), 0.9)
        put(buf, tone(420, 360, 1.0, (1, 0.12), vib=0.05, vibf=8, a=0.05, r=0.3), 1.2)
    elif kind == "eagle_owl":
        dur = 2.4
        buf = np.zeros(int(dur * SR))
        put(buf, tone(180, 170, 0.3, (1, 0.25, 0.1), a=0.04, r=0.12), 0.05)
        put(buf, tone(200, 160, 0.45, (1, 0.25, 0.1), a=0.04, r=0.18), 0.5)
    elif kind == "barn_owl":
        put(buf, noise_burst(1.0, 1500, 7000, a=0.05, r=0.4) * 0.8, 0.05)
    elif kind == "scops_owl":
        for i in range(3):
            put(buf, tone(1250, 1220, 0.22, (1, 0.1), a=0.02, r=0.08), t)
            t += 0.85
    elif kind == "snowy_owl":
        for i in range(3):
            put(buf, tone(380, 330, 0.25, (1, 0.6, 0.3), a=0.01, r=0.08) * 0.6 + noise_burst(0.25, 300, 1600) * 0.3, t)
            t += 0.35
    elif kind == "firebird":
        dur = 3.0
        buf = np.zeros(int(dur * SR))
        for i, f in enumerate([1568, 1976, 2349, 2637, 3136, 2637, 2349]):
            put(buf, tone(f, f, 0.6, (1, 0.4, 0.2), a=0.005, r=0.5) * np.exp(-np.linspace(0, 5, int(0.6 * SR))) * 0.5, 0.05 + i * 0.16)
        for i in range(10):
            put(buf, tone(5500, 4800, 0.04) * 0.3, 1.4 + i * 0.07)
    elif kind == "moon_finch":
        for i, f in enumerate([2093, 2637, 3136, 2637, 3520]):
            put(buf, tone(f, f, 0.5, (1, 0.25), a=0.005, r=0.4) * np.exp(-np.linspace(0, 4, int(0.5 * SR))) * 0.6, 0.05 + i * 0.22)
    else:
        for i in range(5):
            f = r.uniform(3000, 5000)
            put(buf, tone(f, f * 0.9, 0.08), t)
            t += 0.15
    # тишина в конце обрезается, громкость выравнивается
    nz = np.nonzero(np.abs(buf) > 1e-4)[0]
    if len(nz):
        buf = buf[: min(len(buf), nz[-1] + int(0.08 * SR))]
    peak = np.max(np.abs(buf)) + 1e-9
    buf = buf / peak * 0.85
    import wave
    data = (buf * 32767).astype(np.int16)
    with wave.open(os.path.join(AUD, "bird_%s.wav" % bid), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# ======================================================================== birds_db.gd
def gd_value(v):
    if isinstance(v, bool):
        return "true" if v else "false"
    if isinstance(v, (int, np.integer)):
        return str(int(v))
    if isinstance(v, float):
        return repr(round(v, 3))
    if isinstance(v, str):
        return '"%s"' % v
    if isinstance(v, dict):
        return "{" + ", ".join("%s: %s" % (gd_value(k), gd_value(x)) for k, x in v.items()) + "}"
    if isinstance(v, (list, tuple)):
        return "[" + ", ".join(gd_value(x) for x in v) + "]"
    raise TypeError(v)


def write_db():
    lines = [
        "extends RefCounted",
        "## Птицы v20 — СГЕНЕРИРОВАНО tools/birds_design.py (правки — там, потом `python tools/birds_design.py --write`).",
        "## id -> name, size (s/m/l/xl), owl, frame [w,h], biomes {биом: вес}, when (day/night/dusk), shy (0..1 — с какого",
        "## расстояния улетает), common (0..1), props (свойства пера в котле), price (цена пера), perch (ground/tree/water).",
        "## Спрайт art/bird_<id>.png: 12 кадров (0-1 стоит/моргает, 2-3 клюёт, 4 прыжок, 6-9 полёт, 10-11 поёт).",
        "## Перо — предмет feather_<id> (значок art/icon_feather_<id>.png), голос audio/bird_<id>.wav.",
        "",
        "const DATA: Dictionary = {",
    ]
    for bid in ORDER:
        e = B[bid]
        d = {
            "name": e[0], "size": e[1], "owl": e[2] == "owl", "frame": list(FRAME[e[1]]),
            "biomes": e[4], "when": e[5], "shy": float(e[7]), "common": float(e[8]),
            "props": e[9], "price": int(e[10]), "perch": e[11], "magic": "glow" in e[3],
        }
        lines.append("\t%s: %s," % (gd_value(bid), gd_value(d)))
    lines += [
        "}",
        "const ORDER: Array = %s" % gd_value(ORDER),
        "",
        "",
        "static func feather(bid: String) -> String:",
        "\treturn \"feather_\" + bid",
        "",
        "",
        "static func is_feather(id: String) -> bool:",
        "\treturn id.begins_with(\"feather_\") and DATA.has(id.substr(8))",
        "",
        "",
        "static func feather_name(id: String) -> String:",
        "\treturn \"Перо: \" + String(DATA[id.substr(8)][\"name\"]).to_lower() if is_feather(id) else id",
        "",
        "",
        "## Какие птицы живут в биоме в это время суток: [[id, вес], ...]",
        "static func for_biome(biome: int, night: bool, dusk: bool) -> Array:",
        "\tvar out: Array = []",
        "\tfor id in ORDER:",
        "\t\tvar d: Dictionary = DATA[id]",
        "\t\tvar w: String = String(d[\"when\"])",
        "\t\tvar ok: bool = (w == \"day\" and not night) or (w == \"night\" and night) or (w == \"dusk\" and (dusk or night))",
        "\t\tif not ok:",
        "\t\t\tcontinue",
        "\t\tvar bw: float = float((d[\"biomes\"] as Dictionary).get(biome, 0))",
        "\t\tif bw > 0.0:",
        "\t\t\tout.append([id, bw * float(d[\"common\"])])",
        "\treturn out",
        "",
    ]
    with open(os.path.join(GAME, "birds_db.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write("\n".join(lines))


def preview():
    """Лист всех птиц (кадр 0 и полёт) в увеличении — проверить глазами."""
    from PIL import Image
    tiles = []
    for bid in ORDER:
        im = Image.open(os.path.join(ART, "bird_%s.png" % bid))
        w, h = FRAME[B[bid][1]]
        row = Image.new("RGBA", (w * 4 + 24, 56), (120, 150, 90, 255))
        for i, fi in enumerate((0, 2, 7, 11)):
            row.paste(im.crop((fi * w, 0, fi * w + w, h)), (i * w, 56 - h), im.crop((fi * w, 0, fi * w + w, h)))
        fe = Image.open(os.path.join(ART, "icon_feather_%s.png" % bid))
        row.paste(fe, (w * 4, 4), fe)
        tiles.append(row)
    cols = 5
    cw = max(t.width for t in tiles)
    rows = (len(tiles) + cols - 1) // cols
    big = Image.new("RGBA", (cw * cols, 56 * rows), (120, 150, 90, 255))
    for i, t in enumerate(tiles):
        big.paste(t, ((i % cols) * cw, (i // cols) * 56))
    big = big.resize((big.width * 3, big.height * 3), Image.NEAREST)
    out = sys.argv[sys.argv.index("--preview") + 1]
    big.save(out)


if __name__ == "__main__":
    args = sys.argv[1:]
    allp = not any(a in args for a in ("--art", "--audio", "--write", "--preview"))
    if allp or "--art" in args:
        for bid in ORDER:
            draw_bird(bid)
            draw_feather(bid)
        print("art", len(ORDER))
    if allp or "--audio" in args:
        for bid in ORDER:
            song(bid, B[bid][6])
        print("audio", len(ORDER))
    if allp or "--write" in args:
        write_db()
        print("birds_db.gd")
    if "--preview" in args:
        preview()
    print("BIRDS DONE")
