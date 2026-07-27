extends SceneTree

const BoardRefillPolicyScript := preload("res://scripts/board_refill_policy.gd")

var failures: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_test_wave_monster_counts()
	_test_board_groups()
	_test_candidate_distribution()
	_test_v2_distribution()
	_test_dynamic_weights()
	_test_sliding_window()
	var settings := BalanceSimulationEngine.build_default_settings(2)
	settings["waves"] = (settings["waves"] as Array).slice(0, 3)
	var first := BalanceSimulationEngine.new().run_suite(settings)
	var second := BalanceSimulationEngine.new().run_suite(settings)
	_check(first["rows"].size() == 24, "2 runs x 4 scenarios x 3 strategies should create 24 rows")
	_check(first["summary"].size() == 21, "summary should contain 12 groups and 9 deltas")
	_check(JSON.stringify(first["rows"]) == JSON.stringify(second["rows"]), "fixed seeds should reproduce identical rows")
	_test_paired_initial_boards(first["rows"] as Array)
	_test_board_progression_suite()
	await _test_background_runner()
	await _test_background_cancellation()
	await _test_login_button()
	await _test_success_popup_card_arbitration()
	if failures.is_empty():
		print("BALANCE_SIMULATION_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_wave_monster_counts() -> void:
	var waves := GameConfig.get_level_waves()
	_check(waves.size() == GameConfig.LEVEL_WAVE_COUNT, "wave configuration should keep twenty waves")
	var previous_total := 0
	for wave_index in range(waves.size()):
		var wave := waves[wave_index] as Dictionary
		var total := int(wave.get("small", 0)) + int(wave.get("medium", 0)) + int(wave.get("large", 0))
		var expected := GameConfig.get_wave_monster_target_count(wave_index + 1)
		_check(total == expected, "each wave monster split should exactly match its linear target")
		_check(total >= previous_total, "wave monster totals should not decrease")
		_check(total <= GameConfig.WAVE_MONSTER_COUNT_MAX, "wave monster totals should never exceed sixty")
		previous_total = total
	_check(GameConfig.get_wave_monster_target_count(1) == 15, "first wave should contain fifteen monsters")
	_check(GameConfig.get_wave_monster_target_count(GameConfig.LEVEL_WAVE_COUNT) == 60, "last wave should contain sixty monsters")

func _test_board_groups() -> void:
	var fixture: Array[int] = [1, 1, 2, 3, 1, 2, 3, 3, 2]
	var groups := BalanceSimulationEngine.find_groups_for_board(fixture, 3)
	_check(groups.size() == 3, "fixed 3x3 board should contain three connected groups")
	for group in groups:
		_check(group.size() == 3, "every fixture group should contain three cells")

func _test_candidate_distribution() -> void:
	var counts := [0, 0, 0, 0, 0]
	var samples := 100000
	for index in range(samples):
		var roll := (float(index) + 0.5) / float(samples)
		var level := BalanceSimulationEngine.sample_candidate_refill_level(7, roll)
		counts[level - 1] += 1
	var expected := [0.05, 0.15, 0.35, 0.30, 0.15]
	for index in range(expected.size()):
		var actual := float(counts[index]) / float(samples)
		_check(absf(actual - float(expected[index])) <= 0.01, "candidate drop probability must stay within 1 percent")

func _test_v2_distribution() -> void:
	var counts := [0, 0, 0, 0, 0]
	var samples := 100000
	for index in range(samples):
		var roll := (float(index) + 0.5) / float(samples)
		var level := BalanceSimulationEngine.sample_v2_refill_level(7, roll)
		counts[level - 1] += 1
	var expected := [0.08, 0.24, 0.43, 0.20, 0.05]
	for index in range(expected.size()):
		var actual := float(counts[index]) / float(samples)
		_check(absf(actual - float(expected[index])) <= 0.01, "V2 drop probability must stay within 1 percent")

func _test_dynamic_weights() -> void:
	var fixture: Array[int] = [1, 4, 5, 4, 0, 4, 5, 4, 1]
	var base := BalanceSimulationEngine.get_v2_refill_weights(7)
	var dynamic := BalanceSimulationEngine.get_dynamic_v2_weights(7, fixture, 3, 4)
	var total := 0.0
	for index in range(dynamic.size()):
		var weight := dynamic[index]
		total += weight
		if base[index] > 0.0:
			_check(weight >= 0.03 - 0.0001, "dynamic probabilities should respect the 3 percent floor")
			_check(weight <= 0.55 + 0.0001, "dynamic probabilities should respect the 55 percent ceiling")
	_check(absf(total - 1.0) < 0.0001, "dynamic V2 weights should normalize to one")
	_check(dynamic[3] > base[3], "matching orthogonal neighbors should increase that level weight")
	_check(dynamic[1] < base[1], "missing board levels should reduce their weight")

func _test_sliding_window() -> void:
	var opening := BoardRefillPolicyScript.get_dynamic_weights(4, [1, 2, 3, 1, 0, 2, 3, 1, 2], 3, 4)
	_check(opening == [0.33, 0.34, 0.33], "runtime policy should preserve the original 1/2/3 opening distribution")
	var uniform := BalanceSimulationEngine.get_sliding_window_weights(8)
	var progression := BalanceSimulationEngine.get_sliding_progression_weights(8)
	_check(uniform.size() == 8 and progression.size() == 8, "sliding windows should extend to the historical highest level")
	for index in range(3):
		_check(is_zero_approx(uniform[index]) and is_zero_approx(progression[index]), "levels below the five-level window should have zero probability")
	for index in range(3, 8):
		_check(absf(uniform[index] - 0.20) < 0.0001, "uniform sliding window should contain five equal levels")
	_check(absf(progression[3] - 0.32) < 0.0001 and absf(progression[7] - 0.05) < 0.0001, "progression window should favor its lower levels")
	var fixture: Array[int] = [4, 5, 6, 7, 0, 8, 4, 6, 7]
	var analysis := BalanceSimulationEngine.get_state_scored_analysis(progression, 8, fixture, 3, 4, BalanceSimulationEngine.SLIDING_CURRENT_MAX_DROP_CAP)
	var weights := analysis["weights"] as Array[float]
	_check(weights[7] <= BalanceSimulationEngine.SLIDING_CURRENT_MAX_DROP_CAP + 0.0001, "the current highest drop should respect its 5 percent cap")
	var runtime_weights: Array[float] = BoardRefillPolicyScript.get_dynamic_weights(8, fixture, 3, 4)
	_check(runtime_weights.size() == 8, "runtime sliding policy should expose weights through the historical maximum")
	for index in range(3):
		_check(is_zero_approx(runtime_weights[index]), "runtime policy should remove levels below the active five-level window")
	_check(runtime_weights[7] <= BoardRefillPolicyScript.CURRENT_MAX_DROP_CAP + 0.0001, "runtime policy should cap direct drops of the current maximum")

func _test_board_progression_suite() -> void:
	var settings := BalanceSimulationEngine.build_default_settings(1)
	settings["merge_limit"] = 20
	var result := BalanceSimulationEngine.new().run_board_progression_suite(settings)
	_check((result["rows"] as Array).size() == 12, "board-only suite should create four scenarios by three strategies")
	_check((result["summary"] as Array).size() == 12, "board-only summary should contain twelve groups")

func _test_paired_initial_boards(rows: Array) -> void:
	for strategy in BalanceSimulationEngine.STRATEGIES:
		for run_index in range(2):
			var seed_value := BalanceSimulationEngine.BASE_SEED + run_index
			var current := _find_row(rows, "current", strategy, seed_value)
			for scenario in BalanceSimulationEngine.SCENARIOS:
				var candidate := _find_row(rows, scenario, strategy, seed_value)
				_check(not current.is_empty() and not candidate.is_empty(), "paired rows should exist")
				if not current.is_empty() and not candidate.is_empty():
					_check(current["initial_board"] == candidate["initial_board"], "paired scenarios must share the same initial board")

func _test_background_runner() -> void:
	var runner := BalanceSimulationRunner.new()
	root.add_child(runner)
	var state := {"done": false, "result": {}, "error": ""}
	runner.simulation_completed.connect(func(result: Dictionary): state["done"] = true; state["result"] = result)
	runner.simulation_failed.connect(func(message: String): state["done"] = true; state["error"] = message)
	_check(runner.start_standard(1), "background runner should start")
	var deadline := Time.get_ticks_msec() + 10000
	while not bool(state["done"]) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bool(state["done"]), "background runner should finish within timeout")
	_check(str(state["error"]).is_empty(), "background runner should not fail")
	var result := state["result"] as Dictionary
	if not result.is_empty():
		var summary_path := str(result.get("summary_path", ""))
		var runs_path := str(result.get("runs_path", ""))
		_check(FileAccess.file_exists(summary_path), "summary CSV should exist")
		_check(FileAccess.file_exists(runs_path), "runs CSV should exist")
		if FileAccess.file_exists(summary_path):
			DirAccess.remove_absolute(summary_path)
		if FileAccess.file_exists(runs_path):
			DirAccess.remove_absolute(runs_path)
	runner.queue_free()
	await process_frame
	await process_frame

