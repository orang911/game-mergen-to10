extends Node
class_name WaveSystem

const SPAWN_BATCH_PATTERN := [1, 2, 3, 4]
const SPAWN_BATCH_MEMBER_INTERVAL := 0.08

signal wave_started(wave_index: int)
signal spawn_requested(monster_type: String, hp_multiplier: float, visual_tier: int, overrides: Dictionary)
signal wave_spawn_finished(wave_index: int)
signal wave_cleared(wave_index: int)
signal level_completed

var waves: Array = []
var current_wave_index := -1
var spawn_queue: Array = []
var spawn_interval := 1.0
var current_hp_multiplier := 1.0
var current_visual_tier := 1
var spawn_timer := 0.0
var _batch_pattern_index := 0
var _pending_batch_members := 0
var _batch_member_timer := 0.0
var spawning := false
var waiting_for_clear := false
var monsters_are_clear := true
var running := false
var _cycle := 0
var total_waves_cleared := 0
var awaiting_reward := false
var scripted_wave_active := false
var scripted_wave_total := 0
var scripted_wave_remaining := 0
var _current_wave: Dictionary = {}
var _current_wave_total := 0
var _uses_spawn_sequence := false

func setup(wave_config: Array) -> void:
	waves = wave_config

func start_first_wave(start_index: int = 0) -> void:
	scripted_wave_active = false
	current_wave_index = start_index - 1
	_cycle = 0
	total_waves_cleared = 0
	_start_next_wave()

func stop() -> void:
	running = false
	spawning = false
	waiting_for_clear = false
	spawn_queue.clear()
	_pending_batch_members = 0
	_batch_member_timer = 0.0
	scripted_wave_active = false
	scripted_wave_total = 0
	scripted_wave_remaining = 0

func reset() -> void:
	stop()
	current_wave_index = -1
	_cycle = 0
	total_waves_cleared = 0
	spawn_timer = 0.0
	current_hp_multiplier = 1.0
	current_visual_tier = 1
	_batch_pattern_index = 0
	monsters_are_clear = true
	awaiting_reward = false
	_current_wave.clear()
	_current_wave_total = 0
	_uses_spawn_sequence = false

func notify_all_monsters_cleared() -> void:
	monsters_are_clear = true
	if scripted_wave_active:
		return
	_try_clear_wave()

func is_wave_active() -> bool:
	return scripted_wave_active or spawning or waiting_for_clear


func start_scripted_first_wave(total_monsters: int) -> void:
	current_wave_index = 0
	_cycle = 0
	total_waves_cleared = 0
	running = false
	spawning = false
	waiting_for_clear = true
	monsters_are_clear = false
	awaiting_reward = false
	spawn_queue.clear()
	_pending_batch_members = 0
	_batch_member_timer = 0.0
	scripted_wave_active = true
	scripted_wave_total = maxi(1, total_monsters)
	scripted_wave_remaining = scripted_wave_total
	wave_started.emit(current_wave_index)


func set_scripted_remaining(remaining: int) -> void:
	if scripted_wave_active:
		scripted_wave_remaining = clampi(remaining, 0, scripted_wave_total)


func complete_scripted_first_wave() -> void:
	if not scripted_wave_active:
		return
	scripted_wave_active = false
	scripted_wave_remaining = 0
	waiting_for_clear = false
	monsters_are_clear = true
	total_waves_cleared = 1
	awaiting_reward = true
	wave_cleared.emit(0)


func get_current_wave_total() -> int:
	return scripted_wave_total if scripted_wave_active else _current_wave_total


func get_current_wave_remaining(alive_count: int) -> int:
	if scripted_wave_active:
		return scripted_wave_remaining
	return spawn_queue.size() + alive_count

func continue_to_next_wave() -> void:
	if not awaiting_reward:
		return
	awaiting_reward = false
	_start_next_wave()


func get_current_wave() -> Dictionary:
	return _current_wave.duplicate(true)


func export_state() -> Dictionary:
	return {
		"current_wave_index": current_wave_index,
		"spawn_queue": spawn_queue.duplicate(true),
		"spawn_interval": spawn_interval,
		"current_hp_multiplier": current_hp_multiplier,
		"current_visual_tier": current_visual_tier,
		"spawn_timer": spawn_timer,
		"spawning": spawning,
		"waiting_for_clear": waiting_for_clear,
		"monsters_are_clear": monsters_are_clear,
		"running": running,
		"total_waves_cleared": total_waves_cleared,
		"awaiting_reward": awaiting_reward,
		"current_wave_total": _current_wave_total,
		"current_wave": _current_wave.duplicate(true),
		"uses_spawn_sequence": _uses_spawn_sequence,
	}


