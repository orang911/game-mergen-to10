extends SceneTree

var _failed := false
var _retargeted := false


func _init() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	var combat := game.combat_system as CombatSystem
	combat.reset()
	combat.running = true
	combat.monster_system.start()
	combat.wave_system.stop()
	if combat.crystal_system:
		combat.crystal_system.stop()

	var first := combat.monster_system.spawn_monster("small", 1.0, {"hp": 100.0, "speed": 0.0})
	first.path_progress = 0.80
	first.position = combat.path_system.position_at_progress(0.80) - first.get_path_anchor_offset()
	var second := combat.monster_system.spawn_monster("small", 1.0, {"hp": 100.0, "speed": 0.0})
	second.path_progress = 0.60
	second.position = combat.path_system.position_at_progress(0.60) - second.get_path_anchor_offset()
	var first_id := first.get_instance_id()
	var second_id := second.get_instance_id()

	combat.merge_shot_fired.connect(func(_sequence: int, shot: int, target: Monster):
		if shot == 0 and is_instance_valid(target) and target.get_instance_id() == first_id:
			target.queue_free()
	)
	combat.merge_shot_resolved.connect(func(_sequence: int, shot: int, target: Monster, _damage: float, _killed: bool):
		if shot == 0 and is_instance_valid(target) and target.get_instance_id() == second_id:
			_retargeted = true
	)
	var event := MergeAttackEvent.from_merge(4, 3, 2, Vector2(320.0, 900.0), 2)
	event.effect_params["crit_chance"] = 0.0
	event.effect_params["annihilation_chance"] = 0.0
	combat.handle_merge_attack(event)
	await _wait_seconds(0.60)
	_check(_retargeted, "a freed target during flight should retarget without a typed-call error")

	game.queue_free()
	await process_frame
	print("MERGE_FREED_TARGET_SMOKE_OK" if not _failed else "MERGE_FREED_TARGET_SMOKE_FAILED")
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
