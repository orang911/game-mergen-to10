extends Node
class_name CombatSystem

const BattleLayerScene := preload("res://scenes/combat/battle_layer.tscn")

signal merge_attack_received(event: MergeAttackEvent)
signal castle_destroyed
signal castle_durability_changed(current: int, max_value: int)
signal wave_started(wave_index: int)
signal wave_cleared(wave_index: int)
signal level_completed
signal back_pressed
signal normal_attack_hit(position: Vector2)
signal normal_attack_kill(position: Vector2)

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
	var castle_view := battle_layer.get_node_or_null("DesignRoot/DecorLayer/Castle") as CastleView
	castle_system.setup(castle_view)

	projectile_system = ProjectileSystem.new()
	projectile_system.name = "ProjectileSystem"
	add_child(projectile_system)
	projectile_system.setup(battle_layer.get_projectile_layer())

	effect_system = EffectSystem.new()
	effect_system.name = "EffectSystem"
	add_child(effect_system)
	effect_system.setup(battle_layer.get_effect_layer())

	var crystal_view := battle_layer.get_node_or_null("DesignRoot/CrystalPanel") as CrystalView
	if crystal_view and crystal_view.visible:
		crystal_system = CrystalSystem.new()
		crystal_system.name = "CrystalSystem"
		add_child(crystal_system)
		crystal_system.setup(crystal_view, monster_system, projectile_system, effect_system)
		crystal_system.normal_hit.connect(func(pos: Vector2): normal_attack_hit.emit(pos))

