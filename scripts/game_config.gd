extends RefCounted
class_name GameConfig

const GRID_SIZE := 5
const BLOCK_SIZE := 116.0
const BLOCK_GRID_STEP := Vector2(113.0, 113.0)
const BLOCK_GRID_OFFSET := Vector2(5.0, 0.0)
# Source block PNGs include transparent padding. Keep the visual rect inside
# the logical cell so the board reads lighter and the cells have breathing room.
const BLOCK_VISUAL_SIZE := Vector2(112.0, 112.0)
const BLOCK_SOURCE_SIZE := 304.0
const BLOCK_LABEL_FILL := 0.62
const BLOCK_SHADOW_OFFSET := Vector2(0.0, 6.0)
const BLOCK_SHADOW_SCALE := Vector2(0.97, 0.97)
const BLOCK_SHADOW_COLOR := Color(0.05, 0.12, 0.20, 0.24)
const BOARD_GRID_SIZE := Vector2(600.0, 600.0)
const BOARD_GRID_POS := Vector2(160.5, 630.0)
const BOARD_VISUAL_OFFSET := Vector2(-4.0, 0.0)
const BOARD_GRID_BOTTOM_Y := 1235.0
const BOARD_PLATE_SIZE := Vector2(600.0, 600.0)
const BOARD_PLATE_OFFSET := Vector2(5.0, 0.0)
const CRYSTAL_CENTER_OFFSET := Vector2(0.0, -85.0)
const CRYSTAL_PANEL_SIZE := Vector2(180.0, 225.0)
const CRYSTAL_PANEL_TOP := 420.0
const SAVE_PATH := "user://merge_to_10.cfg"
const MAX_BLOCK_LEVEL := 36
const SKILL_ENERGY_MAX := 100
# 仅当一次合成产出高于合成前棋盘最高等级的新数字时使用。
const SKILL_ENERGY_PER_MERGE_UNIT := 6
const SKILL_ENERGY_PER_KILL := 5
const ENERGY_MOTE_DURATION_MIN := 0.35
const ENERGY_MOTE_DURATION_MAX := 0.55
const ENERGY_MOTE_STAGGER := 0.04
const ENERGY_ARRIVAL_FLASH_DURATION := 0.22
const ENERGY_FULL_FEEDBACK_DELAY := 0.24

const CARD_MASK_FADE_IN := 0.16
const CARD_PANEL_INTRO := 0.24
const CARD_INTRO_DURATION := 0.22
const CARD_INTRO_STAGGER := 0.08
const CARD_UNSELECTED_FADE := 0.12
const CARD_SKILL_FLY_DURATION := 0.38
const CARD_CRYSTAL_FLY_DURATION := 0.42
const CARD_PANEL_FADE_OUT := 0.16
const CARD_MASK_FADE_OUT := 0.18
const CARD_FLIP_DURATION := 0.36
const CARD_FLIP_STAGGER := 0.10
const MAX_CARD_LEVEL := 5

const CRYSTAL_DAMAGE_UP_STEP := 0.25
const CRYSTAL_INTERVAL_MULTIPLIER := 0.8
const CRYSTAL_MIN_ATTACK_INTERVAL := 0.24
const CRYSTAL_EXTRA_TARGET_STEP := 1
const FROST_STAR_TARGETS := 3
const FROST_STAR_SLOW_RATIO := 0.25
const FROST_STAR_SLOW_DURATION := 2.0

const SKILL_CARD_IDS := CardCatalog.BOARD_CARD_IDS
const CRYSTAL_CARD_IDS := CardCatalog.CRYSTAL_CARD_IDS
const ALL_CARD_IDS := SKILL_CARD_IDS + CRYSTAL_CARD_IDS
const LEVEL_WAVE_COUNT := 20
const MILESTONE_ENTRY_WAVES := [5, 10, 15, 20]

