@tool
extends Control
class_name CastleView

@onready var _icon := get_node_or_null("Icon") as TextureRect
@onready var _hit_effect := get_node_or_null("HitEffect") as TextureRect
@onready var _label := get_node_or_null("DurabilityLabel") as Label
@onready var _bar_back := get_node_or_null("DurabilityBack") as ColorRect
@onready var _bar_fill := get_node_or_null("DurabilityBack/DurabilityFill") as ColorRect

var _max_value := 20
var _current_value := 20
var _base_icon_position := Vector2(7, 0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_nodes()
	if size.x <= 0.0 or size.y <= 0.0:
		size = Vector2(132, 128)
		custom_minimum_size = size
	_layout_nodes()
	update_durability(_current_value, _max_value)


func update_durability(current: int, max_value: int) -> void:
	_current_value = current
	_max_value = max(1, max_value)
	_layout_nodes()
	if _label:
		_label.text = "%d/%d" % [_current_value, _max_value]
		var ratio := float(_current_value) / float(_max_value)
		var color := Color(0.08, 0.27, 0.65, 1.0) if ratio > 0.5 else (Color(0.95, 0.56, 0.1, 1.0) if ratio > 0.25 else Color(0.9, 0.15, 0.15, 1.0))
		_label.add_theme_color_override("font_color", color)
	if _bar_fill:
		var fill_width := 84.0 * clampf(float(_current_value) / float(_max_value), 0.0, 1.0)
		_bar_fill.size.x = fill_width
		_bar_fill.color = Color(0.28, 0.76, 0.38, 1.0) if fill_width > 42.0 else (Color(0.96, 0.68, 0.18, 1.0) if fill_width > 21.0 else Color(0.92, 0.18, 0.18, 1.0))


func play_damage(_amount: int) -> void:
	if not is_inside_tree():
		return
	if _icon:
		_icon.position = _base_icon_position
		var shake := create_tween()
		shake.tween_property(_icon, "position", _base_icon_position + Vector2(5, 0), 0.035)
		shake.tween_property(_icon, "position", _base_icon_position + Vector2(-5, 0), 0.055)
		shake.tween_property(_icon, "position", _base_icon_position, 0.055)
	if _hit_effect:
		_hit_effect.visible = true
		_hit_effect.modulate = Color(1, 1, 1, 0.0)
		_hit_effect.scale = Vector2(0.55, 0.55)
		var flash := create_tween()
		flash.tween_property(_hit_effect, "modulate:a", 1.0, 0.04)
		flash.parallel().tween_property(_hit_effect, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		flash.tween_property(_hit_effect, "modulate:a", 0.0, 0.12)
		flash.tween_callback(func(): _hit_effect.visible = false)


func _configure_nodes() -> void:
	for child in get_children():
		if child is TextureRect:
			var texture_rect := child as TextureRect
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		elif child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _hit_effect:
		_hit_effect.visible = false
		_hit_effect.modulate = Color(1, 1, 1, 0)


func _layout_nodes() -> void:
	if _icon:
		_set_rect(_icon, _base_icon_position, Vector2(118, 96))
	if _hit_effect:
		_set_rect(_hit_effect, Vector2(34, 42), Vector2(64, 70))
	if _label:
		_set_rect(_label, Vector2(0, 93), Vector2(132, 25))
	if _bar_back:
		_set_rect(_bar_back, Vector2(22, 119), Vector2(88, 7))
	if _bar_fill:
		_bar_fill.position = Vector2(2, 2)
		_bar_fill.size = Vector2(84, 3)


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5
