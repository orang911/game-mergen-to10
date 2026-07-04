@tool
extends Control
class_name MonsterView

const SLICE_DIR := "res://assets/sliced_20260703_172750/"

var monster_type := "small"
var _color := Color.ORANGE
var _sides := 3
var _base_size := 60.0
var _hp_bar_height := 6.0
var _hp := 5.0
var _max_hp := 5.0
var _freeze_timer := 0.0
var _burn_timer := 0.0
var _poison_timer := 0.0
var _sprite: TextureRect
var _frames: Array[Texture2D] = []
var _frame_index := 0
var _anim_time := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	var demo: Dictionary = {"type": "small", "hp": 5, "scale": 0.75}
	configure(demo)
	size = Vector2(100, 100)
	custom_minimum_size = size


func configure(config: Dictionary) -> void:
	monster_type = config.get("type", "small")
	_max_hp = float(config.get("hp", 5))
	_hp = _max_hp
	var scale_val: float = config.get("scale", 1.0)

	match monster_type:
		"small":
			_sides = 32
			_color = Color(0.55, 0.83, 0.36, 1.0)
		"medium":
			_sides = 3
			_color = Color(0.25, 0.63, 1.0, 1.0)
		"large":
			_sides = 4
			_color = Color(0.94, 0.28, 0.24, 1.0)
		_:
			_sides = 4
			_color = Color(0.6, 0.6, 0.6, 1.0)

	_base_size = 80.0 * scale_val
	var total: float = _base_size + _hp_bar_height + 4.0
	custom_minimum_size = Vector2(total, total)
	size = Vector2(total, total)
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_setup_sprite()
	_layout_anchors()
	queue_redraw()


func update_hp(hp: float, _max: float) -> void:
	_hp = hp
	_max_hp = _max
	queue_redraw()


func update_status(freeze: float, burn: float, poison: float) -> void:
	_freeze_timer = freeze
	_burn_timer = burn
	_poison_timer = poison
	queue_redraw()

func _process(delta: float) -> void:
	if _frames.size() <= 1 or _sprite == null:
		return
	_anim_time += delta
	if _anim_time < 0.12:
		return
	_anim_time = 0.0
	_frame_index = (_frame_index + 1) % _frames.size()
	_sprite.texture = _frames[_frame_index]


func _draw() -> void:
	var cx: float = size.x * 0.5
	var cy: float = _base_size * 0.5
	var radius: float = _base_size * 0.48
	var points: PackedVector2Array
	if _sprite == null:
		for i in range(_sides):
			var angle: float = float(i) / float(_sides) * TAU - PI * 0.5
			if _sides == 4:
				angle += PI * 0.25
			points.append(Vector2(cx + radius * cos(angle), cy + radius * sin(angle)))

		var bg_color: Color = _color.darkened(0.3)
		draw_circle(Vector2(cx, cy + radius * 0.78), radius * 0.58, Color(0.2, 0.16, 0.08, 0.16))
		draw_colored_polygon(points, _color)
		var outline := PackedVector2Array(points)
		outline.append(points[0])
		draw_polyline(outline, bg_color, 2.0, true)
		draw_polyline(outline, Color(1, 1, 1, 0.35), 1.0, true)

		var eye_y := cy - radius * 0.08
		var eye_gap := radius * 0.34
		_draw_eye(Vector2(cx - eye_gap, eye_y), -1)
		_draw_eye(Vector2(cx + eye_gap, eye_y), 1)
		if monster_type == "large":
			draw_line(Vector2(cx - 18, cy + 16), Vector2(cx + 18, cy + 16), Color(0.25, 0.05, 0.04, 1.0), 3.0, true)
		else:
			draw_arc(Vector2(cx, cy + 11), 12, 0.1, PI - 0.1, 12, Color(0.1, 0.12, 0.08, 1.0), 2.4, true)

	_draw_status_indicators(cx, cy - radius * 0.7)

	var bar_y: float = _base_size + 4.0
	var bar_w: float = _base_size - 8.0
	var bar_x: float = (size.x - bar_w) * 0.5
	draw_rect(Rect2(bar_x, bar_y, bar_w, _hp_bar_height), Color(0.15, 0.15, 0.15, 0.8), true)
	if _max_hp > 0.0:
		var ratio: float = clampi(int((_hp / _max_hp) * 100.0), 0, 100) / 100.0
		var hp_color: Color = Color.GREEN if ratio > 0.5 else (Color.YELLOW if ratio > 0.25 else Color.RED)
		draw_rect(Rect2(bar_x + 1.0, bar_y + 1.0, (bar_w - 2.0) * ratio, _hp_bar_height - 2.0), hp_color, true)


