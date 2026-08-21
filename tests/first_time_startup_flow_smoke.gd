extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	# Override any developer save before the deferred startup router runs.
	game._first_wave_tutorial_completed = false
	game._crystal_awakened_unlocked = false
	await _wait_seconds(0.60)

	_check(game.loading_view.visible, "a first-time player must begin on Loading")
	_check(not game.game_layer.visible, "Loading must honor its minimum duration")
	await _wait_seconds(3.55)
	_check(game.game_layer.visible, "first-time Loading completion must enter the tutorial battle")
	_check(not game.loading_view.visible, "the tutorial should replace Loading automatically")
	_check(game._first_wave_tutorial != null and game._first_wave_tutorial.is_active(), "first-time battle must activate the tutorial controller")

	game.combat_system.complete_tutorial_first_wave()
	game._on_first_wave_tutorial_finished(false)
	await _wait_seconds(0.30)
	_check(game._first_wave_tutorial_completed and game._crystal_awakened_unlocked, "finishing onboarding must mark tutorial progress")
	_check(game.game_layer.visible and not game.loading_view.visible and not game.main_layer.visible, "finished onboarding must remain in the same battle")
	_check(game._chapter_active and game._campaign_mode == "chapter", "tutorial hand-off must retain the chapter run")
	_check(game.combat_system.wave_system.current_wave_index == 1, "tutorial hand-off must advance into the authored 1-1 follow-up wave")

	game.queue_free()
	await process_frame
	if failures.is_empty():
		print("FIRST_TIME_STARTUP_FLOW_SMOKE_OK")
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
