extends Control
class_name LoadingView

signal play_pressed
signal intro_finished

const DESIGN_SIZE := Vector2(768.0, 1364.0)
const INTRO_TOTAL_DURATION := 1.2

@onready var _background := get_node_or_null("Background") as TextureRect
@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _logo := get_node_or_null("DesignRoot/Logo") as TextureRect
@onready var _crystal := get_node_or_null("DesignRoot/Crystal") as TextureRect
@onready var _die_1 := get_node_or_null("DesignRoot/Die1") as TextureRect
@onready var _die_2 := get_node_or_null("DesignRoot/Die2") as TextureRect
@onready var _die_3 := get_node_or_null("DesignRoot/Die3") as TextureRect
@onready var _die_4 := get_node_or_null("DesignRoot/Die4") as TextureRect
@onready var _die_5 := get_node_or_null("DesignRoot/Die5") as TextureRect
@onready var _monster := get_node_or_null("DesignRoot/Monster") as TextureRect
@onready var _play_button := get_node_or_null("DesignRoot/PlayButton") as TextureButton

var _animated_nodes: Array[Control] = []
var _base_positions: Dictionary = {}
var _base_scales: Dictionary = {}
var _base_rotations: Dictionary = {}
var _intro_tweens: Array[Tween] = []
var _idle_tweens: Array[Tween] = []
var _animation_generation := 0
var _interactive := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_animated_nodes = [
		_logo,
		_crystal,
		_die_1,
		_die_2,
		_die_3,
		_die_4,
		_die_5,
		_monster,
		_play_button,
	]
	for node in _animated_nodes:
		if node:
			node.pivot_offset = node.size * 0.5
			_base_positions[node] = node.position
			_base_scales[node] = node.scale
			_base_rotations[node] = node.rotation
			if node != _play_button:
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _play_button and not _play_button.pressed.is_connected(_on_play_button_pressed):
		_play_button.pressed.connect(_on_play_button_pressed)
	set_interactive(false)
	_restore_base_state()
	if size.x > 0.0 and size.y > 0.0:
		layout_for_viewport(size)


func layout_for_viewport(viewport_size: Vector2) -> void:
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	var scale_factor := minf(viewport_size.x / DESIGN_SIZE.x, viewport_size.y / DESIGN_SIZE.y)
	if _design_root:
		_design_root.position = (viewport_size - DESIGN_SIZE * scale_factor) * 0.5
		_design_root.size = DESIGN_SIZE
		_design_root.scale = Vector2.ONE * scale_factor


func begin_intro() -> void:
	stop_animations()
	_animation_generation += 1
	var generation := _animation_generation
	set_interactive(false)
	if _background:
		_background.visible = true
		_background.modulate = Color.WHITE

	_prepare_intro_node(_logo, Vector2(0.0, -10.0), Vector2.ONE)
	_prepare_intro_node(_crystal, Vector2(0.0, 8.0), Vector2(0.94, 0.94))
	_prepare_intro_node(_die_1, Vector2(0.0, 8.0), Vector2.ONE)
	_prepare_intro_node(_die_2, Vector2(0.0, 8.0), Vector2.ONE)
	_prepare_intro_node(_die_3, Vector2(0.0, 8.0), Vector2.ONE)
	_prepare_intro_node(_die_4, Vector2(0.0, 8.0), Vector2.ONE)
	_prepare_intro_node(_die_5, Vector2(0.0, 8.0), Vector2.ONE)
	_prepare_intro_node(_monster, Vector2(8.0, 0.0), Vector2.ONE)
	_prepare_intro_node(_play_button, Vector2(0.0, 8.0), Vector2(0.98, 0.98))

	_intro_node(_logo, 0.05, 0.38, generation, func(): _start_float(_logo, 5.0, 5.0, generation))
	_intro_node(_crystal, 0.15, 0.45, generation, func():
		_start_float(_crystal, 8.0, 3.8, generation)
		_start_scale_loop(_crystal, 0.99, 1.015, 3.8, generation)
	)
	_intro_node(_die_2, 0.22, 0.32, generation, func(): _start_die_idle(_die_2, 6.0, 3.2, 1.2, generation))
	_intro_node(_die_3, 0.30, 0.32, generation, func(): _start_die_idle(_die_3, 7.0, 3.6, 1.0, generation))
	_intro_node(_die_4, 0.38, 0.32, generation, func(): _start_die_idle(_die_4, 8.0, 4.0, 1.4, generation))
	_intro_node(_die_5, 0.46, 0.32, generation, func(): _start_die_idle(_die_5, 7.0, 4.3, 1.1, generation))
	_intro_node(_die_1, 0.54, 0.32, generation, func(): _start_die_idle(_die_1, 6.0, 4.6, 1.3, generation))
	_intro_node(_monster, 0.62, 0.36, generation, func():
		_start_float(_monster, 7.0, 4.4, generation)
		_start_rotation_loop(_monster, 1.5, 4.4, generation)
	)
	_intro_node(_play_button, 0.72, 0.36, generation, func(): _start_scale_loop(_play_button, 0.98, 1.02, 1.8, generation))

	var completion := create_tween()
	_intro_tweens.append(completion)
	completion.tween_interval(INTRO_TOTAL_DURATION)
	completion.tween_callback(func():
		if generation != _animation_generation:
			return
		set_interactive(true)
		intro_finished.emit()
	)


