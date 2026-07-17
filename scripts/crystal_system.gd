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
var _temporary_element := ""
var _temporary_element_waves := 0


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
	_temporary_element = ""
	_temporary_element_waves = 0
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
	var target_count := 1 + _extra_targets
	if _temporary_element == "lightning":
		target_count += 1
	var targets := _monster_system.get_front_monsters(target_count)
	if targets.is_empty():
		return

	var level := 1
	if _crystal_view:
		level = _crystal_view.get_crystal_level()

	var base_atk := GameConfig.get_base_attack(level)
	var damage: float = roundi(float(base_atk) * DAMAGE_RATIO * _damage_multiplier)

	if _crystal_view:
		_crystal_view.play_attack_flash()

	for i in range(targets.size()):
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
			if target.is_alive() and not _temporary_element.is_empty():
				_apply_crystal_element(target, level, damage)
			if _effect_system:
				_effect_system.play_monster_hit(target)
		)


func apply_upgrade(card_id: String, element_key: String = "", quality: int = 1) -> void:
	var q := clampi(quality, 1, 3)
	match card_id:
		"star_core":
			_damage_multiplier += float(GameConfig.CRYSTAL_DAMAGE_UP_BY_QUALITY[q])
		"rapid_pulse":
			_speed_multiplier *= float(GameConfig.CRYSTAL_INTERVAL_BY_QUALITY[q])
		"double_refraction":
			_extra_targets += int(GameConfig.CRYSTAL_EXTRA_TARGETS_BY_QUALITY[q])
		"element_prism":
			_temporary_element = element_key
			_temporary_element_waves = int(GameConfig.CRYSTAL_ELEMENT_WAVES_BY_QUALITY[q])
	if _crystal_view:
		_crystal_view.play_reward_absorb()


func notify_wave_started() -> void:
	pass


func notify_wave_cleared() -> void:
	if _temporary_element_waves > 0:
		_temporary_element_waves -= 1
		if _temporary_element_waves <= 0:
			_temporary_element = ""


func get_crystal_center_global() -> Vector2:
	return _crystal_center_global


func _apply_crystal_element(target: Monster, level: int, damage: float) -> void:
	var source_level := level
	var desired_index := GameConfig.ELEMENT_ORDER.find(_temporary_element)
	if desired_index >= 0:
		source_level = desired_index + 1
	var event := MergeAttackEvent.from_merge(source_level, level, 2, _crystal_center_global, 0)
	event.damage = damage
	target.apply_element_effect(event)
