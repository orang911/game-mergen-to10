extends Node
class_name CombatSystem

const BattleLayerScene := preload("res://scenes/combat/battle_layer.tscn")
const CRYSTAL_RAIN_SHOT_STAGGER := 0.10
const TUTORIAL_BASIC_COUNT := 4
const TUTORIAL_WAVE_TOTAL := 5
const TUTORIAL_BASIC_SPAWN_DELAY := 0.45
const TUTORIAL_HEAVY_SPAWN_DELAY := 0.65
const MERGE_SHOT_INTERVAL := 0.05

signal merge_attack_received(event: MergeAttackEvent)
signal castle_destroyed
signal castle_durability_changed(current: int, max_value: int)
signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal level_completed
signal back_pressed
signal normal_attack_hit(position: Vector2)
signal normal_attack_kill(position: Vector2)
signal tutorial_basic_progress(killed: int, total: int)
signal tutorial_breakthrough_reached(monster: Monster)
signal tutorial_first_strike_finished
signal merge_shot_fired(sequence_id: int, shot_index: int, target: Monster)
signal merge_shot_resolved(sequence_id: int, shot_index: int, target: Monster, damage: float, killed: bool)
signal merge_sequence_finished(sequence_id: int, fired_count: int)

var running := false
var board_pos := Vector2.ZERO
var visual_board_pos := Vector2.ZERO
var board_size := Vector2.ZERO

var path_system: PathSystem
var monster_system: MonsterSystem
var wave_system: WaveSystem
var castle_system: CastleSystem
var projectile_system: ProjectileSystem
var effect_system: EffectSystem
var crystal_system: CrystalSystem
var path_view
var effect_layer: Control

var battle_layer: BattleLayerView
var game_layer: Control
var _current_wave_total := 0
var run_kills := 0
var run_leaks := 0
var _tutorial_mode := false
var _tutorial_paused := false
var _tutorial_basic_kills := 0
var _tutorial_generation := 0
var _tutorial_breakthrough_monster: Monster
var _merge_attack_generation := 0
var _active_merge_sequences: Dictionary = {}


func setup(p_game_layer: Control) -> void:
	game_layer = p_game_layer
	_build_battle_layer()
	_build_children()
	_connect_signals()

func _build_battle_layer() -> void:
	battle_layer = BattleLayerScene.instantiate() as BattleLayerView
	game_layer.add_child(battle_layer)
	game_layer.move_child(battle_layer, 0)

func _build_children() -> void:
	path_view = battle_layer.get_path_view()
	effect_layer = battle_layer.get_effect_layer()

	path_system = PathSystem.new()
	path_system.name = "PathSystem"
	add_child(path_system)

	monster_system = MonsterSystem.new()
	monster_system.name = "MonsterSystem"
	add_child(monster_system)
	monster_system.setup(path_system, battle_layer.get_monster_layer())

	wave_system = WaveSystem.new()
	wave_system.name = "WaveSystem"
	add_child(wave_system)

	castle_system = CastleSystem.new()
	castle_system.name = "CastleSystem"
	add_child(castle_system)
	var crystal_view := battle_layer.get_crystal_view()
	castle_system.setup(crystal_view)

	projectile_system = ProjectileSystem.new()
	projectile_system.name = "ProjectileSystem"
	add_child(projectile_system)
	projectile_system.setup(battle_layer.get_projectile_layer())

	effect_system = EffectSystem.new()
	effect_system.name = "EffectSystem"
	add_child(effect_system)
	effect_system.setup(battle_layer.get_effect_layer())

	if crystal_view and crystal_view.visible:
		crystal_system = CrystalSystem.new()
		crystal_system.name = "CrystalSystem"
		add_child(crystal_system)
		crystal_system.setup(crystal_view, monster_system, projectile_system, effect_system)
		crystal_system.normal_hit.connect(func(pos: Vector2): normal_attack_hit.emit(pos))
		crystal_system.tutorial_first_strike_finished.connect(func(): tutorial_first_strike_finished.emit())

