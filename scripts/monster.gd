extends Control
class_name Monster

const MonsterViewScene := preload("res://scenes/combat/monster_view.tscn")

signal died(monster: Monster)
signal reached_goal(monster: Monster, durability_damage: int)
signal hp_changed(monster: Monster, hp: float, max_hp: float)
signal status_applied(monster: Monster, element: int, tier: int)
signal status_ended(monster: Monster, element: int)
signal status_ticked(monster: Monster, element: int)

var monster_type := "small"
var max_hp := 5.0
var hp := 5.0
var durability_damage := 1
var speed := 80.0
var alive := true
var reached := false
var path_progress := 0.0
var death_source := ""

# Structured status containers: {tier, duration, remaining, ...}
var poison_status: Dictionary = {}
var freeze_status: Dictionary = {}
var burn_status: Dictionary = {}
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


func get_path_anchor_offset() -> Vector2:
	# Keep the monster body centered on the road. The HP bar extends below
	# the body and must not pull the movement anchor upward.
	return Vector2(size.x * 0.5, _view._base_size * 0.5)


func update_movement(delta: float, total_path_length: float) -> void:
	if not alive or reached:
		return
	path_progress += (speed * get_speed_multiplier() / total_path_length) * delta
	if path_progress >= 0.995:
		path_progress = 1.0
		reached = true
		reached_goal.emit(self, durability_damage)


func apply_damage(amount: float, source: String = "normal") -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	_sync_view()
	hp_changed.emit(self, hp, max_hp)
	if hp <= 0.0:
		alive = false
		death_source = source
		died.emit(self)


func kill(source: String = "system") -> void:
	if not alive:
		return
	alive = false
	hp = 0.0
	death_source = source
	died.emit(self)


func get_speed_multiplier() -> float:
	var mult := 1.0
	if not freeze_status.is_empty():
		mult *= max(0.1, 1.0 - (freeze_status.get("slow_percent", 0.0) as float))
	return mult


func apply_element_effect(event: MergeAttackEvent, source: String = "normal") -> void:
	var params := event.effect_params
	var element: int = params["element"]
	var tier: int = params["tier"]
	var atk: float = event.damage
	match element:
		GameConfig.AttackElement.POISON:
			poison_status = {
				"tier": tier,
				"atk": atk,
				"duration": params["duration"],
				"remaining": params["duration"],
				"dps_ratio": params["dps_ratio"],
				"source": source,
			}
		GameConfig.AttackElement.FREEZE:
			freeze_status = {
				"tier": tier,
				"duration": params["duration"],
				"remaining": params["duration"],
				"slow_percent": params["slow_percent"],
			}
		GameConfig.AttackElement.FIRE:
			burn_status = {
				"tier": tier,
				"atk": atk,
				"duration": params["duration"],
				"remaining": params["duration"],
				"splash_radius": params.get("splash_radius", 0.0),
				"splash_damage_ratio": params.get("splash_damage_ratio", 0.0),
				"dps_ratio": params.get("dps_ratio", float(params.get("splash_damage_ratio", 0.0)) * 0.5),
				"source": source,
			}
		GameConfig.AttackElement.CRITICAL:
			return  # Critical is instant, no persistent status
		_:
			return
	status_applied.emit(self, element, tier)


func update_status(delta: float) -> void:
	var has_poison := not poison_status.is_empty()
	var has_burn := not burn_status.is_empty()

	if has_poison:
		poison_status["remaining"] = max(0.0, poison_status["remaining"] - delta)
		var atk: float = float(poison_status["atk"])
		var dps: float = atk * float(poison_status["dps_ratio"])
		hp = max(0.0, hp - dps * delta)
		_sync_view()
		hp_changed.emit(self, hp, max_hp)
		status_ticked.emit(self, GameConfig.AttackElement.POISON)
		if hp <= 0.0:
			alive = false
			death_source = str(poison_status.get("source", "normal"))
			died.emit(self)
			return
		if poison_status["remaining"] <= 0.0:
			status_ended.emit(self, GameConfig.AttackElement.POISON)
			poison_status.clear()

	if has_burn:
		burn_status["remaining"] = max(0.0, burn_status["remaining"] - delta)
		var atk: float = float(burn_status["atk"])
		var dps: float = atk * float(burn_status.get("dps_ratio", 0.0))
		hp = max(0.0, hp - dps * delta)
		_sync_view()
		hp_changed.emit(self, hp, max_hp)
		status_ticked.emit(self, GameConfig.AttackElement.FIRE)
		if hp <= 0.0:
			alive = false
			death_source = str(burn_status.get("source", "normal"))
			died.emit(self)
			return
		if burn_status["remaining"] <= 0.0:
			status_ended.emit(self, GameConfig.AttackElement.FIRE)
			burn_status.clear()

	if not freeze_status.is_empty():
		freeze_status["remaining"] = max(0.0, freeze_status["remaining"] - delta)
		if freeze_status["remaining"] <= 0.0:
			status_ended.emit(self, GameConfig.AttackElement.FREEZE)
			freeze_status.clear()

	_sync_view()


func is_alive() -> bool:
	return alive


func _sync_view() -> void:
	if _view and is_instance_valid(_view):
		_view.update_hp(hp, max_hp)
		_view.update_status(
			freeze_status.get("remaining", 0.0) if not freeze_status.is_empty() else 0.0,
			burn_status.get("remaining", 0.0) if not burn_status.is_empty() else 0.0,
			poison_status.get("remaining", 0.0) if not poison_status.is_empty() else 0.0
		)
