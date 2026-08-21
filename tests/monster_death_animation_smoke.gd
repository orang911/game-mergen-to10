extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var layer := Control.new()
	root.add_child(layer)
	var system := MonsterSystem.new()
	root.add_child(system)
	var monster := Monster.new()
	monster.setup({"type": "small", "hp": 5.0, "scale": 1.0, "visual_tier": 1})
	layer.add_child(monster)
	system.monsters.append(monster)
	await process_frame

	monster.kill("test")
	system._remove_monster(monster)
	var view: MonsterView = monster._view
	_check(view != null, "monster should retain its view while its death sequence plays")
	if view:
		_check(view._death_playing, "monster removal should start the death animation")
		_check(view._death_frames.size() == 19, "death animation should load all nineteen supplied frames")
		_check(view._sprite.texture == view._death_frames[0], "death animation should start on C-1")
	_check(not system.monsters.has(monster), "dead monster must leave targeting and wave logic immediately")
	await _wait_seconds(0.14)
	if view and is_instance_valid(view):
		_check(view._death_frame_index >= 2, "death frames should advance at runtime")
	await _wait_seconds(0.80)
	_check(not is_instance_valid(monster), "monster should release after its death animation completes")

	system.queue_free()
	layer.queue_free()
	await process_frame
	if failures.is_empty():
		print("MONSTER_DEATH_ANIMATION_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _wait_seconds(seconds: float) -> void:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < deadline:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
