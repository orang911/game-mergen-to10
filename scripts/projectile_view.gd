@tool
extends Control
class_name MergeBolt


var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO
var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if Engine.is_editor_hint():
		start_pos = Vector2(40, 80)
		end_pos = Vector2(180, 60)
		progress = 0.5
		queue_redraw()


func _draw() -> void:
	var head := start_pos.lerp(end_pos, progress)
	draw_line(start_pos, head, Color(0.35, 0.75, 1.0, 0.55), 10.0, true)
	draw_line(start_pos, head, Color(1.0, 1.0, 1.0, 0.9), 4.0, true)
	draw_circle(head, 8.0, Color(0.7, 0.92, 1.0, 0.9))