func _connect_signals() -> void:
	wave_system.spawn_requested.connect(func(monster_type: String):
		monster_system.spawn_monster(monster_type)
	)

	monster_system.monster_spawned.connect(func(_monster: Monster):
		wave_system.monsters_are_clear = false
		_refresh_wave_progress()
	)
	monster_system.monster_died.connect(func(monster: Monster):
		run_kills += 1
		if monster.death_source == "normal":
			normal_attack_kill.emit(monster.global_position + monster.size * 0.5)
		_refresh_wave_progress()
	)

	monster_system.monster_reached_goal.connect(func(monster: Monster, durability_damage: int):
		run_leaks += 1
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
		_current_wave_total = wave_system.spawn_queue.size()
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


func start_run() -> void:
	running = true
	reset()
	wave_system.setup(GameConfig.get_level_waves())
	monster_system.start()
	castle_system.reset()
	if crystal_system:
		crystal_system.start()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.start_run_hud()
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


func _refresh_wave_progress() -> void:
	if battle_layer == null or not is_instance_valid(battle_layer) or wave_system == null or monster_system == null:
		return
	var remaining := wave_system.spawn_queue.size() + monster_system.get_alive_monsters().size()
	battle_layer.set_wave_progress(remaining, _current_wave_total)

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

	# Crystal center follows the visible board, while the road can use its own anchor.
	var crystal_center := GameConfig.get_crystal_center(visual_board_pos, new_board_size)
	if crystal_system:
		crystal_system.set_crystal_center(crystal_center)

func handle_merge_attack(event: MergeAttackEvent) -> void:
	if not running:
		return
	merge_attack_received.emit(event)
	if effect_system:
		effect_system.play_merge_feedback(event)

	var is_lightning := event.element == GameConfig.AttackElement.LIGHTNING
	var is_fire := event.element == GameConfig.AttackElement.FIRE
	var is_critical := event.element == GameConfig.AttackElement.CRITICAL
	var crit_chance: float = event.effect_params.get("crit_chance", 0.0) as float if is_critical else 0.0
	var crit_multiplier: float = event.effect_params.get("crit_multiplier", 2.0) as float
	var chain_count: int = event.effect_params.get("chain_count", 0) as int if is_lightning else 0
	var splash_radius: float = event.effect_params.get("splash_radius", 0.0) as float
	var splash_damage_ratio: float = event.effect_params.get("splash_damage_ratio", 0.0) as float

	# Primary targets + chain pool (each primary gets its own chain targets)
	var fetch_count: int = event.target_count * (1 + chain_count) if is_lightning else event.target_count
	var all_sorted := monster_system.get_front_monsters(max(1, fetch_count))
	if all_sorted.is_empty():
		return
	if effect_system:
		effect_system.play_element_launch(ElementFxRequest.make_launch(event))
	if projectile_system and not is_lightning:
		projectile_system.play_merge_attack(event, all_sorted.slice(0, event.target_count))

	var chain_pool_start := event.target_count
	for i in range(min(event.target_count, all_sorted.size())):
		var target: Monster = all_sorted[i]
		var delay: float = float(i) * ProjectileSystem.LIGHTNING_LINK_STAGGER if is_lightning else ProjectileSystem.MERGE_BOLT_DURATION + float(i) * ProjectileSystem.MULTI_SHOT_STAGGER

		var my_chain_targets: Array[Monster] = []
		if is_lightning:
			for ci in range(chain_count):
				var ci_idx := chain_pool_start + ci
				if ci_idx < all_sorted.size():
					my_chain_targets.append(all_sorted[ci_idx])
			chain_pool_start += chain_count

		var resolve_hit := func():
			if not running or not is_instance_valid(target):
				return
			var hit_center: Vector2 = target.global_position + target.size * 0.5
			var target_alive := target.is_alive()
			if is_lightning and target_alive and projectile_system:
				projectile_system.play_lightning_link(event.origin_position, hit_center, event, null, target)

			if target_alive:
				var final_damage: float = event.damage
				if is_critical and GameConfig.is_critical(randf(), crit_chance):
					final_damage *= crit_multiplier
					if effect_system:
						effect_system.play_critical_hit(event.element_key, hit_center, event.element_tier)
				target.apply_damage(final_damage)
				normal_attack_hit.emit(hit_center)
				if target.is_alive():
					target.apply_element_effect(event)
				if effect_system:
					effect_system.play_element_hit(event.element_key, hit_center + Vector2(0.0, -10.0), event.element_tier)
					effect_system.play_monster_hit(target)

			if is_lightning and not my_chain_targets.is_empty():
				_play_merge_lightning_chain(event, target, my_chain_targets, hit_center)

			# Fire splash (triggered from hit point, independent of primary target survival)
			if is_fire and splash_radius > 0.0:
				var splash_damage: float = event.damage * splash_damage_ratio
				for nearby in monster_system.get_alive_monsters():
					if nearby == target:
						continue
					if not is_instance_valid(nearby) or not nearby.is_alive():
						continue
					if hit_center.distance_to(nearby.global_position + nearby.size * 0.5) <= splash_radius:
						nearby.apply_damage(splash_damage)
						var nearby_pos := nearby.global_position + nearby.size * 0.5
						normal_attack_hit.emit(nearby_pos)
						if nearby.is_alive():
							nearby.apply_element_effect(event)
						if effect_system:
							effect_system.play_monster_hit(nearby)
		if delay <= 0.0:
			resolve_hit.call()
		else:
			get_tree().create_timer(delay).timeout.connect(resolve_hit)


func _play_merge_lightning_chain(event: MergeAttackEvent, first_target: Monster, chain_targets: Array[Monster], first_hit_pos: Vector2) -> void:
	var source_target := first_target
	var source_pos := first_hit_pos
	var hop_damage := event.damage
	var retention := float(event.effect_params.get("chain_damage_ratio", 0.5))
	for chain_target in chain_targets:
		await get_tree().create_timer(ProjectileSystem.LIGHTNING_LINK_STAGGER).timeout
		if not running:
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
		var hit_delay := ProjectileSystem.MERGE_BOLT_DURATION + float(i) * ProjectileSystem.MULTI_SHOT_STAGGER if element_key == "ice" else 0.0
		if hit_delay > 0.0:
			_schedule_skill_hit(event, target, damage, element_key, hit_delay)
		else:
			_resolve_skill_hit(event, target, damage, element_key)


func _schedule_skill_hit(event: MergeAttackEvent, target: Monster, damage: float, element_key: String, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not running:
		return
	_resolve_skill_hit(event, target, damage, element_key)


func _resolve_skill_hit(event: MergeAttackEvent, target: Monster, damage: float, element_key: String) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	target.apply_damage(damage, "skill")
	var hit_pos := target.global_position + target.size * 0.5
	if target.is_alive() and element_key != "critical":
		target.apply_element_effect(event, "skill")
	if effect_system:
		effect_system.play_element_hit(element_key, hit_pos, event.element_tier)
		effect_system.play_monster_hit(target)


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
