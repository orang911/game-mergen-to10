@tool
extends Control
class_name CrystalView

const ATTACK_INTERVAL := CrystalSystem.ATTACK_INTERVAL
const PANEL_DISPLAY_SCALE := Vector2(0.5, 0.5)
const FIXED_TOWER_SIZE_START_LEVEL := 6
const HIGH_LEVEL_UPGRADE_PULSE := 1.06
const HIGH_LEVEL_REWARD_PULSE := 1.08
const DORMANT_TEXTURE := preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv01.png")
const DORMANT_MODULATE := Color(0.42, 0.48, 0.58, 1.0)
const TOWER_CANVAS_SIZE := Vector2(512.0, 512.0)
const TOWER_SOURCE_BASELINE := Vector2(256.0, 477.0)
const TOWER_RENDER_BASELINE := Vector2(90.0, 204.48)
# Charged-shot overlay. When the artist's PNG is available at this path the
# feedback layer uses it (RGBA kept); otherwise a procedural cyan glow is drawn.
const CHARGE_FEEDBACK_PATH := "res://assets/runtime/fx/crystal_tower/charge_overlay.png"
const UPGRADE_SHOWCASE_SCENE_PATH := "res://scenes/tools/crystal_tower_upgrade_showcase.tscn"
const CHARGE_FEEDBACK_MAX_ALPHA := 0.72
const CHARGE_FEEDBACK_FADE_DURATION := 0.16

const TOWER_VISUALS := {
	# All source art is 512×512. Every scale is uniform; levels 6–9 retain the
	# level-five footprint so the tower remains readable over the board.
	# bounds are authored source-pixel alpha bounds for projectile and tip anchors.
	1: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv01.png"), "scale": 0.530, "bounds": Rect2(127, 235, 258, 242)},
	2: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv02.png"), "scale": 0.443, "bounds": Rect2(121, 183, 270, 294)},
	3: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv03.png"), "scale": 0.381, "bounds": Rect2(107, 115, 298, 362)},
	4: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv04.png"), "scale": 0.472, "bounds": Rect2(103, 125, 306, 352)},
	5: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv05.png"), "scale": 0.476, "bounds": Rect2(102, 121, 307, 356)},
	6: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv06.png"), "scale": 0.481, "bounds": Rect2(104, 126, 304, 351)},
	7: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv07.png"), "scale": 0.442, "bounds": Rect2(95, 95, 322, 382)},
	8: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv08.png"), "scale": 0.429, "bounds": Rect2(89, 83, 334, 394)},
	9: {"texture": preload("res://assets/runtime/ui/components/crystal_tower/textures/crystal_tower_lv09.png"), "scale": 0.415, "bounds": Rect2(71, 70, 370, 407)},
}

@onready var _tower := get_node_or_null("Tower") as TextureRect
@onready var _atk_panel := get_node_or_null("AtkPanel") as Control
@onready var _lv_label := get_node_or_null("AtkPanel/AtkLabelLv") as Label
@onready var _atk_label := get_node_or_null("AtkPanel/AtkLabelVal") as Label
@onready var _spd_label := get_node_or_null("AtkPanel/AtkLabelSpd") as Label
@onready var _shield := get_node_or_null("ShieldBadge") as TextureRect
@onready var _shield_label := get_node_or_null("ShieldLabel") as Label
@onready var _durability_label := get_node_or_null("DurabilityLabel") as Label
@onready var _durability_back := get_node_or_null("DurabilityBack") as ColorRect
@onready var _durability_fill := get_node_or_null("DurabilityBack/DurabilityFill") as ColorRect

