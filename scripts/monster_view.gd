@tool
extends Control
class_name MonsterView

const RuntimeAtlasScript := preload("res://scripts/runtime_atlas.gd")
const SLICE_DIR := "res://assets/runtime/characters/monsters/"
const ATLAS_DIR := "res://assets/runtime/characters/monsters/atlases/"
const SLIME_STAGE_01_WALK_SHEET := ATLAS_DIR + "slime_stage_01_walk_sheet.png"
const SLIME_STAGE_01_HIT_SHEET := ATLAS_DIR + "slime_stage_01_hit_sheet.png"
const DEATH_SHEET := ATLAS_DIR + "monster_death_sheet.png"
const TUTORIAL_ARMORED_WALK_SHEET := ATLAS_DIR + "tutorial_armored_walk_sheet.png"
const TUTORIAL_ARMORED_HIT_SHEET := ATLAS_DIR + "tutorial_armored_hit_sheet.png"
const ANIMATION_FRAME_SIZE := Vector2(320.0, 320.0)
const ANIMATION_FRAME_PADDING := 4
const MONSTER_STAGE_TEXTURES := {
	"slime": [
		preload("res://assets/runtime/characters/monsters/slime_stage_01.png"),
		preload("res://assets/runtime/characters/monsters/slime_stage_02.png"),
		preload("res://assets/runtime/characters/monsters/slime_stage_03.png"),
	],
	"goblin": [
		preload("res://assets/runtime/characters/monsters/goblin_stage_01.png"),
		preload("res://assets/runtime/characters/monsters/goblin_stage_02.png"),
		preload("res://assets/runtime/characters/monsters/goblin_stage_03.png"),
	],
	"zombie": [
		preload("res://assets/runtime/characters/monsters/zombie_stage_01.png"),
		preload("res://assets/runtime/characters/monsters/zombie_stage_02.png"),
		preload("res://assets/runtime/characters/monsters/zombie_stage_03.png"),
	],
}
const DEATH_FRAME_COUNT := 19
const DEATH_FRAME_DURATION := 1.0 / 24.0
const SLIME_STAGE_01_WALK_FRAME_COUNT := 18
const SLIME_STAGE_01_HIT_FRAME_COUNT := 8
const TUTORIAL_ARMORED_WALK_FRAME_COUNT := 28
const TUTORIAL_ARMORED_HIT_FRAME_COUNT := 5
const WALK_FRAME_DURATION := 1.0 / 24.0
const HIT_FRAME_DURATION := 1.0 / 24.0
const LIGHTNING_FLASH_INTERVAL := 0.065
const LIGHTNING_SHAKE_X := 4.8
const LIGHTNING_SHAKE_Y := 3.2
const LIGHTNING_LIFT := 9.0
const ELEMENT_RECOIL_DISTANCE := 9.0
const ELEMENT_RECOIL_OUT_DURATION := 0.055
const ELEMENT_RECOIL_RETURN_DURATION := 0.13
const MAX_ELEMENT_STACKS := 4
const LIGHTNING_FLASH_SHADER_CODE := """
shader_type canvas_item;

uniform float lightning_amount : hint_range(0.0, 1.0) = 0.0;
uniform float lightning_white : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 black_phase = vec3(luminance * 0.055);
	vec3 white_phase = mix(vec3(luminance), vec3(1.0), 0.88);
	vec3 lightning_color = mix(black_phase, white_phase, lightning_white);
	source.rgb = mix(source.rgb, lightning_color, lightning_amount);
	COLOR = source;
}
"""

