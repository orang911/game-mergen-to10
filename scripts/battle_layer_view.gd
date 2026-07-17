@tool
extends Control
class_name BattleLayerView

signal back_pressed

const DESIGN_SIZE := Vector2(941, 1672)

@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _board_guide := get_node_or_null("DesignRoot/BoardGuide") as Control
@onready var _decor_layer := get_node_or_null("DesignRoot/DecorLayer") as Control
@onready var _path_view := get_node_or_null("MonsterPathView") as Control
@onready var _monster_layer := get_node_or_null("MonsterLayer") as Control
@onready var _projectile_layer := get_node_or_null("ProjectileLayer") as Control
@onready var _effect_layer := get_node_or_null("EffectLayer") as Control
@onready var _hud_layer := get_node_or_null("DesignRoot/HudLayer") as Control
@onready var _wave_label := get_node_or_null("DesignRoot/HudLayer/WaveLabel") as Label
@onready var _wave_banner := get_node_or_null("DesignRoot/HudLayer/WaveBanner") as Control
@onready var _tip_panel := get_node_or_null("DesignRoot/HudLayer/TipPanel") as Control
@onready var _tip_icon := get_node_or_null("DesignRoot/HudLayer/TipIcon") as Control
@onready var _tip_label := get_node_or_null("DesignRoot/HudLayer/TipLabel") as Label
@onready var _castle_status_label := get_node_or_null("DesignRoot/HudLayer/CastleStatusPanel/CastleStatusLabel") as Label
@onready var _crystal_panel := get_node_or_null("DesignRoot/CrystalPanel") as Control
@onready var _back_button := get_node_or_null("DesignRoot/HudLayer/BackButton") as TextureButton
@onready var _gate_view := get_node_or_null("DesignRoot/DecorLayer/Gate") as Control
@onready var _castle_view := get_node_or_null("DesignRoot/DecorLayer/Castle") as Control

var _castle_anchor_position := Vector2.ZERO

@export var use_manual_layout := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_mode = 0
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	if _tip_label:
		_tip_label.text = "合成相同数字升级，阻止敌人抵达城堡！"
	if _board_guide:
		_board_guide.visible = Engine.is_editor_hint()
	if _design_root:
		_design_root.layout_mode = 0
		_design_root.position = Vector2.ZERO
		_design_root.size = DESIGN_SIZE
	_apply_runtime_layer_order()
	if _back_button:
		_back_button.pressed.connect(func(): back_pressed.emit())
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


func get_castle_anchor_position() -> Vector2:
	return _castle_anchor_position


func set_wave_text(text_value: String) -> void:
	if _wave_label == null:
		_wave_label = get_node_or_null("DesignRoot/HudLayer/WaveLabel") as Label
	if _wave_label:
		_wave_label.text = text_value.replace("Wave ", "第 ") + (" 波" if text_value.begins_with("Wave ") else "")


func set_castle_status(current: int, max_value: int) -> void:
	if _castle_status_label == null:
		_castle_status_label = get_node_or_null("DesignRoot/HudLayer/CastleStatusPanel/CastleStatusLabel") as Label
	if _castle_status_label:
		_castle_status_label.text = "%d/%d" % [current, max_value]


func layout_for_board(board_pos: Vector2, board_size: Vector2, path_margin: float, spawn_pos: Vector2, goal_pos: Vector2, visual_board_pos: Vector2) -> void:
	var viewport_size := _viewport_size()
	_apply_runtime_layer_order()

	# BattleLayer root fills viewport at runtime
	_set_rect(self, Vector2.ZERO, viewport_size)

	# DesignRoot stays at fixed DESIGN_SIZE, top-left
	if _design_root:
		_design_root.position = Vector2.ZERO
		_design_root.size = DESIGN_SIZE

	# System layers still fill the full area
	_set_full_rect(_monster_layer, viewport_size)
	_set_full_rect(_projectile_layer, viewport_size)
	_set_full_rect(_effect_layer, viewport_size)

	var path_node := get_path_view()
	if path_node:
		_set_full_rect(path_node, viewport_size)
		if path_node.has_method("layout_for_board"):
			path_node.call("layout_for_board", board_pos, board_size, path_margin)
			if path_node.has_method("set_path_params"):
				path_node.call("set_path_params", 64.0, 64.0)

	if _board_guide:
		_set_rect(_board_guide, visual_board_pos, board_size)
	if _gate_view:
		var gate_rect := GameConfig.get_path_gate_rect(board_pos, board_size)
		_gate_view.scale = Vector2.ONE
		_set_rect(_gate_view, gate_rect.position, gate_rect.size)
	_layout_crystal(visual_board_pos, board_size)
	_castle_anchor_position = goal_pos
	if _castle_view:
		_set_rect(_castle_view, Vector2(290, 445), Vector2(120, 116))


