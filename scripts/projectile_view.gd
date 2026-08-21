@tool
extends Control
class_name MergeBolt


var start_pos := Vector2.ZERO:
	set(value):
		start_pos = value
		_sync_visuals()

var end_pos := Vector2.ZERO:
	set(value):
		end_pos = value
		_sync_visuals()

var progress := 0.0:
	set(value):
		progress = value
		_sync_visuals()
		queue_redraw()

# Visual params set by projectile_system, never contains damage/logic.
var element: int = -1
var element_key := "poison"
var tier := 1
var projectile_color := Color(0.7, 0.92, 1.0, 0.9)
var trail_color := Color(0.35, 0.75, 1.0, 0.55)

var _trail_glow_rect: TextureRect
var _trail_rect: TextureRect
var _core_rect: TextureRect
var _core_size := Vector2(50.0, 50.0)
var _trail_size := Vector2(110.0, 28.0)
var _trail_offset := Vector2(-48.0, 0.0)
var _rotate_to_velocity := true
var _rotation_offset := 0.0
var _flight_duration := 0.0
var _trail_history_duration := 0.0
var _target_provider := Callable()
var _crystal_beam_visual := false
var crystal_beam_width_scale := 1.0:
	set(value):
		crystal_beam_width_scale = clampf(value, 0.0, 4.0)
		queue_redraw()
var _crystal_beam_burst_tween: Tween
var trail_collapse_ratio := 1.0:
	set(value):
		trail_collapse_ratio = clampf(value, 0.0, 1.0)
		_sync_visuals()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ensure_visual_nodes()
	_apply_element_visuals()
	if Engine.is_editor_hint():
		start_pos = Vector2(40, 80)
		end_pos = Vector2(180, 60)
		progress = 0.5
	_sync_visuals()
	set_process(_target_provider.is_valid())


func track_target_provider(provider: Callable) -> void:
	_target_provider = provider
	set_process(_target_provider.is_valid())


func _process(_delta: float) -> void:
	if not _target_provider.is_valid():
		set_process(false)
		return
	var target_value = _target_provider.call()
	var target := target_value as Control
	if target == null or not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var parent_control := get_parent() as Control
	if parent_control == null:
		return
	var target_global := target.global_position + target.size * 0.5
	end_pos = parent_control.get_global_transform_with_canvas().affine_inverse() * target_global


func apply_event(event: MergeAttackEvent) -> void:
	element = event.element
	apply_element_key(event.element_key, event.element_tier)


func apply_element_key(key: String, tier_value: int = 1) -> void:
	element_key = key
	tier = tier_value
	_apply_element_visuals()
	_sync_visuals()


func configure_crystal_beam_visual(texture: Texture2D = null) -> void:
	_ensure_visual_nodes()
	# The reference effect is a narrow cyan energy line, rather than the generic
	# orb-and-ribbon projectile. Keep the supplied PNG attached for asset
	# validation/fallback, but render the beam procedurally so its width stays
	# stable while the target moves at any angle.
	_crystal_beam_visual = true
	crystal_beam_width_scale = 1.0
	if texture != null:
		_trail_rect.texture = texture
		_trail_glow_rect.texture = texture
	_trail_rect.material = null
	_trail_glow_rect.material = null
	_trail_rect.visible = false
	_trail_glow_rect.visible = false
	_core_rect.visible = false
	queue_redraw()
	_sync_visuals()


func play_crystal_beam_burst(expand_duration: float, collapse_duration: float) -> void:
	if not _crystal_beam_visual:
		return
	if _crystal_beam_burst_tween and _crystal_beam_burst_tween.is_valid():
		_crystal_beam_burst_tween.kill()
	crystal_beam_width_scale = 1.0
	var expand_time := maxf(0.001, expand_duration)
	var collapse_time := maxf(0.001, collapse_duration)
	_crystal_beam_burst_tween = create_tween()
	_crystal_beam_burst_tween.tween_property(self, "crystal_beam_width_scale", 4.0, expand_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_crystal_beam_burst_tween.tween_property(self, "crystal_beam_width_scale", 0.0, collapse_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_crystal_beam_burst_tween.parallel().tween_property(self, "modulate:a", 0.0, collapse_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _ensure_visual_nodes() -> void:
	if _trail_glow_rect == null or not is_instance_valid(_trail_glow_rect):
		_trail_glow_rect = TextureRect.new()
		_trail_glow_rect.name = "TrailGlow"
		_trail_glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_trail_glow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_trail_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_trail_glow_rect)

	if _trail_rect == null or not is_instance_valid(_trail_rect):
		_trail_rect = TextureRect.new()
		_trail_rect.name = "Trail"
		_trail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_trail_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_trail_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_trail_rect)

	if _core_rect == null or not is_instance_valid(_core_rect):
		_core_rect = TextureRect.new()
		_core_rect.name = "Core"
		_core_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_core_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_core_rect)


