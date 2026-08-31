extends Control
class_name EnergyHud

signal gain_fx_batch_finished
signal instant_item_pressed(item_id: String)
signal pending_imprint_trigger_finished(completed: bool)

const PANEL_SIZE := Vector2(913.0, 210.0)
const SKILL_PANEL_POS := Vector2(22.0, 31.0)
const SKILL_PANEL_SIZE := Vector2(400.0, 147.0)
const ENERGY_FRAME_POS := Vector2(169.0, 122.0)
const ENERGY_FRAME_SIZE := Vector2(226.0, 35.0)
const ENERGY_FILL_POS := Vector2(176.0, 129.0)
const ENERGY_FILL_SIZE := Vector2(212.0, 21.0)
const PENDING_ICON_POS := Vector2(35.0, 52.0)
const PENDING_ICON_SIZE := Vector2(105.0, 114.0)
const PENDING_CONTENT_POS := Vector2(49.0, 67.0)
const PENDING_CONTENT_SIZE := Vector2(77.0, 84.0)
const READY_LABEL_POS := Vector2(151.0, 43.0)
const READY_LABEL_SIZE := Vector2(260.0, 74.0)
const READY_LABEL_SINGLE_FONT_SIZE := 27
const READY_LABEL_DOUBLE_FONT_SIZE := 20
const READY_LABEL_DOUBLE_MIN_FONT_SIZE := 18
const READY_LABEL_DOUBLE_LINE_SPACING := -5
const CLUSTER_SWAP_ITEM_ID := "cluster_swap"
const CLUSTER_SWAP_TEXTURE := preload("res://assets/runtime/ui/interfaces/battle/energy_hud/icons/instant_cluster_swap.png")
const CRYSTAL_RAIN_ITEM_ID := "crystal_rain"
const CRYSTAL_RAIN_TEXTURE := preload("res://assets/runtime/ui/interfaces/battle/energy_hud/icons/instant_crystal_rain.png")
const FIRST_ITEM_SLOT_RECT := Rect2(529.0, 43.0, 115.0, 129.0)
const SECOND_ITEM_SLOT_RECT := Rect2(657.0, 43.0, 114.0, 129.0)
const LOCKED_ITEM_RECT := Rect2(785.0, 43.0, 115.0, 125.0)

var _fill_clip: Control
var _fill: ColorRect
var _energy_label: Label
var _ready_label: Label
var _pending_icon: TextureRect
var _disabled_skill_icon: TextureRect
var _inactive_skill_icon: TextureRect
var _pending_skill_id := ""
var _pending_trigger_tween: Tween
var _pending_arrival_tween: Tween
var _pending_trail_ghost: TextureRect
var _pending_trail_lines: Array[Line2D] = []
var _pending_trail_points: Array[Vector2] = []
var _pending_trail_active := false
var _pending_trail_elapsed := 0.0
var _pending_flight_start_global := Vector2.ZERO
var _pending_flight_target_global := Vector2.ZERO
var _pending_flight_arc_height := 0.0
var _pending_trigger_active := false
var _logical_energy := 0
var _visual_energy := 0
var _maximum := 100
var _active_motes := 0
var _shimmer := 0.0
var _full_tween: Tween
var _was_full_visual := false
var _cluster_swap_button: Button
var _cluster_swap_icon: TextureRect
var _cluster_swap_count_label: Label
var _cluster_swap_count := 0
var _crystal_rain_button: Button
var _crystal_rain_icon: TextureRect
var _crystal_rain_enabled := false


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_process(false)


func _process(delta: float) -> void:
	if not _pending_trail_active or _pending_trail_ghost == null or not is_instance_valid(_pending_trail_ghost):
		return
	_pending_trail_elapsed += delta
	if _pending_trail_elapsed < 0.014 and not _pending_trail_points.is_empty():
		return
	_pending_trail_elapsed = 0.0
	var ghost_center_global := _pending_trail_ghost.get_global_transform_with_canvas() * (_pending_trail_ghost.size * 0.5)
	var local_point := get_global_transform_with_canvas().affine_inverse() * ghost_center_global
	_pending_trail_points.append(local_point)
	while _pending_trail_points.size() > 13:
		_pending_trail_points.pop_front()
	var packed_points := PackedVector2Array(_pending_trail_points)
	for line in _pending_trail_lines:
		if line and is_instance_valid(line):
			line.points = packed_points


