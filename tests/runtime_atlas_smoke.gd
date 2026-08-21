extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_atlas_resources(GameConfig.BLOCK_BG_PATHS.values(), 5, "block tile")
	_check_atlas_resources(GameConfig.TEXT_BLOCK_PATHS, GameConfig.MAX_BLOCK_LEVEL, "block glyph")

	var card_paths: Array[String] = []
	for card_id in CardCatalog.DEFINITIONS:
		card_paths.append(str(CardCatalog.DEFINITIONS[card_id].get("icon", "")))
	_check_atlas_resources(card_paths, CardCatalog.DEFINITIONS.size(), "card icon")
	_check(MainHubView.PACKED_ICON_DEPENDENCIES.size() == 15, "lobby atlas must expose all fifteen icon regions")
	for texture in MainHubView.PACKED_ICON_DEPENDENCIES:
		_check(texture is AtlasTexture, "lobby icon dependency must be an AtlasTexture")

	_check_grid("res://assets/runtime/fx/merge/atlases/merge_sheet.png", Vector2(200, 200), 13, 4, 4)
	_check_grid("res://assets/runtime/fx/elements/lightning/atlases/beam_sheet.png", Vector2(258, 516), 3, 3, 4)
	_check_grid(MonsterView.SLIME_STAGE_01_WALK_SHEET, MonsterView.ANIMATION_FRAME_SIZE, 18, 6, MonsterView.ANIMATION_FRAME_PADDING)
	_check_grid(MonsterView.SLIME_STAGE_01_HIT_SHEET, MonsterView.ANIMATION_FRAME_SIZE, 8, 4, MonsterView.ANIMATION_FRAME_PADDING)
	_check_grid(MonsterView.DEATH_SHEET, MonsterView.ANIMATION_FRAME_SIZE, 19, 5, MonsterView.ANIMATION_FRAME_PADDING)
	_check_grid(MonsterView.TUTORIAL_ARMORED_WALK_SHEET, MonsterView.ANIMATION_FRAME_SIZE, 28, 6, MonsterView.ANIMATION_FRAME_PADDING)
	_check_grid(MonsterView.TUTORIAL_ARMORED_HIT_SHEET, MonsterView.ANIMATION_FRAME_SIZE, 5, 5, MonsterView.ANIMATION_FRAME_PADDING)
	_check_grid(GatePortalEffect.SPRITE_SHEET_PATH, GatePortalEffect.FRAME_SIZE, GatePortalEffect.FRAME_COUNT, GatePortalEffect.FRAME_GRID.x, GatePortalEffect.FRAME_PADDING)

	if failures.is_empty():
		print("RUNTIME_ATLAS_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check_atlas_resources(paths: Array, expected_count: int, label: String) -> void:
	_check(paths.size() == expected_count, "%s atlas region count mismatch" % label)
	for path_value in paths:
		var path := str(path_value)
		var texture := load(path) as Texture2D
		_check(texture is AtlasTexture, "%s must load from an AtlasTexture: %s" % [label, path])
		if texture is AtlasTexture:
			_check_atlas_frame_content(texture as AtlasTexture, "%s: %s" % [label, path])


func _check_grid(path: String, frame_size: Vector2, count: int, columns: int, padding: int = 0) -> void:
	var frames := RuntimeAtlas.load_grid(path, frame_size, count, columns)
	_check(frames.size() == count, "grid atlas frame count mismatch: %s" % path)
	for frame_index in range(frames.size()):
		var atlas := frames[frame_index] as AtlasTexture
		_check(atlas != null and atlas.atlas != null, "grid frame must be an AtlasTexture: %s" % path)
		if atlas:
			_check(atlas.region.size == frame_size, "grid frame size mismatch: %s" % path)
			var pitch := frame_size + Vector2.ONE * float(padding * 2)
			var expected := Vector2(float(frame_index % columns), floorf(float(frame_index) / float(columns))) * pitch + Vector2.ONE * float(padding)
			_check(atlas.region.position == expected, "grid frame position mismatch: %s" % path)
			_check_atlas_frame_content(atlas, "%s frame %d" % [path, frame_index])


func _check_atlas_frame_content(atlas: AtlasTexture, label: String) -> void:
	if atlas == null or atlas.atlas == null:
		return
	var sheet_size := atlas.atlas.get_size()
	_check(sheet_size.x <= 2048.0 and sheet_size.y <= 2048.0, "atlas exceeds mobile 2048 limit: %s (%s)" % [label, sheet_size])
	var sheet_image := atlas.atlas.get_image()
	_check(sheet_image != null and not sheet_image.is_empty(), "atlas image should be readable: %s" % label)
	if sheet_image == null or sheet_image.is_empty():
		return
	var frame_image := sheet_image.get_region(Rect2i(atlas.region))
	_check(frame_image.get_used_rect().has_area(), "atlas frame must contain non-transparent pixels: %s" % label)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
