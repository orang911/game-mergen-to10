@tool
extends Control
class_name BoardGridPreview


const BLOCK_SIZE := GameConfig.BLOCK_SIZE
const GRID_SIZE := GameConfig.GRID_SIZE

@export var show_labels := true:
	set(value):
		show_labels = value
		queue_redraw()

var _bg_texture: Texture2D


func _ready() -> void:
	custom_minimum_size = GameConfig.get_board_backdrop_size()
	size = GameConfig.get_board_backdrop_size()
	_bg_texture = load("res://assets/runtime/ui/common/legacy_game_background.png")
	queue_redraw()


func _draw() -> void:
	if _bg_texture:
		draw_texture_rect(_bg_texture, Rect2(Vector2.ZERO, size), false)

	var offset := GameConfig.get_board_grid_offset_in_plate()
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos := offset + GameConfig.get_block_position_for_site(Vector2i(x, y))
			var cell := Rect2(pos, Vector2(BLOCK_SIZE, BLOCK_SIZE))
			draw_rect(cell, Color(0.2, 0.18, 0.15, 0.35), false, 1.5)
			if show_labels:
				var label_pos := pos + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5 - 10)
				draw_string(ThemeDB.fallback_font, label_pos, "(%d,%d)" % [x, y], HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 1, 1, 0.4))
