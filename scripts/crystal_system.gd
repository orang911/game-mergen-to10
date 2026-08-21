extends Node
class_name CrystalSystem

signal normal_hit(position: Vector2)
signal tutorial_first_strike_finished

const ATTACK_INTERVAL := 1.8
const DAMAGE_RATIO := 0.3
const CHARGE_FEEDBACK_DURATION := 0.35
const CRYSTAL_BOLT_FLIGHT_DURATION := 0.18

var _crystal_view: CrystalView
var _monster_system: MonsterSystem
var _projectile_system: ProjectileSystem
var _effect_system: EffectSystem
var _crystal_center_global := Vector2.ZERO
var _crystal_level := 1
var _merge_upgrade_enabled := GameConfig.CRYSTAL_MERGE_UPGRADES_ENABLED
var _awakened := true
var _tutorial_strike_generation := 0
var _locked_target_id := 0
var _charge_serial := 0
var _shot_in_flight := false

var _attack_timer := 0.0
var _running := false
var _damage_multiplier := 1.0
var _speed_multiplier := 1.0
var _extra_targets := 0
var _installed_elements: Dictionary = {}
var _pierce_targets := 0
var _pierce_damage_ratio := 0.0


func setup(view: CrystalView, monsters: MonsterSystem, projectiles: ProjectileSystem, effects: EffectSystem) -> void:
	_crystal_view = view
	_monster_system = monsters
	_projectile_system = projectiles
	_effect_system = effects


func hide_attack_tip() -> void:
	if _crystal_view:
		_crystal_view.hide_attack_tip()


func notify_merge_level(merge_result_level: int) -> void:
	if not _merge_upgrade_enabled:
		return
	if not GameConfig.CRYSTAL_UPGRADE_TRIGGER_LEVELS.has(merge_result_level):
		return
	var next_level := mini(GameConfig.CRYSTAL_MAX_LEVEL, _crystal_level + 1)
	if next_level == _crystal_level:
		return
	_crystal_level = next_level
	if _crystal_view:
		_crystal_view.set_crystal_level(_crystal_level)


func get_crystal_level() -> int:
	return _crystal_level


func set_merge_upgrade_enabled(enabled: bool) -> void:
	_merge_upgrade_enabled = enabled


func is_merge_upgrade_enabled() -> bool:
	return _merge_upgrade_enabled


func set_awakened(awakened: bool) -> void:
	_awakened = awakened
	if not _awakened:
		_attack_timer = 0.0
		cancel_in_flight()
	if _crystal_view:
		_crystal_view.set_awakened(_awakened)


func is_awakened() -> bool:
	return _awakened


func awaken() -> void:
	if _awakened:
		return
	_awakened = true
	_attack_timer = ATTACK_INTERVAL
	if _crystal_view:
		_crystal_view.set_awakened(true, true)


func set_crystal_center(pos: Vector2) -> void:
	_crystal_center_global = pos


func start() -> void:
	_running = true
	_attack_timer = ATTACK_INTERVAL * 0.5


func stop() -> void:
	_running = false
	cancel_in_flight()


func reset() -> void:
	_tutorial_strike_generation += 1
	_running = false
	_attack_timer = 0.0
	_locked_target_id = 0
	_charge_serial += 1
	_shot_in_flight = false
	_crystal_level = 1
	_awakened = true
	_damage_multiplier = 1.0
	_speed_multiplier = 1.0
	_extra_targets = 0
	_installed_elements.clear()
	_pierce_targets = 0
	_pierce_damage_ratio = 0.0
	if _crystal_view:
		_crystal_view.reset()


func export_state() -> Dictionary:
	return {
		"crystal_level": _crystal_level,
		"awakened": _awakened,
		"attack_timer": _attack_timer,
		"damage_multiplier": _damage_multiplier,
		"speed_multiplier": _speed_multiplier,
		"extra_targets": _extra_targets,
		"installed_elements": _installed_elements.duplicate(true),
		"pierce_targets": _pierce_targets,
		"pierce_damage_ratio": _pierce_damage_ratio,
	}


func restore_state(state: Dictionary) -> void:
	_crystal_level = clampi(int(state.get("crystal_level", 1)), 1, GameConfig.CRYSTAL_MAX_LEVEL)
	_awakened = bool(state.get("awakened", true))
	_attack_timer = maxf(0.0, float(state.get("attack_timer", ATTACK_INTERVAL * 0.5)))
	_damage_multiplier = maxf(0.1, float(state.get("damage_multiplier", 1.0)))
	_speed_multiplier = maxf(0.1, float(state.get("speed_multiplier", 1.0)))
	_extra_targets = maxi(0, int(state.get("extra_targets", 0)))
	_installed_elements = (state.get("installed_elements", {}) as Dictionary).duplicate(true)
	_pierce_targets = maxi(0, int(state.get("pierce_targets", 0)))
	_pierce_damage_ratio = maxf(0.0, float(state.get("pierce_damage_ratio", 0.0)))
	if _crystal_view:
		_crystal_view.set_crystal_level(_crystal_level)
		_crystal_view.set_awakened(_awakened)


