extends Node
class_name MonsterSystem

signal monster_spawned(monster: Monster)
signal monster_died(monster: Monster)
signal monster_reached_goal(monster: Monster, durability_damage: int)
signal all_monsters_cleared

var monsters: Array[Monster] = []
var path_system: PathSystem
var parent_layer: Control
var running := false
var _pending_remove: Array[Monster] = []
var _delayed_free: Array[Monster] = []

func setup(p_path: PathSystem, p_parent: Control) -> void:
	path_system = p_path
	parent_layer = p_parent

func start() -> void:
	running = true

func stop() -> void:
	running = false

func reset() -> void:
	_pending_remove.clear()
	for monster in monsters:
		if is_instance_valid(monster):
			monster.alive = false
			monster.queue_free()
	monsters.clear()
	for monster in _delayed_free:
		if is_instance_valid(monster):
			monster.queue_free()
	_delayed_free.clear()

func spawn_monster(monster_type: String) -> Monster:
	var config: Dictionary = GameConfig.MONSTER_CONFIG.get(monster_type, GameConfig.MONSTER_CONFIG["small"]).duplicate()
	config["type"] = monster_type

	var monster := Monster.new()
	monster.setup(config)
	monster.path_progress = 0.0
	monster.position = path_system.get_spawn_position() - monster.size * 0.5
	monster.died.connect(_on_monster_died)
	monster.reached_goal.connect(_on_monster_reached_goal)
	parent_layer.add_child(monster)
	monsters.append(monster)
	monster_spawned.emit(monster)
	return monster

func get_alive_monsters() -> Array[Monster]:
	var result: Array[Monster] = []
	for monster in monsters:
		if is_instance_valid(monster) and monster.is_alive() and not monster.reached:
			result.append(monster)
	return result

func get_front_monsters(count: int) -> Array[Monster]:
	var alive := get_alive_monsters()
	alive.sort_custom(func(a: Monster, b: Monster): return a.path_progress > b.path_progress)
	var result: Array[Monster] = []
	for i in range(min(count, alive.size())):
		result.append(alive[i])
	return result

func _process(delta: float) -> void:
	if not running:
		return
	var total_length := path_system.get_total_length()
	if total_length <= 0.0:
		return
	for monster in monsters:
		if not is_instance_valid(monster):
			_pending_remove.append(monster)
			continue
		if monster.is_alive() and not monster.reached:
			monster.update_status(delta)
			monster.update_movement(delta, total_length)
			monster.position = path_system.position_at_progress(monster.path_progress) - monster.size * 0.5
		elif monster.reached:
			_pending_remove.append(monster)
	for monster in _pending_remove:
		_remove_monster(monster)
	_pending_remove.clear()

func _on_monster_died(monster: Monster) -> void:
	monster_died.emit(monster)
	_pending_remove.append(monster)

func _on_monster_reached_goal(monster: Monster, durability_damage: int) -> void:
	monster_reached_goal.emit(monster, durability_damage)
	_pending_remove.append(monster)

func _remove_monster(monster: Monster) -> void:
	var idx: int = monsters.find(monster)
	if idx >= 0:
		monsters.remove_at(idx)
	if not is_instance_valid(monster):
		if monsters.is_empty():
			all_monsters_cleared.emit()
		return
	monster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_delayed_free.append(monster)
	var delay: float = 0.22 if monster.reached else 0.18
	get_tree().create_timer(delay).timeout.connect(func():
		var d_idx: int = _delayed_free.find(monster)
		if d_idx >= 0:
			_delayed_free.remove_at(d_idx)
		if is_instance_valid(monster):
			monster.queue_free()
	)
	if monsters.is_empty():
		all_monsters_cleared.emit()