var monster_type := "small"
var visual_tier := 1
var appearance_id := ""
var is_boss := false
var _color := Color.ORANGE
var _sides := 3
var _base_size := 60.0
var _hp_bar_height := 6.0
var _hp := 5.0
var _max_hp := 5.0
var _freeze_timer := 0.0
var _burn_timer := 0.0
var _poison_timer := 0.0
var _burn_stack_count := 0
var _poison_stack_count := 0
var _sprite: TextureRect
var _frames: Array[Texture2D] = []
var _hit_frames: Array[Texture2D] = []
var _death_frames: Array[Texture2D] = []
var _frame_index := 0
var _anim_time := 0.0
var _walk_frame_time := 0.0
var _hit_frame_index := 0
var _hit_anim_time := 0.0
var _hit_playing := false
var _death_frame_index := 0
var _death_anim_time := 0.0
var _death_playing := false
var _death_frame_duration := DEATH_FRAME_DURATION
var _sprite_base_position := Vector2.ZERO
var _tutorial_bob := false
var _stage_art_loaded := false
var _authored_walk_animation := false
var _stun_layer: Control
var _stun_tween: Tween
var _lightning_stun_timer := 0.0
var _lightning_flash_elapsed := 0.0
var _lightning_flash_white := true
var _lightning_flash_material: ShaderMaterial
var _poison_flash_timer := 0.0
var _recoil_direction := Vector2.ZERO
var _recoil_elapsed := 0.0
var _recoil_active := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	var demo: Dictionary = {"type": "small", "hp": 5, "scale": 0.75}
	configure(demo)
	size = Vector2(100, 100)
	custom_minimum_size = size


func configure(config: Dictionary) -> void:
	monster_type = config.get("type", "small")
	visual_tier = clampi(int(config.get("visual_tier", 1)), 1, 3)
	appearance_id = str(config.get("appearance_id", ""))
	is_boss = bool(config.get("is_boss", false))
	_max_hp = float(config.get("hp", 5))
	_hp = _max_hp
	var scale_val: float = config.get("scale", 1.0)
	_tutorial_bob = bool(config.get("tutorial_bob", false))

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
	_setup_lightning_flash_material()
	_layout_anchors()
	queue_redraw()


func update_hp(hp: float, _max: float) -> void:
	_hp = hp
	_max_hp = _max
	queue_redraw()


func update_status(
	freeze: float,
	burn: float,
	poison: float,
	lightning_stun: float = 0.0,
	poison_stacks: int = 0,
	burn_stacks: int = 0
) -> void:
	var lightning_restarted := lightning_stun > _lightning_stun_timer + 0.025
	_freeze_timer = freeze
	_burn_timer = burn
	_poison_timer = poison
	_poison_stack_count = clampi(poison_stacks, 0, MAX_ELEMENT_STACKS)
	_burn_stack_count = clampi(burn_stacks, 0, MAX_ELEMENT_STACKS)
	_lightning_stun_timer = lightning_stun
	if lightning_restarted:
		_lightning_flash_elapsed = 0.0
		_lightning_flash_white = true
	if _lightning_stun_timer > 0.0:
		set_process(true)
		_set_lightning_flash(true, _lightning_flash_white)
	else:
		_set_lightning_flash(false, true)
	_apply_element_tint()
	queue_redraw()


func play_poison_tick_feedback() -> void:
	play_damage_feedback()


func play_damage_feedback() -> void:
	_poison_flash_timer = 0.14
	_apply_element_tint()
	# Explicit goblin/tutorial art may otherwise have processing disabled.
	# Keep processing alive long enough to restore the original/frozen tint.
	set_process(true)

