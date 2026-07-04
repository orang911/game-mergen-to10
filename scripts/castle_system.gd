extends Node
class_name CastleSystem

const CastleViewScene := preload("res://scenes/combat/castle_view.tscn")

signal durability_changed(current: int, max_value: int)
signal castle_destroyed

var max_durability := GameConfig.MAX_CASTLE_DURABILITY
var durability := GameConfig.MAX_CASTLE_DURABILITY
var _view: CastleView
var _destroyed_emitted := false

func setup(parent: Control, existing_view: CastleView = null) -> void:
	if existing_view:
		_view = existing_view
	elif parent:
		_view = CastleViewScene.instantiate() as CastleView
		parent.add_child(_view)
	_update_ui()

func reset() -> void:
	durability = max_durability
	_destroyed_emitted = false
	_update_ui()

func damage(amount: int) -> void:
	durability = max(0, durability - amount)
	if _view and is_instance_valid(_view):
		_view.play_damage(amount)
	_update_ui()
	_emit_destroyed_if_needed()

func heal(amount: int) -> void:
	durability = min(max_durability, durability + amount)
	_update_ui()

func layout(anchor_position: Vector2) -> void:
	if _view and is_instance_valid(_view):
		_view.position = anchor_position

func get_durability() -> int:
	return durability

func _update_ui() -> void:
	if _view and is_instance_valid(_view):
		_view.update_durability(durability, max_durability)
	durability_changed.emit(durability, max_durability)

func _emit_destroyed_if_needed() -> void:
	if durability <= 0 and not _destroyed_emitted:
		_destroyed_emitted = true
		castle_destroyed.emit()
