extends RefCounted
class_name CardCatalog

const TYPE_BOARD := "board"
const TYPE_CRYSTAL := "crystal"

const BOARD_FRONT := "res://assets/runtime/ui/cards/backs/board_card_front.png"
const BOARD_BACK := "res://assets/runtime/ui/cards/backs/board_card_back.png"
const CRYSTAL_FRONT := "res://assets/runtime/ui/cards/backs/crystal_card_front.png"
const CRYSTAL_BACK := "res://assets/runtime/ui/components/card_backs/textures/crystal_card_back.png"

const BOARD_CARD_IDS := [
	"ascension_hammer",
	"unity_dial",
	"fate_shuffler",
	"twin_mold",
	"castle_cannon",
	"dragon_catapult",
]

const CRYSTAL_CARD_IDS := [
	"fire_conduit",
	"poison_tank",
	"star_boiler",
	"rapid_clockwork",
	"twin_lens",
	"piercing_cannon",
]

const ALL_CARD_IDS := BOARD_CARD_IDS + CRYSTAL_CARD_IDS

# Runtime card copy is sourced from docs/17_target_card_catalog_2026-07-17.md.
# The exported game does not read Markdown files, so the verified catalog lives
# here as data and remains available on every platform.
const DEFINITIONS := {
	"ascension_hammer": {
		"type": TYPE_BOARD,
		"item_name": "星阶铸锤",
		"skill_name": "晶核跃升",
		"description": "当前合成结果块\n额外提升等级",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/ascension_hammer.tres",
	},
	"unity_dial": {
		"type": TYPE_BOARD,
		"item_name": "万象数盘",
		"skill_name": "万数归一",
		"description": "记录印记块合成前数字\n其余非保留方块统一为该数字",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/unity_dial.tres",
	},
	"fate_shuffler": {
		"type": TYPE_BOARD,
		"item_name": "命运魔箱",
		"skill_name": "命运洗牌",
		"description": "打乱棋盘数字与印记\n并保证至少一组可合成方块",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/fate_shuffler.tres",
	},
	"twin_mold": {
		"type": TYPE_BOARD,
		"item_name": "双生晶模",
		"skill_name": "双生铸模",
		"description": "相邻非最高级方块\n变为结果块相同数字",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/twin_mold.tres",
	},
	"castle_cannon": {
		"type": TYPE_BOARD,
		"item_name": "王城魔炮",
		"skill_name": "王城轰击",
		"description": "对最靠近城堡的怪物\n进行一次高伤害炮击",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/castle_cannon.tres",
	},
	"dragon_catapult": {
		"type": TYPE_BOARD,
		"item_name": "龙焰投石",
		"skill_name": "龙焰轰炸",
		"description": "攻击靠近城堡的一组怪物\n造成范围伤害并附加燃烧",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/dragon_catapult.tres",
	},
	"frost_bell": {
		"type": TYPE_BOARD,
		"item_name": "永霜警戒钟",
		"skill_name": "霜钟震荡",
		"description": "对场上怪物造成伤害\n并施加大范围减速",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/frost_bell.tres",
	},
	"thunder_ballista": {
		"type": TYPE_BOARD,
		"item_name": "雷铸连发弩",
		"skill_name": "雷弧齐射",
		"description": "连续攻击多名怪物\n目标之间产生雷电跳跃",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/thunder_ballista.tres",
	},
	"fire_conduit": {
		"type": TYPE_CRYSTAL,
		"item_name": "炉心龙纹管",
		"skill_name": "龙焰附着",
		"description": "水晶攻击命中后\n对目标附加燃烧",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/fire_conduit.tres",
	},
	"frost_prism": {
		"type": TYPE_CRYSTAL,
		"item_name": "霜卫棱镜",
		"skill_name": "霜痕附着",
		"description": "水晶攻击命中后施加减速\n重复命中刷新持续时间",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/frost_prism.tres",
	},
	"poison_tank": {
		"type": TYPE_CRYSTAL,
		"item_name": "腐蚀炼金罐",
		"skill_name": "剧毒附着",
		"description": "水晶攻击命中后\n施加持续毒伤",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/poison_tank.tres",
	},
	"thunder_spire": {
		"type": TYPE_CRYSTAL,
		"item_name": "雷鸣塔针",
		"skill_name": "雷弧附着",
		"description": "水晶攻击命中后弹射目标\n并造成较低伤害",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/thunder_spire.tres",
	},
	"star_boiler": {
		"type": TYPE_CRYSTAL,
		"item_name": "星核蒸汽炉",
		"skill_name": "星核增幅",
		"description": "当前游戏局提高\n水晶塔普通攻击伤害",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/star_boiler.tres",
	},
	"rapid_clockwork": {
		"type": TYPE_CRYSTAL,
		"item_name": "迅流发条机",
		"skill_name": "迅流脉冲",
		"description": "当前游戏局提高攻击速度\n缩短水晶普通攻击间隔",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/rapid_clockwork.tres",
	},
	"twin_lens": {
		"type": TYPE_CRYSTAL,
		"item_name": "双塔折射镜",
		"skill_name": "双重折射",
		"description": "当前游戏局水晶攻击\n额外命中目标",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/twin_lens.tres",
	},
	"piercing_cannon": {
		"type": TYPE_CRYSTAL,
		"item_name": "城墙穿透炮",
		"skill_name": "晶轨穿透",
		"description": "水晶攻击穿透一个目标\n后续目标承受较低伤害",
		"icon": "res://assets/runtime/ui/components/card_icons/atlas_regions/piercing_cannon.tres",
	},
}


static func get_definition(card_id: String) -> Dictionary:
	return (DEFINITIONS.get(card_id, {}) as Dictionary).duplicate(true)


static func is_board_card(card_id: String) -> bool:
	return str((DEFINITIONS.get(card_id, {}) as Dictionary).get("type", "")) == TYPE_BOARD


static func is_crystal_card(card_id: String) -> bool:
	return str((DEFINITIONS.get(card_id, {}) as Dictionary).get("type", "")) == TYPE_CRYSTAL


static func get_front_texture(card_id: String) -> String:
	return BOARD_FRONT if is_board_card(card_id) else CRYSTAL_FRONT


static func get_back_texture(card_id: String) -> String:
	return BOARD_BACK if is_board_card(card_id) else CRYSTAL_BACK
