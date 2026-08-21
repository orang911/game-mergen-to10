extends SceneTree

var failures: Array[String] = []
var _save_path := ""
var _save_existed := false
var _save_backup := PackedByteArray()


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_backup_live_save()
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	_prepare_tutorial_chapter_fixture(game)

	game._on_card_choice_committed("energy", "ascension_hammer", "", 1)
	_check(game.skill_imprint_system.has_pending_skill(), "chosen tutorial imprint must enter the pending slot")
	var saved_config := ConfigFile.new()
	_check(saved_config.load(GameConfig.SAVE_PATH) == OK, "imprint selection must write the chapter save immediately")
	var saved_run := saved_config.get_value("chapter", "active_run", {}) as Dictionary
	var saved_state := saved_run.get("state", {}) as Dictionary
	var saved_skill := saved_state.get("skill", {}) as Dictionary
	var saved_pending := saved_skill.get("pending_skill", {}) as Dictionary
	_check(str(saved_pending.get("id", "")) == "ascension_hammer", "save must include the pending imprint after selection")

	game.queue_free()
	await process_frame
	await process_frame
	game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	_check(not game._chapter_resume_state.is_empty(), "relaunch must discover the active tutorial chapter save")
	game.start_game()
	await process_frame
	_check(game.skill_imprint_system.has_pending_skill(), "re-entering the chapter must restore the pending imprint")
	_check(str(game.skill_imprint_system.peek_pending_skill().get("id", "")) == "ascension_hammer", "restored pending slot must retain the selected imprint id")

	# Resolve one deterministic valid merge and verify that the restored imprint
	# is consumed and applies its extra level after the normal merge result.
	for value in game.block_map.values():
		var block := value as MergeBlock
		if block:
			block.level = 1
	game.game_status = game.GameStatus.START
	var clicked := game._block_at(Vector2i(0, 0)) as MergeBlock
	game.select_next_blocks(clicked)
	game.merge_selected_blocks(clicked)
	await _wait_seconds(3.20)
	_check(not game.skill_imprint_system.has_pending_skill(), "restored imprint must be consumed by the next valid merge")
	_check(clicked != null and is_instance_valid(clicked) and clicked.level >= 3, "restored ascension imprint must activate after the base merge")

	game.queue_free()
	await process_frame
	_restore_live_save()
	if failures.is_empty():
		print("CHAPTER_IMPRINT_RESUME_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _prepare_tutorial_chapter_fixture(game) -> void:
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._chapter_active = true
	game._chapter_completed = false
	game._campaign_mode = "chapter"
	game._chapter_current_node_id = "1-3"
	game._reset_card_runtime()
	game._clear_game_world()
	game.first_create_blocks(false)
	game.combat_system.reset()
	game.combat_system.running = true
	game.combat_system.monster_system.start()
	game.combat_system.wave_system.setup(ChapterOneConfig.get_waves())
	game.game_status = game.GameStatus.START


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
