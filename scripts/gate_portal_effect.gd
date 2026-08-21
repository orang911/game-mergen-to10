@tool
extends TextureRect
class_name GatePortalEffect

const SPRITE_SHEET_PATH := "res://assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png"
const FRAME_GRID := Vector2i(5, 4)
const FRAME_SIZE := Vector2(320.0, 320.0)
const FRAME_PADDING := 4
const FRAME_COUNT := FRAME_GRID.x * FRAME_GRID.y

@export_range(1.0, 60.0, 1.0) var frame_rate := 12.0

var _frames: Array[AtlasTexture] = []
var _sprite_sheet: Texture2D
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
	# Replace the cached texture when the source PNG was updated while the
	# editor was already open. This keeps an embedded run from showing an older
	# preloaded spritesheet.
	_sprite_sheet = ResourceLoader.load(
		SPRITE_SHEET_PATH,
		"Texture2D",
		ResourceLoader.CACHE_MODE_REPLACE
	) as Texture2D
	if _sprite_sheet == null:
		return
	for index in range(FRAME_COUNT):
		var col := index % FRAME_GRID.x
		var row := floori(float(index) / float(FRAME_GRID.x))
		var pitch := FRAME_SIZE + Vector2.ONE * FRAME_PADDING * 2.0
		var atlas := AtlasTexture.new()
		atlas.atlas = _sprite_sheet
		atlas.region = Rect2(
			Vector2(float(col), float(row)) * pitch + Vector2.ONE * FRAME_PADDING,
			FRAME_SIZE
		)
		atlas.filter_clip = true
		_frames.append(atlas)


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
	# The root node remains the manually positioned/sized layout anchor. Every
	# atlas frame uses the exact same top-left origin with no centroid correction.
	texture = null
	_sync_visual_layout()


func _sync_visual_layout() -> void:
	if not is_instance_valid(_visual_rect):
		return
	_visual_rect.position = Vector2.ZERO
	_visual_rect.size = size


func _set_frame(index: int) -> void:
	if _frames.is_empty():
		return
	_frame_index = posmod(index, _frames.size())
	if is_instance_valid(_visual_rect):
		_visual_rect.texture = _frames[_frame_index]
