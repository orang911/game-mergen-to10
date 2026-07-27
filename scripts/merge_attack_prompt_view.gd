extends Control
class_name MergeAttackPromptView

const DISPLAY_SIZE := Vector2(540.0, 178.0)
const ICON_CENTER := Vector2(270.0, 60.0)
const ICON_ENTER_DURATION := 0.12
const PROMPT_DELAY := 0.08
const PROMPT_ENTER_DURATION := 0.12
const ENTER_DURATION := PROMPT_DELAY + PROMPT_ENTER_DURATION
const EXIT_DURATION := 0.18

@onready var _background: TextureRect = $PromptGroup/Background
@onready var _element_icon: TextureRect = $PromptGroup/ElementIcon
@onready var _element_name: Label = $PromptGroup/ElementName
@onready var _attack_value: Label = $PromptGroup/AttackValue
@onready var _combo_value: Label = $PromptGroup/ComboValue
@onready var _cast_icon: TextureRect = $CastIcon
@onready var _prompt_group: Control = $PromptGroup

var _element_color := Color(0.5, 0.8, 1.0, 1.0)
var _icon_base_scale := 1.0
var _halo_scale := 1.0
var _halo_intensity := 1.0
var _presentation_tier := 1
var _glow_strength := 0.0:
	set(value):
		_glow_strength = value
		queue_redraw()
var _glow_tween: Tween
var _shot_tween: Tween
var _exit_started := false


static func get_merge_presentation(merge_count: int) -> Dictionary:
	if merge_count >= 6:
		return {"tier": 3, "icon_scale": 1.32, "halo_scale": 1.32, "halo_intensity": 1.26}
	if merge_count >= 4:
		return {"tier": 2, "icon_scale": 1.16, "halo_scale": 1.16, "halo_intensity": 1.12}
	return {"tier": 1, "icon_scale": 1.0, "halo_scale": 1.0, "halo_intensity": 1.0}


func play(background_texture: Texture2D, icon_texture: Texture2D, element_name: String, total_damage: float, attack_count: int, target_position: Vector2, element_key: String, merge_count: int) -> void:
	_background.texture = background_texture
	_element_icon.texture = icon_texture
	_cast_icon.texture = icon_texture
	_element_name.text = element_name
	_attack_value.text = "总伤害：%s" % _format_damage(total_damage)
	_combo_value.text = "%d连击" % maxi(1, attack_count)
	_element_color = _color_for_element(element_key)
	var presentation := get_merge_presentation(merge_count)
	_presentation_tier = int(presentation["tier"])
	_icon_base_scale = float(presentation["icon_scale"])
	_halo_scale = float(presentation["halo_scale"])
	_halo_intensity = float(presentation["halo_intensity"])
	position = target_position
	pivot_offset = DISPLAY_SIZE * 0.5
	scale = Vector2.ONE
	modulate.a = 1.0
	_glow_strength = 0.0

	_cast_icon.pivot_offset = _cast_icon.size * 0.5
	_cast_icon.scale = Vector2.ONE * (_icon_base_scale * 0.55)
	_cast_icon.modulate.a = 0.0
	_prompt_group.pivot_offset = _prompt_group.size * 0.5
	_prompt_group.scale = Vector2(0.92, 0.92)
	_prompt_group.modulate.a = 0.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_cast_icon, "modulate:a", 1.0, ICON_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_cast_icon, "scale", Vector2.ONE * _icon_base_scale, ICON_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_glow_strength", 1.0, ICON_ENTER_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_prompt_group, "modulate:a", 1.0, PROMPT_ENTER_DURATION).set_delay(PROMPT_DELAY).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(_prompt_group, "scale", Vector2.ONE, PROMPT_ENTER_DURATION).set_delay(PROMPT_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func begin_attacking() -> void:
	if _exit_started:
		return
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(self, "_glow_strength", 0.62, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_glow_tween.tween_property(self, "_glow_strength", 1.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func pulse_for_shot() -> void:
	if _exit_started:
		return
	if _shot_tween and _shot_tween.is_valid():
		_shot_tween.kill()
	var base_scale := Vector2.ONE * _icon_base_scale
	_cast_icon.scale = base_scale
	_shot_tween = create_tween()
	match _presentation_tier:
		2:
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 1.30, 0.060).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 0.96, 0.060).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale, 0.090).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		3:
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 1.42, 0.065).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 0.92, 0.065).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 1.10, 0.080).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale, 0.100).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		_:
			_shot_tween.tween_property(_cast_icon, "scale", base_scale * 1.22, 0.055).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			_shot_tween.tween_property(_cast_icon, "scale", base_scale, 0.105).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func finish() -> void:
	if _exit_started:
		return
	_exit_started = true
	if _glow_tween and _glow_tween.is_valid():
		_glow_tween.kill()
	if _shot_tween and _shot_tween.is_valid():
		_shot_tween.kill()
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.92, 0.92), EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "_glow_strength", 0.0, EXIT_DURATION)
	tween.chain().tween_callback(queue_free)


func _format_damage(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(roundi(value))
	return "%.1f" % value


func _color_for_element(element_key: String) -> Color:
	match element_key:
		"poison": return Color(0.35, 0.9, 0.3, 1.0)
		"ice": return Color(0.5, 0.8, 1.0, 1.0)
		"lightning": return Color(1.0, 0.93, 0.25, 1.0)
		"critical": return Color(0.75, 0.4, 0.95, 1.0)
		"fire": return Color(1.0, 0.45, 0.15, 1.0)
	return Color(0.7, 0.92, 1.0, 1.0)


func _draw() -> void:
	var outer_alpha := 0.10 * _glow_strength * _halo_intensity
	var middle_alpha := 0.18 * _glow_strength * _halo_intensity
	var inner_alpha := 0.30 * _glow_strength * _halo_intensity
	draw_circle(ICON_CENTER, 78.0 * _halo_scale, Color(_element_color.r, _element_color.g, _element_color.b, outer_alpha))
	draw_circle(ICON_CENTER, 58.0 * _halo_scale, Color(_element_color.r, _element_color.g, _element_color.b, middle_alpha))
	draw_circle(ICON_CENTER, 40.0 * _halo_scale, Color(1.0, 1.0, 1.0, inner_alpha))