func restore_state(state: Dictionary) -> void:
	current_wave_index = int(state.get("current_wave_index", -1))
	spawn_queue = (state.get("spawn_queue", []) as Array).duplicate(true)
	spawn_interval = float(state.get("spawn_interval", 1.0))
	current_hp_multiplier = float(state.get("current_hp_multiplier", 1.0))
	current_visual_tier = clampi(int(state.get("current_visual_tier", 1)), 1, 3)
	spawn_timer = float(state.get("spawn_timer", 0.0))
	spawning = bool(state.get("spawning", false))
	waiting_for_clear = bool(state.get("waiting_for_clear", false))
	monsters_are_clear = bool(state.get("monsters_are_clear", false))
	running = bool(state.get("running", true))
	total_waves_cleared = int(state.get("total_waves_cleared", 0))
	awaiting_reward = bool(state.get("awaiting_reward", false))
	_current_wave_total = int(state.get("current_wave_total", spawn_queue.size()))
	_current_wave = (state.get("current_wave", {}) as Dictionary).duplicate(true)
	_uses_spawn_sequence = bool(state.get("uses_spawn_sequence", false))
	_batch_pattern_index = 0
	_pending_batch_members = 0
	_batch_member_timer = 0.0
	if current_wave_index >= 0:
		wave_started.emit(current_wave_index)

func _start_next_wave() -> void:
	current_wave_index += 1
	if current_wave_index >= waves.size():
		running = false
		level_completed.emit()
		return
	running = true
	spawning = true
	waiting_for_clear = false
	monsters_are_clear = false
	var wave: Dictionary = waves[current_wave_index]
	_current_wave = wave.duplicate(true)
	spawn_interval = max(0.35, wave.get("spawn_interval", 1.0) - _cycle * 0.08)
	current_hp_multiplier = maxf(1.0, float(wave.get("hp_multiplier", 1.0)))
	current_visual_tier = clampi(int(wave.get("visual_tier", 1)), 1, 3)
	spawn_timer = 0.0
	_batch_pattern_index = 0
	_pending_batch_members = 0
	_batch_member_timer = 0.0
	spawn_queue = _build_spawn_queue(wave)
	_current_wave_total = spawn_queue.size()
	_uses_spawn_sequence = wave.has("spawn_sequence")
	wave_started.emit(current_wave_index)

func _build_spawn_queue(wave: Dictionary) -> Array:
	if wave.has("spawn_sequence"):
		return (wave.get("spawn_sequence", []) as Array).duplicate(true)
	var queue: Array = []
	for monster_type in ["small", "medium", "large"]:
		var count: int = wave.get(monster_type, 0)
		count += _cycle
		for _i in range(count):
			queue.append({
				"monster_type": monster_type,
				"hp_multiplier": float(wave.get("hp_multiplier", 1.0)),
				"visual_tier": int(wave.get("visual_tier", 1)),
			})
	queue.shuffle()
	return queue

func _process(delta: float) -> void:
	if not running:
		return
	if spawning:
		if _pending_batch_members > 0:
			_batch_member_timer -= delta
			if _batch_member_timer <= 0.0:
				_emit_next_batch_member()
		else:
			spawn_timer -= delta
			if spawn_timer <= 0.0:
				_start_next_spawn_batch()


func _start_next_spawn_batch() -> void:
	if spawn_queue.is_empty():
		_finish_spawning()
		return
	var requested_size := 1 if _uses_spawn_sequence else int(SPAWN_BATCH_PATTERN[_batch_pattern_index])
	if not _uses_spawn_sequence:
		_batch_pattern_index = (_batch_pattern_index + 1) % SPAWN_BATCH_PATTERN.size()
	_pending_batch_members = mini(requested_size, spawn_queue.size())
	_batch_member_timer = 0.0
	_emit_next_batch_member()


func _emit_next_batch_member() -> void:
	if _pending_batch_members <= 0 or spawn_queue.is_empty():
		_pending_batch_members = 0
		if spawn_queue.is_empty():
			_finish_spawning()
		else:
			spawn_timer = spawn_interval
		return
	var spawn: Dictionary = spawn_queue.pop_front() as Dictionary
	var monster_type := str(spawn.get("monster_type", "small"))
	var hp_multiplier := maxf(1.0, float(spawn.get("hp_multiplier", current_hp_multiplier)))
	var visual_tier := clampi(int(spawn.get("visual_tier", current_visual_tier)), 1, 3)
	var overrides := (spawn.get("overrides", {}) as Dictionary).duplicate(true)
	spawn_requested.emit(monster_type, hp_multiplier, visual_tier, overrides)
	_pending_batch_members -= 1
	if _pending_batch_members > 0:
		_batch_member_timer = SPAWN_BATCH_MEMBER_INTERVAL
	elif spawn_queue.is_empty():
		_finish_spawning()
	else:
		spawn_timer = maxf(0.05, float(spawn.get("delay_after", spawn_interval)))

func _finish_spawning() -> void:
	spawning = false
	wave_spawn_finished.emit(current_wave_index)
	_try_clear_wave()

func _try_clear_wave() -> void:
	if spawning:
		return
	if not monsters_are_clear:
		waiting_for_clear = true
		return
	waiting_for_clear = false
	total_waves_cleared += 1
	running = false
	if current_wave_index >= waves.size() - 1:
		awaiting_reward = false
		level_completed.emit()
		return
	awaiting_reward = true
	wave_cleared.emit(current_wave_index)
