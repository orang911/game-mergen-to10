extends Node
class_name CrystalSystem

const ATTACK_INTERVAL := 1.8
const DAMAGE_RATIO := 0.3

var _crystal_view: CrystalView
var _monster_system: MonsterSystem
var _projectile_system: ProjectileSystem
var _effect_system: EffectSystem
var _crystal_center_global := Vector2.ZERO

var _attack_timer := 0.0
var _running := false


func setup(view: CrystalView, monsters: MonsterSystem, projectiles: ProjectileSystem, effects: EffectSystem) -> void:
	_crystal_view = view
	_monster_system = monsters
	_projectile_system = projectiles
	_effect_system = effects


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
	if _crystal_view:
		_crystal_view.reset()


func _process(delta: float) -> void:
	if not _running:
		return
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = ATTACK_INTERVAL
		_try_attack()


func _try_attack() -> void:
	if _monster_system == null:
		return
	var targets := _monster_system.get_front_monsters(1)
	if targets.is_empty():
		return

	var target: Monster = targets[0]
	var level := 1
	if _crystal_view:
		level = _crystal_view.get_crystal_level()

	var base_atk := GameConfig.get_base_attack(level)
	var damage: float = roundi(float(base_atk) * DAMAGE_RATIO)

	if _crystal_view:
		_crystal_view.play_attack_flash()

	if _projectile_system:
		var target_center := target.global_position + target.size * 0.5
		_projectile_system.play_crystal_bolt(_crystal_center_global, target_center)

	get_tree().create_timer(0.15).timeout.connect(func():
		if is_instance_valid(target) and target.is_alive():
			target.apply_damage(damage)
			if _effect_system:
				_effect_system.play_monster_hit(target)
	)