func _apply_element_visuals() -> void:
	_ensure_visual_nodes()
	var fx: Dictionary = GameConfig.get_element_fx(element_key)
	_core_size = fx.get("core_size", Vector2(50.0, 50.0)) as Vector2
	_trail_size = fx.get("trail_size", Vector2(110.0, 28.0)) as Vector2
	_trail_offset = fx.get("trail_offset", Vector2(-48.0, 0.0)) as Vector2
	_rotate_to_velocity = bool(fx.get("rotate_to_velocity", true))
	_rotation_offset = float(fx.get("rotation_offset", 0.0))
	trail_color = fx.get("trail_color", Color(0.35, 0.75, 1.0, 0.55)) as Color

	_core_rect.texture = _load_texture(str(fx.get("projectile", "")))
	_core_rect.size = _core_size
	_core_rect.pivot_offset = _core_size * 0.5

	_trail_rect.texture = _load_texture(str(fx.get("trail", "")))
	_trail_rect.size = _trail_size
	_trail_rect.pivot_offset = _trail_size * 0.5
	_trail_rect.modulate = trail_color
	_trail_rect.material = null

	var glow_size := _trail_size * 1.15
	_trail_glow_rect.texture = _load_texture(str(fx.get("trail", "")))
	_trail_glow_rect.size = glow_size
	_trail_glow_rect.pivot_offset = glow_size * 0.5
	_trail_glow_rect.modulate = Color(trail_color.r, trail_color.g, trail_color.b, 0.28)
	_trail_glow_rect.visible = true
	_trail_glow_rect.material = null

	var trail_shader_path := str(fx.get("trail_shader", ""))
	if not trail_shader_path.is_empty():
		var trail_shader := load(trail_shader_path) as Shader
		if trail_shader:
			var trail_material := ShaderMaterial.new()
			trail_material.shader = trail_shader
			trail_material.set_shader_parameter("tail_color", fx.get("trail_tail_color", Color(0.05, 0.22, 0.88, 1.0)))
			trail_material.set_shader_parameter("middle_color", fx.get("trail_middle_color", Color(0.05, 0.78, 1.0, 1.0)))
			trail_material.set_shader_parameter("head_color", fx.get("trail_head_color", Color(0.82, 0.97, 1.0, 1.0)))
			trail_material.set_shader_parameter("opacity", float(fx.get("trail_opacity", 0.92)))
			trail_material.set_shader_parameter("flow_speed", float(fx.get("trail_flow_speed", 2.8)))
			trail_material.set_shader_parameter("distortion_strength", float(fx.get("trail_distortion", 0.038)))
			trail_material.set_shader_parameter("use_texture_alpha", bool(fx.get("trail_use_texture_alpha", false)))
			trail_material.set_shader_parameter("black_cutoff", float(fx.get("trail_black_cutoff", 0.025)))
			trail_material.set_shader_parameter("tail_softness", float(fx.get("trail_tail_softness", 0.16)))
			trail_material.set_shader_parameter("head_softness", float(fx.get("trail_head_softness", 0.10)))
			trail_material.set_shader_parameter("body_thickness", float(fx.get("trail_body_thickness", 0.014)))
			_trail_rect.material = trail_material
			# The additive shader already supplies its own soft glow. A second copy
			# would flatten the gradient and overexpose the black-keyed texture.
			_trail_glow_rect.visible = false

	match element_key:
		"poison":
			projectile_color = Color(0.35, 0.9, 0.3, 0.9)
		"ice":
			projectile_color = Color(0.7, 0.85, 1.0, 0.9)
		"lightning":
			projectile_color = Color(1.0, 0.95, 0.25, 0.9)
		"critical":
			projectile_color = Color(0.75, 0.4, 0.95, 0.9)
		"fire":
			projectile_color = Color(1.0, 0.45, 0.15, 0.9)
		"crystal":
			projectile_color = Color(0.25, 0.88, 1.0, 0.9)
		_:
			projectile_color = Color(0.7, 0.92, 1.0, 0.9)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D


func configure_trail_history(flight_duration: float, history_duration: float) -> void:
	_flight_duration = maxf(0.0, flight_duration)
	_trail_history_duration = maxf(0.0, history_duration)
	trail_collapse_ratio = 1.0
	_sync_visuals()


