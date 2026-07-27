extends SceneTree

var _failed := false


func _init() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	game._reset_card_runtime()
	game._clear_game_world()
	game.first_create_blocks(false)
	game.game_status = game.GameStatus.START
	for value in game.block_map.values():
		var block := value as MergeBlock
		if block:
			block.level = 1

	game.skill_imprint_system.choose_skill("ascension_hammer", 1)
	var clicked := game._block_at(Vector2i(0, 0)) as MergeBlock
	game.select_next_blocks(clicked)
	game.merge_selected_blocks(clicked)
	await _wait_seconds(3.20)

	_check(not game.skill_imprint_system.has_pending_skill(), "valid merge should consume the prepared imprint")
	_check(clicked.level >= 2, "base merge result should exist before imprint resolution")
	_check(clicked.skill_imprint_id.is_empty(), "legacy block imprint field must stay unused by the new flow")

	game.queue_free()
	await process_frame
	print("SKILL_IMPRINT_MERGE_SMOKE_OK" if not _failed else "SKILL_IMPRINT_MERGE_SMOKE_FAILED")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame
