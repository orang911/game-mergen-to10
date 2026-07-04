extends RefCounted
class_name GameConfig

const GRID_SIZE := 5
const BLOCK_SIZE := 96.0
const BOARD_BACKDROP_PADDING := 15.0
const SAVE_PATH := "user://merge_to_10.cfg"

const LEVEL_ATTACK := {
	1: 2,
	2: 4,
	3: 6,
	4: 10,
	5: 14,
	6: 18,
	7: 25,
	8: 32,
	9: 40,
	10: 50,
}

enum AttackElement {
	POISON,
	FREEZE,
	LIGHTNING,
	FIRE,
}

const LEVEL_ELEMENT := {
	1: AttackElement.POISON,
	2: AttackElement.FREEZE,
	3: AttackElement.LIGHTNING,
	4: AttackElement.FIRE,
	5: AttackElement.FIRE,
	6: AttackElement.POISON,
	7: AttackElement.FREEZE,
	8: AttackElement.POISON,
	9: AttackElement.LIGHTNING,
	10: AttackElement.LIGHTNING,
}

static func get_level_label(level: int) -> String:
	if level <= 10:
		return str(level)
	return char(64 + level - 10)

static func get_element_for_level(level: int) -> int:
	return LEVEL_ELEMENT.get(level, AttackElement.POISON)

static func get_base_attack(level: int) -> int:
	return LEVEL_ATTACK.get(level, 50)

static func calculate_attack_damage(level: int, merge_count: int) -> float:
	var base_damage := float(get_base_attack(level))
	var bonus: float = 1.0 + float(max(0, merge_count - 2)) * 0.2
	return base_damage * bonus

static func calculate_target_count(merge_count: int) -> int:
	return max(1, merge_count - 1)

static func get_board_size() -> Vector2:
	var side := BLOCK_SIZE * float(GRID_SIZE)
	return Vector2(side, side)

static func get_board_backdrop_size() -> Vector2:
	return get_board_size() + Vector2.ONE * BOARD_BACKDROP_PADDING * 2.0


const MAX_CASTLE_DURABILITY := 20

const MONSTER_CONFIG := {
	"small": {"hp": 5, "durability_damage": 1, "speed": 80.0, "scale": 0.75},
	"medium": {"hp": 12, "durability_damage": 2, "speed": 68.0, "scale": 1.0},
	"large": {"hp": 25, "durability_damage": 3, "speed": 55.0, "scale": 1.25},
}

const WAVES := [
	{"small": 6, "medium": 0, "large": 0, "spawn_interval": 1.0},
	{"small": 8, "medium": 2, "large": 0, "spawn_interval": 0.9},
	{"small": 10, "medium": 4, "large": 1, "spawn_interval": 0.8},
]