const CARD_QUALITY_COMMON := 1
const CARD_QUALITY_RARE := 3
const CARD_QUALITY_EPIC := 5
const CARD_QUALITY_NAMES := {1: "1星", 2: "2星", 3: "3星", 4: "4星", 5: "5星"}
const CARD_QUALITY_COLORS := {
	1: Color(0.72, 0.84, 0.94),
	2: Color(0.40, 0.78, 1.0),
	3: Color(0.45, 0.86, 0.62),
	4: Color(0.75, 0.40, 1.0),
	5: Color(1.0, 0.78, 0.16),
}

# First-pass conservative balance. Every table is indexed by permanent card
# level (1..5) so later tuning remains data-only.
const ASCENSION_EXTRA_LEVELS := [1, 1, 1, 2, 2]
const TWIN_MOLD_TARGETS := [1, 1, 1, 2, 2]
const CASTLE_CANNON_DAMAGE := [1.60, 1.90, 2.20, 2.50, 2.80]
const DRAGON_CATAPULT_TARGETS := [2, 2, 3, 3, 4]
const DRAGON_CATAPULT_DAMAGE := [0.70, 0.80, 0.90, 1.00, 1.10]
const DRAGON_CATAPULT_BURN_RATIO := [0.10, 0.13, 0.16, 0.19, 0.22]
const DRAGON_CATAPULT_BURN_DURATION := [1.8, 2.1, 2.4, 2.7, 3.0]
const FROST_BELL_DAMAGE := [0.25, 0.30, 0.35, 0.40, 0.50]
const FROST_BELL_SLOW := [0.18, 0.22, 0.26, 0.30, 0.35]
const FROST_BELL_DURATION := [1.5, 1.75, 2.0, 2.25, 2.5]
const THUNDER_BALLISTA_TARGETS := [2, 2, 3, 3, 4]
const THUNDER_BALLISTA_DAMAGE := [0.60, 0.70, 0.80, 0.90, 1.00]
const THUNDER_BALLISTA_CHAIN_RATIO := [0.35, 0.40, 0.45, 0.50, 0.55]

const CRYSTAL_FIRE_DPS_RATIO := [0.10, 0.13, 0.16, 0.19, 0.22]
const CRYSTAL_FIRE_DURATION := [1.5, 2.0, 2.5, 3.0, 3.5]
const CRYSTAL_FROST_SLOW := [0.15, 0.20, 0.25, 0.30, 0.35]
const CRYSTAL_FROST_DURATION := [1.2, 1.5, 1.8, 2.1, 2.4]
const CRYSTAL_POISON_DPS_RATIO := [0.10, 0.13, 0.16, 0.19, 0.22]
const CRYSTAL_POISON_DURATION := [2.5, 3.0, 3.5, 4.0, 4.5]
const CRYSTAL_THUNDER_CHAIN_RATIO := [0.25, 0.30, 0.35, 0.40, 0.45]
const CRYSTAL_DAMAGE_UP_BY_LEVEL := [0.10, 0.14, 0.18, 0.22, 0.26]
const CRYSTAL_INTERVAL_BY_LEVEL := [0.95, 0.93, 0.91, 0.89, 0.87]
const CRYSTAL_EXTRA_TARGETS_BY_LEVEL := [1, 1, 1, 2, 2]
const CRYSTAL_PIERCE_DAMAGE_RATIO := [0.35, 0.40, 0.45, 0.50, 0.55]

const SKILL_IMPRINT_TEXTURES := {
	"ascension_hammer": "res://assets/runtime/ui/battle/board/imprints/ascension_hammer.png",
	"unity_dial": "res://assets/runtime/ui/battle/board/imprints/unity_dial.png",
	"fate_shuffler": "res://assets/runtime/ui/battle/board/imprints/fate_shuffler.png",
	"twin_mold": "res://assets/runtime/ui/battle/board/imprints/twin_mold.png",
	"castle_cannon": "res://assets/runtime/ui/battle/board/imprints/combat_skill_placeholder.png",
	"dragon_catapult": "res://assets/runtime/ui/battle/board/imprints/combat_skill_placeholder.png",
	"frost_bell": "res://assets/runtime/ui/battle/board/imprints/combat_skill_placeholder.png",
	"thunder_ballista": "res://assets/runtime/ui/battle/board/imprints/combat_skill_placeholder.png",
}
const TEXT_BLOCK_DIR := "res://assets/runtime/ui/battle/board/text/"