func _apply_runtime_layer_order() -> void:
	_set_canvas_z(_design_root, 0)
	_set_canvas_z(_board_guide, 1)
	_set_canvas_z(_decor_layer, 2)
	_set_canvas_z(_path_view, 5)
	_set_canvas_z(_monster_layer, 10)
	# The entrance is foreground artwork: it covers the road seam and hides
	# monsters until they actually emerge from the doorway.
	_set_canvas_z(_gate_view, 12)
	_set_canvas_z(_crystal_panel, 15)
	_set_canvas_z(_projectile_layer, 20)
	_set_canvas_z(_effect_layer, 30)
	_set_canvas_z(_hud_layer, 40)


func _set_canvas_z(node: CanvasItem, z: int) -> void:
	if node == null:
		return
	node.z_as_relative = false
	node.z_index = z


func _layout_hud(viewport_size: Vector2) -> void:
	if _wave_banner:
		_set_rect(_wave_banner, Vector2((viewport_size.x - 253.0) * 0.5, 24.0), Vector2(253, 73))
	if _wave_label:
		_set_rect(_wave_label, Vector2((viewport_size.x - 340.0) * 0.5, 97.0), Vector2(340, 84))


func _layout_decor(viewport_size: Vector2) -> void:
	if _decor_layer == null:
		return
	_set_child_rect("CloudLeft", Vector2(viewport_size.x * 0.23, 47), Vector2(165, 81))
	_set_child_rect("CloudRight", Vector2(viewport_size.x - 216, 44), Vector2(165, 78))
	_set_child_rect("RockMid", Vector2(viewport_size.x - 248, 484), Vector2(76, 52))
	_set_child_rect("RockRight", Vector2(viewport_size.x - 191, 595), Vector2(91, 65))
	_set_child_rect("TreeLeft", Vector2(-21, viewport_size.y - 216), Vector2(131, 170))
	_set_child_rect("TreeRight", Vector2(viewport_size.x - 107, viewport_size.y - 180), Vector2(112, 167))
	_set_child_rect("RockBottom", Vector2(viewport_size.x * 0.42, viewport_size.y - 102), Vector2(102, 71))


func _set_child_rect(name: String, pos: Vector2, node_size: Vector2) -> void:
	var child := _decor_layer.get_node_or_null(name) as Control
	if child:
		_set_rect(child, pos, node_size)


func _layout_crystal(visual_board_pos: Vector2, board_size: Vector2) -> void:
	if _crystal_panel == null:
		return
	var panel_size := GameConfig.CRYSTAL_PANEL_SIZE
	var center_x := visual_board_pos.x + board_size.x * 0.5
	_set_rect(_crystal_panel, Vector2(center_x - panel_size.x * 0.5, GameConfig.CRYSTAL_PANEL_TOP), panel_size)


func _configure_texture_rects(root: Node) -> void:
	for child in root.get_children():
		if child is TextureRect:
			var texture_rect := child as TextureRect
			texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_configure_texture_rects(child)
	if _wave_banner and is_instance_valid(_wave_banner):
		(_wave_banner as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE
	if _tip_panel and is_instance_valid(_tip_panel):
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
	return DESIGN_SIZE


func _show_editor_preview() -> void:
	var preview_board_size := GameConfig.get_board_size()
	var preview_visual_board_pos := GameConfig.BOARD_GRID_POS
	var road_size := GameConfig.get_path_layout_size()
	var preview_path_board_pos := Vector2(
		preview_visual_board_pos.x,
		GameConfig.PATH_ROAD_TARGET_BOTTOM_Y - preview_board_size.y * 0.5 - road_size.y * 0.5 - GameConfig.PATH_ROAD_OFFSET.y
	)
	layout_for_board(preview_path_board_pos, preview_board_size, 99.0, preview_path_board_pos + Vector2(-16, -99), preview_path_board_pos + Vector2(-125, -16), preview_visual_board_pos)
	set_wave_text("Wave 1")
