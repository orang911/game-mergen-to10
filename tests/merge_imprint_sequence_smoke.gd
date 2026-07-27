extends SceneTree

var _failed := false
var _order: Array[String] = []
var _attack_sequence_id := -1
var _attack_finished := false
var _flight_started := false
var _flight_finished := false
var _arc_observed := false
var _trail_observed := false
var _min_flight_scale := 10.0
var _max_release_scale := 0.0
var _cancel_received := false
var _cancel_value := true


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.muted = true
	game._reset_card_runtime()
	game._clear_game_world()
	game.first_create_blocks(false)
	game.game_status = game.GameStatus.START

	# Keep exactly one adjacent pair so the fixture produces two attacks.
	for value in game.block_map.values():
		var block := value as MergeBlock
		if block:
			block.level = 2 + ((block.board_site.x + block.board_site.y) % 2)
	var clicked := game._block_at(Vector2i(0, 0)) as MergeBlock
	var partner := game._block_at(Vector2i(1, 0)) as MergeBlock
	clicked.level = 1
	partner.level = 1

	var combat := game.combat_system as CombatSystem
	combat.reset()
	combat.running = true
	combat.monster_system.start()
	combat.wave_system.stop()
	if combat.crystal_system:
		combat.crystal_system.stop()
	var target := combat.monster_system.spawn_monster("small", 1.0, {"hp": 999.0, "speed": 0.0})
	target.path_progress = 0.72
	target.position = combat.path_system.position_at_progress(0.72) - target.get_path_anchor_offset()

	combat.merge_attack_received.connect(func(event: MergeAttackEvent):
		_attack_sequence_id = event.sequence_id
		_order.append("merge_attack_started")
	)
	combat.merge_sequence_finished.connect(func(sequence_id: int, _fired_count: int):
		if sequence_id != _attack_sequence_id:
			return
		_attack_finished = true
		_order.append("merge_sequence_finished")
		_check(game.energy_hud.get_node_or_null("PendingImprintFly") == null, "imprint must not fly before the attack sequence finishes")
	)
	game.energy_hud.pending_imprint_trigger_finished.connect(func(completed: bool):
		if not completed:
			return
		_flight_finished = true
		_order.append("imprint_flight_finished")
		_check(clicked.level == 2, "imprint effect must still be unapplied when flight completion is emitted")
	)
	game.skill_imprint_system.pending_skill_changed.connect(func(skill_id: String, _quality: int):
		if skill_id.is_empty() and _flight_finished:
			_order.append("pending_skill_consumed")
	)

	game.skill_imprint_system.choose_skill("ascension_hammer", 1)
	game.select_next_blocks(clicked)
	game.merge_selected_blocks(clicked)

	var deadline := Time.get_ticks_msec() + 5000
	while Time.get_ticks_msec() < deadline:
		var ghost := game.energy_hud.get_node_or_null("PendingImprintFly") as TextureRect
		if ghost and is_instance_valid(ghost):
			if not _flight_started:
				_flight_started = true
				_order.append("imprint_flight_started")
				_check(_attack_finished, "imprint flight must start only after all merge attacks finish")
			_trail_observed = _trail_observed or game.energy_hud.get_node_or_null("PendingImprintTrail") != null
			var scale_value := ghost.scale.x
			_min_flight_scale = minf(_min_flight_scale, scale_value)
			_max_release_scale = maxf(_max_release_scale, scale_value)
			var start: Vector2 = game.energy_hud._pending_flight_start_global
			var finish: Vector2 = game.energy_hud._pending_flight_target_global
			var center := ghost.global_position + ghost.size * 0.5
			var direction := finish - start
			if direction.length_squared() > 0.001:
				var progress := clampf((center.x - start.x) / direction.x, 0.0, 1.0) if absf(direction.x) > 1.0 else clampf((center - start).dot(direction) / direction.length_squared(), 0.0, 1.0)
				var linear_y := lerpf(start.y, finish.y, progress)
				if progress > 0.20 and progress < 0.80 and center.y < linear_y - 16.0:
					_arc_observed = true
		if _flight_finished and clicked.level == 3 and not _order.has("imprint_effect_applied"):
			_order.append("imprint_effect_applied")
			_check(game.skill_imprint_system.has_pending_skill(), "imprint should remain pending until its effect finishes")
		if _order.has("pending_skill_consumed"):
			break
		await process_frame

	_check(_attack_finished, "merge attack should reach its real finished signal")
	_check(_flight_started and _flight_finished, "pending imprint should complete its flight")
	_check(_arc_observed, "imprint flight should rise above the straight line path")
	_check(_trail_observed, "curved imprint flight should keep the glowing trail")
	_check(_min_flight_scale <= 0.70, "imprint should shrink during perspective flight")
	_check(_max_release_scale >= 1.15, "imprint should enlarge when released at the merge point")
	_check(_comes_before("merge_sequence_finished", "imprint_flight_started"), "attack finish must precede flight start")
	_check(_comes_before("imprint_flight_finished", "imprint_effect_applied"), "flight finish must precede imprint activation")
	_check(_comes_before("imprint_effect_applied", "pending_skill_consumed"), "imprint activation must precede pending-slot consumption")
	_check(_comes_before("imprint_flight_finished", "pending_skill_consumed"), "flight finish must precede imprint consumption")
	_check(clicked.level == 3, "ascension imprint should apply only after the flight")
	await _test_cancelled_attack(combat)

	game.queue_free()
	await process_frame
	await _test_cancelled_flight()
	print("MERGE_IMPRINT_SEQUENCE_SMOKE_OK" if not _failed else "MERGE_IMPRINT_SEQUENCE_SMOKE_FAILED")
	quit(1 if _failed else 0)


func _test_cancelled_flight() -> void:
	var hud := EnergyHud.new()
	root.add_child(hud)
	await process_frame
	_cancel_received = false
	_cancel_value = true
	hud.pending_imprint_trigger_finished.connect(func(completed: bool):
		_cancel_received = true
		_cancel_value = completed
	)
	hud.set_pending_skill("ascension_hammer", 1)
	_check(hud.play_pending_imprint_trigger(Vector2(460.0, 520.0)), "cancel fixture should start imprint flight")
	await process_frame
	hud.clear_fx()
	await process_frame
	_check(_cancel_received and not _cancel_value, "clearing HUD effects should cancel the waiting imprint flight")
	_check(hud.get_node_or_null("PendingImprintFly") == null, "cancelled flight should leave no icon")
	_check(hud.get_node_or_null("PendingImprintTrail") == null, "cancelled flight should leave no trail")
	hud.queue_free()
	await process_frame


func _test_cancelled_attack(combat: CombatSystem) -> void:
	combat.running = true
	var event := MergeAttackEvent.from_merge(1, 2, 2, Vector2(320.0, 900.0), 0)
	combat.handle_merge_attack(event)
	await process_frame
	combat.reset()
	await process_frame
	var outcome = combat.get_merge_sequence_outcome(event.sequence_id)
	_check(outcome != null and not bool(outcome), "combat reset should publish a cancelled merge-sequence outcome")


func _comes_before(first: String, second: String) -> bool:
	var first_index := _order.find(first)
	var second_index := _order.find(second)
	return first_index >= 0 and second_index >= 0 and first_index < second_index


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
