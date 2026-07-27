extends Control

const MergeBlockScene := preload("res://scripts/block.gd")
const LoadingViewScene := preload("res://scenes/ui/loading_view.tscn")
const MainHubViewScene := preload("res://scenes/ui/main_hub.tscn")
const MergeTrailGhostScene := preload("res://scripts/merge_trail_ghost.gd")
const EnergyHudScene := preload("res://scripts/energy_hud.gd")
const CardChoiceModalScene := preload("res://scripts/card_choice_modal.gd")
const BoardShadowLayerScene := preload("res://scripts/board_shadow_layer.gd")
const BoardClusterLayoutScene := preload("res://scripts/board_cluster_layout.gd")
const SettlementViewScene := preload("res://scripts/settlement_view.gd")
const BalanceSimulationPanelScene := preload("res://scripts/simulation/balance_simulation_panel.gd")
const BoardRefillPolicyScript := preload("res://scripts/board_refill_policy.gd")
const FirstWaveTutorialControllerScene := preload("res://scripts/first_wave_tutorial_controller.gd")

const GRID_SIZE := GameConfig.GRID_SIZE
const BLOCK_SIZE := GameConfig.BLOCK_SIZE
const SAVE_PATH := GameConfig.SAVE_PATH
const START_DIRECTLY := false
const CLUSTER_SWAP_ITEM_ID := "cluster_swap"
const CLUSTER_SWAP_UNLIMITED_COUNT := -1
const CLUSTER_SWAP_ANIMATION_DURATION := 0.38
const CRYSTAL_RAIN_ITEM_ID := "crystal_rain"
const HUB_DEFAULT_CRYSTALS := 120
const HUB_DEFAULT_COINS := 1804
# Temporary review switch. Keep the saved completion state intact while making
# the awakening tutorial replay on every Start/Restart until visual review ends.
const REPEAT_FIRST_WAVE_TUTORIAL := true

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
var main_hub_view: MainHubView
var game_layer: Control
var battle_background: TextureRect
var board_layer: Control
var board_shadow_layer: BoardShadowLayer
var popup_layer: Control
var score_label: Label
var best_label: Label
var click_player: AudioStreamPlayer
var merge_player: AudioStreamPlayer
var _combo_audio_players: Array[AudioStreamPlayer] = []
var _combo_audio_cursor := 0
var _combo_attack_counts := {}
var combat_system: CombatSystem
var music_button: TextureButton
var bottom_ui: Control
var _manual_paused := false
var merge_frames: Array[Texture2D] = []
var skill_imprint_system: SkillImprintSystem
var energy_hud: EnergyHud
var modal_layer: Control
var active_card_modal: CardChoiceModal
var _wave_reward_pending := false
var _skill_choice_pending := false
var _wave_waiting_to_continue := false
var _board_settlement_active := false
var _success_popup_active := false
var _card_levels: Dictionary = {}
var _seen_card_ids: Array[String] = []
var _run_merge_count := 0
var _run_max_merge_size := 0
var _best_score_at_run_start := 0
var _run_card_counts: Dictionary = {}
var _run_card_levels: Dictionary = {}
var _run_card_order: Array[String] = []
var _cluster_swap_item_count := 0
var _crystal_rain_busy := false
var _instant_item_generation := 0
var _balance_simulation_panel: BalanceSimulationPanel
var _first_wave_tutorial: FirstWaveTutorialController
var _crystal_awakened_unlocked := false
var _first_wave_tutorial_completed := false


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

	for i in range(13):
		merge_frames.append(load("res://assets/runtime/fx/merge/frame_%02d.png" % i) as Texture2D)

	var paths: Dictionary[String, String] = {
		"bg": "res://assets/runtime/ui/screens/login/login_background.png",
		"game_bg": "res://assets/runtime/ui/common/legacy_game_background.png",
		"restart": "res://assets/runtime/ui/common/button_restart.png",
		"refresh": "res://assets/runtime/ui/common/button_refresh.png",
		"back": "res://assets/runtime/ui/common/button_back.png",
		"music": "res://assets/runtime/ui/common/button_sound.png",
		"panel": "res://assets/runtime/ui/common/popup_panel.png",
		"success": "res://assets/runtime/ui/common/legacy_success_panel.png",
		"continue": "res://assets/runtime/ui/common/button_continue.png",
		"new_record": "res://assets/runtime/ui/common/legacy_new_record.png",
		"crown": "res://assets/runtime/ui/common/icon_crown.png",
		"light": "res://assets/runtime/ui/common/success_light.png",
		"esc": "res://assets/runtime/ui/common/button_close.png",
		"slice_board_panel": "res://assets/runtime/ui/battle/board/board_backplate.png",
		"battle_scene_bg": "res://assets/runtime/ui/battle/core/battle_background.png",
		"bottom_bg": "res://assets/runtime/ui/battle/bottom_hud/hud_background.png"
	}
	for key in paths:
		ui_textures[key] = load(paths[key]) as Texture2D

