@tool
extends Control
class_name BlockPreview


const CELL_SIZE := GameConfig.BLOCK_SIZE
const VISUAL_SIZE := GameConfig.BLOCK_VISUAL_SIZE
const LABEL_MAX := minf(VISUAL_SIZE.x, VISUAL_SIZE.y) * GameConfig.BLOCK_LABEL_FILL

@export var level := 1:
	set(value):
		level = clampi(value, 1, GameConfig.MAX_BLOCK_LEVEL)
		_refresh()
@export var selected := false:
	set(value):
		selected = value
		_refresh()

var _shadow_rect: TextureRect
var _bg_rect: TextureRect
var _label_rect: TextureRect
var _bg_textures: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	size = Vector2(CELL_SIZE, CELL_SIZE)

	_shadow_rect = TextureRect.new()
	_shadow_rect.name = "Shadow"
	_shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow_rect.visible = false
	_shadow_rect.modulate = GameConfig.BLOCK_SHADOW_COLOR
	add_child(_shadow_rect)

	_bg_rect = TextureRect.new()
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_label_rect = TextureRect.new()
	_label_rect.name = "LabelOverlay"
	_label_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_label_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(_label_rect)

	_load_textures()
	_refresh()


func _load_textures() -> void:
	for color_name in GameConfig.BLOCK_BG_PATHS:
		_bg_textures[color_name] = load(GameConfig.BLOCK_BG_PATHS[color_name]) as Texture2D


func _refresh() -> void:
	if _bg_rect == null or not is_instance_valid(_bg_rect):
		return
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	_bg_rect.modulate = Color.WHITE
	_bg_rect.self_modulate = Color.WHITE
	_bg_rect.material = null

	var color_name := GameConfig.get_block_color_name(level)
	var bg_tex: Texture2D = _bg_textures.get(color_name)
	if bg_tex:
		_bg_rect.texture = bg_tex
		_bg_rect.modulate = GameConfig.get_block_color_tint(color_name)
		_bg_rect.size = VISUAL_SIZE
		_bg_rect.position = (size - _bg_rect.size) * 0.5
	if _shadow_rect and bg_tex:
		_shadow_rect.texture = bg_tex
		_shadow_rect.modulate = GameConfig.BLOCK_SHADOW_COLOR
		_shadow_rect.size = VISUAL_SIZE * GameConfig.BLOCK_SHADOW_SCALE
		_shadow_rect.position = (size - _shadow_rect.size) * 0.5 + GameConfig.BLOCK_SHADOW_OFFSET

	var path := GameConfig.get_label_texture_path(level)
	var label_tex := load(path) as Texture2D
	if _label_rect and label_tex:
		_label_rect.texture = label_tex
		var tex_sz: Vector2 = label_tex.get_size()
		var scale: float = LABEL_MAX / maxf(tex_sz.x, tex_sz.y)
		var label_size: Vector2 = tex_sz * scale
		_label_rect.size = label_size
		_label_rect.position = (size - label_size) * 0.5
