extends Control
class_name CrystalCardChoiceModalV2

const UiTypographyScript := preload("res://scripts/ui_typography.gd")

signal choice_committed(kind: String, card_id: String, element_key: String, level: int)
signal modal_closed(kind: String)

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const MASK_COLOR := Color(0.0, 0.0, 0.0, 180.0 / 255.0)
const TITLE_TEXTURE := preload("res://assets/runtime/ui/interfaces/crystal_card_choice/decorations/ui_title_ribbon_blank_1070x216_2x_v01.png")
const CONFIRM_TEXTURE := preload("res://assets/runtime/ui/interfaces/crystal_card_choice/buttons/ui_button_confirm_blank_464x152_2x_v01.png")
const TITLE_RECT := Rect2(34.0, 270.0, 873.0, 176.0)
const CARD_SIZE := Vector2(284.0, 530.0)
const CARD_GAP := 16.0
const CARD_Y := 557.0
const CONFIRM_RECT := Rect2(296.5, 1193.0, 348.0, 114.0)
const TITLE_FONT_SIZE := 64
const TITLE_OUTLINE_SIZE := 10
const CONFIRM_FONT_SIZE := 52

var _kind := "milestone"
var _ids: Array[String] = []
var _levels: Array[int] = []
var _new_flags: Array[bool] = []
var _skill_target_global := Vector2.ZERO
var _crystal_target_global := Vector2.ZERO
var _selected_index := -1
var _locked := true

var _mask: ColorRect
var _content_root: Control
var _cards_root: Control
var _confirm: TextureButton
var _title_label: Label
var _confirm_label: Label
var _cards: Array[CrystalChoiceCardViewV2] = []
var _selection_frames: Array[Panel] = []
var _base_card_positions: Array[Vector2] = []


func setup(
	kind: String,
	ids: Array[String],
	skill_target_global: Vector2,
	crystal_target_global: Vector2,
	levels: Array[int],
	new_flags: Array[bool]
) -> void:
	_kind = kind
	_ids = ids.duplicate()
	_levels = levels.duplicate()
	_new_flags = new_flags.duplicate()
	_skill_target_global = skill_target_global
	_crystal_target_global = crystal_target_global
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	get_tree().paused = true
	call_deferred("_play_intro")


