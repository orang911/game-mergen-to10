extends RefCounted
class_name MergeAttackEvent

var level := 1              # legacy alias for result_level
var source_level := 1       # pre-merge level: element/color/tier source
var result_level := 1       # generated block level: attack power source
var attack_level := 1       # level used for ATK lookup
var element_key := "poison"
var element: int = GameConfig.AttackElement.POISON
var element_tier := 1
var atk := 0                 # legacy integer alias for displayed total damage
var merge_count := 0
var attack_count := 1
var total_damage := 0.0
var sequence_id := 0
var origin := Vector2.ZERO  # legacy alias for origin_position
var origin_position := Vector2.ZERO
var damage := 0.0
var target_count := 1
var effect_params: Dictionary = {}
var board_row: int = 0

static var _next_sequence_id := 1

static func from_merge(source_level: int, result_level: int, count: int, attack_origin: Vector2, merge_row: int) -> MergeAttackEvent:
	var event := MergeAttackEvent.new()
	event.source_level = source_level
	event.result_level = result_level
	event.level = result_level
	event.attack_level = result_level
	event.element_key = GameConfig.get_element_key_for_level(source_level)
	event.element = GameConfig.get_element_for_level(source_level)
	event.element_tier = GameConfig.get_element_tier(source_level)
	var safe_count := maxi(1, count)
	var base_attack := float(GameConfig.get_attack_value_for_level(result_level))
	event.merge_count = safe_count
	event.attack_count = safe_count
	event.total_damage = base_attack * float(maxi(1, safe_count - 1))
	event.damage = event.total_damage / float(safe_count)
	event.sequence_id = _next_sequence_id
	_next_sequence_id += 1
	if _next_sequence_id >= 2147483647:
		_next_sequence_id = 1
	event.origin = attack_origin
	event.origin_position = attack_origin
	event.effect_params = GameConfig.get_element_effect_params(source_level)
	if event.element == GameConfig.AttackElement.FREEZE:
		# Ice keeps its dedicated multi-target identity: a merge of N blocks
		# attacks N-1 different front monsters. One full base hit per target
		# preserves the same B * (N-1) theoretical output.
		event.target_count = GameConfig.calculate_target_count(safe_count)
		event.attack_count = event.target_count
		event.damage = base_attack
		event.total_damage = event.damage * float(event.target_count)
	elif event.element == GameConfig.AttackElement.LIGHTNING:
		# Lightning has exactly one primary strike. Extra merged blocks increase
		# primary damage, bounce count and retention instead of adding primaries.
		event.target_count = 1
		event.attack_count = 1
		event.damage = GameConfig.calculate_attack_damage(result_level, safe_count)
		event.total_damage = event.damage
		event.effect_params["chain_count"] = GameConfig.calculate_lightning_bounces(
			int(event.effect_params.get("chain_count", 0)),
			safe_count
		)
		event.effect_params["chain_damage_ratio"] = GameConfig.calculate_lightning_retention(
			float(event.effect_params.get("chain_damage_ratio", 0.5)),
			safe_count
		)
	else:
		# Poison, critical and fire use the sequential focus-fire rule.
		event.target_count = 1
	event.atk = roundi(event.total_damage)
	event.board_row = merge_row
	return event
