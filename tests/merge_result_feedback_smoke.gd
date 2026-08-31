extends SceneTree

const GROUP_SITES: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var game = await _make_game()
	_test_shake_profiles(game)
	await _test_result_feedback_precedes_attack(game)
	await _test_reset_restores_layout(game)
	_test_restricted_inputs_do_not_shake(game)
	game.queue_free()
	await process_frame
	await process_frame

	if failures.is_empty():
		print("MERGE_RESULT_FEEDBACK_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_shake_profiles(game) -> void:
	var expected := {
		2: Vector2(6.0, 0.12),
		3: Vector2(6.0, 0.12),
		4: Vector2(9.0, 0.15),
		5: Vector2(9.0, 0.15),
		6: Vector2(12.0, 0.18),
	}
	for merge_count in expected:
		_check(game._merge_shake_profile(merge_count) == expected[merge_count], "merge %d must use the approved shake tier" % merge_count)


func _test_result_feedback_precedes_attack(game) -> void:
	var clicked := game._block_at(Vector2i(2, 2)) as MergeBlock
	var observed := {
		"received": false,
		"scale": Vector2.ZERO,
		"label_scale": Vector2.ZERO,
		"shake_active": false,
		"shake_intensity": 0.0,
		"shake_duration": 0.0,
		"merge_fx_present": false,
	}
	game.combat_system.running = true
	game.combat_system.merge_attack_received.connect(func(_event: MergeAttackEvent):
		observed["received"] = true
		observed["scale"] = clicked.scale
		observed["label_scale"] = clicked._label_rect.scale
		observed["shake_active"] = game._merge_shake_active
		observed["shake_intensity"] = game._merge_shake_intensity
		observed["shake_duration"] = game._merge_shake_duration
		observed["merge_fx_present"] = game.game_layer.get_node_or_null("MergeFx") != null
	, CONNECT_ONE_SHOT)

	game._on_block_pressed(clicked)
	var deadline := Time.get_ticks_msec() + 1200
	while not bool(observed["received"]) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bool(observed["received"]), "a valid merge must dispatch its existing attack")
	_check((observed["scale"] as Vector2).is_equal_approx(Vector2.ONE * 0.90), "whole-block pop must already be at its 0.90 start scale when attack dispatch begins")
	_check((observed["label_scale"] as Vector2).is_equal_approx(Vector2.ONE), "number reveal must not run a competing scale tween")
	_check(bool(observed["shake_active"]), "screen shake must already be active when attack dispatch begins")
	_check(is_equal_approx(float(observed["shake_intensity"]), 6.0), "three-block merge must start the 6px shake")
	_check(is_equal_approx(float(observed["shake_duration"]), 0.12), "three-block merge must start the 0.12 second shake")
	_check(bool(observed["merge_fx_present"]), "merge effect must exist before attack dispatch begins")

	await _wait_seconds(0.24)
	_check(clicked.scale.is_equal_approx(Vector2.ONE), "result block must settle exactly back to scale 1 after one pop")
	_check(not game._merge_shake_active, "screen shake must finish after its approved duration")
	_check(game.game_layer.position.is_equal_approx(game._game_layer_base_position), "screen shake must return to the exact layout base")


func _test_reset_restores_layout(game) -> void:
	game._play_merge_screen_shake(6)
	await process_frame
	_check(game._merge_shake_active, "large shake fixture must start")
	game._clear_game_world()
	_check(not game._merge_shake_active, "clearing the battle must cancel screen shake")
	_check(game.game_layer.position.is_equal_approx(game._game_layer_base_position), "clearing the battle must restore the game-layer base position")


func _test_restricted_inputs_do_not_shake(game) -> void:
	game.first_create_blocks(false)
	for value in game.block_map.values():
		var block := value as MergeBlock
		if block:
			block.level = GameConfig.MAX_BLOCK_LEVEL
	var max_block := game._block_at(Vector2i(0, 0)) as MergeBlock
	game.game_status = game.GameStatus.START
	game._on_block_pressed(max_block)
	_check(not game._merge_shake_active, "maximum-level tap must not shake the battlefield")
	game.game_status = game.GameStatus.PAUSE
	game._on_block_pressed(max_block)
	_check(not game._merge_shake_active, "paused input must not shake the battlefield")


func _make_game():
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
	game._clear_game_world()
	game.first_create_blocks(false)
	for value in game.block_map.values():
		var block := value as MergeBlock
		if block:
			block.level = GameConfig.MAX_BLOCK_LEVEL
	for site in GROUP_SITES:
		(game._block_at(site) as MergeBlock).level = 1
	game.game_layer.visible = true
	game.game_status = game.GameStatus.START
	game._board_settlement_active = false
	return game


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
