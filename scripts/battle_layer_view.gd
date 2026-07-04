@tool
extends Control
class_name BattleLayerView

@onready var _decor_layer := get_node_or_null("DecorLayer") as Control
@onready var _path_view := get_node_or_null("MonsterPathView") as Control
@onready var _route_markers := get_node_or_null("RouteMarkers") as Control
@onready var _entrance_gate := get_node_or_null("RouteMarkers/EntranceGate") as Control
@onready var _entrance_label := get_node_or_null("RouteMarkers/EntranceLabel") as Control
@onready var _endpoint_label := get_node_or_null("RouteMarkers/EndpointLabel") as Control
@onready var _castle_view := get_node_or_null("CastleView") as CastleView
@onready var _monster_layer := get_node_or_null("MonsterLayer") as Control
@onready var _projectile_layer := get_node_or_null("ProjectileLayer") as Control
@onready var _effect_layer := get_node_or_null("EffectLayer") as Control
@onready var _hud_layer := get_node_or_null("HudLayer") as Control
@onready var _wave_banner := get_node_or_null("HudLayer/WaveBanner") as Control
@onready var _wave_label := get_node_or_null("HudLayer/WaveLabel") as Label
@onready var _tip_panel := get_node_or_null("HudLayer/TipPanel") as Control
@onready var _tip_icon := get_node_or_null("HudLayer/TipIcon") as Control
@onready var _tip_label := get_node_or_null("HudLayer/TipLabel") as Label

var _castle_anchor_position := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_configure_texture_rects(self)
	if _tip_label:
		_tip_label.text = "Merge same numbers to level up\nand stop monsters from reaching the castle!"
	if Engine.is_editor_hint():
		call_deferred("_show_editor_preview")


func get_path_view() -> Control:
	if _path_view == null:
		_path_view = get_node_or_null("MonsterPathView") as Control
	return _path_view


func get_monster_layer() -> Control:
	if _monster_layer == null:
		_monster_layer = get_node_or_null("MonsterLayer") as Control
	return _monster_layer


func get_projectile_layer() -> Control:
	if _projectile_layer == null:
		_projectile_layer = get_node_or_null("ProjectileLayer") as Control
	return _projectile_layer


func get_effect_layer() -> Control:
	if _effect_layer == null:
		_effect_layer = get_node_or_null("EffectLayer") as Control
	return _effect_layer


func get_castle_view() -> CastleView:
	if _castle_view == null:
		_castle_view = get_node_or_null("CastleView") as CastleView
	return _castle_view


func get_castle_anchor_position() -> Vector2:
	return _castle_anchor_position


func set_wave_text(text_value: String) -> void:
	if _wave_label == null:
		_wave_label = get_node_or_null("HudLayer/WaveLabel") as Label
	if _wave_label:
		_wave_label.text = text_value


func layout_for_board(board_pos: Vector2, board_size: Vector2, path_margin: float, spawn_pos: Vector2, goal_pos: Vector2) -> void:
	var viewport_size := _viewport_size()
	_set_rect(self, Vector2.ZERO, viewport_size)
	_set_full_rect(_decor_layer, viewport_size)
	_set_full_rect(_route_markers, viewport_size)
	_set_full_rect(_monster_layer, viewport_size)
	_set_full_rect(_projectile_layer, viewport_size)
	_set_full_rect(_effect_layer, viewport_size)
	_set_full_rect(_hud_layer, viewport_size)

	var path_node := get_path_view()
	if path_node:
		_set_full_rect(path_node, viewport_size)
		if path_node.has_method("layout_for_board"):
			path_node.call("layout_for_board", board_pos, board_size, path_margin)
			if path_node.has_method("set_path_params"):
				path_node.call("set_path_params", 64.0, 64.0)

	_layout_decor(viewport_size)
	_layout_hud(viewport_size)
	_layout_route_markers(spawn_pos, goal_pos)


