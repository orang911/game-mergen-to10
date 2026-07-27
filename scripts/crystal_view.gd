@tool
extends Control
class_name CrystalView

const ATTACK_INTERVAL := CrystalSystem.ATTACK_INTERVAL
const PANEL_DISPLAY_SCALE := Vector2(0.5, 0.5)
const FIXED_TOWER_SIZE_START_LEVEL := 6
const FIXED_TOWER_VISUAL_HEIGHT := 220.0
const HIGH_LEVEL_UPGRADE_PULSE := 1.06
const HIGH_LEVEL_REWARD_PULSE := 1.08
const DORMANT_TEXTURE := preload("res://assets/runtime/ui/battle/core/crystal_dormant.png")

const TOWER_VISUALS := {
	1: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_01.png"), "scale": 0.75},
	2: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_02.png"), "scale": 0.80},
	3: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_03.png"), "scale": 0.80},
	4: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_04.png"), "scale": 0.90},
	5: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_05.png"), "scale": 0.86},
	6: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_06.png"), "scale": 1.00},
	7: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_07.png"), "scale": 1.00},
	8: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_08.png"), "scale": 1.00},
	9: {"texture": preload("res://assets/runtime/ui/battle/core/crystal_level_09.png"), "scale": 1.00},
}

@onready var _tower := get_node_or_null("Tower") as TextureRect
@onready var _atk_panel := get_node_or_null("AtkPanel") as TextureRect
@onready var _lv_label := get_node_or_null("AtkPanel/AtkLabelLv") as Label
@onready var _atk_label := get_node_or_null("AtkPanel/AtkLabelVal") as Label
@onready var _spd_label := get_node_or_null("AtkPanel/AtkLabelSpd") as Label
@onready var _shield := get_node_or_null("ShieldBadge") as TextureRect
@onready var _shield_label := get_node_or_null("ShieldLabel") as Label
@onready var _durability_label := get_node_or_null("DurabilityLabel") as Label
@onready var _durability_back := get_node_or_null("DurabilityBack") as ColorRect
@onready var _durability_fill := get_node_or_null("DurabilityBack/DurabilityFill") as ColorRect

var _crystal_level := 1
var _panel_visible := false
var _upgrade_tween: Tween
var _attack_tween: Tween
var _panel_tween: Tween
var _damage_tween: Tween
var _durability_current := GameConfig.MAX_CASTLE_DURABILITY
var _durability_max := GameConfig.MAX_CASTLE_DURABILITY
var _awakened := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_children_ignore()
	_update_display()
	update_durability(_durability_current, _durability_max)
	_hide_panel_immediate()


func _set_children_ignore() -> void:
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_crystal_level(level: int) -> void:
	if level <= _crystal_level:
		return
	var old_level := _crystal_level
	_crystal_level = level
	_update_display()
	_play_upgrade_animation(old_level)


func get_crystal_level() -> int:
	return _crystal_level


func set_awakened(awakened: bool, animate: bool = false) -> void:
	var was_awakened := _awakened
	_awakened = awakened
	if not _awakened:
		_hide_panel_immediate()
	_update_display()
	if animate and not was_awakened and _awakened:
		_play_awakening_animation()


func is_awakened() -> bool:
	return _awakened


func get_attack_origin_global() -> Vector2:
	if _tower and is_instance_valid(_tower):
		return _tower.get_global_transform_with_canvas() * Vector2(_tower.size.x * 0.5, _tower.size.y * 0.5)
	return get_global_transform_with_canvas() * (size * 0.5)


func update_durability(current: int, max_value: int) -> void:
	_durability_current = maxi(0, current)
	_durability_max = maxi(1, max_value)
	var ratio := clampf(float(_durability_current) / float(_durability_max), 0.0, 1.0)
	if _durability_label:
		_durability_label.text = "%d/%d" % [_durability_current, _durability_max]
		var label_color := Color(0.08, 0.27, 0.65, 1.0) if ratio > 0.5 else (Color(0.95, 0.56, 0.1, 1.0) if ratio > 0.25 else Color(0.9, 0.15, 0.15, 1.0))
		_durability_label.add_theme_color_override("font_color", label_color)
	if _durability_back:
		_durability_back.position = Vector2(46.0, 226.0)
		_durability_back.size = Vector2(88.0, 7.0)
	if _durability_fill:
		_durability_fill.position = Vector2(2.0, 2.0)
		_durability_fill.size = Vector2(84.0 * ratio, 3.0)
		_durability_fill.color = Color(0.28, 0.76, 0.38, 1.0) if ratio > 0.5 else (Color(0.96, 0.68, 0.18, 1.0) if ratio > 0.25 else Color(0.92, 0.18, 0.18, 1.0))


