extends SceneTree

const ModalScene := preload("res://scenes/ui/chapter_node_complete_modal.tscn")

var failures: Array[String] = []
var _save_path := ""
var _save_existed := false
var _save_backup := PackedByteArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	await _test_modal_visual_contract()
	await _test_main_game_routing()
	if failures.is_empty():
		print("CHAPTER_NODE_COMPLETE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_modal_visual_contract() -> void:
	var modal := ModalScene.instantiate() as ChapterNodeCompleteModal
	root.add_child(modal)
	await process_frame
	var panel := modal.get_node("DesignRoot/Content/Panel") as NinePatchRect
	var title_bar := modal.get_node("DesignRoot/Content/TitleBar") as TextureRect
	var divider := modal.get_node("DesignRoot/Content/CrystalDivider") as TextureRect
	var button := modal.get_node("DesignRoot/Content/ContinueButton") as TextureButton
	var description := modal.get_node("DesignRoot/Content/DescriptionLabel") as Label
	var node_title := modal.get_node("DesignRoot/Content/TitleBar/TitleLabel") as Label
	var continue_label := button.get_node("Label") as Label
	_check(panel.texture != null and title_bar.texture != null and divider.texture != null and button.texture_normal != null, "all four supplied V2 level-complete textures must load")
	_check(panel.texture.resource_path.contains("ui/interfaces/chapter_node_complete/") and title_bar.texture.resource_path.contains("ui/interfaces/chapter_node_complete/") and divider.texture.resource_path.contains("ui/interfaces/chapter_node_complete/") and button.texture_normal.resource_path.contains("ui/interfaces/chapter_node_complete/"), "completion modal must reference its organized interface slices only")
	_check(divider.position.y + divider.size.y <= description.position.y, "V2 crystal divider must stay above body copy without overlap")
	_check(description.position.y + description.size.y <= button.position.y, "V2 body copy must stay above the primary action without overlap")
	_check(description.text == "水晶、棋盘与能量状态将带入下一关。", "node-complete description must match the approved copy")
	_check(continue_label.text == "继续前进", "primary button must use the approved copy")
	_check((node_title.get_theme_font("font") as SystemFont).font_weight >= 900, "secondary-screen titles must use the shared heavy Chinese font")
	_check((description.get_theme_font("font") as SystemFont).font_weight == 700, "secondary-screen body copy must use the shared readable medium-bold font")
	_check(description.get_theme_color("font_shadow_color").a == 0.0, "body copy must not retain the dirty title shadow")
	_check((continue_label.get_theme_font("font") as SystemFont).font_weight >= 900, "secondary-screen primary actions must use the shared heavy font")
	_check((modal.get_node("FullScreenShade") as ColorRect).mouse_filter == Control.MOUSE_FILTER_STOP, "full-screen shade must block blank-area input")
	for node_id in ["1-1", "1-2", "1-3", "1-4"]:
		modal.setup(node_id)
		_check((modal.get_node("DesignRoot/Content/TitleBar/TitleLabel") as Label).text == "%s 完成" % node_id, "node title must update for %s" % node_id)
		_check(not (modal.get_node("DesignRoot/Content/SecondaryButton") as Button).visible, "ordinary node completion must keep the secondary action hidden")

	modal.setup_chapter_completion()
	_check((modal.get_node("DesignRoot/Content/TitleBar/TitleLabel") as Label).text == "第一章完成", "chapter completion must use the unified title bar")
	_check(description.text == "挑战仍将继续。下一站：续战 01/20。", "chapter completion must retain the continuation description")
	_check((button.get_node("Label") as Label).text == "继续挑战", "chapter completion must use the unified yellow primary action")
	_check((modal.get_node("DesignRoot/Content/SecondaryButton") as Button).visible, "chapter completion must show the unified return-to-hub action")
	modal.setup("1-4")

	for viewport_size in [Vector2(941.0, 1672.0), Vector2(720.0, 1600.0), Vector2(1080.0, 1920.0)]:
		modal.size = viewport_size
		modal._layout_for_viewport()
		var design_root := modal.get_node("DesignRoot") as Control
		var content := modal.get_node("DesignRoot/Content") as Control
		var scale_factor := design_root.scale.x
		var displayed_position := design_root.position + content.position * scale_factor
		var displayed_size := content.size * scale_factor
		_check(displayed_position.x >= -0.01 and displayed_position.y >= -0.01, "completion panel must stay inside the top-left viewport bounds")
		_check(displayed_position.x + displayed_size.x <= viewport_size.x + 0.01 and displayed_position.y + displayed_size.y <= viewport_size.y + 0.01, "completion panel must stay inside narrow-screen bounds")

	var submit_state := {"count": 0}
	modal.continue_pressed.connect(func(): submit_state["count"] = int(submit_state["count"]) + 1)
	modal._on_continue_pressed()
	modal._on_continue_pressed()
	_check(int(submit_state["count"]) == 1, "continue button must submit exactly once")
	modal.queue_free()
	await process_frame

	var secondary_modal := ModalScene.instantiate() as ChapterNodeCompleteModal
	root.add_child(secondary_modal)
	await process_frame
	secondary_modal.setup_chapter_completion()
	var secondary_state := {"count": 0}
	secondary_modal.secondary_pressed.connect(func(): secondary_state["count"] = int(secondary_state["count"]) + 1)
	secondary_modal._on_secondary_pressed()
	secondary_modal._on_secondary_pressed()
	_check(int(secondary_state["count"]) == 1, "return-to-hub action must submit exactly once")
	secondary_modal.queue_free()
	await process_frame


func _test_main_game_routing() -> void:
	_backup_live_save()
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._chapter_active = true
	game._campaign_mode = "chapter"
	game.combat_system.running = true

	var continue_state := {"count": 0}
	game._show_chapter_transition("1-2", func(): continue_state["count"] = int(continue_state["count"]) + 1)
	await process_frame
	var modal := game.popup_layer.get_node_or_null("ChapterNodeCompleteModal") as ChapterNodeCompleteModal
	_check(modal != null, "ordinary chapter transition must use the new modal")
	if modal:
		modal._on_continue_pressed()
		modal._on_continue_pressed()
	await process_frame
	_check(int(continue_state["count"]) == 1, "ordinary node transition must advance once")

	# 1-4 must show completion first, then display the complete three-card choice.
	var mini_boss_wave := ChapterOneConfig.get_wave(10)
	game.combat_system.wave_system.setup(ChapterOneConfig.get_waves())
	game.combat_system.wave_system._current_wave = mini_boss_wave.duplicate(true)
	game.combat_system.wave_system.current_wave_index = 10
	game.combat_system.wave_system.awaiting_reward = true
	game._chapter_boss_reward_committed = false
	game._on_wave_cleared(10)
	await process_frame
	modal = game.popup_layer.get_node_or_null("ChapterNodeCompleteModal") as ChapterNodeCompleteModal
	_check(modal != null, "1-4 must show node completion before the reward")
	var counts_before_choice: Dictionary = game._run_card_counts.duplicate(true)
	if modal:
		modal._on_continue_pressed()
	await process_frame
	_check(game.popup_layer.get_node_or_null("ChapterNodeCompleteModal") == null, "acknowledging 1-4 completion must replace the completion modal")
	var reward_modal := game.active_card_modal as CrystalCardChoiceModalV2
	_check(reward_modal != null, "1-4 completion must be followed by the unified crystal-card choice")
	var chosen_id := ""
	var offered_ids: Array[String] = []
	if reward_modal:
		offered_ids = reward_modal._ids.duplicate()
		_check(reward_modal._ids.size() == 3, "Boss reward must display three cards")
		var unique_ids: Dictionary = {}
		for card_id in reward_modal._ids:
			unique_ids[card_id] = true
			_check(GameConfig.CRYSTAL_CARD_IDS.has(card_id), "Boss reward offers must all be crystal cards")
		_check(unique_ids.size() == 3, "Boss reward offers must be three distinct crystal cards")
		_check(reward_modal._title_label.text == "选择合成印记", "Boss reward must use the standard three-choice title")
		_check(reward_modal._title_label.get_theme_font_size("font_size") == CrystalCardChoiceModalV2.TITLE_FONT_SIZE, "Boss reward title must use the unified enlarged font scale")
		_check((reward_modal._title_label.get_theme_font("font") as SystemFont).font_weight >= 800, "Boss reward title must use the unified bold Chinese font")
		_check(reward_modal._confirm_label.text == "确定", "Boss reward must use the standard confirm action")
		_check(reward_modal._selected_index == -1, "Boss reward must not preselect a card")
		_check(reward_modal._confirm.disabled, "Boss reward confirm must remain disabled until the player selects a card")
		chosen_id = reward_modal._ids[1]
		reward_modal._locked = false
		reward_modal._select_card(1)
		reward_modal._finish_choice("")
		await _wait_seconds(1.20)
	_check(game.active_card_modal == null, "confirming the Boss choice must close the crystal-card modal")
	_check(not paused, "confirming the Boss choice must resume the chapter")
	_check(game.combat_system.wave_system.current_wave_index == 11, "confirming the 1-4 reward must enter 1-5")
	_check(game._chapter_boss_reward_committed, "the selected Boss reward must persist its committed marker")
	if not chosen_id.is_empty():
		_check(int(game._run_card_counts.get(chosen_id, 0)) == int(counts_before_choice.get(chosen_id, 0)) + 1, "only the selected crystal card must be granted once")
		for offered_id in offered_ids:
			if offered_id != chosen_id:
				_check(int(game._run_card_counts.get(offered_id, 0)) == int(counts_before_choice.get(offered_id, 0)), "unselected crystal cards must not be granted")

	# Restoring after submission must advance without reopening or duplicating it.
	var counts_after_choice: Dictionary = game._run_card_counts.duplicate(true)
	game.combat_system.wave_system._current_wave = mini_boss_wave.duplicate(true)
	game.combat_system.wave_system.current_wave_index = 10
	game.combat_system.wave_system.awaiting_reward = true
	game._restore_pending_chapter_gate()
	await process_frame
	_check(game._run_card_counts == counts_after_choice, "restoring the committed 1-4 reward gate must not duplicate any reward")
	_check(game.popup_layer.get_node_or_null("ChapterNodeCompleteModal") == null, "a committed 1-4 reward must not reopen completion")
	_check(game.active_card_modal == null, "a committed 1-4 reward must not reopen the card choice")
	_check(game.combat_system.wave_system.current_wave_index == 11, "a committed 1-4 reward restore must continue into 1-5")

	# 1-5 chapter completion must use the same supplied panel/title/button art,
	# while preserving the original continuation route.
	var final_wave := ChapterOneConfig.get_wave(11)
	game._chapter_active = true
	game._campaign_mode = "chapter"
	game.combat_system.running = true
	game.combat_system.wave_system._current_wave = final_wave.duplicate(true)
	game.combat_system.wave_system.current_wave_index = 11
	game.combat_system.wave_system.awaiting_reward = true
	game._show_chapter_completion()
	await process_frame
	var chapter_modal := game.popup_layer.get_node_or_null("ChapterCompletionModal") as ChapterNodeCompleteModal
	_check(chapter_modal != null, "1-5 must use the unified level-complete modal instead of the legacy dark panel")
	if chapter_modal:
		_check(chapter_modal._title_label.text == "第一章完成", "1-5 unified modal must show the chapter title")
		_check(chapter_modal._secondary_button.visible, "1-5 unified modal must retain the return-to-hub route")
		chapter_modal._on_continue_pressed()
	await process_frame
	await process_frame
	_check(game.popup_layer.get_node_or_null("ChapterCompletionModal") == null, "continuing must clear the unified chapter modal")
	_check(game._campaign_mode == "continuation", "continue challenge must preserve the original continuation route")

	paused = false
	game.queue_free()
	await process_frame
	_restore_live_save()


func _backup_live_save() -> void:
	_save_path = ProjectSettings.globalize_path(GameConfig.SAVE_PATH)
	_save_existed = FileAccess.file_exists(_save_path)
	if _save_existed:
		_save_backup = FileAccess.get_file_as_bytes(_save_path)


func _restore_live_save() -> void:
	if _save_existed:
		var file := FileAccess.open(_save_path, FileAccess.WRITE)
		if file:
			file.store_buffer(_save_backup)
	elif FileAccess.file_exists(_save_path):
		DirAccess.remove_absolute(_save_path)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
