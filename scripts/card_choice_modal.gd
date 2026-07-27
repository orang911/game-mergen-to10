extends Control
class_name CardChoiceModal

signal choice_committed(kind: String, card_id: String, element_key: String, level: int)
signal modal_closed(kind: String)

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const GREEN_KEY_SHADER := preload("res://shaders/ui_green_key.gdshader")
const MASK_COLOR := Color(0.0, 0.0, 0.0, 180.0 / 255.0)

const SKILL_PANEL_POS := Vector2(70.5, 180.0)
const SKILL_PANEL_SIZE := Vector2(800.0, 735.0)
const SKILL_TITLE_SIZE := Vector2(400.0, 108.0)
const SKILL_CONFIRM_SIZE := Vector2(328.0, 98.0)
const SKILL_CARD_SIZE := Vector2(220.0, 322.72)

const WAVE_TITLE_POS := Vector2(185.5, 400.0)
const WAVE_TITLE_SIZE := Vector2(570.0, 160.0)
const WAVE_CARD_SIZE := Vector2(230.0, 337.39)

var _kind := "energy"
var _ids: Array[String] = []
var _levels: Array[int] = []
var _new_flags: Array[bool] = []
var _skill_target_global := Vector2.ZERO
var _crystal_target_global := Vector2.ZERO

var _mask: ColorRect
var _panel: TextureRect
var _title_art: TextureRect
var _cards: Array[CardView] = []
var _selection_frames: Array[Panel] = []
var _base_card_positions: Array[Vector2] = []
var _confirm: TextureButton
var _selected_index := -1
var _locked := true
var _selection_tween: Tween


func setup(kind: String, ids: Array[String], skill_target_global: Vector2, crystal_target_global: Vector2, levels: Array[int], new_flags: Array[bool]) -> void:
	_kind = kind
	_ids = ids
	_levels = levels
	_new_flags = new_flags
	_skill_target_global = skill_target_global
	_crystal_target_global = crystal_target_global
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	size = DESIGN_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_tree().paused = true
	call_deferred("_play_intro")


func _build() -> void:
	_mask = ColorRect.new()
	_mask.name = "FullScreenMask"
	_mask.color = Color(0, 0, 0, 0)
	_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_mask.position = Vector2.ZERO
	_mask.size = DESIGN_SIZE
	_mask.z_index = 0
	add_child(_mask)

	var milestone := _kind == "milestone"
	_panel = TextureRect.new()
	_panel.name = "WaveCardArea" if milestone else "SkillChoicePanel"
	_panel.texture = null if milestone else load("res://assets/runtime/ui/screens/skill_choice/panel.png") as Texture2D
	_panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel.stretch_mode = TextureRect.STRETCH_SCALE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.z_index = 1
	if milestone:
		_set_rect(_panel, Vector2.ZERO, DESIGN_SIZE)
	else:
		_set_rect(_panel, SKILL_PANEL_POS, SKILL_PANEL_SIZE)
		_panel.material = _green_key_material()
	add_child(_panel)

	_title_art = TextureRect.new()
	_title_art.name = "WaveChoiceTitle" if milestone else "SkillChoiceTitle"
	_title_art.texture = load("res://assets/runtime/ui/screens/wave_choice/title.png") as Texture2D if milestone else load("res://assets/runtime/ui/screens/skill_choice/title.png") as Texture2D
	_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_art.material = _green_key_material()
	if milestone:
		_set_rect(_title_art, WAVE_TITLE_POS, WAVE_TITLE_SIZE)
	else:
		_set_rect(_title_art, Vector2((_panel.size.x - SKILL_TITLE_SIZE.x) * 0.5, -42.0), SKILL_TITLE_SIZE)
	_panel.add_child(_title_art)

	for i in range(_ids.size()):
		var card := CardView.new()
		card.name = "Card_%s" % _ids[i]
		var card_size := WAVE_CARD_SIZE if milestone else SKILL_CARD_SIZE
		var card_pos := Vector2(75 + i * 255, 740) if milestone else Vector2(48 + i * 238, 171)
		_set_rect(card, card_pos, card_size)
		card.setup(
			_ids[i],
			_levels[i] if i < _levels.size() else 1,
			_new_flags[i] if i < _new_flags.size() else false
		)
		_panel.add_child(card)
		_cards.append(card)
		_base_card_positions.append(card_pos)

		var frame := _make_selection_frame(card_size)
		card.add_child(frame)
		_selection_frames.append(frame)
		card.pressed.connect(_select_card.bind(i))
		card.mouse_entered.connect(_hover_card.bind(i, true))
		card.mouse_exited.connect(_hover_card.bind(i, false))

	if not milestone:
		_confirm = TextureButton.new()
		_confirm.name = "ConfirmChoice"
		_confirm.texture_normal = load("res://assets/runtime/ui/screens/skill_choice/button_confirm.png") as Texture2D
		_confirm.texture_hover = _confirm.texture_normal
		_confirm.texture_pressed = _confirm.texture_normal
		_confirm.ignore_texture_size = true
		_confirm.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		_confirm.focus_mode = Control.FOCUS_NONE
		_confirm.disabled = true
		_confirm.material = _green_key_material()
		_set_rect(_confirm, Vector2((_panel.size.x - SKILL_CONFIRM_SIZE.x) * 0.5, 579), SKILL_CONFIRM_SIZE)
		_panel.add_child(_confirm)
		_confirm.pressed.connect(_confirm_selection)


