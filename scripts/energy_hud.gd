extends Control
class_name EnergyHud

signal gain_fx_batch_finished

const PANEL_SIZE := Vector2(913.0, 210.0)
const PANEL_SOURCE_REGION := Rect2(46.0, 15.0, 867.0, 199.0)
const ENERGY_FRAME_POS := Vector2(35.0, 145.0)
const ENERGY_FRAME_SIZE := Vector2(360.0, 35.0)
const ENERGY_FILL_POS := Vector2(37.0, 147.0)
const ENERGY_FILL_SIZE := Vector2(356.0, 32.0)
const ENERGY_SEGMENT_X: Array[float] = [70.0, 135.0, 200.0, 265.0]

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


func _ready() -> void:
	custom_minimum_size = PANEL_SIZE
	size = PANEL_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	set_process(false)


func _build() -> void:
	# The supplied reference contains the exact yellow-title panel as one clean
	# region. Keep that region at one uniform scale so its frame is not squashed.
	var panel := _texture_from_atlas("res://assets/UI/底部UI/效果图.png", PANEL_SOURCE_REGION)
	panel.size = PANEL_SIZE
	add_child(panel)

	_fill_clip = Control.new()
	_fill_clip.name = "EnergyFillClip"
	_fill_clip.clip_contents = true
	_fill_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_fill_clip, ENERGY_FILL_POS, ENERGY_FILL_SIZE)
	add_child(_fill_clip)

	_fill = _texture("res://assets/UI/底部UI/能量.png")
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

	_refresh()


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
