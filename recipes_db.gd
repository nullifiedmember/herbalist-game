extends RefCounted
## Алхимия v16 (СГЕНЕРИРОВАНО tools/potion_design.py — правь там и запускай с --write).
## Свойства трав складываются; травы можно обработать на столе (растереть, нарезать, высушить, обжечь, замочить);
## основа (вода, воск, спирт, мёд, лунная роса) и температура воды решают, что выйдет. Побеждает самое «точное» зелье.

const HERBS = preload("res://herbs_db.gd")
const W = preload("res://wild_db.gd")

const PROPS: Array = ["Свежесть", "Покой", "Сон", "Тепло", "Исцеление", "Сила", "Жгучесть", "Холод", "Огонь", "Свет", "Тьма", "Чары"]
const RARE_PROPS: Array = ["Холод", "Огонь", "Свет", "Тьма", "Чары"]
const BASES: Array = ["water", "wax", "spirit", "honey", "moon_dew"]
const BASE_NAME: Dictionary = {"water": "Вода", "wax": "Воск", "spirit": "Спирт", "honey": "Мёд", "moon_dew": "Лунная роса"}
const BASE_KIND: Dictionary = {"water": "чай", "wax": "мазь", "spirit": "настойка", "honey": "сироп", "moon_dew": "эликсир"}
const TEMPS: Array = ["cold", "warm", "hot"]
const TEMP_NAME: Dictionary = {"cold": "холодная", "warm": "тёплая", "hot": "горячая"}
const PROCS: Array = ["grind", "cut", "dry", "burn", "soak"]
const PROC_NAME: Dictionary = {"grind": "Растереть", "cut": "Нарезать", "dry": "Высушить", "burn": "Обжечь", "soak": "Замочить"}
const LEVEL: Dictionary = {"I": 1, "II": 2, "III": 3}
const RARITY_NAME: Array = ["обычное", "редкое", "очень редкое", "легендарное"]
const RARITY_COL: Array = [Color("c8b898"), Color("7ab0f0"), Color("c890f0"), Color("f8c040")]

## Редкие свойства у трав (дописываются к свойствам из herbs_db.gd)
const HERB_EXTRA: Dictionary = {
	"glowmoss": {"Свет": 1},
	"moonbloom": {"Свет": 1, "Чары": 1},
	"unicorn_mane": {"Свет": 2},
	"crystal_root": {"Чары": 2},
	"star_bell": {"Чары": 1},
	"nightshade": {"Тьма": 2},
	"mandrake": {"Тьма": 1, "Чары": 1},
	"fire_pepper": {"Огонь": 2},
	"elf_leaf": {"Чары": 1},
	"ginseng": {"Свет": 1},
	"wormwood": {"Тьма": 1},
	"web_grass": {"Тьма": 1},
	"marsh_tea": {"Тьма": 1},
	"sea_lavender": {"Холод": 1},
	"cloudberry": {"Холод": 1},
	"lily_valley": {"Холод": 1},
	"heather": {"Чары": 1},
	"fern": {"Тьма": 1},
	"poppy": {"Тьма": 1},
	"st_john": {"Свет": 1},
	"calendula": {"Свет": 1},
	"sundew": {"Чары": 1},
	"catnip": {"Чары": 1},
	"shiso": {"Холод": 1},
	"sea_kale": {"Холод": 1},
	"club_moss": {"Огонь": 1},
}
## Свойства грибов
const SHROOM_PROPS_BASE: Dictionary = {
	"porcini": {"Исцеление": 1, "Сила": 1},
	"birch_bolete": {"Свежесть": 1, "Исцеление": 1},
	"chanterelle": {"Свежесть": 1, "Тепло": 1},
	"fly_agaric": {"Жгучесть": 1, "Тьма": 1, "Чары": 1},
	"glow_cap": {"Свежесть": 1, "Свет": 1},
	"moon_shroom": {"Сон": 1, "Свет": 2, "Чары": 2},
	"swamp_honey": {"Сон": 1, "Тьма": 1},
	"web_shroom": {"Покой": 1, "Тьма": 1},
	"blood_russula": {"Сила": 1, "Тьма": 2},
	"elf_star": {"Исцеление": 2, "Чары": 1},
	"morel": {"Сила": 2},
	"field_champignon": {"Исцеление": 1, "Сила": 1},
}

