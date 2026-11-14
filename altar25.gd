extends Node2D
## v25: алтарь сферы. Над каменной чашей парит сфера стихии; E — коснуться и открыть стихию в книге сфер.

const SP = preload("res://spells25_db.gd")

var el: String = "cold"
var interact_offset: Vector2 = Vector2(0, -30)
var orb: Sprite2D
var t: float = 0.0


func setup(element: String, at: Vector2) -> void:
	el = element
	position = at
	var base: Sprite2D = Sprite2D.new()
	base.texture = load("res://art/altar25.png")
	base.centered = false
	base.offset = Vector2(-24, -62)
	add_child(base)
	orb = Sprite2D.new()
	orb.texture = SP.icon(el)
	orb.position = Vector2(0, -44)
	add_child(orb)
	var p: CPUParticles2D = CPUParticles2D.new()
	p.texture = load("res://art/fx_orb25.png")
	p.amount = 10
	p.lifetime = 1.6
	p.position = Vector2(0, -44)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 10.0
	p.gravity = Vector2(0, -10)
	p.scale_amount_min = 0.3
	p.scale_amount_max = 0.6
	p.color = (SP.EL[el] as Array)[1]
	add_child(p)


func _ready() -> void:
	add_to_group("interactables")
	add_to_group("altars25")


func _process(delta: float) -> void:
	t += delta
	if orb != null:
		orb.position.y = -44.0 + sin(t * 2.0) * 2.5
		orb.modulate.a = 0.45 if Game.orbs_open.has(el) else 1.0


func get_prompt() -> String:
	if Game.orbs_open.has(el):
		return ""
	return "Коснуться сферы: " + String((SP.EL[el] as Array)[0])


func interact() -> void:
	if Game.orbs_open.has(el):
		return
	Game.orbs_open.append(el)
	Sound.play("cast_" + el, -2.0)
	Sound.play("magic", -4.0)
	Game.fx.emit(global_position + Vector2(0, -44), "heart")
	Game.toast.emit("Новая стихия в книге сфер: %s!" % String((SP.EL[el] as Array)[0]), SP.icon(el))
	Game.chron("Открыла стихию «%s» на древнем алтаре." % String((SP.EL[el] as Array)[0]), "magic")
