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
var _highlight_rect: TextureRect
var _imprint_rect: TextureRect
var _label_rect: TextureRect
var _merge_highlight_tween: Tween
var _merge_reveal_tween: Tween
var _motion_tween: Tween
var _motion_base_position := Vector2.ZERO
var _motion_controls_position := false
var skill_imprint_id := ""
var skill_imprint_quality := 1

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
	_shadow_rect.visible = false
	_shadow_rect.modulate = GameConfig.BLOCK_SHADOW_COLOR
	add_child(_shadow_rect)

	_bg_rect = TextureRect.new()
	_bg_rect.name = "Bg"
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# The supplied tile PNG has transparent vertical padding (690x751).
	# Fill the calibrated square visual rect so both axes use the same gap.
	_bg_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_rect)

	_highlight_rect = TextureRect.new()
	_highlight_rect.name = "MergeHighlight"
	_highlight_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_highlight_rect.stretch_mode = TextureRect.STRETCH_SCALE
	_highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_highlight_rect.visible = false
	add_child(_highlight_rect)

	_imprint_rect = TextureRect.new()
	_imprint_rect.name = "SkillImprint"
	_imprint_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imprint_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_imprint_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_imprint_rect.visible = false
	add_child(_imprint_rect)

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
	skill_imprint_id = ""
	skill_imprint_quality = 1
	_refresh_imprint()

func _emit_press() -> void:
	block_pressed.emit(self)

func _refresh() -> void:
	# New tile PNGs already contain their final color, highlight and shadow.
	# Clear any inherited/tweened tint before drawing the base texture.
	modulate = Color.WHITE
	self_modulate = Color.WHITE
	if _bg_rect:
		_bg_rect.modulate = Color.WHITE
		_bg_rect.self_modulate = Color.WHITE
		_bg_rect.material = null
	if _label_rect:
		_label_rect.modulate = Color.WHITE
		_label_rect.self_modulate = Color.WHITE
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
		_bg_rect.modulate = GameConfig.get_block_color_tint(color_name)
		_bg_rect.size = VISUAL_SIZE
		_bg_rect.position = (size - _bg_rect.size) * 0.5
	if _highlight_rect and bg_tex:
		_highlight_rect.texture = bg_tex
		_highlight_rect.size = VISUAL_SIZE
		_highlight_rect.position = (size - _highlight_rect.size) * 0.5
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
	_refresh_imprint()