## Зелья. need — минимальные суммы свойств; temp — для воды (any — любая).
## rarity: 0 обычное, 1 редкое, 2 очень редкое, 3 легендарное. hint — пример рецепта (для режима бога и проверок).
const PRODUCTS: Dictionary = {
	"sleep_tea": {"name": "Сонный чай", "use": "Помогает уснуть и прогоняет кошмары.", "base": "water", "temp": "any", "need": {"Сон": 2}, "rarity": 0, "col": Color("8a78d0"), "keys": [], "ex": ["water", "cold", [["poppy", []]]]},
	"vigor_tea": {"name": "Бодрящий чай", "use": "Возвращает силы после тяжёлой работы.", "base": "water", "temp": "any", "need": {"Свежесть": 2, "Сила": 2}, "rarity": 0, "col": Color("c86a32"), "keys": [], "ex": ["water", "cold", [["glowmoss", []]]]},
	"calm_tea": {"name": "Успокаивающий чай", "use": "Унимает тревогу и дрожь в руках.", "base": "water", "temp": "any", "need": {"Покой": 3}, "rarity": 0, "col": Color("7cc0a0"), "keys": [], "ex": ["water", "warm", [["lavender", ["grind"]]]]},
	"mint_tea": {"name": "Мятный чай", "use": "Снимает жар и тошноту после пира.", "base": "water", "temp": "any", "need": {"Свежесть": 4}, "rarity": 0, "col": Color("5cc08a"), "keys": [], "ex": ["water", "warm", [["mint", ["grind", "cut"]]]]},
	"warm_tea": {"name": "Согревающий чай", "use": "Лечит простуду и озноб.", "base": "water", "temp": "any", "need": {"Свежесть": 1, "Тепло": 1}, "rarity": 0, "col": Color("e0a040"), "keys": [], "ex": ["water", "cold", [["mint", ["dry", "cut"]]]]},
	"morning_tea": {"name": "Чай доброго утра", "use": "Глаза открываются сами, а день кажется длиннее.", "base": "water", "temp": "warm", "need": {"Свежесть": 2, "Тепло": 2}, "rarity": 0, "col": Color("a2b466"), "keys": [], "ex": ["water", "warm", [["mint", []], ["mint", ["grind", "dry"]]]]},
	"colic_tea": {"name": "Детский чай от колик", "use": "Младенцы засыпают, а мамы выдыхают.", "base": "water", "temp": "warm", "need": {"Покой": 2, "Тепло": 1, "Исцеление": 1}, "rarity": 0, "col": Color("b4b995"), "keys": [], "ex": ["water", "warm", [["pink_clover", ["cut", "dry"]]]]},
	"clear_tea": {"name": "Чай ясной головы", "use": "Мысли раскладываются по полочкам.", "base": "water", "temp": "warm", "need": {"Свежесть": 2, "Покой": 2}, "rarity": 0, "col": Color("6cc0aa"), "keys": [], "ex": ["water", "warm", [["sea_lavender", ["grind", "cut"]]]]},
	"wander_tea": {"name": "Чай странника", "use": "Дорога короче, ноги не ноют.", "base": "water", "temp": "warm", "need": {"Тепло": 2, "Сила": 2}, "rarity": 0, "col": Color("ab9b3e"), "keys": [], "ex": ["water", "warm", [["glowmoss", ["grind", "dry"]]]]},
	"meadow_tea": {"name": "Луговой сбор", "use": "Всего понемногу — от всего понемногу.", "base": "water", "temp": "warm", "need": {"Свежесть": 1, "Покой": 1, "Исцеление": 2}, "rarity": 0, "col": Color("afcb97"), "keys": [], "ex": ["water", "warm", [["mint", []], ["chamomile", ["soak", "grind"]]]]},
	"dream_tea": {"name": "Чай сладких снов", "use": "Снится детство и запах пирогов.", "base": "water", "temp": "warm", "need": {"Покой": 2, "Сон": 3}, "rarity": 0, "col": Color("8491cc"), "keys": [], "ex": ["water", "warm", [["mint", []], ["valerian", ["grind"]]]]},
	"cough_tea": {"name": "Чай от кашля", "use": "Грудь дышит свободно уже к вечеру.", "base": "water", "temp": "warm", "need": {"Тепло": 2, "Исцеление": 2}, "rarity": 0, "col": Color("edbb62"), "keys": [], "ex": ["water", "warm", [["calendula", ["cut", "dry"]]]]},
	"chatter_tea": {"name": "Чай болтушки", "use": "Развязывает язык самым молчаливым гостям.", "base": "water", "temp": "warm", "need": {"Свежесть": 1, "Тепло": 2, "Жгучесть": 1}, "rarity": 0, "col": Color("bd9652"), "keys": [], "ex": ["water", "warm", [["mint", ["dry", "cut"]], ["club_moss", []]]]},
	"memory_tea": {"name": "Чай памяти", "use": "Вспоминаются имена, даты и куда положила ключи.", "base": "water", "temp": "warm", "need": {"Свежесть": 3, "Чары": 1}, "rarity": 1, "col": Color("74aca2"), "keys": [], "ex": ["water", "warm", [["elf_leaf", ["grind"]]]]},
	"firefly_tea": {"name": "Светлячковый чай", "use": "Кожа тихо светится до самого утра.", "base": "water", "temp": "warm", "need": {"Свежесть": 1, "Свет": 2}, "rarity": 1, "col": Color("c8e2a0"), "keys": [["glowmoss", "glow_cap", "fire_lily", "sunflower_gold", "unicorn_mane"]], "ex": ["water", "warm", [["unicorn_mane", ["grind", "cut"]]]]},
	"purr_tea": {"name": "Чай кошачьей ласки", "use": "Кошкодевочки мурчат от одного запаха.", "base": "water", "temp": "warm", "need": {"Покой": 2, "Сон": 1, "Чары": 1}, "rarity": 1, "col": Color("9090d1"), "keys": [["catnip"]], "ex": ["water", "warm", [["catnip", []]]]},
	"solace_tea": {"name": "Чай от тоски", "use": "Тяжёлое на душе становится лёгким.", "base": "water", "temp": "warm", "need": {"Покой": 2, "Свет": 1}, "rarity": 1, "col": Color("a7cabe"), "keys": [], "ex": ["water", "warm", [["fire_pepper", ["grind", "soak"]]]]},
	"voice_tea": {"name": "Чай певуньи", "use": "Голос чистый, как ручей.", "base": "water", "temp": "warm", "need": {"Свежесть": 2, "Тепло": 1, "Исцеление": 1}, "rarity": 0, "col": Color("a4c177"), "keys": [], "ex": ["water", "warm", [["chamomile", ["cut", "grind"]]]]},
	"fairy_tea": {"name": "Чай лесной феи", "use": "Слышно, о чём шепчутся деревья.", "base": "water", "temp": "warm", "need": {"Свежесть": 2, "Покой": 1, "Чары": 1}, "rarity": 1, "col": Color("7ca8b1"), "keys": [], "ex": ["water", "warm", [["star_bell", ["grind"]]]]},
	"knight_tea": {"name": "Чай рыцаря", "use": "После турнира — как новенькая.", "base": "water", "temp": "warm", "need": {"Исцеление": 2, "Сила": 2}, "rarity": 0, "col": Color("b0b660"), "keys": [], "ex": ["water", "warm", [["chamomile", []], ["rosehip", []]]]},
	"strong_brew": {"name": "Крепкий отвар", "use": "Чёрный, как дёготь. Будит даже медведя.", "base": "water", "temp": "hot", "need": {"Сила": 3}, "rarity": 0, "col": Color("6e963c"), "keys": [], "ex": ["water", "hot", [["nettle", []]]]},
	"fire_brew": {"name": "Огненный отвар", "use": "Пьёшь — и внутри разгорается печка.", "base": "water", "temp": "hot", "need": {"Тепло": 2, "Огонь": 2}, "rarity": 1, "col": Color("f1872f"), "keys": [], "ex": ["water", "hot", [["fire_pepper", []]]]},
	"bath_brew": {"name": "Банный отвар", "use": "Плеснуть на камни — и любая хворь выходит паром.", "base": "water", "temp": "hot", "need": {"Тепло": 3, "Исцеление": 1}, "rarity": 0, "col": Color("eaad51"), "keys": [], "ex": ["water", "hot", [["chamomile", ["grind"]]]]},
	"flu_brew": {"name": "Отвар от простуды", "use": "Пот, одеяло, сон — к утру здорова.", "base": "water", "temp": "hot", "need": {"Тепло": 2, "Исцеление": 2}, "rarity": 0, "col": Color("edbb62"), "keys": [], "ex": ["water", "hot", [["world_leaf", ["cut", "dry"]]]]},
	"sweat_brew": {"name": "Жаропот", "use": "Выгоняет лихорадку вместе с потом.", "base": "water", "temp": "hot", "need": {"Тепло": 3, "Жгучесть": 1}, "rarity": 0, "col": Color("e08c3f"), "keys": [], "ex": ["water", "hot", [["mint", ["grind", "dry"]], ["nettle", []]]]},
	"smith_brew": {"name": "Кузнечный отвар", "use": "Кузнецы пьют его, чтобы молот был лёгким.", "base": "water", "temp": "hot", "need": {"Тепло": 2, "Сила": 3}, "rarity": 0, "col": Color("9e9a3d"), "keys": [], "ex": ["water", "hot", [["ginseng", ["cut", "dry"]]]]},
	"bitter_brew": {"name": "Горький отвар", "use": "Гадость редкая. Зато живот больше не болит.", "base": "water", "temp": "hot", "need": {"Исцеление": 1, "Жгучесть": 2}, "rarity": 0, "col": Color("d67c54"), "keys": [], "ex": ["water", "hot", [["sundew", []]]]},
	"brave_brew": {"name": "Отвар храбрости", "use": "Колени не дрожат даже перед троллем.", "base": "water", "temp": "hot", "need": {"Сила": 2, "Жгучесть": 2}, "rarity": 0, "col": Color("9b733c"), "keys": [], "ex": ["water", "hot", [["nettle", []], ["nettle", []]]]},
	"ache_brew": {"name": "Отвар от ломоты", "use": "Спина гнётся, как в юности.", "base": "water", "temp": "hot", "need": {"Исцеление": 2, "Сила": 2}, "rarity": 0, "col": Color("b0b660"), "keys": [], "ex": ["water", "hot", [["chamomile", []], ["rosehip", []]]]},
	"hunter_brew": {"name": "Охотничий отвар", "use": "Шаги тише, глаза зорче.", "base": "water", "temp": "hot", "need": {"Сила": 2, "Тьма": 1}, "rarity": 1, "col": Color("5d6e46"), "keys": [], "ex": ["water", "hot", [["club_moss", ["soak", "burn"]]]]},
	"dragon_blood": {"name": "Драконья кровь", "use": "Густой и алый. Говорят, после него можно дышать дымом.", "base": "water", "temp": "hot", "need": {"Сила": 3, "Огонь": 4}, "rarity": 2, "col": Color("be7f2a"), "keys": [["dragon_root", "fire_lily"]], "ex": ["water", "hot", [["chamomile", ["burn", "grind"]], ["dragon_root", ["grind"]]]]},
	"sun_brew": {"name": "Солнечный отвар", "use": "В кружке будто плещется кусочек полдня.", "base": "water", "temp": "hot", "need": {"Тепло": 3, "Свет": 3}, "rarity": 2, "col": Color("f3c875"), "keys": [["sunflower_gold"]], "ex": ["water", "hot", [["mint", ["grind", "dry"]], ["sunflower_gold", []]]]},
	"phoenix_brew": {"name": "Отвар феникса", "use": "Поднимает даже того, кто уже не дышит. Легенда травников.", "base": "water", "temp": "hot", "need": {"Исцеление": 5, "Огонь": 6, "Свет": 3}, "rarity": 3, "col": Color("f8af60"), "keys": [["phoenix_grass"]], "ex": ["water", "hot", [["phoenix_grass", []], ["phoenix_grass", []]]]},
	"ice_inf": {"name": "Ледяной настой", "use": "Зубы ломит, а голова — ясная.", "base": "water", "temp": "cold", "need": {"Свежесть": 1, "Холод": 2}, "rarity": 1, "col": Color("82ced2"), "keys": [], "ex": ["water", "cold", [["chamomile", ["cut", "soak"]]]]},
	"cold_mors": {"name": "Холодный морс", "use": "Лучшее, что можно выпить в жару.", "base": "water", "temp": "cold", "need": {"Свежесть": 3, "Холод": 1}, "rarity": 1, "col": Color("6acaa6"), "keys": [], "ex": ["water", "cold", [["mint", ["grind"]]]]},
	"heat_cure": {"name": "Настой от зноя", "use": "Солнечный удар отступает за минуту.", "base": "water", "temp": "cold", "need": {"Покой": 1, "Холод": 2}, "rarity": 1, "col": Color("8dc9e6"), "keys": [], "ex": ["water", "cold", [["mint", ["dry", "soak"]]]]},
	"burn_inf": {"name": "Настой от ожогов", "use": "Примочка — и кожа больше не горит.", "base": "water", "temp": "cold", "need": {"Исцеление": 2, "Холод": 2}, "rarity": 1, "col": Color("c4d4bc"), "keys": [], "ex": ["water", "cold", [["chamomile", ["soak", "grind"]]]]},
	"hush_inf": {"name": "Тихий настой", "use": "Безмолвие внутри. Мысли текут медленно, как река.", "base": "water", "temp": "cold", "need": {"Покой": 3, "Холод": 1}, "rarity": 1, "col": Color("82bed3"), "keys": [], "ex": ["water", "cold", [["lavender", ["grind"]]]]},
	"dew_inf": {"name": "Утренняя роса", "use": "Умыться им — и лицо свежее, как после сна.", "base": "water", "temp": "cold", "need": {"Свежесть": 2, "Холод": 2}, "rarity": 1, "col": Color("79cdc0"), "keys": [], "ex": ["water", "cold", [["strawberry", ["soak"]]]]},
	"night_eye": {"name": "Настой ночного зрения", "use": "В темноте видно, как в сумерках.", "base": "water", "temp": "cold", "need": {"Свежесть": 2, "Тьма": 2}, "rarity": 1, "col": Color("4c7373"), "keys": [], "ex": ["water", "cold", [["mint", []], ["mint", ["burn", "grind"]]]]},
	"fog_inf": {"name": "Настой тумана", "use": "Вокруг тебя стелется туман — попробуй найди.", "base": "water", "temp": "cold", "need": {"Холод": 2, "Тьма": 2}, "rarity": 1, "col": Color("6978a7"), "keys": [], "ex": ["water", "cold", [["lily_valley", ["grind", "burn"]]]]},
	"mermaid_inf": {"name": "Настой русалки", "use": "Под водой можно дышать — недолго, но можно.", "base": "water", "temp": "cold", "need": {"Свежесть": 3, "Холод": 3}, "rarity": 1, "col": Color("79cdc0"), "keys": [["sea_lavender", "sea_kale", "frost_lotus"]], "ex": ["water", "cold", [["mint", []], ["frost_lotus", ["grind", "cut"]]]]},
	"winter_sleep": {"name": "Зимний сон", "use": "Спишь, как медведь в берлоге: глубоко и без снов.", "base": "water", "temp": "cold", "need": {"Сон": 3, "Холод": 3}, "rarity": 2, "col": Color("90a5e2"), "keys": [["frost_lotus"]], "ex": ["water", "cold", [["poppy", ["grind"]], ["frost_lotus", []]]]},
	"moon_tear": {"name": "Слеза луны", "use": "Серебряная капля. Маги платят за неё золотом.", "base": "water", "temp": "cold", "need": {"Холод": 3, "Свет": 3, "Чары": 2}, "rarity": 2, "col": Color("c7bfd5"), "keys": [["moonbloom", "moon_shroom"]], "ex": ["water", "cold", [["mint", ["dry", "soak"]], ["moon_shroom", ["grind"]]]]},
	"glacier_heart": {"name": "Сердце ледника", "use": "Время вокруг замедляется, как зимой подо льдом.", "base": "water", "temp": "cold", "need": {"Покой": 3, "Холод": 6, "Чары": 3}, "rarity": 3, "col": Color("99ade6"), "keys": [["frost_lotus"], ["world_leaf"]], "ex": ["water", "cold", [["frost_lotus", ["grind"]], ["world_leaf", ["grind", "cut"]], ["sea_lavender", ["cut"]]]]},
	"heal_salve": {"name": "Заживляющая мазь", "use": "Затягивает ссадины и порезы.", "base": "wax", "temp": "any", "need": {"Исцеление": 2}, "rarity": 0, "col": Color("f2d684"), "keys": [], "ex": ["wax", "warm", [["chamomile", ["soak", "grind"]]]]},
	"bruise_salve": {"name": "Мазь от ушибов", "use": "Снимает отёк и синяки.", "base": "wax", "temp": "any", "need": {"Исцеление": 1, "Сила": 2}, "rarity": 0, "col": Color("a8b85a"), "keys": [], "ex": ["wax", "warm", [["rosehip", []]]]},
	"cool_salve": {"name": "Холодящая мазь", "use": "Успокаивает ожоги.", "base": "wax", "temp": "any", "need": {"Свежесть": 2, "Покой": 2}, "rarity": 0, "col": Color("9ccce6"), "keys": [], "ex": ["wax", "warm", [["sea_lavender", ["grind", "cut"]]]]},
	"bite_salve": {"name": "Мазь от укусов", "use": "Комары облетают стороной, а укусы не чешутся.", "base": "wax", "temp": "any", "need": {"Свежесть": 2, "Жгучесть": 1}, "rarity": 0, "col": Color("80a071"), "keys": [], "ex": ["wax", "warm", [["mint", []], ["club_moss", []]]]},
	"warm_salve": {"name": "Согревающая мазь", "use": "Растереть спину — и никакой мороз не страшен.", "base": "wax", "temp": "any", "need": {"Тепло": 3, "Жгучесть": 1}, "rarity": 0, "col": Color("e08c3f"), "keys": [], "ex": ["wax", "warm", [["mint", ["grind", "dry"]], ["nettle", []]]]},
	"joint_salve": {"name": "Мазь для суставов", "use": "Колени больше не скрипят на погоду.", "base": "wax", "temp": "any", "need": {"Тепло": 2, "Сила": 2}, "rarity": 0, "col": Color("ab9b3e"), "keys": [], "ex": ["wax", "warm", [["glowmoss", ["grind", "dry"]]]]},
	"callus_salve": {"name": "Мазь от мозолей", "use": "Ноги снова влезают в сапоги.", "base": "wax", "temp": "any", "need": {"Исцеление": 3}, "rarity": 0, "col": Color("f2d684"), "keys": [], "ex": ["wax", "warm", [["yarrow", ["grind"]]]]},
	"frost_salve": {"name": "Мазь от обморожения", "use": "Пальцы оттаивают и розовеют.", "base": "wax", "temp": "any", "need": {"Тепло": 2, "Исцеление": 2}, "rarity": 0, "col": Color("edbb62"), "keys": [], "ex": ["wax", "warm", [["calendula", ["cut", "dry"]]]]},
	"burn_salve": {"name": "Мазь от ожогов", "use": "Кузнецы и пекарши держат её у печи.", "base": "wax", "temp": "any", "need": {"Исцеление": 2, "Холод": 2}, "rarity": 1, "col": Color("c4d4bc"), "keys": [], "ex": ["wax", "warm", [["elf_leaf", ["dry", "soak"]]]]},
	"glow_salve": {"name": "Мазь сияния", "use": "Кожа сияет, как жемчуг. Вампирши завидуют.", "base": "wax", "temp": "any", "need": {"Исцеление": 1, "Свет": 2}, "rarity": 1, "col": Color("fae79d"), "keys": [], "ex": ["wax", "warm", [["unicorn_mane", ["grind", "burn"]]]]},
	"stride_salve": {"name": "Мазь лёгкой походки", "use": "Натереть ступни — и шагаешь, будто летишь.", "base": "wax", "temp": "any", "need": {"Свежесть": 2, "Сила": 2}, "rarity": 0, "col": Color("65af64"), "keys": [], "ex": ["wax", "warm", [["glowmoss", []]]]},
	"paw_salve": {"name": "Мазь для лапок", "use": "Мягкие подушечки. Кошкодевочки берут ящиками.", "base": "wax", "temp": "any", "need": {"Покой": 2, "Исцеление": 2}, "rarity": 0, "col": Color("b7c7a6"), "keys": [["catnip"]], "ex": ["wax", "warm", [["chamomile", ["soak", "grind"]], ["catnip", []]]]},
	"blade_salve": {"name": "Оружейная мазь", "use": "Клинок не ржавеет и режет, как новый.", "base": "wax", "temp": "any", "need": {"Сила": 3, "Жгучесть": 2}, "rarity": 0, "col": Color("927a3c"), "keys": [], "ex": ["wax", "warm", [["nettle", []], ["nettle", []]]]},
	"fireproof": {"name": "Огнеупорная мазь", "use": "Можно взять уголёк голой рукой. Ненадолго.", "base": "wax", "temp": "any", "need": {"Сила": 2, "Холод": 3}, "rarity": 1, "col": Color("86baab"), "keys": [["frost_lotus", "fire_lily"]], "ex": ["wax", "warm", [["nettle", []], ["frost_lotus", []]]]},
	"shadow_salve": {"name": "Теневая мазь", "use": "Ночью тебя не видно даже кошке.", "base": "wax", "temp": "any", "need": {"Покой": 1, "Тьма": 3}, "rarity": 1, "col": Color("4c4475"), "keys": [["shadow_orchid", "nightshade", "void_bloom"]], "ex": ["wax", "warm", [["void_bloom", ["grind", "soak"]]]]},
	"curse_salve": {"name": "Мазь от проклятий", "use": "Снимает сглаз, порчу и дурной глаз соседки.", "base": "wax", "temp": "any", "need": {"Свет": 3, "Чары": 2}, "rarity": 2, "col": Color("e5b4c2"), "keys": [["unicorn_mane", "sunflower_gold"]], "ex": ["wax", "warm", [["unicorn_mane", []], ["moon_shroom", []]]]},
	"dragonscale": {"name": "Мазь драконьей чешуи", "use": "Кожа твёрдая, как чешуя. Стрелы отскакивают.", "base": "wax", "temp": "any", "need": {"Сила": 3, "Огонь": 3}, "rarity": 2, "col": Color("b4822d"), "keys": [["dragon_root"]], "ex": ["wax", "warm", [["mint", ["dry", "burn"]], ["dragon_root", ["grind"]]]]},
	"scar_salve": {"name": "Мазь от шрамов", "use": "Старые шрамы бледнеют и исчезают.", "base": "wax", "temp": "any", "need": {"Свежесть": 1, "Исцеление": 4}, "rarity": 0, "col": Color("d4d385"), "keys": [], "ex": ["wax", "warm", [["unicorn_mane", ["grind", "cut"]]]]},
	"spider_salve": {"name": "Мазь паучьего шага", "use": "Ладони липнут к стенам. Паучихи одобряют.", "base": "wax", "temp": "any", "need": {"Сила": 2, "Тьма": 2}, "rarity": 1, "col": Color("555a4b"), "keys": [["web_grass", "web_shroom"]], "ex": ["wax", "warm", [["nettle", []], ["web_grass", ["grind", "burn"]]]]},
	"itch_salve": {"name": "Мазь от зуда", "use": "После крапивы и комаров — самое то.", "base": "wax", "temp": "any", "need": {"Покой": 2, "Холод": 1}, "rarity": 1, "col": Color("84c0d7"), "keys": [], "ex": ["wax", "warm", [["oregano", ["grind", "soak"]]]]},
	"web_salve": {"name": "Мазь от паутины", "use": "Паутина сама соскальзывает с волос и одежды.", "base": "wax", "temp": "any", "need": {"Покой": 1, "Жгучесть": 2}, "rarity": 0, "col": Color("ae726a"), "keys": [["web_grass", "web_shroom"]], "ex": ["wax", "warm", [["nettle", []], ["web_grass", []]]]},
	"youth_salve": {"name": "Мазь вечной молодости", "use": "Эльфийки молчат, что знают рецепт. Морщины уходят навсегда.", "base": "wax", "temp": "any", "need": {"Исцеление": 6, "Свет": 3, "Чары": 3}, "rarity": 3, "col": Color("e8bda6"), "keys": [["world_leaf"]], "ex": ["wax", "warm", [["phoenix_grass", ["grind", "soak"]], ["world_leaf", []]]]},
	"strength_tinct": {"name": "Крапивная настойка", "use": "Укрепляет после долгой болезни.", "base": "spirit", "temp": "any", "need": {"Сила": 4}, "rarity": 0, "col": Color("5e9a3a"), "keys": [], "ex": ["spirit", "warm", [["crystal_root", ["grind"]]]]},
	"head_tinct": {"name": "Настойка от мигрени", "use": "Прогоняет головную боль.", "base": "spirit", "temp": "any", "need": {"Покой": 2, "Жгучесть": 1}, "rarity": 0, "col": Color("b0589a"), "keys": [], "ex": ["spirit", "warm", [["web_grass", ["grind"]]]]},
	"pepper_tinct": {"name": "Перцовка", "use": "Орки пьют на спор. Травница — по капле от простуды.", "base": "spirit", "temp": "any", "need": {"Тепло": 1, "Жгучесть": 3}, "rarity": 0, "col": Color("d0643d"), "keys": [], "ex": ["spirit", "warm", [["fire_pepper", []]]]},
	"insomnia_tinct": {"name": "Настойка от бессонницы", "use": "Десять капель — и спишь до петухов.", "base": "spirit", "temp": "any", "need": {"Сон": 3}, "rarity": 0, "col": Color("8a78d0"), "keys": [], "ex": ["spirit", "warm", [["poppy", ["grind"]]]]},
	"heart_drops": {"name": "Сердечные капли", "use": "Сердце бьётся ровно, как часы.", "base": "spirit", "temp": "any", "need": {"Покой": 2, "Исцеление": 2}, "rarity": 0, "col": Color("b7c7a6"), "keys": [], "ex": ["spirit", "warm", [["mint", []], ["stonecrop", ["grind", "soak"]]]]},
	"battle_tinct": {"name": "Боевая настойка", "use": "Рыцарши пьют её перед турниром.", "base": "spirit", "temp": "any", "need": {"Сила": 3, "Жгучесть": 2}, "rarity": 0, "col": Color("927a3c"), "keys": [], "ex": ["spirit", "warm", [["nettle", []], ["nettle", []]]]},
	"alert_tinct": {"name": "Настойка бодрости", "use": "Ночь без сна, а глаза ясные.", "base": "spirit", "temp": "any", "need": {"Свежесть": 3, "Сила": 1}, "rarity": 0, "col": Color("60bb78"), "keys": [], "ex": ["spirit", "warm", [["lingonberry", ["grind"]]]]},
	"cough_drops": {"name": "Капли от кашля", "use": "Три капли в тёплую воду — и кашля нет.", "base": "spirit", "temp": "any", "need": {"Свежесть": 2, "Исцеление": 2}, "rarity": 0, "col": Color("a7cf88"), "keys": [], "ex": ["spirit", "warm", [["sage", ["grind", "cut"]]]]},
	"sight_tinct": {"name": "Настойка ясновидения", "use": "Во сне показывают, что будет завтра.", "base": "spirit", "temp": "any", "need": {"Свет": 1, "Чары": 2}, "rarity": 1, "col": Color("d38cd2"), "keys": [], "ex": ["spirit", "warm", [["moon_shroom", []]]]},
	"witch_tinct": {"name": "Ведьмина настойка", "use": "Чёрная, с зелёной искрой. Лучше не спрашивать, зачем.", "base": "spirit", "temp": "any", "need": {"Тьма": 2, "Чары": 2}, "rarity": 1, "col": Color("7d3ca0"), "keys": [], "ex": ["spirit", "warm", [["void_bloom", []]]]},
	"firewater": {"name": "Огненная вода", "use": "Выдохнешь — и свечи загораются сами.", "base": "spirit", "temp": "any", "need": {"Жгучесть": 2, "Огонь": 3}, "rarity": 1, "col": Color("e6622a"), "keys": [], "ex": ["spirit", "warm", [["mint", ["dry", "burn"]], ["fire_pepper", []]]]},
	"night_tinct": {"name": "Ночная настойка", "use": "Спишь днём, бодрствуешь ночью. Как вампирша.", "base": "spirit", "temp": "any", "need": {"Сон": 2, "Тьма": 3}, "rarity": 1, "col": Color("5b4289"), "keys": [], "ex": ["spirit", "warm", [["mint", ["grind", "burn"]], ["nightshade", []]]]},
	"luck_tinct": {"name": "Настойка удачи", "use": "Монетки находятся, а грибы — белые.", "base": "spirit", "temp": "any", "need": {"Свежесть": 1, "Свет": 2, "Чары": 1}, "rarity": 1, "col": Color("c6c0b1"), "keys": [], "ex": ["spirit", "warm", [["moon_shroom", ["grind", "cut"]]]]},
	"berserk": {"name": "Эликсир берсерка", "use": "Ярость без страха и боли. Орочий вождь бы оценил.", "base": "spirit", "temp": "any", "need": {"Сила": 5, "Огонь": 2}, "rarity": 2, "col": Color("968a33"), "keys": [["dragon_root", "ginseng"]], "ex": ["spirit", "warm", [["nettle", []], ["dragon_root", ["grind"]]]]},
	"crimson_tinct": {"name": "Багровая настойка", "use": "Вкус железа и ночи. Вампирши покупают тайком.", "base": "spirit", "temp": "any", "need": {"Исцеление": 1, "Сила": 2, "Тьма": 3}, "rarity": 2, "col": Color("6b6457"), "keys": [["nightshade"]], "ex": ["spirit", "warm", [["rosehip", []], ["nightshade", ["grind", "burn"]]]]},
	"star_tinct": {"name": "Звёздная настойка", "use": "В бутылке кружатся крошечные звёзды.", "base": "spirit", "temp": "any", "need": {"Свет": 3, "Чары": 3}, "rarity": 2, "col": Color("dea5c8"), "keys": [["moonbloom", "crystal_root"]], "ex": ["spirit", "warm", [["moonbloom", []], ["moon_shroom", []]]]},
	"invis_tinct": {"name": "Настойка невидимости", "use": "Тебя не видно. Совсем. Даже в зеркале.", "base": "spirit", "temp": "any", "need": {"Тьма": 4, "Чары": 3}, "rarity": 2, "col": Color("733796"), "keys": [["shadow_orchid"]], "ex": ["spirit", "warm", [["crystal_root", []], ["shadow_orchid", ["grind"]]]]},
	"mandrake_tears": {"name": "Слёзы мандрагоры", "use": "Человечек плакал не зря: сила и сон в одной капле.", "base": "spirit", "temp": "any", "need": {"Сон": 3, "Сила": 3, "Тьма": 1}, "rarity": 1, "col": Color("72787f"), "keys": [["mandrake"]], "ex": ["spirit", "warm", [["nettle", []], ["mandrake", ["grind"]]]]},
	"north_tinct": {"name": "Северная настойка", "use": "Мороз нипочём. Дворфийки пьют её в шахтах.", "base": "spirit", "temp": "any", "need": {"Сила": 2, "Холод": 3}, "rarity": 1, "col": Color("86baab"), "keys": [], "ex": ["spirit", "warm", [["sea_buckthorn", ["grind", "soak"]]]]},
	"balsam": {"name": "Травяной бальзам", "use": "Девять трав, сорок капель. От всего на свете.", "base": "spirit", "temp": "any", "need": {"Свежесть": 1, "Тепло": 2, "Исцеление": 2, "Сила": 1}, "rarity": 1, "col": Color("bfb762"), "keys": [], "ex": ["spirit", "warm", [["mint", ["grind", "dry"]], ["arnica", ["grind", "cut"]]]]},
	"pine_tinct": {"name": "Хвойная настойка", "use": "Пахнет тайгой и смолой. Лёгкие дышат глубже.", "base": "spirit", "temp": "any", "need": {"Свежесть": 2, "Сила": 2}, "rarity": 0, "col": Color("65af64"), "keys": [], "ex": ["spirit", "warm", [["glowmoss", []]]]},
	"wind_tinct": {"name": "Настойка ветра", "use": "Бежишь — и ветер подталкивает в спину.", "base": "spirit", "temp": "any", "need": {"Свежесть": 4, "Чары": 1}, "rarity": 1, "col": Color("6fb29e"), "keys": [], "ex": ["spirit", "warm", [["elf_leaf", ["grind", "cut"]]]]},
	"void_tinct": {"name": "Настойка бездны", "use": "Смотреть в неё долго нельзя. Бездна смотрит в ответ.", "base": "spirit", "temp": "any", "need": {"Тьма": 6, "Чары": 5}, "rarity": 3, "col": Color("773999"), "keys": [["void_bloom"]], "ex": ["spirit", "warm", [["heather", ["burn", "cut"]], ["void_bloom", ["grind", "soak"]], ["void_bloom", ["cut"]]]]},
	"throat_syrup": {"name": "Сироп для горла", "use": "Ложечка — и голос вернулся.", "base": "honey", "temp": "any", "need": {"Тепло": 1, "Исцеление": 2}, "rarity": 0, "col": Color("eec46d"), "keys": [], "ex": ["honey", "warm", [["yarrow", ["cut", "dry"]]]]},
	"kids_syrup": {"name": "Детский сироп", "use": "Сладкий — дети просят ещё и не капризничают.", "base": "honey", "temp": "any", "need": {"Свежесть": 1, "Покой": 1, "Исцеление": 1}, "rarity": 0, "col": Color("98c79d"), "keys": [], "ex": ["honey", "warm", [["clover", ["grind", "cut"]]]]},
	"sleep_syrup": {"name": "Сироп сладкого сна", "use": "Колыбельная в ложке.", "base": "honey", "temp": "any", "need": {"Покой": 1, "Сон": 2}, "rarity": 0, "col": Color("858dcd"), "keys": [], "ex": ["honey", "warm", [["valerian", []]]]},
	"berry_syrup": {"name": "Ягодный сироп", "use": "Лето в бутылке. Зимой — на вес золота.", "base": "honey", "temp": "any", "need": {"Свежесть": 2, "Сила": 1}, "rarity": 0, "col": Color("62b771"), "keys": [], "ex": ["honey", "warm", [["dandelion", ["cut", "grind"]]]]},
	"spice_syrup": {"name": "Пряный сироп", "use": "Корица, перец и мёд. Греет до пяток.", "base": "honey", "temp": "any", "need": {"Тепло": 2, "Жгучесть": 1}, "rarity": 0, "col": Color("dd853e"), "keys": [], "ex": ["honey", "warm", [["fire_pepper", []]]]},
	"love_syrup": {"name": "Сироп нежности", "use": "Щёки розовеют, слова становятся мягкими.", "base": "honey", "temp": "any", "need": {"Тепло": 2, "Свет": 1, "Чары": 1}, "rarity": 1, "col": Color("e3a284"), "keys": [], "ex": ["honey", "warm", [["mint", ["grind", "dry"]], ["moonbloom", []]]]},
	"laugh_syrup": {"name": "Сироп смеха", "use": "Смешно всё: и коровы, и тучи, и даже налоги.", "base": "honey", "temp": "any", "need": {"Свежесть": 2, "Чары": 1}, "rarity": 1, "col": Color("7ca3aa"), "keys": [], "ex": ["honey", "warm", [["sundew", ["cut", "grind"]]]]},
	"might_syrup": {"name": "Сироп силы", "use": "Мешок муки — как пёрышко.", "base": "honey", "temp": "any", "need": {"Тепло": 1, "Сила": 3}, "rarity": 0, "col": Color("8c983d"), "keys": [], "ex": ["honey", "warm", [["crystal_root", ["cut", "dry"]]]]},
	"golden_syrup": {"name": "Золотой сироп", "use": "Густой, как солнечный свет. Лечит тоску и раны.", "base": "honey", "temp": "any", "need": {"Исцеление": 2, "Свет": 3}, "rarity": 2, "col": Color("f9e59a"), "keys": [["sunflower_gold"]], "ex": ["honey", "warm", [["chamomile", ["soak", "grind"]], ["sunflower_gold", []]]]},
	"courage_syrup": {"name": "Сироп отваги", "use": "Сладкая смелость: и к дракону подойдёшь.", "base": "honey", "temp": "any", "need": {"Сила": 2, "Огонь": 1}, "rarity": 1, "col": Color("9c8832"), "keys": [], "ex": ["honey", "warm", [["nettle", ["grind", "burn"]]]]},
	"peace_syrup": {"name": "Сироп покоя", "use": "Буря внутри утихает.", "base": "honey", "temp": "any", "need": {"Покой": 3, "Исцеление": 1}, "rarity": 0, "col": Color("99bfb7"), "keys": [], "ex": ["honey", "warm", [["pink_clover", ["grind"]]]]},
	"fairy_syrup": {"name": "Сироп цветочной феи", "use": "Пчёлы садятся на плечи и не жалят.", "base": "honey", "temp": "any", "need": {"Свежесть": 2, "Свет": 1, "Чары": 2}, "rarity": 1, "col": Color("a3a4b6"), "keys": [["moonbloom", "elf_star", "unicorn_mane"]], "ex": ["honey", "warm", [["heather", ["grind", "cut"]], ["moonbloom", ["grind", "cut"]]]]},
	"joy_syrup": {"name": "Сироп радости", "use": "Хочется петь и обнимать всех подряд.", "base": "honey", "temp": "any", "need": {"Покой": 1, "Тепло": 2, "Свет": 1}, "rarity": 1, "col": Color("d2ba7c"), "keys": [], "ex": ["honey", "warm", [["mint", []], ["calendula", ["cut", "dry"]]]]},
	"hag_syrup": {"name": "Сироп старой ведьмы", "use": "Тёмный и тягучий. Кошмары больше не приходят.", "base": "honey", "temp": "any", "need": {"Тепло": 2, "Тьма": 2}, "rarity": 1, "col": Color("925f4d"), "keys": [], "ex": ["honey", "warm", [["mint", ["grind", "dry"]], ["mint", ["burn", "grind"]]]]},
	"ambrosia": {"name": "Амброзия", "use": "Пища богов. Одна ложка — и год без болезней.", "base": "honey", "temp": "any", "need": {"Исцеление": 5, "Свет": 5, "Чары": 4}, "rarity": 3, "col": Color("e7bbad"), "keys": [["sunflower_gold"], ["world_leaf", "phoenix_grass"]], "ex": ["honey", "warm", [["elf_star", ["grind", "cut"]], ["phoenix_grass", ["burn", "grind"]], ["sunflower_gold", ["cut"]], ["world_leaf", ["burn", "grind"]]]]},
	"moonlight": {"name": "Эликсир лунного света", "use": "Ночью вокруг тебя светло, как в полнолуние.", "base": "moon_dew", "temp": "any", "need": {"Свет": 2, "Чары": 2}, "rarity": 1, "col": Color("dea5c8"), "keys": [], "ex": ["moon_dew", "warm", [["moon_shroom", []]]]},
	"lucid": {"name": "Эликсир снов наяву", "use": "Во сне можно гулять, где захочешь.", "base": "moon_dew", "temp": "any", "need": {"Сон": 3, "Чары": 2}, "rarity": 1, "col": Color("9e6cd8"), "keys": [], "ex": ["moon_dew", "warm", [["moonbloom", []]]]},
	"flight": {"name": "Эликсир полёта", "use": "Ноги едва касаются земли.", "base": "moon_dew", "temp": "any", "need": {"Свежесть": 3, "Чары": 3}, "rarity": 2, "col": Color("8d91b9"), "keys": [["unicorn_mane", "moonbloom", "crystal_root"]], "ex": ["moon_dew", "warm", [["mint", []], ["crystal_root", ["grind", "cut"]]]]},
	"beast_talk": {"name": "Эликсир звериного языка", "use": "Лиса рассказывает сплетни, а ёж — жалуется на соседей.", "base": "moon_dew", "temp": "any", "need": {"Покой": 2, "Чары": 2}, "rarity": 1, "col": Color("9d89d7"), "keys": [], "ex": ["moon_dew", "warm", [["heather", []]]]},
	"cat_form": {"name": "Эликсир кошачьего облика", "use": "Уши, хвост и непреодолимая тяга к коробкам.", "base": "moon_dew", "temp": "any", "need": {"Покой": 2, "Сон": 1, "Чары": 3}, "rarity": 1, "col": Color("9f7ed8"), "keys": [["catnip"]], "ex": ["moon_dew", "warm", [["heather", []], ["catnip", []]]]},
	"night_elixir": {"name": "Эликсир ночи", "use": "Тьма становится мягкой и послушной.", "base": "moon_dew", "temp": "any", "need": {"Тьма": 3, "Чары": 2}, "rarity": 1, "col": Color("703692"), "keys": [["nightshade", "shadow_orchid", "blood_russula"]], "ex": ["moon_dew", "warm", [["shadow_orchid", []]]]},
	"fire_elixir": {"name": "Эликсир пламени", "use": "Огонь не жжёт, а слушается.", "base": "moon_dew", "temp": "any", "need": {"Огонь": 3, "Чары": 2}, "rarity": 1, "col": Color("e2666e"), "keys": [["fire_lily", "fire_pepper", "dragon_root"]], "ex": ["moon_dew", "warm", [["heather", []], ["fire_pepper", ["grind", "burn"]]]]},
	"ice_elixir": {"name": "Эликсир льда", "use": "Касание — и вода покрывается льдом.", "base": "moon_dew", "temp": "any", "need": {"Холод": 3, "Чары": 2}, "rarity": 1, "col": Color("a6a2ef"), "keys": [["frost_lotus", "cloudberry"]], "ex": ["moon_dew", "warm", [["heather", []], ["frost_lotus", []]]]},
	"life_elixir": {"name": "Эликсир жизни", "use": "Возвращает силы самым старым и больным.", "base": "moon_dew", "temp": "any", "need": {"Исцеление": 5, "Свет": 2, "Чары": 3}, "rarity": 2, "col": Color("e5b6a9"), "keys": [["ginseng", "unicorn_mane"]], "ex": ["moon_dew", "warm", [["unicorn_mane", []], ["world_leaf", []]]]},
	"truth": {"name": "Эликсир истины", "use": "Кто выпьет — не сможет соврать до заката.", "base": "moon_dew", "temp": "any", "need": {"Покой": 2, "Свет": 3, "Чары": 1}, "rarity": 1, "col": Color("c8c4be"), "keys": [], "ex": ["moon_dew", "warm", [["lavender", []], ["unicorn_mane", ["burn", "grind"]]]]},
	"fortune": {"name": "Эликсир фортуны", "use": "Кости падают шестёрками, а кошки — на четыре лапы.", "base": "moon_dew", "temp": "any", "need": {"Свежесть": 1, "Свет": 2, "Чары": 3}, "rarity": 2, "col": Color("c39ec3"), "keys": [["moon_shroom"]], "ex": ["moon_dew", "warm", [["moon_shroom", ["grind", "cut"]]]]},
	"dragon_elixir": {"name": "Эликсир дракона", "use": "Глаза с вертикальным зрачком и пламя в груди.", "base": "moon_dew", "temp": "any", "need": {"Сила": 4, "Огонь": 5, "Чары": 2}, "rarity": 3, "col": Color("bc784d"), "keys": [["dragon_root"], ["phoenix_grass"]], "ex": ["moon_dew", "warm", [["phoenix_grass", ["burn", "cut"]], ["crystal_root", []], ["dragon_root", ["grind", "cut"]]]]},
	"unicorn_elixir": {"name": "Эликсир единорога", "use": "Чистый, как первый снег. Единороги подходят сами.", "base": "moon_dew", "temp": "any", "need": {"Покой": 2, "Исцеление": 4, "Свет": 4}, "rarity": 2, "col": Color("dfdaa0"), "keys": [["unicorn_mane"]], "ex": ["moon_dew", "warm", [["lily_valley", ["grind", "dry"]], ["phoenix_grass", ["cut"]], ["unicorn_mane", ["grind", "burn"]]]]},
	"sea_elixir": {"name": "Эликсир морской девы", "use": "Русалки принимают тебя за свою.", "base": "moon_dew", "temp": "any", "need": {"Свежесть": 3, "Холод": 2, "Чары": 2}, "rarity": 1, "col": Color("88abc3"), "keys": [["sea_lavender", "sea_kale"]], "ex": ["moon_dew", "warm", [["sea_lavender", ["cut", "grind"]], ["elf_leaf", ["dry", "soak"]]]]},
	# v22: добавлено вручную (tools/potion_design.py её не знает — при перегенерации вернуть строку)
	"mermaid_tail": {"name": "Эликсир русалочьего хвоста", "use": "Ноги сливаются в серебристый хвост — целый день можно плавать в море и собирать травы со дна.", "base": "moon_dew", "temp": "any", "need": {"Свежесть": 3, "Холод": 2, "Чары": 3}, "rarity": 2, "col": Color("56d2d6"), "keys": [["sea_lavender", "sea_kale", "sea_lettuce", "ice_algae", "siren_lily", "tide_orchid"]], "ex": ["moon_dew", "warm", [["sea_lavender", []], ["sea_kale", []], ["elf_leaf", []], ["crystal_root", []]]]},
	"time_elixir": {"name": "Эликсир времени", "use": "Мир на миг замирает. Часы на башне спорят сами с собой.", "base": "moon_dew", "temp": "any", "need": {"Свет": 3, "Тьма": 3, "Чары": 5}, "rarity": 3, "col": Color("ac72af"), "keys": [["void_bloom"]], "ex": ["moon_dew", "warm", [["void_bloom", []], ["moon_shroom", ["grind"]]]]},
	"philosopher": {"name": "Философский эликсир", "use": "Огонь и лёд, свет и тьма в одной капле. Говорят, его не варил никто.", "base": "moon_dew", "temp": "any", "need": {"Холод": 3, "Огонь": 3, "Свет": 2, "Тьма": 3, "Чары": 3}, "rarity": 3, "col": Color("af8097"), "keys": [["phoenix_grass"], ["world_leaf"], ["void_bloom"]], "ex": ["moon_dew", "warm", [["world_leaf", ["cut", "burn"]], ["void_bloom", ["cut"]], ["phoenix_grass", ["grind", "burn"]], ["calamus", ["grind", "soak"]]]]},
	"murky": {"name": "Мутный отвар", "use": "Ни на что не годится. Но и это опыт.", "base": "", "temp": "any", "need": {}, "rarity": 0, "col": Color("6e6650"), "ex": []},
}

