extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	# This fixture represents a returning player. The deferred startup router
	# should therefore open title → hub rather than the one-time tutorial.
	game._first_wave_tutorial_completed = true
	game._crystal_awakened_unlocked = true
	game._chapter_resume_state.clear()
	game._chapter_completion_snapshot.clear()
	game._chapter_completed = false
	game._continuation_completed = false
	await _wait_seconds(0.60)

	_check(game.loading_view.visible, "startup should keep Loading visible during its minimum duration")
	_check(game.loading_view.get_node_or_null("DesignRoot/BalanceSimulationButton") == null, "Loading must not expose the simulation button")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	touch.position = Vector2(100.0, 100.0)
	game.loading_view.gui_input.emit(touch)
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	enter.pressed = true
	Input.parse_input_event(enter)
	await _wait_seconds(0.20)
	_check(game.loading_view.visible and not game.main_hub_view.visible, "blank clicks and Enter must not skip Loading")
	await _wait_seconds(2.15)
	_check(game.main_hub_view.visible, "returning players must reach the main hub automatically")
	_check(not game.loading_view.visible, "Loading must hide after automatic routing")
	_check(game.main_hub_view._interactive, "main hub must become interactive after the transition")
	_check(not game.game_layer.visible, "automatic startup must not start returning-player combat")

	game.main_hub_view.stage_pressed.emit(1)
	await _wait_seconds(1.70)
	_check(game.game_layer.visible, "selecting stage one must enter the game")
	_check(game.game_status == game.GameStatus.START, "stage one must finish in the playable START state (actual: %d)" % game.game_status)
	_check(not paused, "stage one must not leave the scene tree paused")
	_check(game.block_map.size() == GameConfig.GRID_SIZE * GameConfig.GRID_SIZE, "stage one must create or restore the complete board")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("STARTUP_INTERACTION_SMOKE_OK")
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