func play_damage(_amount: int) -> void:
	if not is_inside_tree() or _tower == null:
		return
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	var base_position := _tower.position
	_tower.modulate = Color(1.65, 0.30, 0.30, 1.0)
	_damage_tween = create_tween()
	_damage_tween.tween_property(_tower, "position", base_position + Vector2(5.0, 0.0), 0.035)
	_damage_tween.tween_property(_tower, "position", base_position + Vector2(-5.0, 0.0), 0.055)
	_damage_tween.tween_property(_tower, "position", base_position, 0.055)
	_damage_tween.parallel().tween_property(_tower, "modulate", Color.WHITE, 0.14)
	_damage_tween.tween_callback(_update_display)


func reset() -> void:
	_kill_all_tweens()
	_crystal_level = 1
	_awakened = true
	_hide_panel_immediate()
	if _tower:
		_tower.modulate = Color.WHITE
	_update_display()
	update_durability(_durability_current, _durability_max)


func hide_attack_tip() -> void:
	_hide_panel()


func _kill_all_tweens() -> void:
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	_upgrade_tween = null
	_attack_tween = null
	_panel_tween = null
	_damage_tween = null


func _hide_panel_immediate() -> void:
	_panel_visible = false
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = null
	if _atk_panel:
		_atk_panel.scale = Vector2.ZERO
		_atk_panel.visible = false
	if _lv_label:
		_lv_label.visible = false
	if _atk_label:
		_atk_label.visible = false
	if _spd_label:
		_spd_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree() or not _awakened:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not is_instance_valid(_tower):
		return
	var tower_local := _tower.get_global_transform_with_canvas().affine_inverse() * mb.position
	if not Rect2(Vector2.ZERO, _tower.size).has_point(tower_local):
		return

	if _panel_visible:
		_hide_panel()
	else:
		_show_panel()
	get_viewport().set_input_as_handled()


