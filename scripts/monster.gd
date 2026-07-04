extends Control
class_name Monster

const MonsterViewScene := preload("res://scenes/combat/monster_view.tscn")

signal died(monster: Monster)
signal reached_goal(monster: Monster, durability_damage: int)
signal hp_changed(monster: Monster, hp: float, max_hp: float)

var monster_type := "small"
var max_hp := 5.0
var hp := 5.0
var durability_damage := 1
var speed := 80.0
var alive := true
var reached := false
var path_progress := 0.0

var freeze_timer := 0.0
var burn_timer := 0.0
var poison_timer := 0.0
var _burn_dps := 3.0
var _poison_dps := 1.2
var _view: MonsterView


func setup(config: Dictionary) -> void:
	monster_type = config.get("type", "small")
	max_hp = float(config.get("hp", 5))
	hp = max_hp
	durability_damage = config.get("durability_damage", 1)
	speed = config.get("speed", 80.0)

	_view = MonsterViewScene.instantiate() as MonsterView
	if _view == null:
		_view = MonsterView.new()
	_view.name = "MonsterView"
	add_child(_view)
	_view.configure(config)
	custom_minimum_size = _view.size
	size = _view.size
	pivot_offset = Vector2(size.x * 0.5, _view._base_size)


func update_movement(delta: float, total_path_length: float) -> void:
	if not alive or reached:
		return
	path_progress += (speed * get_speed_multiplier() / total_path_length) * delta
	if path_progress >= 0.995:
		path_progress = 1.0
		reached = true
		reached_goal.emit(self, durability_damage)


func apply_damage(amount: float) -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	_sync_view()
	hp_changed.emit(self, hp, max_hp)
	if hp <= 0.0:
		alive = false
		died.emit(self)


func kill() -> void:
	if not alive:
		return
	alive = false
	hp = 0.0
	died.emit(self)


func get_speed_multiplier() -> float:
	if freeze_timer > 0.0:
		return 0.0
	return 1.0


func apply_status(element: int) -> void:
	match element:
		GameConfig.AttackElement.FIRE:
			burn_timer = 1.5
		GameConfig.AttackElement.FREEZE:
			freeze_timer = 1.0
		GameConfig.AttackElement.LIGHTNING:
			pass
		GameConfig.AttackElement.POISON:
			poison_timer = 3.0


func update_status(delta: float) -> void:
	if freeze_timer > 0.0:
		freeze_timer = max(0.0, freeze_timer - delta)
	if burn_timer > 0.0:
		burn_timer = max(0.0, burn_timer - delta)
		hp = max(0.0, hp - _burn_dps * delta)
		_sync_view()
		hp_changed.emit(self, hp, max_hp)
		if hp <= 0.0:
			modulate = Color(1.0, 0.3, 0.1, 1.0)
			alive = false
			died.emit(self)
			return
	if poison_timer > 0.0:
		poison_timer = max(0.0, poison_timer - delta)
		hp = max(0.0, hp - _poison_dps * delta)
		_sync_view()
		hp_changed.emit(self, hp, max_hp)
		if hp <= 0.0:
			modulate = Color(0.3, 0.8, 0.2, 1.0)
			alive = false
			died.emit(self)
			return
	_sync_view()


func is_alive() -> bool:
	return alive


func _sync_view() -> void:
	if _view and is_instance_valid(_view):
		_view.update_hp(hp, max_hp)
		_view.update_status(freeze_timer, burn_timer, poison_timer)