var _crystal_level := 1
var _panel_visible := false
var _upgrade_tween: Tween
var _attack_tween: Tween
var _panel_tween: Tween
var _damage_tween: Tween
var _durability_current := GameConfig.MAX_CASTLE_DURABILITY
var _durability_max := GameConfig.MAX_CASTLE_DURABILITY
var _awakened := true
var _charge_feedback: Control
var _charge_feedback_tween: Tween
# Normalized to the authored level-one texture canvas in the upgrade showcase.
# The showcase is the art source of truth; the old percentage calculation below
# remains a safe fallback if the scene is unavailable or malformed.
var _showcase_charge_feedback_normalized := Rect2(-1.0, -1.0, 0.0, 0.0)
var _showcase_beam_origin_normalized := Vector2(-1.0, -1.0)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_children_ignore()
	_load_showcase_effect_layout()
	_update_display()
	update_durability(_durability_current, _durability_max)
	_hide_panel_immediate()


func _set_children_ignore() -> void:
	for child in get_children():
		if child is Control:
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_crystal_level(level: int) -> void:
	if level <= _crystal_level:
		return
	var old_level := _crystal_level
	_crystal_level = level
	_update_display()
	_play_upgrade_animation(old_level)


func get_crystal_level() -> int:
	return _crystal_level


func set_awakened(awakened: bool, animate: bool = false) -> void:
	var was_awakened := _awakened
	_awakened = awakened
	if not _awakened:
		_hide_panel_immediate()
	_update_display()
	if animate and not was_awakened and _awakened:
		_play_awakening_animation()


func is_awakened() -> bool:
	return _awakened


func get_attack_origin_global() -> Vector2:
	if _tower and is_instance_valid(_tower):
		return get_global_transform_with_canvas() * _get_tower_visual_rect().get_center()
	return get_global_transform_with_canvas() * (size * 0.5)


func get_crystal_top_global() -> Vector2:
	# The beam's origin is authored independently from the glow rectangle. In the
	# showcase, BeamPreview's lower-center point is the point touching the gem;
	# this lets art move the firing point without changing the charge overlay.
	if _crystal_level == 1 and _showcase_beam_origin_normalized.x >= 0.0:
		var canvas_rect := _get_tower_canvas_visual_rect()
		var origin := canvas_rect.position + canvas_rect.size * _showcase_beam_origin_normalized
		return get_global_transform_with_canvas() * origin
	var rect := _get_crystal_feedback_rect()
	return get_global_transform_with_canvas() * Vector2(rect.get_center().x, rect.position.y)


func update_durability(current: int, max_value: int) -> void:
	_durability_current = maxi(0, current)
	_durability_max = maxi(1, max_value)
	var ratio := clampf(float(_durability_current) / float(_durability_max), 0.0, 1.0)
	if _durability_label:
		_durability_label.position = Vector2(24.0, 208.0)
		_durability_label.size = Vector2(132.0, 25.0)
		_durability_label.text = "%d/%d" % [_durability_current, _durability_max]
		var label_color := Color(0.08, 0.27, 0.65, 1.0) if ratio > 0.5 else (Color(0.95, 0.56, 0.1, 1.0) if ratio > 0.25 else Color(0.9, 0.15, 0.15, 1.0))
		_durability_label.add_theme_color_override("font_color", label_color)
	if _durability_back:
		_durability_back.position = Vector2(46.0, 234.0)
		_durability_back.size = Vector2(88.0, 7.0)
	if _durability_fill:
		_durability_fill.position = Vector2(2.0, 2.0)
		_durability_fill.size = Vector2(84.0 * ratio, 3.0)
		_durability_fill.color = Color(0.28, 0.76, 0.38, 1.0) if ratio > 0.5 else (Color(0.96, 0.68, 0.18, 1.0) if ratio > 0.25 else Color(0.92, 0.18, 0.18, 1.0))


func play_damage(_amount: int) -> void:
	if not is_inside_tree() or _tower == null:
		return
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	var base_position := _tower.position
	_tower.modulate = Color(1.65, 0.30, 0.30, 1.0)
	_damage_tween = create_tween()
	_damage_tween.tween_property(_tower, "position", base_position + Vector2(5.0, 0.0), 0.035)
	_damage_tween.tween_property(_tower, "position", base_position + Vector2(-5.0, 0.0), 0.055)
	_damage_tween.tween_property(_tower, "position", base_position, 0.055)
	_damage_tween.parallel().tween_property(_tower, "modulate", Color.WHITE, 0.14)
	_damage_tween.tween_callback(_update_display)