func _draw_eye(center: Vector2, side: int) -> void:
	draw_circle(center, 7.0, Color.WHITE)
	draw_circle(center + Vector2(side * 2.0, 1.0), 3.5, Color(0.04, 0.05, 0.06, 1.0))
	var brow_start := center + Vector2(-8.0 * side, -11.0)
	var brow_end := center + Vector2(8.0 * side, -5.0)
	draw_line(brow_start, brow_end, Color(0.06, 0.05, 0.05, 1.0), 3.0, true)


func _draw_status_indicators(cx: float, top_y: float) -> void:
	var count := 0
	if _freeze_timer > 0.0:
		count += 1
	if _burn_timer > 0.0:
		count += 1
	if _poison_timer > 0.0:
		count += 1
	if count == 0:
		return
	var gap := 14.0
	var r := 5.0
	var total_w: float = gap * float(count - 1)
	var start_x: float = cx - total_w * 0.5
	var idx := 0
	if _freeze_timer > 0.0:
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color(0.35, 0.75, 1.0, 0.9))
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color.WHITE, false, 1.5)
		idx += 1
	if _burn_timer > 0.0:
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color(1.0, 0.45, 0.15, 0.9))
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color.WHITE, false, 1.5)
		idx += 1
	if _poison_timer > 0.0:
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color(0.35, 0.85, 0.25, 0.9))
		draw_circle(Vector2(start_x + gap * float(idx), top_y), r, Color.WHITE, false, 1.5)

func _setup_sprite() -> void:
	_clear_sprite()
	var prefix := _prefix_for_type(monster_type)
	for i in range(1, 4):
		var path := "%smonster_%s_walk_%02d.png" % [SLICE_DIR, prefix, i]
		if FileAccess.file_exists(path):
			_frames.append(load(path) as Texture2D)
	if _frames.is_empty():
		var idle_path := "%smonster_%s_idle.png" % [SLICE_DIR, prefix]
		if FileAccess.file_exists(idle_path):
			_frames.append(load(idle_path) as Texture2D)
	if _frames.is_empty():
		set_process(false)
		return

	_sprite = TextureRect.new()
	_sprite.name = "Sprite"
	_sprite.texture = _frames[0]
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sprite)
	var sprite_size := Vector2(_base_size, _base_size)
	_sprite.position = Vector2((size.x - sprite_size.x) * 0.5, 0)
	_sprite.size = sprite_size
	set_process(_frames.size() > 1)

func _layout_anchors() -> void:
	var hit_anchor := get_node_or_null("HitAnchor") as Control
	if hit_anchor:
		hit_anchor.position = Vector2(size.x * 0.5, _base_size * 0.48)
	var hp_anchor := get_node_or_null("HpAnchor") as Control
	if hp_anchor:
		hp_anchor.position = Vector2(size.x * 0.5, _base_size + 7.0)
	var effect_anchor := get_node_or_null("EffectAnchor") as Control
	if effect_anchor:
		effect_anchor.position = Vector2(size.x * 0.5, 6.0)

func _clear_sprite() -> void:
	_frames.clear()
	_frame_index = 0
	_anim_time = 0.0
	if _sprite and is_instance_valid(_sprite):
		_sprite.queue_free()
	_sprite = null

func _prefix_for_type(type_name: String) -> String:
	match type_name:
		"small":
			return "green"
		"medium":
			return "blue"
		"large":
			return "red"
		_:
			return "yellow"
