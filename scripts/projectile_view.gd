@tool
extends Control
class_name MergeBolt


var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()

# Visual params set by projectile_system, never contains damage/logic.
var element: int = -1
var tier := 1
var projectile_color := Color(0.7, 0.92, 1.0, 0.9)
var trail_color := Color(0.35, 0.75, 1.0, 0.55)
var trail_width := 10.0
var core_width := 4.0
var head_radius := 8.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_apply_element_visuals()
	if Engine.is_editor_hint():
		start_pos = Vector2(40, 80)
		end_pos = Vector2(180, 60)
		progress = 0.5
		queue_redraw()


func apply_event(event: MergeAttackEvent) -> void:
	element = event.element
	tier = event.element_tier
	_apply_element_visuals()
	queue_redraw()


func _apply_element_visuals() -> void:
	match element:
		GameConfig.AttackElement.POISON:
			projectile_color = Color(0.35, 0.9, 0.3, 0.9); trail_color = Color(0.15, 0.7, 0.15, 0.55)
		GameConfig.AttackElement.FREEZE:
			projectile_color = Color(0.7, 0.85, 1.0, 0.9); trail_color = Color(0.3, 0.65, 1.0, 0.55)
		GameConfig.AttackElement.LIGHTNING:
			projectile_color = Color(1.0, 0.95, 0.25, 0.9); trail_color = Color(0.9, 0.8, 0.1, 0.55)
		GameConfig.AttackElement.MAGIC:
			projectile_color = Color(0.75, 0.4, 0.95, 0.9); trail_color = Color(0.45, 0.15, 0.7, 0.55)
		GameConfig.AttackElement.FIRE:
			projectile_color = Color(1.0, 0.45, 0.15, 0.9); trail_color = Color(0.85, 0.25, 0.05, 0.55)
		_:
			projectile_color = Color(0.7, 0.92, 1.0, 0.9); trail_color = Color(0.35, 0.75, 1.0, 0.55)


func _draw() -> void:
	var head := start_pos.lerp(end_pos, progress)
	draw_line(start_pos, head, trail_color, trail_width, true)
	draw_line(start_pos, head, projectile_color, core_width, true)
	draw_circle(head, head_radius, projectile_color)
