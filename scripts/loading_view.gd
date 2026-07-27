extends Control
class_name LoadingView

signal play_pressed
signal simulation_pressed
signal intro_finished

const DESIGN_SIZE := Vector2(967.0, 1626.0)
const INTRO_FADE_DURATION := 0.36
const INTRO_ENABLE_DELAY := 0.12

@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _artwork := get_node_or_null("DesignRoot/Artwork") as TextureRect
@onready var _play_button := get_node_or_null("DesignRoot/PlayButton") as BaseButton

var _intro_tween: Tween
var _interactive := false
var _simulation_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_simulation_button()
	if _play_button and not _play_button.pressed.is_connected(_on_play_button_pressed):
		_play_button.pressed.connect(_on_play_button_pressed)
	set_interactive(false)
	if _artwork:
		_artwork.modulate = Color.WHITE
	if size.x > 0.0 and size.y > 0.0:
		layout_for_viewport(size)


func layout_for_viewport(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or _design_root == null:
		return
	# Full-bleed cover keeps the login page filled without non-uniform image
	# stretching. The play hotspot shares this transform with the artwork.
	var scale_factor := maxf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	_design_root.size = DESIGN_SIZE
	_design_root.scale = Vector2.ONE * scale_factor


func begin_intro() -> void:
	stop_animations()
	set_interactive(false)
	if _artwork:
		_artwork.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_intro_tween = create_tween()
	if _artwork:
		_intro_tween.tween_property(_artwork, "modulate:a", 1.0, INTRO_FADE_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_intro_tween.tween_interval(INTRO_FADE_DURATION)
	_intro_tween.tween_interval(INTRO_ENABLE_DELAY)
	_intro_tween.tween_callback(func():
		set_interactive(true)
		intro_finished.emit()
	)


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	if _play_button:
		_play_button.disabled = not enabled
		_play_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
	if _simulation_button:
		_simulation_button.disabled = not enabled
		_simulation_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func _build_simulation_button() -> void:
	if _design_root == null:
		return
	_simulation_button = Button.new()
	_simulation_button.name = "BalanceSimulationButton"
	_simulation_button.text = "数值模拟"
	_simulation_button.process_mode = Node.PROCESS_MODE_ALWAYS
	_simulation_button.focus_mode = Control.FOCUS_NONE
	_simulation_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_simulation_button.position = Vector2(744.0, 1532.0)
	_simulation_button.size = Vector2(190.0, 64.0)
	_simulation_button.add_theme_font_size_override("font_size", 24)
	_simulation_button.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	_simulation_button.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 1.0))
	_simulation_button.add_theme_constant_override("outline_size", 2)
	_simulation_button.add_theme_stylebox_override("normal", _simulation_button_style(Color(0.08, 0.13, 0.24, 0.82)))
	_simulation_button.add_theme_stylebox_override("hover", _simulation_button_style(Color(0.10, 0.34, 0.62, 0.94)))
	_simulation_button.add_theme_stylebox_override("pressed", _simulation_button_style(Color(0.06, 0.24, 0.48, 0.96)))
	_simulation_button.add_theme_stylebox_override("disabled", _simulation_button_style(Color(0.08, 0.10, 0.16, 0.46)))
	_simulation_button.pressed.connect(func():
		if _interactive:
			simulation_pressed.emit()
	)
	_design_root.add_child(_simulation_button)


func _simulation_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.42, 0.66, 0.96, color.a)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	return style


func stop_animations() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	set_interactive(false)
	if _artwork:
		_artwork.modulate = Color.WHITE


func _on_play_button_pressed() -> void:
	if _interactive:
		play_pressed.emit()


func _exit_tree() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
