extends Control

const MergeBlockScene := preload("res://scripts/block.gd")

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

var normal_textures: Array[Texture2D] = []
var selected_textures: Array[Texture2D] = []
var ui_textures: Dictionary[String, Texture2D] = {}

var background: TextureRect
var loading_layer: Control
var main_layer: Control
var game_layer: Control
var board_layer: Control
var decor_layer: Control
var popup_layer: Control
var score_label: Label
var best_label: Label
var click_player: AudioStreamPlayer
var merge_player: AudioStreamPlayer
var combat_system: CombatSystem
var music_button: TextureButton
var play_button: TextureButton
var logo_node: TextureRect
var loading_bar: ColorRect
var loading_label: Label
var merge_effect: TextureRect

func _ready() -> void:
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
	for level_index in range(1, 11):
		var key := "%02d" % level_index
		normal_textures.append(load("res://assets/textrues/mian/plate_%s_down.png" % key))
		selected_textures.append(load("res://assets/textrues/mian/plate_%s_up.png" % key))

	var paths: Dictionary[String, String] = {
		"bg": "res://assets/textrues/bg/bg_01.jpg",
		"bg_03": "res://assets/textrues/bg/bg_03.png",
		"bg_04": "res://assets/textrues/bg/bg_04.png",
		"bg_05": "res://assets/textrues/bg/bg_05.png",
		"loading_bg": "res://assets/textrues/UILoadingPanel/bg01.jpg",
		"loading_logo": "res://assets/textrues/UILoadingPanel/logo.png",
		"loading_item_01": "res://assets/textrues/UILoadingPanel/item01.png",
		"loading_item_02": "res://assets/textrues/UILoadingPanel/item02.png",
		"game_bg": "res://assets/textrues/mian/bg_02.png",
		"logo": "res://assets/textrues/mian/logo.png",
		"title": "res://assets/textrues/mian/Block Puzzle the number to 10.png",
		"play": "res://assets/textrues/mian/play.png",
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
		"esc": "res://assets/textrues/mian/esc.png"
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

	loading_layer = Control.new()
	loading_layer.name = "Loading"
	loading_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	loading_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(loading_layer)
	_build_loading_layer()

	main_layer = Control.new()
	main_layer.name = "MainMenu"
	main_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(main_layer)

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

	logo_node = _make_texture_rect(ui_textures["logo"])
	logo_node.name = "Logo"
	logo_node.custom_minimum_size = Vector2(560, 350)
	main_layer.add_child(logo_node)

	var title := _make_texture_rect(ui_textures["title"])
	title.name = "Title"
	title.custom_minimum_size = Vector2(430, 80)
	main_layer.add_child(title)

	play_button = _make_texture_button(ui_textures["play"])
	play_button.name = "PlayButton"
	play_button.pressed.connect(_on_play_pressed)
	_wire_button_anim(play_button)
	main_layer.add_child(play_button)

	music_button = _make_texture_button(ui_textures["music"])
	music_button.name = "MusicButton"
	music_button.pressed.connect(_toggle_mute)
	_wire_button_anim(music_button)
	main_layer.add_child(music_button)

	var board_bg := _make_texture_rect(ui_textures["game_bg"])
	board_bg.name = "BoardBackdrop"
	board_bg.custom_minimum_size = Vector2(690, 690)
	game_layer.add_child(board_bg)

	board_layer = Control.new()
	board_layer.name = "Board"
	board_layer.custom_minimum_size = Vector2(BLOCK_SIZE * GRID_SIZE, BLOCK_SIZE * GRID_SIZE)
	board_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_layer.add_child(board_layer)

	score_label = _make_label("0", 56)
	score_label.name = "Score"
	game_layer.add_child(score_label)

	best_label = _make_label("BEST %d" % best_score, 26)
	best_label.name = "Best"
	game_layer.add_child(best_label)

	var restart_button := _make_texture_button(ui_textures["restart"])
	restart_button.name = "RestartButton"
	restart_button.pressed.connect(replay_game)
	_wire_button_anim(restart_button)
	game_layer.add_child(restart_button)

	var back_button := _make_texture_button(ui_textures["back"])
	back_button.name = "BackButton"
	back_button.pressed.connect(over_game)
	_wire_button_anim(back_button)
	game_layer.add_child(back_button)

	merge_effect = _make_texture_rect(ui_textures["light"])
	merge_effect.name = "MergeEffect"
	merge_effect.visible = false
	merge_effect.modulate = Color(1, 1, 1, 0)
	merge_effect.pivot_offset = Vector2(120, 120)
	game_layer.add_child(merge_effect)

	click_player = AudioStreamPlayer.new()
	click_player.stream = load("res://assets/sound/click.mp3")
	add_child(click_player)

	merge_player = AudioStreamPlayer.new()
	merge_player.stream = load("res://assets/sound/mergen.mp3")
	add_child(merge_player)

func _build_loading_layer() -> void:
	var loading_bg := _make_texture_rect(ui_textures["loading_bg"])
	loading_bg.name = "LoadingBg"
	loading_layer.add_child(loading_bg)

	var loading_logo := _make_texture_rect(ui_textures["loading_logo"])
	loading_logo.name = "LoadingLogo"
	loading_layer.add_child(loading_logo)

	var track := _make_texture_rect(ui_textures["loading_item_02"])
	track.name = "LoadingTrack"
	loading_layer.add_child(track)

	loading_bar = ColorRect.new()
	loading_bar.name = "LoadingBar"
	loading_bar.color = Color(0.96, 0.83, 0.32, 1.0)
	loading_layer.add_child(loading_bar)

	var cap := _make_texture_rect(ui_textures["loading_item_01"])
	cap.name = "LoadingCap"
	loading_layer.add_child(cap)

	loading_label = _make_label("0%", 34)
	loading_label.name = "LoadingLabel"
	loading_label.add_theme_color_override("font_color", Color(0.28, 0.24, 0.22))
	loading_layer.add_child(loading_label)

func _build_background_decor() -> void:
	var decor_data := [
		["bg_05", Vector2(-110, 1040), Vector2(660, 520), 34.0],
		["bg_03", Vector2(415, 965), Vector2(405, 405), 42.0],
		["bg_05", Vector2(210, 1120), Vector2(470, 370), 38.0],
		["bg_03", Vector2(-165, 710), Vector2(530, 530), 46.0],
		["bg_04", Vector2(470, 290), Vector2(210, 190), 30.0]
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
		viewport_size = Vector2(720, 1280)

	background.size = viewport_size
	var loading_bg := loading_layer.get_node("LoadingBg") as Control
	_set_rect(loading_bg, Vector2.ZERO, viewport_size)
	_set_rect(loading_layer.get_node("LoadingLogo") as Control, Vector2((viewport_size.x - 558.0) * 0.5, viewport_size.y * 0.19), Vector2(558, 351))
	_set_rect(loading_layer.get_node("LoadingTrack") as Control, Vector2((viewport_size.x - 560.0) * 0.5, viewport_size.y * 0.74), Vector2(560, 50))
	_set_rect(loading_bar, Vector2((viewport_size.x - 540.0) * 0.5, viewport_size.y * 0.745), Vector2(1, 30))
	_set_rect(loading_layer.get_node("LoadingCap") as Control, Vector2((viewport_size.x - 560.0) * 0.5, viewport_size.y * 0.74), Vector2(560, 50))
	_set_rect(loading_label, Vector2(0, viewport_size.y * 0.735), Vector2(viewport_size.x, 60))

	_set_rect(logo_node, Vector2((viewport_size.x - 558.0) * 0.5, viewport_size.y * 0.13), Vector2(558, 351))
	_set_rect(main_layer.get_node("Title") as Control, Vector2((viewport_size.x - 430.0) * 0.5, viewport_size.y * 0.405), Vector2(430, 80))
	_set_rect(main_layer.get_node("PlayButton") as Control, Vector2((viewport_size.x - 250.0) * 0.5, viewport_size.y * 0.64), Vector2(250, 170))
	_set_rect(main_layer.get_node("MusicButton") as Control, Vector2(viewport_size.x - 96.0, 42.0), Vector2(62, 62))

	var board_size := Vector2(BLOCK_SIZE * GRID_SIZE, BLOCK_SIZE * GRID_SIZE)
	var board_pos := Vector2((viewport_size.x - board_size.x) * 0.5, viewport_size.y * 0.345)
	_set_rect(board_layer, board_pos, board_size)
	if combat_system:
		combat_system.layout_for_board(board_pos, board_size)
	_set_rect(game_layer.get_node("BoardBackdrop") as Control, board_pos - Vector2(15, 15), board_size + Vector2(30, 30))
	_set_rect(score_label, Vector2(0, viewport_size.y * 0.13), Vector2(viewport_size.x, 80))
	_set_rect(best_label, Vector2(0, viewport_size.y * 0.195), Vector2(viewport_size.x, 44))
	_set_rect(game_layer.get_node("RestartButton") as Control, Vector2(viewport_size.x - 105.0, 45.0), Vector2(76, 76))
	_set_rect(game_layer.get_node("BackButton") as Control, Vector2(30.0, 45.0), Vector2(76, 76))
	_set_rect(merge_effect, Vector2.ZERO, Vector2(240, 240))

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

func _pulse_loop(node: Control, min_scale: float, max_scale: float, duration: float) -> void:
	node.scale = Vector2.ONE * min_scale
	var tween := create_tween().set_loops()
	tween.tween_property(node, "scale", Vector2.ONE * max_scale, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(node, "scale", Vector2.ONE * min_scale, duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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

func show_main_menu() -> void:
	game_status = GameStatus.NONE
	loading_layer.visible = false
	main_layer.visible = true
	game_layer.visible = false
	decor_layer.visible = true
	_clear_popup()
	_update_mute_visual()
	_animate_main_menu()

func show_loading() -> void:
	loading_layer.visible = true
	main_layer.visible = false
	game_layer.visible = false
	popup_layer.visible = false
	decor_layer.visible = false
	_set_loading_progress(0.0)
	var tween := create_tween()
	tween.tween_method(Callable(self, "_set_loading_progress"), 0.0, 1.0, 1.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.15)
	tween.tween_callback(show_main_menu)

func _set_loading_progress(value: float) -> void:
	var progress := clampf(value, 0.0, 1.0)
	if loading_bar:
		loading_bar.size.x = 540.0 * progress
	if loading_label:
		loading_label.text = "%d%%" % int(progress * 100.0)

func _animate_main_menu() -> void:
	main_layer.modulate = Color(1, 1, 1, 0)
	logo_node.scale = Vector2(0.92, 0.92)
	play_button.scale = Vector2.ONE
	var tween := create_tween()
	tween.tween_property(main_layer, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(logo_node, "scale", Vector2.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_loop(play_button, 0.98, 1.05, 1.7)

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
	block.setup(start_level, normal_textures, selected_textures)
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
	return Vector2(site.x * BLOCK_SIZE, (GRID_SIZE - 1 - site.y) * BLOCK_SIZE)

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

	if clicked.level >= 10:
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

	_play_merge()
	_play_merge_effect(clicked)
	game_status = GameStatus.PAUSE

	var merge_group: Array[MergeBlock] = []
	for block in selected_blocks:
		merge_group.append(block)

	var merged_count: int = merge_group.size()
	var old_level: int = clicked.level
	var click_index: int = merge_group.find(clicked)
	var max_steps: int = max(merged_count - 1 - click_index, click_index)
	var action_time: float = max(0.08, 0.36 / float(merged_count))

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

	await get_tree().create_timer(float(max_steps + 1) * action_time + 0.08).timeout
	selected_blocks.clear()
	clicked.selected = false
	clicked.had_merged = false
	clicked.level += 1
	current_level = max(current_level, clicked.level)
	_dispatch_merge_attack(clicked, merged_count)
	_refresh_score(merged_count, old_level)
	_pulse(clicked)

	if clicked.level >= 10:
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

func _dispatch_merge_attack(clicked: MergeBlock, merge_count: int) -> void:
	if combat_system == null:
		return
	var origin := board_layer.global_position + clicked.position + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5)
	var attack_event := MergeAttackEvent.from_merge(clicked.level, merge_count, origin)
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

	if check_fail():
		end_game(false)

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
			if block == null or block.level >= 10:
				continue
			if _has_same_neighbor(block):
				return false
	return true

func _ensure_any_match() -> void:
	if not check_fail():
		return
	var first := _block_at(Vector2i(0, 0))
	var second := _block_at(Vector2i(1, 0))
	if first != null and second != null and first.level < 10:
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

func end_game(_had_pass: bool) -> void:
	game_status = GameStatus.OVER
	if combat_system:
		combat_system.stop_run()
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
	_set_rect(light, Vector2((size.x - 720.0) * 0.5, size.y * 0.08), Vector2(720, 568))
	light.modulate = Color(1, 1, 1, 0)
	popup_layer.add_child(light)

	var popup := _make_texture_rect(ui_textures["success"])
	popup.name = "SuccessPanel"
	_set_rect(popup, Vector2((size.x - 668.0) * 0.5, size.y * 0.22), Vector2(668, 816))
	popup.scale = Vector2.ZERO
	popup_layer.add_child(popup)

	var icon := TextureRect.new()
	icon.texture = normal_textures[9]
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(icon, Vector2(250, 210), Vector2(168, 168))
	popup.add_child(icon)

	var continue_button := _make_texture_button(ui_textures["continue"])
	_set_rect(continue_button, Vector2(139, 570), Vector2(390, 160))
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
	var popup := _make_popup_panel(Vector2(610, 700))
	popup_layer.add_child(popup)

	var title := _make_label("GAME OVER", 48)
	_set_rect(title, Vector2(0, 55), Vector2(610, 70))
	popup.add_child(title)

	var score_text := _make_label("SCORE  %d" % score, 40)
	_set_rect(score_text, Vector2(0, 150), Vector2(610, 60))
	popup.add_child(score_text)

	var best_text := _make_label("BEST  %d" % best_score, 34)
	_set_rect(best_text, Vector2(0, 215), Vector2(610, 52))
	popup.add_child(best_text)

	var block_icon := TextureRect.new()
	block_icon.texture = normal_textures[clampi(current_level - 1, 0, 9)]
	block_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	block_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_set_rect(block_icon, Vector2(239, 285), Vector2(132, 132))
	popup.add_child(block_icon)

	var crown := _make_texture_rect(ui_textures["crown"])
	_set_rect(crown, Vector2(180, 225), Vector2(45, 39))
	popup.add_child(crown)

	if score >= best_score and score > 0:
		var record := _make_texture_rect(ui_textures["new_record"])
		_set_rect(record, Vector2(175, 432), Vector2(259, 37))
		popup.add_child(record)

	var revive_button := _make_text_button("CONTINUE", Vector2(250, 76))
	_set_rect(revive_button, Vector2(180, 485), Vector2(250, 76))
	revive_button.pressed.connect(resurrect)
	_wire_button_anim(revive_button)
	popup.add_child(revive_button)

	var restart_button := _make_texture_button(ui_textures["restart"])
	_set_rect(restart_button, Vector2(112, 570), Vector2(155, 120))
	restart_button.pressed.connect(replay_game)
	_wire_button_anim(restart_button)
	popup.add_child(restart_button)

	var home_button := _make_texture_button(ui_textures["esc"])
	_set_rect(home_button, Vector2(485, 22), Vector2(77, 66))
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

	block.selected = false
	board_layer.move_child(block, board_layer.get_child_count() - 1)
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(block, "position", target_position, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(block, "scale", Vector2(0.86, 0.86), duration)
	tween.tween_property(block, "modulate:a", 0.0, 0.06)
	tween.tween_callback(block.queue_free)

func _pulse(block: MergeBlock) -> void:
	block.pivot_offset = block.size * 0.5
	var tween := create_tween()
	tween.tween_property(block, "scale", Vector2(1.14, 1.14), 0.08)
	tween.tween_property(block, "scale", Vector2.ONE, 0.1)

func _play_merge_effect(block: MergeBlock) -> void:
	var board_pos := board_layer.position + block.position + Vector2(BLOCK_SIZE * 0.5, BLOCK_SIZE * 0.5)
	merge_effect.visible = true
	merge_effect.position = board_pos - Vector2(120, 120)
	merge_effect.scale = Vector2(0.28, 0.28)
	merge_effect.rotation = 0
	merge_effect.modulate = Color(1, 1, 1, 0.32)
	var tween := create_tween()
	tween.parallel().tween_property(merge_effect, "scale", Vector2(0.58, 0.58), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(merge_effect, "rotation", TAU * 0.035, 0.18)
	tween.parallel().tween_property(merge_effect, "modulate:a", 0.0, 0.18)
	tween.tween_callback(func(): merge_effect.visible = false)

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
	for block in block_map.values():
		if block:
			block.queue_free()
	block_map.clear()
	selected_blocks.clear()
	block_count = 0
	current_level = 0
	_reset_index_map()

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
