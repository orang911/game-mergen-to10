extends RefCounted
class_name BalanceSimulationEngine

const BASE_SEED := 20260722
const BoardRefillPolicyScript := preload("res://scripts/board_refill_policy.gd")
const SCENARIOS := ["current", "candidate_v1", "candidate_v2", "candidate_v2_dynamic"]
const BOARD_SCENARIOS := ["current", "candidate_v2", "sliding_uniform", "sliding_scored"]
const ATTACK_RULE_SCENARIOS := ["attack_legacy", "attack_combo_focus"]
const SLIDING_CURRENT_MAX_DROP_CAP := BoardRefillPolicyScript.CURRENT_MAX_DROP_CAP
const STRATEGIES := ["high_first", "low_first", "random"]
const SCENARIO_NAMES := {
	"current": "当前版",
	"candidate_v1": "原候选版",
	"candidate_v2": "V2基础概率",
	"candidate_v2_dynamic": "V2动态修正",
	"sliding_uniform": "五级滑窗均匀",
	"sliding_scored": "五级滑窗动态",
	"attack_legacy": "旧多目标攻击",
	"attack_combo_focus": "连续集火攻击",
}
const STRATEGY_NAMES := {"high_first": "优先高阶", "low_first": "优先清低阶", "random": "随机合成"}

const EVENT_MONSTER_STATE := 0
const EVENT_WAVE_START := 1
const EVENT_SPAWN := 2
const EVENT_HIT := 3
const EVENT_MERGE := 4
const EVENT_CRYSTAL := 5
const EVENT_COMBO_SHOT := 6
const EVENT_PRIORITY := {
	EVENT_MONSTER_STATE: 0,
	EVENT_WAVE_START: 1,
	EVENT_SPAWN: 2,
	EVENT_HIT: 3,
	EVENT_MERGE: 4,
	EVENT_CRYSTAL: 5,
	EVENT_COMBO_SHOT: 4,
}


static func build_default_settings(run_count: int = 1000) -> Dictionary:
	var points := GameConfig.get_path_points_for_board(GameConfig.BOARD_GRID_POS, GameConfig.get_board_size())
	var path_length := 0.0
	for index in range(points.size() - 1):
		path_length += points[index].distance_to(points[index + 1])
	return {
		"run_count": maxi(1, run_count),
		"action_interval": 1.0,
		"inter_wave_delay": 1.0,
		"merge_projectile_duration": 0.14,
		"merge_shot_interval": 0.05,
		"multi_shot_stagger": 0.10,
		"lightning_damage_per_extra_merge": GameConfig.LIGHTNING_DAMAGE_PER_EXTRA_MERGE,
		"lightning_bounces_per_extra_merge": GameConfig.LIGHTNING_BOUNCES_PER_EXTRA_MERGE,
		"lightning_retention_per_extra_merge": GameConfig.LIGHTNING_RETENTION_PER_EXTRA_MERGE,
		"lightning_max_retention": GameConfig.LIGHTNING_MAX_RETENTION,
		"grid_size": GameConfig.GRID_SIZE,
		"max_block_level": GameConfig.MAX_BLOCK_LEVEL,
		"level_attack": GameConfig.LEVEL_ATTACK.duplicate(true),
		"element_effect": GameConfig.ELEMENT_EFFECT.duplicate(true),
		"element_order": GameConfig.ELEMENT_ORDER.duplicate(),
		"waves": GameConfig.get_level_waves().duplicate(true),
		"monster_config": GameConfig.MONSTER_CONFIG.duplicate(true),
		"path_points": points,
		"path_length": path_length,
		"goal_progress": 0.995,
		"castle_durability": GameConfig.MAX_CASTLE_DURABILITY,
		# Mirrored from CrystalSystem. Keeping scalar snapshots here avoids loading
		# scene-facing combat classes inside the background simulation worker.
		"crystal_attack_interval": 1.8,
		"crystal_damage_ratio": 0.3,
		"crystal_max_level": GameConfig.CRYSTAL_MAX_LEVEL,
		"crystal_merge_upgrades_enabled": GameConfig.CRYSTAL_MERGE_UPGRADES_ENABLED,
		"crystal_upgrade_levels": GameConfig.CRYSTAL_UPGRADE_TRIGGER_LEVELS.duplicate(),
	}


static func sample_current_refill_level(historical_highest: int, roll: float) -> int:
	var maximum := 4 if historical_highest > 4 else 3
	return mini(maximum, floori(clampf(roll, 0.0, 0.999999) * float(maximum)) + 1)


static func sample_candidate_refill_level(historical_highest: int, roll: float) -> int:
	return _sample_weighted_level(_candidate_v1_weights(historical_highest), roll)


static func sample_v2_refill_level(historical_highest: int, roll: float) -> int:
	return _sample_weighted_level(get_v2_refill_weights(historical_highest), roll)


static func get_v2_refill_weights(historical_highest: int) -> Array[float]:
	if historical_highest <= 4:
		return [0.33, 0.34, 0.33, 0.0, 0.0]
	if historical_highest == 5:
		return [0.18, 0.36, 0.36, 0.10, 0.0]
	if historical_highest == 6:
		return [0.10, 0.30, 0.42, 0.16, 0.02]
	return [0.08, 0.24, 0.43, 0.20, 0.05]


static func get_dynamic_v2_weights(historical_highest: int, values: Array[int], grid_size: int, cell_index: int) -> Array[float]:
	return get_dynamic_v2_analysis(historical_highest, values, grid_size, cell_index)["weights"] as Array[float]


static func get_dynamic_v2_analysis(historical_highest: int, values: Array[int], grid_size: int, cell_index: int) -> Dictionary:
	var base := get_v2_refill_weights(historical_highest)
	return get_state_scored_analysis(base, historical_highest, values, grid_size, cell_index)


static func get_sliding_window_weights(historical_highest: int) -> Array[float]:
	if historical_highest < 5:
		return [0.33, 0.34, 0.33]
	var weights: Array[float] = []
	weights.resize(historical_highest)
	weights.fill(0.0)
	var minimum_level := maxi(1, historical_highest - 4)
	for level in range(minimum_level, historical_highest + 1):
		weights[level - 1] = 0.20
	return weights


static func get_sliding_progression_weights(historical_highest: int) -> Array[float]:
	if historical_highest < 5:
		return [0.33, 0.34, 0.33]
	var weights: Array[float] = []
	weights.resize(historical_highest)
	weights.fill(0.0)
	var minimum_level := maxi(1, historical_highest - 4)
	var progression: Array[float] = [0.32, 0.28, 0.22, 0.13, 0.05]
	for offset in range(5):
		weights[minimum_level + offset - 1] = progression[offset]
	return weights


static func get_state_scored_analysis(base: Array[float], historical_highest: int, values: Array[int], grid_size: int, cell_index: int, highest_level_cap: float = -1.0) -> Dictionary:
	var before := _board_quality(values, grid_size)
	var scores: Array[float] = []
	var raw_weights: Array[float] = []
	scores.resize(base.size())
	raw_weights.resize(base.size())
	for index in range(base.size()):
		if base[index] <= 0.0:
			scores[index] = -1000.0
			raw_weights[index] = 0.0
			continue
		var level := index + 1
		var virtual_board := values.duplicate()
		virtual_board[cell_index] = level
		var after := _board_quality(virtual_board, grid_size)
		var component_size := _component_size_at(virtual_board, grid_size, cell_index)
		var score := 0.0
		if component_size == 2:
			score += 3.0
		elif component_size >= 4:
			score -= 2.0 + float(component_size - 4) * 0.5
		var isolated_reduction := int(before["isolated"]) - int(after["isolated"])
		if isolated_reduction > 0:
			score += float(isolated_reduction) * 1.5
		var group_gain := int(after["groups"]) - int(before["groups"])
		score += float(group_gain)
		if component_size == 2 and level >= maxi(2, historical_highest - 2):
			score += 1.0
		var fragmentation_change := int(after["fragments"]) - int(before["fragments"])
		if fragmentation_change > 0:
			score -= float(fragmentation_change) * 2.0
		elif fragmentation_change < 0:
			score += float(-fragmentation_change) * 0.5
		var level_count := _count_level(virtual_board, level)
		var occupied := int(after["occupied"])
		var level_ratio := float(level_count) / float(maxi(1, occupied))
		if level_ratio > 0.32:
			score -= 1.5 * clampf((level_ratio - 0.32) / 0.20, 0.0, 1.0)
		if int(after["empty"]) == 0:
			score += 5.0 if int(after["groups"]) > 0 else -5.0
		scores[index] = score
		raw_weights[index] = base[index] * exp(clampf(score / 2.0, -6.0, 6.0))
	var special_index := historical_highest - 1 if highest_level_cap > 0.0 and historical_highest <= base.size() else -1
	var weights := _normalize_bounded_probabilities(raw_weights, base, 0.03, 0.55, special_index, highest_level_cap)
	return {"weights": weights, "scores": scores}