func _process(delta: float) -> void:
	if _death_playing:
		if _sprite == null:
			return
		_death_anim_time += delta
		while _death_anim_time >= _death_frame_duration and _death_frame_index < _death_frames.size() - 1:
			_death_anim_time -= _death_frame_duration
			_death_frame_index += 1
			_sprite.texture = _death_frames[_death_frame_index]
		return
	if _poison_flash_timer > 0.0:
		_poison_flash_timer = maxf(0.0, _poison_flash_timer - delta)
		_apply_element_tint()
	var lightning_offset := Vector2.ZERO
	if _lightning_stun_timer > 0.0:
		_lightning_flash_elapsed += delta
		var flash_phase := floori(_lightning_flash_elapsed / LIGHTNING_FLASH_INTERVAL)
		var next_white := flash_phase % 2 == 0
		if next_white != _lightning_flash_white:
			_lightning_flash_white = next_white
			_set_lightning_flash(true, _lightning_flash_white)
		var shake_x := sin(_lightning_flash_elapsed * 91.0) * LIGHTNING_SHAKE_X
		shake_x += cos(_lightning_flash_elapsed * 137.0) * 1.4
		var shake_y := sin(_lightning_flash_elapsed * 117.0) * LIGHTNING_SHAKE_Y
		lightning_offset = Vector2(shake_x, -LIGHTNING_LIFT + shake_y)
		rotation = sin(_lightning_flash_elapsed * 103.0) * 0.035
	else:
		_set_lightning_flash(false, true)
		rotation = lerpf(rotation, 0.0, minf(1.0, delta * 22.0))
	var recoil_offset := _advance_element_recoil(delta)
	if _lightning_stun_timer > 0.0 or _recoil_active or recoil_offset.length_squared() > 0.001:
		position = lightning_offset + recoil_offset
	else:
		position = position.lerp(Vector2.ZERO, minf(1.0, delta * 18.0))
	if _hit_playing:
		_hit_anim_time += delta
		while _hit_anim_time >= HIT_FRAME_DURATION and _hit_playing:
			_hit_anim_time -= HIT_FRAME_DURATION
			_hit_frame_index += 1
			if _hit_frame_index >= _hit_frames.size():
				_hit_playing = false
				_hit_frame_index = 0
				_hit_anim_time = 0.0
				if not _frames.is_empty():
					_sprite.texture = _frames[_frame_index % _frames.size()]
				break
			_sprite.texture = _hit_frames[_hit_frame_index]
		if _hit_playing:
			return
	_anim_time += delta
	if _sprite and not _authored_walk_animation and (_tutorial_bob or _stage_art_loaded):
		var bob_amount := 2.5 if _tutorial_bob else 1.5
		_sprite.position = _sprite_base_position + Vector2(0.0, sin(_anim_time * 5.0) * bob_amount)
	if _lightning_stun_timer > 0.0:
		return
	if _sprite == null or _frames.size() <= 1:
		return
	_walk_frame_time += delta
	while _walk_frame_time >= WALK_FRAME_DURATION:
		_walk_frame_time -= WALK_FRAME_DURATION
		_frame_index = (_frame_index + 1) % _frames.size()
	_sprite.texture = _frames[_frame_index]


func _draw() -> void:
	var cx: float = size.x * 0.5
	var cy: float = _base_size * 0.5
	var radius: float = _base_size * 0.48
	_draw_status_indicators(cx, cy - radius * 0.7)
	if is_boss:
		var badge_center := Vector2(cx, 4.0)
		draw_circle(badge_center, 11.0, Color(0.92, 0.25, 0.22, 1.0))
		draw_circle(badge_center, 11.0, Color(1.0, 0.86, 0.35, 1.0), false, 2.0)
		draw_string(ThemeDB.fallback_font, badge_center + Vector2(-4.0, 5.0), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)

	if not _death_playing:
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
	var indicators: Array[Dictionary] = []
	if _freeze_timer > 0.0:
		indicators.append({"color": Color(0.35, 0.75, 1.0, 0.95), "stacks": 0})
	if _burn_timer > 0.0:
		indicators.append({"color": Color(1.0, 0.42, 0.10, 0.98), "stacks": maxi(1, _burn_stack_count)})
	if _poison_timer > 0.0:
		indicators.append({"color": Color(0.32, 0.84, 0.22, 0.98), "stacks": maxi(1, _poison_stack_count)})
	if indicators.is_empty():
		return
	var gap := 19.0
	var radius := 7.0
	var total_w: float = gap * float(indicators.size() - 1)
	var start_x: float = cx - total_w * 0.5
	for index in range(indicators.size()):
		var indicator := indicators[index]
		var center := Vector2(start_x + gap * float(index), top_y)
		draw_circle(center, radius, indicator["color"] as Color)
		draw_circle(center, radius, Color(0.08, 0.10, 0.14, 0.9), false, 2.0)
		var stacks := int(indicator["stacks"])
		if stacks > 0:
			var text_position := center + Vector2(-radius, 4.0)
			draw_string(
				ThemeDB.fallback_font,
				text_position + Vector2(1.0, 1.0),
				str(stacks),
				HORIZONTAL_ALIGNMENT_CENTER,
				radius * 2.0,
				11,
				Color(0.05, 0.05, 0.06, 0.95)
			)
			draw_string(
				ThemeDB.fallback_font,
				text_position,
				str(stacks),
				HORIZONTAL_ALIGNMENT_CENTER,
				radius * 2.0,
				11,
				Color.WHITE
			)

