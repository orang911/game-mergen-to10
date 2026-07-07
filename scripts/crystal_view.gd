@tool
extends Control
class_name CrystalView

@onready var _tower := get_node_or_null("Tower") as TextureRect
@onready var _atk_panel := get_node_or_null("AtkPanel") as TextureRect
@onready var _lv_label := get_node_or_null("AtkLabelLv") as Label
@onready var _atk_label := get_node_or_null("AtkLabelVal") as Label
@onready var _shield := get_node_or_null("ShieldBadge") as TextureRect
@onready var _shield_label := get_node_or_null("ShieldLabel") as Label

var _crystal_level := 1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_update_display()


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
	_crystal_level = 1
	_update_display()


func _update_display() -> void:
	var label_str := GameConfig.get_level_label(_crystal_level)
	var atk := GameConfig.get_base_attack(_crystal_level)

	if _lv_label:
		_lv_label.text = "Lv " + label_str
	if _atk_label:
		_atk_label.text = "ATK " + str(atk)
	if _shield_label:
		_shield_label.text = label_str


func _play_upgrade_animation(_old_level: int) -> void:
	if _tower:
		var base := _tower.scale
		var t := create_tween()
		t.tween_property(_tower, "scale", base * 1.12, 0.12)
		t.tween_property(_tower, "scale", base, 0.18)

	if _shield:
		var base := _shield.scale
		var s := create_tween()
		s.tween_property(_shield, "scale", base * 1.15, 0.10)
		s.tween_property(_shield, "scale", base, 0.15)

	if _atk_panel:
		var base := _atk_panel.scale
		var a := create_tween()
		a.tween_property(_atk_panel, "scale", base * 1.08, 0.10)
		a.tween_property(_atk_panel, "scale", base, 0.15)


func play_attack_flash() -> void:
	if _tower:
		var base := _tower.modulate
		var t := create_tween()
		t.tween_property(_tower, "modulate", Color(1.4, 1.4, 1.8, 1.0), 0.08)
		t.tween_property(_tower, "modulate", base, 0.12)