func reset() -> void:
	_kill_all_tweens()
	cancel_charge_feedback()
	_crystal_level = 1
	_awakened = true
	_hide_panel_immediate()
	if _tower:
		_tower.modulate = Color.WHITE
	_update_display()
	update_durability(_durability_current, _durability_max)


func hide_attack_tip() -> void:
	_hide_panel()


func _kill_all_tweens() -> void:
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	if _damage_tween and _damage_tween.is_valid():
		_damage_tween.kill()
	if _charge_feedback_tween and _charge_feedback_tween.is_valid():
		_charge_feedback_tween.kill()
	_upgrade_tween = null
	_attack_tween = null
	_panel_tween = null
	_damage_tween = null
	_charge_feedback_tween = null


func _hide_panel_immediate() -> void:
	_panel_visible = false
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()
	_panel_tween = null
	if _atk_panel:
		_atk_panel.scale = Vector2.ZERO
		_atk_panel.visible = false
	if _lv_label:
		_lv_label.visible = false
	if _atk_label:
		_atk_label.visible = false
	if _spd_label:
		_spd_label.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not is_visible_in_tree() or not _awakened:
		return
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if not is_instance_valid(_tower):
		return
	var tower_local := _tower.get_global_transform_with_canvas().affine_inverse() * mb.position
	if not Rect2(Vector2.ZERO, _tower.size).has_point(tower_local):
		return

	if _panel_visible:
		_hide_panel()
	else:
		_show_panel()
	get_viewport().set_input_as_handled()


