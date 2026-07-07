extends RefCounted
class_name MergeAttackEvent

var level := 1
var element: int = GameConfig.AttackElement.POISON
var element_tier := 1
var merge_count := 0
var origin := Vector2.ZERO
var damage := 0.0
var target_count := 1
var effect_params: Dictionary = {}

static func from_merge(level_value: int, count: int, attack_origin: Vector2) -> MergeAttackEvent:
	var event := MergeAttackEvent.new()
	event.level = level_value
	event.element = GameConfig.get_element_for_level(level_value)
	event.element_tier = GameConfig.get_element_tier(level_value)
	event.merge_count = count
	event.origin = attack_origin
	event.damage = GameConfig.calculate_attack_damage(level_value, count)
	event.target_count = GameConfig.calculate_target_count(count)
	event.effect_params = GameConfig.get_element_effect_params(level_value)
	return event
