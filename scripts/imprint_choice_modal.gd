extends Control
class_name ImprintChoiceModal

signal choice_committed(kind: String, card_id: String, element_key: String, level: int)
signal modal_closed(kind: String)
signal locked_slot_pressed(card_id: String)

const MASK_COLOR := Color(0.0, 0.0, 0.0, 180.0 / 255.0)
const PANEL_FINAL_POSITION := Vector2(53.0, 189.0)
const SLOT_SIZE := Vector2(180.0, 310.0)
const SLOT_STEP := 190.0
const SLOT_LAYOUT_WIDTH := 736.0
const SLOT_ICON_RECT := Rect2(14.0, 14.0, 152.0, 152.0)
const SLOT_BASE_RECT := Rect2(-45.0, -45.0, 270.0, 270.0)
const SLOT_RING_RECT := Rect2(-24.0, -23.0, 236.0, 236.0)
const SLOT_CHECK_RECT := Rect2(116.0, -17.0, 88.0, 88.0)
const SLOT_LOCK_RECT := Rect2(35.0, 45.0, 110.0, 110.0)
const SLOT_AD_RECT := Rect2(114.0, 115.0, 84.0, 84.0)
const SLOT_LABEL_RECT := Rect2(-4.0, 194.0, 195.0, 78.0)
const SLOT_LOCKED_LABEL_RECT := Rect2(5.0, 260.0, 170.0, 46.0)
const COMMIT_FLY_DURATION := 0.46
# Offer icons use a 152 px canvas while the pending HUD slot uses 88 px.
# 88 / 152 = 0.579, so this makes the handoff match at the pixel level.
const COMMIT_ARRIVAL_SCALE := 0.58

const SLOT_DEFAULT := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/slot/slot_default.png")
const SELECTED_RING := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/overlay/selected_ring.png")
const SELECTED_CHECK := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/overlay/selected_check.png")
const LOCK_TEXTURE := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/overlay/lock.png")
const AD_PLAY_TEXTURE := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/overlay/ad_play.png")
const NAME_LABEL_TEXTURE := preload("res://assets/runtime/ui/battle/prompts/imprint_choice/panel/description_panel.png")
const LOCKED_GRAYSCALE_SHADER := preload("res://shaders/ui_locked_grayscale.gdshader")

@onready var _mask: ColorRect = $FullScreenMask
@onready var _panel_root: Control = $PanelRoot
@onready var _slots_root: Control = $PanelRoot/SlotsRoot
@onready var _description_label: Label = $PanelRoot/DescriptionPanel/EffectLabel
@onready var _description_name_label: Label = $PanelRoot/DescriptionPanel/NameLabel
@onready var _confirm_button: TextureButton = $PanelRoot/ConfirmButton

var _ids: Array[String] = []
var _levels: Array[int] = []
var _locked_flags: Array[bool] = []
var _skill_target_global := Vector2.ZERO
var _slot_views: Array[Dictionary] = []
var _selected_index := -1
var _input_locked := true
var _selection_pulse: Tween
var _notice_generation := 0
var _commit_flight_start_global := Vector2.ZERO
var _commit_flight_target_global := Vector2.ZERO
var _commit_flight_control_global := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_confirm_button.pressed.connect(_confirm_selection)
	_confirm_button.disabled = true


func setup(ids: Array[String], skill_target_global: Vector2, levels: Array[int], locked_flags: Array[bool]) -> void:
	_ids = ids.duplicate()
	_levels = levels.duplicate()
	_locked_flags = locked_flags.duplicate()
	_skill_target_global = skill_target_global
	while _locked_flags.size() < _ids.size():
		_locked_flags.append(_locked_flags.size() >= GameConfig.ENERGY_IMPRINT_FREE_SLOT_COUNT)
	_build_slots()
	_selected_index = -1
	_refresh_description()
	get_tree().paused = true
	call_deferred("_play_intro")