func _show_panel() -> void:
	if _panel_visible:
		return
	_panel_visible = true
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()

	if _atk_panel:
		_atk_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atk_panel.visible = true
		_atk_panel.scale = Vector2.ZERO
		_layout_attack_panel()
		_panel_tween = create_tween()
		_panel_tween.tween_property(_atk_panel, "scale", PANEL_DISPLAY_SCALE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _lv_label:
		_lv_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_lv_label.visible = true
	if _atk_label:
		_atk_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_atk_label.visible = true
	if _spd_label:
		_spd_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_spd_label.visible = true


func _hide_panel() -> void:
	if not _panel_visible:
		return
	_panel_visible = false
	if _panel_tween and _panel_tween.is_valid():
		_panel_tween.kill()

	if _atk_panel:
		_panel_tween = create_tween()
		_panel_tween.tween_property(_atk_panel, "scale", Vector2.ZERO, 0.12)
		_panel_tween.tween_callback(func():
			if is_instance_valid(_atk_panel):
				_atk_panel.visible = false
		)

	if _lv_label:
		_lv_label.visible = false
	if _atk_label:
		_atk_label.visible = false
	if _spd_label:
		_spd_label.visible = false


func _update_display() -> void:
	var label_str := GameConfig.get_level_label(_crystal_level)
	var atk := GameConfig.get_base_attack(_crystal_level)
	var spd := 1.0 / ATTACK_INTERVAL

	if _lv_label:
		_lv_label.text = "Lv " + label_str
	if _atk_label:
		_atk_label.text = "⚔ ATK: " + str(atk)
	if _spd_label:
		_spd_label.text = "◷ SPD: %.2f/s" % spd
	if _shield_label:
		_shield_label.text = label_str

	if _tower:
		var display_level := clampi(_crystal_level, 1, GameConfig.CRYSTAL_MAX_LEVEL)
		var data: Dictionary = TOWER_VISUALS[display_level]
		var tex: Texture2D = DORMANT_TEXTURE if not _awakened else data["texture"]
		if tex:
			_tower.texture = tex
			_tower.size = TOWER_CANVAS_SIZE
			_tower.pivot_offset = TOWER_SOURCE_BASELINE
			_tower.position = TOWER_RENDER_BASELINE - TOWER_SOURCE_BASELINE
			var display_scale := float(data["scale"])
			_tower.scale = Vector2.ONE * display_scale
			_tower.modulate = DORMANT_MODULATE if not _awakened else Color.WHITE
			_tower.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			_tower.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Position AtkPanel so its pivot_offset aligns with the Tower's visual right-center
	_layout_attack_panel()


func _play_awakening_animation() -> void:
	if _tower == null:
		return
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()
	var base_scale := _tower.scale
	_tower.modulate = Color(0.55, 1.2, 1.55, 1.0)
	_upgrade_tween = create_tween()
	_upgrade_tween.parallel().tween_property(_tower, "scale", base_scale * 1.22, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_upgrade_tween.parallel().tween_property(_tower, "modulate", Color(1.35, 1.55, 1.8, 1.0), 0.16)
	_upgrade_tween.tween_property(_tower, "scale", base_scale, 0.24).set_trans(Tween.TRANS_SINE)
	_upgrade_tween.parallel().tween_property(_tower, "modulate", Color.WHITE, 0.24)
	_spawn_awakening_fx()
	play_reward_absorb()


func _spawn_awakening_fx() -> void:
	if _tower == null:
		return
	var tower_rect := _get_tower_visual_rect()
	var tower_center := tower_rect.get_center()
	var tower_base_y := tower_rect.end.y
	var base_halo := Panel.new()
	base_halo.name = "AwakeningBaseHalo"
	base_halo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base_halo_style := StyleBoxFlat.new()
	base_halo_style.bg_color = Color(0.18, 0.90, 1.0, 0.32)
	base_halo_style.border_color = Color(0.70, 1.0, 1.0, 0.92)
	base_halo_style.set_border_width_all(3)
	base_halo_style.set_corner_radius_all(72)
	base_halo_style.shadow_color = Color(0.12, 0.86, 1.0, 0.88)
	base_halo_style.shadow_size = 24
	base_halo.add_theme_stylebox_override("panel", base_halo_style)
	base_halo.position = Vector2(tower_center.x - 86.0, tower_base_y - 29.0)
	base_halo.size = Vector2(172.0, 58.0)
	base_halo.pivot_offset = base_halo.size * 0.5
	base_halo.scale = Vector2(0.22, 0.22)
	base_halo.modulate.a = 0.0
	add_child(base_halo)
	move_child(base_halo, _tower.get_index())

	var column := Panel.new()
	column.name = "AwakeningLightColumn"
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column_style := StyleBoxFlat.new()
	column_style.bg_color = Color(0.30, 0.92, 1.0, 0.28)
	column_style.border_color = Color(0.72, 1.0, 1.0, 0.42)
	column_style.set_border_width_all(2)
	column_style.set_corner_radius_all(36)
	column.add_theme_stylebox_override("panel", column_style)
	column.position = Vector2(tower_center.x - 42.0, -92.0)
	column.size = Vector2(84.0, tower_base_y + 92.0)
	column.pivot_offset = Vector2(column.size.x * 0.5, column.size.y)
	column.scale = Vector2(0.20, 0.15)
	add_child(column)
	move_child(column, _tower.get_index())

	var ring := Panel.new()
	ring.name = "AwakeningEnergyRing"
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_style := StyleBoxFlat.new()
	ring_style.bg_color = Color(0.18, 0.78, 1.0, 0.05)
	ring_style.border_color = Color(0.45, 0.96, 1.0, 0.90)
	ring_style.set_border_width_all(5)
	ring_style.set_corner_radius_all(62)
	ring_style.shadow_color = Color(0.16, 0.82, 1.0, 0.65)
	ring_style.shadow_size = 12
	ring.add_theme_stylebox_override("panel", ring_style)
	ring.position = Vector2(tower_center.x - 65.0, tower_base_y - 59.0)
	ring.size = Vector2(130.0, 54.0)
	ring.pivot_offset = ring.size * 0.5
	ring.scale = Vector2(0.18, 0.18)
	add_child(ring)
	move_child(ring, _tower.get_index())

	var column_tween := create_tween()
	var base_halo_tween := create_tween()
	base_halo_tween.set_parallel(true)
	base_halo_tween.tween_property(base_halo, "scale", Vector2(1.18, 1.18), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	base_halo_tween.tween_property(base_halo, "modulate:a", 1.0, 0.10)
	base_halo_tween.set_parallel(false)
	base_halo_tween.tween_property(base_halo, "scale", Vector2(1.65, 1.65), 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	base_halo_tween.parallel().tween_property(base_halo, "modulate:a", 0.0, 0.34)
	base_halo_tween.tween_callback(base_halo.queue_free)
	column_tween.parallel().tween_property(column, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	column_tween.parallel().tween_property(column, "modulate:a", 0.82, 0.12)
	column_tween.tween_interval(0.18)
	column_tween.tween_property(column, "modulate:a", 0.0, 0.28)
	column_tween.tween_callback(column.queue_free)
	var ring_tween := create_tween()
	ring_tween.parallel().tween_property(ring, "scale", Vector2(1.45, 1.45), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	ring_tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.42)
	ring_tween.tween_callback(ring.queue_free)


func _layout_attack_panel() -> void:
	if not (_atk_panel and _tower):
		return
	var tower_rect := _get_tower_visual_rect()
	var target_local := Vector2(tower_rect.end.x + 7.0, tower_rect.get_center().y)
	_atk_panel.position = target_local - _atk_panel.pivot_offset


func _get_tower_visual_rect() -> Rect2:
	var display_level := clampi(_crystal_level, 1, GameConfig.CRYSTAL_MAX_LEVEL)
	var data: Dictionary = TOWER_VISUALS[display_level]
	var bounds := data.get("bounds", Rect2(Vector2.ZERO, TOWER_CANVAS_SIZE)) as Rect2
	# Tips and projectile origins use the stable authored scale. Upgrade pulses
	# are presentation-only and must not make their anchors drift frame to frame.
	var uniform_scale := float(data["scale"])
	var visual_position := TOWER_RENDER_BASELINE + (bounds.position - TOWER_SOURCE_BASELINE) * uniform_scale
	return Rect2(visual_position, bounds.size * uniform_scale)


func _get_tower_canvas_visual_rect() -> Rect2:
	# _tower is a 512×512 canvas whose pivot is the authored baseline.  This is
	# the same transform used by the TextureRect in the battle scene, so a rect
	# authored against the showcase texture can be mapped without guessing from
	# the alpha bounds of the stone base.
	var display_level := clampi(_crystal_level, 1, GameConfig.CRYSTAL_MAX_LEVEL)
	var data: Dictionary = TOWER_VISUALS[display_level]
	var uniform_scale := float(data["scale"])
	return Rect2(TOWER_RENDER_BASELINE - TOWER_SOURCE_BASELINE * uniform_scale, TOWER_CANVAS_SIZE * uniform_scale)


func _load_showcase_effect_layout() -> void:
	_showcase_charge_feedback_normalized = Rect2(-1.0, -1.0, 0.0, 0.0)
	_showcase_beam_origin_normalized = Vector2(-1.0, -1.0)
	if not ResourceLoader.exists(UPGRADE_SHOWCASE_SCENE_PATH):
		return
	var packed := load(UPGRADE_SHOWCASE_SCENE_PATH) as PackedScene
	if packed == null:
		return
	var showcase := packed.instantiate()
	var tower := showcase.get_node_or_null("Level01/PreviewFrame/Tower") as TextureRect
	var feedback := showcase.get_node_or_null("Level01/PreviewFrame/EffectLayer/ChargeFeedback") as Control
	var beam := showcase.get_node_or_null("Level01/PreviewFrame/EffectLayer/BeamPreview") as Control
	if tower == null or feedback == null or tower.texture == null:
		showcase.free()
		return
	var source_size := tower.texture.get_size()
	if source_size.x <= 0.0 or source_size.y <= 0.0 or tower.size.x <= 0.0 or tower.size.y <= 0.0:
		showcase.free()
		return
	# The showcase uses KEEP_ASPECT_CENTERED. Recreate the actual drawn square
	# inside its TextureRect before normalizing the editable effect rectangle.
	var fit_scale := minf(tower.size.x / source_size.x, tower.size.y / source_size.y)
	var drawn_size := source_size * fit_scale
	var drawn_position := tower.position + (tower.size - drawn_size) * 0.5
	var effect_rect := Rect2(feedback.position, feedback.size)
	_showcase_charge_feedback_normalized = Rect2(
		(effect_rect.position - drawn_position) / drawn_size,
		effect_rect.size / drawn_size
	)
	if beam:
		# The supplied beam art points toward the gem. Its lower-center point is
		# therefore the authored firing origin; the rest of the beam is visual
		# direction/length and is not used as a hitbox.
		var beam_rect := Rect2(beam.position, beam.size)
		var beam_origin := Vector2(beam_rect.get_center().x, beam_rect.end.y)
		_showcase_beam_origin_normalized = (beam_origin - drawn_position) / drawn_size
	showcase.free()


func _get_crystal_feedback_rect() -> Rect2:
	# The feedback sprite is a gem glow, not a second full-tower silhouette.
	# Keep its anchor centered on the crystal core for every tower level.
	var tower_rect := _get_tower_visual_rect()
	if _crystal_level == 1 and _showcase_charge_feedback_normalized.position.x >= 0.0:
		var canvas_rect := _get_tower_canvas_visual_rect()
		return Rect2(
			canvas_rect.position + canvas_rect.size * _showcase_charge_feedback_normalized.position,
			canvas_rect.size * _showcase_charge_feedback_normalized.size
		)
	# The lower stone ring belongs to the tower, not the crystal feedback. The
	# tighter frame leaves the glow on the blue gem and keeps the ring readable.
	# Match the authored blue gem bounds (rather than the much wider tower
	# silhouette): keep the base ring and lower stonework outside this rect.
	var feedback_size := Vector2(tower_rect.size.x * 0.34, tower_rect.size.y * 0.54)
	var feedback_center := Vector2(tower_rect.get_center().x, tower_rect.position.y + tower_rect.size.y * 0.30)
	return Rect2(feedback_center - feedback_size * 0.5, feedback_size)


func _play_upgrade_animation(_old_level: int) -> void:
	if _upgrade_tween and _upgrade_tween.is_valid():
		_upgrade_tween.kill()

	if _tower:
		var base := _tower.scale
		var pulse_multiplier := HIGH_LEVEL_UPGRADE_PULSE if _crystal_level >= FIXED_TOWER_SIZE_START_LEVEL else 1.12
		_upgrade_tween = create_tween()
		_upgrade_tween.tween_property(_tower, "scale", base * pulse_multiplier, 0.12)
		_upgrade_tween.tween_property(_tower, "scale", base, 0.18)

	if _shield:
		var base := _shield.scale
		var s := create_tween()
		s.tween_property(_shield, "scale", base * 1.15, 0.10)
		s.tween_property(_shield, "scale", base, 0.15)



func play_attack_flash() -> void:
	if _attack_tween and _attack_tween.is_valid():
		_attack_tween.kill()
	if _tower:
		_tower.modulate = Color.WHITE
		var base := _tower.modulate
		_attack_tween = create_tween()
		_attack_tween.tween_property(_tower, "modulate", Color(1.4, 1.4, 1.8, 1.0), 0.08)
		_attack_tween.tween_property(_tower, "modulate", base, 0.12)


func play_charge_feedback(duration: float) -> void:
	if not is_inside_tree() or _tower == null:
		return
	_ensure_charge_feedback()
	if _charge_feedback_tween and _charge_feedback_tween.is_valid():
		_charge_feedback_tween.kill()
	# The charge image is intentionally scoped to the blue crystal only.  The
	# stone ring/base remains the authored tower art and must not glow with it.
	var rect := _get_crystal_feedback_rect()
	_charge_feedback.position = rect.position
	_charge_feedback.size = rect.size
	_charge_feedback.pivot_offset = rect.size * 0.5
	_charge_feedback.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_charge_feedback.visible = true
	_charge_feedback_tween = create_tween()
	_charge_feedback_tween.tween_property(_charge_feedback, "modulate:a", CHARGE_FEEDBACK_MAX_ALPHA, maxf(0.01, duration)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_charge_feedback_tween.tween_property(_charge_feedback, "modulate:a", 0.0, CHARGE_FEEDBACK_FADE_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_charge_feedback_tween.tween_callback(func():
		if is_instance_valid(_charge_feedback):
			_charge_feedback.visible = false
		_charge_feedback_tween = null
	)


func cancel_charge_feedback() -> void:
	if _charge_feedback_tween and _charge_feedback_tween.is_valid():
		_charge_feedback_tween.kill()
	_charge_feedback_tween = null
	if _charge_feedback and is_instance_valid(_charge_feedback):
		_charge_feedback.visible = false
		_charge_feedback.modulate.a = 0.0


func _ensure_charge_feedback() -> void:
	if _charge_feedback and is_instance_valid(_charge_feedback):
		return
	var texture: Texture2D = null
	# The production charge PNG is supplied separately by art. Avoid emitting a
	# ResourceLoader error while that file is absent; the visual fallback keeps
	# the timing/state path testable until the approved RGBA asset is copied in.
	if ResourceLoader.exists(CHARGE_FEEDBACK_PATH):
		texture = load(CHARGE_FEEDBACK_PATH) as Texture2D
	if texture:
		var rect := TextureRect.new()
		rect.name = "ChargeFeedback"
		rect.texture = texture
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_charge_feedback = rect
	else:
		# Procedural placeholder keeps the charged-shot readable without a fake
		# texture. It intentionally mirrors the crystal element color.
		var panel := Panel.new()
		panel.name = "ChargeFeedback"
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.32, 0.86, 1.0, 0.85)
		style.border_color = Color(0.68, 1.0, 1.0, 0.85)
		style.set_border_width_all(3)
		style.set_corner_radius_all(48)
		style.shadow_color = Color(0.18, 0.80, 1.0, 0.55)
		style.shadow_size = 18
		panel.add_theme_stylebox_override("panel", style)
		_charge_feedback = panel
	_charge_feedback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_charge_feedback.visible = false
	add_child(_charge_feedback)
	move_child(_charge_feedback, _tower.get_index() + 1)


func play_reward_absorb() -> void:
	play_attack_flash()
	if _tower:
		var tower_base := _tower.scale
		var pulse_multiplier := HIGH_LEVEL_REWARD_PULSE if _crystal_level >= FIXED_TOWER_SIZE_START_LEVEL else 1.16
		var tower_pulse := create_tween()
		tower_pulse.tween_property(_tower, "scale", tower_base * pulse_multiplier, 0.11).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tower_pulse.tween_property(_tower, "scale", tower_base, 0.20).set_trans(Tween.TRANS_SINE)
	if _shield:
		var shield_base := _shield.scale
		_shield.modulate = Color(0.55, 0.9, 1.35, 0.95)
		var ring := create_tween()
		ring.parallel().tween_property(_shield, "scale", shield_base * 1.32, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ring.parallel().tween_property(_shield, "modulate:a", 0.18, 0.18)
		ring.tween_property(_shield, "scale", shield_base, 0.12)
		ring.parallel().tween_property(_shield, "modulate", Color.WHITE, 0.12)
