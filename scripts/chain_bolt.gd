@tool
extends Control
class_name ChainBolt


var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

# Visual params set by projectile_system, never contains damage/logic.
var element: int = -1
var tier := 1
var chain_color := Color(0.95, 0.85, 0.15, 0.65)
var chain_core_color := Color(1.0, 0.98, 0.7, 0.85)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_element_visuals()
	if Engine.is_editor_hint():
		start_pos = Vector2(60, 100)
		end_pos = Vector2(200, 40)
		queue_redraw()


func apply_event(event: MergeAttackEvent) -> void:
	element = event.element
	tier = event.element_tier
	_apply_element_visuals()
	queue_redraw()


func _apply_element_visuals() -> void:
	match element:
		GameConfig.AttackElement.LIGHTNING:
			chain_color = Color(0.95, 0.85, 0.15, 0.65); chain_core_color = Color(1.0, 0.98, 0.7, 0.85)
		GameConfig.AttackElement.POISON:
			chain_color = Color(0.2, 0.75, 0.2, 0.55); chain_core_color = Color(0.5, 0.95, 0.4, 0.8)
		GameConfig.AttackElement.FREEZE:
			chain_color = Color(0.35, 0.7, 1.0, 0.55); chain_core_color = Color(0.75, 0.9, 1.0, 0.8)
		GameConfig.AttackElement.MAGIC:
			chain_color = Color(0.55, 0.2, 0.85, 0.55); chain_core_color = Color(0.8, 0.5, 1.0, 0.8)
		GameConfig.AttackElement.FIRE:
			chain_color = Color(0.9, 0.35, 0.1, 0.55); chain_core_color = Color(1.0, 0.6, 0.2, 0.8)
		_:
			chain_color = Color(0.95, 0.85, 0.15, 0.65); chain_core_color = Color(1.0, 0.98, 0.7, 0.85)


func _draw() -> void:
	var mid := (start_pos + end_pos) * 0.5
	var perp := (end_pos - start_pos).orthogonal().normalized() * 18.0
	var pts := PackedVector2Array([start_pos, mid - perp, mid + perp, end_pos])
	draw_polyline(pts, chain_color, 4.0, true)
	draw_polyline(pts, chain_core_color, 1.5, true)