func _build_scene() -> void:
	background = _make_texture_rect(ui_textures["bg"])
	add_child(background)

	main_layer = Control.new()
	main_layer.name = "MainMenu"
	main_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_layer)
	loading_view = LoadingViewScene.instantiate() as LoadingView
	loading_view.name = "LoadingView"
	loading_view.play_pressed.connect(_on_play_pressed)
	loading_view.simulation_pressed.connect(_show_balance_simulation)
	loading_view.intro_finished.connect(_on_title_intro_finished)
	main_layer.add_child(loading_view)
	main_hub_view = MainHubViewScene.instantiate() as MainHubView
	main_hub_view.name = "MainHubView"
	main_hub_view.stage_pressed.connect(_on_hub_stage_pressed)
	main_hub_view.settings_pressed.connect(_on_hub_settings_pressed)
	main_hub_view.set_resource_values(HUB_DEFAULT_CRYSTALS, HUB_DEFAULT_COINS)
	main_hub_view.visible = false
	main_layer.add_child(main_hub_view)

	game_layer = Control.new()
	game_layer.name = "Game"
	game_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	game_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(game_layer)

	popup_layer = Control.new()
	popup_layer.name = "Popups"
	popup_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_layer.z_as_relative = false
	popup_layer.z_index = 200
	popup_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(popup_layer)

	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	add_child(combat_system)
	combat_system.setup(game_layer)
	combat_system.castle_destroyed.connect(_on_castle_destroyed)
	combat_system.castle_durability_changed.connect(_on_castle_durability_changed)
	combat_system.back_pressed.connect(_toggle_manual_pause)
	var top_home_button := combat_system.battle_layer.get_node_or_null("DesignRoot/HudLayer/HomeButton") as TextureButton
	music_button = combat_system.battle_layer.get_node_or_null("DesignRoot/HudLayer/MusicButton") as TextureButton
	if top_home_button:
		top_home_button.pressed.connect(over_game)
	if music_button:
		music_button.pressed.connect(_toggle_mute)
	combat_system.normal_attack_kill.connect(_on_normal_attack_kill)
	combat_system.merge_attack_received.connect(func(event: MergeAttackEvent): _combo_attack_counts[event.sequence_id] = event.attack_count)
	combat_system.merge_shot_resolved.connect(_on_merge_shot_resolved)
	combat_system.merge_sequence_finished.connect(func(sequence_id: int, _fired_count: int): _combo_attack_counts.erase(sequence_id))
	combat_system.wave_cleared.connect(_on_wave_cleared)
	combat_system.level_completed.connect(func(): end_game(true))
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
	board_layer.z_index = 8
	board_layer.custom_minimum_size = GameConfig.get_board_size()
	board_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board_layer.clip_contents = true
	game_layer.add_child(board_layer)

	board_shadow_layer = BoardShadowLayerScene.new() as BoardShadowLayer
	board_shadow_layer.name = "GlobalBlockShadow"
	board_shadow_layer.z_as_relative = false
	board_shadow_layer.z_index = 7
	board_layer.add_child(board_shadow_layer)
	board_shadow_layer.configure(GameConfig.get_board_size())
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
	energy_hud.instant_item_pressed.connect(_on_instant_item_pressed)

	_build_bottom_ui()

	modal_layer = Control.new()
	modal_layer.name = "CardModalLayer"
	modal_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_layer.z_index = 120
	modal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(modal_layer)

	click_player = AudioStreamPlayer.new()
	click_player.stream = load("res://assets/runtime/audio/click.mp3")
	add_child(click_player)

	merge_player = AudioStreamPlayer.new()
	merge_player.stream = load("res://assets/runtime/audio/merge.mp3")
	add_child(merge_player)
	for player_index in range(4):
		var combo_player := AudioStreamPlayer.new()
		combo_player.name = "ComboAttackAudio%d" % (player_index + 1)
		combo_player.stream = merge_player.stream
		add_child(combo_player)
		_combo_audio_players.append(combo_player)

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
	if main_hub_view:
		main_hub_view.layout_for_viewport(viewport_size)

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
	var board_anchor_pos := GameConfig.BOARD_GRID_POS
	var board_pos := board_anchor_pos + GameConfig.BOARD_VISUAL_OFFSET
	var combat_board_pos := Vector2(
		board_anchor_pos.x,
		GameConfig.PATH_ROAD_TARGET_BOTTOM_Y - board_size.y * 0.5 - road_size.y * 0.5 - GameConfig.PATH_ROAD_OFFSET.y
	)
	_set_rect(board_layer, board_pos, board_size)
	if board_shadow_layer:
		board_shadow_layer.configure(board_size)
	if combat_system:
		combat_system.layout_for_board(combat_board_pos, board_size, board_pos)
	_set_rect(game_layer.get_node("BoardBackdrop") as Control, GameConfig.get_board_plate_position(board_pos), GameConfig.get_board_backdrop_size())
	_set_rect(score_label, Vector2(31, design_size.y - 68.0), Vector2(190, 55))
	_set_rect(best_label, Vector2(design_size.x - 231.0, design_size.y - 61.0), Vector2(200, 42))
	if bottom_ui:
		_set_rect(bottom_ui, Vector2(0, 1360), Vector2(941, 312))
	if energy_hud:
		_set_rect(energy_hud, Vector2((design_size.x - 913.0) * 0.5, 1414.0), Vector2(913, 210))
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
	_set_rect(background_art, Vector2.ZERO, Vector2(941, 312))
	bottom_ui.add_child(background_art)

