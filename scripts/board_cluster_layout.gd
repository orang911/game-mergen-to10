extends RefCounted
class_name BoardClusterLayout

const MAX_IMPROVEMENT_PASSES := 64


static func build_clustered_levels(source_levels: Array[int], grid_size: int) -> Array[int]:
	var safe_size := maxi(1, grid_size)
	var cell_count := safe_size * safe_size
	var levels: Array[int] = source_levels.duplicate()
	levels.sort()
	if levels.size() > cell_count:
		levels.resize(cell_count)

	var layout: Array[int] = []
	layout.resize(cell_count)
	layout.fill(-1)
	var path := _serpentine_path(safe_size)
	for index in range(levels.size()):
		var site: Vector2i = path[index]
		layout[_site_index(site, safe_size)] = levels[index]

	_improve_equal_adjacency(layout, safe_size)
	return layout


static func count_equal_neighbors(layout: Array[int], grid_size: int) -> int:
	var score := 0
	for y in range(grid_size):
		for x in range(grid_size):
			var value := layout[y * grid_size + x]
			if value < 0:
				continue
			if x + 1 < grid_size and layout[y * grid_size + x + 1] == value:
				score += 1
			if y + 1 < grid_size and layout[(y + 1) * grid_size + x] == value:
				score += 1
	return score


static func _serpentine_path(grid_size: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(grid_size):
		if y % 2 == 0:
			for x in range(grid_size):
				result.append(Vector2i(x, y))
		else:
			for x in range(grid_size - 1, -1, -1):
				result.append(Vector2i(x, y))
	return result


static func _improve_equal_adjacency(layout: Array[int], grid_size: int) -> void:
	var current_score := count_equal_neighbors(layout, grid_size)
	for _pass in range(MAX_IMPROVEMENT_PASSES):
		var best_score := current_score
		var best_first := -1
		var best_second := -1
		for first in range(layout.size()):
			for second in range(first + 1, layout.size()):
				if layout[first] == layout[second]:
					continue
				_swap(layout, first, second)
				var candidate_score := count_equal_neighbors(layout, grid_size)
				_swap(layout, first, second)
				if candidate_score > best_score:
					best_score = candidate_score
					best_first = first
					best_second = second
		if best_first < 0:
			break
		_swap(layout, best_first, best_second)
		current_score = best_score


static func _swap(values: Array[int], first: int, second: int) -> void:
	var temporary := values[first]
	values[first] = values[second]
	values[second] = temporary


static func _site_index(site: Vector2i, grid_size: int) -> int:
	return site.y * grid_size + site.x
