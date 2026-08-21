@tool
extends Control
class_name BattleLayerView

signal back_pressed

const DESIGN_SIZE := Vector2(941, 1672)
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
@onready var _time_banner := get_node_or_null("DesignRoot/HudLayer/TimeBanner") as Control
@onready var _currency_banner := get_node_or_null("DesignRoot/HudLayer/CurrencyBanner") as Control
@onready var _wave_status_icon := get_node_or_null("DesignRoot/HudLayer/WaveStatusIcon") as TextureRect
@onready var _timer_status_icon := get_node_or_null("DesignRoot/HudLayer/TimerStatusIcon") as TextureRect
@onready var _currency_icon := get_node_or_null("DesignRoot/HudLayer/CurrencyIcon") as TextureRect
@onready var _currency_label := get_node_or_null("DesignRoot/HudLayer/CurrencyLabel") as Label
@onready var _crystal_panel := get_node_or_null("DesignRoot/CrystalPanel") as Control
@onready var _back_button := get_node_or_null("DesignRoot/HudLayer/BackButton") as TextureButton
@onready var _music_button := get_node_or_null("DesignRoot/HudLayer/MusicButton") as TextureButton
@onready var _home_button := get_node_or_null("DesignRoot/HudLayer/HomeButton") as TextureButton
@onready var _gate_view := get_node_or_null("DesignRoot/DecorLayer/Gate") as Control
@onready var _gate_portal_effect := get_node_or_null("DesignRoot/DecorLayer/GatePortalEffect") as GatePortalEffect

var _castle_anchor_position := Vector2.ZERO
var _elapsed_seconds := 0.0
var _last_display_second := -1
var _timer_running := false
var _timer_paused := false
var _sound_muted := false
var _base_wave_is_boss := false
var _danger_active := false
var _wave_complete := false
var _coin_value := 0
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
	_connect_press_feedback(_back_button)
	_connect_press_feedback(_music_button)
	_connect_press_feedback(_home_button)
	_refresh_control_icons()
	_refresh_wave_status_icon()
	set_coin_value(_coin_value)
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
		var clean_text := text_value.strip_edges()
		if clean_text.begins_with("Wave "):
			clean_text = clean_text.trim_prefix("Wave ")
		if clean_text.begins_with("续战"):
			# Continuation already is a complete player-facing label. Adding
			# another "第/波" made it collide with the remaining-count text.
			_wave_label.add_theme_font_size_override("font_size", 28)
			_wave_label.text = clean_text.replace("续战 ", "续战")
		else:
			_wave_label.add_theme_font_size_override("font_size", 32)
			_wave_label.text = "第%s波" % clean_text if not clean_text.is_empty() else ""


func set_wave_progress(remaining: int, total: int) -> void:
	if _wave_count_label == null:
		_wave_count_label = get_node_or_null("DesignRoot/HudLayer/WaveCountLabel") as Label
	if _wave_count_label:
		_wave_count_label.text = "%d/%d" % [maxi(0, remaining), maxi(0, total)]


func set_coin_value(value: int) -> void:
	_coin_value = maxi(0, value)
	if _currency_label == null:
		_currency_label = get_node_or_null("DesignRoot/HudLayer/CurrencyLabel") as Label
	if _currency_label:
		_currency_label.text = str(_coin_value)


func set_wave_base_state(is_boss: bool) -> void:
	_base_wave_is_boss = is_boss
	_wave_complete = false
	_refresh_wave_status_icon()


func set_wave_danger(enabled: bool) -> void:
	_danger_active = enabled
	_refresh_wave_status_icon()


func set_wave_complete(enabled: bool = true) -> void:
	_wave_complete = enabled
	_refresh_wave_status_icon()


func get_wave_status_name() -> String:
	if _wave_complete:
		return "complete"
	if _danger_active:
		return "warning"
	return "boss" if _base_wave_is_boss else "wave"


func start_run_hud(elapsed_start: float = 0.0) -> void:
	_elapsed_seconds = maxf(0.0, elapsed_start)
	_last_display_second = -1
	_timer_running = true
	_timer_paused = false
	_base_wave_is_boss = false
	_danger_active = false
	_wave_complete = false
	set_wave_progress(0, 0)
	_refresh_control_icons()
	_refresh_wave_status_icon()
	_refresh_time_label()


func stop_run_hud() -> void:
	_timer_running = false
	_timer_paused = false
	_refresh_control_icons()


func set_run_hud_paused(paused: bool) -> void:
	_timer_paused = paused
	_refresh_control_icons()


func set_sound_muted(muted: bool) -> void:
	_sound_muted = muted
	_refresh_control_icons()


func get_elapsed_seconds() -> float:
	return _elapsed_seconds


func set_elapsed_seconds(value: float) -> void:
	_elapsed_seconds = maxf(0.0, value)
	_last_display_second = -1
	_refresh_time_label()