## Жители и их беды. Жители не называют зелье — говорят, что болит.
const VILLAGERS: Array = [
	{"id": "marta", "name": "Марта, пекарша", "tex": "res://art/villager_marta.png"},
	{"id": "lina", "name": "Лина, ткачиха", "tex": "res://art/villager_lina.png"},
	{"id": "tina", "name": "Тина, дочь кузнеца", "tex": "res://art/villager_tim.png"},
]
const ASKS: Dictionary = {
	"sleep_tea": "Третью ночь не сплю — ворочаюсь до самых петухов.",
	"vigor_tea": "После жатвы руки как ватные. Мне бы сил прибавить.",
	"calm_tea": "На душе неспокойно, всё из рук валится.",
	"mint_tea": "Вчера был пир... теперь мутит и жар в голове.",
	"warm_tea": "Простыла у реки — знобит, нос заложило.",
	"heal_salve": "Братишка разбил коленки, ссадины никак не заживают.",
	"bruise_salve": "Ударилась о наковальню — синяк на пол-руки.",
	"cool_salve": "Обожглась у печи, кожа так и горит.",
	"strength_tinct": "После зимней хвори всё никак не окрепну.",
	"head_tinct": "Голова раскалывается с самого утра.",
	"cough_tea": "Кашляю так, что куры разбегаются.",
	"colic_tea": "Малыш плачет ночами, животик болит.",
	"bite_salve": "Комары у реки съели меня живьём.",
	"joint_salve": "Колени скрипят громче калитки.",
	"heat_cure": "Весь день в поле на солнцепёке — голова кругом.",
	"throat_syrup": "Голос сорвала на ярмарке, хриплю, как ворона.",
	"sleep_syrup": "Дочка не засыпает без сказки, а сказки кончились.",
	"frost_salve": "Пальцы отморозила, пока стирала в ручье.",
}