func _connect_signals() -> void:
	wave_system.spawn_requested.connect(func(monster_type: String, hp_multiplier: float, visual_tier: int):
		monster_system.spawn_monster(monster_type, hp_multiplier, {"visual_tier": visual_tier})
	)

	monster_system.monster_spawned.connect(func(_monster: Monster):
		wave_system.monsters_are_clear = false
		_refresh_wave_progress()
	)
	monster_system.monster_died.connect(func(monster: Monster):
		run_kills += 1
		if monster.death_source == "normal":
			normal_attack_kill.emit(monster.global_position + monster.size * 0.5)
		_handle_tutorial_monster_died(monster)
		_refresh_wave_progress()
	)

	monster_system.monster_reached_goal.connect(func(monster: Monster, durability_damage: int):
		run_leaks += 1
		if _tutorial_mode and monster.tutorial_role == "breakthrough":
			castle_system.damage(durability_damage)
			monster.set_tutorial_stunned(true)
			set_tutorial_paused(true)
			tutorial_breakthrough_reached.emit(monster)
			_refresh_wave_progress()
			return
		if effect_system:
			effect_system.play_monster_reached_goal(monster)
		castle_system.damage(durability_damage)
		_refresh_wave_progress()
	)

	castle_system.castle_destroyed.connect(func():
		castle_destroyed.emit()
	)
	castle_system.durability_changed.connect(func(current: int, max_value: int):
		castle_durability_changed.emit(current, max_value)
	)

	monster_system.all_monsters_cleared.connect(func():
		wave_system.notify_all_monsters_cleared()
	)

	wave_system.wave_started.connect(func(wave_index: int):
		wave_started.emit(wave_index)
		_current_wave_total = wave_system.get_current_wave_total()
		var display := ""
		if wave_system._cycle > 0:
			display = "%d-%d" % [wave_system._cycle + 1, wave_index + 1]
		else:
			display = str(wave_index + 1)
		if battle_layer and is_instance_valid(battle_layer):
			battle_layer.set_wave_text("Wave " + display)
			battle_layer.set_wave_progress(_current_wave_total, _current_wave_total)
		if crystal_system:
			crystal_system.notify_wave_started()
	)

	wave_system.wave_cleared.connect(func(wave_index: int):
		_refresh_wave_progress()
		if crystal_system:
			crystal_system.notify_wave_cleared()
		wave_cleared.emit(wave_index)
	)
	wave_system.level_completed.connect(func(): level_completed.emit())

	battle_layer.back_pressed.connect(func(): back_pressed.emit())


func start_run(tutorial_mode: bool = false) -> void:
	running = true
	reset()
	_tutorial_mode = tutorial_mode
	wave_system.setup(GameConfig.get_level_waves())
	monster_system.start()
	castle_system.reset()
	if crystal_system:
		crystal_system.set_awakened(not _tutorial_mode)
		crystal_system.start()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.start_run_hud()
	if _tutorial_mode:
		wave_system.start_scripted_first_wave(TUTORIAL_WAVE_TOTAL)
		tutorial_basic_progress.emit(0, TUTORIAL_BASIC_COUNT)
		_schedule_tutorial_spawn("basic", 0.35)
	else:
		wave_system.start_first_wave()

func stop_run() -> void:
	running = false
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.stop_run_hud()
	wave_system.stop()
	monster_system.stop()
	if crystal_system:
		crystal_system.stop()
	reset()

func reset() -> void:
	_merge_attack_generation += 1
	_active_merge_sequences.clear()
	_tutorial_generation += 1
	_tutorial_mode = false
	_tutorial_paused = false
	_tutorial_basic_kills = 0
	_tutorial_breakthrough_monster = null
	_current_wave_total = 0
	run_kills = 0
	run_leaks = 0
	wave_system.reset()
	monster_system.reset()
	if projectile_system:
		projectile_system.reset()
	if effect_system:
		effect_system.reset()
	if crystal_system:
		crystal_system.reset()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.reset_run_hud()
		battle_layer.reset_tutorial_layer_order()


func trigger_crystal_rain() -> float:
	if not running or monster_system == null or projectile_system == null:
		return 0.0
	var targets := monster_system.get_alive_monsters()
	if targets.is_empty():
		return 0.0
	targets.sort_custom(func(first: Monster, second: Monster):
		return first.path_progress > second.path_progress
	)
	for target_index in range(targets.size()):
		var target := targets[target_index]
		var fallback_position := target.global_position + target.size * 0.5
		projectile_system.play_vertical_crystal_drop(
			target,
			fallback_position,
			float(target_index) * CRYSTAL_RAIN_SHOT_STAGGER,
			_resolve_crystal_rain_hit
		)
	return float(targets.size() - 1) * CRYSTAL_RAIN_SHOT_STAGGER + ProjectileSystem.CRYSTAL_RAIN_FLIGHT_DURATION