func _setup_sprite() -> void:
	_clear_sprite()
	var explicit_texture: Texture2D
	if appearance_id == "mini_boss":
		explicit_texture = _stage_texture("goblin", 3)
	elif appearance_id == "chapter_boss":
		explicit_texture = _stage_texture("zombie", 3)
	elif monster_type == "tutorial_armored":
		_load_tutorial_armored_animation()
	if explicit_texture:
		_frames.append(explicit_texture)
	if _frames.is_empty() and _uses_stage_one_slime_animation():
		_append_atlas_frames(_frames, SLIME_STAGE_01_WALK_SHEET, SLIME_STAGE_01_WALK_FRAME_COUNT, 6)
		if not _frames.is_empty():
			_stage_art_loaded = true
			_authored_walk_animation = true
			_append_atlas_frames(_hit_frames, SLIME_STAGE_01_HIT_SHEET, SLIME_STAGE_01_HIT_FRAME_COUNT, 4)
	var stage_art: Texture2D = null
	if monster_type in ["small", "medium", "large"]:
		stage_art = _stage_texture("slime", visual_tier)
	if _frames.is_empty() and stage_art:
		_frames.append(stage_art)
		_stage_art_loaded = true
	if _frames.is_empty():
		var fallback := _stage_texture("goblin" if monster_type == "tutorial_armored" else "slime", visual_tier)
		if fallback:
			_frames.append(fallback)
			_stage_art_loaded = true
	if _frames.is_empty():
		push_error("No authored monster texture available for type=%s appearance=%s tier=%d" % [monster_type, appearance_id, visual_tier])
		set_process(false)
		return

	_sprite = TextureRect.new()
	_sprite.name = "Sprite"
	_sprite.texture = _frames[0]
	_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Authored monster art stays behind the procedural HP/status overlay so
	# poison/fire stack counts remain readable on opaque body frames.
	_sprite.z_index = -1
	add_child(_sprite)
	var art_zoom := _stage_art_zoom(monster_type, visual_tier) if _stage_art_loaded else 1.0
	var sprite_size := Vector2(_base_size, _base_size) * art_zoom
	_sprite.position = Vector2((size.x - sprite_size.x) * 0.5, 0)
	if _stage_art_loaded:
		_sprite.position.y = (_base_size - sprite_size.y) * 0.5
	_sprite_base_position = _sprite.position
	_sprite.size = sprite_size
	set_process(_frames.size() > 1 or _tutorial_bob or _stage_art_loaded)

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
	_hit_frames.clear()
	_death_frames.clear()
	_frame_index = 0
	_anim_time = 0.0
	_walk_frame_time = 0.0
	_hit_frame_index = 0
	_hit_anim_time = 0.0
	_hit_playing = false
	_death_frame_index = 0
	_death_anim_time = 0.0
	_death_frame_duration = DEATH_FRAME_DURATION
	_death_playing = false
	if _sprite and is_instance_valid(_sprite):
		_sprite.queue_free()
	_sprite = null
	_sprite_base_position = Vector2.ZERO
	_stage_art_loaded = false
	_authored_walk_animation = false
	_lightning_stun_timer = 0.0
	_lightning_flash_elapsed = 0.0
	_lightning_flash_white = true
	_lightning_flash_material = null
	_poison_flash_timer = 0.0
	_burn_stack_count = 0
	_poison_stack_count = 0
	_recoil_direction = Vector2.ZERO
	_recoil_elapsed = 0.0
	_recoil_active = false
	position = Vector2.ZERO
	rotation = 0.0


func _uses_stage_one_slime_animation() -> bool:
	return visual_tier == 1 and monster_type in ["small", "medium", "large"]


