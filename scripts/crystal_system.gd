extends Node
class_name CrystalSystem

signal normal_hit(position: Vector2)

const ATTACK_INTERVAL := 1.8
const DAMAGE_RATIO := 0.3

var _crystal_view: CrystalView
var _monster_system: MonsterSystem
var _projectile_system: ProjectileSystem
var _effect_system: EffectSystem
var _crystal_center_global := Vector2.ZERO

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


func notify_merge_level(level: int) -> void:
	if _crystal_view:
		_crystal_view.set_crystal_level(level)


func set_crystal_center(pos: Vector2) -> void:
	_crystal_center_global = pos


func start() -> void:
	_running = true
	_attack_timer = ATTACK_INTERVAL * 0.5


func stop() -> void:
	_running = false


func reset() -> void:
	_running = false
	_attack_timer = 0.0
	_damage_multiplier = 1.0
	_speed_multiplier = 1.0
	_extra_targets = 0
	_installed_elements.clear()
	_pierce_targets = 0
	_pierce_damage_ratio = 0.0
	if _crystal_view:
		_crystal_view.reset()


func _process(delta: float) -> void:
	if not _running:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = maxf(GameConfig.CRYSTAL_MIN_ATTACK_INTERVAL, ATTACK_INTERVAL * _speed_multiplier)
		_try_attack()


func _try_attack() -> void:
	if _monster_system == null:
		return
	var primary_count := 1 + _extra_targets
	var extra_count := _pierce_targets + (1 if _installed_elements.has("lightning") else 0)
	var targets := _monster_system.get_front_monsters(primary_count + extra_count)
	if targets.is_empty():
		return

	var level := 1
	if _crystal_view:
		level = _crystal_view.get_crystal_level()

	var base_atk := GameConfig.get_base_attack(level)
	var damage: float = roundi(float(base_atk) * DAMAGE_RATIO * _damage_multiplier)

	if _crystal_view:
		_crystal_view.play_attack_flash()

	for i in range(mini(primary_count, targets.size())):
		var target: Monster = targets[i]
		if _projectile_system:
			var target_center := target.global_position + target.size * 0.5
			_projectile_system.play_crystal_bolt(_crystal_center_global, target_center)
		get_tree().create_timer(0.15 + float(i) * 0.04).timeout.connect(func():
			if not is_instance_valid(target) or not target.is_alive():
				return
			var hit_pos := target.global_position + target.size * 0.5
			target.apply_damage(damage)
			normal_hit.emit(hit_pos)
			if target.is_alive():
				_apply_installed_elements(target, level, damage)
			if _effect_system:
				_effect_system.play_monster_hit(target)
		)

	var next_index := primary_count
	for i in range(_pierce_targets):
		if next_index >= targets.size():
			break
		var target: Monster = targets[next_index]
		next_index += 1
		_play_secondary_crystal_hit(target, damage * _pierce_damage_ratio, level, "")

	if _installed_elements.has("lightning") and next_index < targets.size():
		var chain_target: Monster = targets[next_index]
		var source_target: Monster = targets[0]
		var lightning_level := clampi(int(_installed_elements.get("lightning", 1)), 1, GameConfig.MAX_CARD_LEVEL)
		var chain_damage := damage * float(GameConfig.CRYSTAL_THUNDER_CHAIN_RATIO[lightning_level - 1])
		var source_pos := source_target.global_position + source_target.size * 0.5
		var chain_delay := 0.15 + ProjectileSystem.LIGHTNING_LINK_STAGGER
		get_tree().create_timer(chain_delay).timeout.connect(func():
			if not _running or not is_instance_valid(chain_target) or not chain_target.is_alive():
				return
			var source_control: Control = source_target if is_instance_valid(source_target) else null
			if source_control:
				source_pos = source_target.global_position + source_target.size * 0.5
			var target_pos := chain_target.global_position + chain_target.size * 0.5
			if _projectile_system:
				_projectile_system.play_chain(source_pos, target_pos, null, source_control, chain_target)
			_play_secondary_crystal_hit(chain_target, chain_damage, level, "lightning")
		)


func apply_upgrade(card_id: String, _element_key: String = "", quality: int = 1) -> void:
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
	for element_key in ["fire", "ice", "poison"]:
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
			event.effect_params["slow_percent"] = float(GameConfig.CRYSTAL_FROST_SLOW[card_level - 1])
			event.effect_params["duration"] = float(GameConfig.CRYSTAL_FROST_DURATION[card_level - 1])
		"poison":
			event.effect_params["dps_ratio"] = float(GameConfig.CRYSTAL_POISON_DPS_RATIO[card_level - 1])
			event.effect_params["duration"] = float(GameConfig.CRYSTAL_POISON_DURATION[card_level - 1])
	return event


func _play_secondary_crystal_hit(target: Monster, damage: float, crystal_level: int, element_key: String) -> void:
	if not is_instance_valid(target) or not target.is_alive():
		return
	if _projectile_system and element_key.is_empty():
		_projectile_system.play_crystal_bolt(_crystal_center_global, target.global_position + target.size * 0.5)
	target.apply_damage(damage)
	var hit_pos := target.global_position + target.size * 0.5
	normal_hit.emit(hit_pos)
	if target.is_alive():
		_apply_installed_elements(target, crystal_level, damage)
	if _effect_system:
		if not element_key.is_empty():
			_effect_system.play_element_hit(element_key, hit_pos, clampi(int(_installed_elements.get(element_key, 1)), 1, GameConfig.MAX_CARD_LEVEL))
		_effect_system.play_monster_hit(target)