func _layout_hud(viewport_size: Vector2) -> void:
	if _wave_banner:
		_set_rect(_wave_banner, Vector2((viewport_size.x - 270.0) * 0.5, 65.0), Vector2(270, 78))
	if _wave_label:
		_set_rect(_wave_label, Vector2((viewport_size.x - 260.0) * 0.5, 74.0), Vector2(260, 64))
	if _tip_panel:
		_set_rect(_tip_panel, Vector2((viewport_size.x - 244.0) * 0.5, viewport_size.y - 150.0), Vector2(244, 52))
	if _tip_icon:
		_set_rect(_tip_icon, Vector2((viewport_size.x - 244.0) * 0.5 - 54.0, viewport_size.y - 149.0), Vector2(50, 44))
	if _tip_label:
		_set_rect(_tip_label, Vector2((viewport_size.x - 286.0) * 0.5 + 32.0, viewport_size.y - 148.0), Vector2(286, 50))


func _layout_route_markers(spawn_pos: Vector2, goal_pos: Vector2) -> void:
	if _entrance_gate:
		_set_rect(_entrance_gate, spawn_pos + Vector2(-56, -116), Vector2(112, 112))
	if _entrance_label:
		_set_rect(_entrance_label, spawn_pos + Vector2(-70, -158), Vector2(132, 42))
	if _endpoint_label:
		_set_rect(_endpoint_label, goal_pos + Vector2(-18, 22), Vector2(118, 38))

	_castle_anchor_position = goal_pos + Vector2(42, -104)
	var castle := get_castle_view()
	if castle:
		_set_rect(castle, _castle_anchor_position, Vector2(132, 128))


func _layout_decor(viewport_size: Vector2) -> void:
	if _decor_layer == null:
		return
	_set_child_rect("CloudLeft", Vector2(viewport_size.x * 0.23, 36), Vector2(126, 62))
	_set_child_rect("CloudRight", Vector2(viewport_size.x - 165, 34), Vector2(126, 60))
	_set_child_rect("RockMid", Vector2(viewport_size.x - 190, 370), Vector2(58, 40))
	_set_child_rect("RockRight", Vector2(viewport_size.x - 146, 455), Vector2(70, 50))
	_set_child_rect("TreeLeft", Vector2(-16, viewport_size.y - 165), Vector2(100, 130))
	_set_child_rect("TreeRight", Vector2(viewport_size.x - 82, viewport_size.y - 138), Vector2(86, 128))
	_set_child_rect("RockBottom", Vector2(viewport_size.x * 0.42, viewport_size.y - 78), Vector2(78, 54))


func _set_child_rect(name: String, pos: Vector2, node_size: Vector2) -> void:
	var child := _decor_layer.get_node_or_null(name) as Control
	if child:
		_set_rect(child, pos, node_size)


func _configure_texture_rects(root: Node) -> void:
	for child in root.get_children():
		if child is TextureRect:
			var texture_rect := child as TextureRect
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_configure_texture_rects(child)
	if _wave_banner:
		(_wave_banner as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	if _tip_panel:
		(_tip_panel as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE


func _set_full_rect(node: Control, node_size: Vector2) -> void:
	if node == null:
		return
	_set_rect(node, Vector2.ZERO, node_size)


func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	if node == null:
		return
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5


func _viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport:
		var visible_size := viewport.get_visible_rect().size
		if visible_size.x > 0.0 and visible_size.y > 0.0:
			return visible_size
	if size.x > 0.0 and size.y > 0.0:
		return size
	return Vector2(720, 1280)


func _show_editor_preview() -> void:
	var preview_board_size := GameConfig.get_board_size()
	var preview_board_pos := Vector2((720.0 - preview_board_size.x) * 0.5, 442.0)
	layout_for_board(preview_board_pos, preview_board_size, 76.0, preview_board_pos + Vector2(-12, -76), preview_board_pos + Vector2(-96, -12))
	set_wave_text("Wave 1")