func _build() -> void:
	var panel := _texture("res://assets/runtime/ui/interfaces/battle/energy_hud/backplates/skill_panel_frame.png")
	panel.name = "SkillPanelFrame"
	panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(panel, SKILL_PANEL_POS, SKILL_PANEL_SIZE)
	add_child(panel)

	_disabled_skill_icon = _texture("res://assets/runtime/ui/interfaces/battle/energy_hud/icons/skill_disabled_icon.png")
	_disabled_skill_icon.name = "SkillDisabledIcon"
	_disabled_skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(_disabled_skill_icon, PENDING_ICON_POS, PENDING_ICON_SIZE)
	add_child(_disabled_skill_icon)

	_inactive_skill_icon = _texture("res://assets/runtime/ui/interfaces/battle/energy_hud/icons/skill_disabled_icon1.png")
	_inactive_skill_icon.name = "SkillInactiveIcon"
	_inactive_skill_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(_inactive_skill_icon, PENDING_ICON_POS, PENDING_ICON_SIZE)
	add_child(_inactive_skill_icon)

	_fill_clip = Control.new()
	_fill_clip.name = "EnergyFillClip"
	_fill_clip.clip_contents = true
	_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_fill_clip, ENERGY_FILL_POS, ENERGY_FILL_SIZE)
	add_child(_fill_clip)

	_fill = ColorRect.new()
	_fill.name = "EnergyFill"
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill.color = Color(0.05, 0.72, 0.90, 1.0)
	_fill.size = ENERGY_FILL_SIZE
	_fill_clip.add_child(_fill)

	var meter_frame := Panel.new()
	meter_frame.name = "EnergyMeterFrame"
	meter_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var meter_style := StyleBoxFlat.new()
	# Border only: the fill is already clipped beneath this control, while the
	# new X-2 panel supplies the dark meter background.
	meter_style.bg_color = Color.TRANSPARENT
	meter_style.border_color = Color(0.72, 0.86, 0.96, 0.95)
	meter_style.set_border_width_all(3)
	meter_style.set_corner_radius_all(12)
	meter_frame.add_theme_stylebox_override("panel", meter_style)
	_set_rect(meter_frame, ENERGY_FRAME_POS, ENERGY_FRAME_SIZE)
	add_child(meter_frame)

	_pending_icon = _texture("")
	_pending_icon.name = "PendingSkillIcon"
	_pending_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(_pending_icon, PENDING_CONTENT_POS, PENDING_CONTENT_SIZE)
	_pending_icon.visible = false
	add_child(_pending_icon)

	_energy_label = _label("0/100", 20, Color(0.95, 0.98, 1.0))
	_set_rect(_energy_label, ENERGY_FRAME_POS, ENERGY_FRAME_SIZE)
	add_child(_energy_label)

	_ready_label = _label("技能未激活", READY_LABEL_SINGLE_FONT_SIZE, Color(1.0, 1.0, 1.0))
	_ready_label.clip_text = true
	_ready_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_set_rect(_ready_label, READY_LABEL_POS, READY_LABEL_SIZE)
	add_child(_ready_label)
	_build_cluster_swap_item()
	_build_crystal_rain_item()

	var locked_item := _texture("res://assets/runtime/ui/interfaces/battle/energy_hud/icons/locked_item_slot.png")
	locked_item.name = "LockedItem"
	locked_item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(locked_item, LOCKED_ITEM_RECT.position, LOCKED_ITEM_RECT.size)
	add_child(locked_item)

	_refresh()