func _make_selection_frame(frame_size: Vector2) -> Panel:
	var frame := Panel.new()
	frame.name = "SelectionFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.75, 1.0, 0.04)
	style.border_color = Color(0.72, 0.94, 1.0, 0.95)
	style.set_border_width_all(5)
	style.set_corner_radius_all(22)
	frame.add_theme_stylebox_override("panel", style)
	_set_rect(frame, Vector2.ZERO, frame_size)
	return frame


func _play_intro() -> void:
	_locked = true
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.92, 0.92)
	var final_pos := _panel.position
	_panel.position = final_pos + Vector2(0, 24)
	for i in range(_cards.size()):
		var card := _cards[i]
		card.modulate.a = 0.0
		card.scale = Vector2(0.86, 0.86)
		card.position = _base_card_positions[i] + Vector2(0, 36)
	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.tween_property(_mask, "color", MASK_COLOR, GameConfig.CARD_MASK_FADE_IN)
	intro.parallel().tween_property(_panel, "modulate:a", 1.0, GameConfig.CARD_PANEL_INTRO)
	intro.parallel().tween_property(_panel, "scale", Vector2.ONE, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	intro.parallel().tween_property(_panel, "position", final_pos, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await intro.finished

	for i in range(_cards.size()):
		var card := _cards[i]
		var appear := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		appear.tween_property(card, "modulate:a", 1.0, GameConfig.CARD_INTRO_DURATION)
		appear.parallel().tween_property(card, "scale", Vector2.ONE, GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		appear.parallel().tween_property(card, "position", _base_card_positions[i], GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await appear.finished
		await card.reveal(GameConfig.CARD_FLIP_DURATION)
		await get_tree().create_timer(GameConfig.CARD_FLIP_STAGGER, true).timeout

	_locked = false
	for card in _cards:
		card.set_interactable(true)


func _select_card(index: int) -> void:
	if _locked or index < 0 or index >= _cards.size():
		return
	_selected_index = index
	if _kind == "milestone":
		for card in _cards:
			card.set_interactable(false)
		await get_tree().create_timer(0.08, true).timeout
		_finish_choice("")
		return

	if _confirm:
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
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.parallel().tween_property(card, "scale", Vector2(1.035, 1.035) if entered else Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(card, "modulate", Color(1.08, 1.08, 1.08, 1.0) if entered else Color.WHITE, 0.10).set_trans(Tween.TRANS_SINE)


func _confirm_selection() -> void:
	if _locked or _selected_index < 0:
		return
	_finish_choice("")


func _finish_choice(element_key: String) -> void:
	if _locked or _selected_index < 0 or _selected_index >= _cards.size():
		return
	_locked = true
	if _selection_tween and _selection_tween.is_valid():
		_selection_tween.kill()
	var chosen_id := _ids[_selected_index]
	var chosen := _cards[_selected_index]
	for card in _cards:
		card.set_interactable(false)
		if card != chosen:
			var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			fade.parallel().tween_property(card, "modulate:a", 0.0, GameConfig.CARD_UNSELECTED_FADE)
			fade.parallel().tween_property(card, "scale", Vector2(0.84, 0.84), GameConfig.CARD_UNSELECTED_FADE)

	var start_global := chosen.global_position
	var start_size := chosen.size
	chosen.reparent(self, true)
	chosen.global_position = start_global
	chosen.size = start_size
	chosen.pivot_offset = chosen.size * 0.5
	var is_crystal := CardCatalog.is_crystal_card(chosen_id)
	var duration := GameConfig.CARD_CRYSTAL_FLY_DURATION if is_crystal else GameConfig.CARD_SKILL_FLY_DURATION
	var target_global := _crystal_target_global if is_crystal else _skill_target_global
	var target_pos := target_global - chosen.size * 0.5 * 0.12
	var fly := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly.parallel().tween_property(chosen, "global_position", target_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.parallel().tween_property(chosen, "scale", Vector2(0.12, 0.12) if is_crystal else Vector2(0.18, 0.18), duration)
	fly.tween_property(chosen, "modulate:a", 0.0, 0.12)
	await fly.finished
	choice_committed.emit(_kind, chosen_id, element_key, int(_levels[_selected_index] if _selected_index < _levels.size() else 1))

	var outro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.parallel().tween_property(_panel, "modulate:a", 0.0, GameConfig.CARD_PANEL_FADE_OUT)
	outro.parallel().tween_property(_mask, "color:a", 0.0, GameConfig.CARD_MASK_FADE_OUT)
	await outro.finished
	get_tree().paused = false
	modal_closed.emit(_kind)
	queue_free()


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _green_key_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GREEN_KEY_SHADER
	return material