func _resolve_crystal_rain_hit(target, impact_position: Vector2) -> void:
	if not running:
		return
	if effect_system:
		effect_system.play_element_hit("crystal", impact_position, 1)
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var monster := target as Monster
	if monster == null or not monster.is_alive() or monster.reached:
		return
	monster.apply_damage(maxf(1.0, monster.hp), "skill")


func _refresh_wave_progress() -> void:
	if battle_layer == null or not is_instance_valid(battle_layer) or wave_system == null or monster_system == null:
		return
	var remaining := wave_system.get_current_wave_remaining(monster_system.get_alive_monsters().size())
	battle_layer.set_wave_progress(remaining, _current_wave_total)


func is_first_wave_tutorial_active() -> bool:
	return _tutorial_mode


func set_tutorial_paused(paused: bool) -> void:
	if not _tutorial_mode or _tutorial_paused == paused:
		return
	_tutorial_paused = paused
	if paused:
		monster_system.stop()
		if crystal_system:
			crystal_system.stop()
	else:
		monster_system.start()
		if crystal_system:
			crystal_system.start()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.set_run_hud_paused(paused)


func awaken_tutorial_crystal() -> void:
	if _tutorial_mode and crystal_system:
		if battle_layer and is_instance_valid(battle_layer):
			# The breakthrough monster owns the foreground until the awakening
			# core reaches the crystal. Raise the full crystal panel only at the
			# activation beat so its tower, HP UI and awakening FX move together.
			battle_layer.set_tutorial_crystal_foreground(true)
		crystal_system.awaken()


func play_tutorial_first_strike() -> void:
	if crystal_system == null:
		tutorial_first_strike_finished.emit()
		return
	crystal_system.play_tutorial_first_strike(_tutorial_breakthrough_monster)


func complete_tutorial_first_wave() -> void:
	if not _tutorial_mode:
		return
	set_tutorial_paused(false)
	_tutorial_mode = false
	wave_system.complete_scripted_first_wave()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.reset_tutorial_layer_order()


func skip_tutorial_first_wave() -> void:
	if not _tutorial_mode:
		return
	_tutorial_generation += 1
	monster_system.clear_tutorial_monsters()
	if crystal_system:
		crystal_system.awaken()
	wave_system.set_scripted_remaining(0)
	set_tutorial_paused(false)
	_tutorial_mode = false
	wave_system.complete_scripted_first_wave()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.reset_tutorial_layer_order()


func _handle_tutorial_monster_died(monster: Monster) -> void:
	if not _tutorial_mode or monster.tutorial_role.is_empty():
		return
	if monster.tutorial_role == "basic":
		_tutorial_basic_kills += 1
		wave_system.set_scripted_remaining(TUTORIAL_WAVE_TOTAL - _tutorial_basic_kills)
		tutorial_basic_progress.emit(_tutorial_basic_kills, TUTORIAL_BASIC_COUNT)
		if _tutorial_basic_kills < TUTORIAL_BASIC_COUNT:
			_schedule_tutorial_spawn("basic", TUTORIAL_BASIC_SPAWN_DELAY)
		else:
			_schedule_tutorial_spawn("breakthrough", TUTORIAL_HEAVY_SPAWN_DELAY)
	elif monster.tutorial_role == "breakthrough":
		wave_system.set_scripted_remaining(0)
		_tutorial_breakthrough_monster = null


func _schedule_tutorial_spawn(role: String, delay: float) -> void:
	var spawn_generation := _tutorial_generation
	await get_tree().create_timer(delay).timeout
	if spawn_generation != _tutorial_generation or not running or not _tutorial_mode:
		return
	if role == "basic":
		monster_system.spawn_monster("small", 1.0, {
			"hp": 4.0,
			"speed": 60.0,
			"durability_damage": 0,
			"tutorial_role": "basic",
			"tutorial_hold_progress": 0.92,
		})
	else:
		_tutorial_breakthrough_monster = monster_system.spawn_monster("tutorial_armored", 1.0, {
			"hp": 24.0,
			"speed": 78.0,
			"durability_damage": 2,
			"scale": 1.85,
			"tutorial_role": "breakthrough",
			"tutorial_hold_at_goal": true,
			"tutorial_min_hp_before_goal": 8.0,
			"tutorial_bob": true,
		})
		if battle_layer and is_instance_valid(battle_layer):
			battle_layer.set_tutorial_breakthrough_foreground(_tutorial_breakthrough_monster)

