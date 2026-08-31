extends Control
class_name ImprintChoiceModalV2

const UiTypographyScript := preload("res://scripts/ui_typography.gd")

signal choice_committed(kind: String, card_id: String, element_key: String, level: int)
signal modal_closed(kind: String)
signal locked_slot_pressed(card_id: String)

const DESIGN_SIZE := Vector2(941.0, 1672.0)
const MASK_COLOR := Color(0.0, 0.0, 0.0, 180.0 / 255.0)
const TITLE_RECT := Rect2(166.0, 350.0, 608.0, 104.0)
const CARD_SIZE := Vector2(282.0, 598.0)
const CARD_Y := 527.0
const CARD_GAP := 13.0
const CONFIRM_RECT := Rect2(319.0, 1205.0, 303.0, 110.0)
const HINT_RECT := Rect2(150.0, 1140.0, 440.0, 58.0)
const COMMIT_FLY_DURATION := 0.46
const COMMIT_ARRIVAL_SCALE := 0.45
const ICON_SAFE_RECT := Rect2(44.0, 128.0, 194.0, 202.0)
const DESCRIPTION_RECT := Rect2(34.0, 378.0, 214.0, 140.0)
const DESCRIPTION_MAX_FONT_SIZE := 21
const DESCRIPTION_MIN_FONT_SIZE := 18
const DESCRIPTION_LINE_SPACING := -2

const CARD_TEXTURE := preload("res://assets/runtime/ui/interfaces/imprint_choice/backplates/ui_item_card_blank_300x636_2x_v01.png")
const CONFIRM_TEXTURE := preload("res://assets/runtime/ui/interfaces/imprint_choice/buttons/ui_button_confirm_blank_330x120_2x_v01.png")
const AD_TEXTURE := preload("res://assets/runtime/ui/interfaces/imprint_choice/buttons/ui_button_ad_unlock_blank_316x92_2x_v01.png")
const NEW_BADGE_TEXTURE := preload("res://assets/runtime/ui/interfaces/imprint_choice/decorations/ui_badge_new_blank_128x120_2x_v01.png")
const TITLE_ORNAMENT_TEXTURE := preload("res://assets/runtime/ui/interfaces/imprint_choice/decorations/ui_title_banner_blank_304x52_v01.png")

const CARD_ARTIFACT_CLEANUP_SHADER_SOURCE := """
shader_type canvas_item;

void fragment() {
	vec2 sample_uv = UV;
	// The supplied card slice contains a stray white horizontal highlight in
	// the top field and a dark vertical seam along the right content edge.
	// Clone the adjacent clean pixels only inside those two straight regions.
	if (sample_uv.x > 0.095 && sample_uv.x < 0.905 && sample_uv.y > 0.020 && sample_uv.y < 0.046) {
		sample_uv.y = 0.054;
	}
	if (sample_uv.x > 0.908 && sample_uv.x < 0.940 && sample_uv.y > 0.195 && sample_uv.y < 0.905) {
		sample_uv.x = 0.895;
	}
	COLOR = texture(TEXTURE, sample_uv) * COLOR;
}
"""

var _ids: Array[String] = []
var _levels: Array[int] = []
var _locked_flags: Array[bool] = []
var _new_flags: Array[bool] = []
var _skill_target_global := Vector2.ZERO
var _selected_index := -1
var _input_locked := true
var _slot_views: Array[Dictionary] = []
var _notice_generation := 0
var _commit_flight_start_global := Vector2.ZERO
var _commit_flight_target_global := Vector2.ZERO
var _commit_flight_control_global := Vector2.ZERO

var _mask: ColorRect
var _content_root: Control
var _slots_root: Control
var _hint_label: Label
var _confirm_button: TextureButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_static_interface()