func _build_cluster_swap_item() -> void:
	_cluster_swap_button = Button.new()
	_cluster_swap_button.name = "ClusterSwapItem"
	_cluster_swap_button.flat = true
	_cluster_swap_button.focus_mode = Control.FOCUS_NONE
	_cluster_swap_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_cluster_swap_button.tooltip_text = "换位：将相同数字尽可能排列到一起"
	_cluster_swap_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_cluster_swap_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_cluster_swap_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_cluster_swap_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	_set_rect(_cluster_swap_button, FIRST_ITEM_SLOT_RECT.position, FIRST_ITEM_SLOT_RECT.size)
	_cluster_swap_button.pressed.connect(func():
		if _cluster_swap_count != 0:
			instant_item_pressed.emit(CLUSTER_SWAP_ITEM_ID)
	)
	add_child(_cluster_swap_button)

	_cluster_swap_icon = TextureRect.new()
	_cluster_swap_icon.name = "Icon"
	_cluster_swap_icon.texture = CLUSTER_SWAP_TEXTURE
	_cluster_swap_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_cluster_swap_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_cluster_swap_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_cluster_swap_icon, Vector2.ZERO, FIRST_ITEM_SLOT_RECT.size)
	_cluster_swap_button.add_child(_cluster_swap_icon)

	_cluster_swap_count_label = _label("0", 18, Color.WHITE)
	_cluster_swap_count_label.name = "CountLabel"
	_cluster_swap_count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.10, 0.96))
	_cluster_swap_count_label.add_theme_constant_override("outline_size", 3)
	_set_rect(_cluster_swap_count_label, Vector2(80.0, 101.0), Vector2(27.0, 28.0))
	_cluster_swap_button.add_child(_cluster_swap_count_label)

	_cluster_swap_button.mouse_entered.connect(func():
		if _cluster_swap_count != 0:
			_tween_item_icon(Vector2(1.06, 1.06), 0.08)
	)
	_cluster_swap_button.mouse_exited.connect(func(): _tween_item_icon(Vector2.ONE, 0.08))
	_cluster_swap_button.button_down.connect(func():
		if _cluster_swap_count != 0:
			_tween_item_icon(Vector2(0.90, 0.90), 0.05)
	)
	_cluster_swap_button.button_up.connect(func(): _tween_item_icon(Vector2.ONE, 0.08))
	set_cluster_swap_count(0)


func set_cluster_swap_count(count: int) -> void:
	_cluster_swap_count = count
	if _cluster_swap_button:
		_cluster_swap_button.disabled = _cluster_swap_count == 0
	if _cluster_swap_icon:
		_cluster_swap_icon.modulate = Color.WHITE if _cluster_swap_count != 0 else Color(0.34, 0.37, 0.46, 0.62)
	if _cluster_swap_count_label:
		_cluster_swap_count_label.text = "∞" if _cluster_swap_count < 0 else str(_cluster_swap_count)


func play_cluster_swap_used() -> void:
	if _cluster_swap_icon == null:
		return
	_cluster_swap_icon.pivot_offset = _cluster_swap_icon.size * 0.5
	var tween := create_tween()
	tween.parallel().tween_property(_cluster_swap_icon, "scale", Vector2(1.18, 1.18), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_cluster_swap_icon, "rotation", 0.10, 0.10)
	tween.tween_property(_cluster_swap_icon, "rotation", -0.08, 0.08)
	tween.parallel().tween_property(_cluster_swap_icon, "scale", Vector2.ONE, 0.14)
	tween.tween_property(_cluster_swap_icon, "rotation", 0.0, 0.06)


func _tween_item_icon(target_scale: Vector2, duration: float) -> void:
	if _cluster_swap_icon == null:
		return
	_cluster_swap_icon.pivot_offset = _cluster_swap_icon.size * 0.5
	var tween := create_tween()
	tween.tween_property(_cluster_swap_icon, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _build_crystal_rain_item() -> void:
	_crystal_rain_button = Button.new()
	_crystal_rain_button.name = "CrystalRainItem"
	_crystal_rain_button.flat = true
	_crystal_rain_button.focus_mode = Control.FOCUS_NONE
	_crystal_rain_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_crystal_rain_button.tooltip_text = "水晶雨：消灭路径上的全部怪物"
	_crystal_rain_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	_crystal_rain_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	_crystal_rain_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	_crystal_rain_button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	_set_rect(_crystal_rain_button, SECOND_ITEM_SLOT_RECT.position, SECOND_ITEM_SLOT_RECT.size)
	_crystal_rain_button.pressed.connect(func():
		if _crystal_rain_enabled:
			instant_item_pressed.emit(CRYSTAL_RAIN_ITEM_ID)
	)
	add_child(_crystal_rain_button)

	_crystal_rain_icon = TextureRect.new()
	_crystal_rain_icon.name = "Icon"
	_crystal_rain_icon.texture = CRYSTAL_RAIN_TEXTURE
	_crystal_rain_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crystal_rain_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crystal_rain_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_crystal_rain_icon, Vector2.ZERO, SECOND_ITEM_SLOT_RECT.size)
	_crystal_rain_button.add_child(_crystal_rain_icon)

	var count_label := _label("∞", 18, Color.WHITE)
	count_label.name = "CountLabel"
	count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.10, 0.96))
	count_label.add_theme_constant_override("outline_size", 3)
	_set_rect(count_label, Vector2(80.0, 101.0), Vector2(27.0, 28.0))
	_crystal_rain_button.add_child(count_label)

	_crystal_rain_button.mouse_entered.connect(func():
		if _crystal_rain_enabled:
			_tween_crystal_rain_icon(Vector2(1.06, 1.06), 0.08)
	)
	_crystal_rain_button.mouse_exited.connect(func(): _tween_crystal_rain_icon(Vector2.ONE, 0.08))
	_crystal_rain_button.button_down.connect(func():
		if _crystal_rain_enabled:
			_tween_crystal_rain_icon(Vector2(0.90, 0.90), 0.05)
	)
	_crystal_rain_button.button_up.connect(func(): _tween_crystal_rain_icon(Vector2.ONE, 0.08))
	set_crystal_rain_enabled(false)


