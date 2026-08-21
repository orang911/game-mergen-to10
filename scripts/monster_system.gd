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
## Keep this untyped because a monster can be queued for deletion by another
## system between two frames.  Typed arrays reject a freed object before the
## cleanup code can inspect is_instance_valid().
var _pending_remove: Array = []
var _delayed_free: Array[Monster] = []

const SPAWN_INTRO_START_SCALE := 0.12
const SPAWN_INTRO_DURATION := 0.22

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

func spawn_monster(monster_type: String, hp_multiplier: float = 1.0, overrides: Dictionary = {}) -> Monster:
	var config: Dictionary = GameConfig.MONSTER_CONFIG.get(monster_type, GameConfig.MONSTER_CONFIG["small"]).duplicate()
	config["type"] = monster_type
	config["hp"] = maxf(1.0, float(config.get("hp", 1.0)) * maxf(1.0, hp_multiplier))
	for key in overrides:
		config[key] = overrides[key]

	var monster := Monster.new()
	monster.setup(config)
	monster.path_progress = 0.0
	monster.position = path_system.get_spawn_position() - monster.get_path_anchor_offset()
	monster.died.connect(_on_monster_died)
	monster.reached_goal.connect(_on_monster_reached_goal)
	parent_layer.add_child(monster)
	# Keep the monster in front of the entrance artwork and let it emerge from
	# the portal with a short scale-in animation.
	monster.scale = Vector2.ONE * SPAWN_INTRO_START_SCALE
	var spawn_intro := monster.create_tween()
	spawn_intro.tween_property(monster, "scale", Vector2.ONE, SPAWN_INTRO_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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


func export_states() -> Array:
	var result: Array = []
	for monster in monsters:
		if is_instance_valid(monster) and monster.is_alive() and not monster.reached:
			result.append(monster.export_state())
	return result


func restore_states(states: Array) -> void:
	for state_value in states:
		var state := state_value as Dictionary
		var config := (state.get("config", {}) as Dictionary).duplicate(true)
		if config.is_empty():
			continue
		var monster_type := str(config.get("type", "small"))
		var monster := spawn_monster(monster_type, 1.0, config)
		monster.restore_state(state)
		monster.position = path_system.position_at_progress(monster.path_progress) - monster.get_path_anchor_offset()
		monster.scale = Vector2.ONE

func _process(delta: float) -> void:
	if not running:
		return
	var total_length := path_system.get_total_length()
	if total_length <= 0.0:
		return
	var goal_progress := path_system.get_goal_progress_ratio()
	for index in range(monsters.size() - 1, -1, -1):
		var candidate: Variant = monsters[index]
		if not is_instance_valid(candidate):
			monsters.remove_at(index)
			continue
		var monster := candidate as Monster
		if monster.is_alive() and not monster.reached:
			monster.update_status(delta)
			monster.update_movement(delta, total_length, goal_progress)
			monster.position = path_system.position_at_progress(monster.path_progress) - monster.get_path_anchor_offset()
		elif monster.reached and not monster.tutorial_hold_at_goal:
			_pending_remove.append(monster)
	for candidate in _pending_remove:
		if is_instance_valid(candidate):
			_remove_monster(candidate as Monster)
	_pending_remove.clear()

func _on_monster_died(monster: Monster) -> void:
	monster_died.emit(monster)
	# The tutorial breakthrough is killed while combat movement is deliberately
	# paused. Remove it immediately so the defeated body does not remain frozen
	# beside the crystal throughout the final teaching message.
	if not running and monster.tutorial_role == "breakthrough":
		_remove_monster(monster)
	else:
		_pending_remove.append(monster)

func _on_monster_reached_goal(monster: Monster, durability_damage: int) -> void:
	monster_reached_goal.emit(monster, durability_damage)
	if not monster.tutorial_hold_at_goal:
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
	if not monster.is_alive() and not monster.reached:
		# Death is resolved immediately for gameplay, while the released visual
		# remains in place until its supplied 19-frame sequence has finished.
		var death_speed := 2.5 if monster.death_source == "annihilation" else 1.0
		delay = maxf(delay, monster.play_death_animation(death_speed))
	var monster_id := monster.get_instance_id()
	get_tree().create_timer(delay).timeout.connect(func():
		# Resolve by ObjectID instead of capturing the Monster reference. The
		# battle can be reset while the death animation timer is still pending.
		var live_monster := instance_from_id(monster_id) as Monster
		for i in range(_delayed_free.size() - 1, -1, -1):
			var pending := _delayed_free[i]
			if is_instance_valid(pending) and pending.get_instance_id() == monster_id:
				_delayed_free.remove_at(i)
		if is_instance_valid(live_monster):
			live_monster.queue_free()
	)
	if monsters.is_empty():
		all_monsters_cleared.emit()


func clear_tutorial_monsters() -> void:
	_pending_remove.clear()
	for monster in monsters.duplicate():
		if not is_instance_valid(monster) or monster.tutorial_role.is_empty():
			continue
		monster.alive = false
		monsters.erase(monster)
		monster.queue_free()
	for monster in _delayed_free.duplicate():
		if not is_instance_valid(monster) or monster.tutorial_role.is_empty():
			continue
		_delayed_free.erase(monster)
		monster.queue_free()
