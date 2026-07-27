extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check(GameConfig.get_monster_visual_tier(1) == 1, "wave 1 should use equipment stage 1")
	_check(GameConfig.get_monster_visual_tier(7) == 1, "wave 7 should still use equipment stage 1")
	_check(GameConfig.get_monster_visual_tier(8) == 2, "wave 8 should switch to equipment stage 2")
	_check(GameConfig.get_monster_visual_tier(14) == 2, "wave 14 should still use equipment stage 2")
	_check(GameConfig.get_monster_visual_tier(15) == 3, "wave 15 should switch to equipment stage 3")
	_check(GameConfig.get_monster_visual_tier(20) == 3, "wave 20 should use equipment stage 3")

	var monster_types := ["small", "medium", "large"]
	for monster_type in monster_types:
		for tier in range(1, 4):
			var view := MonsterView.new()
			root.add_child(view)
			view.configure({
				"type": monster_type,
				"hp": 10.0,
				"scale": float(GameConfig.MONSTER_CONFIG[monster_type].get("scale", 1.0)),
				"visual_tier": tier,
			})
			var expected_path := "res://assets/runtime/characters/monsters/slime_stage_%02d.png" % tier
			_check(FileAccess.file_exists(expected_path), "missing runtime monster art: %s" % expected_path)
			_check(view._stage_art_loaded, "%s tier %d should use slime stage art" % [monster_type, tier])
			_check(view._frames.size() == 1, "%s tier %d must use one slime drawing" % [monster_type, tier])
			_check(view._sprite != null and view._sprite.texture != null, "%s tier %d should have a visible texture" % [monster_type, tier])
			if view._sprite and view._sprite.texture:
				_check(view._sprite.texture.resource_path == expected_path, "%s tier %d loaded the wrong image" % [monster_type, tier])
				_check(is_equal_approx(view._sprite.size.x, view._sprite.size.y), "%s tier %d should remain proportionally scaled" % [monster_type, tier])
			view.queue_free()
			await process_frame

	var tutorial := MonsterView.new()
	root.add_child(tutorial)
	tutorial.configure({"type": "tutorial_armored", "hp": 24.0, "scale": 1.85, "visual_tier": 3})
	_check(not tutorial._stage_art_loaded, "tutorial armored monster should use its explicit shield-goblin art")
	_check(tutorial._frames.size() == 1, "tutorial armored monster should still load one texture")
	if tutorial._sprite and tutorial._sprite.texture:
		_check(tutorial._sprite.texture.resource_path.ends_with("goblin_stage_03.png"), "tutorial armored monster should use 06 shield goblin")
	tutorial.queue_free()
	await process_frame

	if failures.is_empty():
		print("MONSTER_VISUAL_REPLACEMENT_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