func reset_run_hud() -> void:
	_timer_running = false
	_timer_paused = false
	_elapsed_seconds = 0.0
	_last_display_second = -1
	_last_castle_durability = -1
	_base_wave_is_boss = false
	_danger_active = false
	_wave_complete = false
	_stop_damage_flash()
	set_wave_text("")
	set_wave_progress(0, 0)
	_refresh_control_icons()
	_refresh_wave_status_icon()
	_refresh_time_label()


func _refresh_control_icons() -> void:
	# The v3 HUD bakes the pause symbol into its button art and removes the
	# sound/home controls. Runtime state is still retained for gameplay code.
	pass


func _refresh_wave_status_icon() -> void:
	# The new text-only wave panel deliberately has no status glyph.
	pass


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
	if was_damaged:
		play_crystal_damage_feedback()


func play_crystal_damage_feedback() -> void:
	# The crystal view starts its own shake/red hit animation from the same
	# CastleSystem.damage() call.  This overlay is deliberately short and
	# starts on the durability signal, so the whole battle frame flashes with
	# the crystal hit without affecting popup input.
	_play_fullscreen_red_flash()


func play_tutorial_danger_flash() -> void:
	# The tutorial warning reuses only the screen overlay. It deliberately does
	# not touch CastleSystem or CrystalView damage feedback.
	_play_fullscreen_red_flash()


func _play_fullscreen_red_flash() -> void:
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
	# GatePortalEffect keeps the transform authored in battle_layer.tscn. Do not
	# assign its position, size, scale or rotation here: artists must be able to
	# adjust the portal directly in the scene without runtime layout overwriting it.
	_layout_crystal()
	_castle_anchor_position = goal_pos


func _apply_runtime_layer_order() -> void:
	_set_canvas_z(_design_root, 0)
	_set_canvas_z(_board_guide, 1)
	_set_canvas_z(_decor_layer, 2)
	_set_canvas_z(_path_view, 5)
	_set_canvas_z(_monster_layer, MONSTER_LAYER_Z)
	# Portal animation belongs above the background/decor but below the road.
	_set_canvas_z(_gate_portal_effect, 4)
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
		_set_rect(_wave_banner, Vector2(216.0, 7.0), Vector2(268, 84))
	if _time_banner:
		_set_rect(_time_banner, Vector2(506.0, 7.0), Vector2(178, 84))
	if _currency_banner:
		# The supplied currency plate has transparent vertical padding. Give
		# its nine-patch the full HUD height so the visible pill is not
		# compressed into a thin line behind the number.
		_set_rect(_currency_banner, Vector2(772.0, 15.0), Vector2(153, 84))
	if _wave_status_icon:
		_wave_status_icon.visible = false
	if _timer_status_icon:
		_set_rect(_timer_status_icon, Vector2(519.0, 30.0), Vector2(37, 37))
	if _currency_icon:
		_set_rect(_currency_icon, Vector2(713.0, 14.0), Vector2(82, 86))
	if _wave_label:
		_set_rect(_wave_label, Vector2(231.0, 11.0), Vector2(143, 74))
	if _wave_count_label:
		_set_rect(_wave_count_label, Vector2(374.0, 11.0), Vector2(104, 74))
	if _time_label:
		_set_rect(_time_label, Vector2(553.0, 11.0), Vector2(123, 74))
	if _currency_label:
		_set_rect(_currency_label, Vector2(795.0, 19.0), Vector2(127, 75))
	if _back_button:
		_set_rect(_back_button, Vector2(30.0, 14.0), Vector2(84, 88))
	if _music_button:
		_music_button.visible = false
	if _home_button:
		_home_button.visible = false


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
	for panel in [_wave_banner, _time_banner, _currency_banner]:
		if panel is TextureRect and is_instance_valid(panel):
			(panel as TextureRect).stretch_mode = TextureRect.STRETCH_SCALE


func _connect_press_feedback(button: BaseButton) -> void:
	if button == null:
		return
	button.button_down.connect(func(): _animate_button_scale(button, Vector2(0.96, 0.96), 0.045))
	button.button_up.connect(func(): _animate_button_scale(button, Vector2.ONE, 0.075))
	button.mouse_exited.connect(func():
		if not button.button_pressed:
			_animate_button_scale(button, Vector2.ONE, 0.075)
	)


func _animate_button_scale(button: Control, target_scale: Vector2, duration: float) -> void:
	if button == null or not is_instance_valid(button):
		return
	var tween := button.create_tween()
	tween.tween_property(button, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


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
	var preview_points := GameConfig.get_path_points_for_board(preview_visual_board_pos, preview_board_size)
	var preview_spawn := preview_points[0] if not preview_points.is_empty() else preview_visual_board_pos
	var preview_goal := preview_points[-1] if not preview_points.is_empty() else preview_visual_board_pos
	layout_for_board(preview_visual_board_pos, preview_board_size, 99.0, preview_spawn, preview_goal, preview_visual_board_pos)
	set_wave_text("Wave 8")
	set_wave_progress(8, 200)
	set_wave_base_state(false)
	set_coin_value(1804)
	_elapsed_seconds = 45.0
	_refresh_time_label()