func _append_atlas_frames(target: Array[Texture2D], sheet_path: String, frame_count: int, columns: int) -> void:
	target.append_array(RuntimeAtlasScript.load_grid(
		sheet_path,
		ANIMATION_FRAME_SIZE,
		frame_count,
		columns
	))


func _load_tutorial_armored_animation() -> void:
	_append_atlas_frames(_frames, TUTORIAL_ARMORED_WALK_SHEET, TUTORIAL_ARMORED_WALK_FRAME_COUNT, 6)
	_append_atlas_frames(_hit_frames, TUTORIAL_ARMORED_HIT_SHEET, TUTORIAL_ARMORED_HIT_FRAME_COUNT, 5)
	if not _frames.is_empty():
		_stage_art_loaded = true
		_authored_walk_animation = true


func _setup_lightning_flash_material() -> void:
	var shader := Shader.new()
	shader.code = LIGHTNING_FLASH_SHADER_CODE
	_lightning_flash_material = ShaderMaterial.new()
	_lightning_flash_material.shader = shader
	_lightning_flash_material.set_shader_parameter("lightning_amount", 0.0)
	_lightning_flash_material.set_shader_parameter("lightning_white", 1.0)
	if _sprite and is_instance_valid(_sprite):
		# Keep normal monsters on Godot's native TextureRect rendering path.
		# Even a zero-strength custom canvas shader can change sampling/color
		# conversion on the compatibility renderer, making every monster darker.
		# The material is attached only for the short lightning stun.
		_sprite.use_parent_material = false
		_sprite.material = null


func _set_lightning_flash(active: bool, white_phase: bool) -> void:
	if _lightning_flash_material == null:
		return
	_lightning_flash_material.set_shader_parameter("lightning_amount", 0.96 if active else 0.0)
	_lightning_flash_material.set_shader_parameter("lightning_white", 1.0 if white_phase else 0.0)
	if _sprite == null or not is_instance_valid(_sprite):
		return
	if active:
		_sprite.use_parent_material = false
		if _sprite.material != _lightning_flash_material:
			_sprite.material = _lightning_flash_material
	elif _sprite.material == _lightning_flash_material:
		# Unmount the shader instead of merely setting its blend amount to zero.
		# This prevents inactive monsters from inheriting any shader color change.
		_sprite.material = null


func _apply_element_tint() -> void:
	if _poison_flash_timer > 0.0:
		modulate = Color(1.0, 0.32, 0.32, 1.0)
	elif _freeze_timer > 0.0:
		# Tint the complete authored body rather than adding a separate overlay.
		modulate = Color(0.42, 0.73, 1.0, 1.0)
	else:
		modulate = Color.WHITE
	if _sprite and is_instance_valid(_sprite):
		_sprite.modulate = Color.WHITE


func play_death_animation(speed_multiplier: float = 1.0) -> float:
	if _death_playing:
		return float(DEATH_FRAME_COUNT) * _death_frame_duration
	if _sprite == null:
		return 0.0
	_load_death_frames()
	if _death_frames.is_empty():
		return 0.0
	_death_playing = true
	_hit_playing = false
	_death_frame_index = 0
	_death_anim_time = 0.0
	_death_frame_duration = DEATH_FRAME_DURATION / maxf(1.0, speed_multiplier)
	_sprite.texture = _death_frames[0]
	_set_lightning_flash(false, true)
	_recoil_direction = Vector2.ZERO
	_recoil_elapsed = 0.0
	_recoil_active = false
	modulate = Color.WHITE
	_sprite.modulate = Color.WHITE
	position = Vector2.ZERO
	rotation = 0.0
	if _stun_layer and is_instance_valid(_stun_layer):
		_stun_layer.queue_free()
		_stun_layer = null
	if _stun_tween and _stun_tween.is_valid():
		_stun_tween.kill()
		_stun_tween = null
	queue_redraw()
	set_process(true)
	return float(_death_frames.size()) * _death_frame_duration


func play_hit_animation() -> float:
	if _death_playing or _sprite == null or _hit_frames.is_empty():
		return 0.0
	_hit_playing = true
	_hit_frame_index = 0
	_hit_anim_time = 0.0
	_sprite.texture = _hit_frames[0]
	set_process(true)
	return float(_hit_frames.size()) * HIT_FRAME_DURATION


