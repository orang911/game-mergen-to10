@tool
extends TextureRect
class_name GatePortalEffect

const SPRITE_SHEET := preload("res://assets/UI/游戏核心/门口特效.png")
const FRAME_GRID := Vector2i(4, 4)
const FRAME_SIZE := Vector2(256.0, 256.0)
const FRAME_COUNT := FRAME_GRID.x * FRAME_GRID.y
const ALPHA_THRESHOLD := 0.5
const CENTROID_SAMPLE_STEP := 2

@export_range(1.0, 60.0, 1.0) var frame_rate := 12.0

var _frames: Array[AtlasTexture] = []
var _frame_centroids: Array[Vector2] = []
var _frame_anchor := FRAME_SIZE * 0.5
var _visual_rect: TextureRect
var _frame_index := 0
var _frame_elapsed := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	clip_contents = false
	_ensure_visual_rect()
	_build_frames()
	_set_frame(0)
	set_process(not Engine.is_editor_hint())


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_instance_valid(_visual_rect):
		_sync_visual_layout()


func _process(delta: float) -> void:
	if _frames.is_empty() or frame_rate <= 0.0:
		return
	_frame_elapsed += delta
	var frame_duration := 1.0 / frame_rate
	while _frame_elapsed >= frame_duration:
		_frame_elapsed -= frame_duration
		_set_frame((_frame_index + 1) % _frames.size())


func _build_frames() -> void:
	_frames.clear()
	_frame_centroids.clear()
	var source_image := SPRITE_SHEET.get_image()
	var anchor_sum := Vector2.ZERO
	for index in range(FRAME_COUNT):
		var col := index % FRAME_GRID.x
		var row := floori(float(index) / float(FRAME_GRID.x))
		var atlas := AtlasTexture.new()
		atlas.atlas = SPRITE_SHEET
		atlas.region = Rect2(Vector2(float(col), float(row)) * FRAME_SIZE, FRAME_SIZE)
		atlas.filter_clip = true
		_frames.append(atlas)
		var centroid := FRAME_SIZE * 0.5
		if source_image != null:
			centroid = _measure_frame_centroid(source_image, col, row)
		_frame_centroids.append(centroid)
		anchor_sum += centroid
	if not _frame_centroids.is_empty():
		_frame_anchor = anchor_sum / float(_frame_centroids.size())


func _ensure_visual_rect() -> void:
	if is_instance_valid(_visual_rect):
		return
	_visual_rect = get_node_or_null("Visual") as TextureRect
	if not is_instance_valid(_visual_rect):
		_visual_rect = TextureRect.new()
		_visual_rect.name = "Visual"
		add_child(_visual_rect)
	_visual_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_visual_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_visual_rect.stretch_mode = TextureRect.STRETCH_SCALE
	# The root node remains the manually positioned/sized layout anchor. Only
	# this child is shifted to compensate for motion inside the sprite sheet.
	texture = null
	_sync_visual_layout()


func _sync_visual_layout() -> void:
	if not is_instance_valid(_visual_rect):
		return
	_visual_rect.size = size
	_apply_frame_offset()


func _apply_frame_offset() -> void:
	if not is_instance_valid(_visual_rect) or _frame_centroids.is_empty():
		return
	var centroid := _frame_centroids[_frame_index]
	var pixels_per_source_pixel := Vector2(
		size.x / FRAME_SIZE.x,
		size.y / FRAME_SIZE.y
	)
	_visual_rect.position = (_frame_anchor - centroid) * pixels_per_source_pixel


func _measure_frame_centroid(image: Image, col: int, row: int) -> Vector2:
	var weighted_position := Vector2.ZERO
	var alpha_sum := 0.0
	var origin_x := col * int(FRAME_SIZE.x)
	var origin_y := row * int(FRAME_SIZE.y)
	for y in range(0, int(FRAME_SIZE.y), CENTROID_SAMPLE_STEP):
		for x in range(0, int(FRAME_SIZE.x), CENTROID_SAMPLE_STEP):
			var alpha := image.get_pixel(origin_x + x, origin_y + y).a
			if alpha < ALPHA_THRESHOLD:
				continue
			alpha_sum += alpha
			weighted_position += Vector2(float(x), float(y)) * alpha
	if alpha_sum <= 0.0:
		return FRAME_SIZE * 0.5
	return weighted_position / alpha_sum


func _set_frame(index: int) -> void:
	if _frames.is_empty():
		return
	_frame_index = posmod(index, _frames.size())
	if is_instance_valid(_visual_rect):
		_visual_rect.texture = _frames[_frame_index]
		_apply_frame_offset()