const BLOCK_COLORS := ["green", "blue", "yellow", "purple", "red"]
const ELEMENT_ORDER := ["poison", "ice", "lightning", "critical", "fire"]

# Actual supplied road artwork size. The road is drawn from this rect and the
# movement centerline is expressed in the same source-pixel coordinate space.
const PATH_ROAD_IMAGE_SIZE := Vector2(773.0, 1095.0)
# Virtual frame used only to keep the road anchor relative to the existing
# board layout. It is intentionally separate from the PNG dimensions.
const PATH_ROAD_LAYOUT_SIZE := Vector2(932.0, 1310.0)
const PATH_ROAD_SCALE := 0.955
const PATH_ROAD_OFFSET := Vector2(0.0, 0.0)
const PATH_ROAD_TARGET_BOTTOM_Y := 1405.0
const PATH_GATE_IMAGE_SIZE := Vector2(419.0, 143.0)
const PATH_GATE_DOOR_CENTER_X := 209.5
const PATH_ROAD_ENTRY_CENTER_X := 190.0
# In the supplied effect composite the gate is placed 100 source pixels above
# the road image. Keeping this offset makes its bottom cover the road seam
# without swallowing the first horizontal lane.
const PATH_GATE_TOP_OFFSET_Y := -100.0
const BOARD_TARGET_BOTTOM_Y := BOARD_GRID_BOTTOM_Y
const PATH_ROAD_POINTS := [
	# Centerline sampled directly from layer_003.png (773x1095).
	# Monsters begin behind the gate and follow the short entrance down into
	# the first lane instead of appearing at the outer edge of the bend.
	Vector2(190.0, 1.0),
	Vector2(190.0, 30.0),
	Vector2(192.0, 45.0),
	Vector2(197.0, 58.0),
	Vector2(207.0, 68.0),
	Vector2(220.0, 74.0),
	Vector2(235.0, 75.0),
	Vector2(650.0, 75.0),
	# Rounded top-right bend.
	Vector2(675.0, 79.0),
	Vector2(695.0, 91.0),
	Vector2(710.0, 112.0),
	Vector2(715.0, 137.0),
	# Upper-right straight and the visible outward S bend in the artwork.
	Vector2(715.0, 420.0),
	Vector2(717.0, 438.0),
	Vector2(726.0, 458.0),
	Vector2(737.0, 477.0),
	Vector2(739.0, 990.0),
	# Rounded bottom-right bend.
	Vector2(737.0, 1015.0),
	Vector2(725.0, 1037.0),
	Vector2(705.0, 1052.0),
	Vector2(680.0, 1060.0),
	Vector2(75.0, 1060.0),
	# Rounded bottom-left bend.
	Vector2(55.0, 1057.0),
	Vector2(40.0, 1045.0),
	Vector2(33.0, 1025.0),
	Vector2(33.0, 1000.0),
	Vector2(33.0, 370.0),
	# Rounded inner-left bend into the castle lane.
	Vector2(35.0, 345.0),
	Vector2(47.0, 320.0),
	Vector2(65.0, 299.0),
	Vector2(90.0, 280.0),
	Vector2(300.0, 280.0),
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
	CRITICAL,
	FIRE,
}

const COLOR_ELEMENT := {
	"green": AttackElement.POISON,
	"blue": AttackElement.FREEZE,
	"yellow": AttackElement.LIGHTNING,
	"purple": AttackElement.CRITICAL,
	"red": AttackElement.FIRE,
}

const ELEMENT_KEY_TO_ATTACK := {
	"poison": AttackElement.POISON,
	"ice": AttackElement.FREEZE,
	"lightning": AttackElement.LIGHTNING,
	"critical": AttackElement.CRITICAL,
	"fire": AttackElement.FIRE,
}