func _process(delta: float) -> void:
	if not _running or not _awakened:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = maxf(GameConfig.CRYSTAL_MIN_ATTACK_INTERVAL, ATTACK_INTERVAL * _speed_multiplier)
		_try_attack()


func _try_attack() -> void:
	if _monster_system == null or _shot_in_flight:
		return
	var target := _resolve_locked_target()
	if target == null:
		return
	_shot_in_flight = true
	_begin_charged_shot(target)


func _resolve_locked_target() -> Monster:
	var locked := _get_locked_target()
	if locked != null:
		return locked
	var front := _monster_system.get_front_monsters(1)
	if front.is_empty():
		return null
	_locked_target_id = front[0].get_instance_id()
	return front[0]


func _get_locked_target() -> Monster:
	if _locked_target_id == 0:
		return null
	var candidate := instance_from_id(_locked_target_id) as Monster
	if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or not candidate.is_alive() or candidate.reached:
		cancel_in_flight()
		return null
	return candidate


func _target_still_locked(target_id: int) -> bool:
	var current := _get_locked_target()
	return current != null and current.get_instance_id() == target_id


func cancel_in_flight() -> void:
	_charge_serial += 1
	_shot_in_flight = false
	_locked_target_id = 0
	if _projectile_system:
		_projectile_system.cancel_crystal_beams()
	if _crystal_view:
		_crystal_view.cancel_charge_feedback()


func _begin_charged_shot(target: Monster) -> void:
	var serial := _charge_serial
	var target_id := target.get_instance_id()
	var level := _crystal_level
	var damage: float = roundi(float(GameConfig.get_base_attack(level)) * DAMAGE_RATIO * _damage_multiplier)

	if _crystal_view:
		_crystal_view.play_charge_feedback(CHARGE_FEEDBACK_DURATION)

	await get_tree().create_timer(CHARGE_FEEDBACK_DURATION).timeout
	if serial != _charge_serial or not _running or not _awakened:
		return
	if not _target_still_locked(target_id):
		return

	if _projectile_system:
		_projectile_system.play_crystal_beam(_crystal_origin_global(), target, CRYSTAL_BOLT_FLIGHT_DURATION)

	await get_tree().create_timer(CRYSTAL_BOLT_FLIGHT_DURATION).timeout
	if serial != _charge_serial or not _running or not _awakened:
		return
	if not _target_still_locked(target_id):
		return
	var current := _get_locked_target()
	if current == null or current.get_instance_id() != target_id:
		return
	_resolve_charged_hit(current, damage, level)


func _crystal_origin_global() -> Vector2:
	if _crystal_view:
		return _crystal_view.get_crystal_top_global()
	return _crystal_center_global


func _resolve_charged_hit(target: Monster, damage: float, level: int) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or not target.is_alive() or target.reached:
		cancel_in_flight()
		return
	var hit_pos := target.global_position + target.size * 0.5
	target.apply_damage(damage)
	normal_hit.emit(hit_pos)
	if _effect_system:
		_effect_system.play_element_hit("crystal", hit_pos, level)
		var recoil_element := "fire" if _installed_elements.has("fire") else ""
		_effect_system.play_monster_hit(target, recoil_element, _crystal_center_global)
	if not target.is_alive():
		cancel_in_flight()
		return
	_apply_installed_elements(target, level, damage)
	_play_crystal_afterhit_effects(target, damage, level)
	_shot_in_flight = false


