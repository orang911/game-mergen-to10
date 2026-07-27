@tool
extends Control
class_name BattlePathView

const ROAD_TEXTURE_PATH := "res://assets/runtime/ui/battle/core/monster_road.png"

var board_pos := Vector2.ZERO
var board_size := Vector2.ZERO
var margin := 76.0
var corner_radius := 64.0
var end_offset := 64.0

var _road_texture: Texture2D

# Road scale and offset live in GameConfig so the texture, centerline and
# monsters cannot acquire independent transforms.
@export var draw_road_texture := true:
	set(value):
		draw_road_texture = value
		queue_redraw()
@export var show_debug_path := false:
	set(value):
		show_debug_path = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var road_path := ROAD_TEXTURE_PATH
	if ResourceLoader.exists(road_path):
		_road_texture = load(road_path) as Texture2D
	if Engine.is_editor_hint():
		board_pos = Vector2(40, 60)
		board_size = GameConfig.get_board_size()
		margin = 76.0
		queue_redraw()


func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2, new_margin: float) -> void:
	board_pos = new_board_pos
	board_size = new_board_size
	margin = new_margin
	queue_redraw()


func set_path_params(p_corner_radius: float, p_end_offset: float) -> void:
	corner_radius = p_corner_radius
	end_offset = p_end_offset
	queue_redraw()


func _draw() -> void:
	if board_size.x <= 0.0 or board_size.y <= 0.0:
		return

	# The texture and the movement path must use one rect. Do not derive the
	# draw size from the old merged-background frame: that made the road image
	# and monster centerline drift apart when the whole design was scaled.
	if draw_road_texture and _road_texture:
		var draw_rect := GameConfig.get_path_road_rect(board_pos, board_size)
		draw_texture_rect(_road_texture, draw_rect, false)

	# --- debug path ---
	if show_debug_path:
		_draw_debug_path()


func _build_path_points() -> PackedVector2Array:
	return GameConfig.get_path_points_for_board(board_pos, board_size)


func _draw_debug_path() -> void:
	var points := _build_path_points()
	if points.size() < 2:
		return

	draw_polyline(points, Color(1.0, 0.2, 0.2, 0.8), 3.0, true)

	for i in range(points.size()):
		var color := Color.GREEN if i == 0 else (Color.RED if i == points.size() - 1 else Color.YELLOW)
		draw_circle(points[i], 6.0, color)

	var font := ThemeDB.fallback_font
	if font:
		draw_string(font, points[0] + Vector2(8, -14), "SPAWN", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.GREEN)
		draw_string(font, points[-1] + Vector2(8, 6), "GOAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.RED)