static func _board_quality(values: Array[int], grid_size: int) -> Dictionary:
	var occupied := 0
	var isolated := 0
	for cell_index in range(values.size()):
		if values[cell_index] <= 0:
			continue
		occupied += 1
		if not _cell_has_same_neighbor_in_values(values, grid_size, cell_index):
			isolated += 1
	return {
		"occupied": occupied,
		"empty": values.size() - occupied,
		"isolated": isolated,
		"groups": find_groups_for_board(values, grid_size).size(),
		"fragments": _count_level_components(values, grid_size),
	}


static func _component_size_at(values: Array[int], grid_size: int, start: int) -> int:
	if start < 0 or start >= values.size() or values[start] <= 0:
		return 0
	var level := values[start]
	var visited := {start: true}
	var queue: Array[int] = [start]
	var size := 0
	while not queue.is_empty():
		var cell: int = queue.pop_back()
		size += 1
		for neighbor in _orthogonal_neighbors(cell, grid_size, values.size()):
			if not visited.has(neighbor) and values[neighbor] == level:
				visited[neighbor] = true
				queue.append(neighbor)
	return size


static func _count_level_components(values: Array[int], grid_size: int) -> int:
	var visited := {}
	var component_count := 0
	for start in range(values.size()):
		if values[start] <= 0 or visited.has(start):
			continue
		component_count += 1
		var level := values[start]
		var queue: Array[int] = [start]
		visited[start] = true
		while not queue.is_empty():
			var cell: int = queue.pop_back()
			for neighbor in _orthogonal_neighbors(cell, grid_size, values.size()):
				if not visited.has(neighbor) and values[neighbor] == level:
					visited[neighbor] = true
					queue.append(neighbor)
	return component_count


static func _cell_has_same_neighbor_in_values(values: Array[int], grid_size: int, cell_index: int) -> bool:
	var level := values[cell_index]
	for neighbor in _orthogonal_neighbors(cell_index, grid_size, values.size()):
		if values[neighbor] == level:
			return true
	return false


static func _orthogonal_neighbors(cell_index: int, grid_size: int, cell_count: int) -> Array[int]:
	var result: Array[int] = []
	var cell_x: int = cell_index % grid_size
	var cell_y: int = floori(float(cell_index) / float(grid_size))
	for neighbor in [cell_index - grid_size, cell_index + grid_size, cell_index - 1, cell_index + 1]:
		if neighbor < 0 or neighbor >= cell_count:
			continue
		var neighbor_x: int = neighbor % grid_size
		var neighbor_y: int = floori(float(neighbor) / float(grid_size))
		if absi(neighbor_x - cell_x) + absi(neighbor_y - cell_y) == 1:
			result.append(neighbor)
	return result


static func _count_level(values: Array[int], level: int) -> int:
	var count := 0
	for value in values:
		if value == level:
			count += 1
	return count


static func _normalize_bounded_probabilities(raw: Array[float], fallback: Array[float], minimum: float, maximum: float, special_index: int = -1, special_maximum: float = -1.0) -> Array[float]:
	var result: Array[float] = []
	result.resize(raw.size())
	result.fill(0.0)
	var active: Array[int] = []
	for index in range(raw.size()):
		if fallback[index] > 0.0:
			active.append(index)
	var remaining := 1.0
	while not active.is_empty():
		var raw_total := 0.0
		for index in active:
			raw_total += maxf(0.0, raw[index])
		if raw_total <= 0.0:
			raw_total = 0.0
			for index in active:
				raw_total += fallback[index]
				raw[index] = fallback[index]
		var clamp_index := -1
		var clamp_value := 0.0
		for index in active:
			var probability := remaining * raw[index] / raw_total
			var index_maximum := special_maximum if index == special_index and special_maximum > 0.0 else maximum
			if probability < minimum:
				clamp_index = index
				clamp_value = minimum
				break
			if probability > index_maximum:
				clamp_index = index
				clamp_value = index_maximum
				break
		if clamp_index < 0:
			for index in active:
				result[index] = remaining * raw[index] / raw_total
			break
		result[clamp_index] = clamp_value
		remaining -= clamp_value
		active.erase(clamp_index)
	return result
static func sample_dynamic_v2_refill_level(historical_highest: int, values: Array[int], grid_size: int, cell_index: int, roll: float) -> int:
	return _sample_weighted_level(get_dynamic_v2_weights(historical_highest, values, grid_size, cell_index), roll)


static func _candidate_v1_weights(historical_highest: int) -> Array[float]:
	var weights: Array
	if historical_highest <= 4:
		weights = [0.33, 0.34, 0.33]
	elif historical_highest == 5:
		weights = [0.20, 0.30, 0.30, 0.20]
	elif historical_highest == 6:
		weights = [0.10, 0.25, 0.35, 0.25, 0.05]
	else:
		weights = [0.05, 0.15, 0.35, 0.30, 0.15]
	var typed: Array[float] = []
	for weight in weights:
		typed.append(float(weight))
	return typed


static func _sample_weighted_level(weights: Array[float], roll: float) -> int:
	var cumulative := 0.0
	for index in range(weights.size()):
		cumulative += float(weights[index])
		if roll <= cumulative or index == weights.size() - 1:
			return index + 1
	return weights.size()


static func find_groups_for_board(values: Array[int], grid_size: int) -> Array:
	var visited: Array[bool] = []
	visited.resize(values.size())
	visited.fill(false)
	var groups: Array = []
	for start in range(values.size()):
		if visited[start] or values[start] <= 0:
			continue
		var level: int = values[start]
		var queue: Array[int] = [start]
		var group: Array[int] = []
		visited[start] = true
		while not queue.is_empty():
			var cell: int = queue.pop_back()
			group.append(cell)
			var x: int = cell % grid_size
			var y: int = floori(float(cell) / float(grid_size))
			var neighbors: Array[int] = [cell - grid_size, cell + grid_size, cell - 1, cell + 1]
			for neighbor in neighbors:
				if neighbor < 0 or neighbor >= values.size() or visited[neighbor]:
					continue
				var nx: int = neighbor % grid_size
				var ny: int = floori(float(neighbor) / float(grid_size))
				if absi(nx - x) + absi(ny - y) != 1 or values[neighbor] != level:
					continue
				visited[neighbor] = true
				queue.append(neighbor)
		if group.size() >= 2:
			groups.append(group)
	return groups


func run_suite(settings: Dictionary, progress_callback: Callable = Callable(), cancel_callback: Callable = Callable()) -> Dictionary:
	var rows: Array[Dictionary] = []
	var run_count := int(settings.get("run_count", 1000))
	var total := run_count * SCENARIOS.size() * STRATEGIES.size()
	var completed := 0
	for strategy in STRATEGIES:
		for scenario in SCENARIOS:
			for run_index in range(run_count):
				if cancel_callback.is_valid() and bool(cancel_callback.call()):
					return {"cancelled": true, "rows": rows, "summary": [], "completed": completed, "total": total}
				var seed_value := BASE_SEED + run_index
				var model := RunModel.new()
				rows.append(model.execute(settings, scenario, strategy, seed_value, cancel_callback))
				completed += 1
				if progress_callback.is_valid():
					progress_callback.call(completed, total)
	var summary := _aggregate(rows)
	return {
		"mode": "combat",
		"cancelled": false,
		"rows": rows,
		"summary": summary,
		"completed": completed,
		"total": total,
		"settings": settings.duplicate(true),
	}


func run_board_progression_suite(settings: Dictionary, progress_callback: Callable = Callable(), cancel_callback: Callable = Callable()) -> Dictionary:
	var board_settings := settings.duplicate(true)
	board_settings["board_only"] = true
	board_settings["merge_limit"] = maxi(1, int(settings.get("merge_limit", 500)))
	var rows: Array[Dictionary] = []
	var run_count := int(board_settings.get("run_count", 1000))
	var total := run_count * BOARD_SCENARIOS.size() * STRATEGIES.size()
	var completed := 0
	for strategy in STRATEGIES:
		for scenario in BOARD_SCENARIOS:
			for run_index in range(run_count):
				if cancel_callback.is_valid() and bool(cancel_callback.call()):
					return {"mode": "board", "cancelled": true, "rows": rows, "summary": [], "completed": completed, "total": total}
				var seed_value := BASE_SEED + run_index
				var model := RunModel.new()
				rows.append(model.execute(board_settings, scenario, strategy, seed_value, cancel_callback))
				completed += 1
				if progress_callback.is_valid():
					progress_callback.call(completed, total)
	return {
		"mode": "board",
		"cancelled": false,
		"rows": rows,
		"summary": _aggregate_board_progression(rows),
		"completed": completed,
		"total": total,
		"settings": board_settings,
	}


