@tool
extends Control
class_name MergeBolt


var start_pos := Vector2.ZERO:
	set(value):
		start_pos = value
		_sync_visuals()

var end_pos := Vector2.ZERO:
	set(value):
		end_pos = value
		_sync_visuals()

var progress := 0.0:
	set(value):
		progress = value
		_sync_visuals()
		queue_redraw()

# Visual params set by projectile_system, never contains damage/logic.
var element: int = -1
var element_key := "poison"
var tier := 1
var projectile_color := Color(0.7, 0.92, 1.0, 0.9)
var trail_color := Color(0.35, 0.75, 1.0, 0.55)

var _trail_glow_rect: TextureRect
var _trail_rect: TextureRect
var _core_rect: TextureRect
var _core_size := Vector2(50.0, 50.0)
var _trail_size := Vector2(110.0, 28.0)
var _trail_offset := Vector2(-48.0, 0.0)
var _rotate_to_velocity := true


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ensure_visual_nodes()
	_apply_element_visuals()
	if Engine.is_editor_hint():
		start_pos = Vector2(40, 80)
		end_pos = Vector2(180, 60)
		progress = 0.5
	_sync_visuals()


func apply_event(event: MergeAttackEvent) -> void:
	element = event.element
	apply_element_key(event.element_key, event.element_tier)


func apply_element_key(key: String, tier_value: int = 1) -> void:
	element_key = key
	tier = tier_value
	_apply_element_visuals()
	_sync_visuals()


func _ensure_visual_nodes() -> void:
	if _trail_glow_rect == null or not is_instance_valid(_trail_glow_rect):
		_trail_glow_rect = TextureRect.new()
		_trail_glow_rect.name = "TrailGlow"
		_trail_glow_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_trail_glow_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_trail_glow_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_trail_glow_rect)

	if _trail_rect == null or not is_instance_valid(_trail_rect):
		_trail_rect = TextureRect.new()
		_trail_rect.name = "Trail"
		_trail_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_trail_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_trail_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_trail_rect)

	if _core_rect == null or not is_instance_valid(_core_rect):
		_core_rect = TextureRect.new()
		_core_rect.name = "Core"
		_core_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_core_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_core_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_core_rect)


func _apply_element_visuals() -> void:
	_ensure_visual_nodes()
	var fx: Dictionary = GameConfig.get_element_fx(element_key)
	_core_size = fx.get("core_size", Vector2(50.0, 50.0)) as Vector2
	_trail_size = fx.get("trail_size", Vector2(110.0, 28.0)) as Vector2
	_trail_offset = fx.get("trail_offset", Vector2(-48.0, 0.0)) as Vector2
	_rotate_to_velocity = bool(fx.get("rotate_to_velocity", true))
	trail_color = fx.get("trail_color", Color(0.35, 0.75, 1.0, 0.55)) as Color

	_core_rect.texture = _load_texture(str(fx.get("projectile", "")))
	_core_rect.size = _core_size
	_core_rect.pivot_offset = _core_size * 0.5

	_trail_rect.texture = _load_texture(str(fx.get("trail", "")))
	_trail_rect.size = _trail_size
	_trail_rect.pivot_offset = _trail_size * 0.5
	_trail_rect.modulate = trail_color

	var glow_size := _trail_size * 1.15
	_trail_glow_rect.texture = _load_texture(str(fx.get("trail", "")))
	_trail_glow_rect.size = glow_size
	_trail_glow_rect.pivot_offset = glow_size * 0.5
	_trail_glow_rect.modulate = Color(trail_color.r, trail_color.g, trail_color.b, 0.28)

	match element_key:
		"poison":
			projectile_color = Color(0.35, 0.9, 0.3, 0.9)
		"ice":
			projectile_color = Color(0.7, 0.85, 1.0, 0.9)
		"lightning":
			projectile_color = Color(1.0, 0.95, 0.25, 0.9)
		"critical":
			projectile_color = Color(0.75, 0.4, 0.95, 0.9)
		"fire":
			projectile_color = Color(1.0, 0.45, 0.15, 0.9)
		_:
			projectile_color = Color(0.7, 0.92, 1.0, 0.9)


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	return load(path) as Texture2D


func _sync_visuals() -> void:
	if _core_rect == null or _trail_rect == null:
		return
	var head := start_pos.lerp(end_pos, progress)
	var velocity := end_pos - start_pos
	var angle := velocity.angle() if velocity.length_squared() > 0.001 else 0.0
	var trail_center := head + _trail_offset.rotated(angle)

	_trail_glow_rect.position = trail_center - _trail_glow_rect.size * 0.5
	_trail_glow_rect.rotation = angle if _rotate_to_velocity else 0.0

	_trail_rect.position = trail_center - _trail_size * 0.5
	_trail_rect.rotation = angle if _rotate_to_velocity else 0.0

	_core_rect.size = _core_size
	_core_rect.pivot_offset = _core_size * 0.5
	_core_rect.position = head - _core_size * 0.5
	_core_rect.rotation = angle if _rotate_to_velocity else 0.0


func _draw() -> void:
	if _core_rect != null and is_instance_valid(_core_rect) and _core_rect.texture != null:
		return
	var head := start_pos.lerp(end_pos, progress)
	draw_line(start_pos, head, trail_color, 10.0, true)
	draw_line(start_pos, head, projectile_color, 4.0, true)
	draw_circle(head, 8.0, projectile_color)