func layout_for_board(new_board_pos: Vector2, new_board_size: Vector2, new_visual_board_pos: Vector2) -> void:
	board_pos = new_board_pos
	visual_board_pos = new_visual_board_pos
	board_size = new_board_size
	if effect_system:
		effect_system.layout_for_board(visual_board_pos, board_size)
	path_system.layout_for_board(new_board_pos, new_board_size)
	if path_view and path_view.has_method("set_path_params"):
		path_view.set_path_params(path_system._corner_radius, path_system.end_offset)
	var goal_pos := path_system.position_at_progress(path_system.get_goal_progress_ratio())
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.layout_for_board(new_board_pos, new_board_size, path_system.margin, path_system.get_spawn_position(), goal_pos, visual_board_pos)

	# The merged crystal/castle is now the real attack origin as well as the
	# durability target, so projectiles and card fly-ins follow its visual center.
	var crystal_center := battle_layer.get_crystal_attack_origin_global() if battle_layer else Vector2.ZERO
	if crystal_system:
		crystal_system.set_crystal_center(crystal_center)

func handle_merge_attack(event: MergeAttackEvent) -> void:
	if not running or event == null:
		return
	merge_attack_received.emit(event)
	if effect_system:
		effect_system.play_merge_feedback(event)
	var generation := _merge_attack_generation
	_active_merge_sequences[event.sequence_id] = generation
	if event.element == GameConfig.AttackElement.FREEZE:
		_play_merge_freeze_multitarget(event, generation)
	else:
		# Lightning reaches this path with attack_count == 1 and then starts its
		# dedicated bounce chain from _resolve_merge_sequence_hit().
		_play_merge_attack_sequence(event, generation)


func _play_merge_freeze_multitarget(event: MergeAttackEvent, generation: int) -> void:
	var targets := monster_system.get_front_monsters(maxi(1, event.target_count))
	if targets.is_empty():
		_finish_merge_sequence(event.sequence_id, generation, 0)
		return
	var fired_count := 0
	for shot_index in range(targets.size()):
		if shot_index > 0:
			await get_tree().create_timer(ProjectileSystem.MULTI_SHOT_STAGGER).timeout
		if generation != _merge_attack_generation or not running:
			break
		var target := targets[shot_index] as Monster
		if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive() or target.reached:
			continue
		fired_count += 1
		merge_shot_fired.emit(event.sequence_id, shot_index, target)
		if projectile_system:
			projectile_system.play_merge_shot(
				event,
				target,
				Callable(self, "_provide_specific_merge_visual_target").bind(target.get_instance_id())
			)
		_resolve_merge_freeze_shot(event, target, shot_index, generation)
	if fired_count > 0:
		await get_tree().create_timer(ProjectileSystem.MERGE_BOLT_DURATION).timeout
	_finish_merge_sequence(event.sequence_id, generation, fired_count)


func _resolve_merge_freeze_shot(event: MergeAttackEvent, target: Monster, shot_index: int, generation: int) -> void:
	await get_tree().create_timer(ProjectileSystem.MERGE_BOLT_DURATION).timeout
	if generation != _merge_attack_generation or not running:
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive() or target.reached:
		return
	var hit_result := _resolve_merge_sequence_hit(event, target)
	merge_shot_resolved.emit(
		event.sequence_id,
		shot_index,
		target,
		float(hit_result.get("damage", 0.0)),
		bool(hit_result.get("killed", false))
	)


func _provide_specific_merge_visual_target(instance_id: int) -> Monster:
	var target := instance_from_id(instance_id) as Monster
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.reached:
		return null
	return target


func _play_merge_attack_sequence(event: MergeAttackEvent, generation: int) -> void:
	var fired_count := 0
	var focus_target: Monster = null
	for shot_index in range(maxi(1, event.attack_count)):
		if generation != _merge_attack_generation or not running:
			break
		var launch_target := _resolve_merge_sequence_target(focus_target)
		if launch_target == null:
			break
		focus_target = launch_target
		fired_count += 1
		merge_shot_fired.emit(event.sequence_id, shot_index, launch_target)
		if projectile_system:
			projectile_system.play_merge_shot(
				event,
				launch_target,
				Callable(self, "_provide_merge_visual_target").bind(launch_target.get_instance_id())
			)
		await get_tree().create_timer(ProjectileSystem.MERGE_BOLT_DURATION).timeout
		if generation != _merge_attack_generation or not running:
			break
		var resolved_target := _resolve_merge_sequence_target(launch_target)
		if resolved_target == null:
			break
		focus_target = resolved_target
		var hit_result := _resolve_merge_sequence_hit(event, resolved_target)
		merge_shot_resolved.emit(
			event.sequence_id,
			shot_index,
			resolved_target,
			float(hit_result.get("damage", 0.0)),
			bool(hit_result.get("killed", false))
		)
		if bool(hit_result.get("killed", false)):
			focus_target = null
		if shot_index < event.attack_count - 1:
			await get_tree().create_timer(MERGE_SHOT_INTERVAL).timeout
	_finish_merge_sequence(event.sequence_id, generation, fired_count)


