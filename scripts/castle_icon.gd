@tool
extends Control
class_name CastleIcon


func _ready() -> void:
	# Default size for editor preview
	if size.x < 1.0:
		size = Vector2(72, 72)


func _draw() -> void:
	var blue := Color(0.24, 0.57, 0.95, 1.0)
	var wall := Color(0.96, 0.93, 0.88, 1.0)
	var edge := Color(0.55, 0.60, 0.68, 1.0)
	var door := Color(0.48, 0.25, 0.13, 1.0)
	draw_circle(Vector2(36, 58), 24, Color(0.43, 0.73, 0.42, 0.35))
	draw_rect(Rect2(18, 30, 36, 31), wall, true)
	draw_rect(Rect2(18, 30, 36, 31), edge, false, 2.0)
	draw_rect(Rect2(6, 36, 16, 26), wall, true)
	draw_rect(Rect2(50, 36, 16, 26), wall, true)
	draw_rect(Rect2(28, 43, 16, 19), door, true)
	draw_polygon(PackedVector2Array([Vector2(36, 6), Vector2(18, 30), Vector2(54, 30)]), PackedColorArray([blue, blue, blue]))
	draw_polygon(PackedVector2Array([Vector2(14, 18), Vector2(5, 36), Vector2(23, 36)]), PackedColorArray([blue, blue, blue]))
	draw_polygon(PackedVector2Array([Vector2(58, 18), Vector2(49, 36), Vector2(67, 36)]), PackedColorArray([blue, blue, blue]))
	draw_line(Vector2(38, 8), Vector2(38, 0), Color(0.35, 0.2, 0.1, 1.0), 2.0)
	draw_polygon(PackedVector2Array([Vector2(40, 1), Vector2(56, 5), Vector2(40, 10)]), PackedColorArray([blue, blue, blue]))
