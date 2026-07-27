extends Control
class_name FirstWaveTutorialView

signal skip_pressed
signal awakening_core_pressed

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const CORE_TEXTURE := preload("res://assets/runtime/ui/battle/tutorial/item_crystal_awakening_core.png")

var _board_rect := Rect2()
var _highlight_rect := Rect2()
var _crystal_anchor := Vector2.ZERO
var _dim_rects: Array[ColorRect] = []
var _highlight: Panel
var _tap_hint: Label
var _progress_panel: Panel
var _progress_label: Label
var _message_panel: Panel
var _message_label: Label
var _sub_message_label: Label
var _step_badge: Label
var _red_warning: Panel
var _core_button: TextureButton
var _core_info: Panel
var _crystal_highlight: Panel
var _core_tween: Tween


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_as_relative = false
	z_index = 190
	_build_view()


func setup(board_rect: Rect2, highlight_rect: Rect2, crystal_anchor: Vector2) -> void:
	_board_rect = board_rect
	_highlight_rect = highlight_rect
	_crystal_anchor = crystal_anchor
	if is_node_ready():
		_layout_focus()


func show_first_merge_guide() -> void:
	visible = true
	modulate.a = 0.0
	_set_focus_visible(true)
	_progress_panel.visible = true
	_progress_label.text = "消灭怪物：0/4"
	_show_message("合成相同数字，攻击怪物", "点击高亮的三个数字 1", 1)
	var fade_in := create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func show_basic_progress(killed: int, total: int) -> void:
	_progress_panel.visible = true
	_progress_label.text = "消灭怪物：%d/%d" % [killed, total]
	if killed > 0:
		_set_focus_visible(false)
		if killed < total:
			_show_message("继续合成，消灭教学怪物", "合成相同数字可发动攻击", 1)
		else:
			_hide_message()


func show_breakthrough_primary() -> void:
	_set_focus_visible(false)
	_progress_panel.visible = false
	_red_warning.visible = true
	_show_message("怪物突破防线会损伤水晶！", "水晶耐久：18 / 20", 2, Color(1.0, 0.78, 0.70))
	_pulse_warning()


func show_breakthrough_secondary() -> void:
	_show_message("合成更高的数字，才能发动更强的攻击！", "重甲怪已被冲击眩晕", 2, Color(1.0, 0.91, 0.64))


