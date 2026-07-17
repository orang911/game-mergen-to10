extends Node
class_name WaveSystem

signal wave_started(wave_index: int)
signal spawn_requested(monster_type: String)
signal wave_spawn_finished(wave_index: int)
signal wave_cleared(wave_index: int)
signal level_completed

var waves: Array = []
var current_wave_index := -1
var spawn_queue: Array[String] = []
var spawn_interval := 1.0
var spawn_timer := 0.0
var spawning := false
var waiting_for_clear := false
var monsters_are_clear := true
var running := false
var _cycle := 0
var total_waves_cleared := 0
var awaiting_reward := false

func setup(wave_config: Array) -> void:
	waves = wave_config

func start_first_wave() -> void:
	current_wave_index = -1
	_cycle = 0
	total_waves_cleared = 0
	_start_next_wave()

func stop() -> void:
	running = false
	spawning = false
	waiting_for_clear = false
	spawn_queue.clear()

func reset() -> void:
	stop()
	current_wave_index = -1
	_cycle = 0
	total_waves_cleared = 0
	spawn_timer = 0.0
	monsters_are_clear = true
	awaiting_reward = false

func notify_all_monsters_cleared() -> void:
	monsters_are_clear = true
	_try_clear_wave()

func is_wave_active() -> bool:
	return spawning or waiting_for_clear

func continue_to_next_wave() -> void:
	if not awaiting_reward:
		return
	awaiting_reward = false
	_start_next_wave()

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
	spawn_interval = max(0.35, wave.get("spawn_interval", 1.0) - _cycle * 0.08)
	spawn_timer = 0.0
	spawn_queue = _build_spawn_queue(wave)
	wave_started.emit(current_wave_index)

func _build_spawn_queue(wave: Dictionary) -> Array[String]:
	var queue: Array[String] = []
	for monster_type in ["small", "medium", "large"]:
		var count: int = wave.get(monster_type, 0)
		count += _cycle
		for _i in range(count):
			queue.append(monster_type)
	queue.shuffle()
	return queue

func _process(delta: float) -> void:
	if not running:
		return
	if spawning:
		spawn_timer -= delta
		if spawn_timer <= 0.0:
			_request_next_spawn()

func _request_next_spawn() -> void:
	if spawn_queue.is_empty():
		_finish_spawning()
		return
	var monster_type: String = spawn_queue.pop_front()
	spawn_requested.emit(monster_type)
	spawn_timer = spawn_interval

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
