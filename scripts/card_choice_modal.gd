extends Control
class_name CardChoiceModal

signal choice_committed(kind: String, card_id: String, element_key: String, quality: int)
signal modal_closed(kind: String)

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const MASK_COLOR := Color(0.018, 0.028, 0.075, 0.80)

var _kind := "energy"
var _ids: Array[String] = []
var _qualities: Array[int] = []
var _skill_target_global := Vector2.ZERO
var _crystal_target_global := Vector2.ZERO
var _mask: ColorRect
var _panel: TextureRect
var _panel_shadow: Panel
var _cards: Array[TextureButton] = []
var _selection_frames: Array[Panel] = []
var _selected_index := -1
var _confirm: TextureButton
var _close: Button
var _locked := true
var _base_card_positions: Array[Vector2] = []
var _element_layer: Control
var _selection_tween: Tween


func setup(kind: String, ids: Array[String], skill_target_global: Vector2, crystal_target_global: Vector2, qualities: Array[int]) -> void:
	_kind = kind
	_ids = ids
	_skill_target_global = skill_target_global
	_crystal_target_global = crystal_target_global
	_qualities = qualities
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_tree().paused = true
	call_deferred("_play_intro")


func _build() -> void:
	_mask = ColorRect.new()
	_mask.color = Color(0, 0, 0, 0)
	_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_mask.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_mask)

	var milestone := _kind == "milestone"
	var panel_path := "res://assets/UI/波次选择/layer_001.png" if milestone else "res://assets/UI/技能选择/layer_002.png"
	_panel = TextureRect.new()
	_panel.texture = load(panel_path) as Texture2D
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not milestone:
		_set_rect(_panel, Vector2(29.5, 555.0), Vector2(882, 566))
	else:
		_set_rect(_panel, Vector2(42.0, 250.0), Vector2(857, 949))
	# A soft navy shadow keeps the modal readable over busy combat scenes.
	_panel_shadow = Panel.new()
	_panel_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shadow_style := StyleBoxFlat.new()
	shadow_style.bg_color = Color(0.015, 0.025, 0.07, 0.72)
	shadow_style.corner_radius_top_left = 28
	shadow_style.corner_radius_top_right = 28
	shadow_style.corner_radius_bottom_left = 28
	shadow_style.corner_radius_bottom_right = 28
	shadow_style.shadow_color = Color(0.0, 0.0, 0.0, 0.62)
	shadow_style.shadow_size = 24
	shadow_style.shadow_offset = Vector2(0, 14)
	_set_rect(_panel_shadow, _panel.position + Vector2(0, 12), _panel.size)
	add_child(_panel_shadow)
	add_child(_panel)

	for i in range(_ids.size()):
		var id := _ids[i]
		var is_crystal := GameConfig.CRYSTAL_CARD_IDS.has(id)
		var texture_path: String = GameConfig.CRYSTAL_CARD_TEXTURES.get(id, "") if is_crystal else GameConfig.SKILL_CARD_TEXTURES.get(id, "")
		var card := TextureButton.new()
		card.name = "Card_%s" % id
		card.texture_normal = load(texture_path) as Texture2D
		card.texture_hover = card.texture_normal
		card.texture_pressed = card.texture_normal
		card.ignore_texture_size = true
		card.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		card.focus_mode = Control.FOCUS_NONE
		card.disabled = true
		var card_size := Vector2(190, 356) if not milestone else Vector2(210, 373)
		var card_pos := Vector2(78 + i * 275, 145) if not milestone else Vector2(70 + i * 260, 390)
		_set_rect(card, card_pos, card_size)
		_panel.add_child(card)
		_cards.append(card)
		_base_card_positions.append(card_pos)
		var frame := Panel.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.visible = false
		var frame_style := StyleBoxFlat.new()
		frame_style.bg_color = Color(0.2, 0.75, 1.0, 0.04)
		frame_style.border_color = Color(0.72, 0.94, 1.0, 0.95)
		frame_style.set_border_width_all(5)
		frame_style.set_corner_radius_all(22)
		frame.add_theme_stylebox_override("panel", frame_style)
		_set_rect(frame, Vector2.ZERO, card_size)
		card.add_child(frame)
		_selection_frames.append(frame)
		var quality_badge := Label.new()
		quality_badge.text = str(GameConfig.CARD_QUALITY_NAMES.get(_qualities[i] if i < _qualities.size() else 1, "普通"))
		quality_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		quality_badge.add_theme_font_size_override("font_size", 18)
		quality_badge.add_theme_color_override("font_color", GameConfig.CARD_QUALITY_COLORS.get(_qualities[i] if i < _qualities.size() else 1, Color.WHITE))
		_set_rect(quality_badge, Vector2(0, card_size.y - 34), Vector2(card_size.x, 28))
		quality_badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(quality_badge)
		card.pressed.connect(_select_card.bind(i))
		card.mouse_entered.connect(_hover_card.bind(i, true))
		card.mouse_exited.connect(_hover_card.bind(i, false))

	var confirm_path := "res://assets/UI/波次选择/layer_002.png" if milestone else "res://assets/UI/技能选择/layer_001.png"
	_confirm = TextureButton.new()
	_confirm.texture_normal = load(confirm_path) as Texture2D
	_confirm.texture_hover = _confirm.texture_normal
	_confirm.texture_pressed = _confirm.texture_normal
	_confirm.ignore_texture_size = true
	_confirm.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.disabled = true
	var confirm_size := Vector2(332, 93) if milestone else Vector2(246, 88)
	var confirm_pos := Vector2((_panel.size.x - confirm_size.x) * 0.5, 805) if milestone else Vector2((_panel.size.x - confirm_size.x) * 0.5, 466)
	_set_rect(_confirm, confirm_pos, confirm_size)
	_panel.add_child(_confirm)
	_confirm.pressed.connect(_confirm_selection)

	_close = Button.new()
	_close.text = ""
	_close.flat = true
	_close.focus_mode = Control.FOCUS_NONE
	_close.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(_close, Vector2(_panel.size.x - 92, 34), Vector2(72, 72))
	_panel.add_child(_close)
	_close.pressed.connect(_random_close)


