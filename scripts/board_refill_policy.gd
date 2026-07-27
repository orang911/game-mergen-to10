extends RefCounted
class_name BoardRefillPolicy

## Runtime refill policy shared by the real board and the balance simulator.
## Once the run reaches level 5, only the five levels ending at the historical
## maximum may be generated: 1..5, then 2..6, then 3..7, and so on.

const CURRENT_MAX_DROP_CAP := 0.05
const ACTIVE_LEVEL_MINIMUM := 0.03
const ACTIVE_LEVEL_MAXIMUM := 0.55
const WINDOW_PROGRESSION: Array[float] = [0.32, 0.28, 0.22, 0.13, 0.05]


static func get_base_weights(historical_highest: int, max_block_level: int = GameConfig.MAX_BLOCK_LEVEL) -> Array[float]:
	var highest := clampi(historical_highest, 1, max_block_level)
	if highest < 5:
		return [0.33, 0.34, 0.33]
	var weights: Array[float] = []
	weights.resize(highest)
	weights.fill(0.0)
	var minimum_level := maxi(1, highest - 4)
	for offset in range(5):
		weights[minimum_level + offset - 1] = WINDOW_PROGRESSION[offset]
	return weights


static func get_dynamic_analysis(historical_highest: int, values: Array[int], grid_size: int, cell_index: int) -> Dictionary:
	var highest := clampi(historical_highest, 1, GameConfig.MAX_BLOCK_LEVEL)
	var base := get_base_weights(highest)
	if highest < 5:
		var opening_scores: Array[float] = []
		opening_scores.resize(base.size())
		opening_scores.fill(0.0)
		return {"weights": base, "scores": opening_scores}
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
		score += float(int(after["groups"]) - int(before["groups"]))
		if component_size == 2 and level >= maxi(2, highest - 2):
			score += 1.0
		var fragmentation_change := int(after["fragments"]) - int(before["fragments"])
		if fragmentation_change > 0:
			score -= float(fragmentation_change) * 2.0
		elif fragmentation_change < 0:
			score += float(-fragmentation_change) * 0.5
		var level_ratio := float(_count_level(virtual_board, level)) / float(maxi(1, int(after["occupied"])))
		if level_ratio > 0.32:
			score -= 1.5 * clampf((level_ratio - 0.32) / 0.20, 0.0, 1.0)
		if int(after["empty"]) == 0:
			score += 5.0 if int(after["groups"]) > 0 else -5.0
		scores[index] = score
		raw_weights[index] = base[index] * exp(clampf(score / 2.0, -6.0, 6.0))
	var weights := _normalize_bounded_probabilities(raw_weights, base, highest - 1, CURRENT_MAX_DROP_CAP)
	return {"weights": weights, "scores": scores}


static func get_dynamic_weights(historical_highest: int, values: Array[int], grid_size: int, cell_index: int) -> Array[float]:
	return get_dynamic_analysis(historical_highest, values, grid_size, cell_index)["weights"] as Array[float]


static func sample_level(historical_highest: int, values: Array[int], grid_size: int, cell_index: int, roll: float) -> int:
	var weights := get_dynamic_weights(historical_highest, values, grid_size, cell_index)
	var cursor := 0.0
	for index in range(weights.size()):
		cursor += weights[index]
		if roll <= cursor:
			return index + 1
	return maxi(1, weights.size())


static func _board_quality(values: Array[int], grid_size: int) -> Dictionary:
	var occupied := 0
	var isolated := 0
	for cell_index in range(values.size()):
		if values[cell_index] <= 0:
			continue
		occupied += 1
		if not _cell_has_same_neighbor(values, grid_size, cell_index):
			isolated += 1
	return {
		"occupied": occupied,
		"empty": values.size() - occupied,
		"isolated": isolated,
		"groups": _find_groups(values, grid_size).size(),
		"fragments": _count_level_components(values, grid_size),
	}


static func _find_groups(values: Array[int], grid_size: int) -> Array[Array]:
	var groups: Array[Array] = []
	var visited := {}
	for start in range(values.size()):
		if values[start] <= 0 or visited.has(start):
			continue
		var level := values[start]
		var component: Array = []
		var queue: Array[int] = [start]
		visited[start] = true
		while not queue.is_empty():
			var cell: int = queue.pop_back()
			component.append(cell)
			for neighbor in _neighbors(cell, grid_size, values.size()):
				if not visited.has(neighbor) and values[neighbor] == level:
					visited[neighbor] = true
					queue.append(neighbor)
		if component.size() >= 2:
			groups.append(component)
	return groups


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
		for neighbor in _neighbors(cell, grid_size, values.size()):
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
			for neighbor in _neighbors(cell, grid_size, values.size()):
				if not visited.has(neighbor) and values[neighbor] == level:
					visited[neighbor] = true
					queue.append(neighbor)
	return component_count


static func _cell_has_same_neighbor(values: Array[int], grid_size: int, cell_index: int) -> bool:
	for neighbor in _neighbors(cell_index, grid_size, values.size()):
		if values[neighbor] == values[cell_index]:
			return true
	return false


static func _neighbors(cell_index: int, grid_size: int, cell_count: int) -> Array[int]:
	var result: Array[int] = []
	var cell_x: int = cell_index % grid_size
	var cell_y: int = floori(float(cell_index) / float(grid_size))
	for neighbor_value in [cell_index - grid_size, cell_index + grid_size, cell_index - 1, cell_index + 1]:
		var neighbor: int = int(neighbor_value)
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


static func _normalize_bounded_probabilities(raw: Array[float], fallback: Array[float], special_index: int, special_maximum: float) -> Array[float]:
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
			for index in active:
				raw[index] = fallback[index]
				raw_total += fallback[index]
		var clamp_index := -1
		var clamp_value := 0.0
		for index in active:
			var probability := remaining * raw[index] / raw_total
			var maximum := special_maximum if index == special_index else ACTIVE_LEVEL_MAXIMUM
			if probability < ACTIVE_LEVEL_MINIMUM:
				clamp_index = index
				clamp_value = ACTIVE_LEVEL_MINIMUM
				break
			if probability > maximum:
				clamp_index = index
				clamp_value = maximum
				break
		if clamp_index < 0:
			for index in active:
				result[index] = remaining * raw[index] / raw_total
			break
		result[clamp_index] = clamp_value
		remaining -= clamp_value
		active.erase(clamp_index)
	return result
