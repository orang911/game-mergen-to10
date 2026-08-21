extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_element_parameters()
	await _test_runtime_statuses()
	await _test_poison_and_fire_stacking()
	await _test_annihilation_immunity()
	if failures.is_empty():
		print("ELEMENT_FEEDBACK_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _test_element_parameters() -> void:
	var poison := GameConfig.get_element_effect_params(1)
	_check(is_equal_approx(float(poison["dps_ratio"]), 0.30), "tier-one poison should deal 30 percent per tick")
	var poison_tier_two := GameConfig.get_element_effect_params(6)
	_check(is_equal_approx(float(poison_tier_two["dps_ratio"]), 0.35), "poison should gain five percent per element tier")
	var ice := GameConfig.get_element_effect_params(2)
	_check(is_equal_approx(float(ice["slow_percent"]), 0.60) and is_equal_approx(float(ice["duration"]), 2.0), "ice should be fixed at forty-percent movement for two seconds")
	var critical := GameConfig.get_element_effect_params(4)
	_check(is_equal_approx(float(critical["annihilation_chance"]), 0.05), "critical should start at five percent annihilation")
	var critical_tier_three := GameConfig.get_element_effect_params(14)
	_check(is_equal_approx(float(critical_tier_three["annihilation_chance"]), 0.09), "critical annihilation should gain two percent per tier")
	var protected_monster := Monster.new()
	protected_monster.setup({"type": "tutorial_armored", "hp": 24.0, "tutorial_role": "breakthrough", "tutorial_min_hp_before_goal": 8.0})
	_check(protected_monster.is_annihilation_immune(), "tutorial-protected monsters must be annihilation immune")
	protected_monster.queue_free()


func _test_runtime_statuses() -> void:
	var monster := Monster.new()
	monster.setup({"type": "small", "hp": 100.0, "speed": 100.0, "visual_tier": 1})
	root.add_child(monster)
	await process_frame
	_check(monster._view._sprite.material == null, "normal monsters must use native texture rendering before a lightning hit")

	var poison_event := MergeAttackEvent.from_merge(1, 4, 2, Vector2.ZERO, 0)
	poison_event.damage = 100.0
	monster.apply_element_effect(poison_event)
	monster.update_status(0.99)
	_check(is_equal_approx(monster.hp, 100.0), "poison must not deal fractional per-frame damage")
	monster.update_status(0.02)
	_check(is_equal_approx(monster.hp, 70.0), "poison should deal one full redamage tick after one second")
	var weak_poison := MergeAttackEvent.from_merge(1, 4, 2, Vector2.ZERO, 0)
	weak_poison.damage = 50.0
	monster.apply_element_effect(weak_poison)
	_check(monster.get_poison_layer_count() == 2, "each poison hit should add one independent layer")
	_check(is_equal_approx(float(monster.poison_status["damage_per_tick"]), 45.0), "poison summary damage should combine all active layers")

	var freeze_event := MergeAttackEvent.from_merge(2, 4, 2, Vector2.ZERO, 0)
	monster.apply_element_effect(freeze_event)
	_check(is_equal_approx(monster.get_speed_multiplier(), 0.40), "ice should leave exactly forty percent movement speed")
	_check(monster._view.modulate.b > monster._view.modulate.r, "ice should tint the complete monster visual blue")

	var lightning_event := MergeAttackEvent.from_merge(3, 4, 2, Vector2.ZERO, 0)
	monster.apply_element_effect(lightning_event)
	var lightning_material := monster._view._lightning_flash_material as ShaderMaterial
	_check(lightning_material != null, "lightning should install the shared black-white flash material")
	_check(float(lightning_material.get_shader_parameter("lightning_amount")) > 0.9, "lightning hit should immediately enable black-white flashing")
	await _wait_seconds(0.08)
	_check(monster._view.position.length() > 2.0 and absf(monster._view.rotation) > 0.001, "lightning hit should visibly shake and rotate the complete monster")
	var first_flash_phase := bool(float(lightning_material.get_shader_parameter("lightning_white")) > 0.5)
	await _wait_seconds(0.07)
	var second_flash_phase := bool(float(lightning_material.get_shader_parameter("lightning_white")) > 0.5)
	_check(first_flash_phase != second_flash_phase, "lightning feedback should alternate between black and white phases")
	var before_progress := monster.path_progress
	monster.update_status(0.25)
	monster.update_movement(0.25, 100.0)
	_check(is_equal_approx(monster.path_progress, before_progress), "lightning hard-stun must stop movement")
	monster.update_status(0.80)
	monster.update_movement(0.10, 100.0)
	_check(is_equal_approx(monster.path_progress, before_progress), "the hard-stun frame should not leak movement at expiry")
	monster.update_status(0.02)
	monster.update_movement(0.10, 100.0)
	_check(monster.path_progress > before_progress, "movement should resume after the refreshed one-second hard-stun ends")
	_check(float(lightning_material.get_shader_parameter("lightning_amount")) <= 0.001, "lightning black-white flashing should stop with the hard-stun")
	_check(monster._view._sprite.material == null, "inactive monsters must fully detach the lightning shader")

	var direct_hit_progress := monster.path_progress
	monster.apply_damage(1.0)
	monster.update_status(0.05)
	monster.update_movement(0.05, 100.0)
	_check(is_equal_approx(monster.path_progress, direct_hit_progress), "a direct hit must stop path movement immediately")
	monster.update_status(0.06)
	monster.update_movement(0.06, 100.0)
	_check(is_equal_approx(monster.path_progress, direct_hit_progress), "the hit-stop expiry frame must not leak movement")
	monster.update_status(0.01)
	monster.update_movement(0.01, 100.0)
	_check(monster.path_progress > direct_hit_progress, "movement should resume after the short direct-hit pause")

	var effect_system := EffectSystem.new()
	root.add_child(effect_system)
	var recoil_path_progress := monster.path_progress
	var recoil_origin := monster._view.global_position + Vector2(-120.0, monster._view._base_size * 0.5)
	effect_system.play_monster_hit(monster, "fire", recoil_origin)
	monster._view._process(0.03)
	_check(monster._view.position.x > 4.0, "fire hits should push the monster visual away from the attack origin")
	_check(is_equal_approx(monster.path_progress, recoil_path_progress), "element recoil must not change real path progress")
	monster._view._process(0.25)
	_check(monster._view.position.length() < 0.1, "element recoil should return cleanly to the path center")
	var critical_origin := monster._view.global_position + Vector2(120.0, monster._view._base_size * 0.5)
	effect_system.play_monster_hit(monster, "critical", critical_origin)
	monster._view._process(0.03)
	_check(monster._view.position.x < -4.0, "critical hits should use the same directional recoil feedback")
	monster._view._process(0.25)
	effect_system.queue_free()
	monster.queue_free()
	await process_frame


func _test_poison_and_fire_stacking() -> void:
	var monster := Monster.new()
	monster.setup({"type": "small", "hp": 2000.0, "speed": 0.0, "visual_tier": 1})
	root.add_child(monster)
	await process_frame

	var poison_damages := [100.0, 80.0, 60.0, 40.0]
	for damage in poison_damages:
		var poison_event := MergeAttackEvent.from_merge(1, 4, 2, Vector2.ZERO, 0)
		poison_event.damage = damage
		monster.apply_element_effect(poison_event, "board")
	_check(monster.get_poison_layer_count() == 4, "poison should stack to four layers")
	var poison_layers := monster.poison_status["layers"] as Array
	(poison_layers[0] as Dictionary)["remaining"] = 2.8
	(poison_layers[1] as Dictionary)["remaining"] = 1.2
	(poison_layers[2] as Dictionary)["remaining"] = 2.0
	(poison_layers[3] as Dictionary)["remaining"] = 2.4
	var replacement_poison := MergeAttackEvent.from_merge(1, 4, 2, Vector2.ZERO, 0)
	replacement_poison.damage = 200.0
	monster.apply_element_effect(replacement_poison, "skill")
	poison_layers = monster.poison_status["layers"] as Array
	_check(monster.get_poison_layer_count() == 4, "a fifth poison hit must keep the four-layer cap")
	_check(is_equal_approx(float((poison_layers[1] as Dictionary)["atk"]), 200.0), "a fifth poison hit should replace the earliest-expiring layer")

	var poison_tick_values: Array[float] = []
	var poison_feedback_values: Array[float] = []
	var fire_feedback_values: Array[float] = []
	monster.status_ticked.connect(func(_target: Monster, element: int, damage: float):
		if element == GameConfig.AttackElement.POISON:
			poison_tick_values.append(damage)
	)
	monster.damage_feedback_requested.connect(func(_target: Monster, damage: float, element: int):
		if element == GameConfig.AttackElement.POISON:
			poison_feedback_values.append(damage)
		elif element == GameConfig.AttackElement.FIRE:
			fire_feedback_values.append(damage)
	)
	var hp_before_poison_tick := monster.hp
	monster.update_status(1.01)
	_check(poison_tick_values.size() == 1, "four poison layers must emit one combined tick and one floating-number event per second")
	_check(poison_feedback_values.size() == 1, "combined poison damage should request one unified red flash and floating number")
	_check(is_equal_approx(poison_tick_values[0], 120.0), "combined poison tick should equal the sum of all four active layers")
	_check(is_equal_approx(monster.hp, hp_before_poison_tick - 120.0), "combined poison tick should damage once for the summed value")

	for damage in [100.0, 80.0, 60.0, 40.0]:
		var fire_event := MergeAttackEvent.from_merge(5, 6, 2, Vector2.ZERO, 0)
		fire_event.damage = damage
		monster.apply_element_effect(fire_event, "board")
	_check(monster.get_poison_layer_count() == 4 and monster.get_burn_layer_count() == 4, "poison and fire should coexist at four layers each")
	_check(monster._view._poison_stack_count == 4 and monster._view._burn_stack_count == 4, "monster status UI should receive both stack counts")
	var burn_layers := monster.burn_status["layers"] as Array
	(burn_layers[0] as Dictionary)["remaining"] = 2.0
	(burn_layers[1] as Dictionary)["remaining"] = 0.8
	(burn_layers[2] as Dictionary)["remaining"] = 1.5
	(burn_layers[3] as Dictionary)["remaining"] = 1.8
	var replacement_fire := MergeAttackEvent.from_merge(5, 6, 2, Vector2.ZERO, 0)
	replacement_fire.damage = 200.0
	monster.apply_element_effect(replacement_fire, "skill")
	burn_layers = monster.burn_status["layers"] as Array
	_check(monster.get_burn_layer_count() == 4, "a fifth fire hit must keep the four-layer cap")
	_check(is_equal_approx(float((burn_layers[1] as Dictionary)["atk"]), 200.0), "a fifth fire hit should replace the earliest-expiring layer")
	var burn_dps := float(monster.burn_status["damage_per_second"])
	var hp_before_burn := monster.hp
	monster.update_status(0.25)
	_check(is_equal_approx(monster.hp, hp_before_burn - burn_dps * 0.25), "fire layers should retain continuous burn using their summed DPS")
	_check(fire_feedback_values.is_empty(), "continuous fire should not spam floating text every frame")
	monster.update_status(0.75)
	_check(fire_feedback_values.size() == 1, "continuous fire should aggregate into one unified feedback event per second")
	_check(is_equal_approx(fire_feedback_values[0], burn_dps), "fire floating damage should equal the accumulated one-second burn")

	var saved_poison_count := monster.get_poison_layer_count()
	var saved_burn_count := monster.get_burn_layer_count()
	var saved_state := monster.export_state()
	var restored := Monster.new()
	restored.setup({"type": "small", "hp": 2000.0, "speed": 0.0, "visual_tier": 1})
	root.add_child(restored)
	restored.restore_state(saved_state)
	_check(
		restored.get_poison_layer_count() == saved_poison_count
		and restored.get_burn_layer_count() == saved_burn_count,
		"save restore should preserve every currently active poison and fire layer"
	)
	restored.queue_free()

	var legacy := Monster.new()
	legacy.setup({"type": "small", "hp": 500.0, "speed": 0.0, "visual_tier": 1})
	root.add_child(legacy)
	legacy.restore_state({
		"hp": 500.0,
		"poison_status": {
			"tier": 1, "atk": 100.0, "duration": 3.0, "remaining": 2.0,
			"dps_ratio": 0.30, "damage_per_tick": 30.0, "tick_elapsed": 0.4,
			"source": "normal",
		},
		"burn_status": {
			"tier": 1, "atk": 100.0, "duration": 2.0, "remaining": 1.5,
			"dps_ratio": 0.15, "source": "normal",
		},
	})
	_check(legacy.get_poison_layer_count() == 1 and legacy.get_burn_layer_count() == 1, "legacy single-layer saves should migrate to one poison and one fire layer")
	legacy.queue_free()
	monster.queue_free()
	await process_frame


func _test_annihilation_immunity() -> void:
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
		combat.crystal_system.apply_upgrade("frost_prism", "ice", 3)
		combat.crystal_system.apply_upgrade("thunder_spire", "lightning", 2)
		_check(combat.crystal_system._installed_elements.has("ice"), "crystal frost card should remain executable outside random pools")
		_check(combat.crystal_system._installed_elements.has("lightning"), "crystal thunder card should remain executable outside random pools")
		var crystal_ice := combat.crystal_system._make_crystal_element_event("ice", 1, 50.0, 3)
		var crystal_lightning := combat.crystal_system._make_crystal_element_event("lightning", 1, 50.0, 2)
		var crystal_probe := Monster.new()
		crystal_probe.setup({"type": "small", "hp": 100.0, "speed": 100.0})
		crystal_probe.apply_element_effect(crystal_ice, "crystal")
		_check(is_equal_approx(crystal_probe.get_speed_multiplier(), 0.40), "crystal ice should use the shared forty-percent movement rule")
		crystal_probe.apply_element_effect(crystal_lightning, "crystal")
		_check(is_equal_approx(crystal_probe.lightning_stun_remaining, 1.0), "crystal lightning should apply the shared hard-stun")
		crystal_probe.queue_free()

	var normal := combat.monster_system.spawn_monster("small", 1.0, {"hp": 100.0, "speed": 0.0})
	var boss := combat.monster_system.spawn_monster("large", 1.0, {"hp": 100.0, "speed": 0.0, "is_boss": true})
	normal.path_progress = 0.8
	boss.path_progress = 0.7
	var normal_event := MergeAttackEvent.from_merge(4, 4, 2, Vector2.ZERO, 0)
	normal_event.effect_params["annihilation_chance"] = 1.0
	normal_event.effect_params["crit_chance"] = 1.0
	combat.handle_merge_attack(normal_event)
	await _wait_seconds(0.52)
	_check(not is_instance_valid(normal) or not normal.is_alive(), "forced annihilation should instantly remove a normal monster")
	var boss_event := MergeAttackEvent.from_merge(4, 4, 2, Vector2.ZERO, 0)
	boss_event.effect_params["annihilation_chance"] = 1.0
	boss_event.effect_params["crit_chance"] = 1.0
	combat.handle_merge_attack(boss_event)
	await _wait_seconds(0.52)
	_check(boss.is_alive(), "bosses must be immune even at forced annihilation probability")
	_check(boss.hp < boss.max_hp, "an annihilation-immune boss should still receive the normal critical hit")
	game.queue_free()
	await process_frame


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + roundi(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
