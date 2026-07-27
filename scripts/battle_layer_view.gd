@tool
extends Control
class_name BattleLayerView

signal back_pressed

const DESIGN_SIZE := Vector2(941, 1672)
const TOP_FILL_POS := Vector2(40.0, 112.0)
const TOP_FILL_SIZE := Vector2(837.0, 31.0)
const MONSTER_LAYER_Z := 13
const CRYSTAL_NORMAL_Z := 15
const TUTORIAL_BREAKTHROUGH_Z := 16
const TUTORIAL_CRYSTAL_FOREGROUND_Z := 17

@onready var _design_root := get_node_or_null("DesignRoot") as Control
@onready var _board_guide := get_node_or_null("DesignRoot/BoardGuide") as Control
@onready var _decor_layer := get_node_or_null("DesignRoot/DecorLayer") as Control
@onready var _path_view := get_node_or_null("MonsterPathView") as Control
@onready var _monster_layer := get_node_or_null("MonsterLayer") as Control
@onready var _projectile_layer := get_node_or_null("ProjectileLayer") as Control
@onready var _effect_layer := get_node_or_null("EffectLayer") as Control
@onready var _hud_layer := get_node_or_null("DesignRoot/HudLayer") as Control
@onready var _wave_label := get_node_or_null("DesignRoot/HudLayer/WaveLabel") as Label
@onready var _wave_count_label := get_node_or_null("DesignRoot/HudLayer/WaveCountLabel") as Label
@onready var _time_label := get_node_or_null("DesignRoot/HudLayer/TimeLabel") as Label
@onready var _wave_banner := get_node_or_null("DesignRoot/HudLayer/WaveBanner") as Control
@onready var _top_fill_clip := get_node_or_null("DesignRoot/HudLayer/TopFillClip") as Control
@onready var _top_fill := get_node_or_null("DesignRoot/HudLayer/TopFillClip/TopFill") as TextureRect
@onready var _castle_status_label := get_node_or_null("DesignRoot/HudLayer/CastleStatusPanel/CastleStatusLabel") as Label
@onready var _crystal_panel := get_node_or_null("DesignRoot/CrystalPanel") as Control
@onready var _back_button := get_node_or_null("DesignRoot/HudLayer/BackButton") as TextureButton
@onready var _gate_view := get_node_or_null("DesignRoot/DecorLayer/Gate") as Control
@onready var _gate_portal_effect := get_node_or_null("DesignRoot/DecorLayer/GatePortalEffect") as GatePortalEffect

var _castle_anchor_position := Vector2.ZERO
var _elapsed_seconds := 0.0
var _last_display_second := -1
var _timer_running := false
var _timer_paused := false
var _castle_durability_ratio := 1.0
var _tutorial_crystal_foreground := false
var _last_castle_durability := -1
var _damage_flash: ColorRect
var _damage_flash_tween: Tween

@export var use_manual_layout := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	layout_mode = 0
	custom_minimum_size = DESIGN_SIZE
	size = DESIGN_SIZE
	if _board_guide:
		_board_guide.visible = Engine.is_editor_hint()
	if _design_root:
		_design_root.layout_mode = 0
		_design_root.position = Vector2.ZERO
		_design_root.size = DESIGN_SIZE
	_build_damage_flash()
	_apply_runtime_layer_order()
	if _back_button:
		_back_button.pressed.connect(func(): back_pressed.emit())
	_refresh_time_label()
	if Engine.is_editor_hint():
		call_deferred("_show_editor_preview")


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not _timer_running or _timer_paused:
		return
	_elapsed_seconds += delta
	var display_second := floori(_elapsed_seconds)
	if display_second != _last_display_second:
		_refresh_time_label()


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


func get_crystal_view() -> CrystalView:
	if _crystal_panel == null:
		_crystal_panel = get_node_or_null("DesignRoot/CrystalPanel") as Control
	return _crystal_panel as CrystalView


func get_crystal_attack_origin_global() -> Vector2:
	var crystal_view := get_crystal_view()
	return crystal_view.get_attack_origin_global() if crystal_view else Vector2.ZERO


