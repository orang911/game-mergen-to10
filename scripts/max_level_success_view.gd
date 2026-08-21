extends Control
class_name MaxLevelSuccessView

signal continue_pressed

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const LIGHT_SIZE := Vector2(941.0, 742.0)
const PANEL_SIZE := Vector2(873.0, 1066.0)
const PANEL_Y_RATIO := 0.22
const LIGHT_Y_RATIO := 0.08
const BLOCK_SIZE := Vector2(220.0, 220.0)
const BLOCK_POSITION := Vector2(327.0, 275.0)
const BUTTON_POSITION := Vector2(182.0, 745.0)
const BUTTON_SIZE := Vector2(510.0, 209.0)

const LIGHT_TEXTURE := preload("res://assets/runtime/ui/interfaces/max_level_success/decorations/success_light.png")
const PANEL_TEXTURE := preload("res://assets/runtime/ui/interfaces/max_level_success/backplates/legacy_success_panel.png")
const CONTINUE_TEXTURE := preload("res://assets/runtime/ui/interfaces/max_level_success/buttons/button_continue.png")

var _level := GameConfig.MAX_BLOCK_LEVEL
var _animate_intro := true
var _light: TextureRect
var _panel: TextureRect


func setup(level: int = GameConfig.MAX_BLOCK_LEVEL, animate_intro: bool = true) -> void:
	_level = clampi(level, 1, GameConfig.MAX_BLOCK_LEVEL)
	_animate_intro = animate_intro


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size.x <= 0.0 or size.y <= 0.0:
		size = DESIGN_SIZE
	_build()


func _build() -> void:
	var shade := ColorRect.new()
	shade.name = "PopupShade"
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	_light = _texture_rect(LIGHT_TEXTURE, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_light.name = "SuccessLight"
	_set_rect(_light, Vector2((size.x - DESIGN_SIZE.x) * 0.5, size.y * LIGHT_Y_RATIO), LIGHT_SIZE)
	_light.modulate = Color(1.0, 1.0, 1.0, 0.0 if _animate_intro else 1.0)
	add_child(_light)

	_panel = _texture_rect(PANEL_TEXTURE, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	_panel.name = "SuccessPanel"
	_set_rect(_panel, Vector2((size.x - PANEL_SIZE.x) * 0.5, size.y * PANEL_Y_RATIO), PANEL_SIZE)
	_panel.scale = Vector2.ZERO if _animate_intro else Vector2.ONE
	add_child(_panel)

	var block := _make_block_preview(_level, BLOCK_SIZE)
	block.name = "MaxLevelBlock"
	block.position = BLOCK_POSITION
	_panel.add_child(block)

	var continue_button := TextureButton.new()
	continue_button.name = "ContinueButton"
	continue_button.texture_normal = CONTINUE_TEXTURE
	continue_button.texture_hover = CONTINUE_TEXTURE
	continue_button.texture_pressed = CONTINUE_TEXTURE
	continue_button.ignore_texture_size = true
	continue_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	continue_button.focus_mode = Control.FOCUS_NONE
	_set_rect(continue_button, BUTTON_POSITION, BUTTON_SIZE)
	continue_button.pressed.connect(func(): continue_pressed.emit())
	continue_button.button_down.connect(func(): _animate_button(continue_button, Vector2(0.9, 0.9), 0.06))
	continue_button.button_up.connect(func(): _animate_button(continue_button, Vector2.ONE, 0.08))
	_panel.add_child(continue_button)

	if _animate_intro:
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.parallel().tween_property(_light, "modulate:a", 1.0, 0.12)
		tween.parallel().tween_property(_light, "rotation", TAU, 8.0).set_trans(Tween.TRANS_LINEAR)
		tween.parallel().tween_property(_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _make_block_preview(level: int, preview_size: Vector2) -> Control:
	var container := Control.new()
	container.size = preview_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var background := _texture_rect(load(GameConfig.BLOCK_BG_PATHS[GameConfig.get_block_color_name(level)]) as Texture2D, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	background.name = "BlockBackground"
	background.size = preview_size
	container.add_child(background)

	var glyph_texture := load(GameConfig.get_label_texture_path(level)) as Texture2D
	var glyph := _texture_rect(glyph_texture, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	glyph.name = "BlockGlyph"
	var texture_size: Vector2 = glyph_texture.get_size() if glyph_texture else Vector2.ONE
	var glyph_scale := preview_size.x * GameConfig.BLOCK_LABEL_FILL / maxf(texture_size.x, texture_size.y)
	glyph.size = texture_size * glyph_scale
	glyph.position = (preview_size - glyph.size) * 0.5
	container.add_child(glyph)
	return container


func _texture_rect(texture: Texture2D, stretch: TextureRect.StretchMode) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = stretch
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _animate_button(button: Control, target: Vector2, duration: float) -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(button, "scale", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