func set_skill_imprint(skill_id: String, animated: bool = true, quality: int = 1) -> void:
	skill_imprint_id = skill_id
	skill_imprint_quality = clampi(quality, 1, GameConfig.MAX_CARD_LEVEL)
	_refresh_imprint()
	if animated and _imprint_rect and _imprint_rect.visible:
		_imprint_rect.pivot_offset = _imprint_rect.size * 0.5
		_imprint_rect.modulate = Color(1, 1, 1, 0)
		_imprint_rect.scale = Vector2(0.7, 0.7)
		var tween := create_tween()
		tween.parallel().tween_property(_imprint_rect, "modulate:a", 0.88, 0.18)
		tween.parallel().tween_property(_imprint_rect, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func take_skill_imprint() -> Dictionary:
	if skill_imprint_id.is_empty():
		return {}
	var result := {"id": skill_imprint_id, "quality": skill_imprint_quality}
	play_imprint_trigger()
	skill_imprint_id = ""
	skill_imprint_quality = 1
	return result


func play_imprint_trigger() -> void:
	if _imprint_rect == null or not _imprint_rect.visible:
		return
	var tween := create_tween()
	tween.parallel().tween_property(_imprint_rect, "scale", Vector2(1.22, 1.22), 0.10)
	tween.parallel().tween_property(_imprint_rect, "modulate", Color(1.4, 1.4, 1.4, 1.0), 0.10)
	tween.tween_property(_imprint_rect, "modulate:a", 0.0, 0.14)
	tween.tween_callback(func(): _refresh_imprint())


func _refresh_imprint() -> void:
	if _imprint_rect == null:
		return
	if skill_imprint_id.is_empty():
		_imprint_rect.visible = false
		_imprint_rect.texture = null
		_imprint_rect.scale = Vector2.ONE
		_imprint_rect.modulate = Color.WHITE
		return
	var path: String = GameConfig.SKILL_IMPRINT_TEXTURES.get(skill_imprint_id, "")
	var texture := load(path) as Texture2D
	_imprint_rect.texture = texture
	_imprint_rect.visible = texture != null
	_imprint_rect.size = VISUAL_SIZE * 0.94
	_imprint_rect.position = (size - _imprint_rect.size) * 0.5
	_imprint_rect.modulate = Color(1, 1, 1, 0.88)

func _refresh_selected_motion() -> void:
	if not is_inside_tree():
		return
	_kill_motion_tween(true)
	pivot_offset = size * 0.5
	_motion_tween = create_tween()
	if selected:
		_motion_tween.tween_property(self, "scale", Vector2(1.025, 1.025), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_motion_tween.tween_property(self, "scale", Vector2.ONE, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func shake() -> void:
	if not is_inside_tree():
		return
	_kill_motion_tween(true)
	_motion_base_position = position
	_motion_controls_position = true
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "position", _motion_base_position + Vector2(8, 0), 0.04)
	_motion_tween.tween_property(self, "position", _motion_base_position + Vector2(-8, 0), 0.04)
	_motion_tween.tween_property(self, "position", _motion_base_position, 0.04)
	_motion_tween.tween_callback(func():
		_motion_controls_position = false
		_motion_tween = null
	)


func play_merge_result_pop() -> void:
	if not is_inside_tree():
		return
	_kill_motion_tween(true)
	pivot_offset = size * 0.5
	scale = Vector2.ONE * 0.90
	_motion_tween = create_tween()
	_motion_tween.tween_property(self, "scale", Vector2.ONE * 1.14, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_property(self, "scale", Vector2.ONE, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_motion_tween.tween_callback(func(): _motion_tween = null)


func reset_motion() -> void:
	_kill_motion_tween(true)
	scale = Vector2.ONE


func _kill_motion_tween(restore_position: bool) -> void:
	if _motion_tween and _motion_tween.is_valid():
		_motion_tween.kill()
	_motion_tween = null
	if restore_position and _motion_controls_position:
		position = _motion_base_position
	_motion_controls_position = false


func begin_merge_highlight(duration: float) -> void:
	if not is_inside_tree() or _highlight_rect == null:
		return
	_kill_merge_highlight_tween()
	_highlight_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var charge_time := maxf(0.16, duration)
	_merge_highlight_tween = create_tween()
	_merge_highlight_tween.tween_property(
		_highlight_rect,
		"modulate",
		Color(1.0, 0.96, 0.68, 0.72),
		charge_time
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func complete_merge_highlight() -> void:
	if not is_inside_tree() or _highlight_rect == null:
		return
	_kill_merge_highlight_tween()
	_highlight_rect.modulate = Color(1.0, 0.96, 0.68, 0.72)
	_merge_highlight_tween = create_tween()
	_merge_highlight_tween.tween_property(_highlight_rect, "modulate", Color(1.0, 0.98, 0.78, 0.98), 0.06)
	_merge_highlight_tween.tween_property(_highlight_rect, "modulate", Color(1.0, 1.0, 1.0, 0.0), 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func play_merge_result_reveal() -> void:
	if not is_inside_tree() or _label_rect == null:
		return
	if _merge_reveal_tween and _merge_reveal_tween.is_valid():
		_merge_reveal_tween.kill()
	_label_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_label_rect.scale = Vector2.ONE
	_merge_reveal_tween = create_tween()
	_merge_reveal_tween.tween_property(_label_rect, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func cancel_merge_highlight() -> void:
	reset_motion()
	_kill_merge_highlight_tween()
	if _merge_reveal_tween and _merge_reveal_tween.is_valid():
		_merge_reveal_tween.kill()
	if _highlight_rect:
		_highlight_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if _label_rect:
		_label_rect.modulate = Color.WHITE
		_label_rect.scale = Vector2.ONE


func _kill_merge_highlight_tween() -> void:
	if _merge_highlight_tween and _merge_highlight_tween.is_valid():
		_merge_highlight_tween.kill()
