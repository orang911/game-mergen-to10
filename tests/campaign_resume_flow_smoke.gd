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
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._chapter_completed = false
	game._continuation_completed = false
	game._chapter_resume_state.clear()
	game._chapter_completion_snapshot.clear()
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.start_game()
	await _wait_seconds(1.55)

	# Create the same state WaveSystem has after 1-5 clears and before the
	# chapter-completion choice is answered.
	var wave_system: WaveSystem = game.combat_system.wave_system
	wave_system.current_wave_index = ChapterOneConfig.CHAPTER_WAVE_COUNT - 1
	wave_system.awaiting_reward = true
	wave_system.running = false
	wave_system._current_wave = ChapterOneConfig.get_wave(ChapterOneConfig.CHAPTER_WAVE_COUNT - 1)
	game._chapter_active = true
	game._campaign_mode = "chapter"
	game._chapter_current_node_id = "1-5"
	game._show_chapter_completion()
	await process_frame
	_check(not game._chapter_completion_snapshot.is_empty(), "1-5 completion must retain a Boss-state snapshot")
	_check(game._chapter_completed, "1-5 completion must be recorded")

	game._begin_continuation_from_current_boss()
	await process_frame
	_check(game._campaign_mode == "continuation", "chapter completion button must enter continuation mode")
	_check(wave_system.current_wave_index == ChapterOneConfig.CHAPTER_WAVE_COUNT, "continuation must start at 01/20")
	_check(game._cluster_swap_item_count < 0 and game.energy_hud._crystal_rain_enabled, "continuation should restore both unlimited instant items")

	game.over_game()
	await process_frame
	_check(game.main_hub_view.visible, "leaving continuation must return to the hub")
	_check(not game._chapter_resume_state.is_empty(), "leaving continuation must cache its exact run snapshot")
	_check(str(game._chapter_resume_state.get("campaign_mode", "")) == "continuation", "continuation snapshot must retain its mode")

	# Reload from disk: this validates that the hub receives the persisted
	# continuation snapshot rather than merely reusing this instance's cache.
	game.queue_free()
	await process_frame
	await process_frame
	game = packed.instantiate()
	root.add_child(game)
	await _wait_seconds(0.50)
	game.muted = true
	_check(game.loading_view.visible, "a saved player must still begin on Loading after restart")
	await _wait_seconds(2.35)
	_check(game.main_hub_view.visible, "saved player Loading completion must open the hub")
	game.start_game()
	await _wait_seconds(0.25)
	_check(game.game_layer.visible, "hub Continue must restore the saved continuation battle")
	_check(game.combat_system.wave_system.current_wave_index == ChapterOneConfig.CHAPTER_WAVE_COUNT, "restored continuation must retain its wave index")

	game._on_level_completed()
	await process_frame
	_check(game._continuation_completed, "clearing continuation must mark the twenty-wave run complete")
	_check(game._chapter_completion_snapshot.is_empty(), "clearing continuation must remove the Boss continuation snapshot")
	_check(game.main_hub_view.visible, "clearing continuation must return to the hub")
	var entry_label := game.main_hub_view.get_node("DesignRoot/StageButton/Label") as Label
	_check(entry_label != null and entry_label.text == "重玩第一章", "completed continuation must offer a chapter replay")

	game.queue_free()
	await process_frame
	_restore_live_save()
	if failures.is_empty():
		print("CAMPAIGN_RESUME_FLOW_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


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
	else:
		DirAccess.remove_absolute(_save_path)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
