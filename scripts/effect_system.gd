extends Node
class_name EffectSystem

var _effect_layer: Control


func setup(layer: Control) -> void:
	_effect_layer = layer


func reset() -> void:
	if _effect_layer == null or not is_instance_valid(_effect_layer):
		return
	for child in _effect_layer.get_children():
		if child.name.begins_with("Effect_"):
			child.queue_free()


func play_merge_feedback(_event: MergeAttackEvent) -> void:
	pass


func play_monster_hit(monster: Monster) -> void:
	if not is_instance_valid(monster):
		return
	var original_modulate: Color = monster.modulate
	var tween := monster.create_tween()
	tween.tween_property(monster, "modulate", Color(2.0, 1.5, 1.5, 1.0), 0.04)
	tween.tween_property(monster, "modulate", original_modulate, 0.12)
	var s: float = monster.scale.x
	tween.parallel().tween_property(monster, "scale", Vector2(s * 1.12, s * 1.12), 0.06)
	tween.tween_property(monster, "scale", Vector2(s, s), 0.12)


func play_monster_reached_goal(monster: Monster) -> void:
	if not is_instance_valid(monster):
		return
	var tween := monster.create_tween()
	tween.tween_property(monster, "modulate", Color(1.0, 0.25, 0.25, 1.0), 0.06)
	tween.parallel().tween_property(monster, "scale", Vector2(0.65, 0.65), 0.12)
	tween.tween_property(monster, "modulate:a", 0.0, 0.12)


func play_castle_damage(_amount: int) -> void:
	pass


# -- Element FX placeholders (hook points for future particle / sprite effects) --

func play_element_launch(_req: ElementFxRequest) -> void:
	pass


func play_element_hit(_req: ElementFxRequest) -> void:
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