func get_crystal_tutorial_anchor() -> Vector2:
	var crystal_view := get_crystal_view()
	if crystal_view == null:
		return _castle_anchor_position
	var crystal_center_global := crystal_view.get_attack_origin_global()
	return get_global_transform_with_canvas().affine_inverse() * crystal_center_global


func set_tutorial_breakthrough_foreground(monster: CanvasItem) -> void:
	if monster == null or not is_instance_valid(monster):
		return
	_set_canvas_z(monster, TUTORIAL_BREAKTHROUGH_Z)


func set_tutorial_crystal_foreground(enabled: bool) -> void:
	_tutorial_crystal_foreground = enabled
	_set_canvas_z(
		_crystal_panel,
		TUTORIAL_CRYSTAL_FOREGROUND_Z if enabled else CRYSTAL_NORMAL_Z
	)


func reset_tutorial_layer_order() -> void:
	set_tutorial_crystal_foreground(false)


func set_wave_text(text_value: String) -> void:
	if _wave_label == null:
		_wave_label = get_node_or_null("DesignRoot/HudLayer/WaveLabel") as Label
	if _wave_label:
		_wave_label.text = "第%s波" % text_value.trim_prefix("Wave ") if text_value.begins_with("Wave ") else text_value


func set_wave_progress(remaining: int, total: int) -> void:
	if _wave_count_label == null:
		_wave_count_label = get_node_or_null("DesignRoot/HudLayer/WaveCountLabel") as Label
	if _wave_count_label:
		_wave_count_label.text = "(%d/%d)" % [maxi(0, remaining), maxi(0, total)]


func start_run_hud() -> void:
	_elapsed_seconds = 0.0
	_last_display_second = -1
	_timer_running = true
	_timer_paused = false
	set_wave_progress(0, 0)
	_refresh_time_label()


func stop_run_hud() -> void:
	_timer_running = false
	_timer_paused = false


func set_run_hud_paused(paused: bool) -> void:
	_timer_paused = paused


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func reset_run_hud() -> void:
	_timer_running = false
	_timer_paused = false
	_elapsed_seconds = 0.0
	_last_display_second = -1
	_last_castle_durability = -1
	_stop_damage_flash()
	set_wave_text("")
	set_wave_progress(0, 0)
	_refresh_time_label()


func _refresh_time_label() -> void:
	if _time_label == null:
		_time_label = get_node_or_null("DesignRoot/HudLayer/TimeLabel") as Label
	var total_seconds := maxi(0, floori(_elapsed_seconds))
	_last_display_second = total_seconds
	if _time_label:
		_time_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func set_castle_status(current: int, max_value: int) -> void:
	var was_damaged := _last_castle_durability >= 0 and current < _last_castle_durability
	_last_castle_durability = current
	if _castle_status_label == null:
		_castle_status_label = get_node_or_null("DesignRoot/HudLayer/CastleStatusPanel/CastleStatusLabel") as Label
	if _castle_status_label:
		_castle_status_label.text = "%d/%d" % [current, max_value]
	_castle_durability_ratio = clampf(float(current) / float(maxi(1, max_value)), 0.0, 1.0)
	_layout_castle_fill()
	if was_damaged:
		play_crystal_damage_feedback()


func play_crystal_damage_feedback() -> void:
	# The crystal view starts its own shake/red hit animation from the same
	# CastleSystem.damage() call.  This overlay is deliberately short and
	# starts on the durability signal, so the whole battle frame flashes with
	# the crystal hit without affecting popup input.
	if _damage_flash == null or not is_inside_tree():
		return
	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	_damage_flash_tween = null
	_damage_flash.color.a = 0.0
	_damage_flash_tween = create_tween()
	_damage_flash_tween.tween_property(_damage_flash, "color:a", 0.28, 0.045).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_damage_flash_tween.tween_property(_damage_flash, "color:a", 0.0, 0.17).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_damage_flash_tween.tween_callback(func():
		if is_instance_valid(_damage_flash):
			_damage_flash.color.a = 0.0
		_damage_flash_tween = null
	)


