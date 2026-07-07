extends RefCounted
class_name GameConfig

const GRID_SIZE := 5
const BLOCK_SIZE := 118.0
const BLOCK_GRID_STEP := Vector2(108.0, 108.0)
const BLOCK_GRID_OFFSET := Vector2(-3.0, 0.0)
# Source block PNGs include transparent padding. Keep the visual rect inside
# the logical cell so the board reads lighter and the cells have breathing room.
const BLOCK_VISUAL_SIZE := Vector2(118.0, 112.0)
const BLOCK_SOURCE_SIZE := 304.0
const BLOCK_LABEL_FILL := 0.62
const BLOCK_SHADOW_OFFSET := Vector2(0.0, 6.0)
const BLOCK_SHADOW_SCALE := Vector2(0.97, 0.97)
const BLOCK_SHADOW_COLOR := Color(0.05, 0.12, 0.20, 0.24)
const BOARD_GRID_SIZE := Vector2(590.0, 590.0)
const BOARD_GRID_POS := Vector2(175.5, 630.0)
const BOARD_GRID_BOTTOM_Y := 1220.0
const BOARD_PLATE_SIZE := Vector2(668.0, 682.0)
const BOARD_PLATE_OFFSET := Vector2(-38.5, -42.0)
const CRYSTAL_CENTER_OFFSET := Vector2(0.0, -85.0)
const CRYSTAL_PANEL_SIZE := Vector2(180.0, 225.0)
const CRYSTAL_PANEL_TOP := 420.0
const SAVE_PATH := "user://merge_to_10.cfg"
const MAX_BLOCK_LEVEL := 36
const TEXT_BLOCK_DIR := "res://assets/sliced_20260703_172750/core_blocks_split/text/"

const BLOCK_COLORS := ["green", "blue", "yellow", "purple", "red"]

const PATH_ROAD_IMAGE_SIZE := Vector2(932.0, 1310.0)
const PATH_ROAD_SCALE := 1.0
const PATH_ROAD_OFFSET := Vector2(0.0, 0.0)
const PATH_ROAD_TARGET_BOTTOM_Y := 1420.0
const BOARD_TARGET_BOTTOM_Y := BOARD_GRID_BOTTOM_Y
const PATH_ROAD_POINTS := [
	Vector2(79.0, 163.0),
	Vector2(770.0, 175.0),
	Vector2(810.0, 198.0),
	Vector2(842.0, 242.0),
	Vector2(838.0, 1130.0),
	Vector2(812.0, 1205.0),
	Vector2(750.0, 1255.0),
	Vector2(120.0, 1255.0),
	Vector2(55.0, 1205.0),
	Vector2(74.0, 1135.0),
	Vector2(80.0, 515.0),
	Vector2(95.0, 430.0),
	Vector2(140.0, 386.0),
	Vector2(182.0, 380.0),
]

const LEVEL_ATTACK := {
	1: 2,   2: 4,   3: 6,   4: 10,  5: 14,
	6: 18,  7: 25,  8: 32,  9: 40,  10: 50,
	11: 60,  12: 70,  13: 80,  14: 90,  15: 100,
	16: 110, 17: 120, 18: 130, 19: 140, 20: 150,
	21: 165, 22: 180, 23: 195, 24: 210, 25: 225,
	26: 240, 27: 255, 28: 270, 29: 285, 30: 300,
	31: 320, 32: 340, 33: 360, 34: 380, 35: 400, 36: 420,
}

enum AttackElement {
	POISON,
	FREEZE,
	LIGHTNING,
	MAGIC,
	FIRE,
}

const COLOR_ELEMENT := {
	"green": AttackElement.POISON,
	"blue": AttackElement.FREEZE,
	"yellow": AttackElement.LIGHTNING,
	"purple": AttackElement.MAGIC,
	"red": AttackElement.FIRE,
}

static func get_element_tier(level: int) -> int:
	return floori(float(level - 1) / 5.0) + 1

# Element effect params keyed by element enum, indexed by tier (1-based).
# tier 0 fallback = tier 1 values.
const ELEMENT_EFFECT := {
	AttackElement.POISON: {
		"name": "poison",
		"dps_ratio": 0.20, "dps_ratio_per_tier": 0.05,
		"duration": 3.0, "duration_per_tier": 0.3,
	},
	AttackElement.FREEZE: {
		"name": "freeze",
		"slow_percent": 0.25, "slow_percent_per_tier": 0.04,
		"duration": 2.0, "duration_per_tier": 0.25,
	},
	AttackElement.LIGHTNING: {
		"name": "lightning",
		"chain_count": 1, "chain_count_per_tiers": 2,
		"chain_damage_ratio": 0.50, "chain_damage_ratio_per_tier": 0.05,
	},
	AttackElement.MAGIC: {
		"name": "magic",
		"damage_bonus": 0.20, "damage_bonus_per_tier": 0.05,
	},
	AttackElement.FIRE: {
		"name": "fire",
		"duration": 2.0, "duration_per_tier": 0.2,
		"splash_radius": 70.0, "splash_radius_per_tier": 8.0,
		"splash_damage_ratio": 0.30, "splash_damage_ratio_per_tier": 0.04,
	},
}

