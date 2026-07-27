@tool
extends Control
class_name MainHubView

signal stage_pressed(stage_number: int)
signal settings_pressed

const DESIGN_SIZE := Vector2(951.0, 1654.0)
const INTRO_DURATION := 0.24

@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _stage_button := get_node_or_null("DesignRoot/StageButton") as TextureButton
@onready var _settings_button := get_node_or_null("DesignRoot/SettingsButton") as TextureButton
@onready var _crystal_value := get_node_or_null("DesignRoot/ResourceCrystalValue") as Label
@onready var _coin_value := get_node_or_null("DesignRoot/ResourceCoinValue") as Label

var _interactive := false
var _intro_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _stage_button:
		_stage_button.pressed.connect(func():
			if _interactive:
				stage_pressed.emit(1)
		)
		_wire_button_feedback(_stage_button)
	if _settings_button:
		_settings_button.pressed.connect(func():
			if _interactive:
				settings_pressed.emit()
		)
		_wire_button_feedback(_settings_button)
	set_interactive(false)
	if size.x > 0.0 and size.y > 0.0:
		layout_for_viewport(size)


func layout_for_viewport(viewport_size: Vector2) -> void:
	if _design_root == null or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
	_design_root.size = DESIGN_SIZE
	_design_root.scale = Vector2.ONE * scale_factor


func show_menu() -> void:
	visible = true
	set_interactive(false)
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	if _design_root:
		_design_root.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_intro_tween = create_tween()
	if _design_root:
		_intro_tween.tween_property(_design_root, "modulate:a", 1.0, INTRO_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		_intro_tween.tween_interval(INTRO_DURATION)
	_intro_tween.tween_callback(func(): set_interactive(true))


func hide_menu() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
	_intro_tween = null
	set_interactive(false)
	visible = false


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	for button in [_stage_button, _settings_button]:
		if button:
			button.disabled = not enabled
			button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func set_resource_values(crystals: int, coins: int) -> void:
	if _crystal_value:
		_crystal_value.text = str(maxi(0, crystals))
	if _coin_value:
		_coin_value.text = str(maxi(0, coins))


func set_muted(muted: bool) -> void:
	if _settings_button:
		_settings_button.modulate = Color(0.70, 0.76, 0.90, 1.0) if muted else Color.WHITE


func _wire_button_feedback(button: BaseButton) -> void:
	button.pivot_offset = button.size * 0.5
	button.button_down.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2(0.94, 0.94), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	)
	button.button_up.connect(func():
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	)


func _exit_tree() -> void:
	if _intro_tween and _intro_tween.is_valid():
		_intro_tween.kill()
