extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_damage_formula()
	_test_runtime_attribute_cycle()
	_test_merge_feedback_presentation_tiers()
	_test_runtime_card_pools()
	_test_attack_rule_simulation()
	await _test_merge_feedback_lifecycle()
	await _test_runtime_focus_sequence()
	await _test_ice_multitarget_sequence()
	await _test_lightning_bounce_sequence()
	await _test_retarget_during_flight()
	await _test_retarget_after_reaching_goal()
	await _test_no_target_stops_sequence()
	await _test_independent_sequences()
	await _test_single_shot_attribute_basis()
	await _test_reset_cancels_sequence()
	if failures.is_empty():
		print("MERGE_COMBO_ATTACK_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_damage_formula() -> void:
	for merge_count in range(2, 7):
		var event := MergeAttackEvent.from_merge(1, 4, merge_count, Vector2.ZERO, 0)
		var expected_total := 10.0 * float(merge_count - 1)
		_check(event.attack_count == merge_count, "merge %d should create %d attacks" % [merge_count, merge_count])
		_check(is_equal_approx(event.total_damage, expected_total), "merge %d should preserve old total output" % merge_count)
		_check(is_equal_approx(event.damage * float(event.attack_count), expected_total), "merge %d shot sum should equal total damage" % merge_count)
		var ice_event := MergeAttackEvent.from_merge(2, 4, merge_count, Vector2.ZERO, 0)
		_check(ice_event.target_count == merge_count - 1, "ice merge %d should target N-1 monsters" % merge_count)
		_check(ice_event.attack_count == merge_count - 1, "ice merge %d should fire once per target" % merge_count)
		_check(is_equal_approx(ice_event.damage, 10.0), "ice should deal one full base hit per target")
		_check(is_equal_approx(ice_event.total_damage, expected_total), "ice should preserve B*(N-1) total output")
		var lightning_event := MergeAttackEvent.from_merge(3, 4, merge_count, Vector2.ZERO, 0)
		_check(lightning_event.target_count == 1 and lightning_event.attack_count == 1, "lightning should have one primary strike")
		_check(
			int(lightning_event.effect_params.get("chain_count", 0)) == 1 + merge_count - 2,
			"lightning merge %d should add one bounce per extra block" % merge_count
		)


func _test_runtime_attribute_cycle() -> void:
	var expected := ["poison", "ice", "lightning", "critical", "fire"]
	for level in range(1, GameConfig.MAX_BLOCK_LEVEL + 1):
		var element_key := GameConfig.get_element_key_for_level(level)
		_check(element_key == expected[posmod(level - 1, expected.size())], "level %d should follow the five-color attribute cycle" % level)
		_check(GameConfig.COLOR_ELEMENT[GameConfig.get_block_color_name(level)] == GameConfig.get_element_for_level(level), "level %d color and attack attribute must stay aligned" % level)


func _test_merge_feedback_presentation_tiers() -> void:
	var cases := [
		{"merge_count": 2, "tier": 1, "scale": 1.0},
		{"merge_count": 3, "tier": 1, "scale": 1.0},
		{"merge_count": 4, "tier": 2, "scale": 1.16},
		{"merge_count": 5, "tier": 2, "scale": 1.16},
		{"merge_count": 6, "tier": 3, "scale": 1.32},
		{"merge_count": 12, "tier": 3, "scale": 1.32},
	]
	for case_value in cases:
		var presentation := MergeAttackPromptView.get_merge_presentation(int(case_value["merge_count"]))
		_check(int(presentation["tier"]) == int(case_value["tier"]), "merge %d should use feedback tier %d" % [int(case_value["merge_count"]), int(case_value["tier"])])
		_check(is_equal_approx(float(presentation["icon_scale"]), float(case_value["scale"])), "merge %d should use the configured icon scale" % int(case_value["merge_count"]))


func _test_runtime_card_pools() -> void:
	var retired := ["frost_bell", "thunder_ballista", "frost_prism", "thunder_spire"]
	_check(CardCatalog.BOARD_CARD_IDS.size() == 6, "runtime board pool should contain six cards")
	_check(CardCatalog.CRYSTAL_CARD_IDS.size() == 6, "runtime crystal pool should contain six cards")
	for card_id in retired:
		_check(not CardCatalog.ALL_CARD_IDS.has(card_id), "%s must not appear in runtime card choices" % card_id)
		_check(not CardCatalog.get_definition(card_id).is_empty(), "%s definition should remain archived" % card_id)


func _test_attack_rule_simulation() -> void:
	var settings := BalanceSimulationEngine.build_default_settings(1)
	settings["waves"] = (settings["waves"] as Array).slice(0, 2)
	var result := BalanceSimulationEngine.new().run_attack_rule_suite(settings)
	var rows := result["rows"] as Array
	_check(rows.size() == 6, "attack comparison should create two rules by three strategies")
	_check((result["summary"] as Array).size() == 9, "attack comparison should include six groups and three paired deltas")
	for strategy in BalanceSimulationEngine.STRATEGIES:
		var legacy := _find_row(rows, "attack_legacy", strategy)
		var combo := _find_row(rows, "attack_combo_focus", strategy)
		_check(not legacy.is_empty() and not combo.is_empty(), "paired attack rows should exist")
		if not legacy.is_empty() and not combo.is_empty():
			_check(legacy["initial_board"] == combo["initial_board"], "paired attack rules should share initial board")
			_check(legacy["spawn_order_hash"] == combo["spawn_order_hash"], "paired attack rules should share monster order")
			_check(combo.has("board_overkill_damage") and combo.has("avg_front_kill_time"), "combo reports should expose requested diagnostics")


func _test_merge_feedback_lifecycle() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	_spawn_fixture_monster(combat, 100.0, 0.80)
	var event := MergeAttackEvent.from_merge(1, 4, 2, Vector2(320.0, 900.0), 2)
	var state := {"fired": 0}
	combat.merge_shot_fired.connect(func(_sequence: int, _shot: int, _target: Monster): state["fired"] = int(state["fired"]) + 1)
	combat.handle_merge_attack(event)
	await process_frame
	_check(combat.effect_system._merge_feedbacks.has(event.sequence_id), "merge feedback should appear before projectile launch")
	await _wait_seconds(MergeAttackPromptView.ENTER_DURATION * 0.5)
	_check(int(state["fired"]) == 0, "projectile should wait for merge feedback entrance")
	await _wait_seconds(MergeAttackPromptView.ENTER_DURATION * 0.75)
	_check(int(state["fired"]) == 1, "projectile should launch after merge feedback entrance")
	_check(combat.effect_system._merge_feedbacks.has(event.sequence_id), "merge feedback should remain during the attack sequence")
	await _wait_seconds(ProjectileSystem.MERGE_BOLT_DURATION + MergeAttackPromptView.EXIT_DURATION + 0.08)
	_check(not combat.effect_system._merge_feedbacks.has(event.sequence_id), "merge feedback should clear after the attack sequence finishes")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_runtime_focus_sequence() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var first: Monster = _spawn_fixture_monster(combat, 20.0, 0.80)
	var second: Monster = _spawn_fixture_monster(combat, 100.0, 0.50)
	var first_id := first.get_instance_id()
	var second_id := second.get_instance_id()
	var resolved_targets: Array[int] = []
	combat.merge_shot_resolved.connect(func(_sequence: int, _shot: int, target: Monster, _damage: float, _killed: bool): resolved_targets.append(target.get_instance_id()))
	var event := MergeAttackEvent.from_merge(1, 4, 5, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(event)
	await _wait_seconds(1.25)
	_check(resolved_targets.size() == 5, "five-block merge should resolve five attacks")
	if resolved_targets.size() == 5:
		_check(resolved_targets[0] == first_id and resolved_targets[1] == first_id and resolved_targets[2] == first_id, "sequence should focus the front monster until death")
		_check(resolved_targets[3] == second_id and resolved_targets[4] == second_id, "shots after the kill should switch to the next monster")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_ice_multitarget_sequence() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var targets: Array[Monster] = [
		_spawn_fixture_monster(combat, 100.0, 0.80),
		_spawn_fixture_monster(combat, 100.0, 0.70),
		_spawn_fixture_monster(combat, 100.0, 0.60),
		_spawn_fixture_monster(combat, 100.0, 0.50),
	]
	var event := MergeAttackEvent.from_merge(2, 4, 4, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(event)
	await _wait_seconds(0.70)
	for index in range(3):
		_check(targets[index].hp < targets[index].max_hp, "ice N-1 target %d should take damage" % index)
		_check(not targets[index].freeze_status.is_empty(), "ice N-1 target %d should be slowed" % index)
	_check(is_equal_approx(targets[3].hp, targets[3].max_hp), "ice must not hit beyond its N-1 target budget")
	_check(targets[3].freeze_status.is_empty(), "the fourth monster must not be frozen by a four-block merge")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_lightning_bounce_sequence() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var targets: Array[Monster] = [
		_spawn_fixture_monster(combat, 100.0, 0.80),
		_spawn_fixture_monster(combat, 100.0, 0.70),
		_spawn_fixture_monster(combat, 100.0, 0.60),
		_spawn_fixture_monster(combat, 100.0, 0.50),
	]
	var event := MergeAttackEvent.from_merge(3, 4, 4, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(event)
	await _wait_seconds(0.70)
	for index in range(4):
		_check(targets[index].hp < targets[index].max_hp, "lightning primary/bounce target %d should take damage" % index)
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_retarget_during_flight() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var first: Monster = _spawn_fixture_monster(combat, 100.0, 0.82)
	var second: Monster = _spawn_fixture_monster(combat, 100.0, 0.52)
	var first_id := first.get_instance_id()
	var second_id := second.get_instance_id()
	var state := {"resolved_id": 0}
	combat.merge_shot_fired.connect(func(_sequence: int, shot: int, target: Monster):
		if shot == 0 and target.get_instance_id() == first_id:
			target.kill("test")
	)
	combat.merge_shot_resolved.connect(func(_sequence: int, shot: int, target: Monster, _damage: float, _killed: bool):
		if shot == 0:
			state["resolved_id"] = target.get_instance_id()
	)
	combat.handle_merge_attack(MergeAttackEvent.from_merge(1, 3, 2, Vector2(320.0, 900.0), 2))
	await _wait_seconds(0.50)
	_check(int(state["resolved_id"]) == second_id, "a target killed during flight should retarget the next front monster")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_retarget_after_reaching_goal() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var first: Monster = _spawn_fixture_monster(combat, 100.0, 0.82)
	var second: Monster = _spawn_fixture_monster(combat, 100.0, 0.52)
	var first_id := first.get_instance_id()
	var second_id := second.get_instance_id()
	var state := {"resolved_id": 0}
	combat.merge_shot_fired.connect(func(_sequence: int, shot: int, target: Monster):
		if shot == 0 and target.get_instance_id() == first_id:
			target.reached = true
	)
	combat.merge_shot_resolved.connect(func(_sequence: int, shot: int, target: Monster, _damage: float, _killed: bool):
		if shot == 0:
			state["resolved_id"] = target.get_instance_id()
	)
	combat.handle_merge_attack(MergeAttackEvent.from_merge(1, 3, 2, Vector2(320.0, 900.0), 2))
	await _wait_seconds(0.50)
	_check(int(state["resolved_id"]) == second_id, "a target reaching the crystal during flight should retarget the next monster")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_no_target_stops_sequence() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var state := {"fired": 0, "finished": -1}
	combat.merge_shot_fired.connect(func(_sequence: int, _shot: int, _target: Monster): state["fired"] = int(state["fired"]) + 1)
	combat.merge_sequence_finished.connect(func(_sequence: int, fired_count: int): state["finished"] = fired_count)
	combat.handle_merge_attack(MergeAttackEvent.from_merge(1, 4, 5, Vector2(320.0, 900.0), 2))
	await _wait_seconds(MergeAttackPromptView.ENTER_DURATION + 0.08)
	_check(int(state["fired"]) == 0 and int(state["finished"]) == 0, "no target should discard every remaining shot immediately")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_independent_sequences() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	_spawn_fixture_monster(combat, 1000.0, 0.70)
	var first_event := MergeAttackEvent.from_merge(1, 3, 2, Vector2(280.0, 900.0), 2)
	var second_event := MergeAttackEvent.from_merge(4, 4, 3, Vector2(380.0, 900.0), 2)
	var counts := {first_event.sequence_id: 0, second_event.sequence_id: 0}
	combat.merge_shot_resolved.connect(func(sequence_id: int, _shot: int, _target: Monster, _damage: float, _killed: bool):
		if counts.has(sequence_id):
			counts[sequence_id] = int(counts[sequence_id]) + 1
	)
	combat.handle_merge_attack(first_event)
	combat.handle_merge_attack(second_event)
	await _wait_seconds(0.85)
	_check(int(counts[first_event.sequence_id]) == 2, "first merge sequence should keep its own two shots")
	_check(int(counts[second_event.sequence_id]) == 3, "second merge sequence should independently keep its three shots")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_single_shot_attribute_basis() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	var target: Monster = _spawn_fixture_monster(combat, 500.0, 0.70)
	var poison_event := MergeAttackEvent.from_merge(1, 4, 2, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(poison_event)
	await _wait_seconds(0.42)
	_check(is_equal_approx(float(target.poison_status.get("atk", 0.0)), poison_event.damage), "poison should use per-shot damage")
	var ice_event := MergeAttackEvent.from_merge(2, 4, 2, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(ice_event)
	await _wait_seconds(0.42)
	_check(is_equal_approx(float(target.freeze_status.get("slow_percent", 0.0)), float(ice_event.effect_params.get("slow_percent", 0.0))), "ice should apply its per-shot slow")
	var lightning_target: Monster = _spawn_fixture_monster(combat, 500.0, 0.35)
	var lightning_hp_before := lightning_target.hp
	var lightning_event := MergeAttackEvent.from_merge(3, 4, 2, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(lightning_event)
	await _wait_seconds(0.46)
	_check(lightning_target.hp < lightning_hp_before, "lightning should damage a secondary monster through chain hops")
	var fire_event := MergeAttackEvent.from_merge(5, 4, 2, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(fire_event)
	await _wait_seconds(0.42)
	_check(is_equal_approx(float(target.burn_status.get("atk", 0.0)), fire_event.damage), "burn should use per-shot damage")
	var critical_event := MergeAttackEvent.from_merge(4, 4, 2, Vector2(320.0, 900.0), 2)
	critical_event.effect_params["crit_chance"] = 1.0
	critical_event.effect_params["crit_multiplier"] = 2.0
	var critical_state := {"damage": 0.0}
	combat.merge_shot_resolved.connect(func(sequence_id: int, shot: int, _hit_target: Monster, damage: float, _killed: bool):
		if sequence_id == critical_event.sequence_id and shot == 0:
			critical_state["damage"] = damage
	)
	combat.handle_merge_attack(critical_event)
	await _wait_seconds(0.42)
	_check(is_equal_approx(float(critical_state["damage"]), critical_event.damage * 2.0), "critical should multiply only the current shot")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _test_reset_cancels_sequence() -> void:
	var fixture := await _make_combat_fixture()
	var game = fixture["game"]
	var combat: CombatSystem = fixture["combat"]
	_spawn_fixture_monster(combat, 1000.0, 0.70)
	var resolved_count := 0
	combat.merge_shot_resolved.connect(func(_sequence: int, _shot: int, _target: Monster, _damage: float, _killed: bool): resolved_count += 1)
	var event := MergeAttackEvent.from_merge(1, 4, 5, Vector2(320.0, 900.0), 2)
	combat.handle_merge_attack(event)
	_check(combat.effect_system._merge_feedbacks.has(event.sequence_id), "reset fixture should register merge feedback before cancellation")
	combat.reset()
	_check(not combat.effect_system._merge_feedbacks.has(event.sequence_id), "reset should clear pending merge feedback")
	await _wait_seconds(0.45)
	_check(resolved_count == 0, "reset should cancel pending projectile hits and delayed attacks")
	_cleanup_game(game)
	await process_frame
	await process_frame


func _make_combat_fixture() -> Dictionary:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true
	var combat := game.combat_system as CombatSystem
	combat.reset()
	combat.running = true
	combat.monster_system.start()
	combat.wave_system.stop()
	if combat.crystal_system:
		combat.crystal_system.stop()
	return {"game": game, "combat": combat}


func _spawn_fixture_monster(combat: CombatSystem, hp: float, progress: float) -> Monster:
	var monster := combat.monster_system.spawn_monster("small", 1.0, {"hp": hp, "speed": 0.0})
	monster.path_progress = progress
	monster.position = combat.path_system.position_at_progress(progress) - monster.get_path_anchor_offset()
	return monster


func _find_row(rows: Array, scenario: String, strategy: String) -> Dictionary:
	for value in rows:
		var row := value as Dictionary
		if row.get("scenario", "") == scenario and row.get("strategy", "") == strategy:
			return row
	return {}


func _cleanup_game(game) -> void:
	if game != null and is_instance_valid(game):
		game.queue_free()


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