func _test_background_cancellation() -> void:
	var runner := BalanceSimulationRunner.new()
	root.add_child(runner)
	var state := {"done": false, "cancelled": false, "error": ""}
	runner.simulation_cancelled.connect(func(): state["done"] = true; state["cancelled"] = true)
	runner.simulation_completed.connect(func(_result: Dictionary): state["done"] = true)
	runner.simulation_failed.connect(func(message: String): state["done"] = true; state["error"] = message)
	_check(runner.start_standard(100), "cancellation runner should start")
	runner.cancel()
	var deadline := Time.get_ticks_msec() + 10000
	while not bool(state["done"]) and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(bool(state["done"]), "cancelled runner should finish within timeout")
	_check(bool(state["cancelled"]), "cancelled runner should emit simulation_cancelled")
	_check(str(state["error"]).is_empty(), "cancelled runner should not fail")
	runner.queue_free()
	await process_frame
	await process_frame

func _test_login_button() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true
	var battle_layer := game.combat_system.battle_layer as BattleLayerView
	var crystal_view := battle_layer.get_crystal_view()
	_check(battle_layer.get_node_or_null("DesignRoot/DecorLayer/Castle") == null, "legacy castle visual should be removed from the battle scene")
	_check(crystal_view != null, "merged crystal/castle view should exist")
	if crystal_view:
		_check(crystal_view.position.is_equal_approx(GameConfig.CRYSTAL_CASTLE_PANEL_POSITION), "crystal should occupy the former castle footprint")
		_check(game.combat_system.castle_system._view == crystal_view, "castle durability system should target the crystal view")
		_check(game.combat_system.crystal_system._crystal_view == crystal_view, "crystal attack system should keep the same merged view")
		_check(game.combat_system.crystal_system.get_crystal_center_global().is_equal_approx(crystal_view.get_attack_origin_global()), "crystal projectile origin should follow the relocated merged view")
		game.combat_system.crystal_system.notify_merge_level(3)
		_check(game.combat_system.crystal_system.get_crystal_level() == 1 and crystal_view.get_crystal_level() == 1, "early-game merge upgrades should stay disabled")
		game.combat_system.crystal_system.set_merge_upgrade_enabled(true)
		game.combat_system.crystal_system.notify_merge_level(3)
		_check(game.combat_system.crystal_system.get_crystal_level() == 2 and crystal_view.get_crystal_level() == 2, "later systems should be able to re-enable the preserved upgrade progression")
		game.combat_system.crystal_system.set_merge_upgrade_enabled(false)
		game.combat_system.castle_system.reset()
		game.combat_system.castle_system.damage(3)
		await process_frame
		var durability_label := crystal_view.get_node_or_null("DurabilityLabel") as Label
		_check(durability_label != null and durability_label.text == "17/20", "merged crystal should retain the local durability UI")
	game.loading_view.set_interactive(true)
	var button := game.loading_view.get_node_or_null("DesignRoot/BalanceSimulationButton") as Button
	_check(button != null, "login page should expose the temporary simulation button")
	if button:
		button.pressed.emit()
		await process_frame
		_check(game.get_node_or_null("BalanceSimulationPanel") != null, "simulation button should open the result panel")
	game.queue_free()
	await process_frame
	await process_frame


func _test_success_popup_card_arbitration() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game := packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true
	game._success_popup_active = true
	game._skill_choice_pending = true
	game._try_open_card_choice()
	_check(game.active_card_modal == null, "highest-level popup should block the skill choice modal")
	_check(game._skill_choice_pending, "blocked skill choice should remain pending until Continue")
	game._seen_card_ids.clear()
	for card_id in CardCatalog.ALL_CARD_IDS:
		game._seen_card_ids.append(card_id)
	game.game_status = 3 # MainGame.GameStatus.PAUSE
	game._close_success_popup()
	await process_frame
	_check(game.active_card_modal != null, "Continue should open the pending skill choice after closing the highest-level popup")
	game._reset_card_runtime()
	game.queue_free()
	await process_frame
	await process_frame

func _find_row(rows: Array, scenario: String, strategy: String, seed_value: int) -> Dictionary:
	for value in rows:
		var row := value as Dictionary
		if row["scenario"] == scenario and row["strategy"] == strategy and int(row["seed"]) == seed_value:
			return row
	return {}

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