func setup(
	ids: Array[String],
	skill_target_global: Vector2,
	levels: Array[int],
	locked_flags: Array[bool],
	new_flags: Array[bool] = [],
	animate_intro: bool = true
) -> void:
	_ids = ids.duplicate()
	_levels = levels.duplicate()
	_locked_flags = locked_flags.duplicate()
	_new_flags = new_flags.duplicate()
	_skill_target_global = skill_target_global
	while _locked_flags.size() < _ids.size():
		_locked_flags.append(_locked_flags.size() >= GameConfig.ENERGY_IMPRINT_FREE_SLOT_COUNT)
	while _new_flags.size() < _ids.size():
		_new_flags.append(false)
	_build_slots()
	_selected_index = -1
	_refresh_selection_state(false)
	get_tree().paused = true
	if animate_intro:
		call_deferred("_play_intro")
	else:
		_finish_intro_immediately()


func _finish_intro_immediately() -> void:
	_mask.color = MASK_COLOR
	_content_root.modulate = Color.WHITE
	for entry in _slot_views:
		var slot := entry["root"] as Control
		slot.modulate = Color.WHITE
		slot.position = entry["base_position"]
		slot.scale = Vector2.ONE
	_input_locked = false
	_refresh_selection_state(false)


func _build_static_interface() -> void:
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

	var title_group := Control.new()
	title_group.name = "TitleGroup"
	title_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(title_group, TITLE_RECT.position, TITLE_RECT.size)
	_content_root.add_child(title_group)
	_build_title_ornament(title_group, true)
	_build_title_ornament(title_group, false)

	var title := _label("道具选择", 54, Color.WHITE, 7, 900)
	title.name = "Title"
	title.add_theme_color_override("font_shadow_color", Color(0.25, 0.70, 1.0, 0.85))
	title.add_theme_constant_override("shadow_offset_x", 0)
	title.add_theme_constant_override("shadow_offset_y", 0)
	title.add_theme_constant_override("shadow_outline_size", 9)
	_set_rect(title, Vector2(178.0, 0.0), Vector2(250.0, TITLE_RECT.size.y))
	title_group.add_child(title)

	_slots_root = Control.new()
	_slots_root.name = "SlotsRoot"
	_slots_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_rect(_slots_root, Vector2.ZERO, DESIGN_SIZE)
	_content_root.add_child(_slots_root)

	_hint_label = _label("请选择技能印记", 31, Color.WHITE, 5)
	_hint_label.name = "SelectionHint"
	_set_rect(_hint_label, HINT_RECT.position, HINT_RECT.size)
	_hint_label.visible = false
	_content_root.add_child(_hint_label)

	_confirm_button = TextureButton.new()
	_confirm_button.name = "ConfirmButton"
	_confirm_button.texture_normal = CONFIRM_TEXTURE
	_confirm_button.ignore_texture_size = true
	_confirm_button.stretch_mode = TextureButton.STRETCH_SCALE
	_confirm_button.focus_mode = Control.FOCUS_NONE
	_confirm_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_set_rect(_confirm_button, CONFIRM_RECT.position, CONFIRM_RECT.size)
	_confirm_button.pressed.connect(_confirm_selection)
	_confirm_button.button_down.connect(_on_confirm_button_down)
	_confirm_button.button_up.connect(_on_confirm_button_up)
	_content_root.add_child(_confirm_button)

	var confirm_label := _label("确定", 52, Color.WHITE, 7, 900)
	confirm_label.name = "Label"
	_set_rect(confirm_label, Vector2.ZERO, CONFIRM_RECT.size)
	_confirm_button.add_child(confirm_label)
	_set_confirm_enabled(false)