func _show_panel() -> void:
	if _panel_visible:
		return
	_panel_visible = true
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()

	if _atk_panel:
		_atk_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atk_panel.visible = true
		_atk_panel.scale = Vector2.ZERO
		_layout_attack_panel()
		_panel_tween = create_tween()
		_panel_tween.tween_property(_atk_panel, "scale", PANEL_DISPLAY_SCALE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _lv_label:
		_lv_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lv_label.visible = true
	if _atk_label:
		_atk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atk_label.visible = true
	if _spd_label:
		_spd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_spd_label.visible = true


func _hide_panel() -> void:
	if not _panel_visible:
		return
	_panel_visible = false
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()

	if _atk_panel:
		_panel_tween = create_tween()
		_panel_tween.tween_property(_atk_panel, "scale", Vector2.ZERO, 0.12)
		_panel_tween.tween_callback(func():
			if is_instance_valid(_atk_panel):
				_atk_panel.visible = false
		)

	if _lv_label:
		_lv_label.visible = false
	if _atk_label:
		_atk_label.visible = false
	if _spd_label:
		_spd_label.visible = false


func _update_display() -> void:
	var label_str := GameConfig.get_level_label(_crystal_level)
	var atk := GameConfig.get_base_attack(_crystal_level)
	var spd := 1.0 / ATTACK_INTERVAL

	if _lv_label:
		_lv_label.text = "Lv " + label_str
	if _atk_label:
		_atk_label.text = "⚔ ATK: " + str(atk)
	if _spd_label:
		_spd_label.text = "◷ SPD: %.2f/s" % spd
	if _shield_label:
		_shield_label.text = label_str

	if _tower:
		var display_level := clampi(_crystal_level, 1, GameConfig.CRYSTAL_MAX_LEVEL)
		var data: Dictionary = TOWER_VISUALS[display_level]
		var tex: Texture2D = DORMANT_TEXTURE if not _awakened else data["texture"]
		if tex:
			_tower.texture = tex
			var tex_sz: Vector2 = tex.get_size()
			var panel_sz := size
			_tower.position = Vector2((panel_sz.x - tex_sz.x) / 2.0, panel_sz.y - tex_sz.y)
			_tower.pivot_offset = Vector2(tex_sz.x / 2.0, tex_sz.y)
			_tower.size = tex_sz
			var display_scale := 0.75 if not _awakened else float(data["scale"])
			if _crystal_level >= FIXED_TOWER_SIZE_START_LEVEL:
				display_scale = FIXED_TOWER_VISUAL_HEIGHT / tex_sz.y
			_tower.scale = Vector2.ONE * display_scale
			_tower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_tower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Position AtkPanel so its pivot_offset aligns with the Tower's visual right-center
	_layout_attack_panel()


func _play_awakening_animation() -> void:
	if _tower == null:
		return
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()
	var base_scale := _tower.scale
	_tower.modulate = Color(0.55, 1.2, 1.55, 1.0)
	_upgrade_tween = create_tween()
	_upgrade_tween.parallel().tween_property(_tower, "scale", base_scale * 1.22, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_tween.parallel().tween_property(_tower, "modulate", Color(1.35, 1.55, 1.8, 1.0), 0.16)
	_upgrade_tween.tween_property(_tower, "scale", base_scale, 0.24).set_trans(Tween.TRANS_SINE)
	_upgrade_tween.parallel().tween_property(_tower, "modulate", Color.WHITE, 0.24)
	_spawn_awakening_fx()
	play_reward_absorb()


func _spawn_awakening_fx() -> void:
	if _tower == null:
		return
	var tower_center := _tower.position + _tower.size * 0.5
	var column := Panel.new()
	column.name = "AwakeningLightColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column_style := StyleBoxFlat.new()
	column_style.bg_color = Color(0.30, 0.92, 1.0, 0.28)
	column_style.border_color = Color(0.72, 1.0, 1.0, 0.42)
	column_style.set_border_width_all(2)
	column_style.set_corner_radius_all(36)
	column.add_theme_stylebox_override("panel", column_style)
	column.position = Vector2(tower_center.x - 42.0, -92.0)
	column.size = Vector2(84.0, tower_center.y + 130.0)
	column.pivot_offset = Vector2(column.size.x * 0.5, column.size.y)
	column.scale = Vector2(0.20, 0.15)
	add_child(column)
	move_child(column, _tower.get_index())

	var ring := Panel.new()
	ring.name = "AwakeningEnergyRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.18, 0.78, 1.0, 0.05)
	ring_style.border_color = Color(0.45, 0.96, 1.0, 0.90)
	ring_style.set_border_width_all(5)
	ring_style.set_corner_radius_all(62)
	ring_style.shadow_color = Color(0.16, 0.82, 1.0, 0.65)
	ring_style.shadow_size = 12
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.position = Vector2(tower_center.x - 65.0, _tower.position.y + _tower.size.y - 66.0)
	ring.size = Vector2(130.0, 54.0)
	ring.pivot_offset = ring.size * 0.5
	ring.scale = Vector2(0.18, 0.18)
	add_child(ring)
	move_child(ring, _tower.get_index())

	var column_tween := create_tween()
	column_tween.parallel().tween_property(column, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	column_tween.parallel().tween_property(column, "modulate:a", 0.82, 0.12)
	column_tween.tween_interval(0.18)
	column_tween.tween_property(column, "modulate:a", 0.0, 0.28)
	column_tween.tween_callback(column.queue_free)
	var ring_tween := create_tween()
	ring_tween.parallel().tween_property(ring, "scale", Vector2(1.45, 1.45), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.42)
	ring_tween.tween_callback(ring.queue_free)


func _layout_attack_panel() -> void:
	if not (_atk_panel and _tower):
		return
	var target_canvas := _tower.get_global_transform_with_canvas() * Vector2(_tower.size.x, _tower.size.y * 0.5)
	var target_local := get_global_transform_with_canvas().affine_inverse() * target_canvas
	_atk_panel.position = target_local - _atk_panel.pivot_offset


func _play_upgrade_animation(_old_level: int) -> void:
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()

	if _tower:
		var base := _tower.scale
		var pulse_multiplier := HIGH_LEVEL_UPGRADE_PULSE if _crystal_level >= FIXED_TOWER_SIZE_START_LEVEL else 1.12
		_upgrade_tween = create_tween()
		_upgrade_tween.tween_property(_tower, "scale", base * pulse_multiplier, 0.12)
		_upgrade_tween.tween_property(_tower, "scale", base, 0.18)

	if _shield:
		var base := _shield.scale
		var s := create_tween()
		s.tween_property(_shield, "scale", base * 1.15, 0.10)
		s.tween_property(_shield, "scale", base, 0.15)



func play_attack_flash() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	if _tower:
		_tower.modulate = Color.WHITE
		var base := _tower.modulate
		_attack_tween = create_tween()
		_attack_tween.tween_property(_tower, "modulate", Color(1.4, 1.4, 1.8, 1.0), 0.08)
		_attack_tween.tween_property(_tower, "modulate", base, 0.12)


func play_reward_absorb() -> void:
	play_attack_flash()
	if _tower:
		var tower_base := _tower.scale
		var pulse_multiplier := HIGH_LEVEL_REWARD_PULSE if _crystal_level >= FIXED_TOWER_SIZE_START_LEVEL else 1.16
		var tower_pulse := create_tween()
		tower_pulse.tween_property(_tower, "scale", tower_base * pulse_multiplier, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tower_pulse.tween_property(_tower, "scale", tower_base, 0.20).set_trans(Tween.TRANS_SINE)
	if _shield:
		var shield_base := _shield.scale
		_shield.modulate = Color(0.55, 0.9, 1.35, 0.95)
		var ring := create_tween()
		ring.parallel().tween_property(_shield, "scale", shield_base * 1.32, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring.parallel().tween_property(_shield, "modulate:a", 0.18, 0.18)
		ring.tween_property(_shield, "scale", shield_base, 0.12)
		ring.parallel().tween_property(_shield, "modulate", Color.WHITE, 0.12)
