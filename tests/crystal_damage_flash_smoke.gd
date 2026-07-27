extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var combat := game.combat_system as CombatSystem
	var battle := combat.battle_layer as BattleLayerView
	var crystal := battle.get_crystal_view()
	var flash := battle.get_node_or_null("CrystalDamageScreenFlash") as ColorRect
	_check(flash != null, "battle view should create the full-screen damage flash")
	if flash:
		_check(flash.z_index == 110 and not flash.z_as_relative, "damage flash should cover the battle HUD but stay below modal UI")
		_check(flash.mouse_filter == Control.MOUSE_FILTER_IGNORE, "damage flash must not intercept input")

	battle.reset_run_hud()
	combat.castle_system.reset()
	combat.castle_system.damage(2)
	await process_frame
	_check(crystal._damage_tween != null and crystal._damage_tween.is_valid(), "crystal hit animation should start with durability damage")
	_check(flash != null and flash.color.a > 0.0, "screen red flash should start on the same damage event")

	await _wait_seconds(0.28)
	_check(flash != null and flash.color.a <= 0.001, "screen red flash should fade out after the hit")

	battle.reset_run_hud()
	combat.castle_system.reset()
	await _wait_seconds(0.06)
	_check(flash != null and flash.color.a <= 0.001, "run reset and durability restoration must not flash red")

	game.queue_free()
	await process_frame
	print("CRYSTAL_DAMAGE_FLASH_SMOKE_OK" if not _failed else "CRYSTAL_DAMAGE_FLASH_SMOKE_FAILED")
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