func begin_trail_collapse(duration: float) -> void:
	# On impact the orb vanishes immediately while the ribbon contracts toward
	# the hit point over a few frames. Fading at the same time prevents the final
	# one-pixel remnant from flashing before the projectile node is removed.
	if _core_rect != null and is_instance_valid(_core_rect):
		_core_rect.visible = false
	var collapse_duration := maxf(0.001, duration)
	var collapse := create_tween().set_parallel(true)
	collapse.tween_property(self, "trail_collapse_ratio", 0.0, collapse_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _trail_rect != null and is_instance_valid(_trail_rect):
		collapse.tween_property(_trail_rect, "modulate:a", 0.0, collapse_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if _trail_glow_rect != null and is_instance_valid(_trail_glow_rect) and _trail_glow_rect.visible:
		collapse.tween_property(_trail_glow_rect, "modulate:a", 0.0, collapse_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _sync_visuals() -> void:
	if _core_rect == null or _trail_rect == null:
		return
	if _crystal_beam_visual:
		queue_redraw()
		return
	var head := start_pos.lerp(end_pos, progress)
	var velocity := end_pos - start_pos
	var angle := velocity.angle() if velocity.length_squared() > 0.001 else 0.0
	var visual_angle := angle + _rotation_offset
	var display_trail_size := _trail_size
	var display_trail_offset := _trail_offset
	if _flight_duration > 0.0 and _trail_history_duration > 0.0 and velocity.length_squared() > 0.001:
		# Convert the requested history time into world distance. During the first
		# part of the flight the trail grows with distance travelled; afterwards it
		# keeps the most recent history window. The texture's head-side overlap is
		# preserved so the ribbon remains visually joined to the moving orb.
		var history_progress := minf(clampf(progress, 0.0, 1.0), _trail_history_duration / _flight_duration)
		var history_length := velocity.length() * history_progress
		var head_overlap := _trail_offset.x + _trail_size.x * 0.5
		var full_trail_length := maxf(_trail_size.y * 0.70, history_length + maxf(0.0, head_overlap))
		display_trail_size.x = maxf(1.0, full_trail_length * trail_collapse_ratio)
		display_trail_offset.x = head_overlap * trail_collapse_ratio - display_trail_size.x * 0.5
	var trail_center := head + display_trail_offset.rotated(angle)

	var glow_size := display_trail_size * 1.15
	_trail_glow_rect.size = glow_size
	_trail_glow_rect.pivot_offset = glow_size * 0.5
	_trail_glow_rect.position = trail_center - glow_size * 0.5
	_trail_glow_rect.rotation = angle if _rotate_to_velocity else 0.0

	_trail_rect.size = display_trail_size
	_trail_rect.pivot_offset = display_trail_size * 0.5
	_trail_rect.position = trail_center - display_trail_size * 0.5
	_trail_rect.rotation = angle if _rotate_to_velocity else 0.0

	_core_rect.size = _core_size
	_core_rect.pivot_offset = _core_size * 0.5
	_core_rect.position = head - _core_size * 0.5
	_core_rect.rotation = visual_angle if _rotate_to_velocity else _rotation_offset


func _draw() -> void:
	if _crystal_beam_visual:
		var length_ratio := clampf(progress, 0.0, 1.0)
		var width_ratio := clampf(crystal_beam_width_scale, 0.0, 4.0)
		var alpha := clampf(modulate.a * trail_collapse_ratio * (width_ratio / 2.0), 0.0, 1.0)
		var beam_end := start_pos.lerp(end_pos, length_ratio)
		# Crystal beam animation is deliberately staged: the local Y/length axis
		# grows from zero to the target first, then the local X/width axis expands
		# to 4 and contracts to zero. The target can still move during flight.
		draw_line(start_pos, beam_end, Color(0.12, 0.82, 1.0, 0.24 * alpha), maxf(0.1, 9.0 * width_ratio), true)
		draw_line(start_pos, beam_end, Color(0.10, 0.90, 1.0, 0.78 * alpha), maxf(0.1, 2.6 * width_ratio), true)
		draw_line(start_pos, beam_end, Color(0.78, 1.0, 1.0, 0.92 * alpha), maxf(0.1, 0.9 * width_ratio), true)
		return
	if _core_rect != null and is_instance_valid(_core_rect) and _core_rect.texture != null:
		return
	var head := start_pos.lerp(end_pos, progress)
	draw_line(start_pos, head, trail_color, 10.0, true)
	draw_line(start_pos, head, projectile_color, 4.0, true)
	draw_circle(head, 8.0, projectile_color)
