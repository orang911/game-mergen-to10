extends Control
class_name Monster

const MonsterViewScene := preload("res://scenes/combat/monster_view.tscn")
const MAX_ELEMENT_STACKS := 4
const POISON_TICK_INTERVAL := 1.0
const DIRECT_HIT_STOP_DURATION := 0.10

signal died(monster: Monster)
signal reached_goal(monster: Monster, durability_damage: int)
signal tutorial_hold_reached(monster: Monster)
signal hp_changed(monster: Monster, hp: float, max_hp: float)
signal status_applied(monster: Monster, element: int, tier: int)
signal status_ended(monster: Monster, element: int)
signal status_ticked(monster: Monster, element: int, damage: float)
signal damage_feedback_requested(monster: Monster, damage: float, element: int)

var monster_type := "small"
var max_hp := 5.0
var hp := 5.0
var durability_damage := 1
var speed := 80.0
var alive := true
var reached := false
var path_progress := 0.0
var death_source := ""
var tutorial_role := ""
var tutorial_hold_progress := -1.0
var tutorial_hold_at_goal := false
var tutorial_min_hp_before_goal := 0.0
var appearance_id := ""
var is_boss := false
var annihilation_immune := false
var visual_tier := 1
var _spawn_config: Dictionary = {}
var _goal_emitted := false
var _tutorial_hold_emitted := false

# Structured status containers: {tier, duration, remaining, ...}
var poison_status: Dictionary = {}
var freeze_status: Dictionary = {}
var burn_status: Dictionary = {}
var lightning_stun_remaining := 0.0
var _lightning_stunned_this_frame := false
var hit_stop_remaining := 0.0
var _hit_stopped_this_frame := false
var _burn_feedback_damage := 0.0
var _burn_feedback_elapsed := 0.0
var _view: MonsterView


func setup(config: Dictionary) -> void:
	_spawn_config = config.duplicate(true)
	monster_type = config.get("type", "small")
	max_hp = float(config.get("hp", 5))
	hp = max_hp
	durability_damage = config.get("durability_damage", 1)
	speed = config.get("speed", 80.0)
	tutorial_role = str(config.get("tutorial_role", ""))
	tutorial_hold_progress = float(config.get("tutorial_hold_progress", -1.0))
	tutorial_hold_at_goal = bool(config.get("tutorial_hold_at_goal", false))
	tutorial_min_hp_before_goal = maxf(0.0, float(config.get("tutorial_min_hp_before_goal", 0.0)))
	appearance_id = str(config.get("appearance_id", ""))
	is_boss = bool(config.get("is_boss", false))
	annihilation_immune = bool(config.get("annihilation_immune", false))
	visual_tier = clampi(int(config.get("visual_tier", 1)), 1, 3)
	_goal_emitted = false
	_tutorial_hold_emitted = false

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


func update_movement(delta: float, total_path_length: float, goal_progress: float = 0.995) -> void:
	if not alive or reached:
		return
	# Combat lightning hard-stun is deliberately separate from the teaching
	# breakthrough stun.  It only arrests path movement; damage-over-time keeps
	# being advanced by update_status().
	if (
		lightning_stun_remaining > 0.0
		or _lightning_stunned_this_frame
		or hit_stop_remaining > 0.0
		or _hit_stopped_this_frame
	):
		return
	path_progress += (speed * get_speed_multiplier() / total_path_length) * delta
	if tutorial_hold_progress > 0.0 and path_progress >= tutorial_hold_progress:
		path_progress = tutorial_hold_progress
		if not _tutorial_hold_emitted:
			_tutorial_hold_emitted = true
			tutorial_hold_reached.emit(self)
		return
	if path_progress >= goal_progress:
		path_progress = goal_progress
		reached = true
		if not _goal_emitted:
			_goal_emitted = true
			reached_goal.emit(self, durability_damage)


func apply_damage(amount: float, source: String = "normal") -> void:
	if not alive:
		return
	if amount > 0.0:
		apply_hit_stop()
	var hp_before := hp
	var next_hp := maxf(0.0, hp - amount)
	if not reached and tutorial_min_hp_before_goal > 0.0:
		next_hp = maxf(tutorial_min_hp_before_goal, next_hp)
	hp = next_hp
	var actual_damage := maxf(0.0, hp_before - hp)
	_sync_view()
	hp_changed.emit(self, hp, max_hp)
	if actual_damage > 0.0:
		damage_feedback_requested.emit(self, actual_damage, -1)
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