func _resolve_merge_sequence_target(original_target: Monster) -> Monster:
	if is_instance_valid(original_target) and not original_target.is_queued_for_deletion() and original_target.is_alive() and not original_target.reached:
		return original_target
	var replacement := monster_system.get_front_monsters(1)
	return replacement[0] as Monster if not replacement.is_empty() else null


func _provide_merge_visual_target(original_instance_id: int) -> Monster:
	var original := instance_from_id(original_instance_id) as Monster
	return _resolve_merge_sequence_target(original)


func _resolve_merge_sequence_hit(event: MergeAttackEvent, target: Monster) -> Dictionary:
	if not is_instance_valid(target) or not target.is_alive() or target.reached:
		return {"damage": 0.0, "killed": false}
	var hit_center := target.global_position + target.size * 0.5
	var final_damage := event.damage
	if event.element == GameConfig.AttackElement.CRITICAL:
		var crit_chance := float(event.effect_params.get("crit_chance", 0.0))
		if GameConfig.is_critical(randf(), crit_chance):
			final_damage *= float(event.effect_params.get("crit_multiplier", 2.0))
			if effect_system:
				effect_system.play_critical_hit(event.element_key, hit_center, event.element_tier)
	target.apply_damage(final_damage)
	var killed := not target.is_alive()
	normal_attack_hit.emit(hit_center)
	if target.is_alive() and (
		event.element == GameConfig.AttackElement.POISON
		or event.element == GameConfig.AttackElement.FREEZE
		or event.element == GameConfig.AttackElement.FIRE
	):
		target.apply_element_effect(event)
	if effect_system:
		effect_system.play_element_hit(event.element_key, hit_center + Vector2(0.0, -10.0), event.element_tier)
		effect_system.play_monster_hit(target)
	if event.element == GameConfig.AttackElement.FIRE:
		_apply_merge_fire_splash(event, target, hit_center)
	elif event.element == GameConfig.AttackElement.LIGHTNING:
		_play_current_lightning_chain(event, target, hit_center)
	return {"damage": final_damage, "killed": killed}


func _play_current_lightning_chain(event: MergeAttackEvent, primary: Monster, hit_center: Vector2) -> void:
	var chain_count := maxi(0, int(event.effect_params.get("chain_count", 0)))
	if chain_count <= 0:
		return
	var chain_targets: Array[Monster] = []
	for candidate in monster_system.get_front_monsters(chain_count + 1):
		if candidate == primary or not is_instance_valid(candidate) or not candidate.is_alive():
			continue
		chain_targets.append(candidate)
		if chain_targets.size() >= chain_count:
			break
	if not chain_targets.is_empty():
		_play_merge_lightning_chain(event, primary, chain_targets, hit_center, _merge_attack_generation)


func _apply_merge_fire_splash(event: MergeAttackEvent, primary: Monster, hit_center: Vector2) -> void:
	var splash_radius := float(event.effect_params.get("splash_radius", 0.0))
	var splash_ratio := float(event.effect_params.get("splash_damage_ratio", 0.0))
	if splash_radius <= 0.0 or splash_ratio <= 0.0:
		return
	var splash_damage := event.damage * splash_ratio
	for nearby in monster_system.get_alive_monsters():
		if nearby == primary or not is_instance_valid(nearby) or not nearby.is_alive():
			continue
		var nearby_pos := nearby.global_position + nearby.size * 0.5
		if hit_center.distance_to(nearby_pos) > splash_radius:
			continue
		nearby.apply_damage(splash_damage)
		normal_attack_hit.emit(nearby_pos)
		if nearby.is_alive():
			nearby.apply_element_effect(event)
		if effect_system:
			effect_system.play_monster_hit(nearby)