func set_crystal_rain_enabled(enabled: bool) -> void:
	_crystal_rain_enabled = enabled
	if _crystal_rain_button:
		_crystal_rain_button.disabled = not enabled
	if _crystal_rain_icon:
		_crystal_rain_icon.modulate = Color.WHITE if enabled else Color(0.34, 0.37, 0.46, 0.62)


func play_crystal_rain_used() -> void:
	if _crystal_rain_icon == null:
		return
	_crystal_rain_icon.pivot_offset = _crystal_rain_icon.size * 0.5
	var tween := create_tween()
	tween.parallel().tween_property(_crystal_rain_icon, "scale", Vector2(1.18, 1.18), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(_crystal_rain_icon, "rotation", -0.10, 0.10)
	tween.tween_property(_crystal_rain_icon, "rotation", 0.08, 0.08)
	tween.parallel().tween_property(_crystal_rain_icon, "scale", Vector2.ONE, 0.14)
	tween.tween_property(_crystal_rain_icon, "rotation", 0.0, 0.06)


func _tween_crystal_rain_icon(target_scale: Vector2, duration: float) -> void:
	if _crystal_rain_icon == null:
		return
	_crystal_rain_icon.pivot_offset = _crystal_rain_icon.size * 0.5
	var tween := create_tween()
	tween.tween_property(_crystal_rain_icon, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func set_energy(current: int, maximum: int) -> void:
	_logical_energy = current
	_maximum = maxi(1, maximum)
	if _active_motes <= 0:
		_visual_energy = current
	_refresh()


func set_pending_skill(skill_id: String, _quality: int = 1) -> void:
	if _pending_icon == null:
		return
	var should_animate_arrival := _pending_skill_id.is_empty() and not skill_id.is_empty()
	_pending_skill_id = skill_id
	if skill_id.is_empty():
		_kill_pending_skill_arrival(true)
		_pending_icon.texture = null
		_pending_icon.modulate = Color.WHITE
		_refresh_skill_slot_visual()
		_refresh_ready_label()
	else:
		_pending_icon.texture = load(GameConfig.SKILL_IMPRINT_TEXTURES.get(skill_id, "")) as Texture2D
		_pending_icon.modulate = Color.WHITE
		_refresh_skill_slot_visual()
		var imprint_name := str(SkillImprintSystem.IMPRINT_NAMES.get(skill_id, skill_id))
		_set_ready_label_text("下一次合成：待触发\n%s" % imprint_name, true, imprint_name)
		if should_animate_arrival and _pending_icon.texture != null:
			_play_pending_skill_arrival()
		elif not _pending_trigger_active:
			_pending_icon.scale = Vector2.ONE


func _play_pending_skill_arrival() -> void:
	_kill_pending_skill_arrival(false)
	_pending_icon.visible = true
	_pending_icon.pivot_offset = _pending_icon.size * 0.5
	# The travelling modal copy arrives at exactly this 88 px display size.
	# Begin at 1.0, then overshoot, so the node swap is visually seamless.
	_pending_icon.scale = Vector2.ONE
	_pending_arrival_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_pending_arrival_tween.tween_property(_pending_icon, "scale", Vector2(1.26, 1.26), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pending_arrival_tween.tween_property(_pending_icon, "scale", Vector2(0.94, 0.94), 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pending_arrival_tween.tween_property(_pending_icon, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _kill_pending_skill_arrival(reset_scale: bool) -> void:
	if _pending_arrival_tween and _pending_arrival_tween.is_valid():
		_pending_arrival_tween.kill()
	_pending_arrival_tween = null
	if reset_scale and _pending_icon:
		_pending_icon.scale = Vector2.ONE


func play_pending_imprint_trigger(target_global: Vector2) -> bool:
	if _pending_icon == null or _pending_icon.texture == null:
		return false
	# Hide the slot copy immediately and animate a travelling copy.  The
	# arrival pulse is intentionally larger than the source icon so the player
	# can read the imprint being consumed at the merge point.
	_clear_pending_trigger_fx(false)
	_pending_icon.visible = false
	var ghost := TextureRect.new()
	ghost.name = "PendingImprintFly"
	ghost.texture = _pending_icon.texture
	ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.size = _pending_icon.size
	ghost.global_position = _pending_icon.global_position
	ghost.pivot_offset = ghost.size * 0.5
	ghost.z_index = 22
	add_child(ghost)
	_pending_trail_ghost = ghost
	_pending_trigger_active = true
	_pending_flight_start_global = get_skill_target_global()
	_pending_flight_target_global = target_global
	var flight_distance := _pending_flight_start_global.distance_to(_pending_flight_target_global)
	_pending_flight_arc_height = clampf(flight_distance * 0.12, 60.0, 130.0)
	_pending_trail_points.clear()
	_pending_trail_elapsed = 0.0
	_pending_trail_lines.clear()
	var glow := _create_pending_trail_line("PendingImprintTrailGlow", 30.0, Color(0.22, 0.78, 1.0, 0.18), 19)
	var trail := _create_pending_trail_line("PendingImprintTrail", 13.0, Color(0.70, 0.95, 1.0, 0.70), 20)
	_pending_trail_lines.append(glow)
	_pending_trail_lines.append(trail)
	_pending_trail_active = true
	set_process(true)

	var burst := Panel.new()
	burst.name = "PendingImprintBurst"
	burst.mouse_filter = Control.MOUSE_FILTER_IGNORE
	burst.z_index = 21
	var burst_size := ghost.size * 0.82
	burst.size = burst_size
	var target_local := get_global_transform_with_canvas().affine_inverse() * target_global
	burst.position = target_local - burst_size * 0.5
	burst.pivot_offset = burst_size * 0.5
	burst.modulate.a = 0.0
	var burst_style := StyleBoxFlat.new()
	burst_style.bg_color = Color(0.20, 0.78, 1.0, 0.08)
	burst_style.border_color = Color(0.78, 0.96, 1.0, 0.96)
	burst_style.set_border_width_all(3)
	burst_style.set_corner_radius_all(int(minf(burst_size.x, burst_size.y) * 0.28))
	burst_style.shadow_color = Color(0.16, 0.78, 1.0, 0.82)
	burst_style.shadow_size = 12
	burst.add_theme_stylebox_override("panel", burst_style)
	add_child(burst)

	_set_pending_flight_progress(0.0, ghost)
	var sequence := create_tween()
	_pending_trigger_tween = sequence
	sequence.tween_method(
		_set_pending_flight_progress.bind(ghost),
		0.0,
		1.0,
		0.32
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	sequence.tween_callback(func():
		if is_instance_valid(burst):
			burst.modulate.a = 0.92
	)
	sequence.tween_property(ghost, "scale", Vector2(1.30, 1.30), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sequence.parallel().tween_property(ghost, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sequence.parallel().tween_property(burst, "scale", Vector2(1.38, 1.38), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sequence.parallel().tween_property(burst, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for line in _pending_trail_lines:
		sequence.parallel().tween_property(line, "modulate:a", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	sequence.tween_callback(func():
		_complete_pending_trigger_fx(ghost, burst)
	)
	return true


func _set_pending_flight_progress(progress: float, ghost: TextureRect) -> void:
	if ghost == null or not is_instance_valid(ghost):
		return
	var clamped_progress := clampf(progress, 0.0, 1.0)
	var center := _pending_flight_start_global.lerp(_pending_flight_target_global, clamped_progress)
	center.y -= sin(clamped_progress * PI) * _pending_flight_arc_height
	ghost.global_position = center - ghost.size * 0.5
	var perspective_scale := lerpf(1.0, 0.62, clamped_progress)
	ghost.scale = Vector2.ONE * perspective_scale


func _create_pending_trail_line(line_name: String, width: float, color: Color, z: int) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.width = width
	line.default_color = color
	line.antialiased = true
	line.z_index = z
	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 0.16))
	width_curve.add_point(Vector2(0.35, 0.68))
	width_curve.add_point(Vector2(1.0, 1.0))
	line.width_curve = width_curve
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.34, 1.0])
	gradient.colors = PackedColorArray([
		Color(color.r, color.g, color.b, 0.02),
		Color(color.r, color.g, color.b, color.a * 0.42),
		color
	])
	line.gradient = gradient
	add_child(line)
	return line


func _stop_pending_trail() -> void:
	_pending_trail_active = false
	set_process(false)
	_pending_trail_ghost = null
	_pending_trail_points.clear()
	_pending_trail_elapsed = 0.0
	_pending_flight_start_global = Vector2.ZERO
	_pending_flight_target_global = Vector2.ZERO
	_pending_flight_arc_height = 0.0
	for line in _pending_trail_lines:
		if line and is_instance_valid(line):
			line.queue_free()
	_pending_trail_lines.clear()


func _complete_pending_trigger_fx(ghost: TextureRect, burst: Panel) -> void:
	if not _pending_trigger_active:
		return
	_pending_trigger_active = false
	_stop_pending_trail()
	if is_instance_valid(ghost):
		ghost.queue_free()
	if is_instance_valid(burst):
		burst.queue_free()
	_pending_trigger_tween = null
	pending_imprint_trigger_finished.emit(true)


func _clear_pending_trigger_fx(emit_cancel: bool = false) -> void:
	var was_active := _pending_trigger_active
	if _pending_trigger_tween and _pending_trigger_tween.is_valid():
		_pending_trigger_tween.kill()
		_pending_trigger_tween = null
	_stop_pending_trail()
	_pending_trigger_active = false
	for child in get_children():
		if child.name == "PendingImprintFly" or child.name == "PendingImprintBurst":
			child.queue_free()
	if emit_cancel and was_active:
		pending_imprint_trigger_finished.emit(false)


func get_energy_target_global() -> Vector2:
	return global_position + ENERGY_FRAME_POS + Vector2(70.0, ENERGY_FRAME_SIZE.y * 0.5)


func get_skill_target_global() -> Vector2:
	if _pending_icon == null:
		return Vector2.ZERO
	return _pending_icon.get_global_transform_with_canvas() * (_pending_icon.size * 0.5)


func play_energy_gain(amount: int, source_global: Vector2, mote_count: int, bright: bool) -> void:
	var count := maxi(1, mote_count)
	_active_motes += count
	for i in range(count):
		var mote := EnergyGainFx.new()
		mote.name = "EnergyMote"
		add_child(mote)
		var inverse := get_global_transform_with_canvas().affine_inverse()
		var start_local: Vector2 = inverse * source_global + Vector2(randf_range(-18, 18), randf_range(-15, 15))
		var target_local: Vector2 = inverse * get_energy_target_global()
		var visual_step := amount / count + (1 if i < amount % count else 0)
		mote.setup(start_local, target_local, randf_range(GameConfig.ENERGY_MOTE_DURATION_MIN, GameConfig.ENERGY_MOTE_DURATION_MAX), float(i) * GameConfig.ENERGY_MOTE_STAGGER, bright, _on_mote_arrived.bind(visual_step))


func clear_fx() -> void:
	_kill_pending_skill_arrival(true)
	_clear_pending_trigger_fx(true)
	for child in get_children():
		if child is EnergyGainFx:
			child.queue_free()
	_refresh_skill_slot_visual()
	_active_motes = 0
	_visual_energy = _logical_energy
	_was_full_visual = _visual_energy >= _maximum
	_refresh()


func _on_mote_arrived(visual_step: int) -> void:
	_active_motes = maxi(0, _active_motes - 1)
	_visual_energy = mini(_logical_energy, _visual_energy + visual_step)
	_play_arrival_feedback()
	_refresh()
	if _active_motes == 0:
		_visual_energy = _logical_energy
		_refresh()
		if _visual_energy >= _maximum and not _was_full_visual:
			_was_full_visual = true
			_play_full_feedback()
			await get_tree().create_timer(GameConfig.ENERGY_FULL_FEEDBACK_DELAY).timeout
		gain_fx_batch_finished.emit()


func _play_full_feedback() -> void:
	var target_local := get_global_transform_with_canvas().affine_inverse() * get_energy_target_global()
	for i in range(9):
		var burst := EnergyGainFx.new()
		add_child(burst)
		var angle := TAU * float(i) / 9.0
		var end := target_local + Vector2.from_angle(angle) * randf_range(44.0, 76.0)
		burst.setup(target_local, end, 0.18, float(i) * 0.012, true, Callable())
	var strong := create_tween()
	strong.tween_property(self, "modulate", Color(1.35, 1.35, 1.5, 1), 0.08)
	strong.tween_property(self, "modulate", Color.WHITE, 0.18)


func _play_arrival_feedback() -> void:
	if _fill:
		var fill_flash := create_tween()
		fill_flash.tween_property(_fill, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.05)
		fill_flash.tween_property(_fill, "modulate", Color.WHITE, GameConfig.ENERGY_ARRIVAL_FLASH_DURATION)
	var pulse := create_tween()
	pulse.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08)
	pulse.tween_property(self, "scale", Vector2.ONE, 0.12)
	var label_pulse := create_tween()
	label_pulse.tween_property(_energy_label, "scale", Vector2(1.12, 1.12), 0.07)
	label_pulse.tween_property(_energy_label, "scale", Vector2.ONE, 0.12)


func _refresh() -> void:
	if _fill_clip == null:
		return
	var ratio := clampf(float(_visual_energy) / float(_maximum), 0.0, 1.0)
	_fill_clip.size.x = ENERGY_FILL_SIZE.x * ratio
	_energy_label.text = "%d/%d" % [_visual_energy, _maximum]
	var full := _visual_energy >= _maximum
	if _pending_skill_id.is_empty():
		_refresh_ready_label()
	_refresh_skill_slot_visual()
	if not full:
		_was_full_visual = false


func _refresh_skill_slot_visual() -> void:
	# The black/silver frame is structural and must never disappear.  Only the
	# inner content switches between the inactive glyph and the selected imprint.
	if _disabled_skill_icon:
		_disabled_skill_icon.visible = true
	var has_pending_icon := not _pending_skill_id.is_empty() and _pending_icon != null and _pending_icon.texture != null
	if _inactive_skill_icon:
		_inactive_skill_icon.visible = not has_pending_icon
	if _pending_icon:
		_pending_icon.visible = has_pending_icon and not _pending_trigger_active


func _refresh_ready_label() -> void:
	if _ready_label == null or not _pending_skill_id.is_empty():
		return
	var full := _visual_energy >= _maximum
	_set_ready_label_text("能量已满\n等待选择印记" if full else "技能未激活", full)


func _set_ready_label_text(value: String, double_line: bool, detail_text: String = "") -> void:
	if _ready_label == null:
		return
	_ready_label.text = value
	var font_size := READY_LABEL_SINGLE_FONT_SIZE
	var line_spacing := 0
	if double_line:
		font_size = READY_LABEL_DOUBLE_FONT_SIZE
		if detail_text.length() > 6:
			font_size = READY_LABEL_DOUBLE_MIN_FONT_SIZE
		line_spacing = READY_LABEL_DOUBLE_LINE_SPACING
	_ready_label.add_theme_font_size_override("font_size", font_size)
	_ready_label.add_theme_constant_override("line_spacing", line_spacing)


func _texture(path: String) -> TextureRect:
	var node := TextureRect.new()
	node.texture = load(path) as Texture2D if not path.is_empty() else null
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_SCALE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _texture_from_atlas(path: String, region: Rect2) -> TextureRect:
	var atlas := AtlasTexture.new()
	atlas.atlas = load(path) as Texture2D
	atlas.region = region
	atlas.filter_clip = true
	var node := _texture("")
	node.texture = atlas
	return node


func _label(value: String, font_size: int, color: Color) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.025, 0.04, 0.065, 1.0))
	node.add_theme_color_override("font_shadow_color", Color(0.015, 0.025, 0.045, 0.82))
	node.add_theme_constant_override("outline_size", 4)
	node.add_theme_constant_override("shadow_offset_x", 2)
	node.add_theme_constant_override("shadow_offset_y", 3)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei UI", "Microsoft YaHei", "Noto Sans CJK SC", "Arial"])
	font.font_weight = 800
	font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	node.add_theme_font_override("font", font)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.pivot_offset = node.size * 0.5
	return node


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5
