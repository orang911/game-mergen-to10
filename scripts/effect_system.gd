extends Node
class_name EffectSystem

var _effect_layer: Control
var _texture_cache: Dictionary = {}
var _visual_board_pos := GameConfig.BOARD_GRID_POS
var _board_size := GameConfig.get_board_size()


func setup(layer: Control) -> void:
	_effect_layer = layer


func layout_for_board(new_visual_board_pos: Vector2, new_board_size: Vector2) -> void:
	_visual_board_pos = new_visual_board_pos
	_board_size = new_board_size


func reset() -> void:
	if _effect_layer == null or not is_instance_valid(_effect_layer):
		return
	_recursive_free_effect_nodes(_effect_layer)


func _recursive_free_effect_nodes(parent: Node) -> void:
	for child in parent.get_children():
		if child.name.begins_with("Effect_"):
			child.queue_free()
		else:
			_recursive_free_effect_nodes(child)


func play_merge_feedback(event: MergeAttackEvent) -> void:
	const PROMPT_SCENE = preload("res://scenes/combat/merge_attack_prompt_view.tscn")
	const PROMPT_BACKGROUND = preload("res://assets/runtime/ui/battle/prompts/prompt_panel.png")
	const ICON_FIRE = preload("res://assets/runtime/ui/battle/prompts/icon_fire.png")
	const ICON_POISON = preload("res://assets/runtime/ui/battle/prompts/icon_poison.png")
	const ICON_CRITICAL = preload("res://assets/runtime/ui/battle/prompts/icon_critical.png")
	const ICON_LIGHTNING = preload("res://assets/runtime/ui/battle/prompts/icon_lightning.png")
	const ICON_ICE = preload("res://assets/runtime/ui/battle/prompts/icon_ice.png")

	if _effect_layer == null or not is_instance_valid(_effect_layer):
		return

	var parent: Control = _effect_layer.get_node_or_null("FloatingText") as Control
	if parent == null:
		parent = _effect_layer

	var presentation_map: Dictionary = {
		"fire": {"icon": ICON_FIRE, "name": "燃烧"},
		"poison": {"icon": ICON_POISON, "name": "中毒"},
		"critical": {"icon": ICON_CRITICAL, "name": "暴击"},
		"lightning": {"icon": ICON_LIGHTNING, "name": "电击"},
		"ice": {"icon": ICON_ICE, "name": "冰冻"},
	}

	var presentation: Dictionary = presentation_map.get(event.element_key, {}) as Dictionary
	var icon: Texture2D = presentation.get("icon", null) as Texture2D
	if icon == null:
		return

	var instance := PROMPT_SCENE.instantiate() as MergeAttackPromptView
	if instance == null:
		return

	instance.name = "Effect_MergeAttackPrompt"
	parent.add_child(instance, true)

	var row := clampi(event.board_row, 0, GameConfig.GRID_SIZE - 1)
	var row_top_y: float = _visual_board_pos.y + GameConfig.get_block_position_for_site(Vector2i(0, row)).y
	var target_position := Vector2(
		_visual_board_pos.x + (_board_size.x - MergeAttackPromptView.DISPLAY_SIZE.x) * 0.5,
		row_top_y - 8.0
	)

	instance.play(PROMPT_BACKGROUND, icon, str(presentation.get("name", "")), event.atk, target_position)


func play_monster_hit(_monster: Monster) -> void:
	# Generic flash/scale hit feedback is temporarily disabled. Lightning keeps
	# its dedicated spritesheet hit sequence through play_element_hit().
	pass


func play_monster_reached_goal(monster: Monster) -> void:
	if not is_instance_valid(monster):
		return
	var tween := monster.create_tween()
	tween.tween_property(monster, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.06)
	tween.parallel().tween_property(monster, "scale", Vector2(0.65, 0.65), 0.12)
	tween.tween_property(monster, "modulate:a", 0.0, 0.12)


func play_castle_damage(_amount: int) -> void:
	pass


# -- Element FX --

func play_element_launch(req: ElementFxRequest) -> void:
	if _effect_layer == null or not is_instance_valid(_effect_layer):
		return
	if req.element_key != "lightning":
		return
	var flash_size := GameConfig.LAUNCH_FLASH_SIZE
	var local_pos: Vector2 = _global_to_effect_local(req.origin_position)
	var flash := ColorRect.new()
	flash.name = "Effect_LaunchFlash"
	flash.color = _element_color(req.element_key)
	flash.size = flash_size
	flash.position = local_pos - flash_size * 0.5
	flash.pivot_offset = flash_size * 0.5
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_effect_layer.add_child(flash)
	var tween := flash.create_tween()
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.15, 1.15), GameConfig.LAUNCH_FLASH_DURATION).from(Vector2(0.6, 0.6))
	tween.tween_property(flash, "modulate:a", 0.0, GameConfig.LAUNCH_FLASH_DURATION).from(0.75)
	tween.chain().tween_callback(flash.queue_free)


