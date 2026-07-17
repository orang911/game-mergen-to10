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
	)
	monster_system.monster_died.connect(func(monster: Monster):
		if monster.death_source == "normal":
			normal_attack_kill.emit(monster.global_position + monster.size * 0.5)
	)

	monster_system.monster_reached_goal.connect(func(monster: Monster, durability_damage: int):
		if effect_system:
			effect_system.play_monster_reached_goal(monster)
		castle_system.damage(durability_damage)
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
		var display := ""
		if wave_system._cycle > 0:
			display = "%d-%d" % [wave_system._cycle + 1, wave_index + 1]
		else:
			display = str(wave_index + 1)
		if battle_layer and is_instance_valid(battle_layer):
			battle_layer.set_wave_text("Wave " + display)
		if crystal_system:
			crystal_system.notify_wave_started()
	)

	wave_system.wave_cleared.connect(func(wave_index: int):
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
	wave_system.start_first_wave()

func stop_run() -> void:
	running = false
	wave_system.stop()
	monster_system.stop()
	if crystal_system:
		crystal_system.stop()
	reset()

func reset() -> void:
	wave_system.reset()
	monster_system.reset()
	if projectile_system:
		projectile_system.reset()
	if effect_system:
		effect_system.reset()
	if crystal_system:
		crystal_system.reset()
	if battle_layer and is_instance_valid(battle_layer):
		battle_layer.set_wave_text("")

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
	if projectile_system:
		projectile_system.play_merge_attack(event, all_sorted.slice(0, event.target_count))

	var chain_pool_start := event.target_count
	for i in range(min(event.target_count, all_sorted.size())):
		var target: Monster = all_sorted[i]
		var delay: float = ProjectileSystem.MERGE_BOLT_DURATION + i * 0.07
		var target_center_global: Vector2 = target.global_position + target.size * 0.5

		var my_chain_targets: Array[Monster] = []
		if is_lightning:
			for ci in range(chain_count):
				var ci_idx := chain_pool_start + ci
				if ci_idx < all_sorted.size():
					my_chain_targets.append(all_sorted[ci_idx])
			chain_pool_start += chain_count

		get_tree().create_timer(delay).timeout.connect(func():
			if not is_instance_valid(target):
				return
			var hit_center: Vector2 = target.global_position + target.size * 0.5
			var target_alive := target.is_alive()

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

			# Lightning chain
			for ci in range(my_chain_targets.size()):
				var chain: Monster = my_chain_targets[ci]
				if not is_instance_valid(chain) or not chain.is_alive():
					continue
				var chain_damage: float = event.damage * float(event.effect_params.get("chain_damage_ratio", 0.5))
				if projectile_system:
					projectile_system.play_chain(hit_center, chain.global_position + chain.size * 0.5, event)
				chain.apply_damage(chain_damage)
				var chain_pos := chain.global_position + chain.size * 0.5
				normal_attack_hit.emit(chain_pos)
				if chain.is_alive():
					chain.apply_element_effect(event)
				if effect_system:
					effect_system.play_monster_hit(chain)

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
		)


func apply_crystal_upgrade(card_id: String, element_key: String = "", quality: int = 1) -> void:
	if crystal_system:
		crystal_system.apply_upgrade(card_id, element_key, quality)


func continue_after_wave_reward() -> void:
	if wave_system:
		wave_system.continue_to_next_wave()


func trigger_frost_star(trigger_level: int, quality: int = 1) -> void:
	var q := clampi(quality, 1, 3)
	var targets := monster_system.get_front_monsters(q + 1)
	var damage: float = float(GameConfig.get_base_attack(trigger_level)) * [0.8, 1.0, 1.25][q - 1]
	for target in targets:
		if not is_instance_valid(target) or not target.is_alive():
			continue
		var event := MergeAttackEvent.from_merge(2, trigger_level, 2, target.global_position, 0)
		event.damage = damage
		event.effect_params["slow_percent"] = [0.20, 0.25, 0.30][q - 1]
		event.effect_params["duration"] = [1.5, 2.0, 2.5][q - 1]
		target.apply_damage(damage, "skill")
		if target.is_alive():
			target.apply_element_effect(event, "skill")
		if effect_system:
			effect_system.play_monster_hit(target)