func _toggle_manual_pause() -> void:
	if game_layer == null or not game_layer.visible:
		return
	if _first_wave_tutorial and _first_wave_tutorial.is_active():
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
	background.visible = false
	main_layer.visible = true
	game_layer.visible = false
	popup_layer.visible = false
	_clear_popup()
	_update_mute_visual()
	if loading_view:
		loading_view.stop_animations()
		loading_view.visible = false
	if main_hub_view:
		main_hub_view.set_resource_values(HUB_DEFAULT_CRYSTALS, HUB_DEFAULT_COINS)
		main_hub_view.set_muted(muted)
		main_hub_view.show_menu()

func show_loading() -> void:
	game_status = GameStatus.NONE
	background.visible = true
	main_layer.visible = true
	game_layer.visible = false
	popup_layer.visible = false
	if main_hub_view:
		main_hub_view.hide_menu()
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
	show_main_menu()


func _on_hub_stage_pressed(stage_number: int) -> void:
	if stage_number != 1:
		return
	_play_click()
	start_game()


func _on_hub_settings_pressed() -> void:
	_toggle_mute()


func _show_balance_simulation() -> void:
	if _balance_simulation_panel and is_instance_valid(_balance_simulation_panel):
		return
	_play_click()
	if loading_view:
		loading_view.set_interactive(false)
	_balance_simulation_panel = BalanceSimulationPanelScene.new() as BalanceSimulationPanel
	_balance_simulation_panel.name = "BalanceSimulationPanel"
	add_child(_balance_simulation_panel)
	_balance_simulation_panel.closed.connect(func():
		_balance_simulation_panel = null
		if loading_view and main_layer and main_layer.visible:
			loading_view.set_interactive(true)
	)

func start_game() -> void:
	_combo_attack_counts.clear()
	_reset_card_runtime()
	_grant_starting_instant_items()
	var tutorial_mode := REPEAT_FIRST_WAVE_TUTORIAL or not _first_wave_tutorial_completed
	if loading_view:
		loading_view.stop_animations()
		loading_view.visible = false
	if main_hub_view:
		main_hub_view.hide_menu()
	background.visible = false
	main_layer.visible = false
	game_layer.visible = true
	popup_layer.visible = true
	game_layer.modulate = Color(1, 1, 1, 0)
	_clear_game_world()
	_reset_run_statistics()
	score = 0
	_update_score_label()
	first_create_blocks(tutorial_mode)
	if tutorial_mode:
		_create_first_wave_tutorial()
	if combat_system:
		combat_system.start_run(tutorial_mode)
	game_status = GameStatus.PAUSE
	_animate_game_in()
	await get_tree().create_timer(1.35).timeout
	if game_status == GameStatus.PAUSE:
		if _first_wave_tutorial:
			_first_wave_tutorial.start()
		game_status = GameStatus.START

func replay_game() -> void:
	_play_click()
	_reset_card_runtime()
	_grant_starting_instant_items()
	game_status = GameStatus.PAUSE
	_clear_popup()
	_clear_game_world()
	_reset_run_statistics()
	var tutorial_mode := REPEAT_FIRST_WAVE_TUTORIAL or not _first_wave_tutorial_completed
	score = 0
	_update_score_label()
	first_create_blocks(tutorial_mode)
	if tutorial_mode:
		_create_first_wave_tutorial()
	if combat_system:
		combat_system.start_run(tutorial_mode)
	_animate_game_in()
	await get_tree().create_timer(1.35).timeout
	if game_status == GameStatus.PAUSE:
		if _first_wave_tutorial:
			_first_wave_tutorial.start()
		game_status = GameStatus.START

func over_game() -> void:
	_play_click()
	_reset_card_runtime()
	if combat_system:
		combat_system.stop_run()
	_clear_popup()
	_clear_game_world()
	show_main_menu()

