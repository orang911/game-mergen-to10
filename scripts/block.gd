extends TextureButton
class_name MergeBlock

signal block_pressed(block: MergeBlock)

const CELL_SIZE := GameConfig.BLOCK_SIZE
const VISUAL_SIZE := GameConfig.BLOCK_VISUAL_SIZE
const LABEL_MAX := minf(VISUAL_SIZE.x, VISUAL_SIZE.y) * GameConfig.BLOCK_LABEL_FILL

var board_site := Vector2i.ZERO
var had_merged := false
var _bg_textures: Dictionary = {}
var _shadow_rect: TextureRect
var _bg_rect: TextureRect
var _label_rect: TextureRect

var level := 1:
	set(value):
		level = clampi(value, 1, GameConfig.MAX_BLOCK_LEVEL)
		_refresh()

var selected := false:
	set(value):
		selected = value
		_refresh()
		_refresh_selected_motion()

func _ready() -> void:
	custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
	size = Vector2(CELL_SIZE, CELL_SIZE)
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_SCALE
	focus_mode = Control.FOCUS_NONE

	_shadow_rect = TextureRect.new()
	_shadow_rect.name = "Shadow"
	_shadow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_shadow_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_shadow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow_rect.modulate = GameConfig.BLOCK_SHADOW_COLOR
	add_child(_shadow_rect)

	_bg_rect = TextureRect.new()
	_bg_rect.name = "Bg"
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

	if not pressed.is_connected(_emit_press):
		pressed.connect(_emit_press)
	_refresh()

func setup(start_level: int, bg_textures: Dictionary) -> void:
	_bg_textures = bg_textures
	level = start_level
	selected = false
	had_merged = false

func _emit_press() -> void:
	block_pressed.emit(self)

func _refresh() -> void:
	var color_name := GameConfig.get_block_color_name(level)
	var bg_tex: Texture2D = _bg_textures.get(color_name)

	# Clear TextureButton textures — visual comes from children
	texture_normal = null
	texture_hover = null
	texture_pressed = null
	texture_disabled = null

	# Background rect centered in cell
	if _bg_rect and bg_tex:
		_bg_rect.texture = bg_tex
		_bg_rect.size = VISUAL_SIZE
		_bg_rect.position = (size - _bg_rect.size) * 0.5
	if _shadow_rect and bg_tex:
		_shadow_rect.texture = bg_tex
		_shadow_rect.modulate = GameConfig.BLOCK_SHADOW_COLOR
		_shadow_rect.size = VISUAL_SIZE * GameConfig.BLOCK_SHADOW_SCALE
		_shadow_rect.position = (size - _shadow_rect.size) * 0.5 + GameConfig.BLOCK_SHADOW_OFFSET

	# Text overlay centered within the bg rect
	var path := GameConfig.get_label_texture_path(level)
	var label_tex := load(path) as Texture2D
	if _label_rect and label_tex:
		_label_rect.texture = label_tex
		var tex_sz: Vector2 = label_tex.get_size()
		var scale: float = LABEL_MAX / maxf(tex_sz.x, tex_sz.y)
		var label_size: Vector2 = tex_sz * scale
		_label_rect.size = label_size
		_label_rect.position = (size - label_size) * 0.5

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
