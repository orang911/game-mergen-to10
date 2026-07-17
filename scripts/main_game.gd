extends Control

const MergeBlockScene := preload("res://scripts/block.gd")
const LoadingViewScene := preload("res://scenes/ui/loading_view.tscn")
const MergeTrailGhostScene := preload("res://scripts/merge_trail_ghost.gd")
const EnergyHudScene := preload("res://scripts/energy_hud.gd")
const CardChoiceModalScene := preload("res://scripts/card_choice_modal.gd")

const GRID_SIZE := GameConfig.GRID_SIZE
const BLOCK_SIZE := GameConfig.BLOCK_SIZE
const SAVE_PATH := GameConfig.SAVE_PATH
const START_DIRECTLY := false

enum GameStatus { NONE, START, OVER, PAUSE }

var game_status := GameStatus.NONE
var block_map: Dictionary = {}
var index_map: Array = []
var selected_blocks: Array[MergeBlock] = []
var block_count := 0
var current_level := 0
var score := 0
var best_score := 0
var muted := false

var block_bg_textures: Dictionary[String, Texture2D] = {}
var ui_textures: Dictionary[String, Texture2D] = {}

var background: TextureRect
var main_layer: Control
var loading_view: LoadingView
var game_layer: Control
var battle_background: TextureRect
var board_layer: Control
var decor_layer: Control
var popup_layer: Control
var score_label: Label
var best_label: Label
var click_player: AudioStreamPlayer
var merge_player: AudioStreamPlayer
var combat_system: CombatSystem
var music_button: TextureButton
var bottom_ui: Control
var bottom_buttons_art: TextureRect
var _manual_paused := false
var merge_frames: Array[Texture2D] = []
var skill_imprint_system: SkillImprintSystem
var energy_hud: EnergyHud
var modal_layer: Control
var active_card_modal: CardChoiceModal
var _wave_reward_pending := false
var _skill_choice_pending := false
var _wave_waiting_to_continue := false
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	randomize()
	_load_save()
	_load_assets()
	_reset_index_map()
	_build_scene()
	resized.connect(_layout_scene)
	call_deferred("_layout_scene")
	if START_DIRECTLY:
		call_deferred("start_game")
	else:
		show_loading()

func _load_assets() -> void:
	for color_name in GameConfig.BLOCK_BG_PATHS:
		block_bg_textures[color_name] = load(GameConfig.BLOCK_BG_PATHS[color_name]) as Texture2D

	for i in range(1, 14):
		merge_frames.append(load("res://assets/effest/texture/couple-%04d.png" % i) as Texture2D)

	var paths: Dictionary[String, String] = {
		"bg": "res://assets/UI/loading/loading_background.jpg",
		"bg_03": "res://assets/sliced_20260703_172750/decor_cloud_01.png",
		"bg_04": "res://assets/sliced_20260703_172750/decor_cloud_02.png",
		"bg_05": "res://assets/sliced_20260703_172750/decor_tree_01.png",
		"game_bg": "res://assets/textrues/mian/bg_02.png",
		"restart": "res://assets/textrues/mian/Rstart.png",
		"refresh": "res://assets/textrues/mian/Refresh.png",
		"back": "res://assets/textrues/mian/back.png",
		"music": "res://assets/textrues/mian/music.png",
		"panel": "res://assets/textrues/mian/Panel.png",
		"success": "res://assets/textrues/mian/jiesuan.png",
		"continue": "res://assets/textrues/mian/Continue.png",
		"new_record": "res://assets/textrues/mian/newrecord.png",
		"crown": "res://assets/textrues/mian/Crown.png",
		"light": "res://assets/textrues/mian/Light.png",
		"esc": "res://assets/textrues/mian/esc.png",
		"slice_board_panel": "res://assets/UI/游戏核心/合成底板.png",
		"slice_setting_bg": "res://assets/sliced_20260703_172750/setting_button_bg.png",
		"slice_setting_icon": "res://assets/sliced_20260703_172750/setting_icon.png",
		"slice_tip_panel": "res://assets/sliced_20260703_172750/tip_panel.png",
		"slice_tip_bulb": "res://assets/sliced_20260703_172750/tip_icon_bulb.png",
		"battle_scene_bg": "res://assets/UI/游戏核心/layer_004.png",
		"bottom_bg": "res://assets/UI/底部UI/layer_003.png",
		"bottom_buttons": "res://assets/UI/底部UI/layer_002.png"
	}
	for key in paths:
		ui_textures[key] = load(paths[key]) as Texture2D