## Цвет жидкости (по зелью или основе)
static func color(id: String) -> Color:
	if PRODUCTS.has(id):
		return PRODUCTS[id]["col"]
	match id:
		"water":
			return Color("7ab4d0")
		"wax":
			return Color("e8c070")
		"spirit":
			return Color("cfe2c6")
		"honey":
			return Color("e8a830")
		"moon_dew":
			return Color("b8c8f8")
	return Color("6e6650")


## Можно ли положить в котёл: трава или гриб
static func is_ingredient(id: String) -> bool:
	return HERBS.DATA.has(id) or SHROOM_PROPS.has(id) or preload("res://tree_db.gd").is_ingredient(id)


## Свойства ингредиента без обработки
static func herb_props(id: String) -> Dictionary:
	var out: Dictionary = {}
	if HERBS.DATA.has(id):
		for p in HERBS.DATA[id]["props"]:
			out[String(p[0])] = int(out.get(String(p[0]), 0)) + int(LEVEL.get(String(p[1]), 1))
		var ex: Dictionary = HERB_EXTRA.get(id, {})
		for k in ex.keys():
			out[k] = int(out.get(k, 0)) + int(ex[k])
	elif SHROOM_PROPS.has(id):
		out = (SHROOM_PROPS[id] as Dictionary).duplicate()
	else:
		out = preload("res://tree_db.gd").ing_props(id)   # v17: листья деревьев и насекомые
	return out