func first_create_blocks(tutorial_mode: bool = false) -> void:
	_reset_index_map()
	var tutorial_board: Array[Array] = [
		[2, 2, 2, 2, 2],
		[2, 1, 1, 1, 3],
		[3, 2, 2, 2, 2],
		[3, 2, 3, 2, 3],
		[2, 1, 3, 3, 3],
	]
	var order := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var level := int(tutorial_board[y][x]) if tutorial_mode else randi_range(1, 3)
			_create_block(Vector2i(x, y), level, true, order * 0.04)
			order += 1
	if not tutorial_mode:
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
	if _first_wave_tutorial and _first_wave_tutorial.is_active() and not _first_wave_tutorial.can_interact_with_site(block.board_site):
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
	_board_settlement_active = true

	var merge_group: Array[MergeBlock] = []
	for block in selected_blocks:
		merge_group.append(block)
	var board_highest_before_merge := _get_board_highest_level()
	var prepared_skill: Dictionary = skill_imprint_system.consume_pending_skill() if skill_imprint_system else {}
	var triggered_imprints: Array[Dictionary] = []
	if not clicked.skill_imprint_id.is_empty():
		var clicked_imprint := clicked.take_skill_imprint()
		clicked_imprint["trigger_level"] = clicked.level
		triggered_imprints.append(clicked_imprint)
	for block in merge_group:
		if block != clicked and not block.skill_imprint_id.is_empty():
			var block_imprint := block.take_skill_imprint()
			block_imprint["trigger_level"] = block.level
			triggered_imprints.append(block_imprint)

	var merged_count: int = merge_group.size()
	_run_merge_count += 1
	_run_max_merge_size = maxi(_run_max_merge_size, merged_count)
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
	if _first_wave_tutorial and _first_wave_tutorial.is_active():
		_first_wave_tutorial.notify_merge_completed()
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

	_board_settlement_active = false
	if game_status == GameStatus.PAUSE and not _success_popup_active:
		game_status = GameStatus.START
	call_deferred("_try_open_card_choice")

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
	var moved_existing_block := false
	for x in range(GRID_SIZE):
		var write_y := 0
		for y in range(GRID_SIZE):
			var block := _block_at(Vector2i(x, y))
			if block == null:
				continue
			if y != write_y:
				_move_block_to(block, Vector2i(x, write_y))
				moved_existing_block = true
			write_y += 1
	# Finish compacting the surviving blocks before new blocks enter from the
	# top. Running both tween groups together can visually freeze overlapping
	# blocks when a card modal pauses the tree mid-settlement.
	if moved_existing_block:
		await get_tree().create_timer(0.14).timeout

	var created_block := false
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if index_map[y][x] == -1:
				var site := Vector2i(x, y)
				_create_block(site, _sample_refill_level(site), true)
				created_block = true

	if created_block:
		await get_tree().create_timer(0.32).timeout
	_snap_blocks_to_grid()


func _sample_refill_level(site: Vector2i) -> int:
	var values: Array[int] = []
	values.resize(GRID_SIZE * GRID_SIZE)
	values.fill(0)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var block := _block_at(Vector2i(x, y))
			if block != null and is_instance_valid(block):
				values[y * GRID_SIZE + x] = block.level
	var historical_highest := maxi(1, current_level)
	return BoardRefillPolicyScript.sample_level(historical_highest, values, GRID_SIZE, site.y * GRID_SIZE + site.x, randf())


func _snap_blocks_to_grid() -> void:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var block := _block_at(Vector2i(x, y))
			if block and is_instance_valid(block):
				block.position = _position_for_site(block.board_site)

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
	if game_status == GameStatus.OVER:
		return
	game_status = GameStatus.OVER
	_reset_card_runtime()
	var settlement_stats := _collect_settlement_stats(_had_pass)
	if combat_system:
		combat_system.stop_run()
	_clear_merge_trails()
	_show_account_popup(_had_pass, settlement_stats)

func resurrect() -> void:
	_play_click()
	_clear_popup()
	game_status = GameStatus.PAUSE
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
	if combat_system:
		combat_system.start_run()
	# The defeat flow clears and disables instant items while the settlement is
	# open. Reviving resumes the same board, so restore both unlimited item slots
	# before returning control to the player.
	_grant_starting_instant_items()
	game_status = GameStatus.START

