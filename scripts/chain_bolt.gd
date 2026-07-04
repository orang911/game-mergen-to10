@tool
extends Control
class_name ChainBolt


var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if Engine.is_editor_hint():
		start_pos = Vector2(60, 100)
		end_pos = Vector2(200, 40)
		queue_redraw()


func _draw() -> void:
	var mid := (start_pos + end_pos) * 0.5
	var perp := (end_pos - start_pos).orthogonal().normalized() * 18.0
	var pts := PackedVector2Array([start_pos, mid - perp, mid + perp, end_pos])
	draw_polyline(pts, Color(0.95, 0.85, 0.15, 0.65), 4.0, true)
	draw_polyline(pts, Color(1.0, 0.98, 0.7, 0.85), 1.5, true)