const ELEMENT_FX := {
	"poison": {
		"projectile": "res://assets/runtime/fx/elements/poison/projectile_core.png",
		"hit": "res://assets/runtime/fx/elements/poison/hit_spritesheet.png",
		"trail": "res://assets/runtime/fx/elements/shared/trail_soft_white.png",
		"trail_color": Color(0.25, 1.0, 0.35, 0.82),
		"core_size": Vector2(66.0, 66.0),
		"trail_size": Vector2(165.0, 42.0),
		"trail_offset": Vector2(-72.0, 0.0),
		"hit_size": Vector2(150.0, 150.0),
	},
	"ice": {
		"projectile": "res://assets/runtime/fx/elements/ice/projectile_core.png",
		"hit": "res://assets/runtime/fx/elements/ice/hit_spritesheet.png",
		"trail": "res://assets/runtime/fx/elements/ice/trail_texture.png",
		"trail_shader": "res://shaders/ice_projectile_trail.gdshader",
		"trail_color": Color.WHITE,
		"trail_tail_color": Color(0.05, 0.22, 0.88, 1.0),
		"trail_middle_color": Color(0.05, 0.78, 1.0, 1.0),
		"trail_head_color": Color(0.82, 0.97, 1.0, 1.0),
		"trail_opacity": 0.92,
		"trail_flow_speed": 2.8,
		"trail_distortion": 0.038,
		"trail_head_softness": 0.10,
		"core_size": Vector2(70.0, 70.0),
		"trail_size": Vector2(195.0, 64.0),
		"trail_offset": Vector2(-88.0, 0.0),
		# The requested in-game facing is the reverse of the source shard's pointed
		# end, so use the opposite 90-degree correction from the first pass.
		"rotation_offset": PI * 0.5,
		"hit_size": Vector2(160.0, 160.0),
	},
	"lightning": {
		"projectile": "res://assets/runtime/fx/elements/lightning/projectile_core.png",
		"hit": "res://assets/runtime/fx/elements/lightning/hit_spritesheet.png",
		"trail": "res://assets/runtime/fx/elements/shared/trail_soft_white.png",
		"trail_color": Color(1.0, 0.9, 0.15, 0.82),
		"core_size": Vector2(64.0, 64.0),
		"trail_size": Vector2(165.0, 42.0),
		"trail_offset": Vector2(-72.0, 0.0),
		"hit_size": Vector2(170.0, 170.0),
		"hit_grid": Vector2i(4, 4),
		"hit_frame_count": 10,
		"hit_fps": 18.0,
	},
	"critical": {
		"projectile": "res://assets/runtime/fx/elements/critical/projectile_core.png",
		"hit": "res://assets/runtime/fx/elements/critical/hit_spritesheet.png",
		"trail": "res://assets/runtime/fx/elements/shared/trail_soft_white.png",
		"trail_color": Color(0.72, 0.34, 1.0, 0.82),
		"core_size": Vector2(72.0, 72.0),
		"trail_size": Vector2(165.0, 42.0),
		"trail_offset": Vector2(-72.0, 0.0),
		"hit_size": Vector2(165.0, 165.0),
	},
	"fire": {
		"projectile": "res://assets/runtime/fx/elements/fire/projectile_core.png",
		"hit": "res://assets/runtime/fx/elements/fire/hit_spritesheet.png",
		"trail": "res://assets/runtime/fx/elements/shared/trail_soft_white.png",
		"trail_color": Color(1.0, 0.42, 0.12, 0.82),
		"core_size": Vector2(76.0, 76.0),
		"trail_size": Vector2(165.0, 42.0),
		"trail_offset": Vector2(-72.0, 0.0),
		"hit_size": Vector2(180.0, 180.0),
	},
}

const LAUNCH_FLASH_SIZE := Vector2(90.0, 90.0)
const LAUNCH_FLASH_DURATION := 0.12

const ELEMENT_HIT_GRID := Vector2i(4, 4)
const ELEMENT_HIT_FRAME_COUNT := 16
const ELEMENT_HIT_FPS := 18.0