func _build_slots() -> void:
	for child in _slots_root.get_children():
		child.queue_free()
	_slot_views.clear()
	for index in range(_ids.size()):
		var card_id := _ids[index]
		var locked := bool(_locked_flags[index])
		var slot := Control.new()
		slot.name = "ImprintSlot_%d_%s" % [index + 1, card_id]
		slot.position = _slot_position_for_index(index, _ids.size())
		slot.size = SLOT_SIZE
		slot.pivot_offset = Vector2(90.0, 90.0)
		slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots_root.add_child(slot)

		var base := _texture_rect(SLOT_DEFAULT)
		base.name = "SlotBase"
		_set_rect(base, SLOT_BASE_RECT.position, SLOT_BASE_RECT.size)
		slot.add_child(base)

		var button := Button.new()
		button.name = "SlotButton"
		button.flat = true
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		_set_rect(button, Vector2.ZERO, Vector2(180.0, 180.0))
		slot.add_child(button)

		var icon := _texture_rect(_icon_texture(card_id))
		icon.name = "Icon"
		_set_rect(icon, SLOT_ICON_RECT.position, SLOT_ICON_RECT.size)
		if locked:
			var grayscale := ShaderMaterial.new()
			grayscale.shader = LOCKED_GRAYSCALE_SHADER
			icon.material = grayscale
		slot.add_child(icon)

		var ring := _texture_rect(SELECTED_RING)
		ring.name = "SelectedRing"
		ring.visible = false
		_set_rect(ring, SLOT_RING_RECT.position, SLOT_RING_RECT.size)
		slot.add_child(ring)

		var check := _texture_rect(SELECTED_CHECK)
		check.name = "SelectedCheck"
		check.visible = false
		_set_rect(check, SLOT_CHECK_RECT.position, SLOT_CHECK_RECT.size)
		slot.add_child(check)

		var lock_icon := _texture_rect(LOCK_TEXTURE)
		lock_icon.name = "Lock"
		lock_icon.visible = locked
		_set_rect(lock_icon, SLOT_LOCK_RECT.position, SLOT_LOCK_RECT.size)
		slot.add_child(lock_icon)

		var ad_play := _texture_rect(AD_PLAY_TEXTURE)
		ad_play.name = "AdPlay"
		ad_play.visible = locked
		_set_rect(ad_play, SLOT_AD_RECT.position, SLOT_AD_RECT.size)
		slot.add_child(ad_play)

		var name_plate := NinePatchRect.new()
		name_plate.name = "NamePlate"
		name_plate.texture = NAME_LABEL_TEXTURE
		name_plate.patch_margin_left = 28
		name_plate.patch_margin_right = 28
		name_plate.patch_margin_top = 20
		name_plate.patch_margin_bottom = 20
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(name_plate, SLOT_LABEL_RECT.position, SLOT_LABEL_RECT.size)
		slot.add_child(name_plate)

		var name_label := _label(_imprint_name(card_id), 28, Color.WHITE, 4)
		name_label.name = "Name"
		_set_rect(name_label, SLOT_LABEL_RECT.position + Vector2(5.0, 2.0), SLOT_LABEL_RECT.size - Vector2(10.0, 4.0))
		slot.add_child(name_label)

		var locked_plate := Panel.new()
		locked_plate.name = "LockedPlate"
		var locked_style := StyleBoxFlat.new()
		locked_style.bg_color = Color(0.24, 0.26, 0.36, 0.62)
		locked_style.set_corner_radius_all(8)
		locked_plate.add_theme_stylebox_override("panel", locked_style)
		locked_plate.visible = locked
		locked_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(locked_plate, SLOT_LOCKED_LABEL_RECT.position, SLOT_LOCKED_LABEL_RECT.size)
		slot.add_child(locked_plate)

		var locked_label := _label("看广告解锁" if locked else "", 23, Color(0.68, 0.70, 0.77, 1.0), 2)
		locked_label.name = "LockedLabel"
		_set_rect(locked_label, SLOT_LOCKED_LABEL_RECT.position, SLOT_LOCKED_LABEL_RECT.size)
		slot.add_child(locked_label)

		button.pressed.connect(_on_slot_pressed.bind(index))
		button.button_down.connect(_on_slot_button_down.bind(index))
		button.button_up.connect(_on_slot_button_up.bind(index))
		_slot_views.append({
			"root": slot,
			"button": button,
			"base": base,
			"icon": icon,
			"ring": ring,
			"check": check,
			"base_position": slot.position,
		})