func _finish_merge_sequence(sequence_id: int, generation: int, fired_count: int) -> void:
	if generation == _merge_attack_generation:
		_active_merge_sequences.erase(sequence_id)
		merge_sequence_finished.emit(sequence_id, fired_count)


func _play_merge_lightning_chain(event: MergeAttackEvent, first_target: Monster, chain_targets: Array[Monster], first_hit_pos: Vector2, generation: int) -> void:
	var source_target := first_target
	var source_pos := first_hit_pos
	var hop_damage := event.damage
	var retention := float(event.effect_params.get("chain_damage_ratio", 0.5))
	for chain_target in chain_targets:
		await get_tree().create_timer(ProjectileSystem.LIGHTNING_LINK_STAGGER).timeout
		if not running or generation != _merge_attack_generation:
			return
		if not is_instance_valid(chain_target) or not chain_target.is_alive():
			continue
		var source_control: Control = source_target if source_target != null and is_instance_valid(source_target) else null
		if source_control:
			source_pos = source_target.global_position + source_target.size * 0.5
		var chain_pos := chain_target.global_position + chain_target.size * 0.5
		if projectile_system:
			projectile_system.play_chain(source_pos, chain_pos, event, source_control, chain_target)
		hop_damage *= retention
		chain_target.apply_damage(hop_damage)
		normal_attack_hit.emit(chain_pos)
		if chain_target.is_alive():
			chain_target.apply_element_effect(event)
		if effect_system:
			# Every chain segment owns an impact, not only the primary A -> B hit.
			# Play it when this hop first appears and resolves its damage.
			effect_system.play_element_hit(event.element_key, chain_pos + Vector2(0.0, -10.0), event.element_tier)
			effect_system.play_monster_hit(chain_target)
		source_target = chain_target
		source_pos = chain_pos


func trigger_card_attack(card_id: String, trigger_level: int, card_level: int, origin: Vector2) -> void:
	if not running or monster_system == null:
		return
	if card_id == "frost_bell" or card_id == "thunder_ballista":
		return
	var level := clampi(card_level, 1, GameConfig.MAX_CARD_LEVEL)
	var base_damage := float(GameConfig.get_base_attack(trigger_level))
	match card_id:
		"castle_cannon":
			var targets := monster_system.get_front_monsters(1)
			var damage := base_damage * float(GameConfig.CASTLE_CANNON_DAMAGE[level - 1])
			_play_skill_strike(targets, damage, "critical", origin, {})
		"dragon_catapult":
			var target_count := int(GameConfig.DRAGON_CATAPULT_TARGETS[level - 1])
			var targets := monster_system.get_front_monsters(target_count)
			var damage := base_damage * float(GameConfig.DRAGON_CATAPULT_DAMAGE[level - 1])
			var params := {
				"duration": float(GameConfig.DRAGON_CATAPULT_BURN_DURATION[level - 1]),
				"dps_ratio": float(GameConfig.DRAGON_CATAPULT_BURN_RATIO[level - 1]),
				"splash_radius": 0.0,
				"splash_damage_ratio": 0.0,
			}
			_play_skill_strike(targets, damage, "fire", origin, params)
		"frost_bell":
			var targets := monster_system.get_alive_monsters()
			var damage := base_damage * float(GameConfig.FROST_BELL_DAMAGE[level - 1])
			var params := {
				"slow_percent": float(GameConfig.FROST_BELL_SLOW[level - 1]),
				"duration": float(GameConfig.FROST_BELL_DURATION[level - 1]),
			}
			_play_skill_strike(targets, damage, "ice", origin, params)
		"thunder_ballista":
			var target_count := int(GameConfig.THUNDER_BALLISTA_TARGETS[level - 1])
			var targets := monster_system.get_front_monsters(target_count)
			var damage := base_damage * float(GameConfig.THUNDER_BALLISTA_DAMAGE[level - 1])
			var chain_ratio := float(GameConfig.THUNDER_BALLISTA_CHAIN_RATIO[level - 1])
			_play_ballista_strike(targets, damage, chain_ratio, origin, level)