func _play_intro() -> void:
	_locked = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.86, 0.86)
	var final_pos := _panel.position
	_panel.position = final_pos + Vector2(0, 30)
	if _panel_shadow:
		_panel_shadow.modulate.a = 0.0
		_panel_shadow.scale = Vector2(0.86, 0.86)
		_panel_shadow.position = final_pos + Vector2(0, 42)
	for i in range(_cards.size()):
		var card := _cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.82, 0.82)
		card.position = _base_card_positions[i] + Vector2(0, 46)
	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.tween_property(_mask, "color", MASK_COLOR, GameConfig.CARD_MASK_FADE_IN)
	intro.parallel().tween_property(_panel, "modulate:a", 1.0, GameConfig.CARD_PANEL_INTRO)
	intro.parallel().tween_property(_panel, "scale", Vector2.ONE, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(_panel, "position", final_pos, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if _panel_shadow:
		intro.parallel().tween_property(_panel_shadow, "modulate:a", 1.0, GameConfig.CARD_PANEL_INTRO)
		intro.parallel().tween_property(_panel_shadow, "scale", Vector2.ONE, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		intro.parallel().tween_property(_panel_shadow, "position", final_pos + Vector2(0, 12), GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro.finished
	for i in range(_cards.size()):
		var card := _cards[i]
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(card, "modulate:a", 1.0, GameConfig.CARD_INTRO_DURATION)
		tween.parallel().tween_property(card, "scale", Vector2.ONE, GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(card, "position", _base_card_positions[i], GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(GameConfig.CARD_INTRO_STAGGER, true).timeout
	_locked = false
	for card in _cards:
		card.disabled = false


func _select_card(index: int) -> void:
	if _locked or index < 0 or index >= _cards.size():
		return
	_selected_index = index
	_confirm.disabled = false
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	for i in range(_cards.size()):
		var card := _cards[i]
		var selected := i == index
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.parallel().tween_property(card, "scale", Vector2(1.08, 1.08) if selected else Vector2(0.94, 0.94), 0.12)
		tween.parallel().tween_property(card, "position", _base_card_positions[i] + (Vector2(0, -14) if selected else Vector2.ZERO), 0.12)
		tween.parallel().tween_property(card, "modulate", Color.WHITE if selected else Color(1, 1, 1, 0.72), 0.12)
		_selection_frames[i].visible = selected
		_selection_frames[i].modulate.a = 1.0
	var selected_frame := _selection_frames[index]
	_selection_tween = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_selection_tween.tween_property(selected_frame, "modulate:a", 0.48, 0.55).set_trans(Tween.TRANS_SINE)
	_selection_tween.tween_property(selected_frame, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE)


func _hover_card(index: int, entered: bool) -> void:
	if _locked or index == _selected_index or index < 0 or index >= _cards.size():
		return
	var card := _cards[index]
	var target_scale := Vector2(1.035, 1.035) if entered else Vector2.ONE
	var target_modulate := Color(1.08, 1.08, 1.08, 1.0) if entered else Color.WHITE
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(card, "scale", target_scale, 0.10).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(card, "modulate", target_modulate, 0.10).set_trans(Tween.TRANS_SINE)


func _random_close() -> void:
	if _locked:
		return
	_selected_index = randi_range(0, _cards.size() - 1)
	if _ids[_selected_index] == "element_prism":
		_finish_choice(["fire", "ice", "poison", "lightning"].pick_random())
	else:
		_finish_choice("")


func _confirm_selection() -> void:
	if _locked or _selected_index < 0:
		return
	if _ids[_selected_index] == "element_prism":
		_show_element_choice()
	else:
		_finish_choice("")


func _show_element_choice() -> void:
	_locked = true
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	for card in _cards:
		card.visible = false
	_confirm.visible = false
	_element_layer = Control.new()
	_element_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_element_layer, Vector2(90, 385), Vector2(_panel.size.x - 180, 260))
	_panel.add_child(_element_layer)
	var title := Label.new()
	title.text = "选择水晶属性"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.08, 0.35, 0.68))
	_set_rect(title, Vector2(0, 0), Vector2(_element_layer.size.x, 62))
	_element_layer.add_child(title)
	var names := {"fire": "火", "ice": "冰", "poison": "毒", "lightning": "雷"}
	var colors := {"fire": Color(1, .28, .12), "ice": Color(.25, .72, 1), "poison": Color(.22, .8, .28), "lightning": Color(1, .8, .12)}
	var keys := ["fire", "ice", "poison", "lightning"]
	for i in range(keys.size()):
		var key: String = keys[i]
		var button := Button.new()
		button.text = names[key]
		button.add_theme_font_size_override("font_size", 34)
		button.add_theme_color_override("font_color", Color.WHITE)
		var style := StyleBoxFlat.new()
		style.bg_color = colors[key]
		style.corner_radius_top_left = 18
		style.corner_radius_top_right = 18
		style.corner_radius_bottom_left = 18
		style.corner_radius_bottom_right = 18
		button.add_theme_stylebox_override("normal", style)
		_set_rect(button, Vector2(20 + i * 155, 92), Vector2(125, 125))
		_element_layer.add_child(button)
		button.pressed.connect(_finish_choice.bind(key))
	_locked = false


func _finish_choice(element_key: String) -> void:
	if _locked:
		return
	_locked = true
	var chosen_id := _ids[_selected_index]
	var chosen := _cards[_selected_index]
	chosen.visible = true
	for card in _cards:
		card.disabled = true
		if card != chosen:
			var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			fade.parallel().tween_property(card, "modulate:a", 0.0, GameConfig.CARD_UNSELECTED_FADE)
			fade.parallel().tween_property(card, "scale", Vector2(0.84, 0.84), GameConfig.CARD_UNSELECTED_FADE)
	if _element_layer:
		_element_layer.queue_free()
	var start_global := chosen.global_position
	var start_size := chosen.size
	chosen.reparent(self, true)
	chosen.global_position = start_global
	chosen.size = start_size
	chosen.pivot_offset = chosen.size * 0.5
	var is_crystal := GameConfig.CRYSTAL_CARD_IDS.has(chosen_id)
	var duration := GameConfig.CARD_CRYSTAL_FLY_DURATION if is_crystal else GameConfig.CARD_SKILL_FLY_DURATION
	var target_global := _crystal_target_global if is_crystal else _skill_target_global
	var target_pos := target_global - chosen.size * 0.5 * 0.12
	var fly := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly.parallel().tween_property(chosen, "global_position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.parallel().tween_property(chosen, "scale", Vector2(0.12, 0.12) if is_crystal else Vector2(0.18, 0.18), duration)
	fly.tween_property(chosen, "modulate:a", 0.0, 0.12)
	await fly.finished
	choice_committed.emit(_kind, chosen_id, element_key, int(_qualities[_selected_index] if _selected_index < _qualities.size() else 1))
	var outro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.parallel().tween_property(_panel, "modulate:a", 0.0, GameConfig.CARD_PANEL_FADE_OUT)
	if _panel_shadow:
		outro.parallel().tween_property(_panel_shadow, "modulate:a", 0.0, GameConfig.CARD_PANEL_FADE_OUT)
	outro.parallel().tween_property(_mask, "color:a", 0.0, GameConfig.CARD_MASK_FADE_OUT)
	await outro.finished
	get_tree().paused = false
	modal_closed.emit(_kind)
	queue_free()


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5
