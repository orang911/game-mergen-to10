@tool
extends Control
class_name BlockPreview


const BLOCK_SIZE := GameConfig.BLOCK_SIZE

@export var level := 1:
	set(value):
		level = clampi(value, 1, 10)
		_refresh()
@export var selected := false:
	set(value):
		selected = value
		_refresh()

var _texture_rect: TextureRect
var _label: Label
var _normal_textures: Array[Texture2D] = []
var _selected_textures: Array[Texture2D] = []


func _ready() -> void:
	custom_minimum_size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	size = Vector2(BLOCK_SIZE, BLOCK_SIZE)
	_texture_rect = TextureRect.new()
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_texture_rect.size = size
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_texture_rect)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 42)
	_label.add_theme_color_override("font_color", Color.WHITE)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.size = size
	_label.position = Vector2.ZERO
	add_child(_label)

	_load_textures()
	_refresh()


func _load_textures() -> void:
	for i in range(1, 11):
		var key := "%02d" % i
		_normal_textures.append(load("res://assets/textrues/mian/plate_%s_down.png" % key))
		_selected_textures.append(load("res://assets/textrues/mian/plate_%s_up.png" % key))


func _refresh() -> void:
	if _texture_rect == null or not is_instance_valid(_texture_rect):
		return
	var idx: int = clampi(level - 1, 0, 9)
	if idx >= _normal_textures.size() or idx >= _selected_textures.size():
		return
	_texture_rect.texture = _selected_textures[idx] if selected else _normal_textures[idx]
	_label.text = str(level)
