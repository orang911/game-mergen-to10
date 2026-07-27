extends Node
class_name CastleSystem

signal durability_changed(current: int, max_value: int)
signal castle_destroyed

var max_durability := GameConfig.MAX_CASTLE_DURABILITY
var durability := GameConfig.MAX_CASTLE_DURABILITY
var _view: Node
var _destroyed_emitted := false

func setup(existing_view: Node = null) -> void:
	_view = existing_view
	_update_ui()

func reset() -> void:
	durability = max_durability
	_destroyed_emitted = false
	_update_ui()

func damage(amount: int) -> void:
	durability = max(0, durability - amount)
	if _view and is_instance_valid(_view) and _view.has_method("play_damage"):
		_view.play_damage(amount)
	_update_ui()
	_emit_destroyed_if_needed()

func heal(amount: int) -> void:
	durability = min(max_durability, durability + amount)
	_update_ui()

func layout(anchor_position: Vector2) -> void:
	if _view and is_instance_valid(_view) and _view is Control:
		(_view as Control).position = anchor_position

func get_durability() -> int:
	return durability

func _update_ui() -> void:
	if _view and is_instance_valid(_view) and _view.has_method("update_durability"):
		_view.update_durability(durability, max_durability)
	durability_changed.emit(durability, max_durability)

func _emit_destroyed_if_needed() -> void:
	if durability <= 0 and not _destroyed_emitted:
		_destroyed_emitted = true
		castle_destroyed.emit()