func _build_slots() -> void:
	for child in _slots_root.get_children():
		child.queue_free()
	_slot_views.clear()
	var count := mini(_ids.size(), GameConfig.ENERGY_IMPRINT_OFFER_COUNT)
	var group_width := float(count) * CARD_SIZE.x + float(maxi(0, count - 1)) * CARD_GAP
	var group_left := (DESIGN_SIZE.x - group_width) * 0.5
	for index in range(count):
		var card_id := _ids[index]
		var locked := bool(_locked_flags[index])
		var root := Control.new()
		root.name = "ImprintCard_%d_%s" % [index + 1, card_id]
		root.position = Vector2(group_left + float(index) * (CARD_SIZE.x + CARD_GAP), CARD_Y)
		root.size = CARD_SIZE
		root.pivot_offset = CARD_SIZE * 0.5
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_slots_root.add_child(root)

		var selection := Panel.new()
		selection.name = "SelectionOutline"
		selection.visible = false
		selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var selection_style := StyleBoxFlat.new()
		selection_style.bg_color = Color(0.08, 0.72, 1.0, 0.10)
		selection_style.border_color = Color(0.28, 0.90, 1.0, 1.0)
		selection_style.set_border_width_all(6)
		selection_style.set_corner_radius_all(34)
		selection_style.shadow_color = Color(0.16, 0.82, 1.0, 0.65)
		selection_style.shadow_size = 14
		selection.add_theme_stylebox_override("panel", selection_style)
		_set_rect(selection, Vector2(-7.0, -7.0), CARD_SIZE + Vector2(14.0, 14.0))
		root.add_child(selection)

		var card := NinePatchRect.new()
		card.name = "CardFrame"
		card.texture = CARD_TEXTURE
		card.patch_margin_left = 36
		card.patch_margin_right = 36
		card.patch_margin_top = 36
		card.patch_margin_bottom = 36
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.material = _make_card_artifact_cleanup_material()
		_set_rect(card, Vector2.ZERO, CARD_SIZE)
		root.add_child(card)

		var name_label := _label(_imprint_name(card_id), 30, Color.WHITE, 5, 850)
		name_label.name = "Name"
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		_set_rect(name_label, Vector2(20.0, 14.0), Vector2(242.0, 76.0))
		root.add_child(name_label)

		var icon_clip := Control.new()
		icon_clip.name = "IconClip"
		icon_clip.clip_contents = true
		icon_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_set_rect(icon_clip, ICON_SAFE_RECT.position, ICON_SAFE_RECT.size)
		root.add_child(icon_clip)

		var icon := _texture_rect(_icon_texture(card_id))
		icon.name = "Icon"
		_set_rect(icon, Vector2.ZERO, ICON_SAFE_RECT.size)
		icon_clip.add_child(icon)

		var description_text := _imprint_description(card_id, _level_for_index(index))
		var description := _label(description_text, _description_font_size(description_text), Color(0.035, 0.045, 0.065, 1.0), 0, 700)
		description.name = "Description"
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		description.clip_text = true
		description.add_theme_constant_override("line_spacing", DESCRIPTION_LINE_SPACING)
		_set_rect(description, DESCRIPTION_RECT.position, DESCRIPTION_RECT.size)
		root.add_child(description)

		var new_badge := _texture_rect(NEW_BADGE_TEXTURE)
		new_badge.name = "NewBadge"
		new_badge.visible = bool(_new_flags[index])
		_set_rect(new_badge, Vector2(216.0, -18.0), Vector2(76.0, 72.0))
		root.add_child(new_badge)
		var new_label := _label("新", 34, Color.WHITE, 5)
		new_label.name = "Label"
		_set_rect(new_label, Vector2.ZERO, new_badge.size)
		new_badge.add_child(new_label)

		var button := Button.new()
		button.name = "CardButton"
		button.flat = true
		button.text = ""
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		_set_rect(button, Vector2.ZERO, CARD_SIZE)
		button.pressed.connect(_on_slot_pressed.bind(index))
		button.button_down.connect(_on_slot_button_down.bind(index))
		button.button_up.connect(_on_slot_button_up.bind(index))
		root.add_child(button)

		var ad_button: TextureButton = null
		if locked:
			ad_button = TextureButton.new()
			ad_button.name = "AdUnlockButton"
			ad_button.texture_normal = AD_TEXTURE
			ad_button.ignore_texture_size = true
			ad_button.stretch_mode = TextureButton.STRETCH_SCALE
			ad_button.focus_mode = Control.FOCUS_NONE
			ad_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			# The reward preview stays clean; the ad is a separate action below it.
			_set_rect(ad_button, Vector2(20.0, CARD_SIZE.y + 16.0), Vector2(220.0, 64.0))
			ad_button.pressed.connect(_on_locked_ad_pressed.bind(index))
			root.add_child(ad_button)
			var ad_label := _label("▶  看广告解锁", 22, Color.WHITE, 4)
			ad_label.name = "Label"
			_set_rect(ad_label, Vector2.ZERO, ad_button.size)
			ad_button.add_child(ad_label)

		_slot_views.append({
			"root": root,
			"icon": icon,
			"button": button,
			"ad_button": ad_button,
			"selection": selection,
			"base_position": root.position,
		})