func _element_color(key: String) -> Color:
	match key:
		"poison":    return Color(0.35, 0.9, 0.3, 1.0)
		"ice":       return Color(0.5, 0.8, 1.0, 1.0)
		"lightning": return Color(1.0, 0.95, 0.25, 1.0)
		"critical":  return Color(0.75, 0.4, 0.95, 1.0)
		"fire":      return Color(1.0, 0.45, 0.15, 1.0)
	return Color(0.7, 0.92, 1.0, 1.0)


func play_element_hit(element_key_or_req, position: Vector2 = Vector2.ZERO, tier: int = 1) -> void:
	if _effect_layer == null or not is_instance_valid(_effect_layer):
		return

	var element_key: String = "poison"
	var hit_position: Vector2 = position
	var tier_value: int = tier
	if element_key_or_req is ElementFxRequest:
		var req := element_key_or_req as ElementFxRequest
		element_key = req.element_key
		hit_position = req.target_position
		tier_value = req.tier
	else:
		element_key = str(element_key_or_req)
	if element_key != "lightning":
		return

	var fx: Dictionary = GameConfig.get_element_fx(element_key)
	var sheet: Texture2D = _load_texture(str(fx.get("hit", "")))
	if sheet == null:
		return

	var hit_size: Vector2 = fx.get("hit_size", Vector2(160.0, 160.0)) as Vector2
	var hit_grid: Vector2i = fx.get("hit_grid", GameConfig.ELEMENT_HIT_GRID) as Vector2i
	var hit_frame_count := clampi(int(fx.get("hit_frame_count", GameConfig.ELEMENT_HIT_FRAME_COUNT)), 1, hit_grid.x * hit_grid.y)
	var hit_fps := maxf(1.0, float(fx.get("hit_fps", GameConfig.ELEMENT_HIT_FPS)))
	var local_pos: Vector2 = _global_to_effect_local(hit_position)
	var frame := TextureRect.new()
	frame.name = "Effect_ElementHit_%s" % element_key
	frame.texture = _make_atlas_frame(sheet, 0, hit_grid)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size = hit_size
	frame.position = local_pos - hit_size * 0.5
	frame.pivot_offset = hit_size * 0.5
	frame.scale = Vector2.ONE * (1.0 + float(max(0, tier_value - 1)) * 0.04)
	_effect_layer.add_child(frame)
	_play_hit_frames(frame, sheet, hit_grid, hit_frame_count, hit_fps)


func play_critical_hit(_element_key: String, _hit_position: Vector2, _tier: int) -> void:
	# Critical damage remains active; its temporary flash and floating hit art do not.
	pass


func play_element_chain(_req: ElementFxRequest) -> void:
	pass


func play_element_area(_req: ElementFxRequest) -> void:
	pass


func play_status_apply(_req: ElementFxRequest) -> void:
	pass


func play_status_tick(_req: ElementFxRequest) -> void:
	pass


func play_status_end(_req: ElementFxRequest) -> void:
	pass


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D
	var texture := load(path) as Texture2D
	if texture:
		_texture_cache[path] = texture
	return texture


func _global_to_effect_local(global_pos: Vector2) -> Vector2:
	return _effect_layer.get_global_transform_with_canvas().affine_inverse() * global_pos


func _make_atlas_frame(sheet: Texture2D, frame_index: int, grid: Vector2i) -> AtlasTexture:
	var frame_size := Vector2(
		floorf(sheet.get_width() / float(grid.x)),
		floorf(sheet.get_height() / float(grid.y))
	)
	var col := frame_index % grid.x
	var row := floori(float(frame_index) / float(grid.x))
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(Vector2(float(col), float(row)) * frame_size, frame_size)
	atlas.filter_clip = true
	return atlas


func _play_hit_frames(node: TextureRect, sheet: Texture2D, grid: Vector2i, frame_count: int, fps: float) -> void:
	var frame_delay := 1.0 / fps
	for i in range(frame_count):
		if not is_instance_valid(node):
			return
		node.texture = _make_atlas_frame(sheet, i, grid)
		await get_tree().create_timer(frame_delay).timeout
	if is_instance_valid(node):
		node.queue_free()
