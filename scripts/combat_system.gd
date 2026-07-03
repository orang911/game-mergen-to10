extends Node
class_name CombatSystem

signal merge_attack_received(event: MergeAttackEvent)

var projectile_system: ProjectileSystem
var effect_system: EffectSystem
var running := false

func _ready() -> void:
	projectile_system = ProjectileSystem.new()
	projectile_system.name = "ProjectileSystem"
	add_child(projectile_system)

	effect_system = EffectSystem.new()
	effect_system.name = "EffectSystem"
	add_child(effect_system)

func start_run() -> void:
	running = true
	reset()

func stop_run() -> void:
	running = false
	reset()

func reset() -> void:
	if projectile_system:
		projectile_system.reset()
	if effect_system:
		effect_system.reset()

func layout_for_board(_board_pos: Vector2, _board_size: Vector2) -> void:
	pass

func handle_merge_attack(event: MergeAttackEvent) -> void:
	if not running:
		return
	merge_attack_received.emit(event)
	if effect_system:
		effect_system.play_merge_feedback(event)
	if projectile_system:
		projectile_system.play_merge_attack(event)
