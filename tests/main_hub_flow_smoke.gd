extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	# The hub flow applies after the first-wave onboarding has been completed.
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._chapter_resume_state.clear()
	game._chapter_completion_snapshot.clear()
	game._chapter_completed = false
	game._continuation_completed = false
	await process_frame
	game.muted = true

	_check(game.loading_view != null and game.loading_view.visible, "game should open on Loading")
	_check(game.main_hub_view != null and not game.main_hub_view.visible, "main hub should stay hidden while Loading runs")

	await _wait_seconds(2.90)
	_check(game.main_layer.visible, "automatic routing should keep the menu layer visible")
	_check(not game.loading_view.visible, "Loading should hide after completion")
	_check(game.main_hub_view.visible, "Loading completion should open the main hub")
	_check(not game.game_layer.visible, "opening the hub must not start combat")
	_check(game.main_hub_view._interactive, "hub should become interactive after its intro")

	var design_root := game.main_hub_view.get_node("DesignRoot") as Control
	var forest_island := game.main_hub_view.get_node("DesignRoot/ForestIsland") as TextureRect
	var stage_button := game.main_hub_view.get_node("DesignRoot/StageButton") as Button
	var stage_label := game.main_hub_view.get_node("DesignRoot/StageButton/Label") as Label
	var bottom_navigation := game.main_hub_view.get_node("DesignRoot/BottomNavigation") as NinePatchRect
	var mission_title := game.main_hub_view.get_node("DesignRoot/MissionTitle") as Label
	var mission_track := game.main_hub_view.get_node("DesignRoot/MissionProgressTrack") as NinePatchRect
	var mission_fill := game.main_hub_view.get_node("DesignRoot/MissionProgressFillClip/Fill") as NinePatchRect
	var settings_frame := game.main_hub_view.get_node("DesignRoot/SettingsFrame") as NinePatchRect
	var settings_icon := game.main_hub_view.get_node("DesignRoot/SettingsIcon") as TextureRect
	var crystal_counter := game.main_hub_view.get_node("DesignRoot/CrystalCounter") as NinePatchRect
	var crystal_icon := game.main_hub_view.get_node("DesignRoot/CrystalIcon") as TextureRect
	var coin_counter := game.main_hub_view.get_node("DesignRoot/CoinCounter") as NinePatchRect
	var coin_icon := game.main_hub_view.get_node("DesignRoot/CoinIcon") as TextureRect
	var stage_style := stage_button.get_theme_stylebox("normal") as StyleBoxTexture
	_check(stage_style != null and stage_style.texture != null and stage_style.texture.resource_path.contains("ui/interfaces/main_hub/"), "start button should load the organized mobile-safe NinePatch art")
	_check(stage_label.text == "继续挑战", "the returning-player hub entry should invite the next challenge")
	_check(forest_island.position == Vector2(166, 563) and forest_island.size == Vector2(610, 606), "forest island should match the production preview transform")
	_check(stage_button.position == Vector2(258, 1179) and stage_button.size == Vector2(426, 162), "start button should preserve the production preview proportions")
	var stage_progress := stage_button.get_node("ProgressLabel") as Label
	game.main_hub_view.set_stage_entry("继续挑战", "1-1")
	_check(stage_label.position == Vector2(0, 4) and stage_label.size == Vector2(426, 65), "two-line stage titles should use their own upper safe area")
	_check(stage_progress.text == "1-1", "stage progress should show only the stage number")
	_check(stage_progress.position == Vector2(0, 70) and stage_progress.size == Vector2(426, 54), "stage number should use a larger separate lower safe area")
	_check(stage_progress.get_theme_font_size("font_size") == 38, "stage number should use the enlarged approved font size")
	_check(stage_label.position.y + stage_label.size.y <= stage_progress.position.y, "stage title and progress label rectangles must not overlap")
	_check(bottom_navigation.position == Vector2(-64, 1450) and bottom_navigation.size == Vector2(1069, 402), "bottom navigation should continue far past every viewport edge so its lower border stays offscreen")
	var selected_tab := game.main_hub_view.get_node("DesignRoot/BattleSelectedTab") as NinePatchRect
	_check(selected_tab.position == Vector2(307, 1448) and selected_tab.size == Vector2(327, 404), "selected battle tab should continue below the viewport with the navigation plate")
	_check(bottom_navigation.position.y + bottom_navigation.size.y >= 1852.0 and selected_tab.position.y + selected_tab.size.y >= 1852.0, "bottom navigation artwork must extend at least 180px beyond the design viewport")
	_check((game.main_hub_view.get_node("DesignRoot/ShopIcon") as TextureRect).position == Vector2(75, 1474), "shop icon should remain clear of its label")
	_check((game.main_hub_view.get_node("DesignRoot/LockedIcon") as TextureRect).position == Vector2(708, 1477), "locked icon should remain clear of its label")
	_check(mission_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "mission title should use the production preview's left alignment")
	_check(settings_frame.position == Vector2(23, 25) and settings_frame.size == Vector2(127, 121), "settings frame should match the reference top inset and visible width")
	_check(settings_icon.position == Vector2(34, 33) and settings_icon.size == Vector2(104, 104), "settings gear should use the reference icon scale inside its frame")
	_check(crystal_counter.position == Vector2(205, 50) and crystal_counter.size == Vector2(245, 66), "crystal counter should match the reference frame bounds")
	_check(crystal_icon.position == Vector2(193, 30) and crystal_icon.size == Vector2(101, 109), "crystal icon should retain the reference overlap and scale")
	_check(coin_counter.position == Vector2(454, 50) and coin_counter.size == Vector2(241, 66), "coin counter should align with the crystal counter")
	_check(coin_icon.position == Vector2(436, 25) and coin_icon.size == Vector2(114, 115), "coin icon should match the larger reference silhouette")
	var lobby_title := game.main_hub_view.get_node("DesignRoot/LobbyTitle") as Label
	_check(lobby_title.scale == Vector2.ONE, "lobby title glyphs must not be stretched non-uniformly")
	_check(mission_track.position == Vector2(215, 265) and mission_track.size == Vector2(395, 48), "mission progress track should match the approved effect bounds")
	var mission_panel := game.main_hub_view.get_node("DesignRoot/MissionPanel") as NinePatchRect
	var mission_reward := game.main_hub_view.get_node("DesignRoot/MissionRewardSlot") as NinePatchRect
	_check(mission_panel.position == Vector2(178, 174) and mission_panel.size == Vector2(604, 165), "mission panel should match the reference outer bounds")
	_check(mission_panel.texture.resource_path.ends_with("lobby_mission_panel_plain_default_v01.png"), "mission panel should not contain the baked duplicate reward socket")
	_check(mission_reward.position == Vector2(624, 195) and mission_reward.size == Vector2(135, 118), "mission reward slot should use the compact reference proportions")
	_check(mission_track.patch_margin_left > 0 and mission_fill.patch_margin_left > 0, "mission progress textures should stretch only through NinePatch safe centres")
	game.main_hub_view.set_resource_values(2823, 114000)
	_check((game.main_hub_view.get_node("DesignRoot/CrystalValue") as Label).text == "2823", "ordinary crystal balances should stay exact")
	_check((game.main_hub_view.get_node("DesignRoot/CoinValue") as Label).text == "114K", "six-digit balances should remain inside the counter safe area")
	game.main_hub_view.set_daily_activity(100)
	_check(is_equal_approx(mission_fill.size.x, 390.0), "full activity should fill the approved progress width without overflowing")
	game.main_hub_view.set_daily_activity(0)
	_check(not mission_fill.visible, "zero activity should hide the fill instead of leaving a stretched end cap")
	for path in [
		"DesignRoot/Background",
		"DesignRoot/ForestIsland",
		"DesignRoot/SettingsIcon",
		"DesignRoot/CrystalIcon",
		"DesignRoot/CoinIcon",
		"DesignRoot/MissionRewardIcon",
		"DesignRoot/ShopIcon",
		"DesignRoot/BattleIcon",
		"DesignRoot/LockedIcon",
	]:
		var texture_node := game.main_hub_view.get_node(path) as TextureRect
		_check(texture_node != null and texture_node.texture != null and _is_current_hub_texture(texture_node.texture), "%s should load its organized runtime texture" % path)
	for path in [
		"DesignRoot/MissionPanel",
		"DesignRoot/TaskEntry/Frame",
		"DesignRoot/AdEntry/Frame",
		"DesignRoot/BottomNavigation",
		"DesignRoot/BattleSelectedTab",
	]:
		var frame_node := game.main_hub_view.get_node(path) as NinePatchRect
		_check(frame_node != null and frame_node.texture != null and frame_node.texture.resource_path.contains("ui/interfaces/main_hub/"), "%s should load its organized frame" % path)
	_check(bottom_navigation.patch_margin_left > 0 and bottom_navigation.patch_margin_top > 0, "lobby frames should use real NinePatch margins instead of whole-texture stretching")
	_check(game.main_hub_view.get_node_or_null("DesignRoot/SettingsButton") != null, "settings should be a functional secondary UI entry")
	var interactive_buttons: Array[BaseButton] = []
	_collect_buttons(design_root, interactive_buttons)
	_check(interactive_buttons.size() == 9 and interactive_buttons.has(stage_button), "the lobby should expose stage plus eight secondary entries")
	game.main_hub_view.entry_pressed.emit("double_coin")
	await process_frame
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "benefits", "double-coin entry should open the shared benefits bundle")
	game.secondary_ui.close()
	game.main_hub_view.entry_pressed.emit("remove_ads")
	await process_frame
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "benefits", "remove-ads entry should open the same benefits bundle")
	game.secondary_ui.close()
	game.main_hub_view.entry_pressed.emit("shop")
	await process_frame
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "shop", "shop entry should open the formal secondary UI")
	game.secondary_ui.close()

	for viewport_size in [Vector2(941.0, 1672.0), Vector2(941.0, 1800.0), Vector2(1280.0, 1672.0)]:
		game.main_hub_view.layout_for_viewport(viewport_size)
		_check(is_equal_approx(design_root.scale.x, design_root.scale.y), "hub scaling should remain proportional")
		var display_size := MainHubView.DESIGN_SIZE * design_root.scale.x
		_check(
			design_root.position.x >= -0.01
				and design_root.position.y >= -0.01
				and design_root.position.x + display_size.x <= viewport_size.x + 0.01
				and design_root.position.y + display_size.y <= viewport_size.y + 0.01,
			"hub should remain centered inside the viewport"
		)

	game.main_hub_view.stage_pressed.emit(1)
	await process_frame
	_check(game.game_layer.visible and not game.main_layer.visible, "clicking stage one should enter combat")

	game.over_game()
	await _wait_seconds(0.30)
	_check(game.main_layer.visible and game.main_hub_view.visible, "returning home should reopen the main hub")
	_check(not game.loading_view.visible, "returning home should not replay Loading")

	game.queue_free()
	await process_frame
	await process_frame
	if failures.is_empty():
		print("MAIN_HUB_FLOW_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _is_current_hub_texture(texture: Texture2D) -> bool:
	return texture.resource_path.contains("ui/interfaces/main_hub/") or texture.resource_path.contains("ui/shared/meta_icons/")


func _collect_buttons(node: Node, output: Array[BaseButton]) -> void:
	for child in node.get_children():
		if child is BaseButton:
			output.append(child as BaseButton)
		_collect_buttons(child, output)