func _play_skill_strike(targets: Array[Monster], damage: float, element_key: String, origin: Vector2, overrides: Dictionary) -> void:
	if targets.is_empty():
		return
	var event := _make_skill_event(element_key, damage, origin, targets.size())
	for key in overrides:
		event.effect_params[key] = overrides[key]
	if effect_system:
		effect_system.play_element_launch(ElementFxRequest.make_launch(event))
	if projectile_system:
		projectile_system.play_merge_attack(event, targets)
	for i in range(targets.size()):
		var target := targets[i]
		if not is_instance_valid(target) or not target.is_alive():
			continue
		# Standardized non-lightning skill projectiles resolve when their visual
		# reaches the target; successive targets keep the same 0.10 s stagger.
		var hit_delay := ProjectileSystem.MERGE_BOLT_DURATION + float(i) * ProjectileSystem.MULTI_SHOT_STAGGER
		if hit_delay > 0.0:
			_schedule_skill_hit(event, target, damage, element_key, hit_delay)
		else:
			_resolve_skill_hit(event, target, damage, element_key)


func _schedule_skill_hit(event: MergeAttackEvent, target: Monster, damage: float, element_key: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not running or not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	_resolve_skill_hit(event, target, damage, element_key)


func _resolve_skill_hit(event: MergeAttackEvent, target, damage: float, element_key: String) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var monster := target as Monster
	if monster == null or not monster.is_alive():
		return
	monster.apply_damage(damage, "skill")
	var hit_pos := monster.global_position + monster.size * 0.5
	if monster.is_alive() and element_key != "critical":
		monster.apply_element_effect(event, "skill")
	if effect_system:
		effect_system.play_element_hit(element_key, hit_pos, event.element_tier)
		effect_system.play_monster_hit(monster)


func _play_ballista_strike(targets: Array[Monster], damage: float, chain_ratio: float, origin: Vector2, level: int) -> void:
	if targets.is_empty():
		return
	var event := _make_skill_event("lightning", damage, origin, targets.size())
	event.element_tier = level
	var first_target := targets[0]
	if not is_instance_valid(first_target) or not first_target.is_alive():
		return
	if projectile_system:
		projectile_system.play_merge_attack(event, [first_target])
	var first_hit_pos := first_target.global_position + first_target.size * 0.5
	first_target.apply_damage(damage, "skill")
	if effect_system:
		effect_system.play_element_hit("lightning", first_hit_pos, level)
		effect_system.play_monster_hit(first_target)
	var chain_targets: Array[Monster] = []
	for i in range(1, targets.size()):
		chain_targets.append(targets[i])
	if not chain_targets.is_empty():
		_play_ballista_chain_sequence(event, first_target, chain_targets, damage * chain_ratio, level, first_hit_pos)


func _play_ballista_chain_sequence(event: MergeAttackEvent, first_target: Monster, targets: Array[Monster], damage: float, level: int, first_hit_pos: Vector2) -> void:
	var source_target := first_target
	var source_pos := first_hit_pos
	for target in targets:
		await get_tree().create_timer(ProjectileSystem.LIGHTNING_LINK_STAGGER).timeout
		if not running:
			return
		if not is_instance_valid(target) or not target.is_alive():
			continue
		var source_control: Control = source_target if source_target != null and is_instance_valid(source_target) else null
		if source_control:
			source_pos = source_target.global_position + source_target.size * 0.5
		var hit_pos := target.global_position + target.size * 0.5
		if projectile_system:
			projectile_system.play_chain(source_pos, hit_pos, event, source_control, target)
		target.apply_damage(damage, "skill")
		if effect_system:
			effect_system.play_element_hit("lightning", hit_pos, level)
			effect_system.play_monster_hit(target)
		source_target = target
		source_pos = hit_pos


func _make_skill_event(element_key: String, damage: float, origin: Vector2, target_count: int) -> MergeAttackEvent:
	var source_level := maxi(1, GameConfig.ELEMENT_ORDER.find(element_key) + 1)
	var event := MergeAttackEvent.from_merge(source_level, source_level, 2, origin, 0)
	event.element_key = element_key
	event.element = int(GameConfig.ELEMENT_KEY_TO_ATTACK.get(element_key, GameConfig.AttackElement.POISON))
	event.damage = damage
	event.atk = roundi(damage)
	event.target_count = maxi(1, target_count)
	event.effect_params = GameConfig.get_element_effect_params(source_level)
	return event


func apply_crystal_upgrade(card_id: String, element_key: String = "", quality: int = 1) -> void:
	if crystal_system:
		crystal_system.apply_upgrade(card_id, element_key, quality)


func continue_after_wave_reward() -> void:
	if wave_system:
		wave_system.continue_to_next_wave()