func _build() -> void:
	_mask = ColorRect.new()
	_mask.name = "FullScreenMask"
	_mask.color = Color(0.0, 0.0, 0.0, 0.0)
	_mask.mouse_filter = Control.MOUSE_FILTER_STOP
	_set_rect(_mask, Vector2.ZERO, DESIGN_SIZE)
	add_child(_mask)

	_content_root = Control.new()
	_content_root.name = "ContentRoot"
	_content_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_content_root, Vector2.ZERO, DESIGN_SIZE)
	add_child(_content_root)

	var title := TextureRect.new()
	title.name = "TitleRibbon"
	title.texture = TITLE_TEXTURE
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(title, TITLE_RECT.position, TITLE_RECT.size)
	_content_root.add_child(title)
	_title_label = _label("选择合成印记", TITLE_FONT_SIZE, Color.WHITE, TITLE_OUTLINE_SIZE, 900)
	_title_label.name = "Title"
	_title_label.add_theme_color_override("font_outline_color", Color(0.43, 0.18, 0.03, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.20, 0.07, 0.01, 0.70))
	_title_label.add_theme_constant_override("shadow_offset_y", 4)
	_set_rect(_title_label, Vector2(190.0, 4.0), Vector2(493.0, 145.0))
	title.add_child(_title_label)
	var left_diamond := _label("◆", 26, Color(1.0, 0.98, 0.78, 1.0), 4, 900)
	left_diamond.name = "LeftDiamond"
	left_diamond.add_theme_color_override("font_outline_color", Color(0.65, 0.32, 0.02, 1.0))
	_set_rect(left_diamond, Vector2(145.0, 51.0), Vector2(42.0, 42.0))
	title.add_child(left_diamond)
	var right_diamond := _label("◆", 26, Color(1.0, 0.98, 0.78, 1.0), 4, 900)
	right_diamond.name = "RightDiamond"
	right_diamond.add_theme_color_override("font_outline_color", Color(0.65, 0.32, 0.02, 1.0))
	_set_rect(right_diamond, Vector2(686.0, 51.0), Vector2(42.0, 42.0))
	title.add_child(right_diamond)

	_cards_root = Control.new()
	_cards_root.name = "CardsRoot"
	_cards_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_cards_root, Vector2.ZERO, DESIGN_SIZE)
	_content_root.add_child(_cards_root)

	var count := _ids.size()
	var group_width := float(count) * CARD_SIZE.x + float(maxi(0, count - 1)) * CARD_GAP
	var group_left := (DESIGN_SIZE.x - group_width) * 0.5
	for index in range(count):
		var card := CrystalChoiceCardViewV2.new()
		card.name = "Card_%s" % _ids[index]
		var card_position := Vector2(group_left + float(index) * (CARD_SIZE.x + CARD_GAP), CARD_Y)
		_set_rect(card, card_position, CARD_SIZE)
		card.setup(
			_ids[index],
			_levels[index] if index < _levels.size() else 1,
			_new_flags[index] if index < _new_flags.size() else false
		)
		_cards_root.add_child(card)
		_cards.append(card)
		_base_card_positions.append(card_position)
		var selection_frame := _make_selection_frame(CARD_SIZE)
		card.add_child(selection_frame)
		# The selection treatment is a backing glow/border. Keep it below the
		# card transform and hit area so it never tints icons, copy or stars.
		card.move_child(selection_frame, 0)
		_selection_frames.append(selection_frame)
		card.pressed.connect(_select_card.bind(index))
		card.mouse_entered.connect(_hover_card.bind(index, true))
		card.mouse_exited.connect(_hover_card.bind(index, false))

	_confirm = TextureButton.new()
	_confirm.name = "ConfirmButton"
	_confirm.texture_normal = CONFIRM_TEXTURE
	_confirm.texture_hover = CONFIRM_TEXTURE
	_confirm.texture_pressed = CONFIRM_TEXTURE
	_confirm.ignore_texture_size = true
	_confirm.stretch_mode = TextureButton.STRETCH_SCALE
	_confirm.focus_mode = Control.FOCUS_NONE
	_confirm.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(_confirm, CONFIRM_RECT.position, CONFIRM_RECT.size)
	_confirm.pressed.connect(_confirm_selection)
	_confirm.button_down.connect(_on_confirm_down)
	_confirm.button_up.connect(_on_confirm_up)
	_content_root.add_child(_confirm)
	_confirm_label = _label("确定", CONFIRM_FONT_SIZE, Color.WHITE, 8, 900)
	_confirm_label.name = "Label"
	_confirm_label.add_theme_color_override("font_outline_color", Color(0.48, 0.18, 0.02, 1.0))
	_set_rect(_confirm_label, Vector2.ZERO, CONFIRM_RECT.size)
	_confirm.add_child(_confirm_label)
	_set_confirm_enabled(false)


func _make_selection_frame(frame_size: Vector2) -> Panel:
	var frame := Panel.new()
	frame.name = "SelectionFrame"
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1.0, 0.78, 0.16, 0.06)
	style.border_color = Color(1.0, 0.84, 0.25, 1.0)
	style.set_border_width_all(5)
	style.set_corner_radius_all(28)
	style.shadow_color = Color(1.0, 0.72, 0.08, 0.55)
	style.shadow_size = 10
	frame.add_theme_stylebox_override("panel", style)
	_set_rect(frame, Vector2(-5.0, -5.0), frame_size + Vector2(10.0, 10.0))
	return frame


func _play_intro() -> void:
	_locked = true
	_content_root.modulate.a = 0.0
	for index in range(_cards.size()):
		var card := _cards[index]
		card.modulate.a = 0.0
		card.position = _base_card_positions[index] + Vector2(0.0, 38.0)
		card.scale = Vector2(0.88, 0.88)
	var intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	intro.tween_property(_mask, "color", MASK_COLOR, GameConfig.CARD_MASK_FADE_IN)
	intro.parallel().tween_property(_content_root, "modulate:a", 1.0, GameConfig.CARD_PANEL_INTRO)
	for index in range(_cards.size()):
		_play_card_intro(_cards[index], index)
	var last_delay := 0.03 + maxf(0.0, float(_cards.size() - 1)) * GameConfig.CARD_FLIP_STAGGER
	var total := last_delay + maxf(GameConfig.CARD_INTRO_DURATION, GameConfig.CARD_FLIP_DURATION) + 0.06
	await get_tree().create_timer(total, true).timeout
	if not is_inside_tree():
		return
	_locked = false
	for card in _cards:
		card.set_interactable(true)