func _play_crystal_afterhit_effects(source: Monster, damage: float, level: int) -> void:
	var extra_count := _pierce_targets + (1 if _installed_elements.has("lightning") else 0)
	if extra_count <= 0:
		return
	var front := _monster_system.get_front_monsters(extra_count + 1)
	var followers: Array[Monster] = []
	for i in range(1, front.size()):
		var candidate: Monster = front[i]
		if candidate == source or not is_instance_valid(candidate) or not candidate.is_alive() or candidate.reached:
			continue
		followers.append(candidate)
	if followers.is_empty():
		return

	var next_index := 0
	for _i in range(_pierce_targets):
		if next_index >= followers.size():
			break
		var pierce_target: Monster = followers[next_index]
		next_index += 1
		_play_secondary_crystal_hit(pierce_target, damage * _pierce_damage_ratio, level, "")

	if _installed_elements.has("lightning") and next_index < followers.size():
		var chain_target: Monster = followers[next_index]
		var lightning_level := clampi(int(_installed_elements.get("lightning", 1)), 1, GameConfig.MAX_CARD_LEVEL)
		var chain_damage := damage * float(GameConfig.CRYSTAL_THUNDER_CHAIN_RATIO[lightning_level - 1])
		var source_id := source.get_instance_id()
		var chain_target_id := chain_target.get_instance_id()
		var source_pos := source.global_position + source.size * 0.5
		var chain_delay := 0.15 + ProjectileSystem.LIGHTNING_LINK_STAGGER
		get_tree().create_timer(chain_delay).timeout.connect(func():
			var live_source := instance_from_id(source_id) as Monster
			var live_target := instance_from_id(chain_target_id) as Monster
			if not _running or not is_instance_valid(live_target) or not live_target.is_alive():
				return
			var source_control: Control = live_source if is_instance_valid(live_source) else null
			var live_source_pos := source_pos
			if source_control:
				live_source_pos = live_source.global_position + live_source.size * 0.5
			var target_pos := live_target.global_position + live_target.size * 0.5
			if _projectile_system:
				_projectile_system.play_chain(live_source_pos, target_pos, null, source_control, live_target)
			_play_secondary_crystal_hit(live_target, chain_damage, level, "lightning")
		)


func play_tutorial_first_strike(target) -> void:
	var strike_generation := _tutorial_strike_generation
	if not _awakened:
		tutorial_first_strike_finished.emit()
		return
	# Do not type this argument as Monster. A delayed teaching callback can retain
	# a reference after the target has been released; Godot would reject that
	# value at the call boundary before this guard could run.
	if target == null or not is_instance_valid(target) or not (target is Monster) or not target.is_alive():
		# Keep the awakening rhythm intact even if the tutorial target was removed
		# by an interrupt, restart or external attack.
		if _crystal_view:
			_crystal_view.play_charge_feedback(CHARGE_FEEDBACK_DURATION)
		await get_tree().create_timer(CHARGE_FEEDBACK_DURATION + CRYSTAL_BOLT_FLIGHT_DURATION).timeout
		if strike_generation == _tutorial_strike_generation:
			tutorial_first_strike_finished.emit()
		return
	if _crystal_view:
		_crystal_view.play_charge_feedback(CHARGE_FEEDBACK_DURATION)
	await get_tree().create_timer(CHARGE_FEEDBACK_DURATION).timeout
	if strike_generation != _tutorial_strike_generation:
		return
	if _projectile_system and is_instance_valid(target) and target.is_alive():
		_projectile_system.play_crystal_beam(_crystal_origin_global(), target as Control, CRYSTAL_BOLT_FLIGHT_DURATION)
	await get_tree().create_timer(CRYSTAL_BOLT_FLIGHT_DURATION).timeout
	if strike_generation != _tutorial_strike_generation:
		return
	if is_instance_valid(target) and target.is_alive():
		var hit_pos: Vector2 = target.global_position + target.size * 0.5
		target.apply_damage(maxf(1.0, target.hp), "tutorial_crystal")
		normal_hit.emit(hit_pos)
		if _effect_system:
			_effect_system.play_element_hit("crystal", hit_pos, 1)
			_effect_system.play_monster_hit(target)
	tutorial_first_strike_finished.emit()


func apply_upgrade(card_id: String, _element_key: String = "", quality: int = 1) -> void:
	# Frost and thunder can remain out of the random card pool, but an existing
	# card, scripted grant or future reward must use the same live element state
	# as the board and imprint systems.
	var q := clampi(quality, 1, GameConfig.MAX_CARD_LEVEL)
	match card_id:
		"fire_conduit":
			_installed_elements["fire"] = maxi(int(_installed_elements.get("fire", 0)), q)
		"frost_prism":
			_installed_elements["ice"] = maxi(int(_installed_elements.get("ice", 0)), q)
		"poison_tank":
			_installed_elements["poison"] = maxi(int(_installed_elements.get("poison", 0)), q)
		"thunder_spire":
			_installed_elements["lightning"] = maxi(int(_installed_elements.get("lightning", 0)), q)
		"star_boiler":
			_damage_multiplier += float(GameConfig.CRYSTAL_DAMAGE_UP_BY_LEVEL[q - 1])
		"rapid_clockwork":
			_speed_multiplier *= float(GameConfig.CRYSTAL_INTERVAL_BY_LEVEL[q - 1])
		"twin_lens":
			_extra_targets += int(GameConfig.CRYSTAL_EXTRA_TARGETS_BY_LEVEL[q - 1])
		"piercing_cannon":
			_pierce_targets = mini(3, _pierce_targets + 1)
			_pierce_damage_ratio = maxf(_pierce_damage_ratio, float(GameConfig.CRYSTAL_PIERCE_DAMAGE_RATIO[q - 1]))
	if _crystal_view:
		_crystal_view.play_reward_absorb()


