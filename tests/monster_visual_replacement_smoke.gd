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
			var expected_path := (
				MonsterView.SLIME_STAGE_01_WALK_SHEET
				if tier == 1
				else "res://assets/runtime/characters/monsters/slime_stage_%02d.png" % tier
			)
			_check(ResourceLoader.exists(expected_path), "missing runtime monster art: %s" % expected_path)
			_check(view._stage_art_loaded, "%s tier %d should use slime stage art" % [monster_type, tier])
			if tier == 1:
				_check(view._frames.size() == 18, "%s tier one should load all 18 walk frames" % monster_type)
				_check(view._hit_frames.size() == 8, "%s tier one should load all 8 hit frames" % monster_type)
			else:
				_check(view._frames.size() == 1, "%s tier %d must keep one slime drawing" % [monster_type, tier])
				_check(view._hit_frames.is_empty(), "%s tier %d should not borrow tier-one hit art" % [monster_type, tier])
			_check(view._sprite != null and view._sprite.texture != null, "%s tier %d should have a visible texture" % [monster_type, tier])
			if view._sprite and view._sprite.texture:
				if tier == 1:
					_check(_is_atlas_frame(view._sprite.texture, expected_path, 0, 6), "%s tier %d loaded the wrong atlas frame" % [monster_type, tier])
				else:
					_check(view._sprite.texture.resource_path == expected_path, "%s tier %d loaded the wrong image" % [monster_type, tier])
				_check(is_equal_approx(view._sprite.size.x, view._sprite.size.y), "%s tier %d should remain proportionally scaled" % [monster_type, tier])
			if tier == 1:
				var hit_duration := view.play_hit_animation()
				_check(is_equal_approx(hit_duration, 8.0 / 24.0), "%s hit sequence should run at 24 FPS" % monster_type)
				_check(view._hit_playing and _is_atlas_frame(view._sprite.texture, MonsterView.SLIME_STAGE_01_HIT_SHEET, 0, 4), "%s should switch to the hit sequence immediately" % monster_type)
				view._process(hit_duration + 0.01)
				_check(not view._hit_playing and _is_atlas_frame(view._sprite.texture, MonsterView.SLIME_STAGE_01_WALK_SHEET, view._frame_index, 6), "%s should return to its walk loop after the hit" % monster_type)
			view.queue_free()
			await process_frame

	var tutorial := MonsterView.new()
	root.add_child(tutorial)
	tutorial.configure({"type": "tutorial_armored", "hp": 24.0, "scale": 1.85, "visual_tier": 3})
	_check(tutorial._stage_art_loaded and tutorial._authored_walk_animation, "tutorial armored monster should use its authored animation")
	_check(tutorial._frames.size() == MonsterView.TUTORIAL_ARMORED_WALK_FRAME_COUNT, "tutorial armored monster should load all 28 walk frames")
	_check(tutorial._hit_frames.size() == MonsterView.TUTORIAL_ARMORED_HIT_FRAME_COUNT, "tutorial armored monster should load all 5 hit frames")
	if tutorial._sprite and tutorial._sprite.texture:
		_check(_is_atlas_frame(tutorial._sprite.texture, MonsterView.TUTORIAL_ARMORED_WALK_SHEET, 0, 6), "tutorial armored walk must begin on atlas frame zero")
		tutorial._process(MonsterView.WALK_FRAME_DURATION + 0.001)
		_check(_is_atlas_frame(tutorial._sprite.texture, MonsterView.TUTORIAL_ARMORED_WALK_SHEET, 1, 6), "tutorial armored walk atlas frames must advance at runtime")
		var tutorial_hit_duration := tutorial.play_hit_animation()
		_check(is_equal_approx(tutorial_hit_duration, 5.0 / 24.0), "tutorial armored hit sequence should run at 24 FPS")
		_check(_is_atlas_frame(tutorial._sprite.texture, MonsterView.TUTORIAL_ARMORED_HIT_SHEET, 0, 5), "tutorial armored damage must begin on the first hit atlas frame")
		tutorial._process(tutorial_hit_duration + 0.01)
		_check(not tutorial._hit_playing and _is_atlas_frame(tutorial._sprite.texture, MonsterView.TUTORIAL_ARMORED_WALK_SHEET, tutorial._frame_index, 6), "tutorial armored monster must return to its walk atlas after being hit")
	tutorial.queue_free()
	await process_frame

	for boss_case in [
		{"appearance_id": "mini_boss", "expected": "res://assets/runtime/characters/monsters/goblin_stage_03.png"},
		{"appearance_id": "chapter_boss", "expected": "res://assets/runtime/characters/monsters/zombie_stage_03.png"},
	]:
		var boss_view := MonsterView.new()
		root.add_child(boss_view)
		boss_view.configure({"type": "large", "appearance_id": boss_case["appearance_id"], "hp": 100.0, "scale": 1.0, "visual_tier": 3})
		_check(boss_view._sprite != null and boss_view._sprite.texture != null, "%s should always have authored art" % boss_case["appearance_id"])
		if boss_view._sprite and boss_view._sprite.texture:
			_check(boss_view._sprite.texture.resource_path == boss_case["expected"], "%s should use its explicit packaged texture" % boss_case["appearance_id"])
		boss_view.queue_free()
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


func _is_atlas_frame(texture: Texture2D, sheet_path: String, frame_index: int, columns: int) -> bool:
	var atlas := texture as AtlasTexture
	if atlas == null or atlas.atlas == null:
		return false
	var pitch := MonsterView.ANIMATION_FRAME_SIZE + Vector2.ONE * float(MonsterView.ANIMATION_FRAME_PADDING * 2)
	var expected_position := Vector2(float(frame_index % columns), float(frame_index / columns)) * pitch
	expected_position += Vector2.ONE * float(MonsterView.ANIMATION_FRAME_PADDING)
	return atlas.atlas.resource_path == sheet_path and atlas.region.position == expected_position