static func get_element_effect_params(level: int) -> Dictionary:
	var element: int = get_element_for_level(level)
	var tier: int = get_element_tier(level)
	var base: Dictionary = ELEMENT_EFFECT[element] if ELEMENT_EFFECT.has(element) else ELEMENT_EFFECT[AttackElement.POISON]
	var t: float = float(tier)
	var params: Dictionary = {"element": element, "tier": tier}
	match element:
		AttackElement.POISON:
			params["dps_ratio"] = float(base["dps_ratio"]) + float(base["dps_ratio_per_tier"]) * (t - 1.0)
			params["duration"] = float(base["duration"]) + float(base["duration_per_tier"]) * (t - 1.0)
		AttackElement.FREEZE:
			params["slow_percent"] = float(base["slow_percent"]) + float(base["slow_percent_per_tier"]) * (t - 1.0)
			params["duration"] = float(base["duration"]) + float(base["duration_per_tier"]) * (t - 1.0)
		AttackElement.LIGHTNING:
			params["chain_count"] = int(base["chain_count"]) + floori((t - 1.0) / float(base["chain_count_per_tiers"]))
			params["chain_damage_ratio"] = float(base["chain_damage_ratio"]) + float(base["chain_damage_ratio_per_tier"]) * (t - 1.0)
		AttackElement.MAGIC:
			params["damage_bonus"] = float(base["damage_bonus"]) + float(base["damage_bonus_per_tier"]) * (t - 1.0)
		AttackElement.FIRE:
			params["duration"] = float(base["duration"]) + float(base["duration_per_tier"]) * (t - 1.0)
			params["splash_radius"] = float(base["splash_radius"]) + float(base["splash_radius_per_tier"]) * (t - 1.0)
			params["splash_damage_ratio"] = float(base["splash_damage_ratio"]) + float(base["splash_damage_ratio_per_tier"]) * (t - 1.0)
	return params

const BLOCK_BG_PATHS := {
	"green": "res://assets/sliced_20260703_172750/core_blocks_split/blocks_304/block_green.png",
	"blue": "res://assets/sliced_20260703_172750/core_blocks_split/blocks_304/block_blue.png",
	"yellow": "res://assets/sliced_20260703_172750/core_blocks_split/blocks_304/block_yellow.png",
	"purple": "res://assets/sliced_20260703_172750/core_blocks_split/blocks_304/block_purple.png",
	"red": "res://assets/sliced_20260703_172750/core_blocks_split/blocks_304/block_red.png",
}


static func get_block_color_index(level: int) -> int:
	return (level - 1) % 5

static func get_block_color_name(level: int) -> String:
	return BLOCK_COLORS[get_block_color_index(level)]

static func get_level_label(level: int) -> String:
	if level <= 10:
		return str(level)
	return char(64 + level - 10)

static func get_label_texture_path(level: int) -> String:
	if level <= 10:
		return TEXT_BLOCK_DIR + "number_" + str(level) + ".png"
	return TEXT_BLOCK_DIR + "letter_" + char(64 + level - 10) + ".png"

static func get_element_for_level(level: int) -> int:
	return COLOR_ELEMENT.get(get_block_color_name(level), AttackElement.POISON)

static func get_base_attack(level: int) -> int:
	return LEVEL_ATTACK.get(level, 50)

static func calculate_attack_damage(level: int, merge_count: int) -> float:
	var base_damage := float(get_base_attack(level))
	var bonus: float = 1.0 + float(max(0, merge_count - 2)) * 0.2
	return base_damage * bonus

static func calculate_target_count(merge_count: int) -> int:
	return max(1, merge_count - 1)

static func get_board_size() -> Vector2:
	return BOARD_GRID_SIZE

static func get_block_grid_content_size() -> Vector2:
	return Vector2(BLOCK_SIZE, BLOCK_SIZE) + BLOCK_GRID_STEP * float(GRID_SIZE - 1)

static func get_block_grid_inner_offset() -> Vector2:
	return (get_board_size() - get_block_grid_content_size()) * 0.5 + BLOCK_GRID_OFFSET

static func get_block_position_for_site(site: Vector2i) -> Vector2:
	var inner_offset := get_block_grid_inner_offset()
	return inner_offset + Vector2(float(site.x) * BLOCK_GRID_STEP.x, float(GRID_SIZE - 1 - site.y) * BLOCK_GRID_STEP.y)

static func get_board_backdrop_size() -> Vector2:
	return BOARD_PLATE_SIZE

static func get_board_plate_position(board_grid_pos: Vector2) -> Vector2:
	return board_grid_pos + BOARD_PLATE_OFFSET

static func get_board_grid_offset_in_plate() -> Vector2:
	return -BOARD_PLATE_OFFSET

static func get_crystal_center(board_grid_pos: Vector2, board_grid_size: Vector2) -> Vector2:
	return board_grid_pos + Vector2(board_grid_size.x * 0.5, 0.0) + CRYSTAL_CENTER_OFFSET

static func get_path_road_rect(board_pos: Vector2, board_size: Vector2) -> Rect2:
	var road_size := PATH_ROAD_IMAGE_SIZE * PATH_ROAD_SCALE
	var board_center := board_pos + board_size * 0.5
	return Rect2(board_center - road_size * 0.5 + PATH_ROAD_OFFSET, road_size)

static func get_path_points_for_board(board_pos: Vector2, board_size: Vector2) -> PackedVector2Array:
	var road_rect := get_path_road_rect(board_pos, board_size)
	var points := PackedVector2Array()
	for point in PATH_ROAD_POINTS:
		points.append(road_rect.position + point * PATH_ROAD_SCALE)
	return points


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
