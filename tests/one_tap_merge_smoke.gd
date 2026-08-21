extends SceneTree

const GROUP_SITES: Array[Vector2i] = [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)]

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for target_site in GROUP_SITES:
		var game = await _make_game()
		var clicked := game._block_at(target_site) as MergeBlock
		var merge_count_before: int = int(game._run_merge_count)
		game._on_block_pressed(clicked)
		_check(game.game_status == game.GameStatus.PAUSE, "valid group must begin merging on its first tap: %s" % target_site)
		_check(game._run_merge_count == merge_count_before + 1, "first tap must submit exactly one merge: %s" % target_site)
		await _wait_seconds(0.58)
		_check(clicked != null and is_instance_valid(clicked) and clicked.level == 2, "result must remain on the tapped cell: %s" % target_site)
		_check(clicked.board_site == target_site, "result board site must equal the tapped site: %s" % target_site)
		game.queue_free()
		await process_frame
		await process_frame

	var invalid_game = await _make_game()
	var isolated := invalid_game._block_at(Vector2i(0, 0)) as MergeBlock
	isolated.level = 1
	var base_position := isolated.position
	var merge_count_before: int = int(invalid_game._run_merge_count)
	invalid_game._on_block_pressed(isolated)
	await _wait_seconds(0.05)
	_check(invalid_game.game_status == invalid_game.GameStatus.START, "isolated tap must not pause the board")
	_check(invalid_game._run_merge_count == merge_count_before, "isolated tap must not create a merge attack")
	_check(invalid_game.selected_blocks.is_empty() and not isolated.selected, "isolated tap must leave no selection state")
	_check(not isolated.position.is_equal_approx(base_position), "isolated tap must retain the existing shake feedback")
	invalid_game.queue_free()
	await process_frame

	if failures.is_empty():
		print("ONE_TAP_MERGE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


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