func _build_scene() -> void:
	background = _make_texture_rect(ui_textures["bg"])
	add_child(background)

	decor_layer = Control.new()
	decor_layer.name = "Decor"
	decor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	decor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decor_layer)
	_build_background_decor()

	main_layer = Control.new()
	main_layer.name = "MainMenu"
	main_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_layer)
	loading_view = LoadingViewScene.instantiate() as LoadingView
	loading_view.name = "LoadingView"
	loading_view.play_pressed.connect(_on_play_pressed)
	loading_view.intro_finished.connect(_on_title_intro_finished)
	main_layer.add_child(loading_view)

	game_layer = Control.new()
	game_layer.name = "Game"
	game_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_layer)

	popup_layer = Control.new()
	popup_layer.name = "Popups"
	popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup_layer)

	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	combat_system.setup(game_layer)
	combat_system.castle_destroyed.connect(_on_castle_destroyed)
	combat_system.castle_durability_changed.connect(_on_castle_durability_changed)
	combat_system.back_pressed.connect(_toggle_manual_pause)
	combat_system.normal_attack_kill.connect(_on_normal_attack_kill)
	combat_system.wave_cleared.connect(_on_wave_cleared)
	combat_system.level_completed.connect(func(): end_game(true))
	for tip_path in ["DesignRoot/HudLayer/TipPanel", "DesignRoot/HudLayer/TipIcon", "DesignRoot/HudLayer/TipLabel"]:
		var tip_node := combat_system.battle_layer.get_node_or_null(tip_path) as CanvasItem
		if tip_node:
			tip_node.visible = false

	battle_background = _make_texture_rect(ui_textures["battle_scene_bg"])
	battle_background.name = "BattleBackground"
	game_layer.add_child(battle_background)
	game_layer.move_child(battle_background, 0)

	var board_bg := _make_texture_rect(_texture_or("slice_board_panel", "game_bg"))
	board_bg.name = "BoardBackdrop"
	board_bg.z_as_relative = false
	board_bg.z_index = 6
	board_bg.custom_minimum_size = GameConfig.get_board_backdrop_size()
	game_layer.add_child(board_bg)

	board_layer = Control.new()
	board_layer.name = "Board"
	board_layer.z_as_relative = false
	board_layer.z_index = 7
	board_layer.custom_minimum_size = GameConfig.get_board_size()
	board_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_layer.clip_contents = true
	game_layer.add_child(board_layer)
	if combat_system and combat_system.battle_layer:
		game_layer.move_child(combat_system.battle_layer, board_layer.get_index() + 1)

	score_label = _make_label("0", 73)
	score_label.name = "Score"
	game_layer.add_child(score_label)

	best_label = _make_label("BEST %d" % best_score, 34)
	best_label.name = "Best"
	game_layer.add_child(best_label)

	skill_imprint_system = SkillImprintSystem.new()
	skill_imprint_system.name = "SkillImprintSystem"
	add_child(skill_imprint_system)
	skill_imprint_system.energy_changed.connect(_on_skill_energy_changed)
	skill_imprint_system.energy_gain_requested.connect(_on_energy_gain_requested)
	skill_imprint_system.skill_choice_requested.connect(_on_skill_choice_requested)
	skill_imprint_system.pending_skill_changed.connect(_on_pending_skill_changed)

	energy_hud = EnergyHudScene.new() as EnergyHud
	energy_hud.name = "EnergyHud"
	energy_hud.z_index = 80
	game_layer.add_child(energy_hud)
	energy_hud.gain_fx_batch_finished.connect(func(): skill_imprint_system.notify_fx_batch_finished())

	_build_bottom_ui()

	modal_layer = Control.new()
	modal_layer.name = "CardModalLayer"
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.z_index = 120
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(modal_layer)

	click_player = AudioStreamPlayer.new()
	click_player.stream = load("res://assets/sound/click.mp3")
	add_child(click_player)

	merge_player = AudioStreamPlayer.new()
	merge_player.stream = load("res://assets/sound/mergen.mp3")
	add_child(merge_player)

func _build_background_decor() -> void:
	var decor_data := [
		["bg_05", Vector2(-144, 1359), Vector2(863, 679), 44.0],
		["bg_03", Vector2(542, 1261), Vector2(529, 529), 55.0],
		["bg_05", Vector2(274, 1463), Vector2(614, 483), 50.0],
		["bg_03", Vector2(-216, 928), Vector2(693, 693), 60.0],
		["bg_04", Vector2(614, 379), Vector2(274, 248), 39.0]
	]
	for i in range(decor_data.size()):
		var item: Array = decor_data[i]
		var texture_key: String = item[0]
		var sprite := _make_texture_rect(ui_textures[texture_key])
		sprite.name = "Decor_%d" % i
		sprite.position = item[1]
		sprite.size = item[2]
		sprite.modulate = Color(1, 1, 1, 0.82)
		decor_layer.add_child(sprite)
		_float_node(sprite, float(item[3]), Vector2(0, -18 + i * 4))

func _layout_scene() -> void:
	var viewport_size := size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		viewport_size = Vector2(941, 1672)

	var design_size := Vector2(941.0, 1672.0)
	var scale_factor := minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)

	# Full-screen layers (not affected by game scaling)
	background.size = viewport_size
	if loading_view:
		loading_view.layout_for_viewport(viewport_size)

	# Game layer: letterboxed at design aspect ratio, all children work in 941x1672 coords
	game_layer.position = (viewport_size - design_size * scale_factor) * 0.5
	game_layer.scale = Vector2(scale_factor, scale_factor)
	game_layer.size = design_size

	# Battle background fills actual screen (reverse the scale so it covers viewport)
	_set_rect(battle_background, Vector2.ZERO, viewport_size / scale_factor)

	var board_size := GameConfig.get_board_size()
	# Keep the board anchor in the established design frame. The actual PNG
	# rect and its centerline are derived from the same source-size rect in
	# GameConfig, while this virtual frame preserves the board relationship.
	var road_size := GameConfig.get_path_layout_size()
	var board_pos := GameConfig.BOARD_GRID_POS
	var combat_board_pos := Vector2(
		board_pos.x,
		GameConfig.PATH_ROAD_TARGET_BOTTOM_Y - board_size.y * 0.5 - road_size.y * 0.5 - GameConfig.PATH_ROAD_OFFSET.y
	)
	_set_rect(board_layer, board_pos, board_size)
	if combat_system:
		combat_system.layout_for_board(combat_board_pos, board_size, board_pos)
	_set_rect(game_layer.get_node("BoardBackdrop") as Control, GameConfig.get_board_plate_position(board_pos), GameConfig.get_board_backdrop_size())
	_set_rect(score_label, Vector2(31, design_size.y - 68.0), Vector2(190, 55))
	_set_rect(best_label, Vector2(design_size.x - 231.0, design_size.y - 61.0), Vector2(200, 42))
	if bottom_ui:
		_set_rect(bottom_ui, Vector2(0, 1324), Vector2(941, 348))
	if energy_hud:
		_set_rect(energy_hud, Vector2((design_size.x - 868.0) * 0.5, 1339.0), Vector2(868, 206))
	if modal_layer:
		_set_rect(modal_layer, Vector2.ZERO, design_size)
	for block in block_map.values():
		if block:
			block.position = _position_for_site(block.board_site)