func _show_success_popup() -> void:
	_clear_popup()
	_success_popup_active = true
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
	continue_button.pressed.connect(_close_success_popup)
	_wire_button_anim(continue_button)
	popup.add_child(continue_button)

	var tween := create_tween()
	tween.parallel().tween_property(light, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(light, "rotation", TAU, 8.0).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property(popup, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close_success_popup() -> void:
	if not _success_popup_active:
		return
	_play_click()
	_clear_popup()
	if game_status == GameStatus.PAUSE and not _board_settlement_active:
		game_status = GameStatus.START
	call_deferred("_try_open_card_choice")

func _show_account_popup(won: bool, settlement_stats: Dictionary) -> void:
	_clear_popup()
	popup_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	var settlement := SettlementViewScene.new() as SettlementView
	settlement.name = "SettlementView"
	popup_layer.add_child(settlement)
	settlement.retry_pressed.connect(replay_game)
	settlement.revive_pressed.connect(resurrect)
	settlement.home_pressed.connect(over_game)
	settlement.setup(won, settlement_stats)


func _reset_run_statistics() -> void:
	_run_merge_count = 0
	_run_max_merge_size = 0
	_best_score_at_run_start = best_score
	_run_card_counts.clear()
	_run_card_levels.clear()
	_run_card_order.clear()


func _collect_settlement_stats(won: bool) -> Dictionary:
	var waves_cleared := 0
	var wave_total := 0
	var elapsed := 0.0
	var kills := 0
	var leaks := 0
	var castle := 0
	var castle_max := GameConfig.MAX_CASTLE_DURABILITY
	if combat_system:
		kills = combat_system.run_kills
		leaks = combat_system.run_leaks
		if combat_system.wave_system:
			waves_cleared = combat_system.wave_system.total_waves_cleared
			wave_total = combat_system.wave_system.waves.size()
		if combat_system.castle_system:
			castle = combat_system.castle_system.get_durability()
			castle_max = combat_system.castle_system.max_durability
		if combat_system.battle_layer:
			elapsed = combat_system.battle_layer.get_elapsed_seconds()
	var reward_coins := maxi(10, floori(float(score) / 20.0) + kills * 2 + waves_cleared * 10 + (100 if won else 0))
	var reward_crystals := maxi(1, waves_cleared + (16 if won else 0))
	return {
		"waves": waves_cleared,
		"wave_total": wave_total,
		"elapsed": elapsed,
		"score": score,
		"best": best_score,
		"new_record": score > _best_score_at_run_start,
		"highest": maxi(current_level, _get_board_highest_level()),
		"kills": kills,
		"merges": _run_merge_count,
		"max_merge": _run_max_merge_size,
		"castle": castle,
		"castle_max": castle_max,
		"leaks": leaks,
		"board_damage": 0,
		"crystal_damage": 0,
		"skill_damage": 0,
		"reward_coins": reward_coins,
		"reward_crystals": reward_crystals,
		"cards": _collect_run_cards(),
	}


func _collect_run_cards() -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	for card_id in _run_card_order:
		cards.append({
			"id": card_id,
			"level": clampi(int(_run_card_levels.get(card_id, 1)), 1, GameConfig.MAX_CARD_LEVEL),
			"selections": maxi(1, int(_run_card_counts.get(card_id, 1))),
		})
	return cards

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
	_success_popup_active = false
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
		var level := clampi(int(imprint.get("quality", 1)), 1, GameConfig.MAX_CARD_LEVEL)
		var trigger_level := clampi(int(imprint.get("trigger_level", result_block.level - 1)), 1, GameConfig.MAX_BLOCK_LEVEL)
		match skill_id:
			"ascension_hammer":
				result_block.level = mini(GameConfig.MAX_BLOCK_LEVEL, result_block.level + int(GameConfig.ASCENSION_EXTRA_LEVELS[level - 1]))
			"unity_dial":
				_apply_unity_dial(result_block, trigger_level)
			"fate_shuffler":
				_apply_board_echo(level)
			"twin_mold":
				_apply_twin_mold(result_block, int(GameConfig.TWIN_MOLD_TARGETS[level - 1]))
			"castle_cannon":
				if combat_system:
					combat_system.trigger_card_attack(skill_id, result_block.level, level, result_block.global_position + result_block.size * 0.5)
			"dragon_catapult":
				if combat_system:
					combat_system.trigger_card_attack(skill_id, result_block.level, level, result_block.global_position + result_block.size * 0.5)
		await get_tree().create_timer(0.08).timeout


func _active_blocks() -> Array[MergeBlock]:
	var result: Array[MergeBlock] = []
	for value in block_map.values():
		var block := value as MergeBlock
		if block and is_instance_valid(block):
			result.append(block)
	return result


func _on_instant_item_pressed(item_id: String) -> void:
	match item_id:
		CLUSTER_SWAP_ITEM_ID:
			await _use_cluster_swap_item()
		CRYSTAL_RAIN_ITEM_ID:
			await _use_crystal_rain_item()


func _use_crystal_rain_item() -> void:
	if _crystal_rain_busy:
		return
	if game_status != GameStatus.START or active_card_modal != null:
		return
	if get_tree().paused or combat_system == null:
		return
	var sequence_duration := combat_system.trigger_crystal_rain()
	if sequence_duration <= 0.0:
		return

	_play_click()
	_crystal_rain_busy = true
	var use_generation := _instant_item_generation
	if energy_hud:
		energy_hud.play_crystal_rain_used()
		energy_hud.set_crystal_rain_enabled(false)
	await get_tree().create_timer(sequence_duration + 0.02).timeout
	if use_generation != _instant_item_generation:
		return
	_crystal_rain_busy = false
	if energy_hud and game_layer and game_layer.visible and game_status != GameStatus.OVER:
		energy_hud.set_crystal_rain_enabled(true)


func _use_cluster_swap_item() -> void:
	if _cluster_swap_item_count == 0:
		return
	if game_status != GameStatus.START or _board_settlement_active or active_card_modal != null:
		return
	if get_tree().paused:
		return

	_play_click()
	game_status = GameStatus.PAUSE
	_board_settlement_active = true
	for block in selected_blocks:
		if block and is_instance_valid(block):
			block.selected = false
	selected_blocks.clear()

	var moved_count := _apply_cluster_swap_layout()
	if moved_count <= 0:
		_board_settlement_active = false
		if game_status == GameStatus.PAUSE:
			game_status = GameStatus.START
		return

	if _cluster_swap_item_count > 0:
		_cluster_swap_item_count -= 1
	if energy_hud:
		energy_hud.play_cluster_swap_used()
		energy_hud.set_cluster_swap_count(_cluster_swap_item_count)
	await get_tree().create_timer(CLUSTER_SWAP_ANIMATION_DURATION).timeout
	_snap_blocks_to_grid()
	_board_settlement_active = false
	if game_status == GameStatus.PAUSE:
		game_status = GameStatus.START
	call_deferred("_try_open_card_choice")


func _apply_cluster_swap_layout() -> int:
	var blocks := _active_blocks()
	if blocks.size() < 2:
		return 0
	blocks.sort_custom(func(first: MergeBlock, second: MergeBlock):
		return first.board_site.y * GRID_SIZE + first.board_site.x < second.board_site.y * GRID_SIZE + second.board_site.x
	)

	var levels: Array[int] = []
	var current_layout: Array[int] = []
	current_layout.resize(GRID_SIZE * GRID_SIZE)
	current_layout.fill(-1)
	var blocks_by_level: Dictionary = {}
	for block in blocks:
		levels.append(block.level)
		current_layout[block.board_site.y * GRID_SIZE + block.board_site.x] = block.level
		if not blocks_by_level.has(block.level):
			blocks_by_level[block.level] = []
		var group: Array = blocks_by_level[block.level]
		group.append(block)
		blocks_by_level[block.level] = group

	var target_layout: Array[int] = BoardClusterLayoutScene.build_clustered_levels(levels, GRID_SIZE)
	var current_cluster_score := BoardClusterLayoutScene.count_equal_neighbors(current_layout, GRID_SIZE)
	var target_cluster_score := BoardClusterLayoutScene.count_equal_neighbors(target_layout, GRID_SIZE)
	if target_layout == current_layout or target_cluster_score <= current_cluster_score:
		return 0

	var assignments: Array[Dictionary] = []
	for cell_index in range(target_layout.size()):
		var target_level := target_layout[cell_index]
		if target_level < 0 or not blocks_by_level.has(target_level):
			continue
		var target_site := Vector2i(cell_index % GRID_SIZE, floori(float(cell_index) / float(GRID_SIZE)))
		var candidates: Array = blocks_by_level[target_level]
		var nearest_index := 0
		var nearest_distance := 1000000
		for candidate_index in range(candidates.size()):
			var candidate := candidates[candidate_index] as MergeBlock
			var delta := candidate.board_site - target_site
			var distance := absi(delta.x) + absi(delta.y)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_index = candidate_index
		var chosen := candidates[nearest_index] as MergeBlock
		candidates.remove_at(nearest_index)
		blocks_by_level[target_level] = candidates
		assignments.append({"block": chosen, "site": target_site, "old_site": chosen.board_site})

	var block_ids: Dictionary = {}
	for id_value in block_map.keys():
		var mapped_block := block_map.get(id_value) as MergeBlock
		if mapped_block and is_instance_valid(mapped_block):
			block_ids[mapped_block.get_instance_id()] = int(id_value)

	_reset_index_map()
	var moves: Array[Dictionary] = []
	for assignment in assignments:
		var block := assignment["block"] as MergeBlock
		var site: Vector2i = assignment["site"]
		var old_site: Vector2i = assignment["old_site"]
		var block_id := int(block_ids.get(block.get_instance_id(), -1))
		if block_id < 0:
			continue
		index_map[site.y][site.x] = block_id
		block.board_site = site
		if old_site != site:
			moves.append({"block": block, "site": site})

	for move_index in range(moves.size()):
		var move: Dictionary = moves[move_index]
		var block := move["block"] as MergeBlock
		var site: Vector2i = move["site"]
		var tween := create_tween()
		tween.tween_interval(minf(0.06, float(move_index) * 0.003))
		tween.tween_property(block, "position", _position_for_site(site), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	return moves.size()


func _get_board_highest_level() -> int:
	var highest := 0
	for block in _active_blocks():
		highest = maxi(highest, block.level)
	return highest


func _is_new_highest_merge_result(result_level: int, highest_before_merge: int) -> bool:
	return result_level > highest_before_merge


func _apply_unity_dial(result_block: MergeBlock, recorded_level: int) -> void:
	var blocks := _active_blocks()
	if blocks.is_empty():
		return
	var max_level := 1
	for block in blocks:
		max_level = maxi(max_level, block.level)
	for block in blocks:
		if block != result_block and block.level < max_level:
			block.level = clampi(recorded_level, 1, GameConfig.MAX_BLOCK_LEVEL)


func _apply_twin_mold(result_block: MergeBlock, target_count: int) -> void:
	var candidates: Array[MergeBlock] = []
	var origin := result_block.board_site
	var offsets: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
	for offset in offsets:
		var site: Vector2i = origin + offset
		if site.x < 0 or site.y < 0 or site.x >= GRID_SIZE or site.y >= GRID_SIZE:
			continue
		var neighbor := _block_at(site)
		if neighbor and neighbor != result_block and neighbor.level < GameConfig.MAX_BLOCK_LEVEL:
			candidates.append(neighbor)
	if candidates.is_empty():
		for block in _active_blocks():
			if block != result_block and block.level < GameConfig.MAX_BLOCK_LEVEL:
				candidates.append(block)
	candidates.sort_custom(func(a: MergeBlock, b: MergeBlock): return a.level < b.level)
	for i in range(mini(target_count, candidates.size())):
		candidates[i].level = result_block.level


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
		# One defeated monster produces one visible mote. The single mote carries
		# the full energy reward, so this only simplifies the visual feedback.
		skill_imprint_system.add_energy(GameConfig.SKILL_ENERGY_PER_KILL, position, 1, true)


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
	if _board_settlement_active or _success_popup_active:
		return
	if _first_wave_tutorial and _first_wave_tutorial.is_active():
		return
	if active_card_modal != null or game_status == GameStatus.OVER or modal_layer == null:
		return
	var kind := ""
	var ids: Array[String] = []
	var levels: Array[int] = []
	var new_flags: Array[bool] = []
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
	var seen_changed := false
	for id in ids:
		var current_level := clampi(int(_card_levels.get(id, 0)), 0, GameConfig.MAX_CARD_LEVEL)
		levels.append(clampi(current_level + 1, 1, GameConfig.MAX_CARD_LEVEL))
		var first_seen := not _seen_card_ids.has(id)
		new_flags.append(first_seen)
		if first_seen:
			_seen_card_ids.append(id)
			seen_changed = true
	if seen_changed:
		_save_progress()
	active_card_modal = CardChoiceModalScene.new() as CardChoiceModal
	modal_layer.add_child(active_card_modal)
	active_card_modal.choice_committed.connect(_on_card_choice_committed)
	active_card_modal.modal_closed.connect(_on_card_modal_closed)
	active_card_modal.setup(kind, ids, skill_target, crystal_target, levels, new_flags)


func _on_card_choice_committed(kind: String, card_id: String, element_key: String, level: int) -> void:
	var applied_level := clampi(level, 1, GameConfig.MAX_CARD_LEVEL)
	_card_levels[card_id] = maxi(int(_card_levels.get(card_id, 0)), applied_level)
	if not _run_card_counts.has(card_id):
		_run_card_order.append(card_id)
	_run_card_counts[card_id] = int(_run_card_counts.get(card_id, 0)) + 1
	_run_card_levels[card_id] = applied_level
	_save_progress()
	var is_crystal := CardCatalog.is_crystal_card(card_id)
	if is_crystal and combat_system:
		combat_system.apply_crystal_upgrade(card_id, element_key, applied_level)
		if kind == "energy" and skill_imprint_system:
			skill_imprint_system.resolve_energy_without_skill()
	elif skill_imprint_system:
		if kind == "energy":
			skill_imprint_system.choose_skill(card_id, applied_level)
		else:
			skill_imprint_system.enqueue_skill(card_id, applied_level)


func _draw_unified_cards(source: String) -> Dictionary:
	var board_pool: Array = GameConfig.SKILL_CARD_IDS.duplicate()
	var crystal_pool: Array = GameConfig.CRYSTAL_CARD_IDS.duplicate()
	var ids: Array[String] = []
	if source == "milestone":
		crystal_pool.shuffle()
		for i in range(mini(2, crystal_pool.size())):
			ids.append(crystal_pool.pop_back())
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
	return {"ids": ids}


func _on_card_modal_closed(_kind: String) -> void:
	active_card_modal = null
	call_deferred("_try_open_card_choice")


func _reset_card_runtime() -> void:
	_stop_first_wave_tutorial()
	_instant_item_generation += 1
	_crystal_rain_busy = false
	get_tree().paused = false
	_manual_paused = false
	_board_settlement_active = false
	_success_popup_active = false
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
	_cluster_swap_item_count = 0
	if energy_hud:
		energy_hud.set_cluster_swap_count(0)
		energy_hud.set_crystal_rain_enabled(false)


func _grant_starting_instant_items() -> void:
	_cluster_swap_item_count = CLUSTER_SWAP_UNLIMITED_COUNT
	if energy_hud:
		energy_hud.set_cluster_swap_count(_cluster_swap_item_count)
		energy_hud.set_crystal_rain_enabled(true)


func _create_first_wave_tutorial() -> void:
	_stop_first_wave_tutorial()
	if combat_system == null or modal_layer == null:
		return
	_first_wave_tutorial = FirstWaveTutorialControllerScene.new() as FirstWaveTutorialController
	_first_wave_tutorial.name = "FirstWaveTutorialController"
	add_child(_first_wave_tutorial)
	var first_position := _position_for_site(Vector2i(1, 1))
	var last_position := _position_for_site(Vector2i(3, 1))
	var highlight_rect := Rect2(
		board_layer.position + first_position,
		(last_position - first_position) + Vector2(BLOCK_SIZE, BLOCK_SIZE)
	)
	var board_rect := Rect2(board_layer.position, board_layer.size)
	var crystal_anchor := combat_system.battle_layer.get_crystal_tutorial_anchor()
	_first_wave_tutorial.setup(combat_system, modal_layer, board_rect, highlight_rect, crystal_anchor)
	_first_wave_tutorial.awakening_committed.connect(_on_tutorial_awakening_committed)
	_first_wave_tutorial.instant_items_locked.connect(_on_tutorial_items_locked)
	_first_wave_tutorial.finished.connect(_on_first_wave_tutorial_finished)


func _stop_first_wave_tutorial() -> void:
	if _first_wave_tutorial == null:
		return
	var tutorial := _first_wave_tutorial
	_first_wave_tutorial = null
	if is_instance_valid(tutorial):
		tutorial.stop()
		tutorial.queue_free()


func _on_tutorial_items_locked(locked: bool) -> void:
	if locked:
		_cluster_swap_item_count = 0
		_crystal_rain_busy = false
		if energy_hud:
			energy_hud.set_cluster_swap_count(0)
			energy_hud.set_crystal_rain_enabled(false)
	else:
		_grant_starting_instant_items()


func _on_tutorial_awakening_committed() -> void:
	_crystal_awakened_unlocked = true
	_first_wave_tutorial_completed = true
	_save_progress()


func _on_first_wave_tutorial_finished(_skipped: bool) -> void:
	var tutorial := _first_wave_tutorial
	_first_wave_tutorial = null
	if tutorial and is_instance_valid(tutorial):
		tutorial.queue_free()
	call_deferred("_try_open_card_choice")

func _toggle_mute() -> void:
	muted = not muted
	_play_click()
	_update_mute_visual()

func _update_mute_visual() -> void:
	if music_button:
		music_button.modulate = Color(1, 1, 1, 0.45) if muted else Color.WHITE
	if main_hub_view:
		main_hub_view.set_muted(muted)

func _play_click() -> void:
	if not muted and click_player and click_player.stream:
		click_player.play()

func _play_merge() -> void:
	if not muted and merge_player and merge_player.stream:
		merge_player.play()


func _on_merge_shot_resolved(sequence_id: int, shot_index: int, _target: Monster, _damage: float, killed: bool) -> void:
	if muted or _combo_audio_players.is_empty():
		return
	var total := maxi(1, int(_combo_attack_counts.get(sequence_id, shot_index + 1)))
	var player := _combo_audio_players[_combo_audio_cursor % _combo_audio_players.size()]
	_combo_audio_cursor += 1
	player.stop()
	player.pitch_scale = 1.0 + minf(0.12, float(shot_index) * 0.025)
	if killed or shot_index >= total - 1:
		player.volume_db = -13.0
	elif shot_index == 0:
		player.volume_db = -16.0
	else:
		player.volume_db = -23.0
	player.play()

func _load_save() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("score", "best", 0))
		var saved_levels: Dictionary = config.get_value("cards", "levels", {}) as Dictionary
		for card_id in CardCatalog.ALL_CARD_IDS:
			_card_levels[card_id] = clampi(int(saved_levels.get(card_id, 0)), 0, GameConfig.MAX_CARD_LEVEL)
		var saved_seen: Array = config.get_value("cards", "seen_ids", []) as Array
		for value in saved_seen:
			var card_id := str(value)
			if CardCatalog.ALL_CARD_IDS.has(card_id) and not _seen_card_ids.has(card_id):
				_seen_card_ids.append(card_id)
		var has_existing_progress := best_score > 0 or not _seen_card_ids.is_empty()
		if not has_existing_progress:
			for value in _card_levels.values():
				if int(value) > 0:
					has_existing_progress = true
					break
		var has_tutorial_flag := config.has_section_key("tutorial", "first_wave_awakening_completed")
		var has_awakened_flag := config.has_section_key("progression", "crystal_awakened")
		_first_wave_tutorial_completed = bool(config.get_value(
			"tutorial", "first_wave_awakening_completed", has_existing_progress
		)) if has_tutorial_flag else has_existing_progress
		_crystal_awakened_unlocked = bool(config.get_value(
			"progression", "crystal_awakened", has_existing_progress
		)) if has_awakened_flag else has_existing_progress
		if _first_wave_tutorial_completed or _crystal_awakened_unlocked:
			_first_wave_tutorial_completed = true
			_crystal_awakened_unlocked = true
		if (not has_tutorial_flag or not has_awakened_flag) and has_existing_progress:
			_save_progress()
	else:
		for card_id in CardCatalog.ALL_CARD_IDS:
			_card_levels[card_id] = 0
		_first_wave_tutorial_completed = false
		_crystal_awakened_unlocked = false

func _save_best() -> void:
	_save_progress()


func _save_progress() -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("score", "best", best_score)
	config.set_value("cards", "levels", _card_levels)
	config.set_value("cards", "seen_ids", _seen_card_ids)
	config.set_value("progression", "crystal_awakened", _crystal_awakened_unlocked)
	config.set_value("tutorial", "first_wave_awakening_completed", _first_wave_tutorial_completed)
	config.save(SAVE_PATH)
