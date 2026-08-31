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
	for task_id in MetaProgressService.TASK_ORDER:
		game.meta_progress.task_progress[task_id] = 0
		game.meta_progress.task_claimed[task_id] = false
	game.meta_progress.task_progress["login"] = 1
	game._refresh_hub_meta()

	var design_root := game.main_hub_view.get_node("DesignRoot") as Control
	var forest_island := game.main_hub_view.get_node("DesignRoot/ForestIsland") as TextureRect
	var stage_button := game.main_hub_view.get_node("DesignRoot/StageButton") as Button
	var stage_label := game.main_hub_view.get_node("DesignRoot/StageButton/Label") as Label
	var bottom_navigation := game.main_hub_view.get_node("DesignRoot/BottomNavigation") as NinePatchRect
	var mission_title := game.main_hub_view.get_node("DesignRoot/MissionTitle") as Label
	var mission_progress_text := game.main_hub_view.get_node("DesignRoot/MissionProgressText") as Label
	var mission_track := game.main_hub_view.get_node("DesignRoot/MissionProgressTrack") as NinePatchRect
	var mission_fill := game.main_hub_view.get_node("DesignRoot/MissionProgressFillClip/Fill") as NinePatchRect
	var settings_frame := game.main_hub_view.get_node("DesignRoot/SettingsFrame") as NinePatchRect
	var settings_icon := game.main_hub_view.get_node("DesignRoot/SettingsIcon") as TextureRect
	var crystal_counter := game.main_hub_view.get_node("DesignRoot/CrystalCounter") as TextureRect
	var crystal_icon := game.main_hub_view.get_node("DesignRoot/CrystalIcon") as TextureRect
	var coin_counter := game.main_hub_view.get_node("DesignRoot/CoinCounter") as TextureRect
	var coin_icon := game.main_hub_view.get_node("DesignRoot/CoinIcon") as TextureRect
	var stage_style := stage_button.get_theme_stylebox("normal") as StyleBoxTexture
	_check(stage_style != null and stage_style.texture != null and stage_style.texture.resource_path.contains("ui/interfaces/main_hub/"), "start button should load the organized mobile-safe NinePatch art")
	_check(stage_label.text == "继续挑战", "the returning-player hub entry should invite the next challenge")
	_check(forest_island.position == Vector2(166, 563) and forest_island.size == Vector2(610, 606), "forest island should match the production preview transform")
	_check(MainHubView.FOREST_ISLAND_LOOP.get_frame_count(&"default") == 68, "forest island should retain the complete supplied 68-frame sequence")
	_check(is_equal_approx(MainHubView.FOREST_ISLAND_LOOP.get_animation_speed(&"default"), 24.0), "forest island should play the supplied loop at 24 fps")
	_check(not MainHubView.FOREST_ISLAND_LOOP.get_animation_loop(&"default"), "forest island resource should defer replay timing to the lobby idle controller")
	_check(MainHubView.FOREST_ISLAND_LOOP.get_frame_texture(&"default", 0).get_size().x <= 640.0, "forest island frames should use the mobile-safe import size limit")
	_check(forest_island.texture.resource_path.contains("main_hub/animations/forest_island_loop_v01/"), "forest island should render the formal runtime animation instead of the static fallback")
	var forest_frame_before := forest_island.texture
	game.main_hub_view._process(0.1)
	_check(forest_island.texture != forest_frame_before, "forest island sequence should advance while the lobby is visible")
	var forest_loop_duration := float(MainHubView.FOREST_ISLAND_LOOP.get_frame_count(&"default")) / MainHubView.FOREST_ISLAND_LOOP.get_animation_speed(&"default")
	game.main_hub_view._forest_animation_time = forest_loop_duration - 0.01
	game.main_hub_view._forest_animation_wait_remaining = 0.0
	game.main_hub_view._process(0.02)
	var forest_idle_texture := forest_island.texture
	var forest_idle_duration: float = game.main_hub_view._forest_animation_wait_remaining
	_check(forest_idle_duration >= MainHubView.FOREST_ANIMATION_IDLE_MIN and forest_idle_duration <= MainHubView.FOREST_ANIMATION_IDLE_MAX, "forest island should wait a random five to ten seconds after each complete loop")
	game.main_hub_view._process(4.9)
	_check(forest_island.texture == forest_idle_texture, "forest island should hold the calm final frame during the idle interval")
	game.main_hub_view._process(10.0)
	_check(forest_island.texture == MainHubView.FOREST_ISLAND_LOOP.get_frame_texture(&"default", 0), "forest island should restart from frame one after its idle interval")
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
	var shop_icon := game.main_hub_view.get_node("DesignRoot/ShopIcon") as TextureRect
	var shop_label := game.main_hub_view.get_node("DesignRoot/ShopLabel") as Label
	_check(shop_icon.modulate == Color(0.48, 0.48, 0.52, 1.0), "locked shop icon should be visibly greyed")
	_check(shop_label.text == "未解锁" and shop_label.get_theme_color("font_color") == Color(0.66, 0.68, 0.74, 1.0), "locked shop should replace 商城 with 未解锁")
	_check(game.main_hub_view.get_node_or_null("DesignRoot/ShopButton") == null, "locked shop should not expose the real shop entry")
	var locked_shop_button := game.main_hub_view.get_node_or_null("DesignRoot/LockedShopButton") as Button
	_check(locked_shop_button != null and locked_shop_button.position == Vector2(32, 1450) and locked_shop_button.size == Vector2(253, 222), "locked shop should expose only a notice hit target over its complete dock slot")
	if locked_shop_button != null:
		locked_shop_button.pressed.emit()
		await process_frame
		var locked_notice := game.main_hub_view.get_node_or_null("DesignRoot/LockedNotice") as Panel
		var locked_notice_copy := locked_notice.get_node_or_null("Copy") as Label if locked_notice != null else null
		_check(locked_notice != null and locked_notice.position == Vector2(190, 785) and locked_notice.size == Vector2(561, 102), "locked notice should appear in the center of the design canvas")
		_check(locked_notice_copy != null and locked_notice_copy.text == "未解锁，敬请期待", "locked notice should use the approved expectation copy")
		await _wait_seconds(1.70)
		_check(game.main_hub_view.get_node_or_null("DesignRoot/LockedNotice") == null, "locked notice should dismiss itself without opening another page")
		_check(not game.secondary_ui.visible, "locked shop notice should not open the shop or any secondary interface")
	_check(game.main_hub_view.get_node_or_null("DesignRoot/GiftEntry") == null and game.main_hub_view.get_node_or_null("DesignRoot/FirstPurchaseButton") == null, "first-purchase art and entry should be absent from the hub")
	var piggy_entry := game.main_hub_view.get_node("DesignRoot/PiggyEntry") as Control
	_check(piggy_entry.position == Vector2(780, 695), "piggy bank should fill the removed first-purchase slot and align with sign-in")
	var battle_nav_icon := game.main_hub_view.get_node("DesignRoot/BattleIcon") as TextureRect
	var crystal_nav_icon := game.main_hub_view.get_node("DesignRoot/CrystalNavIcon") as TextureRect
	var crystal_nav_label := game.main_hub_view.get_node("DesignRoot/CrystalNavLabel") as Label
	_check(battle_nav_icon.position == Vector2(360, 1430) and battle_nav_icon.texture.resource_path.ends_with("lobby_icon_battle_portal_v02.png"), "battle navigation should use the supplied portal art")
	_check(crystal_nav_icon.position == Vector2(708, 1477) and crystal_nav_icon.texture.resource_path.ends_with("lobby_icon_battle_crystal_v01.tres"), "crystal navigation should reuse the formal crystal tower art")
	_check(crystal_nav_label.text == "水晶" and crystal_nav_label.get_theme_color("font_color") == Color.WHITE, "right navigation should be labeled 水晶 instead of 未解锁")
	_check(mission_title.horizontal_alignment == HORIZONTAL_ALIGNMENT_LEFT, "mission title should use the production preview's left alignment")
	_check(settings_frame.position == Vector2(23, 25) and settings_frame.size == Vector2(127, 121), "settings frame should match the reference top inset and visible width")
	_check(settings_icon.position == Vector2(34, 33) and settings_icon.size == Vector2(104, 104), "settings gear should use the reference icon scale inside its frame")
	_check(crystal_counter.position == Vector2(205, 53) and crystal_counter.size == CurrencyAssets.HUB_COUNTER_PANEL_SIZE, "crystal counter should retain the complete source asset's native 241x61 aspect")
	_check(crystal_counter.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "crystal counter should never stretch the complete frame art")
	_check(crystal_icon.position == Vector2(203, 40) and crystal_icon.size == Vector2(82, 89), "shared diamond should use the lobby-specific compact top-counter size")
	_check(coin_counter.position == Vector2(454, 53) and coin_counter.size == CurrencyAssets.HUB_COUNTER_PANEL_SIZE, "coin counter should use the same native frame size as the crystal counter")
	_check(coin_counter.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "coin counter should never stretch the complete frame art")
	_check(coin_icon.position == Vector2(450, 39) and coin_icon.size == Vector2(86, 87), "shared coin should use the lobby-specific compact top-counter size")
	var double_coin_icon := game.main_hub_view.get_node("DesignRoot/DoubleCoinEntry/Icon") as TextureRect
	_check(double_coin_icon.position == Vector2(3, 11) and double_coin_icon.size == Vector2(135, 135) and double_coin_icon.texture.resource_path.ends_with("lobby_icon_double_coin_x2_v01.tres"), "double-coin entry should retain its original dedicated icon and bounds")
	var lobby_title := game.main_hub_view.get_node("DesignRoot/LobbyTitle") as Label
	_check(lobby_title.scale == Vector2.ONE, "lobby title glyphs must not be stretched non-uniformly")
	_check(mission_track.position == Vector2(215, 265) and mission_track.size == Vector2(395, 48), "mission progress track should match the approved effect bounds")
	var mission_panel := game.main_hub_view.get_node("DesignRoot/MissionPanel") as NinePatchRect
	var mission_reward := game.main_hub_view.get_node("DesignRoot/MissionRewardSlot") as NinePatchRect
	var mission_reward_icon := game.main_hub_view.get_node("DesignRoot/MissionRewardIcon") as TextureRect
	var mission_reward_count := game.main_hub_view.get_node("DesignRoot/MissionRewardCount") as Label
	_check(mission_panel.position == Vector2(178, 174) and mission_panel.size == Vector2(604, 165), "mission panel should match the reference outer bounds")
	_check(mission_panel.texture.resource_path.ends_with("lobby_mission_panel_plain_default_v01.png"), "mission panel should not contain the baked duplicate reward socket")
	_check(mission_reward.position == Vector2(624, 195) and mission_reward.size == Vector2(135, 118), "mission reward slot should use the compact reference proportions")
	_check(mission_reward_icon.position == Vector2(648, 206) and mission_reward_icon.size == Vector2(84, 84), "mission currency should use a separate compact reward-slot size")
	_check(mission_title.text == "完成 1 次挑战" and mission_progress_text.text == "0/1", "new daily queue should show the first unclaimed task and its real progress")
	_check(mission_reward_icon.texture.resource_path.ends_with("currency_diamond_v01.png") and mission_reward_count.text == "10", "queue head should show the single shared diamond and its amount")
	_check(mission_track.patch_margin_left > 0 and mission_fill.patch_margin_left > 0, "mission progress textures should stretch only through NinePatch safe centres")
	game.main_hub_view.set_resource_values(2823, 114000)
	_check((game.main_hub_view.get_node("DesignRoot/CrystalValue") as Label).text == "2823", "ordinary crystal balances should stay exact")
	_check((game.main_hub_view.get_node("DesignRoot/CoinValue") as Label).text == "114K", "six-digit balances should remain inside the counter safe area")
	game.main_hub_view.set_task_summary({"title": "击败 30 个怪物", "progress": 15, "target": 30, "reward": {"coins": 50}})
	_check(mission_title.text == "击败 30 个怪物" and mission_progress_text.text == "15/30", "task summary should render shared task copy and progress")
	_check(is_equal_approx(mission_fill.size.x, 195.0), "half-complete task should fill half the approved progress width")
	_check(mission_reward_icon.texture.resource_path.ends_with("currency_coin_v01.png") and mission_reward_count.text == "50", "task summary should switch to the single shared coin and its amount")
	game.main_hub_view.set_task_summary({})
	_check(mission_title.text == "今日任务已完成" and mission_progress_text.text == "4/4" and is_equal_approx(mission_fill.size.x, 390.0), "empty queue should render the locked all-complete state")
	_check(not mission_reward.visible and not mission_reward_icon.visible and not mission_reward_count.visible, "all-complete state should hide the independent reward slot")
	game._refresh_hub_meta()
	for path in [
		"DesignRoot/Background",
		"DesignRoot/ForestIsland",
		"DesignRoot/SettingsIcon",
		"DesignRoot/CrystalIcon",
		"DesignRoot/CoinIcon",
		"DesignRoot/MissionRewardIcon",
		"DesignRoot/ShopIcon",
		"DesignRoot/BattleIcon",
		"DesignRoot/CrystalNavIcon",
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
	_check(interactive_buttons.size() == 10 and interactive_buttons.has(stage_button) and interactive_buttons.has(locked_shop_button), "the lobby should include the locked-shop notice target without restoring the real shop or first-purchase entries")
	var mission_button := game.main_hub_view.get_node("DesignRoot/MissionTasksButton") as Button
	game.meta_progress.task_progress["settle_once"] = 1
	mission_button.pressed.emit()
	await process_frame
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "daily", "clicking the mission summary should open the shared task interface")
	var settle_claim := game.secondary_ui._content.get_node_or_null("DailyTaskSection/TaskRow_settle_once/TaskStateButton_claim") as TextureButton
	_check(settle_claim != null and not settle_claim.disabled, "task page should render the queue-head task as claimable from shared progress")
	if settle_claim != null:
		settle_claim.pressed.emit()
		await process_frame
		_check(mission_title.text == "合成 20 次" and mission_progress_text.text == "0/20", "claiming in the task page should immediately advance the hub queue")
	game.secondary_ui.close()
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
	_check(not game.secondary_ui.visible, "legacy shop events should not bypass the locked lobby state")
	game.main_hub_view.entry_pressed.emit("first_purchase")
	await process_frame
	_check(not game.secondary_ui.visible, "legacy first-purchase events should remain disabled")
	game.main_hub_view.entry_pressed.emit("crystal_upgrade")
	await process_frame
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "crystal_upgrade", "bottom-right crystal entry should open the crystal upgrade page")
	_check(game.secondary_ui._content.get_node_or_null("CrystalUpgradeCurrentTower") != null, "crystal upgrade page should assemble the current tower cutout")
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
	return texture.resource_path.contains("ui/interfaces/main_hub/") or texture.resource_path.contains("ui/shared/meta_icons/") or texture.resource_path.contains("ui/shared/currency/")


func _collect_buttons(node: Node, output: Array[BaseButton]) -> void:
	for child in node.get_children():
		if child is BaseButton:
			output.append(child as BaseButton)
		_collect_buttons(child, output)
