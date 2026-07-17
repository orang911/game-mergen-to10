extends Control
class_name EnergyGainFx

var _start := Vector2.ZERO
var _target := Vector2.ZERO
var _control := Vector2.ZERO
var _duration := 0.45
var _delay := 0.0
var _elapsed := 0.0
var _bright := false
var _finished: Callable
var _trail: Array[Vector2] = []


func setup(start_pos: Vector2, target_pos: Vector2, duration: float, delay: float, bright: bool, finished: Callable) -> void:
	_start = start_pos
	_target = target_pos
	_duration = maxf(0.1, duration)
	_delay = maxf(0.0, delay)
	_bright = bright
	_finished = finished
	position = _start
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	set_process(true)
	var midpoint := (_start + _target) * 0.5
	_control = midpoint + Vector2(randf_range(-75.0, 75.0), randf_range(-130.0, -55.0))
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed < _delay:
		return
	var t := clampf((_elapsed - _delay) / _duration, 0.0, 1.0)
	var eased := ease(t, -1.7)
	var inv := 1.0 - eased
	position = inv * inv * _start + 2.0 * inv * eased * _control + eased * eased * _target
	_trail.push_front(position)
	if _trail.size() > 7:
		_trail.pop_back()
	queue_redraw()
	if t >= 1.0:
		if _finished.is_valid():
			_finished.call()
		queue_free()


func _draw() -> void:
	for i in range(_trail.size()):
		var a := (1.0 - float(i) / float(maxi(1, _trail.size()))) * 0.24
		draw_circle(_trail[i] - position, maxf(2.0, 7.0 - float(i)), Color(0.25, 0.9, 1.0, a))
	var glow := Color(0.42, 0.96, 1.0, 0.40 if not _bright else 0.62)
	draw_circle(Vector2.ZERO, 13.0 if _bright else 10.0, glow)
	draw_circle(Vector2.ZERO, 6.5 if _bright else 5.0, Color(0.82, 0.98, 1.0, 0.96))
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color.WHITE)