func play_death_animation(speed_multiplier: float = 1.0) -> float:
	if _view and is_instance_valid(_view):
		return _view.play_death_animation(speed_multiplier)
	return 0.0


func play_hit_animation() -> float:
	if _view and is_instance_valid(_view):
		return _view.play_hit_animation()
	return 0.0


func play_element_recoil(attack_origin_global: Vector2) -> float:
	if _view and is_instance_valid(_view):
		return _view.play_element_recoil(attack_origin_global)
	return 0.0


func get_speed_multiplier() -> float:
	var mult := 1.0
	if not freeze_status.is_empty():
		mult *= max(0.1, 1.0 - (freeze_status.get("slow_percent", 0.0) as float))
	return mult


func is_annihilation_immune() -> bool:
	return annihilation_immune or is_boss or not tutorial_role.is_empty() or tutorial_min_hp_before_goal > 0.0


func apply_lightning_stun(duration: float = 1.0) -> void:
	if not alive:
		return
	# A repeat hit refreshes the one-second hard stun instead of stacking it.
	lightning_stun_remaining = maxf(0.0, duration)
	_sync_view()


func apply_hit_stop(duration: float = DIRECT_HIT_STOP_DURATION) -> void:
	if not alive or reached:
		return
	# Direct hits arrest path movement briefly. Repeated hits refresh the short
	# pause, while poison and burn ticks use _apply_combined_status_damage() and
	# deliberately do not keep the monster locked in place.
	hit_stop_remaining = maxf(hit_stop_remaining, maxf(0.0, duration))


func apply_element_effect(event: MergeAttackEvent, source: String = "normal") -> void:
	var params := event.effect_params
	var element: int = int(params.get("element", event.element))
	var tier: int = int(params.get("tier", event.element_tier))
	var atk: float = event.damage
	match element:
		GameConfig.AttackElement.POISON:
			_normalize_legacy_stacked_status(poison_status, "poison")
			var poison_duration := maxf(0.0, float(params.get("duration", 3.0)))
			var poison_layer := {
				"tier": tier,
				"atk": atk,
				"duration": poison_duration,
				"remaining": poison_duration,
				"dps_ratio": float(params.get("dps_ratio", 0.0)),
				"damage_per_tick": maxf(0.0, atk * float(params.get("dps_ratio", 0.0))),
				"source": source,
			}
			_add_stacked_status_layer(poison_status, poison_layer, "poison")
		GameConfig.AttackElement.FREEZE:
			freeze_status = {
				"tier": tier,
				"duration": 2.0,
				"remaining": 2.0,
				"slow_percent": 0.60,
			}
		GameConfig.AttackElement.LIGHTNING:
			apply_lightning_stun(1.0)
		GameConfig.AttackElement.FIRE:
			var was_burn_empty := burn_status.is_empty()
			_normalize_legacy_stacked_status(burn_status, "burn")
			if was_burn_empty:
				_burn_feedback_damage = 0.0
				_burn_feedback_elapsed = 0.0
			var burn_duration := maxf(0.0, float(params.get("duration", 2.0)))
			var burn_ratio := float(params.get("dps_ratio", float(params.get("splash_damage_ratio", 0.0)) * 0.5))
			var burn_layer := {
				"tier": tier,
				"atk": atk,
				"duration": burn_duration,
				"remaining": burn_duration,
				"splash_radius": params.get("splash_radius", 0.0),
				"splash_damage_ratio": params.get("splash_damage_ratio", 0.0),
				"dps_ratio": burn_ratio,
				"damage_per_second": maxf(0.0, atk * burn_ratio),
				"source": source,
			}
			_add_stacked_status_layer(burn_status, burn_layer, "burn")
		GameConfig.AttackElement.CRITICAL:
			return  # Critical is instant, no persistent status
		_:
			return
	_sync_view()
	status_applied.emit(self, element, tier)