func _set_rect(node: Control, pos: Vector2, node_size: Vector2) -> void:
	node.position = pos
	node.size = node_size
	node.pivot_offset = node_size * 0.5

func _wire_button_anim(button: BaseButton) -> void:
	button.button_down.connect(func(): _button_scale(button, Vector2(0.9, 0.9), 0.06))
	button.button_up.connect(func(): _button_scale(button, Vector2.ONE, 0.08))

func _button_scale(node: Control, target_scale: Vector2, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(node, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _float_node(node: Control, duration: float, offset: Vector2) -> void:
	var base_pos := node.position
	var tween := create_tween().set_loops()
	tween.tween_property(node, "position", base_pos + offset, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "position", base_pos, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _make_texture_rect(texture: Texture2D) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

func _make_texture_button(texture: Texture2D) -> TextureButton:
	var button := TextureButton.new()
	button.texture_normal = texture
	button.texture_hover = texture
	button.texture_pressed = texture
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE
	return button

func _build_bottom_ui() -> void:
	bottom_ui = Control.new()
	bottom_ui.name = "BottomUi"
	bottom_ui.z_index = 70
	bottom_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(bottom_ui)

	var background_art := _make_texture_rect(ui_textures["bottom_bg"])
	background_art.name = "Background"
	_set_rect(background_art, Vector2.ZERO, Vector2(941, 348))
	bottom_ui.add_child(background_art)

	bottom_buttons_art = _make_texture_rect(ui_textures["bottom_buttons"])
	bottom_buttons_art.name = "ButtonsArt"
	_set_rect(bottom_buttons_art, Vector2(82, 240), Vector2(811, 91))
	bottom_ui.add_child(bottom_buttons_art)

	var home_button := _make_hotspot_button()
	home_button.name = "HomeButton"
	_set_rect(home_button, Vector2(82, 240), Vector2(175, 91))
	home_button.pressed.connect(over_game)
	bottom_ui.add_child(home_button)

	var play_button := _make_hotspot_button()
	play_button.name = "PlayPauseButton"
	_set_rect(play_button, Vector2(307, 240), Vector2(354, 91))
	play_button.pressed.connect(_toggle_manual_pause)
	bottom_ui.add_child(play_button)

	music_button = _make_hotspot_button()
	music_button.name = "MusicButton"
	_set_rect(music_button, Vector2(702, 240), Vector2(191, 91))
	music_button.pressed.connect(_toggle_mute)
	bottom_ui.add_child(music_button)

func _make_hotspot_button() -> TextureButton:
	var button := TextureButton.new()
	button.ignore_texture_size = true
	button.focus_mode = Control.FOCUS_NONE
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	return button

func _toggle_manual_pause() -> void:
	if game_layer == null or not game_layer.visible:
		return
	_manual_paused = not _manual_paused
	get_tree().paused = _manual_paused
	_play_click()

func _texture_or(primary_key: String, fallback_key: String) -> Texture2D:
	if ui_textures.has(primary_key) and ui_textures[primary_key] != null:
		return ui_textures[primary_key]
	return ui_textures[fallback_key]

func _make_label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_shadow_color", Color(0.08, 0.05, 0.04, 0.75))
	label.add_theme_constant_override("shadow_offset_x", 3)
	label.add_theme_constant_override("shadow_offset_y", 3)
	return label

func _make_round_panel(fill_color: Color, border_color: Color, radius: float) -> Panel:
	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.corner_radius_top_left = int(radius)
	style.corner_radius_top_right = int(radius)
	style.corner_radius_bottom_left = int(radius)
	style.corner_radius_bottom_right = int(radius)
	style.shadow_color = Color(0.18, 0.28, 0.42, 0.18)
	style.shadow_size = 8
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func show_main_menu() -> void:
	game_status = GameStatus.NONE
	main_layer.visible = true
	game_layer.visible = false
	popup_layer.visible = false
	decor_layer.visible = false
	_clear_popup()
	_update_mute_visual()
	_begin_title_intro()

func show_loading() -> void:
	game_status = GameStatus.NONE
	main_layer.visible = true
	game_layer.visible = false
	popup_layer.visible = false
	decor_layer.visible = false
	_begin_title_intro()

func _begin_title_intro() -> void:
	if loading_view:
		loading_view.visible = true
		loading_view.set_interactive(false)
		loading_view.begin_intro()

func _on_title_intro_finished() -> void:
	if main_layer and main_layer.visible and loading_view:
		loading_view.set_interactive(true)

func _animate_game_in() -> void:
	game_layer.modulate = Color(1, 1, 1, 0)
	board_layer.scale = Vector2(0.96, 0.96)
	var backdrop := game_layer.get_node("BoardBackdrop") as Control
	backdrop.scale = Vector2(0.96, 0.96)
	var tween := create_tween()
	tween.tween_property(game_layer, "modulate:a", 1.0, 0.18)
	tween.parallel().tween_property(board_layer, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(backdrop, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_play_pressed() -> void:
	_play_click()
	start_game()

func start_game() -> void:
	_reset_card_runtime()
	if loading_view:
		loading_view.stop_animations()
		loading_view.visible = false
	main_layer.visible = false
	game_layer.visible = true
	popup_layer.visible = true
	decor_layer.visible = true
	game_layer.modulate = Color(1, 1, 1, 0)
	_clear_game_world()
	score = 0
	_update_score_label()
	first_create_blocks()
	if combat_system:
		combat_system.start_run()
	game_status = GameStatus.PAUSE
	_animate_game_in()
	await get_tree().create_timer(1.35).timeout
	if game_status == GameStatus.PAUSE:
		game_status = GameStatus.START

func replay_game() -> void:
	_play_click()
	_reset_card_runtime()
	game_status = GameStatus.PAUSE
	_clear_popup()
	_clear_game_world()
	score = 0
	_update_score_label()
	first_create_blocks()
	if combat_system:
		combat_system.start_run()
	_animate_game_in()
	await get_tree().create_timer(1.35).timeout
	if game_status == GameStatus.PAUSE:
		game_status = GameStatus.START

func over_game() -> void:
	_play_click()
	_reset_card_runtime()
	if combat_system:
		combat_system.stop_run()
	_clear_popup()
	_clear_game_world()
	show_main_menu()

func first_create_blocks() -> void:
	_reset_index_map()
	var order := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var level := randi_range(1, 3)
			_create_block(Vector2i(x, y), level, true, order * 0.04)
			order += 1
	_ensure_any_match()

func _create_block(site: Vector2i, start_level: int, drop_in: bool, drop_delay: float = 0.0) -> MergeBlock:
	var block := MergeBlockScene.new() as MergeBlock
	block.setup(start_level, block_bg_textures)
	block.board_site = site
	block.name = "Block_%d" % block_count
	block.block_pressed.connect(_on_block_pressed)
	board_layer.add_child(block)
	block.position = _position_for_site(site)
	block_map[block_count] = block
	index_map[site.y][site.x] = block_count
	block_count += 1

	if drop_in:
		var target_pos := _position_for_site(site)
		block.position = Vector2(target_pos.x, -BLOCK_SIZE * (site.y + 1))
		var tween := create_tween()
		if drop_delay > 0.0:
			tween.tween_interval(drop_delay)
		tween.tween_property(block, "position", target_pos, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	return block

func _position_for_site(site: Vector2i) -> Vector2:
	return GameConfig.get_block_position_for_site(site)

func _on_block_pressed(block: MergeBlock) -> void:
	if game_status != GameStatus.START:
		return
	if block.selected:
		if block.had_merged:
			return
		merge_selected_blocks(block)
	else:
		select_next_blocks(block)

func select_next_blocks(clicked: MergeBlock) -> void:
	for block in selected_blocks:
		block.selected = false
	selected_blocks.clear()

	if clicked.level >= GameConfig.MAX_BLOCK_LEVEL:
		return

	_flood_select(clicked, clicked.level)
	if selected_blocks.size() == 1:
		clicked.selected = false
		selected_blocks.clear()
		clicked.shake()

func _flood_select(block: MergeBlock, target_level: int) -> void:
	if block == null or block.level != target_level or block.selected:
		return

	block.selected = true
	selected_blocks.append(block)

	var x := block.board_site.x
	var y := block.board_site.y
	if y - 1 >= 0:
		_flood_select(_block_at(Vector2i(x, y - 1)), target_level)
	if y + 1 < GRID_SIZE:
		_flood_select(_block_at(Vector2i(x, y + 1)), target_level)
	if x - 1 >= 0:
		_flood_select(_block_at(Vector2i(x - 1, y)), target_level)
	if x + 1 < GRID_SIZE:
		_flood_select(_block_at(Vector2i(x + 1, y)), target_level)

func merge_selected_blocks(clicked: MergeBlock) -> void:
	if selected_blocks.size() < 2:
		clicked.selected = false
		selected_blocks.clear()
		clicked.shake()
		return

	if combat_system and combat_system.crystal_system:
		combat_system.crystal_system.hide_attack_tip()
	_play_merge()
	game_status = GameStatus.PAUSE

	var merge_group: Array[MergeBlock] = []
	for block in selected_blocks:
		merge_group.append(block)
	var board_highest_before_merge := _get_board_highest_level()
	var prepared_skill: Dictionary = skill_imprint_system.consume_pending_skill() if skill_imprint_system else {}
	var triggered_imprints: Array[Dictionary] = []
	if not clicked.skill_imprint_id.is_empty():
		triggered_imprints.append(clicked.take_skill_imprint())
	for block in merge_group:
		if block != clicked and not block.skill_imprint_id.is_empty():
			triggered_imprints.append(block.take_skill_imprint())

	var merged_count: int = merge_group.size()
	var source_level: int = clicked.level
	var result_level: int = source_level + 1

	var click_index: int = merge_group.find(clicked)
	var max_steps: int = max(merged_count - 1 - click_index, click_index)
	var action_time: float = max(0.08, 0.36 / float(merged_count))
	var merge_action_duration := float(max_steps + 1) * action_time + 0.08
	clicked.begin_merge_highlight(merge_action_duration)

	for block in merge_group:
		if block == clicked:
			continue
		block.had_merged = true
		var index: int = merge_group.find(block)
		var step_distance: int = abs(index - click_index)
		var delay: float = float(max_steps - step_distance) * action_time
		var next_index: int = index
		if index > click_index:
			next_index -= 1
		elif index < click_index:
			next_index += 1
		var target_block: MergeBlock = merge_group[next_index]
		_remove_block_to_target(block, target_block.position, delay, action_time)

	await get_tree().create_timer(merge_action_duration).timeout
	selected_blocks.clear()
	clicked.selected = false
	clicked.had_merged = false
	clicked.level = result_level
	clicked.complete_merge_highlight()
	clicked.play_merge_result_reveal()
	_play_merge_effect(clicked)
	if not triggered_imprints.is_empty():
		await _apply_triggered_imprints(triggered_imprints, clicked)
	result_level = clicked.level
	if not prepared_skill.is_empty():
		clicked.set_skill_imprint(str(prepared_skill.get("id", "")), true, int(prepared_skill.get("quality", 1)))
	current_level = max(current_level, clicked.level)
	if combat_system and combat_system.crystal_system:
		combat_system.crystal_system.notify_merge_level(clicked.level)
	_dispatch_merge_attack(clicked, merged_count, source_level, clicked.level)
	if skill_imprint_system and _is_new_highest_merge_result(clicked.level, board_highest_before_merge):
		var merge_origin := board_layer.global_position + clicked.position + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5)
		skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_PER_MERGE_UNIT * (merged_count - 1), merge_origin, 3, false)
	_refresh_score(merged_count, source_level)
	_pulse(clicked)

	if clicked.level >= GameConfig.MAX_BLOCK_LEVEL:
		await get_tree().create_timer(0.16).timeout
		_remove_block(clicked, true, clicked.position)
		await get_tree().create_timer(0.18).timeout
		await _fall_and_fill()
		if game_status != GameStatus.OVER:
			_show_success_popup()
	else:
		await get_tree().create_timer(0.12).timeout
		await _fall_and_fill()

	if game_status == GameStatus.PAUSE:
		game_status = GameStatus.START

func _refresh_score(merge_count: int, level_value: int) -> void:
	score += (merge_count - 1) * level_value * 2
	_update_score_label()
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.25, 1.25), 0.1)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.1)

func _dispatch_merge_attack(clicked: MergeBlock, merge_count: int, source_level: int, result_level: int) -> void:
	if combat_system == null:
		return
	var origin := board_layer.global_position + clicked.position + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5)
	var attack_event := MergeAttackEvent.from_merge(source_level, result_level, merge_count, origin, clicked.board_site.y)
	combat_system.handle_merge_attack(attack_event)

