@tool
extends Control
class_name BattlePathView

const SLICE_DIR := "res://assets/sliced_20260703_172750/"

var board_pos := Vector2.ZERO
var board_size := Vector2.ZERO
var margin := 76.0
var corner_radius := 64.0
var end_offset := 64.0

var _arrow_color := Color(0.72, 0.58, 0.42, 0.42)
var _arrow_textures: Dictionary[String, Texture2D] = {}
var _road_rect: TextureRect

@export var road_scale := 1.0:
	set(value):
		road_scale = value
		_apply_road_transform()
@export var road_offset := Vector2.ZERO:
	set(value):
		road_offset = value
		_apply_road_transform()
@export var show_debug_path := true:
	set(value):
		show_debug_path = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_road_rect = get_node_or_null("RoadImage") as TextureRect
	_load_arrow_textures()
	if Engine.is_editor_hint():
		board_pos = Vector2(40, 60)
		board_size = GameConfig.get_board_size()
		margin = 76.0
		_apply_road_transform()
		queue_redraw()


func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2, new_margin: float) -> void:
	board_pos = new_board_pos
	board_size = new_board_size
	margin = new_margin
	_apply_road_transform()
	queue_redraw()


func set_path_params(p_corner_radius: float, p_end_offset: float) -> void:
	corner_radius = p_corner_radius
	end_offset = p_end_offset
	queue_redraw()


func _apply_road_transform() -> void:
	if _road_rect == null or not is_instance_valid(_road_rect):
		return
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return

	var tex: Texture2D = _road_rect.texture
	if tex == null:
		return

	var center := board_pos + board_size * 0.5
	var tex_size := tex.get_size() * road_scale
	_road_rect.position = center - tex_size * 0.5 + road_offset
	_road_rect.size = tex_size


func _draw() -> void:
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return

	# --- debug: actual monster path ---
	if show_debug_path:
		_draw_debug_path()

	# --- arrows ---
	var left := board_pos.x - margin
	var top := board_pos.y - margin
	var right := board_pos.x + board_size.x + margin
	var bottom := board_pos.y + board_size.y + margin

	_draw_route_arrow("right", Vector2(left + 95, top), Vector2.RIGHT)
	_draw_route_arrow("right", Vector2(left + 245, top), Vector2.RIGHT)
	_draw_route_arrow("right", Vector2(left + 395, top), Vector2.RIGHT)
	_draw_route_arrow("down", Vector2(right, top + 150), Vector2.DOWN)
	_draw_route_arrow("down", Vector2(right, top + 320), Vector2.DOWN)
	_draw_route_arrow("down", Vector2(right, top + 490), Vector2.DOWN)
	_draw_route_arrow("left", Vector2(right - 100, bottom), Vector2.LEFT)
	_draw_route_arrow("left", Vector2(right - 245, bottom), Vector2.LEFT)
	_draw_route_arrow("left", Vector2(right - 390, bottom), Vector2.LEFT)
	_draw_route_arrow("up", Vector2(left, bottom - 160), Vector2.UP)
	_draw_route_arrow("up", Vector2(left, bottom - 330), Vector2.UP)
	_draw_route_arrow("up", Vector2(left, bottom - 500), Vector2.UP)


func _build_path_points() -> PackedVector2Array:
	var r := corner_radius
	var left := board_pos.x - margin
	var top := board_pos.y - margin
	var right := board_pos.x + board_size.x + margin
	var bottom := board_pos.y + board_size.y + margin

	var points := PackedVector2Array()
	points.append(Vector2(left + r, top))
	points.append(Vector2(right - r, top))
	points.append(Vector2(right, top + r))
	points.append(Vector2(right, bottom - r))
	points.append(Vector2(right - r, bottom))
	points.append(Vector2(left + r, bottom))
	points.append(Vector2(left, bottom - r))
	points.append(Vector2(left, top + end_offset))
	return points


func _draw_debug_path() -> void:
	var points := _build_path_points()
	if points.size() < 2:
		return

	# red line showing actual monster path center
	draw_polyline(points, Color(1.0, 0.2, 0.2, 0.8), 3.0, true)

	# dots at each waypoint
	for i in range(points.size()):
		var color := Color.GREEN if i == 0 else (Color.RED if i == points.size() - 1 else Color.YELLOW)
		draw_circle(points[i], 6.0, color)

	# spawn (green) and goal (red) labels
	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, points[0] + Vector2(8, -14), "SPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
		draw_string(font, points[-1] + Vector2(8, 6), "GOAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)


func _load_arrow_textures() -> void:
	for key in ["up", "down", "left", "right"]:
		var path := "%spath_arrow_%s.png" % [SLICE_DIR, key]
		if ResourceLoader.exists(path):
			_arrow_textures[key] = load(path) as Texture2D


func _draw_route_arrow(texture_key: String, center: Vector2, fallback_dir: Vector2) -> void:
	var texture: Texture2D = _arrow_textures.get(texture_key, null)
	if texture == null:
		_draw_arrow(center, fallback_dir)
		return
	var texture_size := texture.get_size()
	var draw_size := texture_size * 1.18
	draw_texture_rect(texture, Rect2(center - draw_size * 0.5, draw_size), false, Color(1, 1, 1, 0.58))


func _draw_arrow(center: Vector2, dir: Vector2) -> void:
	var n := dir.normalized()
	var side := Vector2(-n.y, n.x)
	var tip := center + n * 24.0
	var tail := center - n * 20.0
	draw_line(tail, center + n * 10.0, _arrow_color, 7.0, true)
	var head := PackedVector2Array([
		tip,
		center - n * 3.0 + side * 14.0,
		center - n * 3.0 - side * 14.0,
	])
	draw_colored_polygon(head, _arrow_color)
