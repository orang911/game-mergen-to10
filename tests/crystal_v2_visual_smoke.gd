extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	for level in range(1, 10):
		var data: Dictionary = CrystalView.TOWER_VISUALS[level]
		var texture := data["texture"] as Texture2D
		var expected_path := "res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv%02d.png" % level
		_check(texture != null, "level %d should have a V2 texture" % level)
		if texture:
			_check(texture.resource_path == expected_path, "level %d should load its V2 runtime texture" % level)
			_check(texture.get_size() == CrystalView.TOWER_CANVAS_SIZE, "level %d should use the shared 512px canvas" % level)

	var packed := load("res://scenes/combat/battle_layer.tscn") as PackedScene
	var battle := packed.instantiate() as BattleLayerView
	root.add_child(battle)
	await process_frame
	await process_frame
	var crystal := battle.get_crystal_view()
	var tower := crystal.get_node_or_null("Tower") as TextureRect
	_check(tower != null, "battle crystal tower should exist")
	if tower:
		_check(tower.texture.resource_path.ends_with("ui/components/crystal_tower/textures/crystal_tower_lv01.png"), "scene default should use organized V2 level one")
		_check(tower.size == CrystalView.TOWER_CANVAS_SIZE, "runtime tower node should keep the shared canvas size")
		_check((tower.position + tower.pivot_offset).distance_to(CrystalView.TOWER_RENDER_BASELINE) < 0.01, "runtime tower baseline should stay fixed at the path anchor")

	crystal.set_awakened(false)
	await process_frame
	if tower:
		_check(tower.texture.resource_path.ends_with("ui/components/crystal_tower/textures/crystal_tower_lv01.png"), "dormant state should use the organized V2 level-one silhouette")
		_check(tower.modulate == CrystalView.DORMANT_MODULATE, "dormant state should darken the V2 crystal without an old texture")
	crystal.set_awakened(true)
	for level in range(2, 10):
		crystal.set_crystal_level(level)
		await process_frame
		if tower:
			_check(tower.texture.resource_path.ends_with("ui/components/crystal_tower/textures/crystal_tower_lv%02d.png" % level), "level %d should switch to its organized V2 artwork" % level)
			_check(tower.scale.x == tower.scale.y, "level %d must keep aspect ratio" % level)
			_check(tower.size == CrystalView.TOWER_CANVAS_SIZE, "level %d should preserve the shared canvas" % level)
			var visual_rect := crystal.call("_get_tower_visual_rect") as Rect2
			_check(absf(visual_rect.end.y - CrystalView.TOWER_RENDER_BASELINE.y) < 0.01, "level %d should keep the crystal floor baseline fixed" % level)

	var durability_label := crystal.get_node_or_null("DurabilityLabel") as Label
	var durability_bar := crystal.get_node_or_null("DurabilityBack") as ColorRect
	_check(durability_label != null and durability_label.position.is_equal_approx(Vector2(24, 208)), "durability text should stay below the tower")
	_check(durability_bar != null and durability_bar.position.is_equal_approx(Vector2(46, 234)), "durability bar should stay below the durability text")
	crystal.call("_show_panel")
	await process_frame
	var tip_panel := crystal.get_node_or_null("AtkPanel") as Control
	var final_rect := crystal.call("_get_tower_visual_rect") as Rect2
	var expected_tip_anchor := Vector2(final_rect.end.x + 7.0, final_rect.get_center().y)
	_check(tip_panel != null and (tip_panel.position + tip_panel.pivot_offset).distance_to(expected_tip_anchor) < 0.01, "attack tip should anchor to the visible crystal edge")

	battle.queue_free()
	await process_frame
	print("CRYSTAL_V2_VISUAL_SMOKE_OK" if not _failed else "CRYSTAL_V2_VISUAL_SMOKE_FAILED")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
