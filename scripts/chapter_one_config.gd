extends RefCounted
class_name ChapterOneConfig

## Campaign data is intentionally separate from the endless-mode 20-wave
## formula.  A chapter is a continuous run made of lightweight named nodes.
const CHAPTER_ID := "chapter_01"
const TITLE := "水晶初醒"
const CHAPTER_WAVE_COUNT := 12
const CONTINUATION_WAVE_COUNT := GameConfig.LEVEL_WAVE_COUNT

static func get_waves() -> Array:
	var waves: Array = [
		{
			"id": "1-1-tutorial",
			"node_id": "1-1",
			"allow_random_energy_imprint": true,
			"tutorial_placeholder": true,
			"segment_end": false,
		},
		{
			"id": "1-1-element-intro",
			"node_id": "1-1",
			"allow_random_energy_imprint": true,
			"small": 5,
			"hp_multiplier": 1.00,
			"visual_tier": 1,
			"spawn_interval": 1.00,
		},
		{
			"id": "1-1-free-merge",
			"node_id": "1-1",
			"allow_random_energy_imprint": true,
			"small": 7,
			"hp_multiplier": 1.05,
			"visual_tier": 1,
			"spawn_interval": 0.95,
			"segment_end": true,
		},
		{
			"id": "1-2-practice-a",
			"node_id": "1-2",
			"allow_random_energy_imprint": true,
			"small": 5,
			"medium": 1,
			"hp_multiplier": 1.10,
			"visual_tier": 1,
			"spawn_interval": 0.95,
		},
		{
			"id": "1-2-practice-b",
			"node_id": "1-2",
			"allow_random_energy_imprint": true,
			"small": 4,
			"medium": 2,
			"hp_multiplier": 1.15,
			"visual_tier": 2,
			"spawn_interval": 0.90,
		},
		{
			"id": "1-2-practice-c",
			"node_id": "1-2",
			"allow_random_energy_imprint": true,
			"small": 4,
			"medium": 3,
			"hp_multiplier": 1.20,
			"visual_tier": 2,
			"spawn_interval": 0.88,
			"segment_end": true,
		},
		{
			"id": "1-3-imprint-fixed",
			"node_id": "1-3",
			"allow_random_energy_imprint": true,
			"small": 4,
			"medium": 3,
			"hp_multiplier": 1.25,
			"visual_tier": 2,
			"spawn_interval": 0.90,
		},
		{
			"id": "1-3-imprint-choice",
			"node_id": "1-3",
			"allow_random_energy_imprint": true,
			"small": 3,
			"medium": 4,
			"hp_multiplier": 1.30,
			"visual_tier": 2,
			"spawn_interval": 0.88,
		},
		{
			"id": "1-3-imprint-freeplay",
			"node_id": "1-3",
			"allow_random_energy_imprint": true,
			"small": 3,
			"medium": 4,
			"large": 1,
			"hp_multiplier": 1.35,
			"visual_tier": 2,
			"spawn_interval": 0.86,
			"segment_end": true,
		},
		{
			"id": "1-4-guards",
			"node_id": "1-4",
			"allow_random_energy_imprint": true,
			"small": 3,
			"medium": 3,
			"hp_multiplier": 1.40,
			"visual_tier": 3,
			"spawn_interval": 0.86,
		},
		{
			"id": "1-4-mini-boss",
			"node_id": "1-4",
			"allow_random_energy_imprint": true,
			"is_boss": true,
			"spawn_interval": 0.90,
			"spawn_sequence": [
				{
					"monster_type": "large",
					"hp_multiplier": 1.0,
					"overrides": {
						"hp": 120.0,
						"durability_damage": 2,
						"speed": GameConfig.MONSTER_CONFIG["large"]["speed"] * 0.80,
						"scale": 1.42,
						"appearance_id": "mini_boss",
						"is_boss": true,
					},
					"delay_after": 1.10,
				},
				{"monster_type": "small", "hp_multiplier": 1.40, "visual_tier": 3, "delay_after": 0.72},
				{"monster_type": "small", "hp_multiplier": 1.40, "visual_tier": 3},
			],
			"segment_end": true,
			"chapter_reward": "crystal_choice",
		},
		{
			"id": "1-5-final-boss",
			"node_id": "1-5",
			"allow_random_energy_imprint": true,
			"is_boss": true,
			"spawn_interval": 0.90,
			"spawn_sequence": [
				{
					"monster_type": "large",
					"hp_multiplier": 1.0,
					"overrides": {
						"hp": 300.0,
						"durability_damage": 3,
						"speed": GameConfig.MONSTER_CONFIG["large"]["speed"] * 0.70,
						"scale": 1.65,
						"appearance_id": "chapter_boss",
						"is_boss": true,
					},
					"delay_after": 1.10,
				},
				{"monster_type": "medium", "hp_multiplier": 1.50, "visual_tier": 3, "delay_after": 0.70},
				{"monster_type": "medium", "hp_multiplier": 1.50, "visual_tier": 3, "delay_after": 0.70},
				{"monster_type": "medium", "hp_multiplier": 1.50, "visual_tier": 3},
			],
			"segment_end": true,
			"chapter_final": true,
		},
	]
	waves.append_array(get_continuation_waves())
	return waves


static func get_continuation_waves() -> Array:
	# Preserve the previous 20-wave formula after Chapter One. It is a separate
	# continuation block so its numbers and compositions can be tuned without
	# disturbing the authored onboarding beats above.
	var continuation: Array = []
	var legacy_waves := GameConfig.get_level_waves()
	for index in range(legacy_waves.size()):
		var wave := (legacy_waves[index] as Dictionary).duplicate(true)
		wave["id"] = "continuation-%02d" % (index + 1)
		wave["continuation"] = true
		wave["continuation_index"] = index + 1
		wave["display_label"] = "续战 %02d" % (index + 1)
		continuation.append(wave)
	return continuation


static func get_wave(index: int) -> Dictionary:
	var waves := get_waves()
	if index < 0 or index >= waves.size():
		return {}
	return (waves[index] as Dictionary).duplicate(true)