func _play_card_intro(card: CrystalChoiceCardViewV2, index: int) -> void:
	var delay := 0.03 + float(index) * GameConfig.CARD_FLIP_STAGGER
	await get_tree().create_timer(delay, true).timeout
	if not is_instance_valid(card):
		return
	card.reveal(GameConfig.CARD_FLIP_DURATION)
	var appear := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	appear.tween_property(card, "modulate:a", 1.0, GameConfig.CARD_INTRO_DURATION)
	appear.parallel().tween_property(card, "position", _base_card_positions[index], GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	appear.parallel().tween_property(card, "scale", Vector2.ONE, GameConfig.CARD_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _select_card(index: int) -> void:
	if _locked or index < 0 or index >= _cards.size():
		return
	_selected_index = index
	_set_confirm_enabled(true)
	for card_index in range(_cards.size()):
		var selected := card_index == index
		var card := _cards[card_index]
		_selection_frames[card_index].visible = selected
		card.z_index = 4 if selected else 0
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.parallel().tween_property(card, "scale", Vector2(1.045, 1.045) if selected else Vector2(0.96, 0.96), 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(card, "position", _base_card_positions[card_index] + (Vector2(0.0, -11.0) if selected else Vector2.ZERO), 0.13)
		tween.parallel().tween_property(card, "modulate", Color.WHITE if selected else Color(1.0, 1.0, 1.0, 0.82), 0.13)


func _hover_card(index: int, entered: bool) -> void:
	if _locked or index == _selected_index or index < 0 or index >= _cards.size():
		return
	var card := _cards[index]
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(card, "scale", Vector2(1.025, 1.025) if entered else Vector2(0.96, 0.96) if _selected_index >= 0 else Vector2.ONE, 0.10)


func _on_confirm_down() -> void:
	if _confirm.disabled:
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_confirm, "scale", Vector2(0.96, 0.96), 0.07)


func _on_confirm_up() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_confirm, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_confirm_enabled(enabled: bool) -> void:
	_confirm.disabled = not enabled
	_confirm.modulate = Color.WHITE if enabled else Color(0.52, 0.54, 0.58, 0.92)


func _confirm_selection() -> void:
	if _locked or _selected_index < 0:
		return
	_finish_choice("")


func _finish_choice(element_key: String) -> void:
	if _locked or _selected_index < 0 or _selected_index >= _cards.size():
		return
	_locked = true
	_set_confirm_enabled(false)
	var chosen_id := _ids[_selected_index]
	var chosen := _cards[_selected_index]
	for card in _cards:
		card.set_interactable(false)
		if card != chosen:
			var fade := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			fade.parallel().tween_property(card, "modulate:a", 0.0, GameConfig.CARD_UNSELECTED_FADE)
			fade.parallel().tween_property(card, "scale", Vector2(0.84, 0.84), GameConfig.CARD_UNSELECTED_FADE)

	chosen.reparent(self, true)
	chosen.z_as_relative = true
	chosen.z_index = 100
	chosen.pivot_offset = chosen.size * 0.5
	var is_crystal := CardCatalog.is_crystal_card(chosen_id)
	var duration := GameConfig.CARD_CRYSTAL_FLY_DURATION if is_crystal else GameConfig.CARD_SKILL_FLY_DURATION
	var target_global := _crystal_target_global if is_crystal else _skill_target_global
	if target_global == Vector2.ZERO:
		target_global = Vector2(470.0, 430.0) if is_crystal else Vector2(170.0, 1510.0)
	var target_scale := Vector2(0.12, 0.12) if is_crystal else Vector2(0.18, 0.18)
	var target_position := target_global - chosen.size * 0.5 * target_scale
	var fly := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly.parallel().tween_property(chosen, "global_position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.parallel().tween_property(chosen, "scale", target_scale, duration)
	fly.parallel().tween_property(_content_root, "modulate:a", 0.12, minf(0.22, duration))
	fly.tween_property(chosen, "modulate:a", 0.0, 0.12)
	await fly.finished
	if not is_inside_tree():
		return
	choice_committed.emit(_kind, chosen_id, element_key, int(_levels[_selected_index] if _selected_index < _levels.size() else 1))
	var outro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.tween_property(_mask, "color:a", 0.0, GameConfig.CARD_MASK_FADE_OUT)
	await outro.finished
	get_tree().paused = false
	modal_closed.emit(_kind)
	queue_free()


func _label(value: String, font_size: int, color: Color, outline_size: int, font_weight: int = 800) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.01, 1.0))
	node.add_theme_constant_override("outline_size", outline_size)
	UiTypographyScript.apply(node, font_weight)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5
