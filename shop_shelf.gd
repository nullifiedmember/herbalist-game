extends Node2D
## Полка в лавке: на досках стоят вещи — видно значок и ценник (монетка и цифры пикселями).
## E у полки — полка крупно (shelf_ui.gd): кликнуть вещь — купить. Купленное исчезает до завтра.

const IT = preload("res://items_db.gd")
# Что продают лавки разных земель (на две полки, до 12 вещей)
const STOCK: Dictionary = {
	"cats": ["pack_basket", "hat_straw", "ring_copper", "gloves_garden", "sickle", "knife", "belt_rope", "dress", "pack_sack", "boots_old", "wreath", "net"],
	"knights": ["belt_leather", "boots_travel", "gloves_leather", "cloak_travel", "axe", "pickaxe", "shovel", "pack_travel", "hood", "ring_copper", "lantern_hand", "pack_sack"],
	"elves": ["wreath", "amulet_clover", "gold_sickle", "pack_herb", "sickle", "gloves_garden", "dress", "ring_moss", "hat_straw", "trowel", "net"],
	"mages": ["amulet_moon", "ring_amber", "goggles", "lab_coat", "herbarium", "witch_hat", "apron", "pack_alch", "lantern_hand", "belt_leather"],
	"dwarves": ["pickaxe", "axe", "shovel", "trowel", "knife", "belt_leather", "gloves_leather", "boots_travel", "lantern_hand", "pack_travel", "ring_copper", "gloves_fire"],
	"orcs": ["pickaxe", "pack_creel", "belt_rope", "boots_old", "knife", "axe", "gloves_leather", "ring_copper", "rags", "pack_sack", "shovel", "gloves_fire"],
	"goblins": ["pickaxe", "pack_creel", "belt_rope", "boots_old", "knife", "rags", "pack_sack", "ring_copper", "trowel", "lantern_hand"],
	"gothic": ["lantern_hand", "amulet_moon", "cloak_travel", "hood", "ring_amber", "witch_hat", "herbarium", "boots_travel", "apron"],
	"spider": ["pack_basket", "knife", "gloves_leather", "ring_moss", "hood", "apron", "lantern_hand", "trowel"],
	"japan": ["hat_straw", "sickle", "gold_sickle", "trowel", "pack_herb", "wreath", "dress", "belt_rope", "ring_moss", "net"],
	"sea": ["pack_creel", "ring_amber", "amulet_clover", "hat_straw", "belt_rope", "boots_old", "knife"],
}
# Третья полка в каждой лавке — для зельевара: бутылочки и основы
const ALCH: Dictionary = {
	"mages": ["bottle", "bottle", "spirit", "honey", "moon_dew", "moon_dew"],
	"elves": ["bottle", "bottle", "honey", "wax", "moon_dew", "spirit"],
	"gothic": ["bottle", "bottle", "spirit", "spirit", "wax", "moon_dew"],
}
const ALCH_DEFAULT: Array = ["bottle", "bottle", "bottle", "wax", "spirit", "honey"]
# где на картинке полки стоят вещи: 3 доски по 2 вещи (от ног полки)
const SPOTS: Array = [Vector2(-20, -66), Vector2(20, -66), Vector2(-20, -38), Vector2(20, -38), Vector2(-20, -10), Vector2(20, -10)]

var land: String = "cats"
var shelf_i: int = 0                 # 0 — левая полка, 1 — правая
var shop_key: String = ""            # какая лавка (чтобы купленное не появлялось снова сегодня)
var interact_offset: Vector2 = Vector2(0, 8)
var icons: Array = []
var digits: Texture2D
var coin: Texture2D


func _ready() -> void:
	add_to_group("interactables")
	digits = load("res://art/price_digits.png") if ResourceLoader.exists("res://art/price_digits.png") else null
	coin = load("res://art/price_coin.png") if ResourceLoader.exists("res://art/price_coin.png") else null
	for i in range(SPOTS.size()):
		var s: Sprite2D = Sprite2D.new()
		s.centered = false
		s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(s)
		icons.append(s)
	refresh()


## Вещи на этой полке: [индекс в товарах лавки, id]
func items() -> Array:
	var all: Array = STOCK.get(land, STOCK["cats"])
	var out: Array = []
	if shelf_i == 2:
		var al: Array = ALCH.get(land, ALCH_DEFAULT)
		for k2 in range(al.size()):
			out.append([100 + k2, String(al[k2])])
		return out
	for k in range(SPOTS.size()):
		var gi: int = shelf_i * SPOTS.size() + k
		if gi < all.size():
			out.append([gi, String(all[gi])])
	return out


func sold(gi: int) -> bool:
	return int(Game.shop_sold.get("%s:%d" % [shop_key, gi], -1)) == Game.day


func price(id: String) -> int:
	return Game.rep_price(land, int(IT.gear(id).get("price", IT.PRICE.get(id, 10))))


func buy(gi: int, id: String) -> bool:
	if sold(gi):
		return false
	var p: int = price(id)
	if Game.coins < p:
		return false
	Game.coins -= p
	Game.shop_sold["%s:%d" % [shop_key, gi]] = Game.day
	Game.add_item(id, int(IT.PACK.get(id, 1)))
	Game.rep_add(land, 1, true)
	Sound.play("coin", -4.0)
	refresh()
	return true


func refresh() -> void:
	var its: Array = items()
	for k in range(SPOTS.size()):
		var s: Sprite2D = icons[k]
		s.visible = false
		if k < its.size() and not sold(int(its[k][0])):
			s.texture = IT.icon(String(its[k][1]))
			s.position = (SPOTS[k] as Vector2) + Vector2(-12, -23)
			s.visible = true
	queue_redraw()


## Ценники: монетка и цифры под каждой вещью
func _draw() -> void:
	if digits == null:
		return
	var its: Array = items()
	for k in range(mini(its.size(), SPOTS.size())):
		if sold(int(its[k][0])):
			continue
		var txt: String = str(price(String(its[k][1])))
		var w: float = 6.0 + txt.length() * 4.0
		var p: Vector2 = (SPOTS[k] as Vector2) + Vector2(-w / 2.0, 1)
		draw_rect(Rect2(p + Vector2(-1, -1), Vector2(w + 2, 7)), Color("f4e8c8"))
		draw_rect(Rect2(p + Vector2(-1, 6), Vector2(w + 2, 1)), Color("8a6a40"))
		if coin != null:
			draw_texture(coin, p)
		for j in range(txt.length()):
			var dgt: int = int(txt[j])
			draw_texture_rect_region(digits, Rect2(p + Vector2(6 + j * 4, 0), Vector2(3, 5)), Rect2(dgt * 3, 0, 3, 5))


func get_prompt() -> String:
	return "Полка с товаром"


func interact() -> void:
	var ui: Node = get_tree().get_first_node_in_group("shelf_ui")
	if ui != null:
		ui.call("open_shelf", self)
