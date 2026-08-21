extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(ResourceLoader.exists("res://assets/runtime/fx/crystal_tower/charge_overlay.png"), "crystal charge overlay runtime asset should be imported")
	_check(ResourceLoader.exists("res://assets/runtime/fx/crystal_tower/attack_beam.png"), "crystal beam runtime asset should be imported")
	await _test_single_target_lock()
	await _test_charge_feedback_peak()
	await _test_beam_visual_asset()
	await _test_flight_hit_timing()
	await _test_target_death_switch()
	await _test_target_invalidation()
	await _test_pause_reset()
	await _test_card_additional_effects()
	await _test_tutorial_first_strike()
	if failures.is_empty():
		print("CRYSTAL_CHARGED_SHOT_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_single_target_lock() -> void:
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var front: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var behind: Monster = _spawn_monster(combat, 1000.0, 0.50)
	crystal._try_attack()
	await process_frame
	_check(crystal._locked_target_id == front.get_instance_id(), "charged shot should lock the frontmost alive monster")
	await _wait_seconds(0.70)
	_check(front.hp < front.max_hp, "the locked front monster should take the main hit")
	_check(is_equal_approx(behind.hp, behind.max_hp), "a single main target must not damage the monster behind it")
	_check(crystal._locked_target_id == front.get_instance_id(), "the lock should persist while the target survives")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_charge_feedback_peak() -> void:
	_check(is_equal_approx(CrystalSystem.CHARGE_FEEDBACK_DURATION, 0.35), "charge feedback should peak over 0.35 seconds")
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var view: CrystalView = combat.battle_layer.get_crystal_view()
	_check(view._showcase_charge_feedback_normalized.position.x >= 0.0, "crystal charge layout should load from the upgrade showcase scene")
	_check(view._showcase_beam_origin_normalized.x >= 0.0, "crystal beam origin should load from the upgrade showcase scene")
	_spawn_monster(combat, 1000.0, 0.80)
	crystal._try_attack()
	await process_frame
	await process_frame
	_check(view._charge_feedback != null and is_instance_valid(view._charge_feedback), "charge should create a feedback overlay on the crystal")
	var peak := await _poll_feedback_alpha(view, 0.60)
	_check(peak >= CrystalView.CHARGE_FEEDBACK_MAX_ALPHA - 0.06, "charge feedback should reach its max opacity around the 0.35s peak")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_beam_visual_asset() -> void:
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	_spawn_monster(combat, 1000.0, 0.80)
	crystal._try_attack()
	await _wait_seconds(0.38)
	var beam := combat.battle_layer.get_projectile_layer().get_node_or_null("CrystalBeam") as MergeBolt
	_check(beam != null, "charged shot should create a dedicated crystal beam node")
	if beam:
		_check(beam._crystal_beam_visual, "charged shot should use the thin lock-line visual")
		var beam_texture := beam._trail_rect.texture as Texture2D
		_check(beam_texture != null and beam_texture.resource_path.ends_with("attack_beam.png"), "charged shot should use the supplied beam texture")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_flight_hit_timing() -> void:
	_check(is_equal_approx(CrystalSystem.CRYSTAL_BOLT_FLIGHT_DURATION, 0.18), "charged shot flight should last 0.18 seconds")
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var monster: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var hp_before := monster.hp
	crystal._try_attack()
	await _wait_seconds(0.40)
	_check(is_equal_approx(monster.hp, hp_before), "charged shot must not resolve before charge and flight finish")
	await _wait_seconds(0.30)
	_check(monster.hp < hp_before, "charged shot should resolve its hit after the 0.18s flight")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_target_death_switch() -> void:
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var first: Monster = _spawn_monster(combat, 1.0, 0.80)
	var second: Monster = _spawn_monster(combat, 1000.0, 0.50)
	crystal._try_attack()
	await _wait_seconds(0.70)
	_check(not first.is_alive(), "the front monster should die to the charged shot")
	_check(crystal._locked_target_id == 0, "the lock should release when the target dies")
	crystal._try_attack()
	await _wait_seconds(0.70)
	_check(crystal._locked_target_id == second.get_instance_id(), "after the first target dies the crystal should lock the next front monster")
	_check(second.hp < second.max_hp, "the next front monster should take the following charged shot")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_target_invalidation() -> void:
	# Death during the charge.
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var monster: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var hits := [0]
	crystal.normal_hit.connect(func(_pos: Vector2): hits[0] += 1)
	crystal._try_attack()
	await _wait_seconds(0.10)
	monster.kill("test")
	await _wait_seconds(0.65)
	_check(crystal._locked_target_id == 0, "a target dying during the charge should release the lock")
	_check(hits[0] == 0, "a target dying during the charge must not produce a hit")
	_cleanup(fixture)
	await process_frame
	await process_frame

	# Reaching the goal during flight.
	fixture = await _make_crystal_fixture()
	combat = fixture["combat"]
	crystal = fixture["crystal"]
	var runner: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var flight_hits := [0]
	crystal.normal_hit.connect(func(_pos: Vector2): flight_hits[0] += 1)
	crystal._try_attack()
	await _wait_seconds(0.40)
	runner.reached = true
	await _wait_seconds(0.35)
	_check(crystal._locked_target_id == 0, "a target reaching the goal during flight should release the lock")
	_check(flight_hits[0] == 0, "a target reaching the goal during flight must not produce a hit")
	_check(not is_instance_valid(runner) or is_equal_approx(runner.hp, runner.max_hp), "an invalidated target must not take invalid damage")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_pause_reset() -> void:
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var view: CrystalView = combat.battle_layer.get_crystal_view()
	var monster: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var hits := [0]
	crystal.normal_hit.connect(func(_pos: Vector2): hits[0] += 1)
	crystal._try_attack()
	await _wait_seconds(0.10)
	crystal.stop()
	_check(view._charge_feedback == null or not view._charge_feedback.visible, "pause should cancel the charge feedback overlay")
	await _wait_seconds(0.65)
	_check(is_equal_approx(monster.hp, monster.max_hp), "pause should cancel the in-flight shot without damage")
	_check(crystal._locked_target_id == 0, "pause should release the lock")
	_check(hits[0] == 0, "pause should prevent the cancelled shot from emitting a hit")
	_cleanup(fixture)
	await process_frame
	await process_frame

	fixture = await _make_crystal_fixture()
	combat = fixture["combat"]
	crystal = fixture["crystal"]
	var reset_target: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var reset_hits := [0]
	crystal.normal_hit.connect(func(_pos: Vector2): reset_hits[0] += 1)
	crystal._try_attack()
	await _wait_seconds(0.10)
	crystal.reset()
	await _wait_seconds(0.65)
	_check(is_equal_approx(reset_target.hp, reset_target.max_hp), "battle reset should cancel the in-flight shot without damage")
	_check(crystal._locked_target_id == 0, "battle reset should clear the lock")
	_check(reset_hits[0] == 0, "battle reset should prevent the cancelled shot from emitting a hit")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_card_additional_effects() -> void:
	# Element (fire) and pierce after-hit effects continue on the single main target.
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	crystal.apply_upgrade("fire_conduit", "", 1)
	crystal.apply_upgrade("piercing_cannon", "", 1)
	var front: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var behind: Monster = _spawn_monster(combat, 1000.0, 0.50)
	crystal._try_attack()
	await _wait_seconds(0.85)
	_check(front.hp < front.max_hp, "the main target should take the charged shot")
	_check(not front.burn_status.is_empty(), "the installed fire card should still burn the main target")
	_check(behind.hp < behind.max_hp, "the installed pierce card should still hit a monster behind the main target")
	_cleanup(fixture)
	await process_frame
	await process_frame

	# twin_lens must not restore additional primary targets.
	fixture = await _make_crystal_fixture()
	combat = fixture["combat"]
	crystal = fixture["crystal"]
	crystal.apply_upgrade("twin_lens", "", 1)
	var primary: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var secondary: Monster = _spawn_monster(combat, 1000.0, 0.50)
	crystal._try_attack()
	await _wait_seconds(0.70)
	_check(primary.hp < primary.max_hp, "single-target mode should still damage the front monster")
	_check(is_equal_approx(secondary.hp, secondary.max_hp), "twin_lens must not create a second main target in single-target mode")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _test_tutorial_first_strike() -> void:
	var fixture := await _make_crystal_fixture()
	var combat: CombatSystem = fixture["combat"]
	var crystal: CrystalSystem = fixture["crystal"]
	var monster: Monster = _spawn_monster(combat, 1000.0, 0.80)
	var finished := [false]
	crystal.tutorial_first_strike_finished.connect(func(): finished[0] = true)
	crystal.play_tutorial_first_strike(monster)
	await _wait_seconds(0.75)
	_check(not is_instance_valid(monster) or not monster.is_alive(), "tutorial first strike should keep its guaranteed kill")
	_check(finished[0], "tutorial first strike should still emit its finished callback")
	_cleanup(fixture)
	await process_frame
	await process_frame


func _make_crystal_fixture() -> Dictionary:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.muted = true
	var combat := game.combat_system as CombatSystem
	combat.reset()
	combat.running = true
	combat.monster_system.start()
	combat.wave_system.stop()
	var crystal := combat.crystal_system as CrystalSystem
	crystal._running = true
	crystal._awakened = true
	crystal._attack_timer = 999.0
	crystal._speed_multiplier = 1.0
	return {"game": game, "combat": combat, "crystal": crystal}


func _spawn_monster(combat: CombatSystem, hp: float, progress: float) -> Monster:
	var monster := combat.monster_system.spawn_monster("small", 1.0, {"hp": hp, "speed": 0.0})
	monster.path_progress = progress
	monster.position = combat.path_system.position_at_progress(progress) - monster.get_path_anchor_offset()
	return monster


func _poll_feedback_alpha(view: CrystalView, duration: float) -> float:
	var peak := 0.0
	var deadline := Time.get_ticks_msec() + int(duration * 1000.0)
	while Time.get_ticks_msec() < deadline:
		if view._charge_feedback != null and is_instance_valid(view._charge_feedback):
			peak = maxf(peak, view._charge_feedback.modulate.a)
		await process_frame
	return peak


func _cleanup(fixture: Dictionary) -> void:
	var game = fixture.get("game", null)
	if game != null and is_instance_valid(game):
		game.queue_free()


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
