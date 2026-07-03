extends TextureButton
class_name MergeBlock

signal block_pressed(block: MergeBlock)

const BLOCK_SIZE := 132.0

var board_site := Vector2i.ZERO
var had_merged := false
var normal_textures: Array[Texture2D] = []
var selected_textures: Array[Texture2D] = []

var level := 1:
	set(value):
		level = clampi(value, 1, 10)
		_refresh_texture()

var selected := false:
	set(value):
		selected = value
		_refresh_texture()
		_refresh_selected_motion()

func _ready() -> void:
	custom_minimum_size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	focus_mode = Control.FOCUS_NONE
	if not pressed.is_connected(_emit_press):
		pressed.connect(_emit_press)
	_refresh_texture()

func setup(start_level: int, normal: Array[Texture2D], selected_frames: Array[Texture2D]) -> void:
	normal_textures = normal
	selected_textures = selected_frames
	level = start_level
	selected = false
	had_merged = false

func _emit_press() -> void:
	block_pressed.emit(self)

func _refresh_texture() -> void:
	if normal_textures.is_empty() or selected_textures.is_empty():
		return

	var index: int = clampi(level - 1, 0, min(normal_textures.size(), selected_textures.size()) - 1)
	var frame: Texture2D = selected_textures[index] if selected else normal_textures[index]
	texture_normal = frame
	texture_hover = frame
	texture_pressed = selected_textures[index]
	texture_disabled = frame

func _refresh_selected_motion() -> void:
	if not is_inside_tree():
		return
	pivot_offset = size * 0.5
	var tween := create_tween()
	if selected:
		tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func shake() -> void:
	if not is_inside_tree():
		return
	var base_pos := position
	var tween := create_tween()
	tween.tween_property(self, "position", base_pos + Vector2(8, 0), 0.04)
	tween.tween_property(self, "position", base_pos + Vector2(-8, 0), 0.04)
	tween.tween_property(self, "position", base_pos, 0.04)
