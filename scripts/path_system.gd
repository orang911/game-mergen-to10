extends Node
class_name PathSystem

signal path_rebuilt

var board_pos := Vector2.ZERO
var board_size := Vector2.ZERO
var margin := 76.0
var end_offset := 64.0
var _total_length := 0.0
var _corner_radius := 64.0
var _points: PackedVector2Array
var _segment_lengths: Array[float] = []


func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2) -> void:
	board_pos = new_board_pos
	board_size = new_board_size
	_build_path()
	path_rebuilt.emit()


func _build_path() -> void:
	_points = GameConfig.get_path_points_for_board(board_pos, board_size)
	_segment_lengths.clear()

	_total_length = 0.0
	_segment_lengths.clear()
	for i in range(_points.size() - 1):
		var seg_len := _points[i].distance_to(_points[i + 1])
		_segment_lengths.append(seg_len)
		_total_length += seg_len


func get_spawn_position() -> Vector2:
	if _points.is_empty():
		var fallback_points := GameConfig.get_path_points_for_board(board_pos, board_size)
		if not fallback_points.is_empty():
			return fallback_points[0]
		return board_pos
	return _points[0]


func get_goal_progress_ratio() -> float:
	if _total_length <= 0.0:
		return 1.0
	# The path artwork ends inside the crystal artwork.  Keep this final span as
	# the crystal's visual footprint: monsters attack at its outer boundary
	# instead of walking through the tower to the path endpoint.
	return clampf((_total_length - end_offset) / _total_length, 0.0, 1.0)


func position_at_progress(progress: float) -> Vector2:
	if _total_length <= 0.0 or _points.size() < 2:
		return get_spawn_position()
	var dist := progress * _total_length
	for i in range(_segment_lengths.size()):
		if dist <= _segment_lengths[i] or i == _segment_lengths.size() - 1:
			var t: float = dist / _segment_lengths[i] if _segment_lengths[i] > 0.0 else 0.0
			t = clampf(t, 0.0, 1.0)
			return _points[i].lerp(_points[i + 1], t)
		dist -= _segment_lengths[i]
	return _points[-1]


func get_total_length() -> float:
	return _total_length