static func _g(v: Dictionary, k: String) -> int:
	return int(v.get(k, 0))


static func _clean(v: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for k in PROPS:
		if int(v.get(k, 0)) > 0:
			out[k] = int(v[k])
	return out


## Самое сильное свойство (при равенстве — первое по порядку PROPS)
static func strongest(v: Dictionary) -> String:
	var best: String = ""
	var bv: int = 0
	for k in PROPS:
		if int(v.get(k, 0)) > bv:
			bv = int(v[k])
			best = String(k)
	return best


## Обработка на столе меняет свойства травы
static func apply_proc(v0: Dictionary, p: String) -> Dictionary:
	var v: Dictionary = v0.duplicate()
	match p:
		"grind":
			var s: String = strongest(v)
			if s != "":
				v[s] = _g(v, s) + 1
		"cut":
			v["Жгучесть"] = 0
			v["Свежесть"] = _g(v, "Свежесть") + 1
		"dry":
			v["Тепло"] = _g(v, "Тепло") + _g(v, "Свежесть")
			v["Свежесть"] = 0
			v["Холод"] = 0
		"burn":
			v["Огонь"] = _g(v, "Огонь") + (_g(v, "Тепло") + _g(v, "Жгучесть") + 1) / 2
			v["Тьма"] = _g(v, "Тьма") + (_g(v, "Покой") + _g(v, "Сон") + 1) / 2
			v["Тепло"] = 0
			v["Жгучесть"] = 0
			v["Покой"] = 0
			v["Сон"] = 0
			v["Свежесть"] = 0
			v["Исцеление"] = _g(v, "Исцеление") / 2
		"soak":
			v["Холод"] = _g(v, "Холод") + _g(v, "Тепло")
			v["Тепло"] = 0
			v["Покой"] = _g(v, "Покой") + _g(v, "Жгучесть")
			v["Жгучесть"] = 0
			v["Свет"] = _g(v, "Свет") + _g(v, "Огонь") / 2
			v["Огонь"] = 0
		"ash":   # пережгла — остался пепел
			v = {"Тьма": 1}
	return _clean(v)


## Ингредиент {id, procs: [..]} -> свойства
static func ing_props(ing: Dictionary) -> Dictionary:
	var v: Dictionary = herb_props(String(ing["id"]))
	for p in ing.get("procs", []):
		v = apply_proc(v, String(p))
	return v


static func mix_list(ings: Array) -> Dictionary:
	var out: Dictionary = {}
	for ing in ings:
		var v: Dictionary = ing_props(ing)
		for k in v.keys():
			out[k] = int(out.get(k, 0)) + int(v[k])
	return _clean(out)


## Вода в котле: холодная добавляет Холод и гасит Тепло, горячая усиливает главное свойство и выпаривает Свежесть
static func finish(m0: Dictionary, base: String, temp: String) -> Dictionary:
	var m: Dictionary = m0.duplicate()
	if base == "water":
		if temp == "cold":
			m["Холод"] = _g(m, "Холод") + 1
			m["Тепло"] = maxi(0, _g(m, "Тепло") - 1)
		elif temp == "hot":
			var s: String = strongest(m)
			if s != "":
				m[s] = _g(m, s) + 1
			m["Свежесть"] = maxi(0, _g(m, "Свежесть") - 1)
	elif base == "moon_dew":
		m["Чары"] = _g(m, "Чары") + 1
	return _clean(m)


static func _keys_ok(id: String, ids: Dictionary) -> bool:
	for grp in PRODUCTS[id].get("keys", []):
		var ok: bool = false
		for g in grp:
			if ids.has(String(g)):
				ok = true
				break
		if not ok:
			return false
	return true


## Что выйдет: самое «точное» подходящее зелье (сумма нужных свойств больше — значит точнее)
static func brew_mix(base: String, temp: String, ings: Array) -> String:
	if ings.is_empty():
		return "murky"
	var m: Dictionary = finish(mix_list(ings), base, temp)
	var ids: Dictionary = {}
	for ing in ings:
		ids[String(ing["id"])] = true
	var best: String = "murky"
	var bs: float = -1.0
	for id in PRODUCTS.keys():
		var d: Dictionary = PRODUCTS[id]
		if String(d["base"]) != base:
			continue
		var tp: String = String(d["temp"])
		if tp != "any" and tp != temp:
			continue
		var need: Dictionary = d["need"]
		var ok: bool = true
		var sc: float = 0.0
		for k in need.keys():
			sc += float(need[k])
			if _g(m, String(k)) < int(need[k]):
				ok = false
				break
		if not ok or not _keys_ok(String(id), ids):
			continue
		if tp != "any":
			sc += 0.5
		if sc > bs:
			bs = sc
			best = String(id)
	return best


## Совместимость со старым кодом: две травы, тёплая вода
static func brew(base: String, a: String, b: String) -> String:
	return brew_mix(base, "warm", [{"id": a}, {"id": b}])


static func mix(a: String, b: String) -> Dictionary:
	return mix_list([{"id": a}, {"id": b}])


static func props_text(m: Dictionary) -> String:
	var parts: Array = []
	for k in PROPS:
		if int(m.get(k, 0)) > 0:
			parts.append("%s %d" % [k, int(m[k])])
	return " · ".join(parts)


static func mix_text(a: String, b: String) -> String:
	return props_text(mix(a, b))


## Подсказка после неудачи: самое близкое зелье этой основы и чего не хватает
static func hint_mix(base: String, temp: String, ings: Array) -> String:
	var m: Dictionary = finish(mix_list(ings), base, temp)
	var best_have: float = -1.0
	var best_missing: String = ""
	for id in PRODUCTS.keys():
		var d: Dictionary = PRODUCTS[id]
		if String(d["base"]) != base or int(d["rarity"]) >= 2:
			continue
		var need: Dictionary = d["need"]
		var have: float = 0.0
		var missing: String = ""
		for k in need.keys():
			if _g(m, String(k)) >= int(need[k]):
				have += 1.0
			elif missing == "":
				missing = String(k)
		have /= float(maxi(1, need.size()))
		if have > best_have and missing != "":
			best_have = have
			best_missing = missing
	if best_have >= 0.5:
		return "Почти получилось! Не хватает свойства «%s»." % best_missing
	return "С этой основой такие травы не дружат. Попробуй другие свойства."


static func hint(base: String, a: String, b: String) -> String:
	return hint_mix(base, "warm", [{"id": a}, {"id": b}])


static func name(id: String) -> String:
	return String(PRODUCTS[id]["name"]) if PRODUCTS.has(id) else id


static func icon(id: String) -> Texture2D:
	var p: String = "res://art/potion_%s.png" % id
	if ResourceLoader.exists(p):
		return load(p)
	return load("res://art/potion_murky.png")


static func is_product(id: String) -> bool:
	return PRODUCTS.has(id)


static func rarity(id: String) -> int:
	return int(PRODUCTS[id]["rarity"]) if PRODUCTS.has(id) else 0


## Цена у торговок: от силы зелья и редкости
static func price(id: String) -> int:
	if not PRODUCTS.has(id) or id == "murky":
		return 1
	var sum: int = 0
	for k in (PRODUCTS[id]["need"] as Dictionary).keys():
		sum += int(PRODUCTS[id]["need"][k])
	return int(round(6.0 + sum * 3.0) * [1.0, 2.5, 6.0, 25.0][rarity(id)])

## v25: свойства новых грибов (shrooms25_db.gd)
static var SHROOM_PROPS: Dictionary = _shroom_props()


static func _shroom_props() -> Dictionary:
	var r: Dictionary = SHROOM_PROPS_BASE.duplicate()
	var s25: Dictionary = preload("res://shrooms25_db.gd").PROPS
	for k in s25.keys():
		r[k] = s25[k]
	return r
