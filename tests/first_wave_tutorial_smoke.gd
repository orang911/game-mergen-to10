extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true
	game._first_wave_tutorial_completed = false
	game._crystal_awakened_unlocked = false
	game.start_game()
	await _wait_seconds(1.55)

	var tutorial: FirstWaveTutorialController = game._first_wave_tutorial
	_check(tutorial != null and tutorial.is_active(), "new run should start the first-wave tutorial")
	_check(game.combat_system.is_first_wave_tutorial_active(), "combat should use the scripted first wave")
	_check(not game.combat_system.crystal_system.is_awakened(), "tutorial crystal should start dormant")
	_check(game.combat_system.wave_system.get_current_wave_total() == 5, "tutorial wave should replace wave one with five monsters")
	_check(game._cluster_swap_item_count == 0 and not game.energy_hud._crystal_rain_enabled, "instant items should be locked during tutorial")
	_check(tutorial.can_interact_with_site(Vector2i(1, 1)), "highlighted tutorial group should accept input")
	_check(not tutorial.can_interact_with_site(Vector2i(0, 0)), "other board cells should reject input before first merge")
	_check(game._block_at(Vector2i(1, 1)).level == 1 and game._block_at(Vector2i(2, 1)).level == 1 and game._block_at(Vector2i(3, 1)).level == 1, "fixed board should contain the three highlighted ones")
	var first_attack := MergeAttackEvent.from_merge(1, 2, 3, Vector2.ZERO, 1)
	_check(first_attack.attack_count == 3, "the first three-one merge should create three attacks")
	_check(is_equal_approx(first_attack.total_damage, 8.0), "the first three-one merge should preserve eight total damage")
	_check(is_equal_approx(first_attack.damage, 8.0 / 3.0), "tutorial attacks should use the shared per-shot formula")

	# Avoid touching the developer's real save file while still exercising the
	# full visual/combat state machine.
	var save_callback := Callable(game, "_on_tutorial_awakening_committed")
	if tutorial.awakening_committed.is_connected(save_callback):
		tutorial.awakening_committed.disconnect(save_callback)
	tutorial.notify_merge_completed()

	for kill_index in range(4):
		var monster := await _wait_for_tutorial_monster(game.combat_system.monster_system, "basic", 1.2)
		_check(monster != null, "basic tutorial monster %d should spawn" % (kill_index + 1))
		if monster:
			monster.kill("test")
		await _wait_seconds(0.08)

	var heavy := await _wait_for_tutorial_monster(game.combat_system.monster_system, "breakthrough", 1.6)
	_check(heavy != null, "armored breakthrough monster should spawn after four kills")
	if heavy:
		var crystal_view: CrystalView = game.combat_system.battle_layer.get_crystal_view()
		_check(
			not heavy.z_as_relative and heavy.z_index > crystal_view.z_index,
			"breakthrough monster should move in front of the dormant crystal"
		)
		heavy.apply_damage(999.0, "test")
		_check(is_equal_approx(heavy.hp, 8.0), "armored monster should retain eight hp before reaching the goal")
		heavy.path_progress = 0.994
		await _wait_seconds(0.15)
		_check(heavy.reached and heavy.is_alive(), "armored monster should remain alive beside the crystal")
		_check(game.combat_system.castle_system.get_durability() == 18, "breakthrough should reduce durability exactly from twenty to eighteen")
		_check(game.combat_system._tutorial_paused, "breakthrough should pause tutorial combat")

	await _wait_seconds(2.2)
	_check(tutorial.state == FirstWaveTutorialController.State.CORE_REWARD, "awakening core should appear after the two warnings")
	tutorial._on_awakening_core_pressed()
	await _wait_seconds(0.65)
	_check(game.combat_system.crystal_system.is_awakened(), "one core click should awaken the level-one crystal")
	if heavy and is_instance_valid(heavy):
		_check(
			game.combat_system.battle_layer.get_crystal_view().z_index > heavy.z_index,
			"activated crystal should dynamically rise in front of the breakthrough monster"
		)
	await _wait_seconds(0.80)
	_check(heavy == null or not is_instance_valid(heavy) or not heavy.is_alive(), "tutorial crystal strike should kill the breakthrough monster")
	await _wait_seconds(2.35)
	_check(not game.combat_system.is_first_wave_tutorial_active(), "tutorial mode should end after the first strike message")
	_check(game.combat_system.wave_system.current_wave_index == 1, "completed tutorial should advance directly to normal wave two")
	_check(game._cluster_swap_item_count != 0 and game.energy_hud._crystal_rain_enabled, "instant items should unlock after awakening")
	_check(
		game.combat_system.battle_layer.get_crystal_view().z_index == BattleLayerView.CRYSTAL_NORMAL_Z,
		"crystal should restore its normal layer after tutorial completion"
	)

	game.queue_free()
	await process_frame
	await process_frame
	await _test_opening_skip()
	if failures.is_empty():
		print("FIRST_WAVE_TUTORIAL_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_opening_skip() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.muted = true
	game._first_wave_tutorial_completed = false
	game._crystal_awakened_unlocked = false
	game.start_game()
	await _wait_seconds(1.5)
	var tutorial: FirstWaveTutorialController = game._first_wave_tutorial
	_check(tutorial != null, "opening skip fixture should start tutorial")
	if tutorial:
		var save_callback := Callable(game, "_on_tutorial_awakening_committed")
		if tutorial.awakening_committed.is_connected(save_callback):
			tutorial.awakening_committed.disconnect(save_callback)
		tutorial._on_skip_pressed()
		await _wait_seconds(0.25)
		_check(game.combat_system.crystal_system.is_awakened(), "skip should immediately activate the crystal")
		_check(not game.combat_system.is_first_wave_tutorial_active(), "skip should clear tutorial combat state")
		_check(game.combat_system.wave_system.current_wave_index == 1, "skip should complete tutorial wave one and enter wave two")
		_check(
			game.combat_system.battle_layer.get_crystal_view().z_index == BattleLayerView.CRYSTAL_NORMAL_Z,
			"skipping tutorial should restore the normal crystal layer"
		)
		for monster in game.combat_system.monster_system.monsters:
			_check(not is_instance_valid(monster) or monster.tutorial_role.is_empty(), "skip should remove all tutorial monsters")
	game.queue_free()
	await process_frame
	await process_frame


func _wait_for_tutorial_monster(system: MonsterSystem, role: String, timeout: float) -> Monster:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while Time.get_ticks_msec() < deadline:
		for monster in system.monsters:
			if is_instance_valid(monster) and monster.tutorial_role == role and monster.is_alive():
				return monster
		await process_frame
	return null


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