func update_status(delta: float) -> void:
	_lightning_stunned_this_frame = lightning_stun_remaining > 0.0
	_hit_stopped_this_frame = hit_stop_remaining > 0.0
	if hit_stop_remaining > 0.0:
		hit_stop_remaining = maxf(0.0, hit_stop_remaining - delta)

	if not poison_status.is_empty() and _advance_poison_layers(delta):
		return

	if not burn_status.is_empty() and _advance_burn_layers(delta):
		return

	if not freeze_status.is_empty():
		freeze_status["remaining"] = max(0.0, freeze_status["remaining"] - delta)
		if freeze_status["remaining"] <= 0.0:
			status_ended.emit(self, GameConfig.AttackElement.FREEZE)
			freeze_status.clear()

	if lightning_stun_remaining > 0.0:
		lightning_stun_remaining = maxf(0.0, lightning_stun_remaining - delta)

	_sync_view()


func is_alive() -> bool:
	return alive


func export_state() -> Dictionary:
	return {
		"config": _spawn_config.duplicate(true),
		"hp": hp,
		"max_hp": max_hp,
		"path_progress": path_progress,
		"alive": alive,
		"reached": reached,
		"death_source": death_source,
		"poison_status": poison_status.duplicate(true),
		"freeze_status": freeze_status.duplicate(true),
		"burn_status": burn_status.duplicate(true),
		"lightning_stun_remaining": lightning_stun_remaining,
		"hit_stop_remaining": hit_stop_remaining,
	}


func restore_state(state: Dictionary) -> void:
	hp = clampf(float(state.get("hp", max_hp)), 0.0, max_hp)
	path_progress = clampf(float(state.get("path_progress", 0.0)), 0.0, 1.0)
	alive = bool(state.get("alive", true))
	reached = bool(state.get("reached", false))
	death_source = str(state.get("death_source", ""))
	poison_status = (state.get("poison_status", {}) as Dictionary).duplicate(true)
	freeze_status = (state.get("freeze_status", {}) as Dictionary).duplicate(true)
	burn_status = (state.get("burn_status", {}) as Dictionary).duplicate(true)
	_normalize_legacy_stacked_status(poison_status, "poison")
	_normalize_legacy_stacked_status(burn_status, "burn")
	_burn_feedback_damage = 0.0
	_burn_feedback_elapsed = 0.0
	lightning_stun_remaining = maxf(0.0, float(state.get("lightning_stun_remaining", 0.0)))
	hit_stop_remaining = maxf(0.0, float(state.get("hit_stop_remaining", 0.0)))
	_sync_view()


func _add_stacked_status_layer(status: Dictionary, layer: Dictionary, status_kind: String) -> void:
	var layers: Array = status.get("layers", [])
	if layers.size() < MAX_ELEMENT_STACKS:
		layers.append(layer)
	else:
		var replace_index := 0
		var shortest_remaining := INF
		for index in range(layers.size()):
			var existing := layers[index] as Dictionary
			var existing_remaining := float(existing.get("remaining", 0.0))
			if existing_remaining < shortest_remaining:
				shortest_remaining = existing_remaining
				replace_index = index
		layers[replace_index] = layer
	status["layers"] = layers
	if status_kind == "poison" and not status.has("tick_elapsed"):
		status["tick_elapsed"] = 0.0
	_refresh_stacked_status_summary(status, status_kind)


