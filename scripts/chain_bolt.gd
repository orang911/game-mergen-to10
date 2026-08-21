@tool
extends Control
class_name ChainBolt

const RuntimeAtlasScript := preload("res://scripts/runtime_atlas.gd")
static var FRAME_TEXTURES: Array[Texture2D] = RuntimeAtlasScript.load_grid(
	"res://assets/runtime/fx/elements/lightning/atlases/beam_sheet.png",
	Vector2(258.0, 516.0),
	3,
	3
)
const FRAME_SEQUENCE := [0, 1, 2, 0, 1, 2]
const PLAY_DURATION := 0.4
const FRAME_DURATION := PLAY_DURATION / 6.0
const BEAM_WIDTH := 120.0
const ENDPOINT_PADDING := 32.0
const MIN_BEAM_LENGTH := 96.0

var start_pos := Vector2.ZERO:
	set(value):
		start_pos = value
		_layout_beam()

var end_pos := Vector2.ZERO:
	set(value):
		end_pos = value
		_layout_beam()

# Visual metadata only. Lightning uses the supplied sequence; the old drawn
# line remains as a fallback if another element reuses this class later.
var element: int = -1
var tier := 1
var chain_color := Color(0.95, 0.85, 0.15, 0.65)
var chain_core_color := Color(1.0, 0.98, 0.7, 0.85)

var _source_target: Control
var _target_target: Control
var _beam: TextureRect
var _elapsed := 0.0
var _display_step := -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ensure_beam()
	_apply_element_visuals()
	_sync_followed_endpoints()
	_show_step(0)
	_layout_beam()
	if Engine.is_editor_hint():
		start_pos = Vector2(80.0, 260.0)
		end_pos = Vector2(360.0, 100.0)
		set_process(false)


func _process(delta: float) -> void:
	_sync_followed_endpoints()
	_elapsed += delta
	var step := mini(FRAME_SEQUENCE.size() - 1, floori(_elapsed / FRAME_DURATION))
	_show_step(step)
	if _elapsed >= PLAY_DURATION:
		queue_free()


func apply_event(event: MergeAttackEvent) -> void:
	element = event.element
	tier = event.element_tier
	_apply_element_visuals()
	queue_redraw()


func bind_targets(source_target: Control, target_target: Control) -> void:
	_source_target = source_target
	_target_target = target_target
	_sync_followed_endpoints()


func _ensure_beam() -> void:
	if _beam != null and is_instance_valid(_beam):
		return
	_beam = TextureRect.new()
	_beam.name = "LightningSequence"
	_beam.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_beam.stretch_mode = TextureRect.STRETCH_SCALE
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_beam)


func _uses_lightning_sequence() -> bool:
	return element < 0 or element == GameConfig.AttackElement.LIGHTNING


func _show_step(step: int) -> void:
	if step == _display_step:
		return
	_display_step = step
	_ensure_beam()
	_beam.visible = _uses_lightning_sequence()
	if _beam.visible:
		_beam.texture = FRAME_TEXTURES[FRAME_SEQUENCE[step]]
	queue_redraw()


func _sync_followed_endpoints() -> void:
	if get_parent() == null:
		return
	if _source_target != null and is_instance_valid(_source_target):
		start_pos = _global_to_parent_local(_control_center_global(_source_target))
	if _target_target != null and is_instance_valid(_target_target):
		end_pos = _global_to_parent_local(_control_center_global(_target_target))


func _control_center_global(target: Control) -> Vector2:
	return target.global_position + target.size * 0.5


func _global_to_parent_local(global_pos: Vector2) -> Vector2:
	var parent_canvas := get_parent() as CanvasItem
	if parent_canvas == null:
		return global_pos
	return parent_canvas.get_global_transform_with_canvas().affine_inverse() * global_pos


func _layout_beam() -> void:
	if _beam == null or not is_instance_valid(_beam):
		return
	var connection := end_pos - start_pos
	var distance := connection.length()
	var beam_length := maxf(MIN_BEAM_LENGTH, distance + ENDPOINT_PADDING * 2.0)
	var beam_size := Vector2(BEAM_WIDTH, beam_length)
	var midpoint := (start_pos + end_pos) * 0.5
	_beam.size = beam_size
	_beam.pivot_offset = beam_size * 0.5
	_beam.position = midpoint - beam_size * 0.5
	_beam.rotation = connection.angle() - PI * 0.5 if distance > 0.001 else 0.0


func _apply_element_visuals() -> void:
	match element:
		GameConfig.AttackElement.POISON:
			chain_color = Color(0.2, 0.75, 0.2, 0.55); chain_core_color = Color(0.5, 0.95, 0.4, 0.8)
		GameConfig.AttackElement.FREEZE:
			chain_color = Color(0.35, 0.7, 1.0, 0.55); chain_core_color = Color(0.75, 0.9, 1.0, 0.8)
		GameConfig.AttackElement.CRITICAL:
			chain_color = Color(0.55, 0.2, 0.85, 0.55); chain_core_color = Color(0.8, 0.5, 1.0, 0.8)
		GameConfig.AttackElement.FIRE:
			chain_color = Color(0.9, 0.35, 0.1, 0.55); chain_core_color = Color(1.0, 0.6, 0.2, 0.8)
		_:
			chain_color = Color(0.95, 0.85, 0.15, 0.65); chain_core_color = Color(1.0, 0.98, 0.7, 0.85)
	if _beam != null and is_instance_valid(_beam):
		_beam.visible = _uses_lightning_sequence()


func _draw() -> void:
	if _uses_lightning_sequence():
		return
	var mid := (start_pos + end_pos) * 0.5
	var perp := (end_pos - start_pos).orthogonal().normalized() * 18.0
	var pts := PackedVector2Array([start_pos, mid - perp, mid + perp, end_pos])
	draw_polyline(pts, chain_color, 4.0, true)
	draw_polyline(pts, chain_core_color, 1.5, true)