func set_interactive(enabled: bool) -> void:
	_interactive = enabled
	if _play_button:
		_play_button.disabled = not enabled
		_play_button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func stop_animations() -> void:
	_animation_generation += 1
	_kill_tweens(_intro_tweens)
	_kill_tweens(_idle_tweens)
	set_interactive(false)
	_restore_base_state()


func _prepare_intro_node(node: Control, position_offset: Vector2, scale_factor: Vector2) -> void:
	if not node:
		return
	node.visible = true
	node.modulate = Color(1.0, 1.0, 1.0, 0.0)
	node.position = _base_positions[node] + position_offset
	node.scale = _base_scales[node] * scale_factor
	node.rotation = _base_rotations[node]


func _intro_node(node: Control, delay: float, duration: float, generation: int, on_finished: Callable) -> void:
	if not node:
		return
	var tween := create_tween()
	_intro_tweens.append(tween)
	tween.tween_interval(delay)
	tween.tween_property(node, "modulate:a", 1.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "position", _base_positions[node], duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(node, "scale", _base_scales[node], duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_callback(func():
		if generation == _animation_generation and on_finished.is_valid():
			on_finished.call()
	)


func _start_die_idle(node: Control, amplitude: float, period: float, rotation_degrees: float, generation: int) -> void:
	_start_float(node, amplitude, period, generation)
	_start_rotation_loop(node, rotation_degrees, period, generation)


func _start_float(node: Control, amplitude: float, period: float, generation: int) -> void:
	if not node or generation != _animation_generation:
		return
	var base_position: Vector2 = _base_positions[node]
	var tween := create_tween().set_loops()
	_idle_tweens.append(tween)
	tween.tween_property(node, "position", base_position + Vector2(0.0, -amplitude), period * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", base_position + Vector2(0.0, amplitude), period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", base_position, period * 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_rotation_loop(node: Control, degrees: float, period: float, generation: int) -> void:
	if not node or generation != _animation_generation:
		return
	var base_rotation: float = _base_rotations[node]
	var radians := deg_to_rad(degrees)
	var tween := create_tween().set_loops()
	_idle_tweens.append(tween)
	tween.tween_property(node, "rotation", base_rotation + radians, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "rotation", base_rotation - radians, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _start_scale_loop(node: Control, min_scale: float, max_scale: float, period: float, generation: int) -> void:
	if not node or generation != _animation_generation:
		return
	var base_scale: Vector2 = _base_scales[node]
	var tween := create_tween().set_loops()
	_idle_tweens.append(tween)
	tween.tween_property(node, "scale", base_scale * max_scale, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", base_scale * min_scale, period * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_tweens(tweens: Array[Tween]) -> void:
	for tween in tweens:
		if tween and tween.is_valid():
			tween.kill()
	tweens.clear()


func _restore_base_state() -> void:
	for node in _animated_nodes:
		if not node or not _base_positions.has(node):
			continue
		node.position = _base_positions[node]
		node.scale = _base_scales[node]
		node.rotation = _base_rotations[node]
		node.modulate = Color.WHITE
		node.visible = true


func _on_play_button_pressed() -> void:
	if _interactive:
		play_pressed.emit()


func _exit_tree() -> void:
	_kill_tweens(_intro_tweens)
	_kill_tweens(_idle_tweens)