func show_core_reward() -> void:
	_red_warning.visible = false
	_hide_message()
	_core_button.visible = true
	_core_button.disabled = false
	_core_button.modulate = Color.WHITE
	_core_button.scale = Vector2.ONE
	_core_info.visible = true
	_crystal_highlight.visible = true
	_set_rect(_crystal_highlight, _crystal_anchor - Vector2(88.0, 58.0), Vector2(176.0, 116.0))
	_set_rect(_core_button, _crystal_anchor + Vector2(10.0, -88.0) - Vector2(66.0, 66.0), Vector2(132.0, 132.0))
	_set_rect(_core_info, _crystal_anchor + Vector2(72.0, -108.0), Vector2(330.0, 126.0))
	if _core_tween:
		_core_tween.kill()
	_core_tween = create_tween().set_loops()
	_core_tween.tween_property(_core_button, "scale", Vector2(1.10, 1.10), 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_core_tween.tween_property(_core_button, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var crystal_pulse := create_tween().set_loops()
	crystal_pulse.tween_property(_crystal_highlight, "scale", Vector2(1.10, 1.10), 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	crystal_pulse.tween_property(_crystal_highlight, "scale", Vector2.ONE, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func play_core_fly() -> void:
	if _core_button == null or not _core_button.visible:
		return
	_core_button.disabled = true
	_core_info.visible = false
	if _core_tween:
		_core_tween.kill()
	_core_button.pivot_offset = _core_button.size * 0.5
	var destination := _crystal_anchor - _core_button.size * 0.5
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_core_button, "position", destination, 0.52).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(_core_button, "scale", Vector2(0.12, 0.12), 0.52).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_core_button, "rotation", 0.42, 0.52).set_trans(Tween.TRANS_SINE)
	await tween.finished
	_core_button.visible = false
	_crystal_highlight.visible = false


func show_awakened() -> void:
	_show_message("水晶已唤醒！", "持续攻击已解锁", 3, Color(0.76, 0.96, 1.0))


func show_final_message() -> void:
	_show_message("水晶会持续守护防线！", "合成更高数字，与水晶一起消灭怪物！", 3, Color(0.80, 0.96, 1.0))


func cleanup() -> void:
	if _core_tween:
		_core_tween.kill()
	queue_free()


func _build_view() -> void:
	for index in range(4):
		var dim := ColorRect.new()
		dim.name = "BoardDim%d" % index
		dim.color = Color(0.01, 0.02, 0.06, 0.56)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dim)
		_dim_rects.append(dim)

	_highlight = Panel.new()
	_highlight.name = "FirstMergeHighlight"
	_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var highlight_style := StyleBoxFlat.new()
	highlight_style.bg_color = Color(0.18, 0.85, 1.0, 0.07)
	highlight_style.border_color = Color(0.35, 0.96, 1.0, 1.0)
	highlight_style.set_border_width_all(5)
	highlight_style.set_corner_radius_all(18)
	highlight_style.shadow_color = Color(0.22, 0.87, 1.0, 0.70)
	highlight_style.shadow_size = 14
	_highlight.add_theme_stylebox_override("panel", highlight_style)
	add_child(_highlight)
	_tap_hint = _label("☝", 58, Color.WHITE)
	_tap_hint.add_theme_color_override("font_outline_color", Color(0.02, 0.06, 0.12, 0.95))
	_tap_hint.add_theme_constant_override("outline_size", 5)
	_tap_hint.rotation = -0.20
	add_child(_tap_hint)

	_progress_panel = _panel(Color(0.055, 0.095, 0.20, 0.94), Color(0.48, 0.87, 1.0, 1.0), 18)
	_set_rect(_progress_panel, Vector2(340.0, 150.0), Vector2(260.0, 54.0))
	add_child(_progress_panel)
	_progress_label = _label("消灭怪物：0/4", 27, Color.WHITE)
	_progress_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.10, 1.0))
	_progress_label.add_theme_constant_override("outline_size", 5)
	_set_rect(_progress_label, Vector2.ZERO, _progress_panel.size)
	_progress_panel.add_child(_progress_label)

	_message_panel = _panel(Color(0.055, 0.075, 0.15, 0.96), Color(0.55, 0.84, 1.0, 1.0), 22)
	_set_rect(_message_panel, Vector2(146.0, 548.0), Vector2(649.0, 122.0))
	add_child(_message_panel)
	_step_badge = _label("1", 28, Color.WHITE)
	_step_badge.add_theme_stylebox_override("normal", _round_label_style(Color(0.16, 0.52, 0.98, 1.0), Color(0.72, 0.94, 1.0, 1.0), 24))
	_set_rect(_step_badge, Vector2(22.0, 26.0), Vector2(48.0, 48.0))
	_message_panel.add_child(_step_badge)
	_message_label = _label("", 31, Color.WHITE)
	_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_message_label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 1.0))
	_message_label.add_theme_constant_override("outline_size", 5)
	_set_rect(_message_label, Vector2(88.0, 11.0), Vector2(535.0, 58.0))
	_message_panel.add_child(_message_label)
	_sub_message_label = _label("", 22, Color(0.72, 0.86, 1.0))
	_sub_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_set_rect(_sub_message_label, Vector2(89.0, 65.0), Vector2(530.0, 42.0))
	_message_panel.add_child(_sub_message_label)

	_red_warning = Panel.new()
	_red_warning.name = "CrystalDamageWarning"
	_red_warning.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var warning_style := StyleBoxFlat.new()
	warning_style.bg_color = Color(0.7, 0.02, 0.02, 0.04)
	warning_style.border_color = Color(1.0, 0.08, 0.05, 0.90)
	warning_style.set_border_width_all(14)
	warning_style.shadow_color = Color(1.0, 0.0, 0.0, 0.38)
	warning_style.shadow_size = 26
	_red_warning.add_theme_stylebox_override("panel", warning_style)
	_set_rect(_red_warning, Vector2(6.0, 6.0), DESIGN_SIZE - Vector2(12.0, 12.0))
	add_child(_red_warning)
	_red_warning.visible = false

	_core_button = TextureButton.new()
	_core_button.name = "AwakeningCore"
	_core_button.texture_normal = CORE_TEXTURE
	_core_button.texture_hover = CORE_TEXTURE
	_core_button.texture_pressed = CORE_TEXTURE
	_core_button.ignore_texture_size = true
	_core_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_core_button.focus_mode = Control.FOCUS_NONE
	_core_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_core_button.pressed.connect(func(): awakening_core_pressed.emit())
	add_child(_core_button)
	_core_button.visible = false

	_core_info = _panel(Color(0.055, 0.075, 0.15, 0.97), Color(0.58, 0.94, 1.0, 1.0), 18)
	add_child(_core_info)
	var core_title := _label("唤醒晶核", 29, Color(0.80, 0.98, 1.0))
	core_title.add_theme_color_override("font_outline_color", Color(0.02, 0.05, 0.12, 1.0))
	core_title.add_theme_constant_override("outline_size", 4)
	_set_rect(core_title, Vector2(14.0, 10.0), Vector2(302.0, 50.0))
	_core_info.add_child(core_title)
	var core_desc := _label("唤醒水晶，解锁持续攻击。", 20, Color.WHITE)
	_set_rect(core_desc, Vector2(14.0, 59.0), Vector2(302.0, 45.0))
	_core_info.add_child(core_desc)
	_core_info.visible = false

	_crystal_highlight = Panel.new()
	_crystal_highlight.name = "CrystalTargetHighlight"
	_crystal_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crystal_highlight_style := StyleBoxFlat.new()
	crystal_highlight_style.bg_color = Color(0.20, 0.88, 1.0, 0.05)
	crystal_highlight_style.border_color = Color(0.45, 0.97, 1.0, 0.96)
	crystal_highlight_style.set_border_width_all(5)
	crystal_highlight_style.set_corner_radius_all(58)
	crystal_highlight_style.shadow_color = Color(0.14, 0.84, 1.0, 0.72)
	crystal_highlight_style.shadow_size = 16
	_crystal_highlight.add_theme_stylebox_override("panel", crystal_highlight_style)
	add_child(_crystal_highlight)
	_crystal_highlight.visible = false

	var skip := Button.new()
	skip.name = "SkipTutorial"
	skip.text = "跳过教学"
	skip.focus_mode = Control.FOCUS_NONE
	skip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	skip.add_theme_font_size_override("font_size", 22)
	skip.add_theme_color_override("font_color", Color(0.88, 0.94, 1.0))
	skip.add_theme_stylebox_override("normal", _round_label_style(Color(0.03, 0.06, 0.14, 0.78), Color(0.45, 0.62, 0.86, 0.90), 16))
	skip.add_theme_stylebox_override("hover", _round_label_style(Color(0.07, 0.18, 0.34, 0.94), Color(0.65, 0.90, 1.0, 1.0), 16))
	skip.add_theme_stylebox_override("pressed", _round_label_style(Color(0.02, 0.04, 0.10, 0.98), Color(0.48, 0.76, 1.0, 1.0), 16))
	_set_rect(skip, Vector2(755.0, 145.0), Vector2(158.0, 48.0))
	skip.pressed.connect(func(): skip_pressed.emit())
	add_child(skip)

	_layout_focus()
	_message_panel.visible = false
	_progress_panel.visible = false


