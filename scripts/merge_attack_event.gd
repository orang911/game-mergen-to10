extends RefCounted
class_name MergeAttackEvent

var level := 1              # legacy alias for result_level
var source_level := 1       # pre-merge level: element/color/tier source
var result_level := 1       # generated block level: attack power source
var attack_level := 1       # level used for ATK lookup
var element_key := "poison"
var element: int = GameConfig.AttackElement.POISON
var element_tier := 1
var atk := 0
var merge_count := 0
var origin := Vector2.ZERO  # legacy alias for origin_position
var origin_position := Vector2.ZERO
var damage := 0.0
var target_count := 1
var effect_params: Dictionary = {}
var board_row: int = 0

static func from_merge(source_level: int, result_level: int, count: int, attack_origin: Vector2, merge_row: int) -> MergeAttackEvent:
	var event := MergeAttackEvent.new()
	event.source_level = source_level
	event.result_level = result_level
	event.level = result_level
	event.attack_level = result_level
	event.element_key = GameConfig.get_element_key_for_level(source_level)
	event.element = GameConfig.get_element_for_level(source_level)
	event.element_tier = GameConfig.get_element_tier(source_level)
	event.atk = GameConfig.get_attack_value_for_level(result_level)
	event.merge_count = count
	event.origin = attack_origin
	event.origin_position = attack_origin
	event.damage = float(event.atk)
	event.effect_params = GameConfig.get_element_effect_params(source_level)
	if event.element == GameConfig.AttackElement.LIGHTNING:
		event.target_count = 1
		event.damage = GameConfig.calculate_attack_damage(result_level, count)
		event.atk = roundi(event.damage)
		event.effect_params["chain_count"] = GameConfig.calculate_lightning_bounces(
			int(event.effect_params.get("chain_count", 0)),
			count
		)
		event.effect_params["chain_damage_ratio"] = GameConfig.calculate_lightning_retention(
			float(event.effect_params.get("chain_damage_ratio", 0.5)),
			count
		)
	else:
		event.target_count = GameConfig.calculate_target_count(count)
	event.board_row = merge_row
	return event
