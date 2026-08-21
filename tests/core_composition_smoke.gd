extends SceneTree

const BattleScene := preload("res://scenes/combat/battle_layer.tscn")
const MainScene := preload("res://scenes/main.tscn")

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var board_texture := load("res://assets/runtime/ui/interfaces/battle/board/standalone/battle_board_backdrop.png") as Texture2D
	_check(board_texture != null, "new board backdrop should load")
	_check(board_texture.get_size().is_equal_approx(Vector2(1254, 1254)), "new board backdrop should retain its authored dimensions")
	var expected_plate_position := Vector2(136.00, 688.36)
	var expected_plate_size := Vector2(653.68, 649.39)
	_check(GameConfig.get_board_plate_position(GameConfig.BOARD_GRID_POS).distance_to(expected_plate_position) < 0.08, "board backdrop should use the effect-image anchor")
	_check(GameConfig.get_board_backdrop_size().distance_to(expected_plate_size) < 0.08, "board backdrop should preserve the effect-image scale")
	var first_block_visual := GameConfig.BOARD_GRID_POS + GameConfig.get_block_position_for_site(Vector2i(0, 4)) + (Vector2(GameConfig.BLOCK_SIZE, GameConfig.BLOCK_SIZE) - GameConfig.BLOCK_VISUAL_SIZE) * 0.5
	_check(first_block_visual.distance_to(Vector2(177.05, 725.29)) < 0.08, "top-left block should sit inside the new board inner frame")
	_check(GameConfig.BOTTOM_HUD_BASE_POSITION.distance_to(Vector2(0.0, 1405.75)) < 0.08, "bottom backdrop should leave the lower path turn visible")
	_check(GameConfig.ENERGY_HUD_POSITION.distance_to(Vector2(14.0, 1420.0)) < 0.08, "energy panel should use the effect-image anchor")

	var road_texture := load("res://assets/runtime/ui/interfaces/battle/standalone/monster_path.png") as Texture2D
	var road_image := road_texture.get_image() if road_texture else null
	_check(road_image != null, "new path image should load")
	var portal_sheet := load(GatePortalEffect.SPRITE_SHEET_PATH) as Texture2D
	_check(portal_sheet != null and portal_sheet.get_size().is_equal_approx(Vector2(1640.0, 1312.0)), "runtime portal sheet should use the mobile-safe 1640x1312 atlas")
	for source_point in GameConfig.PATH_ROAD_POINTS:
		var pixel := road_image.get_pixelv(Vector2i(source_point)) if road_image else Color.TRANSPARENT
		_check(pixel.a > 0.9, "every movement point should stay on the opaque road centerline")

	var board_pos := GameConfig.BOARD_GRID_POS + GameConfig.BOARD_VISUAL_OFFSET
	var road_rect := GameConfig.get_path_road_rect(board_pos, GameConfig.get_board_size())
	var gate_rect := GameConfig.get_path_gate_rect(board_pos, GameConfig.get_board_size())
	_check(road_rect.position.is_equal_approx(GameConfig.PATH_ROAD_POSITION), "road should use the fixed composition anchor")
	_check(gate_rect.position.is_equal_approx(GameConfig.PATH_GATE_POSITION), "gate should use the fixed composition anchor")

	var expected_goal := GameConfig.PATH_ROAD_POSITION + GameConfig.PATH_ROAD_POINTS[-1] * GameConfig.PATH_ROAD_SCALE
	var authored_crystal_position := Vector2(247.20, 452.80)
	var authored_crystal_base := authored_crystal_position + CrystalView.TOWER_RENDER_BASELINE
	_check(GameConfig.CRYSTAL_CASTLE_PANEL_POSITION.is_equal_approx(authored_crystal_position), "runtime crystal anchor should match the authored scene position")

	var battle := BattleScene.instantiate() as BattleLayerView
	root.add_child(battle)
	await process_frame
	var portal := battle.get_node_or_null("DesignRoot/DecorLayer/GatePortalEffect") as Control
	var authored_portal_position := portal.position if portal else Vector2.ZERO
	var authored_portal_size := portal.size if portal else Vector2.ZERO
	var authored_portal_scale := portal.scale if portal else Vector2.ZERO
	var authored_portal_rotation := portal.rotation if portal else 0.0
	battle.layout_for_board(board_pos, GameConfig.get_board_size(), 0.0, expected_goal, expected_goal, board_pos)
	await process_frame
	var gate := battle.get_node_or_null("DesignRoot/DecorLayer/Gate") as TextureRect
	var crystal := battle.get_crystal_view()
	_check(gate != null and gate.position.is_equal_approx(gate_rect.position), "new gate should be placed at the composition anchor")
	_check(gate != null and gate.texture != null and gate.texture.resource_path.ends_with("ui/interfaces/battle/standalone/monster_gate.png"), "live entrance should use the organized gate art")
	_check(portal != null and portal.position.is_equal_approx(authored_portal_position), "runtime layout must preserve the portal's scene-authored position")
	_check(portal != null and portal.size.is_equal_approx(authored_portal_size), "runtime layout must preserve the portal's scene-authored size")
	_check(portal != null and portal.scale.is_equal_approx(authored_portal_scale), "runtime layout must preserve the portal's scene-authored scale")
	_check(portal != null and is_equal_approx(portal.rotation, authored_portal_rotation), "runtime layout must preserve the portal's scene-authored rotation")
	if portal is GatePortalEffect:
		var portal_effect := portal as GatePortalEffect
		_check(portal_effect._frames.size() == 20, "updated portal sheet should expose all twenty frames")
		if not portal_effect._frames.is_empty():
			_check(portal_effect._frames[0].region.size.is_equal_approx(GatePortalEffect.FRAME_SIZE), "updated portal frames should use the mobile-safe 320px cells")
		var portal_visual := portal_effect.get_node_or_null("Visual") as TextureRect
		_check(portal_visual != null and portal_visual.position.is_equal_approx(Vector2.ZERO), "portal frames should use their authored top-left origin without centroid correction")
		portal_effect._set_frame(7)
		_check(portal_visual != null and portal_visual.position.is_equal_approx(Vector2.ZERO), "changing portal frames must not apply positional compensation")
	_check(crystal != null and crystal.position.is_equal_approx(GameConfig.CRYSTAL_CASTLE_PANEL_POSITION), "crystal panel should use the new endpoint anchor")
	var tower := crystal.get_node_or_null("Tower") as TextureRect if crystal else null
	var visual_base := crystal.get_global_transform_with_canvas() * (tower.position + tower.pivot_offset) if crystal and tower else Vector2.ZERO
	_check(tower != null and tower.size == CrystalView.TOWER_CANVAS_SIZE, "crystal should render from the shared 512px canvas")
	_check(tower != null and visual_base.distance_to(authored_crystal_base) < 1.0, "crystal floor baseline should follow the authored scene position")
	var path_view := battle.get_path_view()
	_check(portal != null and portal.z_index == 4, "portal should render above background/decor at z 4")
	_check(path_view != null and path_view.z_index == 5, "road should render above the portal at z 5")
	var runtime_road := path_view.get("_road_texture") as Texture2D if path_view else null
	_check(runtime_road != null and runtime_road.resource_path.ends_with("ui/interfaces/battle/standalone/monster_path.png"), "live path renderer should use the organized path art")
	battle.queue_free()
	await process_frame

	# Build the actual game root as a resource/layout audit. This verifies that
	# the composition constants are not only correct in isolation but are used by
	# the live background, board, bottom background and energy HUD nodes.
	var main := MainScene.instantiate() as Control
	root.add_child(main)
	await process_frame
	await process_frame
	var game_layer := main.get_node_or_null("Game") as Control
	var live_board := game_layer.get_node_or_null("Board") as Control if game_layer else null
	var board_backdrop := game_layer.get_node_or_null("BoardBackdrop") as TextureRect if game_layer else null
	var live_background := game_layer.get_node_or_null("BattleBackground") as TextureRect if game_layer else null
	var bottom_ui := game_layer.get_node_or_null("BottomUi") as Control if game_layer else null
	var live_energy_hud := game_layer.get_node_or_null("EnergyHud") as Control if game_layer else null
	_check(board_backdrop != null and board_backdrop.texture != null and board_backdrop.texture.resource_path.ends_with("ui/interfaces/battle/board/standalone/battle_board_backdrop.png"), "live board should directly reference the organized battle-board backdrop")
	_check(board_backdrop != null and board_backdrop.position.distance_to(expected_plate_position) < 0.08, "live board backdrop should use the effect-image position")
	_check(board_backdrop != null and board_backdrop.scale.is_equal_approx(Vector2.ONE), "board backdrop should remain at its authored scale")
	_check(live_board != null and live_board.scale.is_equal_approx(Vector2.ONE * GameConfig.BOARD_CONTENT_SCALE), "block board should be uniformly reduced by five percent")
	_check(live_board != null and live_board.pivot_offset.is_equal_approx(Vector2(live_board.size.x * 0.5, live_board.size.y)), "block board should scale around its bottom-centre pivot")
	var live_board_bottom := live_board.get_transform() * Vector2(live_board.size.x * 0.5, live_board.size.y) if live_board else Vector2.ZERO
	var expected_board_bottom := GameConfig.BOARD_GRID_POS + Vector2(GameConfig.get_board_size().x * 0.5, GameConfig.get_board_size().y)
	_check(live_board_bottom.distance_to(expected_board_bottom) < 0.08, "block board bottom edge should remain fixed after scaling")
	_check(live_background != null and live_background.texture != null and live_background.texture.resource_path.ends_with("ui/interfaces/battle/standalone/battle_background.png"), "live battle background should use the organized background")
	_check(bottom_ui != null and bottom_ui.position.distance_to(GameConfig.BOTTOM_HUD_BASE_POSITION) < 0.08, "live bottom background should leave the path turn visible")
	_check(live_energy_hud != null and live_energy_hud.position.distance_to(GameConfig.ENERGY_HUD_POSITION) < 0.08, "live energy HUD should use the effect-image anchor")
	main.queue_free()
	await process_frame
	print("CORE_COMPOSITION_SMOKE_OK" if not _failed else "CORE_COMPOSITION_SMOKE_FAILED")
	quit(1 if _failed else 0)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