func run_attack_rule_suite(settings: Dictionary, progress_callback: Callable = Callable(), cancel_callback: Callable = Callable()) -> Dictionary:
	var rows: Array[Dictionary] = []
	var run_count := int(settings.get("run_count", 1000))
	var total := run_count * ATTACK_RULE_SCENARIOS.size() * STRATEGIES.size()
	var jobs: Array[Dictionary] = []
	for strategy in STRATEGIES:
		for attack_scenario in ATTACK_RULE_SCENARIOS:
			jobs.append({"scenario": attack_scenario, "strategy": strategy})
	var progress_state := {"completed": 0}
	var progress_mutex := Mutex.new()
	var threads: Array[Thread] = []
	for job in jobs:
		var thread := Thread.new()
		threads.append(thread)
		thread.start(Callable(self, "_run_attack_rule_group").bind(
			settings,
			str(job["scenario"]),
			str(job["strategy"]),
			run_count,
			cancel_callback,
			progress_callback,
			progress_state,
			progress_mutex,
			total
		))
	for thread in threads:
		var group_value: Variant = thread.wait_to_finish()
		for row in group_value as Array:
			rows.append(row as Dictionary)
	var completed := int(progress_state["completed"])
	var was_cancelled := completed < total and cancel_callback.is_valid() and bool(cancel_callback.call())
	if was_cancelled:
		return {"mode": "attack_rules", "cancelled": true, "rows": rows, "summary": [], "completed": completed, "total": total}
	return {
		"mode": "attack_rules",
		"cancelled": false,
		"rows": rows,
		"summary": _aggregate_scenarios(rows, ATTACK_RULE_SCENARIOS, "attack_legacy"),
		"completed": completed,
		"total": total,
		"settings": settings.duplicate(true),
	}


func _run_attack_rule_group(settings: Dictionary, attack_scenario: String, strategy: String, run_count: int, cancel_callback: Callable, progress_callback: Callable, progress_state: Dictionary, progress_mutex: Mutex, total: int) -> Array[Dictionary]:
	var group_rows: Array[Dictionary] = []
	for run_index in range(run_count):
		if cancel_callback.is_valid() and bool(cancel_callback.call()):
			break
		var seed_value := BASE_SEED + run_index
		var model := RunModel.new()
		group_rows.append(model.execute(settings, attack_scenario, strategy, seed_value, cancel_callback))
		progress_mutex.lock()
		progress_state["completed"] = int(progress_state["completed"]) + 1
		var completed := int(progress_state["completed"])
		progress_mutex.unlock()
		if progress_callback.is_valid():
			progress_callback.call(completed, total)
	return group_rows