func _layout_focus() -> void:
	if _dim_rects.size() != 4 or _highlight == null:
		return
	var focus := _highlight_rect.grow(8.0)
	_set_rect(_dim_rects[0], _board_rect.position, Vector2(_board_rect.size.x, maxf(0.0, focus.position.y - _board_rect.position.y)))
	_set_rect(_dim_rects[1], Vector2(_board_rect.position.x, focus.end.y), Vector2(_board_rect.size.x, maxf(0.0, _board_rect.end.y - focus.end.y)))
	_set_rect(_dim_rects[2], Vector2(_board_rect.position.x, focus.position.y), Vector2(maxf(0.0, focus.position.x - _board_rect.position.x), focus.size.y))
	_set_rect(_dim_rects[3], Vector2(focus.end.x, focus.position.y), Vector2(maxf(0.0, _board_rect.end.x - focus.end.x), focus.size.y))
	_set_rect(_highlight, focus.position, focus.size)
	_set_rect(_tap_hint, Vector2(focus.end.x - 44.0, focus.end.y - 24.0), Vector2(72.0, 72.0))
	if _message_panel:
		var message_y := clampf(_board_rect.position.y - 82.0, 500.0, 610.0)
		_message_panel.position.y = message_y


func _set_focus_visible(value: bool) -> void:
	for dim in _dim_rects:
		dim.visible = value
	_highlight.visible = value
	_tap_hint.visible = value
	if value:
		_highlight.pivot_offset = _highlight.size * 0.5
		var tween := create_tween().set_loops()
		tween.tween_property(_highlight, "modulate:a", 0.48, 0.45).set_trans(Tween.TRANS_SINE)
		tween.tween_property(_highlight, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE)
		_tap_hint.pivot_offset = _tap_hint.size * 0.5
		var tap_tween := create_tween().set_loops()
		tap_tween.tween_property(_tap_hint, "position", _tap_hint.position + Vector2(-9.0, -9.0), 0.34).set_trans(Tween.TRANS_SINE)
		tap_tween.tween_property(_tap_hint, "position", _tap_hint.position, 0.34).set_trans(Tween.TRANS_SINE)


func _show_message(title: String, subtitle: String, step: int, title_color: Color = Color.WHITE) -> void:
	_message_panel.visible = true
	_message_label.text = title
	_message_label.add_theme_color_override("font_color", title_color)
	_sub_message_label.text = subtitle
	_step_badge.text = str(step)
	_message_panel.modulate.a = 0.0
	var target_y := clampf(_board_rect.position.y - 82.0, 500.0, 610.0)
	_message_panel.position.y = target_y + 14.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_message_panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(_message_panel, "position:y", target_y, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_message() -> void:
	_message_panel.visible = false


func _pulse_warning() -> void:
	_red_warning.modulate.a = 0.25
	var tween := create_tween()
	tween.tween_property(_red_warning, "modulate:a", 1.0, 0.10)
	tween.tween_property(_red_warning, "modulate:a", 0.45, 0.12)
	tween.tween_property(_red_warning, "modulate:a", 1.0, 0.15)


func _panel(fill: Color, border: Color, radius: int) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _round_label_style(fill, border, radius))
	return panel


func _round_label_style(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0.01, 0.02, 0.06, 0.62)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0.0, 4.0)
	return style


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _set_rect(control: Control, position_value: Vector2, size_value: Vector2) -> void:
	control.position = position_value
	control.size = size_value
	control.pivot_offset = size_value * 0.5
