@tool
extends Control
class_name CrystalView

const ATTACK_INTERVAL := CrystalSystem.ATTACK_INTERVAL
const PANEL_DISPLAY_SCALE := Vector2(0.5, 0.5)

const TOWER_VISUALS := {
	1: {"texture": preload("res://assets/UI/base_layers/base_009.png"), "scale": 0.75},
	3: {"texture": preload("res://assets/UI/base_layers/base_003.png"), "scale": 0.80},
	5: {"texture": preload("res://assets/UI/base_layers/base_005.png"), "scale": 1.00},
	7: {"texture": preload("res://assets/UI/base_layers/base_007.png"), "scale": 1.35},
	9: {"texture": preload("res://assets/UI/base_layers/base_001.png"), "scale": 1.40},
}

const _TIER_LOOKUP := [1, 1, 3, 3, 5, 5, 7, 7, 9]

@onready var _tower := get_node_or_null("Tower") as TextureRect
@onready var _atk_panel := get_node_or_null("AtkPanel") as TextureRect
@onready var _lv_label := get_node_or_null("AtkPanel/AtkLabelLv") as Label
@onready var _atk_label := get_node_or_null("AtkPanel/AtkLabelVal") as Label
@onready var _spd_label := get_node_or_null("AtkPanel/AtkLabelSpd") as Label
@onready var _shield := get_node_or_null("ShieldBadge") as TextureRect
@onready var _shield_label := get_node_or_null("ShieldLabel") as Label

var _crystal_level := 1
var _panel_visible := false
var _upgrade_tween: Tween
var _attack_tween: Tween
var _panel_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_children_ignore()
	_update_display()
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


func reset() -> void:
	_kill_all_tweens()
	_crystal_level = 1
	_hide_panel_immediate()
	if _tower:
		_tower.modulate = Color.WHITE
	_update_display()


func hide_attack_tip() -> void:
	_hide_panel()


func _kill_all_tweens() -> void:
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	_upgrade_tween = null
	_attack_tween = null
	_panel_tween = null


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
	if Engine.is_editor_hint() or not is_visible_in_tree():
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


func _visual_tier(level: int) -> int:
	return _TIER_LOOKUP[clampi(level, 1, 9) - 1]


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
		var tier := _visual_tier(_crystal_level)
		var data: Dictionary = TOWER_VISUALS[tier]
		var tex: Texture2D = data["texture"]
		if tex:
			_tower.texture = tex
			var tex_sz: Vector2 = tex.get_size()
			var panel_sz := size
			_tower.position = Vector2((panel_sz.x - tex_sz.x) / 2.0, panel_sz.y - tex_sz.y)
			_tower.pivot_offset = Vector2(tex_sz.x / 2.0, tex_sz.y)
			_tower.size = tex_sz
			_tower.scale = Vector2.ONE * float(data["scale"])
			_tower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_tower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Position AtkPanel so its pivot_offset aligns with the Tower's visual right-center
	_layout_attack_panel()


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
		_upgrade_tween = create_tween()
		_upgrade_tween.tween_property(_tower, "scale", base * 1.12, 0.12)
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
		var tower_pulse := create_tween()
		tower_pulse.tween_property(_tower, "scale", tower_base * 1.16, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tower_pulse.tween_property(_tower, "scale", tower_base, 0.20).set_trans(Tween.TRANS_SINE)
	if _shield:
		var shield_base := _shield.scale
		_shield.modulate = Color(0.55, 0.9, 1.35, 0.95)
		var ring := create_tween()
		ring.parallel().tween_property(_shield, "scale", shield_base * 1.32, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring.parallel().tween_property(_shield, "modulate:a", 0.18, 0.18)
		ring.tween_property(_shield, "scale", shield_base, 0.12)
		ring.parallel().tween_property(_shield, "modulate", Color.WHITE, 0.12)