func _aggregate_board_progression(rows: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for strategy in STRATEGIES:
		for scenario in BOARD_SCENARIOS:
			var group: Array = []
			for row in rows:
				if row["scenario"] == scenario and row["strategy"] == strategy:
					group.append(row)
			if group.is_empty():
				continue
			result.append({
				"scenario": scenario,
				"scenario_name": SCENARIO_NAMES.get(scenario, scenario),
				"strategy": strategy,
				"strategy_name": STRATEGY_NAMES.get(strategy, strategy),
				"runs": group.size(),
				"completion_rate": _boolean_rate(group, "merge_limit_reached"),
				"stall_rate": _boolean_rate(group, "board_stalled"),
				"avg_merges": _average_field(group, "merge_count"),
				"highest_p50": _percentile_field(group, "highest_level", 0.50),
				"highest_p75": _percentile_field(group, "highest_level", 0.75),
				"highest_p90": _percentile_field(group, "highest_level", 0.90),
				"reach_10_rate": _milestone_reach_rate(group, "merges_to_10"),
				"reach_11_rate": _milestone_reach_rate(group, "merges_to_11"),
				"reach_12_rate": _milestone_reach_rate(group, "merges_to_12"),
				"reach_15_rate": _milestone_reach_rate(group, "merges_to_15"),
				"reach_20_rate": _milestone_reach_rate(group, "merges_to_20"),
				"reach_26_rate": _milestone_reach_rate(group, "merges_to_26"),
				"reach_36_rate": _milestone_reach_rate(group, "merges_to_36"),
				"merges_to_10_p50": _milestone_percentile(group, "merges_to_10", 0.50),
				"merges_to_11_p50": _milestone_percentile(group, "merges_to_11", 0.50),
				"merges_to_12_p50": _milestone_percentile(group, "merges_to_12", 0.50),
				"merges_to_15_p50": _milestone_percentile(group, "merges_to_15", 0.50),
				"merges_to_20_p50": _milestone_percentile(group, "merges_to_20", 0.50),
				"merges_to_26_p50": _milestone_percentile(group, "merges_to_26", 0.50),
				"merges_to_36_p50": _milestone_percentile(group, "merges_to_36", 0.50),
				"avg_generated_level": _average_field(group, "avg_generated_level"),
				"avg_group_size": _average_field(group, "avg_group_size"),
				"avg_refill_group_count": _average_field(group, "avg_refill_group_count"),
			})
	return result


func _boolean_rate(rows: Array, field: String) -> float:
	var count := 0
	for row in rows:
		count += 1 if bool(row.get(field, false)) else 0
	return float(count) / float(maxi(1, rows.size()))


func _aggregate(rows: Array[Dictionary]) -> Array[Dictionary]:
	return _aggregate_scenarios(rows, SCENARIOS, "current")


func _aggregate_scenarios(rows: Array[Dictionary], scenario_list: Array, baseline_scenario: String) -> Array[Dictionary]:
	var grouped := {}
	for row in rows:
		var key := "%s|%s" % [row["scenario"], row["strategy"]]
		if not grouped.has(key):
			grouped[key] = []
		grouped[key].append(row)
	var result: Array[Dictionary] = []
	for strategy in STRATEGIES:
		for scenario in scenario_list:
			var key := "%s|%s" % [scenario, strategy]
			var group: Array = grouped.get(key, [])
			if group.is_empty():
				continue
			result.append(_aggregate_group(group, scenario, strategy))
	for strategy in STRATEGIES:
		var current := _find_summary(result, baseline_scenario, strategy)
		for candidate_scenario in scenario_list:
			if candidate_scenario == baseline_scenario:
				continue
			var candidate := _find_summary(result, candidate_scenario, strategy)
			if not current.is_empty() and not candidate.is_empty():
				result.append(_make_delta_summary(current, candidate, strategy, candidate_scenario))
	return result


func _aggregate_group(group: Array, scenario: String, strategy: String) -> Dictionary:
	var wins := 0
	var stalled := 0
	var generated_total := 0
	var generated_ones := 0
	var post5_total := 0
	var post5_ones := 0
	for row in group:
		wins += 1 if bool(row["won"]) else 0
		stalled += 1 if bool(row["board_stalled"]) else 0
		generated_total += int(row["generated_total"])
		generated_ones += int(row["generated_ones"])
		post5_total += int(row["post5_generated_total"])
		post5_ones += int(row["post5_generated_ones"])
	return {
		"scenario": scenario,
		"scenario_name": SCENARIO_NAMES.get(scenario, scenario),
		"strategy": strategy,
		"strategy_name": STRATEGY_NAMES.get(strategy, strategy),
		"runs": group.size(),
		"win_rate": float(wins) / float(group.size()),
		"stall_rate": float(stalled) / float(group.size()),
		"wave_p50": _milestone_percentile(group, "failure_wave", 0.50),
		"wave_p75": _milestone_percentile(group, "failure_wave", 0.75),
		"wave_p90": _milestone_percentile(group, "failure_wave", 0.90),
		"highest_p50": _percentile_field(group, "highest_level", 0.50),
		"highest_p90": _percentile_field(group, "highest_level", 0.90),
		"reach_5_rate": _milestone_reach_rate(group, "merges_to_5"),
		"reach_6_rate": _milestone_reach_rate(group, "merges_to_6"),
		"reach_7_rate": _milestone_reach_rate(group, "merges_to_7"),
		"reach_8_rate": _milestone_reach_rate(group, "merges_to_8"),
		"merges_to_5_p50": _milestone_percentile(group, "merges_to_5", 0.50),
		"merges_to_6_p50": _milestone_percentile(group, "merges_to_6", 0.50),
		"merges_to_7_p50": _milestone_percentile(group, "merges_to_7", 0.50),
		"merges_to_8_p50": _milestone_percentile(group, "merges_to_8", 0.50),
		"generated_one_rate": float(generated_ones) / float(maxi(1, generated_total)),
		"post5_one_rate": float(post5_ones) / float(maxi(1, post5_total)),
		"adjacent_match_rate": _average_field(group, "adjacent_match_rate"),
		"avg_dynamic_selected_probability": _average_field(group, "avg_dynamic_selected_probability"),
		"avg_dynamic_selected_score": _average_field(group, "avg_dynamic_selected_score"),
		"avg_refill_group_count": _average_field(group, "avg_refill_group_count"),
		"avg_group_size": _average_field(group, "avg_group_size"),
		"avg_board_damage": _average_field(group, "board_damage"),
		"avg_theoretical_damage": _average_field(group, "board_theoretical_damage"),
		"avg_effective_damage": _average_field(group, "board_effective_damage"),
		"avg_overkill_damage": _average_field(group, "board_overkill_damage"),
		"avg_front_kill_time": _average_field(group, "avg_front_kill_time"),
		"avg_merge_damage_2": _average_field(group, "merge_damage_2"),
		"avg_merge_damage_3": _average_field(group, "merge_damage_3"),
		"avg_merge_damage_4": _average_field(group, "merge_damage_4"),
		"avg_merge_damage_5": _average_field(group, "merge_damage_5"),
		"avg_merge_damage_6_plus": _average_field(group, "merge_damage_6_plus"),
		"avg_crystal_damage": _average_field(group, "crystal_damage"),
		"avg_status_damage": _average_field(group, "status_damage"),
		"avg_total_damage": _average_field(group, "total_damage"),
		"avg_spawned": _average_field(group, "spawned"),
		"avg_killed": _average_field(group, "killed"),
		"avg_leaked": _average_field(group, "leaked"),
		"avg_castle": _average_field(group, "castle_remaining"),
		"death_progress_mean": _average_field(group, "death_progress_mean"),
		"death_progress_p50": _percentile_field(group, "death_progress_p50", 0.50),
		"death_progress_p90": _percentile_field(group, "death_progress_p90", 0.90),
		"avg_duration": _average_field(group, "duration"),
	}


func _make_delta_summary(current: Dictionary, candidate: Dictionary, strategy: String, candidate_scenario: String) -> Dictionary:
	var delta := {
		"scenario": "delta_%s" % candidate_scenario,
		"scenario_name": "%s-当前" % SCENARIO_NAMES.get(candidate_scenario, candidate_scenario),
		"strategy": strategy,
		"strategy_name": STRATEGY_NAMES.get(strategy, strategy),
		"runs": int(candidate["runs"]),
	}
	for key in candidate.keys():
		if key == "runs":
			continue
		if candidate[key] is float or candidate[key] is int:
			if current.has(key) and (current[key] is float or current[key] is int):
				var current_value := float(current[key])
				var absolute_change := float(candidate[key]) - current_value
				delta[key] = absolute_change
				delta["%s_relative_change" % key] = "N/A" if is_zero_approx(current_value) else absolute_change / absf(current_value)
	return delta


func _find_summary(rows: Array[Dictionary], scenario: String, strategy: String) -> Dictionary:
	for row in rows:
		if row["scenario"] == scenario and row["strategy"] == strategy:
			return row
	return {}


func _average_field(rows: Array, field: String) -> float:
	var total := 0.0
	for row in rows:
		total += float(row.get(field, 0.0))
	return total / float(maxi(1, rows.size()))


func _percentile_field(rows: Array, field: String, ratio: float) -> float:
	var values: Array[float] = []
	for row in rows:
		values.append(float(row.get(field, 0.0)))
	return _percentile(values, ratio)


func _milestone_percentile(rows: Array, field: String, ratio: float) -> float:
	var values: Array[float] = []
	for row in rows:
		var value := float(row.get(field, -1.0))
		if value >= 0.0:
			values.append(value)
	return _percentile(values, ratio) if not values.is_empty() else -1.0


func _milestone_reach_rate(rows: Array, field: String) -> float:
	var reached := 0
	for row in rows:
		if float(row.get(field, -1.0)) >= 0.0:
			reached += 1
	return float(reached) / float(maxi(1, rows.size()))


func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	values.sort()
	var index := clampi(roundi(float(values.size() - 1) * ratio), 0, values.size() - 1)
	return values[index]


class RunModel:
	var settings: Dictionary
	var scenario := "current"
	var drop_scenario := "current"
	var attack_rule := "combo_focus"
	var strategy := "high_first"
	var seed_value := 0
	var initial_rng := RandomNumberGenerator.new()
	var refill_rng := RandomNumberGenerator.new()
	var selection_rng := RandomNumberGenerator.new()
	var crit_rng := RandomNumberGenerator.new()
	var cancel_callback := Callable()

	var board: Array[int] = []
	var historical_highest := 1
	var merge_count := 0
	var group_size_total := 0
	var generated_counts := {}
	var post5_generated_counts := {}
	var generated_adjacent_matches := 0
	var dynamic_selected_probability_total := 0.0
	var dynamic_selected_score_total := 0.0
	var dynamic_sample_count := 0
	var refill_group_count_total := 0
	var refill_cycle_count := 0
	var milestone_merges := {5: -1, 6: -1, 7: -1, 8: -1, 9: -1, 10: -1, 11: -1, 12: -1, 15: -1, 20: -1, 26: -1, 36: -1}
	var board_stalled := false
	var board_only := false
	var crystal_level := 1
	var initial_board_signature := ""

	var events: Array = []
	var event_sequence := 0
	var time := 0.0
	var done := false
	var won := false
	var paused_until := 0.0
	var current_wave := -1
	var waves_cleared := 0
	var wave_transition_pending := false
	var spawn_remaining := 0
	var wave_alive := 0
	var castle_remaining := 20

	var monsters: Array[Dictionary] = []
	var alive_ids: Array[int] = []
	var spawned := 0
	var killed := 0
	var leaked := 0
	var death_progress: Array[float] = []
	var board_damage := 0.0
	var crystal_damage := 0.0
	var status_damage := 0.0
	var board_theoretical_damage := 0.0
	var board_effective_damage := 0.0
	var board_overkill_damage := 0.0
	var merge_damage_by_size := {2: 0.0, 3: 0.0, 4: 0.0, 5: 0.0, 6: 0.0}
	var front_focus_started := {}
	var front_kill_time_total := 0.0
	var front_kill_time_count := 0
	var spawn_order_hash := 0


	func execute(p_settings: Dictionary, p_scenario: String, p_strategy: String, p_seed: int, p_cancel: Callable) -> Dictionary:
		settings = p_settings
		scenario = p_scenario
		if BalanceSimulationEngine.ATTACK_RULE_SCENARIOS.has(p_scenario):
			drop_scenario = "sliding_scored"
			attack_rule = "legacy" if p_scenario == "attack_legacy" else "combo_focus"
		else:
			drop_scenario = p_scenario
			attack_rule = "combo_focus"
		strategy = p_strategy
		seed_value = p_seed
		cancel_callback = p_cancel
		board_only = bool(settings.get("board_only", false))
		initial_rng.seed = p_seed * 17 + 3
		refill_rng.seed = p_seed * 19 + 5
		selection_rng.seed = p_seed * 23 + 11
		crit_rng.seed = p_seed * 31 + 7
		castle_remaining = int(settings["castle_durability"])
		_initialize_board()
		initial_board_signature = _board_signature()
		if bool(settings.get("debug_events", false)):
			print("SIM_DEBUG initialized")
		_push_event(float(settings["action_interval"]), EVENT_MERGE, {})
		if not board_only:
			_push_event(0.0, EVENT_WAVE_START, {"wave": 0})
			_push_event(float(settings["crystal_attack_interval"]) * 0.5, EVENT_CRYSTAL, {})

		var processed_events := 0
		while not done and not events.is_empty():
			if bool(settings.get("debug_events", false)) and processed_events < 20:
				print("SIM_DEBUG before event=%d time=%.4f heap=%d" % [processed_events, time, events.size()])
			if bool(settings.get("debug_events", false)) and processed_events > 0 and processed_events % 10000 == 0:
				print("SIM_DEBUG events=%d time=%.4f heap=%d alive=%d wave=%d" % [processed_events, time, events.size(), alive_ids.size(), current_wave])
			if processed_events >= int(settings.get("max_events_per_run", 2000000)):
				done = true
				break
			if processed_events % 256 == 0 and cancel_callback.is_valid() and bool(cancel_callback.call()):
				done = true
				break
			var event: Array = _pop_event()
			time = float(event[0])
			if time > 20000.0:
				done = true
				break
			_process_event(int(event[2]), event[3] as Dictionary)
			processed_events += 1

		var death_mean := 0.0
		for value in death_progress:
			death_mean += value
		death_mean /= float(maxi(1, death_progress.size()))
		var death_copy := death_progress.duplicate()
		death_copy.sort()
		return {
			"scenario": scenario,
			"strategy": strategy,
			"seed": seed_value,
			"initial_board": initial_board_signature,
			"spawn_order_hash": spawn_order_hash,
			"won": won,
			"waves_cleared": waves_cleared,
			"failure_wave": -1 if won else waves_cleared + 1,
			"duration": time,
			"castle_remaining": castle_remaining,
			"highest_level": historical_highest,
			"merge_count": merge_count,
			"merge_limit_reached": board_only and merge_count >= int(settings.get("merge_limit", 500)),
			"merges_to_5": milestone_merges[5],
			"merges_to_6": milestone_merges[6],
			"merges_to_7": milestone_merges[7],
			"merges_to_8": milestone_merges[8],
			"merges_to_9": milestone_merges[9],
			"merges_to_10": milestone_merges[10],
			"merges_to_11": milestone_merges[11],
			"merges_to_12": milestone_merges[12],
			"merges_to_15": milestone_merges[15],
			"merges_to_20": milestone_merges[20],
			"merges_to_26": milestone_merges[26],
			"merges_to_36": milestone_merges[36],
			"board_stalled": board_stalled,
			"avg_group_size": float(group_size_total) / float(maxi(1, merge_count)),
			"generated_total": _count_generated(generated_counts),
			"generated_ones": int(generated_counts.get(1, 0)),
			"post5_generated_total": _count_generated(post5_generated_counts),
			"post5_generated_ones": int(post5_generated_counts.get(1, 0)),
			"adjacent_match_rate": float(generated_adjacent_matches) / float(maxi(1, _count_generated(generated_counts))),
			"avg_dynamic_selected_probability": dynamic_selected_probability_total / float(maxi(1, dynamic_sample_count)),
			"avg_dynamic_selected_score": dynamic_selected_score_total / float(maxi(1, dynamic_sample_count)),
			"avg_refill_group_count": float(refill_group_count_total) / float(maxi(1, refill_cycle_count)),
			"avg_generated_level": _generated_level_average(),
			"spawned": spawned,
			"killed": killed,
			"leaked": leaked,
			"board_damage": board_damage,
			"board_theoretical_damage": board_theoretical_damage,
			"board_effective_damage": board_effective_damage,
			"board_overkill_damage": board_overkill_damage,
			"avg_front_kill_time": front_kill_time_total / float(maxi(1, front_kill_time_count)),
			"merge_damage_2": float(merge_damage_by_size.get(2, 0.0)),
			"merge_damage_3": float(merge_damage_by_size.get(3, 0.0)),
			"merge_damage_4": float(merge_damage_by_size.get(4, 0.0)),
			"merge_damage_5": float(merge_damage_by_size.get(5, 0.0)),
			"merge_damage_6_plus": float(merge_damage_by_size.get(6, 0.0)),
			"crystal_damage": crystal_damage,
			"status_damage": status_damage,
			"total_damage": board_damage + crystal_damage + status_damage,
			"death_progress_mean": death_mean,
			"death_progress_p50": _array_percentile(death_copy, 0.50),
			"death_progress_p90": _array_percentile(death_copy, 0.90),
		}


	func _process_event(event_type: int, data: Dictionary) -> void:
		match event_type:
			EVENT_WAVE_START:
				_start_wave(int(data["wave"]))
			EVENT_SPAWN:
				_spawn_monster(str(data["monster_type"]))
			EVENT_MERGE:
				_process_merge_event()
			EVENT_CRYSTAL:
				_process_crystal_event()
			EVENT_HIT:
				_process_hit(data)
			EVENT_MONSTER_STATE:
				_process_monster_state(data)
			EVENT_COMBO_SHOT:
				_process_combo_shot(data)


	func _initialize_board() -> void:
		var cell_count := int(settings["grid_size"]) * int(settings["grid_size"])
		board.resize(cell_count)
		for index in range(cell_count):
			board[index] = _sample_initial_level()
			historical_highest = maxi(historical_highest, board[index])
		if _find_groups().is_empty() and board.size() >= 2:
			board[1] = board[0]


	func _sample_initial_level() -> int:
		var roll := initial_rng.randf()
		if roll < 0.33:
			return 1
		if roll < 0.67:
			return 2
		return 3


	func _sample_refill_level(cell_index: int) -> int:
		var roll := refill_rng.randf()
		var level := 1
		match drop_scenario:
			"current":
				level = BalanceSimulationEngine.sample_current_refill_level(historical_highest, roll)
			"candidate_v1":
				level = BalanceSimulationEngine.sample_candidate_refill_level(historical_highest, roll)
			"candidate_v2":
				level = BalanceSimulationEngine.sample_v2_refill_level(historical_highest, roll)
			"candidate_v2_dynamic":
				var analysis := BalanceSimulationEngine.get_dynamic_v2_analysis(historical_highest, board, int(settings["grid_size"]), cell_index)
				var weights := analysis["weights"] as Array[float]
				var scores := analysis["scores"] as Array[float]
				level = BalanceSimulationEngine._sample_weighted_level(weights, roll)
				dynamic_selected_probability_total += weights[level - 1]
				dynamic_selected_score_total += scores[level - 1]
				dynamic_sample_count += 1
			"sliding_uniform":
				level = BalanceSimulationEngine._sample_weighted_level(BalanceSimulationEngine.get_sliding_window_weights(historical_highest), roll)
			"sliding_scored":
				var sliding_analysis := BalanceSimulationEngine.BoardRefillPolicyScript.get_dynamic_analysis(historical_highest, board, int(settings["grid_size"]), cell_index)
				var sliding_weights := sliding_analysis["weights"] as Array[float]
				var sliding_scores := sliding_analysis["scores"] as Array[float]
				level = BalanceSimulationEngine._sample_weighted_level(sliding_weights, roll)
				dynamic_selected_probability_total += sliding_weights[level - 1]
				dynamic_selected_score_total += sliding_scores[level - 1]
				dynamic_sample_count += 1
		generated_counts[level] = int(generated_counts.get(level, 0)) + 1
		if historical_highest >= 5:
			post5_generated_counts[level] = int(post5_generated_counts.get(level, 0)) + 1
		if _cell_has_level_neighbor(cell_index, level):
			generated_adjacent_matches += 1
		return level


	func _process_merge_event() -> void:
		if done:
			return
		if time < paused_until:
			_push_event(paused_until, EVENT_MERGE, {})
			return
		if not board_stalled:
			_perform_merge()
		if board_only and merge_count >= int(settings.get("merge_limit", 500)):
			done = true
			won = true
			return
		if not board_stalled:
			_push_event(time + float(settings["action_interval"]), EVENT_MERGE, {})


	func _perform_merge() -> void:
		var groups := _find_groups()
		if groups.is_empty():
			board_stalled = true
			return
		var group: Array = _choose_group(groups)
		var anchor := int(group[selection_rng.randi_range(0, group.size() - 1)])
		var source_level := board[anchor]
		var result_level := mini(int(settings["max_block_level"]), source_level + 1)
		merge_count += 1
		group_size_total += group.size()
		for cell in group:
			board[int(cell)] = 0
		board[anchor] = result_level
		historical_highest = maxi(historical_highest, result_level)
		for milestone in [5, 6, 7, 8, 9, 10, 11, 12, 15, 20, 26, 36]:
			if result_level >= milestone and int(milestone_merges[milestone]) < 0:
				milestone_merges[milestone] = merge_count
		if bool(settings.get("crystal_merge_upgrades_enabled", false)) and (settings["crystal_upgrade_levels"] as Array).has(result_level):
			crystal_level = mini(int(settings["crystal_max_level"]), crystal_level + 1)
		_compact_and_refill()
		if not board_only:
			_dispatch_board_attack(source_level, result_level, group.size())


	func _generated_level_average() -> float:
		var total := 0
		var count := 0
		for level_value in generated_counts.keys():
			var generated_count := int(generated_counts[level_value])
			total += int(level_value) * generated_count
			count += generated_count
		return float(total) / float(maxi(1, count))


	func _find_groups() -> Array:
		return BalanceSimulationEngine.find_groups_for_board(board, int(settings["grid_size"]))


	func _choose_group(groups: Array) -> Array:
		if strategy == "random":
			return groups[selection_rng.randi_range(0, groups.size() - 1)]
		var best: Array = []
		var best_level := -1 if strategy == "high_first" else 100000
		var best_size := -1
		for group in groups:
			var level := board[int(group[0])]
			var better_level := level > best_level if strategy == "high_first" else level < best_level
			if better_level:
				best = [group]
				best_level = level
				best_size = group.size()
			elif level == best_level:
				if group.size() > best_size:
					best = [group]
					best_size = group.size()
				elif group.size() == best_size:
					best.append(group)
		return best[selection_rng.randi_range(0, best.size() - 1)]


	func _compact_and_refill() -> void:
		var grid_size := int(settings["grid_size"])
		for x in range(grid_size):
			var values: Array[int] = []
			for y in range(grid_size):
				var value := board[y * grid_size + x]
				if value > 0:
					values.append(value)
			for y in range(grid_size):
				board[y * grid_size + x] = values[y] if y < values.size() else 0
		for x in range(grid_size):
			for y in range(grid_size):
				var cell_index := y * grid_size + x
				if board[cell_index] <= 0:
					board[cell_index] = _sample_refill_level(cell_index)
		refill_group_count_total += _find_groups().size()
		refill_cycle_count += 1


	func _cell_has_level_neighbor(cell_index: int, level: int) -> bool:
		var grid_size := int(settings["grid_size"])
		var cell_x: int = cell_index % grid_size
		var cell_y: int = floori(float(cell_index) / float(grid_size))
		for neighbor in [cell_index - grid_size, cell_index + grid_size, cell_index - 1, cell_index + 1]:
			if neighbor < 0 or neighbor >= board.size():
				continue
			var neighbor_x: int = neighbor % grid_size
			var neighbor_y: int = floori(float(neighbor) / float(grid_size))
			if absi(neighbor_x - cell_x) + absi(neighbor_y - cell_y) == 1 and board[neighbor] == level:
				return true
		return false


	func _dispatch_board_attack(source_level: int, result_level: int, merged: int) -> void:
		if attack_rule == "legacy":
			_dispatch_legacy_board_attack(source_level, result_level, merged)
			return
		var element_order := settings["element_order"] as Array
		var element_key := str(element_order[posmod(source_level - 1, element_order.size())])
		var element_index := _element_index_for_key(element_key)
		var tier := floori(float(source_level - 1) / float(element_order.size())) + 1
		var base_damage := float((settings["level_attack"] as Dictionary).get(result_level, 50))
		if element_index == 1:
			_dispatch_ice_multitarget_attack(base_damage, merged, tier)
			return
		if element_index == 2:
			_dispatch_lightning_bounce_attack(base_damage, merged, tier)
			return
		var attack_count := maxi(1, merged)
		var total_damage := base_damage * float(maxi(1, merged - 1))
		var single_damage := total_damage / float(attack_count)
		board_theoretical_damage += total_damage
		_push_event(time, EVENT_COMBO_SHOT, {
			"remaining": attack_count,
			"focus_target": -1,
			"damage": single_damage,
			"element": element_index,
			"tier": tier,
			"params": _element_params(element_index, tier),
			"source": "board",
			"merge_size": merged,
		})


	func _dispatch_ice_multitarget_attack(base_damage: float, merged: int, tier: int) -> void:
		var target_count := maxi(1, merged - 1)
		var targets := _get_front_targets(target_count)
		var params := _element_params(1, tier)
		board_theoretical_damage += base_damage * float(target_count)
		for index in range(targets.size()):
			if not front_focus_started.has(targets[index]):
				front_focus_started[targets[index]] = time
			_push_event(
				time
					+ float(settings.get("merge_projectile_duration", 0.14))
					+ float(index) * float(settings.get("multi_shot_stagger", 0.10)),
				EVENT_HIT,
				{
					"target": targets[index],
					"damage": base_damage,
					"element": 1,
					"tier": tier,
					"params": params,
					"source": "board",
					"merge_size": merged,
					"ice_multitarget": true,
				}
			)


	func _dispatch_lightning_bounce_attack(base_damage: float, merged: int, tier: int) -> void:
		var targets := _get_front_targets(1)
		var extra_merges := maxi(0, merged - 2)
		var damage := base_damage * (
			1.0
				+ float(extra_merges)
				* float(settings.get("lightning_damage_per_extra_merge", 0.20))
		)
		var params := _element_params(2, tier)
		params["chain_count"] = maxi(
			0,
			int(params.get("chain_count", 0))
				+ extra_merges * int(settings.get("lightning_bounces_per_extra_merge", 1))
		)
		params["chain_damage_ratio"] = clampf(
			float(params.get("chain_damage_ratio", 0.5))
				+ float(extra_merges)
				* float(settings.get("lightning_retention_per_extra_merge", 0.05)),
			0.0,
			float(settings.get("lightning_max_retention", 0.90))
		)
		var potential_damage := damage
		var hop_damage := damage
		for _hop in range(int(params.get("chain_count", 0))):
			hop_damage *= float(params.get("chain_damage_ratio", 0.5))
			potential_damage += hop_damage
		board_theoretical_damage += potential_damage
		if targets.is_empty():
			return
		var target_id := int(targets[0])
		if not front_focus_started.has(target_id):
			front_focus_started[target_id] = time
		_push_event(
			time + float(settings.get("merge_projectile_duration", 0.14)),
			EVENT_HIT,
			{
				"target": target_id,
				"damage": damage,
				"element": 2,
				"tier": tier,
				"params": params,
				"source": "board",
				"merge_size": merged,
			}
		)


	func _dispatch_legacy_board_attack(source_level: int, result_level: int, merged: int) -> void:
		if alive_ids.is_empty():
			return
		var element_order := settings["element_order"] as Array
		var element_key := str(element_order[posmod(source_level - 1, element_order.size())])
		var element_index := _element_index_for_key(element_key)
		var tier := floori(float(source_level - 1) / float(element_order.size())) + 1
		var base_damage := float((settings["level_attack"] as Dictionary).get(result_level, 50))
		var target_count := maxi(1, merged - 1)
		var targets := _get_front_targets(target_count)
		var params := _element_params(element_index, tier)
		board_theoretical_damage += base_damage * float(targets.size())
		for index in range(targets.size()):
			if not front_focus_started.has(targets[index]):
				front_focus_started[targets[index]] = time
			_push_event(time + 0.14 + float(index) * 0.10, EVENT_HIT, {
				"target": targets[index], "damage": base_damage, "element": element_index,
				"tier": tier, "params": params, "source": "board", "legacy": true, "merge_size": merged,
			})


	func _element_index_for_key(element_key: String) -> int:
		match element_key:
			"ice":
				return 1
			"lightning":
				return 2
			"critical":
				return 3
			"fire":
				return 4
			_:
				return 0


	func _process_combo_shot(data: Dictionary) -> void:
		if done or int(data.get("remaining", 0)) <= 0:
			return
		var target_id := int(data.get("focus_target", -1))
		if not _ensure_monster_current(target_id):
			var targets := _get_front_targets(1)
			if targets.is_empty():
				return
			target_id = targets[0]
		if not front_focus_started.has(target_id):
			front_focus_started[target_id] = time
		var hit_data := data.duplicate(true)
		hit_data["target"] = target_id
		hit_data["focus_target"] = target_id
		hit_data["combo_focus"] = true
		_push_event(time + float(settings.get("merge_projectile_duration", 0.14)), EVENT_HIT, hit_data)


	func _element_params(element_index: int, tier: int) -> Dictionary:
		var effects := settings["element_effect"] as Dictionary
		var base := effects.get(element_index, {}) as Dictionary
		var step := float(tier - 1)
		match element_index:
			0:
				return {"dps_ratio": float(base.get("dps_ratio", 0.20)) + float(base.get("dps_ratio_per_tier", 0.05)) * step,
					"duration": float(base.get("duration", 3.0)) + float(base.get("duration_per_tier", 0.3)) * step}
			1:
				return {"slow_percent": float(base.get("slow_percent", 0.25)) + float(base.get("slow_percent_per_tier", 0.04)) * step,
					"duration": float(base.get("duration", 2.0)) + float(base.get("duration_per_tier", 0.25)) * step}
			2:
				return {"chain_count": int(base.get("chain_count", 1)) + floori(step / float(base.get("chain_count_per_tiers", 2))),
					"chain_damage_ratio": float(base.get("chain_damage_ratio", 0.50)) + float(base.get("chain_damage_ratio_per_tier", 0.05)) * step}
			3:
				return {"crit_chance": clampf(float(base.get("crit_chance", 0.25)) + float(base.get("crit_chance_per_tier", 0.05)) * step, 0.0, 1.0),
					"crit_multiplier": float(base.get("crit_multiplier", 2.0))}
			4:
				var splash_ratio := float(base.get("splash_damage_ratio", 0.30)) + float(base.get("splash_damage_ratio_per_tier", 0.04)) * step
				return {"duration": float(base.get("duration", 2.0)) + float(base.get("duration_per_tier", 0.2)) * step,
					"splash_radius": float(base.get("splash_radius", 70.0)) + float(base.get("splash_radius_per_tier", 8.0)) * step,
					"splash_damage_ratio": splash_ratio, "dps_ratio": splash_ratio * 0.5}
		return {}


	func _process_crystal_event() -> void:
		if done:
			return
		if time < paused_until:
			_push_event(paused_until, EVENT_CRYSTAL, {})
			return
		var targets := _get_front_targets(1)
		if not targets.is_empty():
			var base_damage := float((settings["level_attack"] as Dictionary).get(crystal_level, 50))
			var damage := float(roundi(base_damage * float(settings["crystal_damage_ratio"])))
			_push_event(time + 0.14, EVENT_HIT, {"target": targets[0], "damage": damage, "element": -1, "tier": crystal_level, "params": {}, "source": "crystal"})
		_push_event(time + float(settings["crystal_attack_interval"]), EVENT_CRYSTAL, {})


	func _process_hit(data: Dictionary) -> void:
		var target_id := int(data["target"])
		var is_combo := bool(data.get("combo_focus", false))
		if not _ensure_monster_current(target_id):
			if not is_combo:
				return
			var replacement := _get_front_targets(1)
			if replacement.is_empty():
				return
			target_id = replacement[0]
			if not front_focus_started.has(target_id):
				front_focus_started[target_id] = time
		var damage := float(data["damage"])
		var element := int(data["element"])
		var params := data["params"] as Dictionary
		if element == 3 and crit_rng.randf() < float(params.get("crit_chance", 0.0)):
			damage *= float(params.get("crit_multiplier", 2.0))
		var hit_progress := float(monsters[target_id]["progress"])
		var hp_before := float(monsters[target_id]["hp"])
		var dealt := _apply_damage(target_id, damage, str(data["source"]))
		if str(data["source"]) == "board":
			board_effective_damage += dealt
			board_overkill_damage += maxf(0.0, damage - hp_before)
			var merge_bucket := mini(6, maxi(2, int(data.get("merge_size", 2))))
			merge_damage_by_size[merge_bucket] = float(merge_damage_by_size.get(merge_bucket, 0.0)) + dealt
		if element == 2 and not bool(data.get("lightning_chain", false)):
			_schedule_lightning_chain(target_id, damage, params, data)
		if not _is_alive(target_id):
			if element == 4:
				_apply_fire_splash(target_id, hit_progress, damage, params)
			if is_combo:
				_schedule_next_combo_shot(data, -1)
			return
		match element:
			0:
				_apply_status(target_id, "poison", damage * float(params.get("dps_ratio", 0.0)), float(params.get("duration", 0.0)), 0.0)
			1:
				_apply_status(target_id, "freeze", 0.0, float(params.get("duration", 0.0)), float(params.get("slow_percent", 0.0)))
			4:
				_apply_status(target_id, "burn", damage * float(params.get("dps_ratio", 0.0)), float(params.get("duration", 0.0)), 0.0)
				_apply_fire_splash(target_id, hit_progress, damage, params)
		if is_combo:
			_schedule_next_combo_shot(data, target_id)


	func _schedule_lightning_chain(primary_id: int, damage: float, params: Dictionary, source_data: Dictionary) -> void:
		var chain_count := maxi(0, int(params.get("chain_count", 0)))
		var retention := clampf(float(params.get("chain_damage_ratio", 0.5)), 0.0, 1.0)
		if chain_count <= 0 or retention <= 0.0:
			return
		var candidates := _get_front_targets(chain_count + 1)
		var hop_damage := damage
		var hop_index := 0
		for candidate_id in candidates:
			if candidate_id == primary_id:
				continue
			hop_damage *= retention
			hop_index += 1
			_push_event(time + float(hop_index) / 15.0, EVENT_HIT, {
				"target": candidate_id,
				"damage": hop_damage,
				"element": 2,
				"tier": int(source_data.get("tier", 1)),
				"params": params,
				"source": str(source_data.get("source", "board")),
				"merge_size": int(source_data.get("merge_size", 2)),
				"lightning_chain": true,
			})
			if hop_index >= chain_count:
				break


	func _schedule_next_combo_shot(data: Dictionary, focus_target: int) -> void:
		var remaining := int(data.get("remaining", 1)) - 1
		if remaining <= 0:
			return
		var next_data := data.duplicate(true)
		next_data["remaining"] = remaining
		next_data["focus_target"] = focus_target
		next_data.erase("target")
		next_data.erase("combo_focus")
		_push_event(time + float(settings.get("merge_shot_interval", 0.05)), EVENT_COMBO_SHOT, next_data)


	func _apply_fire_splash(primary_id: int, hit_progress: float, damage: float, params: Dictionary) -> void:
		var radius := float(params.get("splash_radius", 0.0))
		var ratio := float(params.get("splash_damage_ratio", 0.0))
		if radius <= 0.0 or ratio <= 0.0:
			return
		var hit_pos := _position_at_progress(hit_progress)
		var snapshot := alive_ids.duplicate()
		for target_id in snapshot:
			if target_id == primary_id or not _ensure_monster_current(target_id):
				continue
			var target_pos := _position_at_progress(float(monsters[target_id]["progress"]))
			if hit_pos.distance_to(target_pos) <= radius:
				_apply_damage(target_id, damage * ratio, "board")
				if _is_alive(target_id):
					_apply_status(target_id, "burn", damage * float(params.get("dps_ratio", 0.0)), float(params.get("duration", 0.0)), 0.0)


	func _apply_status(target_id: int, status: String, dps: float, duration: float, slow: float) -> void:
		if not _ensure_monster_current(target_id):
			return
		var monster := monsters[target_id]
		match status:
			"poison":
				monster["poison_dps"] = dps
				monster["poison_end"] = time + duration
			"burn":
				monster["burn_dps"] = dps
				monster["burn_end"] = time + duration
			"freeze":
				monster["freeze_slow"] = slow
				monster["freeze_end"] = time + duration
		_schedule_monster_state(target_id)


	func _start_wave(wave_index: int) -> void:
		if done or wave_index >= (settings["waves"] as Array).size():
			return
		current_wave = wave_index
		wave_transition_pending = false
		var wave := (settings["waves"] as Array)[wave_index] as Dictionary
		var queue: Array[String] = []
		for monster_type in ["small", "medium", "large"]:
			for _index in range(int(wave.get(monster_type, 0))):
				queue.append(monster_type)
		var wave_rng := RandomNumberGenerator.new()
		wave_rng.seed = seed_value * 101 + wave_index * 7919 + 13
		for index in range(queue.size() - 1, 0, -1):
			var swap_index := wave_rng.randi_range(0, index)
			var temp := queue[index]
			queue[index] = queue[swap_index]
			queue[swap_index] = temp
		spawn_remaining = queue.size()
		wave_alive = 0
		var spawn_interval := float(wave.get("spawn_interval", 1.0))
		var pattern := [1, 2, 3, 4]
		var cursor := time
		var queue_index := 0
		var pattern_index := 0
		while queue_index < queue.size():
			var batch_size := mini(int(pattern[pattern_index]), queue.size() - queue_index)
			for member in range(batch_size):
				_push_event(cursor + float(member) * 0.08, EVENT_SPAWN, {"monster_type": queue[queue_index]})
				queue_index += 1
			cursor += float(maxi(0, batch_size - 1)) * 0.08 + spawn_interval
			pattern_index = (pattern_index + 1) % pattern.size()


	func _spawn_monster(monster_type: String) -> void:
		var wave := (settings["waves"] as Array)[current_wave] as Dictionary
		var config := ((settings["monster_config"] as Dictionary).get(monster_type, {}) as Dictionary)
		var max_hp := float(config.get("hp", 5.0)) * float(wave.get("hp_multiplier", 1.0))
		var monster_id := monsters.size()
		var monster := {
			"id": monster_id, "type": monster_type, "alive": true,
			"hp": max_hp, "max_hp": max_hp,
			"speed": float(config.get("speed", 80.0)),
			"durability": int(config.get("durability_damage", 1)),
			"progress": 0.0, "last_time": time,
			"poison_dps": 0.0, "poison_end": -1.0,
			"burn_dps": 0.0, "burn_end": -1.0,
			"freeze_slow": 0.0, "freeze_end": -1.0,
			"state_version": 0, "alive_index": alive_ids.size(),
		}
		monsters.append(monster)
		alive_ids.append(monster_id)
		spawn_remaining -= 1
		wave_alive += 1
		spawned += 1
		spawn_order_hash = hash([spawn_order_hash, monster_type])
		_schedule_monster_state(monster_id)
		_check_wave_clear()


	func _process_monster_state(data: Dictionary) -> void:
		var target_id := int(data["target"])
		if not _is_alive(target_id):
			return
		var monster := monsters[target_id]
		if int(data["version"]) != int(monster["state_version"]):
			return
		_sync_monster(monster, time)
		if float(monster["hp"]) <= 0.00001:
			_kill_monster(target_id)
			return
		if float(monster["progress"]) >= float(settings["goal_progress"]) - 0.000001:
			_leak_monster(target_id)
			return
		_clear_expired_statuses(monster)
		_schedule_monster_state(target_id)


	func _schedule_monster_state(target_id: int) -> void:
		if not _is_alive(target_id):
			return
		var monster := monsters[target_id]
		_sync_monster(monster, time)
		monster["state_version"] = int(monster["state_version"]) + 1
		var next_time := INF
		var speed_multiplier := 1.0 - float(monster["freeze_slow"]) if float(monster["freeze_end"]) > time else 1.0
		var progress_speed := float(monster["speed"]) * maxf(0.1, speed_multiplier) / float(settings["path_length"])
		if progress_speed > 0.0:
			next_time = minf(next_time, time + (float(settings["goal_progress"]) - float(monster["progress"])) / progress_speed)
		var dps := 0.0
		if float(monster["poison_end"]) > time:
			dps += float(monster["poison_dps"])
			next_time = minf(next_time, float(monster["poison_end"]))
		if float(monster["burn_end"]) > time:
			dps += float(monster["burn_dps"])
			next_time = minf(next_time, float(monster["burn_end"]))
		if float(monster["freeze_end"]) > time:
			next_time = minf(next_time, float(monster["freeze_end"]))
		if dps > 0.0:
			next_time = minf(next_time, time + float(monster["hp"]) / dps)
		if next_time < INF:
			_push_event(maxf(time + 0.000001, next_time), EVENT_MONSTER_STATE, {"target": target_id, "version": monster["state_version"]})


	func _sync_monster(monster: Dictionary, target_time: float) -> void:
		var cursor := float(monster["last_time"])
		if target_time <= cursor:
			return
		while cursor < target_time - 0.0000001:
			var segment_end := target_time
			for key in ["poison_end", "burn_end", "freeze_end"]:
				var end_time := float(monster[key])
				if end_time > cursor + 0.0000001:
					segment_end = minf(segment_end, end_time)
			var delta := maxf(0.0, segment_end - cursor)
			var dps := 0.0
			if float(monster["poison_end"]) > cursor:
				dps += float(monster["poison_dps"])
			if float(monster["burn_end"]) > cursor:
				dps += float(monster["burn_dps"])
			if dps > 0.0:
				var dealt := minf(float(monster["hp"]), dps * delta)
				monster["hp"] = float(monster["hp"]) - dealt
				status_damage += dealt
			var slow := float(monster["freeze_slow"]) if float(monster["freeze_end"]) > cursor else 0.0
			monster["progress"] = float(monster["progress"]) + float(monster["speed"]) * maxf(0.1, 1.0 - slow) / float(settings["path_length"]) * delta
			cursor = segment_end
		monster["last_time"] = target_time


	func _clear_expired_statuses(monster: Dictionary) -> void:
		if float(monster["poison_end"]) <= time:
			monster["poison_end"] = -1.0
			monster["poison_dps"] = 0.0
		if float(monster["burn_end"]) <= time:
			monster["burn_end"] = -1.0
			monster["burn_dps"] = 0.0
		if float(monster["freeze_end"]) <= time:
			monster["freeze_end"] = -1.0
			monster["freeze_slow"] = 0.0


	func _ensure_monster_current(target_id: int) -> bool:
		if not _is_alive(target_id):
			return false
		var monster := monsters[target_id]
		_sync_monster(monster, time)
		if float(monster["hp"]) <= 0.00001:
			_kill_monster(target_id)
			return false
		if float(monster["progress"]) >= float(settings["goal_progress"]):
			_leak_monster(target_id)
			return false
		return true


	func _get_front_targets(count: int) -> Array[int]:
		var ranked: Array = []
		var snapshot := alive_ids.duplicate()
		for target_id in snapshot:
			if not _ensure_monster_current(target_id):
				continue
			var progress := float(monsters[target_id]["progress"])
			var inserted := false
			for index in range(ranked.size()):
				if progress > float(ranked[index][0]):
					ranked.insert(index, [progress, target_id])
					inserted = true
					break
			if not inserted:
				ranked.append([progress, target_id])
			if ranked.size() > count:
				ranked.pop_back()
		var result: Array[int] = []
		for entry in ranked:
			result.append(int(entry[1]))
		return result


	func _apply_damage(target_id: int, amount: float, source: String) -> float:
		if not _ensure_monster_current(target_id):
			return 0.0
		var monster := monsters[target_id]
		var dealt := minf(float(monster["hp"]), maxf(0.0, amount))
		monster["hp"] = float(monster["hp"]) - dealt
		if source == "crystal":
			crystal_damage += dealt
		else:
			board_damage += dealt
		if float(monster["hp"]) <= 0.00001:
			_kill_monster(target_id)
		else:
			_schedule_monster_state(target_id)
		return dealt


	func _kill_monster(target_id: int) -> void:
		if not _is_alive(target_id):
			return
		var monster := monsters[target_id]
		monster["alive"] = false
		killed += 1
		death_progress.append(clampf(float(monster["progress"]), 0.0, 1.0))
		if front_focus_started.has(target_id):
			front_kill_time_total += maxf(0.0, time - float(front_focus_started[target_id]))
			front_kill_time_count += 1
			front_focus_started.erase(target_id)
		_remove_alive_id(monster)
		wave_alive -= 1
		_check_wave_clear()


	func _leak_monster(target_id: int) -> void:
		if not _is_alive(target_id):
			return
		var monster := monsters[target_id]
		monster["alive"] = false
		front_focus_started.erase(target_id)
		leaked += 1
		castle_remaining -= int(monster["durability"])
		_remove_alive_id(monster)
		wave_alive -= 1
		if castle_remaining <= 0:
			castle_remaining = 0
			done = true
			won = false
			return
		_check_wave_clear()


	func _remove_alive_id(monster: Dictionary) -> void:
		var index := int(monster["alive_index"])
		var last_id := alive_ids[-1]
		alive_ids[index] = last_id
		alive_ids.pop_back()
		if index < alive_ids.size():
			monsters[last_id]["alive_index"] = index
		monster["alive_index"] = -1


	func _check_wave_clear() -> void:
		if done or spawn_remaining > 0 or wave_alive > 0 or current_wave < 0 or wave_transition_pending:
			return
		waves_cleared = current_wave + 1
		if current_wave >= (settings["waves"] as Array).size() - 1:
			done = true
			won = true
			return
		wave_transition_pending = true
		paused_until = time + float(settings["inter_wave_delay"])
		_push_event(paused_until, EVENT_WAVE_START, {"wave": current_wave + 1})


	func _is_alive(target_id: int) -> bool:
		return target_id >= 0 and target_id < monsters.size() and bool(monsters[target_id].get("alive", false))


	func _position_at_progress(progress: float) -> Vector2:
		var points := settings["path_points"] as PackedVector2Array
		var distance := clampf(progress, 0.0, 1.0) * float(settings["path_length"])
		for index in range(points.size() - 1):
			var segment := points[index].distance_to(points[index + 1])
			if distance <= segment or index == points.size() - 2:
				return points[index].lerp(points[index + 1], clampf(distance / maxf(0.0001, segment), 0.0, 1.0))
			distance -= segment
		return points[-1]


	func _push_event(event_time: float, event_type: int, data: Dictionary) -> void:
		event_sequence += 1
		var entry := [event_time, event_sequence, event_type, data]
		events.append(entry)
		var index := events.size() - 1
		while index > 0:
			var parent := (index - 1) / 2
			if not _event_before(events[index], events[parent]):
				break
			var temp = events[parent]
			events[parent] = events[index]
			events[index] = temp
			index = parent


	func _pop_event() -> Array:
		var result: Array = events[0]
		var last = events.pop_back()
		if not events.is_empty():
			events[0] = last
			var index := 0
			while true:
				var left := index * 2 + 1
				var right := left + 1
				var smallest := index
				if left < events.size() and _event_before(events[left], events[smallest]):
					smallest = left
				if right < events.size() and _event_before(events[right], events[smallest]):
					smallest = right
				if smallest == index:
					break
				var temp = events[index]
				events[index] = events[smallest]
				events[smallest] = temp
				index = smallest
		return result


	func _event_before(first: Array, second: Array) -> bool:
		var first_time := float(first[0])
		var second_time := float(second[0])
		if not is_equal_approx(first_time, second_time):
			return first_time < second_time
		var first_priority := int(EVENT_PRIORITY.get(int(first[2]), 99))
		var second_priority := int(EVENT_PRIORITY.get(int(second[2]), 99))
		if first_priority != second_priority:
			return first_priority < second_priority
		return int(first[1]) < int(second[1])


	func _count_generated(counts: Dictionary) -> int:
		var total := 0
		for value in counts.values():
			total += int(value)
		return total


	func _board_signature() -> String:
		var parts := PackedStringArray()
		for value in board:
			parts.append(str(value))
		return ",".join(parts)


	func _array_percentile(values: Array[float], ratio: float) -> float:
		if values.is_empty():
			return 0.0
		var index := clampi(roundi(float(values.size() - 1) * ratio), 0, values.size() - 1)
		return values[index]