func _update_score_label() -> void:
	score_label.text = str(score)
	if score > best_score:
		best_score = score
		_save_best()
	best_label.text = "BEST %d" % best_score

func _fall_and_fill() -> void:
	for x in range(GRID_SIZE):
		var write_y := 0
		for y in range(GRID_SIZE):
			var block := _block_at(Vector2i(x, y))
			if block == null:
				continue
			if y != write_y:
				_move_block_to(block, Vector2i(x, write_y))
			write_y += 1

	var create_level := 4 if current_level > 4 else 3
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if index_map[y][x] == -1:
				_create_block(Vector2i(x, y), randi_range(1, create_level), true)

	await get_tree().create_timer(0.32).timeout

func _move_block_to(block: MergeBlock, new_site: Vector2i) -> void:
	var old_site := block.board_site
	var index: int = index_map[old_site.y][old_site.x]
	index_map[old_site.y][old_site.x] = -1
	index_map[new_site.y][new_site.x] = index
	block.board_site = new_site
	var tween := create_tween()
	tween.tween_property(block, "position", _position_for_site(new_site), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func check_fail() -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var block := _block_at(Vector2i(x, y))
			if block == null or block.level >= GameConfig.MAX_BLOCK_LEVEL:
				continue
			if _has_same_neighbor(block):
				return false
	return true

func _ensure_any_match() -> void:
	if not check_fail():
		return
	var first := _block_at(Vector2i(0, 0))
	var second := _block_at(Vector2i(1, 0))
	if first != null and second != null and first.level < GameConfig.MAX_BLOCK_LEVEL:
		second.level = first.level

func _has_same_neighbor(block: MergeBlock) -> bool:
	var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]
	for dir in dirs:
		var site: Vector2i = block.board_site + dir
		if site.x < 0 or site.y < 0 or site.x >= GRID_SIZE or site.y >= GRID_SIZE:
			continue
		var neighbor := _block_at(site)
		if neighbor != null and neighbor.level == block.level:
			return true
	return false