func notify_wave_started() -> void:
	pass


func notify_wave_cleared() -> void:
	pass


func get_crystal_center_global() -> Vector2:
	return _crystal_center_global


func _apply_installed_elements(target: Monster, crystal_level: int, damage: float) -> void:
	for element_key in ["fire", "ice", "poison", "lightning"]:
		if not _installed_elements.has(element_key):
			continue
		var card_level := clampi(int(_installed_elements[element_key]), 1, GameConfig.MAX_CARD_LEVEL)
		var event := _make_crystal_element_event(element_key, crystal_level, damage, card_level)
		target.apply_element_effect(event)
		if _effect_system:
			_effect_system.play_element_hit(element_key, target.global_position + target.size * 0.5, card_level)


func _make_crystal_element_event(element_key: String, crystal_level: int, damage: float, card_level: int) -> MergeAttackEvent:
	var source_level := maxi(1, GameConfig.ELEMENT_ORDER.find(element_key) + 1)
	var event := MergeAttackEvent.from_merge(source_level, crystal_level, 2, _crystal_center_global, 0)
	event.damage = damage
	event.element_key = element_key
	event.element = int(GameConfig.ELEMENT_KEY_TO_ATTACK.get(element_key, GameConfig.AttackElement.POISON))
	event.element_tier = card_level
	event.effect_params["element"] = event.element
	event.effect_params["element_key"] = element_key
	event.effect_params["tier"] = card_level
	match element_key:
		"fire":
			event.effect_params["duration"] = float(GameConfig.CRYSTAL_FIRE_DURATION[card_level - 1])
			event.effect_params["dps_ratio"] = float(GameConfig.CRYSTAL_FIRE_DPS_RATIO[card_level - 1])
			event.effect_params["splash_radius"] = 0.0
			event.effect_params["splash_damage_ratio"] = 0.0
		"ice":
			# All ice sources use the global two-second / forty-percent-speed rule.
			event.effect_params["slow_percent"] = 0.60
			event.effect_params["duration"] = 2.0
		"poison":
			event.effect_params["dps_ratio"] = float(GameConfig.CRYSTAL_POISON_DPS_RATIO[card_level - 1])
			event.effect_params["duration"] = float(GameConfig.CRYSTAL_POISON_DURATION[card_level - 1])
	return event


func _play_secondary_crystal_hit(target: Monster, damage: float, crystal_level: int, element_key: String) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	if _projectile_system and element_key.is_empty():
		_projectile_system.play_crystal_bolt(_crystal_center_global, target.global_position + target.size * 0.5)
		var target_id := target.get_instance_id()
		get_tree().create_timer(ProjectileSystem.MERGE_BOLT_DURATION).timeout.connect(
			_resolve_secondary_crystal_hit_by_id.bind(target_id, damage, crystal_level, element_key)
		)
		return
	_resolve_secondary_crystal_hit(target, damage, crystal_level, element_key)


func _resolve_secondary_crystal_hit_by_id(target_id: int, damage: float, crystal_level: int, element_key: String) -> void:
	var target := instance_from_id(target_id) as Monster
	if not is_instance_valid(target):
		return
	_resolve_secondary_crystal_hit(target, damage, crystal_level, element_key)


func _resolve_secondary_crystal_hit(target, damage: float, crystal_level: int, element_key: String) -> void:
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var monster := target as Monster
	if monster == null or not monster.is_alive():
		return
	monster.apply_damage(damage)
	var hit_pos := monster.global_position + monster.size * 0.5
	normal_hit.emit(hit_pos)
	if monster.is_alive():
		_apply_installed_elements(monster, crystal_level, damage)
	if _effect_system:
		if element_key.is_empty():
			_effect_system.play_element_hit("crystal", hit_pos, crystal_level)
		else:
			_effect_system.play_element_hit(element_key, hit_pos, clampi(int(_installed_elements.get(element_key, 1)), 1, GameConfig.MAX_CARD_LEVEL))
		var recoil_element := element_key
		if recoil_element.is_empty() and _installed_elements.has("fire"):
			recoil_element = "fire"
		_effect_system.play_monster_hit(monster, recoil_element, _crystal_center_global)