func _build_title_ornament(parent: Control, left_side: bool) -> void:
	var ornament := _texture_rect(TITLE_ORNAMENT_TEXTURE)
	ornament.name = "LeftOrnament" if left_side else "RightOrnament"
	ornament.flip_h = left_side
	_set_rect(ornament, Vector2(70.0 if left_side else 438.0, 30.0), Vector2(108.0, 45.0))
	parent.add_child(ornament)


func _play_intro() -> void:
	_input_locked = true
	_set_confirm_enabled(false)
	_mask.color = Color(0.0, 0.0, 0.0, 0.0)
	_content_root.modulate.a = 0.0
	for index in range(_slot_views.size()):
		var slot := _slot_views[index]["root"] as Control
		var base_position: Vector2 = _slot_views[index]["base_position"]
		slot.modulate.a = 0.0
		slot.position = base_position + Vector2(0.0, 38.0)
		slot.scale = Vector2(0.88, 0.88)

	var base_intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	base_intro.tween_property(_mask, "color", MASK_COLOR, 0.18)
	base_intro.parallel().tween_property(_content_root, "modulate:a", 1.0, 0.22)
	for index in range(_slot_views.size()):
		var slot := _slot_views[index]["root"] as Control
		var base_position: Vector2 = _slot_views[index]["base_position"]
		var card_intro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_intro.tween_interval(0.05 + float(index) * 0.065)
		card_intro.tween_property(slot, "modulate:a", 1.0, 0.20)
		card_intro.parallel().tween_property(slot, "position", base_position, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		card_intro.parallel().tween_property(slot, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.48, true).timeout
	if not is_inside_tree():
		return
	_input_locked = false
	_set_confirm_enabled(false)


func _on_slot_pressed(index: int) -> void:
	if _input_locked or index < 0 or index >= _slot_views.size():
		return
	_selected_index = index
	_notice_generation += 1
	_refresh_selection_state(true)


func _on_locked_ad_pressed(index: int) -> void:
	# Reserved visual placement only. Rewarded-ad behavior is intentionally not
	# connected in this version, and it must not gate normal card selection.
	return


func _show_locked_notice(index: int) -> void:
	locked_slot_pressed.emit(_ids[index])
	_notice_generation += 1
	var generation := _notice_generation
	_hint_label.text = "广告功能暂未开放"
	_hint_label.modulate = Color(1.0, 0.80, 0.25, 1.0)
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_hint_label, "scale", Vector2(1.06, 1.06), 0.10)
	tween.tween_property(_hint_label, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(1.15, true).timeout
	if generation == _notice_generation and is_inside_tree():
		_refresh_selection_state(false)


func _refresh_selection_state(animated: bool) -> void:
	for index in range(_slot_views.size()):
		var selected := index == _selected_index
		var root := _slot_views[index]["root"] as Control
		var selection := _slot_views[index]["selection"] as Panel
		selection.visible = selected
		root.z_index = 4 if selected else 0
		var target_scale := Vector2(1.025, 1.025) if selected else Vector2.ONE
		if animated:
			var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			tween.tween_property(root, "scale", target_scale, 0.13).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		else:
			root.scale = target_scale
	if _selected_index < 0:
		_hint_label.text = "请选择技能印记"
		_hint_label.modulate = Color.WHITE
		_set_confirm_enabled(false)
	else:
		_hint_label.text = "已选择：%s" % _imprint_name(_ids[_selected_index])
		_hint_label.modulate = Color.WHITE
		_set_confirm_enabled(not _input_locked)


func _on_slot_button_down(index: int) -> void:
	if _input_locked or index < 0 or index >= _slot_views.size():
		return
	var root := _slot_views[index]["root"] as Control
	var base_scale := 1.025 if index == _selected_index else 1.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "scale", Vector2.ONE * base_scale * 0.97, 0.07)


