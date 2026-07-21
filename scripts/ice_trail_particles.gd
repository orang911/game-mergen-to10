extends Node2D
class_name IceTrailParticles


const PARTICLE_TEXTURE := preload("res://assets/runtime/fx/elements/ice/particle_snowflake.png")
const EMISSION_DISTANCE_MIN := 9.0
const EMISSION_DISTANCE_MAX := 27.0
const EMISSION_GAP_CHANCE := 0.20
const EMISSION_GAP_EXTRA_MIN := 18.0
const EMISSION_GAP_EXTRA_MAX := 36.0
const EMISSION_BURST_CHANCE := 0.30
const LIFETIME_MIN := 0.20
const LIFETIME_MAX := 0.62
const LATERAL_SPEED_MIN := 68.0
const LATERAL_SPEED_MAX := 125.0

var _target: MergeBolt
var _last_position := Vector2.ZERO
var _distance_until_next := 0.0
var _has_position := false
var _side := -1.0
var _active_particles := 0
var _stopped := false
var _use_additive_next := false
var _additive_material: CanvasItemMaterial
var _normal_material: CanvasItemMaterial


func _ready() -> void:
	position = Vector2.ZERO
	_normal_material = CanvasItemMaterial.new()
	_normal_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
	_additive_material = CanvasItemMaterial.new()
	_additive_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_use_additive_next = randf() >= 0.5
	set_process(_target != null)


func follow(target: MergeBolt) -> void:
	_target = target
	_stopped = false
	_distance_until_next = _next_emission_distance()
	_has_position = false
	set_process(true)
	_capture_current_position()


func stop_emitting() -> void:
	_target = null
	_stopped = true
	set_process(false)
	_try_finish()


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_queued_for_deletion():
		stop_emitting()
		return
	var current := _target.start_pos.lerp(_target.end_pos, _target.progress)
	if not _has_position:
		_last_position = current
		_has_position = true
		return
	_emit_over_distance(_last_position, current)
	_last_position = current


func _capture_current_position() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	_last_position = _target.start_pos.lerp(_target.end_pos, _target.progress)
	_has_position = true


func _emit_over_distance(from_position: Vector2, to_position: Vector2) -> void:
	var segment := to_position - from_position
	var distance := segment.length()
	if distance <= 0.001:
		return
	var direction := segment / distance
	var cursor := 0.0
	var remaining := distance
	while remaining >= _distance_until_next:
		cursor += _distance_until_next
		var emission_position := from_position + direction * cursor
		_spawn_particle(emission_position, direction)
		# Occasional pairs create short dense patches between deliberately sparse
		# sections instead of a mechanically even row of snowflakes.
		if randf() < EMISSION_BURST_CHANCE:
			_spawn_particle(emission_position + direction * randf_range(-4.0, 4.0), direction)
		remaining -= _distance_until_next
		_distance_until_next = _next_emission_distance()
	_distance_until_next -= remaining


func _next_emission_distance() -> float:
	var spacing := randf_range(EMISSION_DISTANCE_MIN, EMISSION_DISTANCE_MAX)
	if randf() < EMISSION_GAP_CHANCE:
		spacing += randf_range(EMISSION_GAP_EXTRA_MIN, EMISSION_GAP_EXTRA_MAX)
	return spacing


func _spawn_particle(spawn_position: Vector2, travel_direction: Vector2) -> void:
	var particle := Sprite2D.new()
	particle.texture = PARTICLE_TEXTURE
	particle.centered = true
	particle.position = spawn_position
	particle.rotation = randf_range(-PI, PI)
	var size_roll := randf()
	var start_scale: float
	if size_roll < 0.45:
		start_scale = randf_range(0.040, 0.075)
	elif size_roll < 0.85:
		start_scale = randf_range(0.085, 0.130)
	else:
		start_scale = randf_range(0.145, 0.205)
	particle.scale = Vector2.ONE * start_scale
	particle.material = _additive_material if _use_additive_next else _normal_material
	var start_alpha := randf_range(0.46, 0.72) if _use_additive_next else randf_range(0.68, 0.94)
	particle.modulate = Color(randf_range(0.68, 0.90), randf_range(0.90, 1.0), 1.0, start_alpha)
	_use_additive_next = not _use_additive_next
	add_child(particle)
	_active_particles += 1

	# Alternate sides for a balanced two-sided wake, then add small variation so
	# the particles do not form two mechanical straight rows.
	_side *= -1.0
	var normal := Vector2(-travel_direction.y, travel_direction.x)
	var lateral_speed := randf_range(LATERAL_SPEED_MIN, LATERAL_SPEED_MAX) * _side
	var forward_speed := randf_range(-18.0, 14.0)
	var lifetime := randf_range(LIFETIME_MIN, LIFETIME_MAX)
	var end_position := spawn_position + (normal * lateral_speed + travel_direction * forward_speed) * lifetime
	var end_scale := Vector2.ONE * start_scale * randf_range(0.16, 0.30)

	var disperse := create_tween().set_parallel(true)
	disperse.tween_property(particle, "position", end_position, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	disperse.tween_property(particle, "scale", end_scale, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	disperse.tween_property(particle, "rotation", particle.rotation + randf_range(-1.8, 1.8), lifetime)
	disperse.chain().tween_callback(_on_particle_finished.bind(particle))
	var fade_delay := lifetime * randf_range(0.12, 0.62)
	var fade := create_tween()
	if fade_delay > 0.0:
		fade.tween_interval(fade_delay)
	fade.tween_property(particle, "modulate:a", 0.0, maxf(0.04, lifetime - fade_delay)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _on_particle_finished(particle: Sprite2D) -> void:
	if is_instance_valid(particle):
		particle.queue_free()
	_active_particles = maxi(0, _active_particles - 1)
	_try_finish()


func _try_finish() -> void:
	if _stopped and _active_particles == 0:
		queue_free()