# Lightning always has one primary target. Larger merge groups convert their
# former extra primary targets into stronger damage and a longer, gentler
# chain. Ratios are centralized here for later balance tuning.
const LIGHTNING_DAMAGE_PER_EXTRA_MERGE := 0.20
const LIGHTNING_BOUNCES_PER_EXTRA_MERGE := 1
const LIGHTNING_RETENTION_PER_EXTRA_MERGE := 0.05
const LIGHTNING_MAX_RETENTION := 0.90

static func is_critical(roll: float, chance: float) -> bool:
	return roll < chance

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
		"name": "ice",
		"slow_percent": 0.25, "slow_percent_per_tier": 0.04,
		"duration": 2.0, "duration_per_tier": 0.25,
	},
	AttackElement.LIGHTNING: {
		"name": "lightning",
		"chain_count": 1, "chain_count_per_tiers": 2,
		"chain_damage_ratio": 0.50, "chain_damage_ratio_per_tier": 0.05,
	},
	AttackElement.CRITICAL: {
		"name": "critical",
		"crit_chance": 0.25, "crit_chance_per_tier": 0.05,
		"crit_multiplier": 2.0,
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
	var element_key := get_element_key_for_level(level)
	var tier: int = get_element_tier(level)
	var base: Dictionary = ELEMENT_EFFECT[element] if ELEMENT_EFFECT.has(element) else ELEMENT_EFFECT[AttackElement.POISON]
	var t: float = float(tier)
	var params: Dictionary = {"element": element, "element_key": element_key, "tier": tier}
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
		AttackElement.CRITICAL:
			params["crit_chance"] = clampf(float(base["crit_chance"]) + float(base["crit_chance_per_tier"]) * (t - 1.0), 0.0, 1.0)
			params["crit_multiplier"] = float(base["crit_multiplier"])
		AttackElement.FIRE:
			params["duration"] = float(base["duration"]) + float(base["duration_per_tier"]) * (t - 1.0)
			params["splash_radius"] = float(base["splash_radius"]) + float(base["splash_radius_per_tier"]) * (t - 1.0)
			params["splash_damage_ratio"] = float(base["splash_damage_ratio"]) + float(base["splash_damage_ratio_per_tier"]) * (t - 1.0)
	return params

const BLOCK_BG_PATHS := {
	"green": "res://assets/runtime/ui/battle/blocks/block_green.png",
	"blue": "res://assets/runtime/ui/battle/blocks/block_blue.png",
	"yellow": "res://assets/runtime/ui/battle/blocks/block_yellow.png",
	"purple": "res://assets/runtime/ui/battle/blocks/block_purple.png",
	"red": "res://assets/runtime/ui/battle/blocks/block_red.png",
}

# Color correction from the supplied tile PNGs to the board effect reference.
# Applied only to the tile background; number overlays remain pure white.
const BLOCK_COLOR_TINTS := {
	"green": Color(0.72, 0.80, 0.54, 1.0),
	"blue": Color(0.80, 0.72, 0.81, 1.0),
	"yellow": Color(0.93, 0.96, 0.58, 1.0),
	"purple": Color(0.60, 0.53, 0.79, 1.0),
	"red": Color(0.82, 0.66, 0.78, 1.0),
}


static func get_block_color_index(level: int) -> int:
	return (level - 1) % 5

static func get_block_color_name(level: int) -> String:
	return BLOCK_COLORS[get_block_color_index(level)]

static func get_block_color_tint(color_name: String) -> Color:
	return BLOCK_COLOR_TINTS.get(color_name, Color.WHITE) as Color

static func get_level_label(level: int) -> String:
	if level <= 10:
		return str(level)
	return char(64 + level - 10)

static func get_label_texture_path(level: int) -> String:
	if level <= 10:
		return TEXT_BLOCK_DIR + "number_" + str(level) + ".png"
	return TEXT_BLOCK_DIR + "letter_" + char(96 + level - 10) + ".png"

static func get_element_for_level(level: int) -> int:
	return ELEMENT_KEY_TO_ATTACK.get(get_element_key_for_level(level), AttackElement.POISON)

static func get_element_key_for_level(level: int) -> String:
	var index := posmod(level - 1, ELEMENT_ORDER.size())
	return ELEMENT_ORDER[index]

static func get_element_fx(element_key: String) -> Dictionary:
	return ELEMENT_FX.get(element_key, ELEMENT_FX["poison"]) as Dictionary

static func get_attack_value_for_level(level: int) -> int:
	return get_base_attack(level)

static func get_base_attack(level: int) -> int:
	return LEVEL_ATTACK.get(level, 50)

static func calculate_attack_damage(level: int, merge_count: int) -> float:
	var base_damage := float(get_base_attack(level))
	var bonus: float = 1.0 + float(max(0, merge_count - 2)) * LIGHTNING_DAMAGE_PER_EXTRA_MERGE
	return base_damage * bonus


static func calculate_lightning_bounces(base_bounces: int, merge_count: int) -> int:
	return maxi(0, base_bounces + max(0, merge_count - 2) * LIGHTNING_BOUNCES_PER_EXTRA_MERGE)


static func calculate_lightning_retention(base_retention: float, merge_count: int) -> float:
	var improved := base_retention + float(max(0, merge_count - 2)) * LIGHTNING_RETENTION_PER_EXTRA_MERGE
	return clampf(improved, 0.0, LIGHTNING_MAX_RETENTION)

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

static func get_path_layout_size() -> Vector2:
	return PATH_ROAD_LAYOUT_SIZE * PATH_ROAD_SCALE

static func get_path_gate_rect(board_pos: Vector2, board_size: Vector2) -> Rect2:
	var road_rect := get_path_road_rect(board_pos, board_size)
	var gate_size := PATH_GATE_IMAGE_SIZE * PATH_ROAD_SCALE
	var door_center_x := road_rect.position.x + PATH_ROAD_ENTRY_CENTER_X * PATH_ROAD_SCALE
	var gate_position := Vector2(
		door_center_x - PATH_GATE_DOOR_CENTER_X * PATH_ROAD_SCALE,
		road_rect.position.y + PATH_GATE_TOP_OFFSET_Y * PATH_ROAD_SCALE
	)
	return Rect2(gate_position, gate_size)

static func get_path_points_for_board(board_pos: Vector2, board_size: Vector2) -> PackedVector2Array:
	var road_rect := get_path_road_rect(board_pos, board_size)
	var points := PackedVector2Array()
	for point in PATH_ROAD_POINTS:
		points.append(road_rect.position + point * PATH_ROAD_SCALE)
	return points


const MAX_CASTLE_DURABILITY := 20

const MONSTER_SPEED_MULTIPLIER := 2.0
const WAVE_MONSTER_COUNT_MULTIPLIER := 2

const MONSTER_CONFIG := {
	"small": {"hp": 5, "durability_damage": 1, "speed": 80.0 * MONSTER_SPEED_MULTIPLIER, "scale": 0.75},
	"medium": {"hp": 12, "durability_damage": 2, "speed": 68.0 * MONSTER_SPEED_MULTIPLIER, "scale": 1.0},
	"large": {"hp": 25, "durability_damage": 3, "speed": 55.0 * MONSTER_SPEED_MULTIPLIER, "scale": 1.25},
}

static func get_level_waves() -> Array:
	var result: Array = []
	for wave_number in range(1, LEVEL_WAVE_COUNT + 1):
		var stage := floori(float(wave_number - 1) / 5.0)
		result.append({
			"small": (5 + wave_number + stage) * WAVE_MONSTER_COUNT_MULTIPLIER,
			"medium": maxi(0, floori(float(wave_number - 2) / 2.0)) * WAVE_MONSTER_COUNT_MULTIPLIER,
			"large": maxi(0, floori(float(wave_number - 4) / 4.0)) * WAVE_MONSTER_COUNT_MULTIPLIER,
			"spawn_interval": maxf(0.42, 1.02 - float(wave_number - 1) * 0.025),
		})
	return result
