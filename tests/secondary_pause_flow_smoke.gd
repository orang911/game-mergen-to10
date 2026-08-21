extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.loading_view.stop_animations()
	game.loading_view.visible = false
	game.muted = true
	game._first_wave_tutorial_completed = true
	game._stop_first_wave_tutorial()
	game.main_layer.visible = false
	game.game_layer.visible = true
	game.game_status = game.GameStatus.START
	game._chapter_active = true
	game._campaign_mode = "chapter"

	game._toggle_manual_pause()
	await process_frame
	_check(game.get_tree().paused and game._manual_paused, "pause should freeze the scene tree")
	_check(game.secondary_ui.visible and game.secondary_ui.page_id == "pause", "pause should open the formal pause panel")
	game.secondary_ui._open_settings()
	await process_frame
	_check(game.secondary_ui.page_id == "settings" and game.get_tree().paused, "settings opened from pause must remain paused")
	game.secondary_ui.close()
	await process_frame
	_check(game.secondary_ui.page_id == "pause" and game.get_tree().paused, "closing settings should return to pause without resuming")
	game.secondary_ui.close()
	await process_frame
	_check(not game.get_tree().paused and not game._manual_paused, "closing pause should resume combat")

	game._success_popup_active = true
	game._toggle_manual_pause()
	_check(not game._manual_paused, "settlement modal should block pause")
	game._success_popup_active = false

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("SECONDARY_PAUSE_FLOW_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