func play_element_recoil(attack_origin_global: Vector2) -> float:
	if _death_playing:
		return 0.0
	var body_center := global_position + Vector2(size.x * 0.5, _base_size * 0.5)
	var away_direction := body_center - attack_origin_global
	if away_direction.length_squared() < 0.01:
		away_direction = Vector2.UP
	_recoil_direction = away_direction.normalized()
	_recoil_elapsed = 0.0
	_recoil_active = true
	set_process(true)
	return ELEMENT_RECOIL_OUT_DURATION + ELEMENT_RECOIL_RETURN_DURATION


func _advance_element_recoil(delta: float) -> Vector2:
	if not _recoil_active:
		return Vector2.ZERO
	_recoil_elapsed += delta
	var total_duration := ELEMENT_RECOIL_OUT_DURATION + ELEMENT_RECOIL_RETURN_DURATION
	if _recoil_elapsed >= total_duration:
		_recoil_elapsed = 0.0
		_recoil_active = false
		return Vector2.ZERO
	var strength := 0.0
	if _recoil_elapsed <= ELEMENT_RECOIL_OUT_DURATION:
		var outward_t := clampf(_recoil_elapsed / ELEMENT_RECOIL_OUT_DURATION, 0.0, 1.0)
		strength = 1.0 - pow(1.0 - outward_t, 3.0)
	else:
		var return_t := clampf(
			(_recoil_elapsed - ELEMENT_RECOIL_OUT_DURATION) / ELEMENT_RECOIL_RETURN_DURATION,
			0.0,
			1.0
		)
		var smooth_return := return_t * return_t * (3.0 - 2.0 * return_t)
		strength = 1.0 - smooth_return
	return _recoil_direction * ELEMENT_RECOIL_DISTANCE * strength


func _load_death_frames() -> void:
	if not _death_frames.is_empty():
		return
	_append_atlas_frames(_death_frames, DEATH_SHEET, DEATH_FRAME_COUNT, 5)


func _stage_texture(family: String, tier: int) -> Texture2D:
	var textures := MONSTER_STAGE_TEXTURES.get(family, []) as Array
	if textures.is_empty():
		return null
	return textures[clampi(tier, 1, textures.size()) - 1] as Texture2D


func _stage_art_zoom(type_name: String, tier: int) -> float:
	# Source canvases are all 512px, while the painted alpha bounds vary a lot.
	# These values normalize the visible body instead of stretching the bitmap.
	var stage_index := clampi(tier, 1, 3) - 1
	match type_name:
		"small", "medium", "large":
			return [2.28, 1.76, 1.70][stage_index]
		_:
			return 1.0

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


func set_tutorial_stunned(stunned: bool) -> void:
	if not stunned:
		if _stun_tween and _stun_tween.is_valid():
			_stun_tween.kill()
		_stun_tween = null
		if _stun_layer and is_instance_valid(_stun_layer):
			_stun_layer.queue_free()
		_stun_layer = null
		return
	if _stun_layer and is_instance_valid(_stun_layer):
		return
	_stun_layer = Control.new()
	_stun_layer.name = "TutorialStunStars"
	_stun_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stun_layer.position = Vector2(size.x * 0.5, -8.0)
	add_child(_stun_layer)
	var star_texture := load("res://assets/runtime/ui/components/rating_stars/icons/star_active.png") as Texture2D
	for i in range(3):
		var star := TextureRect.new()
		star.texture = star_texture
		star.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		star.mouse_filter = Control.MOUSE_FILTER_IGNORE
		star.size = Vector2(24.0, 24.0)
		var angle := TAU * float(i) / 3.0
		star.position = Vector2(cos(angle) * 42.0, sin(angle) * 10.0) - star.size * 0.5
		_stun_layer.add_child(star)
	_stun_layer.pivot_offset = Vector2.ZERO
	_stun_tween = create_tween().set_loops()
	_stun_tween.tween_property(_stun_layer, "rotation", TAU, 1.15).set_trans(Tween.TRANS_LINEAR)
