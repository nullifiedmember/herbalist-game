extends RefCounted
## v27: пол у каждого животного. У каждой особи он свой (случайный), у некоторых видов задан по виду.
## "f" — самка, "m" — самец.

# виды, где пол задан жёстко или с перекосом: вид -> шанс самки (0..1)
const BIAS: Dictionary = {
	"cow": 1.0, "chicken": 0.85, "sheep": 0.9, "goat": 0.9, "pig": 0.9, "goose": 0.6,
	"unicorn": 0.5, "stray_cat": 0.5,
}

# особые названия: вид -> [самка, самец]
const WORDS: Dictionary = {
	"cow": ["корова", "бык"], "chicken": ["курица", "петух"], "sheep": ["овца", "баран"], "goat": ["коза", "козёл"],
	"pig": ["свинья", "хряк"], "goose": ["гусыня", "гусь"], "duck": ["утка", "селезень"], "deer": ["лань", "олень"],
	"horse": ["кобыла", "жеребец"], "pony": ["пони-кобылка", "пони-жеребец"], "elk": ["лосиха", "лось"],
	"boar": ["свиноматка", "кабан"], "fox": ["лисица", "лис"], "wolf": ["волчица", "волк"], "bear": ["медведица", "медведь"],
	"rabbit": ["крольчиха", "кролик"], "squirrel": ["белка-самка", "белка-самец"],
}


static func roll(kind: String) -> String:
	var p: float = float(BIAS.get(kind, 0.5))
	return "f" if randf() < p else "m"


## «самка», «корова» и т.п.; со значком пола
static func label(kind: String, sex: String) -> String:
	var i: int = 0 if sex == "f" else 1
	var w: String = String((WORDS[kind] as Array)[i]) if WORDS.has(kind) else ("самка" if sex == "f" else "самец")
	return ("♀ " if sex == "f" else "♂ ") + w


## Для справочников: как пол устроен у вида
static func species_text(kind: String) -> String:
	if float(BIAS.get(kind, 0.5)) >= 1.0:
		return "♀ только самки"
	if WORDS.has(kind):
		return "♀ %s / ♂ %s" % [String((WORDS[kind] as Array)[0]), String((WORDS[kind] as Array)[1])]
	return "♀ самка / ♂ самец"