func _slot_position_for_index(index: int, slot_count: int) -> Vector2:
	# Legacy layout helper retained for this unused scene. Runtime Chapter One
	# choices use ImprintChoiceModalV2 and always provide three candidates.
	if slot_count >= 4:
		return Vector2(float(index) * SLOT_STEP, 0.0)
	var group_width := SLOT_SIZE.x + float(maxi(0, slot_count - 1)) * SLOT_STEP
	var group_left := maxf(0.0, (SLOT_LAYOUT_WIDTH - group_width) * 0.5)
	return Vector2(group_left + float(index) * SLOT_STEP, 0.0)


func _play_intro() -> void:
	_input_locked = true
	_confirm_button.disabled = true
	_mask.color = Color(0.0, 0.0, 0.0, 0.0)
	_panel_root.modulate.a = 0.0
	_panel_root.position = PANEL_FINAL_POSITION + Vector2(0.0, 24.0)
	_panel_root.scale = Vector2(0.94, 0.94)
	for index in range(_slot_views.size()):
		var slot := _slot_views[index]["root"] as Control
		var base_position: Vector2 = _slot_views[index]["base_position"]
		slot.modulate.a = 0.0
		slot.position = base_position + Vector2(0.0, 28.0)
		slot.scale = Vector2(0.84, 0.84)

	var panel_intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	panel_intro.tween_property(_mask, "color", MASK_COLOR, GameConfig.CARD_MASK_FADE_IN)
	panel_intro.parallel().tween_property(_panel_root, "modulate:a", 1.0, GameConfig.CARD_PANEL_INTRO)
	panel_intro.parallel().tween_property(_panel_root, "position", PANEL_FINAL_POSITION, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel_intro.parallel().tween_property(_panel_root, "scale", Vector2.ONE, GameConfig.CARD_PANEL_INTRO).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	for index in range(_slot_views.size()):
		var slot := _slot_views[index]["root"] as Control
		var base_position: Vector2 = _slot_views[index]["base_position"]
		var target_scale := Vector2.ONE
		var slot_intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		slot_intro.tween_interval(0.04 + float(index) * 0.045)
		slot_intro.tween_property(slot, "modulate:a", 1.0, 0.20)
		slot_intro.parallel().tween_property(slot, "position", base_position, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		slot_intro.parallel().tween_property(slot, "scale", target_scale, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var total := 0.04 + maxf(0.0, float(_slot_views.size() - 1)) * 0.045 + 0.24
	await get_tree().create_timer(total, true).timeout
	if not is_inside_tree():
		return
	_input_locked = false
	_confirm_button.disabled = _selected_index < 0
	_start_selection_pulse()


func _on_slot_pressed(index: int) -> void:
	if _input_locked or index < 0 or index >= _ids.size():
		return
	if bool(_locked_flags[index]):
		locked_slot_pressed.emit(_ids[index])
		_show_locked_notice()
		return
	_set_selected(index, true)


func _on_slot_button_down(index: int) -> void:
	if _input_locked or index < 0 or index >= _slot_views.size():
		return
	_tween_slot_modulate(index, Color(0.86, 0.88, 0.96, 1.0))


func _on_slot_button_up(index: int) -> void:
	if _input_locked or index < 0 or index >= _slot_views.size():
		return
	_tween_slot_modulate(index, Color.WHITE)


func _set_selected(index: int, animated: bool) -> void:
	if index < 0 or index >= _ids.size() or bool(_locked_flags[index]):
		return
	_selected_index = index
	_notice_generation += 1
	for slot_index in range(_slot_views.size()):
		var selected := slot_index == index
		var slot := _slot_views[slot_index]["root"] as Control
		var ring := _slot_views[slot_index]["ring"] as TextureRect
		var check := _slot_views[slot_index]["check"] as TextureRect
		ring.visible = selected
		check.visible = selected
		slot.z_index = 3 if selected else 0
		if animated:
			_tween_slot_scale(slot_index, 1.0)
		else:
			slot.scale = Vector2.ONE
	_refresh_description()
	if not _input_locked:
		_confirm_button.disabled = false
		_start_selection_pulse()


func _tween_slot_scale(index: int, value: float) -> void:
	var slot := _slot_views[index]["root"] as Control
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(slot, "scale", Vector2.ONE * value, 0.11).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _tween_slot_modulate(index: int, value: Color) -> void:
	var slot := _slot_views[index]["root"] as Control
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(slot, "modulate", value, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _start_selection_pulse() -> void:
	if _selection_pulse and _selection_pulse.is_valid():
		_selection_pulse.kill()
	if _selected_index < 0 or _selected_index >= _slot_views.size():
		return
	var ring := _slot_views[_selected_index]["ring"] as TextureRect
	ring.modulate.a = 1.0
	_selection_pulse = create_tween().set_loops().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_selection_pulse.tween_property(ring, "modulate:a", 0.55, 0.58).set_trans(Tween.TRANS_SINE)
	_selection_pulse.tween_property(ring, "modulate:a", 1.0, 0.58).set_trans(Tween.TRANS_SINE)


func _refresh_description() -> void:
	if _selected_index < 0 or _selected_index >= _ids.size():
		_description_label.text = "请选择技能印记"
		_description_label.add_theme_font_size_override("font_size", 31)
		_description_name_label.text = ""
		return
	var card_id := _ids[_selected_index]
	var level := _level_for_index(_selected_index)
	var description := _imprint_description(card_id, level)
	_description_label.text = description
	_description_label.add_theme_font_size_override("font_size", _description_font_size(description))
	_description_name_label.text = _imprint_name(card_id)


func _show_locked_notice() -> void:
	_notice_generation += 1
	var generation := _notice_generation
	_description_label.text = "广告功能暂未开放"
	_description_label.add_theme_font_size_override("font_size", 31)
	_description_name_label.text = "请选择前两个已开放印记"
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_description_label.modulate = Color(1.18, 0.88, 0.36, 1.0)
	tween.tween_property(_description_label, "modulate", Color.WHITE, 0.28).set_trans(Tween.TRANS_SINE)
	await get_tree().create_timer(1.15, true).timeout
	if generation == _notice_generation and is_inside_tree():
		_refresh_description()


func _confirm_selection() -> void:
	if _input_locked or _selected_index < 0 or _selected_index >= _ids.size() or bool(_locked_flags[_selected_index]):
		return
	_input_locked = true
	_confirm_button.disabled = true
	if _selection_pulse and _selection_pulse.is_valid():
		_selection_pulse.kill()
	for view in _slot_views:
		(view["button"] as BaseButton).disabled = true

	var chosen_id := _ids[_selected_index]
	var chosen_level := _level_for_index(_selected_index)
	var chosen_icon := _slot_views[_selected_index]["icon"] as TextureRect
	var fly_icon := _texture_rect(chosen_icon.texture)
	fly_icon.name = "ChosenImprintFlyIcon"
	fly_icon.z_index = 50
	fly_icon.size = chosen_icon.size
	fly_icon.pivot_offset = fly_icon.size * 0.5
	add_child(fly_icon)
	_commit_flight_start_global = chosen_icon.get_global_transform_with_canvas() * (chosen_icon.size * 0.5)
	chosen_icon.modulate.a = 0.0

	var target_global := _skill_target_global
	if target_global == Vector2.ZERO:
		target_global = Vector2(190.0, 1515.0)
	_commit_flight_target_global = target_global
	_commit_flight_control_global = _make_commit_curve_control(_commit_flight_start_global, _commit_flight_target_global)
	_set_commit_flight_progress(0.0, fly_icon)
	var fly := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly.tween_property(_panel_root, "modulate:a", 0.0, 0.18)
	fly.parallel().tween_method(
		_set_commit_flight_progress.bind(fly_icon),
		0.0,
		1.0,
		COMMIT_FLY_DURATION
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await fly.finished
	if not is_inside_tree():
		return
	# Replace the travelling copy with the real HUD icon on the exact arrival
	# frame. EnergyHud starts its bounce at the same scale, so there is no pop
	# or coordinate jump between the two nodes.
	fly_icon.visible = false
	choice_committed.emit("energy", chosen_id, "", chosen_level)
	fly_icon.queue_free()

	var outro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.tween_property(_mask, "color:a", 0.0, GameConfig.CARD_MASK_FADE_OUT)
	await outro.finished
	get_tree().paused = false
	modal_closed.emit("energy")
	queue_free()


func _make_commit_curve_control(start_global: Vector2, target_global: Vector2) -> Vector2:
	var delta := target_global - start_global
	var lateral_bend := clampf(absf(delta.y) * 0.14, 90.0, 170.0)
	var control := start_global.lerp(target_global, 0.44)
	# The pending slot is on the left. Bowing right first produces a readable
	# downward arc from every one of the four offer positions.
	control.x += lateral_bend
	control.y = start_global.y + delta.y * 0.40
	var viewport_width := get_viewport_rect().size.x
	control.x = clampf(control.x, 64.0, maxf(64.0, viewport_width - 64.0))
	return control


func _quadratic_bezier(start: Vector2, control: Vector2, target: Vector2, progress: float) -> Vector2:
	var t := clampf(progress, 0.0, 1.0)
	var inverse := 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + target * t * t


func _set_commit_flight_progress(progress: float, fly_icon: TextureRect) -> void:
	if fly_icon == null or not is_instance_valid(fly_icon):
		return
	var t := clampf(progress, 0.0, 1.0)
	var center_global := _quadratic_bezier(
		_commit_flight_start_global,
		_commit_flight_control_global,
		_commit_flight_target_global,
		t
	)
	var center_local := get_global_transform_with_canvas().affine_inverse() * center_global
	fly_icon.position = center_local - fly_icon.size * 0.5
	var scale_progress := smoothstep(0.0, 1.0, t)
	fly_icon.scale = Vector2.ONE * lerpf(1.0, COMMIT_ARRIVAL_SCALE, scale_progress)


func _level_for_index(index: int) -> int:
	return clampi(int(_levels[index] if index < _levels.size() else 1), 1, GameConfig.MAX_CARD_LEVEL)


func _imprint_name(card_id: String) -> String:
	return str(CardCatalog.get_definition(card_id).get("item_name", SkillImprintSystem.IMPRINT_NAMES.get(card_id, card_id)))


func _imprint_description(card_id: String, level: int) -> String:
	match card_id:
		"ascension_hammer":
			return "下一次合成结果提升%d级" % int(GameConfig.ASCENSION_EXTRA_LEVELS[level - 1])
		"unity_dial":
			return "将其余非最高级方块统一为本次合成前数字"
		"fate_shuffler":
			return "重新排列棋盘，并保证至少一组可合成方块"
		"twin_mold":
			return "使%d个相邻方块变为本次合成结果数字" % int(GameConfig.TWIN_MOLD_TARGETS[level - 1])
		"castle_cannon":
			return "对最前方怪物造成%d%%基础攻击伤害" % roundi(float(GameConfig.CASTLE_CANNON_DAMAGE[level - 1]) * 100.0)
		"dragon_catapult":
			return "攻击前方%d个怪物，造成%d%%伤害并附加燃烧" % [
				int(GameConfig.DRAGON_CATAPULT_TARGETS[level - 1]),
				roundi(float(GameConfig.DRAGON_CATAPULT_DAMAGE[level - 1]) * 100.0),
			]
	return str(CardCatalog.get_definition(card_id).get("description", ""))


func _description_font_size(value: String) -> int:
	if value.length() <= 15:
		return 31
	if value.length() <= 21:
		return 28
	return 25


func _icon_texture(card_id: String) -> Texture2D:
	var path := str(GameConfig.SKILL_IMPRINT_TEXTURES.get(card_id, ""))
	return load(path) as Texture2D if not path.is_empty() else null


func _texture_rect(texture: Texture2D) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _label(value: String, font_size: int, color: Color, outline_size: int) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.025, 0.045, 0.10, 1.0))
	node.add_theme_constant_override("outline_size", outline_size)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5
