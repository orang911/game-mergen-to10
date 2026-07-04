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
	var left := board_pos.x - margin
	var top := board_pos.y - margin
	var right := board_pos.x + board_size.x + margin
	var bottom := board_pos.y + board_size.y + margin
	var r := _corner_radius

	# 8 corners matching BattlePathView octagon: 4 straights + 3 chamfers + left partial
	_points.clear()
	_segment_lengths.clear()

	# 0: entry → top-right (straight, top edge)
	_points.append(Vector2(left + r, top))
	# 1: top-right chamfer → right edge
	_points.append(Vector2(right - r, top))
	# 2: right-top → right-bottom (straight, right edge)
	_points.append(Vector2(right, top + r))
	# 3: bottom-right chamfer → bottom edge
	_points.append(Vector2(right, bottom - r))
	# 4: bottom-right → bottom-left (straight, bottom edge)
	_points.append(Vector2(right - r, bottom))
	# 5: bottom-left chamfer → left edge
	_points.append(Vector2(left + r, bottom))
	# 6: left-bottom → left-mid (straight, left edge)
	_points.append(Vector2(left, bottom - r))
	# 7: endpoint (on left edge, before completing the loop)
	_points.append(Vector2(left, top + end_offset))

	_total_length = 0.0
	_segment_lengths.clear()
	for i in range(_points.size() - 1):
		var seg_len := _points[i].distance_to(_points[i + 1])
		_segment_lengths.append(seg_len)
		_total_length += seg_len


func get_spawn_position() -> Vector2:
	if _points.is_empty():
		return Vector2(board_pos.x - margin + _corner_radius, board_pos.y - margin)
	return _points[0]


func get_goal_progress_ratio() -> float:
	if _total_length <= 0.0:
		return 1.0
	return (_total_length - 4.0) / _total_length


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