func layout_for_board(board_pos: Vector2, board_size: Vector2, path_margin: float, spawn_pos: Vector2, goal_pos: Vector2, visual_board_pos: Vector2) -> void:
	var viewport_size := _viewport_size()
	_apply_runtime_layer_order()
	_layout_hud(viewport_size)

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
	_set_full_rect(_damage_flash, viewport_size)

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
	_layout_crystal()
	_castle_anchor_position = goal_pos


func _apply_runtime_layer_order() -> void:
	_set_canvas_z(_design_root, 0)
	_set_canvas_z(_board_guide, 1)
	_set_canvas_z(_decor_layer, 2)
	_set_canvas_z(_path_view, 5)
	_set_canvas_z(_monster_layer, MONSTER_LAYER_Z)
	_set_canvas_z(_gate_portal_effect, 11)
	# Monsters stay in front of the entrance; their scale-in intro makes them
	# appear to emerge from the portal instead of popping through the gate.
	_set_canvas_z(_gate_view, 12)
	_set_canvas_z(
		_crystal_panel,
		TUTORIAL_CRYSTAL_FOREGROUND_Z if _tutorial_crystal_foreground else CRYSTAL_NORMAL_Z
	)
	_set_canvas_z(_projectile_layer, 35)
	_set_canvas_z(_effect_layer, 30)
	_set_canvas_z(_hud_layer, 40)
	_set_canvas_z(_damage_flash, 110)


func _build_damage_flash() -> void:
	if _damage_flash and is_instance_valid(_damage_flash):
		return
	_damage_flash = ColorRect.new()
	_damage_flash.name = "CrystalDamageScreenFlash"
	_damage_flash.layout_mode = 0
	_damage_flash.position = Vector2.ZERO
	_damage_flash.size = DESIGN_SIZE
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.color = Color(0.96, 0.055, 0.04, 0.0)
	add_child(_damage_flash)


func _stop_damage_flash() -> void:
	if _damage_flash_tween and _damage_flash_tween.is_valid():
		_damage_flash_tween.kill()
	_damage_flash_tween = null
	if _damage_flash and is_instance_valid(_damage_flash):
		_damage_flash.color.a = 0.0


func _set_canvas_z(node: CanvasItem, z: int) -> void:
	if node == null:
		return
	node.z_as_relative = false
	node.z_index = z


func _layout_hud(viewport_size: Vector2) -> void:
	if _wave_banner:
		_set_rect(_wave_banner, Vector2(185.0, 24.0), Vector2(420, 76))
	if _wave_label:
		_set_rect(_wave_label, Vector2(205.0, 22.0), Vector2(118, 79))
	if _wave_count_label:
		_set_rect(_wave_count_label, Vector2(312.0, 24.0), Vector2(111, 75))
	if _time_label:
		_set_rect(_time_label, Vector2(447.0, 19.0), Vector2(141, 83))
	_layout_castle_fill()


func _layout_castle_fill() -> void:
	if _top_fill_clip == null:
		_top_fill_clip = get_node_or_null("DesignRoot/HudLayer/TopFillClip") as Control
	if _top_fill == null:
		_top_fill = get_node_or_null("DesignRoot/HudLayer/TopFillClip/TopFill") as TextureRect
	if _top_fill_clip:
		_set_rect(_top_fill_clip, TOP_FILL_POS, Vector2(TOP_FILL_SIZE.x * _castle_durability_ratio, TOP_FILL_SIZE.y))
	if _top_fill:
		_set_rect(_top_fill, Vector2.ZERO, TOP_FILL_SIZE)


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


func _layout_crystal() -> void:
	if _crystal_panel == null:
		return
	_set_rect(_crystal_panel, GameConfig.CRYSTAL_CASTLE_PANEL_POSITION, GameConfig.CRYSTAL_PANEL_SIZE)


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
	set_wave_text("Wave 8")
	set_wave_progress(8, 200)
	_elapsed_seconds = 45.0
	_refresh_time_label()