func _advance_poison_layers(delta: float) -> bool:
	_normalize_legacy_stacked_status(poison_status, "poison")
	var layers: Array = poison_status.get("layers", [])
	if layers.is_empty():
		poison_status.clear()
		return false
	var remaining_delta := maxf(0.0, delta)
	var tick_elapsed := clampf(float(poison_status.get("tick_elapsed", 0.0)), 0.0, POISON_TICK_INTERVAL)
	while remaining_delta > 0.000001 and not layers.is_empty():
		var time_to_tick := maxf(0.000001, POISON_TICK_INTERVAL - tick_elapsed)
		var time_to_expiry := INF
		for layer_value in layers:
			var layer := layer_value as Dictionary
			var layer_remaining := maxf(0.0, float(layer.get("remaining", 0.0)))
			if layer_remaining > 0.000001:
				time_to_expiry = minf(time_to_expiry, layer_remaining)
		var step := minf(remaining_delta, time_to_tick)
		if time_to_expiry < INF:
			step = minf(step, time_to_expiry)
		if step <= 0.000001:
			break
		for layer_value in layers:
			var layer := layer_value as Dictionary
			layer["remaining"] = maxf(0.0, float(layer.get("remaining", 0.0)) - step)
		tick_elapsed += step
		remaining_delta -= step
		var reached_tick := tick_elapsed >= POISON_TICK_INTERVAL - 0.000001
		if reached_tick:
			tick_elapsed = 0.0
			var combined_damage := 0.0
			var dominant_damage := -1.0
			var dominant_source := "normal"
			for layer_value in layers:
				var layer := layer_value as Dictionary
				var layer_damage := maxf(0.0, float(layer.get("damage_per_tick", 0.0)))
				combined_damage += layer_damage
				if layer_damage > dominant_damage:
					dominant_damage = layer_damage
					dominant_source = str(layer.get("source", "normal"))
			if combined_damage > 0.0:
				_apply_combined_status_damage(combined_damage, GameConfig.AttackElement.POISON, dominant_source, true)
				if not alive:
					poison_status["layers"] = layers
					poison_status["tick_elapsed"] = tick_elapsed
					_refresh_stacked_status_summary(poison_status, "poison")
					return true
		var active_layers: Array = []
		for layer_value in layers:
			var layer := layer_value as Dictionary
			if float(layer.get("remaining", 0.0)) > 0.000001:
				active_layers.append(layer)
		layers = active_layers
	poison_status["layers"] = layers
	poison_status["tick_elapsed"] = tick_elapsed
	if layers.is_empty():
		poison_status.clear()
		status_ended.emit(self, GameConfig.AttackElement.POISON)
	else:
		_refresh_stacked_status_summary(poison_status, "poison")
	return false


func _advance_burn_layers(delta: float) -> bool:
	_normalize_legacy_stacked_status(burn_status, "burn")
	var layers: Array = burn_status.get("layers", [])
	if layers.is_empty():
		burn_status.clear()
		return false
	var combined_damage := 0.0
	var dominant_damage := -1.0
	var dominant_source := "normal"
	var active_layers: Array = []
	for layer_value in layers:
		var layer := layer_value as Dictionary
		var layer_remaining := maxf(0.0, float(layer.get("remaining", 0.0)))
		var active_time := minf(maxf(0.0, delta), layer_remaining)
		var layer_damage := maxf(0.0, float(layer.get("damage_per_second", 0.0))) * active_time
		combined_damage += layer_damage
		if layer_damage > dominant_damage:
			dominant_damage = layer_damage
			dominant_source = str(layer.get("source", "normal"))
		layer["remaining"] = maxf(0.0, layer_remaining - maxf(0.0, delta))
		if float(layer["remaining"]) > 0.000001:
			active_layers.append(layer)
	burn_status["layers"] = active_layers
	if active_layers.is_empty():
		burn_status.clear()
	else:
		_refresh_stacked_status_summary(burn_status, "burn")
	if combined_damage > 0.0:
		var actual_burn_damage := _apply_combined_status_damage(
			combined_damage,
			GameConfig.AttackElement.FIRE,
			dominant_source,
			false
		)
		_burn_feedback_damage += actual_burn_damage
	_burn_feedback_elapsed += maxf(0.0, delta)
	var should_flush_feedback := (
		_burn_feedback_elapsed >= 1.0
		or active_layers.is_empty()
		or not alive
	)
	if should_flush_feedback:
		_flush_burn_damage_feedback()
	if not alive:
		return true
	if active_layers.is_empty():
		status_ended.emit(self, GameConfig.AttackElement.FIRE)
	return false


func _apply_combined_status_damage(
	amount: float,
	element: int,
	source: String,
	request_feedback: bool
) -> float:
	if not alive or amount <= 0.0:
		return 0.0
	var hp_before := hp
	hp = maxf(0.0, hp - amount)
	if not reached and tutorial_min_hp_before_goal > 0.0:
		hp = maxf(tutorial_min_hp_before_goal, hp)
	var actual_damage := maxf(0.0, hp_before - hp)
	_sync_view()
	hp_changed.emit(self, hp, max_hp)
	status_ticked.emit(self, element, amount)
	if request_feedback and actual_damage > 0.0:
		damage_feedback_requested.emit(self, actual_damage, element)
	if hp <= 0.0:
		alive = false
		death_source = source
		died.emit(self)
	return actual_damage


func _flush_burn_damage_feedback() -> void:
	if _burn_feedback_damage > 0.0:
		damage_feedback_requested.emit(self, _burn_feedback_damage, GameConfig.AttackElement.FIRE)
	_burn_feedback_damage = 0.0
	_burn_feedback_elapsed = 0.0