func _on_slot_button_up(index: int) -> void:
	if _input_locked or index < 0 or index >= _slot_views.size():
		return
	var root := _slot_views[index]["root"] as Control
	var base_scale := 1.025 if index == _selected_index else 1.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(root, "scale", Vector2.ONE * base_scale, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_confirm_button_down() -> void:
	if _confirm_button.disabled:
		return
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_confirm_button, "scale", Vector2(0.96, 0.96), 0.07)


func _on_confirm_button_up() -> void:
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_confirm_button, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _set_confirm_enabled(enabled: bool) -> void:
	_confirm_button.disabled = not enabled
	_confirm_button.modulate = Color.WHITE if enabled else Color(0.48, 0.52, 0.60, 0.92)


func _confirm_selection() -> void:
	if _input_locked or _selected_index < 0 or _selected_index >= _slot_views.size():
		return
	_input_locked = true
	_set_confirm_enabled(false)
	for view in _slot_views:
		(view["button"] as BaseButton).disabled = true
		var ad_button := view["ad_button"] as TextureButton
		if ad_button:
			ad_button.disabled = true

	var chosen_id := _ids[_selected_index]
	var chosen_level := _level_for_index(_selected_index)
	var chosen_icon := _slot_views[_selected_index]["icon"] as TextureRect
	var fly_icon := _texture_rect(chosen_icon.texture)
	fly_icon.name = "ChosenImprintFlyIcon"
	fly_icon.z_index = 100
	fly_icon.size = chosen_icon.size
	fly_icon.pivot_offset = fly_icon.size * 0.5
	add_child(fly_icon)
	_commit_flight_start_global = chosen_icon.get_global_transform_with_canvas() * (chosen_icon.size * 0.5)
	chosen_icon.modulate.a = 0.0

	_commit_flight_target_global = _skill_target_global
	if _commit_flight_target_global == Vector2.ZERO:
		_commit_flight_target_global = Vector2(170.0, 1510.0)
	_commit_flight_control_global = _make_commit_curve_control(_commit_flight_start_global, _commit_flight_target_global)
	_set_commit_flight_progress(0.0, fly_icon)
	var fly := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fly.tween_property(_content_root, "modulate:a", 0.10, 0.18)
	fly.parallel().tween_method(_set_commit_flight_progress.bind(fly_icon), 0.0, 1.0, COMMIT_FLY_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await fly.finished
	if not is_inside_tree():
		return
	fly_icon.visible = false
	choice_committed.emit("energy", chosen_id, "", chosen_level)
	fly_icon.queue_free()

	var outro := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	outro.tween_property(_mask, "color:a", 0.0, 0.18)
	await outro.finished
	get_tree().paused = false
	modal_closed.emit("energy")
	queue_free()


func _make_commit_curve_control(start_global: Vector2, target_global: Vector2) -> Vector2:
	var delta := target_global - start_global
	var control := start_global.lerp(target_global, 0.46)
	control.x += clampf(absf(delta.y) * 0.14, 85.0, 175.0)
	control.y = start_global.y + delta.y * 0.38
	control.x = clampf(control.x, 70.0, maxf(70.0, get_viewport_rect().size.x - 70.0))
	return control


func _quadratic_bezier(start: Vector2, control: Vector2, target: Vector2, progress: float) -> Vector2:
	var t := clampf(progress, 0.0, 1.0)
	var inverse := 1.0 - t
	return start * inverse * inverse + control * 2.0 * inverse * t + target * t * t


func _set_commit_flight_progress(progress: float, fly_icon: TextureRect) -> void:
	if fly_icon == null or not is_instance_valid(fly_icon):
		return
	var t := clampf(progress, 0.0, 1.0)
	var center_global := _quadratic_bezier(_commit_flight_start_global, _commit_flight_control_global, _commit_flight_target_global, t)
	var center_local := get_global_transform_with_canvas().affine_inverse() * center_global
	fly_icon.position = center_local - fly_icon.size * 0.5
	fly_icon.scale = Vector2.ONE * lerpf(1.0, COMMIT_ARRIVAL_SCALE, smoothstep(0.0, 1.0, t))


func _level_for_index(index: int) -> int:
	return clampi(int(_levels[index] if index < _levels.size() else 1), 1, GameConfig.MAX_CARD_LEVEL)


func _imprint_name(card_id: String) -> String:
	return str(CardCatalog.get_definition(card_id).get("item_name", SkillImprintSystem.IMPRINT_NAMES.get(card_id, card_id)))


func _imprint_description(card_id: String, level: int) -> String:
	match card_id:
		"ascension_hammer":
			return "下一次合成结果\n提升%d级" % int(GameConfig.ASCENSION_EXTRA_LEVELS[level - 1])
		"unity_dial":
			return "将其余非最高级方块\n统一为本次合成前数字"
		"fate_shuffler":
			return "重新排列棋盘，并保证\n至少一组可合成方块"
		"twin_mold":
			return "使%d个相邻方块变为\n本次合成结果数字" % int(GameConfig.TWIN_MOLD_TARGETS[level - 1])
		"castle_cannon":
			return "对最前方怪物造成\n%d%%基础攻击伤害" % roundi(float(GameConfig.CASTLE_CANNON_DAMAGE[level - 1]) * 100.0)
		"dragon_catapult":
			return "攻击前方%d只怪物\n造成%d%%伤害\n并附加燃烧" % [
				int(GameConfig.DRAGON_CATAPULT_TARGETS[level - 1]),
				roundi(float(GameConfig.DRAGON_CATAPULT_DAMAGE[level - 1]) * 100.0),
			]
	return str(CardCatalog.get_definition(card_id).get("description", ""))


func _description_font_size(value: String) -> int:
	# The narrow three-card layout needs predictable two/three-line copy. Size
	# against the longest explicit line as well as total copy length so numbers
	# and punctuation cannot push a glyph into the frame.
	var compact := value.replace("\n", "")
	var longest_line := 0
	for line in value.split("\n"):
		longest_line = maxi(longest_line, str(line).length())
	if value.count("\n") >= 2 or compact.length() >= 25 or longest_line >= 12:
		return DESCRIPTION_MIN_FONT_SIZE
	if compact.length() >= 18 or longest_line >= 10:
		return 19
	return DESCRIPTION_MAX_FONT_SIZE


func _make_card_artifact_cleanup_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = CARD_ARTIFACT_CLEANUP_SHADER_SOURCE
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _icon_texture(card_id: String) -> Texture2D:
	var definition := CardCatalog.get_definition(card_id)
	var path := str(definition.get("icon", GameConfig.SKILL_IMPRINT_TEXTURES.get(card_id, "")))
	return load(path) as Texture2D if not path.is_empty() else null


func _texture_rect(texture: Texture2D) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _label(value: String, font_size: int, color: Color, outline_size: int, font_weight: int = 800) -> Label:
	var node := Label.new()
	node.text = value
	node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.09, 1.0))
	node.add_theme_constant_override("outline_size", outline_size)
	UiTypographyScript.apply(node, font_weight)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


func _set_rect(node: Control, position: Vector2, node_size: Vector2) -> void:
	node.position = position
	node.size = node_size
	node.pivot_offset = node_size * 0.5