func _on_castle_destroyed() -> void:
	call_deferred("end_game", false)

func _on_castle_durability_changed(current: int, max_value: int) -> void:
	if combat_system and combat_system.battle_layer and is_instance_valid(combat_system.battle_layer):
		combat_system.battle_layer.set_castle_status(current, max_value)

func end_game(_had_pass: bool) -> void:
	game_status = GameStatus.OVER
	_reset_card_runtime()
	if combat_system:
		combat_system.stop_run()
	_clear_merge_trails()
	_show_account_popup()

func resurrect() -> void:
	_play_click()
	_clear_popup()
	var min_level := 0
	for block in block_map.values():
		if block == null:
			continue
		if min_level == 0 or block.level < min_level:
			min_level = block.level

	if min_level == 0:
		replay_game()
		return

	for block in block_map.values().duplicate():
		if block != null and block.level == min_level:
			_remove_block(block, true, block.position)
	await get_tree().create_timer(0.18).timeout
	await _fall_and_fill()
	if game_status != GameStatus.OVER:
		if combat_system:
			combat_system.start_run()
		game_status = GameStatus.START

func _show_success_popup() -> void:
	_clear_popup()
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shade := _make_popup_shade()
	popup_layer.add_child(shade)

	var light := _make_texture_rect(ui_textures["light"])
	_set_rect(light, Vector2((size.x - 941.0) * 0.5, size.y * 0.08), Vector2(941, 742))
	light.modulate = Color(1, 1, 1, 0)
	popup_layer.add_child(light)

	var popup := _make_texture_rect(ui_textures["success"])
	popup.name = "SuccessPanel"
	_set_rect(popup, Vector2((size.x - 873.0) * 0.5, size.y * 0.22), Vector2(873, 1066))
	popup.scale = Vector2.ZERO
	popup_layer.add_child(popup)

	var icon := _make_block_preview(GameConfig.MAX_BLOCK_LEVEL, Vector2(220, 220))
	icon.position = Vector2(327, 275)
	popup.add_child(icon)

	var continue_button := _make_texture_button(ui_textures["continue"])
	_set_rect(continue_button, Vector2(182, 745), Vector2(510, 209))
	continue_button.pressed.connect(func(): _play_click(); _clear_popup())
	_wire_button_anim(continue_button)
	popup.add_child(continue_button)

	var tween := create_tween()
	tween.parallel().tween_property(light, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(light, "rotation", TAU, 8.0).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _show_account_popup() -> void:
	_clear_popup()
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var popup := _make_popup_panel(Vector2(797, 915))
	popup_layer.add_child(popup)

	var title := _make_label("GAME OVER", 48)
	_set_rect(title, Vector2(0, 72), Vector2(797, 91))
	popup.add_child(title)

	var score_text := _make_label("SCORE  %d" % score, 40)
	_set_rect(score_text, Vector2(0, 196), Vector2(797, 78))
	popup.add_child(score_text)

	var best_text := _make_label("BEST  %d" % best_score, 34)
	_set_rect(best_text, Vector2(0, 281), Vector2(797, 68))
	popup.add_child(best_text)

	var block_icon := _make_block_preview(clampi(current_level, 1, GameConfig.MAX_BLOCK_LEVEL), Vector2(173, 173))
	block_icon.position = Vector2(312, 373)
	popup.add_child(block_icon)

	var crown := _make_texture_rect(ui_textures["crown"])
	_set_rect(crown, Vector2(235, 294), Vector2(59, 51))
	popup.add_child(crown)

	if score >= best_score and score > 0:
		var record := _make_texture_rect(ui_textures["new_record"])
		_set_rect(record, Vector2(229, 565), Vector2(338, 48))
		popup.add_child(record)

	var revive_button := _make_text_button("CONTINUE", Vector2(327, 99))
	_set_rect(revive_button, Vector2(235, 634), Vector2(327, 99))
	revive_button.pressed.connect(resurrect)
	_wire_button_anim(revive_button)
	popup.add_child(revive_button)

	var restart_button := _make_texture_button(ui_textures["restart"])
	_set_rect(restart_button, Vector2(146, 745), Vector2(203, 157))
	restart_button.pressed.connect(replay_game)
	_wire_button_anim(restart_button)
	popup.add_child(restart_button)

	var home_button := _make_texture_button(ui_textures["esc"])
	_set_rect(home_button, Vector2(634, 29), Vector2(101, 86))
	home_button.pressed.connect(over_game)
	_wire_button_anim(home_button)
	popup.add_child(home_button)

func _make_popup_panel(panel_size: Vector2) -> Control:
	var shade := _make_popup_shade()
	popup_layer.add_child(shade)

	var panel := TextureRect.new()
	panel.texture = ui_textures["panel"]
	panel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	panel.stretch_mode = TextureRect.STRETCH_SCALE
	panel.size = panel_size
	panel.position = (size - panel_size) * 0.5
	panel.pivot_offset = panel_size * 0.5
	panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return panel

func _make_popup_shade() -> ColorRect:
	var shade := ColorRect.new()
	shade.name = "PopupShade"
	shade.color = Color(0, 0, 0, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	return shade

func _make_block_preview(level: int, preview_size: Vector2) -> Control:
	var container := Control.new()
	container.size = preview_size
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bg := TextureRect.new()
	bg.texture = block_bg_textures.get(GameConfig.get_block_color_name(level))
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bg.size = preview_size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	var label := TextureRect.new()
	label.texture = load(GameConfig.get_label_texture_path(level)) as Texture2D
	label.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	label.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex_sz: Vector2 = label.texture.get_size() if label.texture else Vector2.ZERO
	var label_max: float = preview_size.x * GameConfig.BLOCK_LABEL_FILL
	var s: float = label_max / maxf(tex_sz.x, tex_sz.y)
	var ls: Vector2 = tex_sz * s
	label.position = (preview_size - ls) * 0.5
	label.size = ls
	container.add_child(label)

	return container


func _make_text_button(text: String, button_size: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", 28)
	return button

func _clear_popup() -> void:
	for child in popup_layer.get_children():
		child.queue_free()
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _remove_block(block: MergeBlock, animated: bool, target_position: Vector2) -> void:
	var site := block.board_site
	var index: int = index_map[site.y][site.x]
	if index != -1:
		index_map[site.y][site.x] = -1
		block_map[index] = null

	if animated:
		var tween := create_tween()
		tween.parallel().tween_property(block, "position", target_position, 0.14)
		tween.parallel().tween_property(block, "modulate:a", 0.0, 0.14)
		tween.tween_callback(block.queue_free)
	else:
		block.queue_free()

func _remove_block_to_target(block: MergeBlock, target_position: Vector2, delay: float, duration: float) -> void:
	var site := block.board_site
	var index: int = index_map[site.y][site.x]
	if index != -1:
		index_map[site.y][site.x] = -1
		block_map[index] = null

	_spawn_merge_trail(block, target_position, delay, duration)
	block.selected = false
	board_layer.move_child(block, board_layer.get_child_count() - 1)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(block, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(block, "scale", Vector2(0.86, 0.86), duration)
	tween.tween_property(block, "modulate:a", 0.0, 0.06)
	tween.tween_callback(block.queue_free)

func _spawn_merge_trail(block: MergeBlock, target_position: Vector2, delay: float, duration: float) -> void:
	if board_layer == null or not is_instance_valid(board_layer) or block == null or not is_instance_valid(block):
		return
	var ghost := MergeTrailGhostScene.new() as MergeTrailGhost
	if ghost == null:
		return
	ghost.name = "MergeAfterimage_%d" % block.get_instance_id()
	ghost.setup_from_block(block)
	ghost.position = block.position
	ghost.scale = block.scale * 0.96
	ghost.pivot_offset = block.size * 0.5
	board_layer.add_child(ghost)
	board_layer.move_child(ghost, 0)
	ghost.play_to(target_position, delay, duration)

func _pulse(block: MergeBlock) -> void:
	block.pivot_offset = block.size * 0.5
	var tween := create_tween()
	tween.tween_property(block, "scale", Vector2(1.14, 1.14), 0.08)
	tween.tween_property(block, "scale", Vector2.ONE, 0.1)

func _play_merge_effect(block: MergeBlock) -> void:
	if merge_frames.is_empty():
		return
	var center := board_layer.position + block.position + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5)
	var tex_sz := merge_frames[0].get_size()
	var fx_size := tex_sz * 1.1
	var fx := TextureRect.new()
	fx.name = "MergeFx"
	fx.texture = merge_frames[0]
	fx.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fx.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fx.position = center - fx_size * 0.5
	fx.size = fx_size
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(fx)

	_play_effect_frames(fx)

func _play_effect_frames(fx: TextureRect) -> void:
	for i in range(1, merge_frames.size()):
		await get_tree().create_timer(0.02).timeout
		if not is_instance_valid(fx):
			return
		fx.texture = merge_frames[i]
	if is_instance_valid(fx):
		fx.queue_free()

func _block_at(site: Vector2i) -> MergeBlock:
	if site.x < 0 or site.y < 0 or site.x >= GRID_SIZE or site.y >= GRID_SIZE:
		return null
	var index: int = index_map[site.y][site.x]
	if index == -1:
		return null
	return block_map.get(index, null) as MergeBlock

func _reset_index_map() -> void:
	index_map.clear()
	for _y in range(GRID_SIZE):
		var row := []
		for _x in range(GRID_SIZE):
			row.append(-1)
		index_map.append(row)

func _clear_game_world() -> void:
	_clear_merge_trails()
	for block in block_map.values():
		if block:
			block.cancel_merge_highlight()
			block.queue_free()
	block_map.clear()
	selected_blocks.clear()
	block_count = 0
	current_level = 0
	_reset_index_map()

func _clear_merge_trails() -> void:
	if board_layer == null or not is_instance_valid(board_layer):
		return
	for child in board_layer.get_children():
		if child is MergeTrailGhost:
			child.queue_free()


func _apply_triggered_imprints(imprints: Array[Dictionary], result_block: MergeBlock) -> void:
	for imprint in imprints:
		var skill_id := str(imprint.get("id", ""))
		var quality := clampi(int(imprint.get("quality", 1)), 1, 3)
		match skill_id:
			"core_ascension":
				result_block.level = mini(GameConfig.MAX_BLOCK_LEVEL, result_block.level + (2 if quality >= 3 else 1))
			"frequency_convergence":
				_apply_frequency_convergence(result_block, quality)
			"fragment_reforge":
				_apply_fragment_reforge(quality)
			"board_echo":
				_apply_board_echo(quality)
			"frost_star":
				if combat_system:
					combat_system.trigger_frost_star(result_block.level, quality)
		await get_tree().create_timer(0.08).timeout


func _active_blocks() -> Array[MergeBlock]:
	var result: Array[MergeBlock] = []
	for value in block_map.values():
		var block := value as MergeBlock
		if block and is_instance_valid(block):
			result.append(block)
	return result


func _get_board_highest_level() -> int:
	var highest := 0
	for block in _active_blocks():
		highest = maxi(highest, block.level)
	return highest


func _is_new_highest_merge_result(result_level: int, highest_before_merge: int) -> bool:
	return result_level > highest_before_merge


func _apply_frequency_convergence(result_block: MergeBlock, quality: int = 1) -> void:
	var blocks := _active_blocks()
	if blocks.is_empty():
		return
	var min_level := GameConfig.MAX_BLOCK_LEVEL
	var max_level := 1
	for block in blocks:
		min_level = mini(min_level, block.level)
		max_level = maxi(max_level, block.level)
	for block in blocks:
		if block != result_block and block.level < max_level:
			block.level = mini(max_level - 1, min_level + quality - 1)


func _apply_fragment_reforge(quality: int = 1) -> void:
	var blocks := _active_blocks()
	if blocks.is_empty():
		return
	var min_level := GameConfig.MAX_BLOCK_LEVEL
	for block in blocks:
		min_level = mini(min_level, block.level)
	for block in blocks:
		if block.level == min_level:
			block.level = mini(GameConfig.MAX_BLOCK_LEVEL, block.level + quality)


func _apply_board_echo(quality: int = 1) -> void:
	var sites: Array[Vector2i] = []
	var ids: Array[int] = []
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var id: int = index_map[y][x]
			if id != -1 and block_map.get(id) != null:
				sites.append(Vector2i(x, y))
				ids.append(id)
	if ids.size() < 2:
		return
	for _attempt in range(20):
		ids.shuffle()
		_assign_echo_layout(sites, ids, false)
		if not check_fail():
			_assign_echo_layout(sites, ids, true)
			return
	var first := block_map.get(ids[0]) as MergeBlock
	var second := block_map.get(ids[1]) as MergeBlock
	if first and second:
		second.level = first.level
	_assign_echo_layout(sites, ids, true)


func _assign_echo_layout(sites: Array[Vector2i], ids: Array[int], animate: bool) -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			index_map[y][x] = -1
	for i in range(mini(sites.size(), ids.size())):
		var site := sites[i]
		var id := ids[i]
		index_map[site.y][site.x] = id
		var block := block_map.get(id) as MergeBlock
		if block:
			block.board_site = site
			if animate:
				var tween := create_tween()
				tween.tween_property(block, "position", _position_for_site(site), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_skill_energy_changed(current: int, maximum: int) -> void:
	if energy_hud:
		energy_hud.set_energy(current, maximum)


func _on_energy_gain_requested(amount: int, source_global: Vector2, mote_count: int, bright: bool) -> void:
	if energy_hud:
		energy_hud.play_energy_gain(amount, source_global, mote_count, bright)
	else:
		skill_imprint_system.notify_fx_batch_finished()


func _on_normal_attack_kill(position: Vector2) -> void:
	if skill_imprint_system:
		skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_PER_KILL, position, 3, true)


func _on_pending_skill_changed(skill_id: String, quality: int) -> void:
	if energy_hud:
		energy_hud.set_pending_skill(skill_id, quality)


func _on_skill_choice_requested() -> void:
	_skill_choice_pending = true
	_try_open_card_choice()


func _on_wave_cleared(wave_index: int) -> void:
	_wave_reward_pending = GameConfig.MILESTONE_ENTRY_WAVES.has(wave_index + 2)
	_wave_waiting_to_continue = true
	_try_open_card_choice()


func _try_open_card_choice() -> void:
	if active_card_modal != null or game_status == GameStatus.OVER or modal_layer == null:
		return
	var kind := ""
	var ids: Array[String] = []
	var qualities: Array[int] = []
	var skill_target := energy_hud.get_skill_target_global() if energy_hud else Vector2.ZERO
	var crystal_target := combat_system.crystal_system.get_crystal_center_global() if combat_system and combat_system.crystal_system else Vector2.ZERO
	if _wave_reward_pending:
		kind = "milestone"
		_wave_reward_pending = false
	elif _skill_choice_pending:
		kind = "energy"
		_skill_choice_pending = false
	else:
		if _wave_waiting_to_continue and combat_system:
			# 同一结算时刻已经满能量但光点尚未抵达：等待技能选择请求，
			# 严格保持“水晶强化 -> 技能选择 -> 下一波”。
			if skill_imprint_system and skill_imprint_system.is_full_waiting_for_choice():
				return
			_wave_waiting_to_continue = false
			combat_system.continue_after_wave_reward()
		return
	var draw := _draw_unified_cards(kind)
	ids = draw["ids"]
	qualities = draw["qualities"]
	active_card_modal = CardChoiceModalScene.new() as CardChoiceModal
	modal_layer.add_child(active_card_modal)
	active_card_modal.choice_committed.connect(_on_card_choice_committed)
	active_card_modal.modal_closed.connect(_on_card_modal_closed)
	active_card_modal.setup(kind, ids, skill_target, crystal_target, qualities)


func _on_card_choice_committed(kind: String, card_id: String, element_key: String, quality: int) -> void:
	var is_crystal := GameConfig.CRYSTAL_CARD_IDS.has(card_id)
	if is_crystal and combat_system:
		combat_system.apply_crystal_upgrade(card_id, element_key, quality)
		if kind == "energy" and skill_imprint_system:
			skill_imprint_system.resolve_energy_without_skill()
	elif skill_imprint_system:
		if kind == "energy":
			skill_imprint_system.choose_skill(card_id, quality)
		else:
			skill_imprint_system.enqueue_skill(card_id, quality)


func _draw_unified_cards(source: String) -> Dictionary:
	var board_pool: Array = GameConfig.SKILL_CARD_IDS.duplicate()
	var crystal_pool: Array = GameConfig.CRYSTAL_CARD_IDS.duplicate()
	var ids: Array[String] = []
	if source == "milestone":
		crystal_pool.shuffle()
		ids.append(crystal_pool.pop_back())
		ids.append(crystal_pool.pop_back())
		var mixed_pool: Array = GameConfig.ALL_CARD_IDS.duplicate()
		mixed_pool.shuffle()
		for candidate in mixed_pool:
			if not ids.has(candidate):
				ids.append(candidate)
				break
	else:
		board_pool.shuffle()
		ids.append(board_pool.pop_back())
		ids.append(board_pool.pop_back())
		var mixed_pool: Array = GameConfig.ALL_CARD_IDS.duplicate()
		mixed_pool.shuffle()
		for candidate in mixed_pool:
			if not ids.has(candidate):
				ids.append(candidate)
				break
	ids.shuffle()
	var qualities: Array[int] = []
	for id in ids:
		qualities.append(_roll_card_quality(source, id))
	if source == "milestone":
		var has_epic_crystal := false
		for i in range(ids.size()):
			if GameConfig.CRYSTAL_CARD_IDS.has(ids[i]) and qualities[i] >= GameConfig.CARD_QUALITY_EPIC:
				has_epic_crystal = true
		if not has_epic_crystal:
			for i in range(ids.size()):
				if GameConfig.CRYSTAL_CARD_IDS.has(ids[i]):
					qualities[i] = GameConfig.CARD_QUALITY_EPIC
					break
	return {"ids": ids, "qualities": qualities}


func _roll_card_quality(source: String, card_id: String) -> int:
	var roll := randf()
	if source == "milestone":
		return GameConfig.CARD_QUALITY_EPIC if roll < 0.35 else GameConfig.CARD_QUALITY_RARE
	return GameConfig.CARD_QUALITY_EPIC if roll < 0.05 else (GameConfig.CARD_QUALITY_RARE if roll < 0.30 else GameConfig.CARD_QUALITY_COMMON)


func _on_card_modal_closed(_kind: String) -> void:
	active_card_modal = null
	call_deferred("_try_open_card_choice")


func _reset_card_runtime() -> void:
	get_tree().paused = false
	_manual_paused = false
	_wave_reward_pending = false
	_skill_choice_pending = false
	_wave_waiting_to_continue = false
	if active_card_modal and is_instance_valid(active_card_modal):
		active_card_modal.queue_free()
	active_card_modal = null
	if skill_imprint_system:
		skill_imprint_system.reset()
	if energy_hud:
		energy_hud.clear_fx()
		energy_hud.set_pending_skill("")

func _toggle_mute() -> void:
	muted = not muted
	_play_click()
	_update_mute_visual()

func _update_mute_visual() -> void:
	if music_button:
		music_button.modulate = Color(1, 1, 1, 0.45) if muted else Color.WHITE

func _play_click() -> void:
	if not muted and click_player and click_player.stream:
		click_player.play()

func _play_merge() -> void:
	if not muted and merge_player and merge_player.stream:
		merge_player.play()

func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("score", "best", 0))

func _save_best() -> void:
	var config := ConfigFile.new()
	config.set_value("score", "best", best_score)
	config.save(SAVE_PATH)