func _normalize_legacy_stacked_status(status: Dictionary, status_kind: String) -> void:
	if status.is_empty():
		return
	var existing_layers: Variant = status.get("layers", null)
	if existing_layers is Array:
		_refresh_stacked_status_summary(status, status_kind)
		return
	var legacy := status.duplicate(true)
	var legacy_layer := {
		"tier": int(legacy.get("tier", 1)),
		"atk": float(legacy.get("atk", 0.0)),
		"duration": float(legacy.get("duration", legacy.get("remaining", 0.0))),
		"remaining": maxf(0.0, float(legacy.get("remaining", 0.0))),
		"dps_ratio": float(legacy.get("dps_ratio", 0.0)),
		"source": str(legacy.get("source", "normal")),
	}
	if status_kind == "poison":
		legacy_layer["damage_per_tick"] = maxf(
			0.0,
			float(legacy.get("damage_per_tick", float(legacy_layer["atk"]) * float(legacy_layer["dps_ratio"])))
		)
	else:
		legacy_layer["splash_radius"] = float(legacy.get("splash_radius", 0.0))
		legacy_layer["splash_damage_ratio"] = float(legacy.get("splash_damage_ratio", 0.0))
		legacy_layer["damage_per_second"] = maxf(
			0.0,
			float(legacy.get("damage_per_second", float(legacy_layer["atk"]) * float(legacy_layer["dps_ratio"])))
		)
	status.clear()
	status["layers"] = [legacy_layer]
	if status_kind == "poison":
		status["tick_elapsed"] = float(legacy.get("tick_elapsed", 0.0))
	_refresh_stacked_status_summary(status, status_kind)


func _refresh_stacked_status_summary(status: Dictionary, status_kind: String) -> void:
	var layers: Array = status.get("layers", [])
	if layers.is_empty():
		status.clear()
		return
	var max_remaining := 0.0
	var max_duration := 0.0
	var total_damage_rate := 0.0
	var dominant_damage := -1.0
	var dominant_source := "normal"
	for layer_value in layers:
		var layer := layer_value as Dictionary
		max_remaining = maxf(max_remaining, float(layer.get("remaining", 0.0)))
		max_duration = maxf(max_duration, float(layer.get("duration", 0.0)))
		var layer_damage_rate := float(
			layer.get("damage_per_tick", 0.0)
			if status_kind == "poison"
			else layer.get("damage_per_second", 0.0)
		)
		total_damage_rate += maxf(0.0, layer_damage_rate)
		if layer_damage_rate > dominant_damage:
			dominant_damage = layer_damage_rate
			dominant_source = str(layer.get("source", "normal"))
	var latest := layers[layers.size() - 1] as Dictionary
	status["layers"] = layers
	status["layer_count"] = layers.size()
	status["remaining"] = max_remaining
	status["duration"] = max_duration
	status["tier"] = int(latest.get("tier", 1))
	status["atk"] = float(latest.get("atk", 0.0))
	status["dps_ratio"] = float(latest.get("dps_ratio", 0.0))
	status["source"] = dominant_source
	if status_kind == "poison":
		status["damage_per_tick"] = total_damage_rate
	else:
		status["damage_per_second"] = total_damage_rate


func get_poison_layer_count() -> int:
	return clampi(int(poison_status.get("layer_count", 0)), 0, MAX_ELEMENT_STACKS)


func get_burn_layer_count() -> int:
	return clampi(int(burn_status.get("layer_count", 0)), 0, MAX_ELEMENT_STACKS)


func set_tutorial_stunned(stunned: bool) -> void:
	if _view and is_instance_valid(_view):
		_view.set_tutorial_stunned(stunned)


func _sync_view() -> void:
	if _view and is_instance_valid(_view):
		_view.update_hp(hp, max_hp)
		_view.update_status(
			freeze_status.get("remaining", 0.0) if not freeze_status.is_empty() else 0.0,
			burn_status.get("remaining", 0.0) if not burn_status.is_empty() else 0.0,
			poison_status.get("remaining", 0.0) if not poison_status.is_empty() else 0.0,
			lightning_stun_remaining,
			get_poison_layer_count(),
			get_burn_layer_count()
		)


func play_poison_tick_feedback() -> void:
	play_damage_feedback()


func play_damage_feedback() -> void:
	if _view and is_instance_valid(_view):
		_view.play_damage_feedback()
