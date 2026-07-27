extends Control
class_name EnergyHud

signal gain_fx_batch_finished
signal instant_item_pressed(item_id: String)

const PANEL_SIZE := Vector2(913.0, 210.0)
const PANEL_SOURCE_REGION := Rect2(46.0, 15.0, 867.0, 199.0)
const ENERGY_FRAME_POS := Vector2(35.0, 145.0)
const ENERGY_FRAME_SIZE := Vector2(360.0, 35.0)
const ENERGY_FILL_POS := Vector2(37.0, 147.0)
const ENERGY_FILL_SIZE := Vector2(356.0, 32.0)
const ENERGY_SEGMENT_X: Array[float] = [70.0, 135.0, 200.0, 265.0]
const CLUSTER_SWAP_ITEM_ID := "cluster_swap"
const CLUSTER_SWAP_TEXTURE := preload("res://assets/runtime/ui/battle/bottom_hud/item_cluster_swap.png")
const CRYSTAL_RAIN_ITEM_ID := "crystal_rain"
const CRYSTAL_RAIN_TEXTURE := preload("res://assets/runtime/ui/battle/bottom_hud/item_crystal_rain.png")
const FIRST_ITEM_SLOT_RECT := Rect2(455.0, 64.0, 126.0, 126.0)
const SECOND_ITEM_SLOT_RECT := Rect2(600.0, 64.0, 126.0, 126.0)

var _fill_clip: Control
var _fill: TextureRect
var _energy_label: Label
var _ready_label: Label
var _pending_icon: TextureRect
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


func _build() -> void:
	# The supplied reference contains the exact yellow-title panel as one clean
	# region. Keep that region at one uniform scale so its frame is not squashed.
	var panel := _texture_from_atlas("res://assets/runtime/ui/battle/bottom_hud/hud_atlas.png", PANEL_SOURCE_REGION)
	panel.size = PANEL_SIZE
	add_child(panel)

	_fill_clip = Control.new()
	_fill_clip.name = "EnergyFillClip"
	_fill_clip.clip_contents = true
	_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_fill_clip, ENERGY_FILL_POS, ENERGY_FILL_SIZE)
	add_child(_fill_clip)

	_fill = _texture("res://assets/runtime/ui/battle/bottom_hud/energy_fill.png")
	_fill.size = ENERGY_FILL_SIZE
	_fill_clip.add_child(_fill)

	# The fill is drawn over the empty slot, so redraw its four dividers above
	# the fill. This keeps all five cells readable at every energy percentage.
	for divider_x in ENERGY_SEGMENT_X:
		var divider := ColorRect.new()
		divider.color = Color(0.035, 0.075, 0.16, 0.92)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(divider, ENERGY_FILL_POS + Vector2(divider_x, 1.0), Vector2(2.0, 30.0))
		add_child(divider)

	var best_label := _label("BEST", 22, Color(0.62, 0.66, 0.76))
	best_label.add_theme_color_override("font_outline_color", Color(0.12, 0.14, 0.22, 0.9))
	best_label.add_theme_constant_override("outline_size", 2)
	_set_rect(best_label, Vector2(315.0, 145.0), Vector2(78.0, 35.0))
	add_child(best_label)

	_pending_icon = _texture("")
	_set_rect(_pending_icon, Vector2(17, 61), Vector2(107, 80))
	add_child(_pending_icon)

	_energy_label = _label("0 / 100", 18, Color(0.92, 0.96, 1.0))
	_set_rect(_energy_label, Vector2(124, 147), Vector2(190, 37))
	_energy_label.visible = false
	add_child(_energy_label)

	_ready_label = _label("", 17, Color(0.88, 0.98, 1.0))
	_set_rect(_ready_label, Vector2(74, 183), Vector2(274, 29))
	add_child(_ready_label)
	_build_cluster_swap_item()
	_build_crystal_rain_item()

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
	_set_rect(_cluster_swap_icon, Vector2(9.0, 9.0), FIRST_ITEM_SLOT_RECT.size - Vector2(18.0, 18.0))
	_cluster_swap_button.add_child(_cluster_swap_icon)

	var badge := Panel.new()
	badge.name = "CountBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.12, 0.25, 0.94)
	badge_style.border_color = Color(0.78, 0.90, 1.0, 0.95)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", badge_style)
	_set_rect(badge, Vector2(88.0, 88.0), Vector2(32.0, 32.0))
	_cluster_swap_button.add_child(badge)

	_cluster_swap_count_label = _label("0", 21, Color.WHITE)
	_cluster_swap_count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.10, 0.96))
	_cluster_swap_count_label.add_theme_constant_override("outline_size", 2)
	_set_rect(_cluster_swap_count_label, Vector2.ZERO, Vector2(32.0, 32.0))
	badge.add_child(_cluster_swap_count_label)

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
	_set_rect(_crystal_rain_icon, Vector2(9.0, 9.0), SECOND_ITEM_SLOT_RECT.size - Vector2(18.0, 18.0))
	_crystal_rain_button.add_child(_crystal_rain_icon)

	var badge := Panel.new()
	badge.name = "CountBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color(0.08, 0.12, 0.25, 0.94)
	badge_style.border_color = Color(0.78, 0.90, 1.0, 0.95)
	badge_style.set_border_width_all(2)
	badge_style.set_corner_radius_all(14)
	badge.add_theme_stylebox_override("panel", badge_style)
	_set_rect(badge, Vector2(88.0, 88.0), Vector2(32.0, 32.0))
	_crystal_rain_button.add_child(badge)

	var count_label := _label("∞", 21, Color.WHITE)
	count_label.name = "CountLabel"
	count_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.10, 0.96))
	count_label.add_theme_constant_override("outline_size", 2)
	_set_rect(count_label, Vector2.ZERO, Vector2(32.0, 32.0))
	badge.add_child(count_label)

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


func set_pending_skill(skill_id: String, quality: int = 1) -> void:
	if _pending_icon == null:
		return
	if skill_id.is_empty():
		_pending_icon.texture = null
		_pending_icon.modulate = Color.WHITE
		_ready_label.text = ""
	else:
		_pending_icon.texture = load(GameConfig.SKILL_IMPRINT_TEXTURES.get(skill_id, "")) as Texture2D
		_pending_icon.modulate = Color.WHITE
		_ready_label.text = "下次合成触发 · %s" % GameConfig.CARD_QUALITY_NAMES.get(quality, "1星")


func get_energy_target_global() -> Vector2:
	return global_position + ENERGY_FRAME_POS + Vector2(70.0, ENERGY_FRAME_SIZE.y * 0.5)


func get_skill_target_global() -> Vector2:
	return _pending_icon.global_position + _pending_icon.size * 0.5


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
	for child in get_children():
		if child is EnergyGainFx:
			child.queue_free()
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
	_energy_label.text = "%d / %d" % [_visual_energy, _maximum]
	var full := _visual_energy >= _maximum
	if full and _ready_label.text.is_empty():
		_ready_label.text = "技能就绪"
	elif not full and _ready_label.text == "技能就绪":
		_ready_label.text = ""
	if not full:
		_was_full_visual = false


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
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.pivot_offset = node.size * 0.5
	return node


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5
