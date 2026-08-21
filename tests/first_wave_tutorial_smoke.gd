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
	game._chapter_completed = false
	game._chapter_resume_state.clear()
	game._chapter_completion_snapshot.clear()
	game._continuation_completed = false
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
	_check(first_attack.attack_count == 3 and first_attack.target_count == 1, "the first three-one poison merge should fire once per card at the front target")
	_check(is_equal_approx(first_attack.total_damage, 8.0), "the first three-one merge should preserve eight total damage")
	_check(is_equal_approx(first_attack.damage, 8.0 / 3.0), "tutorial poison should divide its preserved damage across sequential hits")

	# Avoid touching the developer's real save file while still exercising the
	# full visual/combat state machine.
	var save_callback := Callable(game, "_on_tutorial_awakening_committed")
	if tutorial.awakening_committed.is_connected(save_callback):
		tutorial.awakening_committed.disconnect(save_callback)
	var forbidden_tutorial_block := game._block_at(Vector2i(0, 0)) as MergeBlock
	game._on_block_pressed(forbidden_tutorial_block)
	_check(game.game_status == game.GameStatus.START and game.selected_blocks.is_empty(), "a non-highlighted tutorial tap must remain blocked without selection")
	var tutorial_merge_target := game._block_at(Vector2i(2, 1)) as MergeBlock
	game._on_block_pressed(tutorial_merge_target)
	_check(game.game_status == game.GameStatus.PAUSE, "one highlighted tap should immediately start the tutorial merge")
	await _wait_seconds(0.62)
	_check(tutorial.state == FirstWaveTutorialController.State.BASIC_MONSTERS, "one highlighted tap should complete the first-merge tutorial step")
	_check(tutorial_merge_target != null and is_instance_valid(tutorial_merge_target) and tutorial_merge_target.level == 2, "tutorial merge result should remain at the tapped highlighted cell")

	for kill_index in range(4):
		var monster := await _wait_for_tutorial_monster(game.combat_system.monster_system, "basic", 1.2)
		_check(monster != null, "basic tutorial monster %d should spawn" % (kill_index + 1))
		if monster:
			monster.kill("test")
		await _wait_seconds(0.08)

	var heavy := await _wait_for_tutorial_monster(game.combat_system.monster_system, "breakthrough", 1.6)
	_check(
		heavy != null and is_equal_approx(heavy.speed, CombatSystem.TUTORIAL_BREAKTHROUGH_BASE_SPEED * CombatSystem.TUTORIAL_BREAKTHROUGH_SPEED_MULTIPLIER),
		"crystal-activation tutorial Boss must move at exactly twice its original speed"
	)
	_check(heavy != null, "armored breakthrough monster should spawn after four kills")
	if heavy:
		var tutorial_hold_signal_count := [0]
		heavy.tutorial_hold_reached.connect(func(_monster: Monster):
			tutorial_hold_signal_count[0] += 1
		)
		var crystal_view: CrystalView = game.combat_system.battle_layer.get_crystal_view()
		_check(
			not heavy.z_as_relative and heavy.z_index > crystal_view.z_index,
			"breakthrough monster should move in front of the dormant crystal"
		)
		heavy.apply_damage(999.0, "test")
		_check(is_equal_approx(heavy.hp, 8.0), "armored monster should retain eight hp before reaching the goal")
		heavy.path_progress = 0.919
		await _wait_seconds(0.16)
		_check(is_equal_approx(heavy.path_progress, 0.92), "armored monster should stop at the authored activation marker")
		_check(
			heavy != null and is_instance_valid(heavy) and heavy.is_alive() and not heavy.reached and game.combat_system.monster_system.monsters.has(heavy),
			"armored monster should remain before the crystal until the tutorial first strike"
		)
		_check(tutorial_hold_signal_count[0] == 1, "armored monster should emit the tutorial hold signal exactly once")
		_check(game.combat_system.castle_system.get_durability() == 20, "activation marker must not damage crystal durability")
		_check(game.combat_system.run_leaks == 0, "activation marker must not count as a leaked monster")
		_check(
			crystal_view._damage_tween == null or not crystal_view._damage_tween.is_valid(),
			"tutorial warning flash must not play crystal damage feedback"
		)
		_check(game.combat_system._tutorial_paused, "breakthrough should pause tutorial combat")
		_check(
			game.combat_system.battle_layer._damage_flash_tween != null and game.combat_system.battle_layer._damage_flash_tween.is_valid(),
			"activation marker should play the full-screen red warning flash"
		)

	await _wait_seconds(0.24)
	_check(tutorial.state == FirstWaveTutorialController.State.CORE_REWARD, "awakening core should appear immediately after the red warning flash")
	var tutorial_view: FirstWaveTutorialView = tutorial._view
	_check(tutorial_view != null and tutorial_view._core_button.visible, "awakening crystal icon should be visible during the core reward")
	if tutorial_view:
		_check(not tutorial_view._progress_panel.visible, "the completed 4/4 counter should hide before awakening")
		_check(not tutorial_view._red_warning.visible, "the obsolete durability warning should stay hidden")
		var icon_center := tutorial_view._core_button.get_global_rect().get_center()
		_check(tutorial_view._core_info.get_global_rect().has_point(icon_center), "awakening crystal icon should be inside the explanation card")
		_check(not tutorial_view._card_crystal_icon.visible, "reward card should use the clickable crystal instead of a duplicate static icon")
		_check(tutorial_view._core_button.texture_normal == load("res://assets/runtime/ui/interfaces/battle/tutorial/icons/icon_crystal_awakening_level_01.png"), "reward card should use the crystal-only level-one icon")
		_check(tutorial_view._awakening_screen_button.visible, "core reward must enable the full-screen awakening tap target")
		_check(tutorial_view._awakening_screen_button.get_rect().has_point(Vector2(40.0, 1500.0)), "awakening must accept a tap far away from the crystal card")
		_check((tutorial_view.get_node("SkipTutorial") as Button).z_index > tutorial_view._awakening_screen_button.z_index, "skip tutorial must remain independently clickable above the screen tap target")
		tutorial_view._on_awakening_screen_pressed()
		tutorial_view._on_awakening_screen_pressed()
	_check(tutorial.state == FirstWaveTutorialController.State.AWAKENING, "one arbitrary screen tap should start awakening exactly once")
	await _wait_seconds(0.65)
	_check(game.combat_system.crystal_system.is_awakened(), "one core click should awaken the level-one crystal")
	if tutorial_view and is_instance_valid(tutorial_view):
		_check(tutorial_view._card_crystal_icon.visible, "awakened card should display the static level-one crystal icon")
		_check(not tutorial_view._core_button.visible, "awakened card should not retain a clickable crystal icon")
	if heavy and is_instance_valid(heavy):
		_check(
			game.combat_system.battle_layer.get_crystal_view().z_index > heavy.z_index,
			"activated crystal should dynamically rise in front of the breakthrough monster"
		)
	# The awakened crystal now uses the shared 0.35s charge + 0.18s beam
	# sequence, after the card-dismiss animation, before the guaranteed kill.
	await _wait_seconds(1.45)
	_check(heavy == null or not is_instance_valid(heavy) or not heavy.is_alive(), "tutorial crystal strike should kill the breakthrough monster")
	await _wait_seconds(2.50)
	_check(not game.combat_system.is_first_wave_tutorial_active(), "tutorial mode should end after the first strike message")
	_check(game._first_wave_tutorial_completed and game._crystal_awakened_unlocked, "tutorial completion should be persisted")
	_check(game.game_layer.visible and not game.main_layer.visible, "completed tutorial should stay in the current battle")
	_check(game.combat_system.wave_system.current_wave_index == 1, "completed tutorial must advance to the authored 1-1 follow-up wave")

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
	game._chapter_completed = false
	game._chapter_resume_state.clear()
	game._chapter_completion_snapshot.clear()
	game._continuation_completed = false
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
		_check(game.game_layer.visible and not game.loading_view.visible, "skip should also continue in the current chapter battle")
		_check(game.combat_system.wave_system.current_wave_index == 1, "skip should advance to the authored 1-1 follow-up wave")
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
