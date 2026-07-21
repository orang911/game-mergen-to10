extends Node
class_name ProjectileSystem

const ProjectileViewScene := preload("res://scenes/combat/projectile_view.tscn")
const IceTrailParticlesScript := preload("res://scripts/ice_trail_particles.gd")
const MERGE_BOLT_DURATION := 0.14
const ICE_TRAIL_HISTORY_DURATION := 0.10
const ICE_TRAIL_COLLAPSE_FRAMES := 3.0
const ICE_TRAIL_COLLAPSE_DURATION := ICE_TRAIL_COLLAPSE_FRAMES / 60.0
const MULTI_SHOT_STAGGER := 0.10
const LIGHTNING_LINK_STAGGER := ChainBolt.FRAME_DURATION

var parent_layer: Control
var _generation := 0


func setup(layer: Control) -> void:
	parent_layer = layer


func reset() -> void:
	_generation += 1
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	for child in parent_layer.get_children():
		if child is MergeBolt or child is ChainBolt or child.get_script() == IceTrailParticlesScript:
			child.queue_free()


func play_merge_attack(event: MergeAttackEvent, targets: Array = []) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	# Only lightning and the newly supplied ice orb are currently enabled.
	# Damage timing remains owned by CombatSystem and is unaffected here.
	var generation := _generation
	for i in range(targets.size()):
		var target = targets[i]
		if not is_instance_valid(target):
			continue
		var target_center: Vector2 = target.global_position + target.size * 0.5
		if event.element == GameConfig.AttackElement.LIGHTNING:
			play_lightning_link(event.origin_position, target_center, event, null, target)
			continue
		if event.element != GameConfig.AttackElement.FREEZE:
			continue
		var shot_delay := float(i) * MULTI_SHOT_STAGGER
		if shot_delay <= 0.0:
			_spawn_ice_bolt(event, target)
		else:
			_schedule_ice_bolt(event, target, shot_delay, generation)


func _schedule_ice_bolt(event: MergeAttackEvent, target: Control, delay: float, generation: int) -> void:
	await get_tree().create_timer(delay).timeout
	if generation != _generation:
		return
	_spawn_ice_bolt(event, target)


func _spawn_ice_bolt(event: MergeAttackEvent, target: Control) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	if not is_instance_valid(target):
		return
	var target_center := target.global_position + target.size * 0.5
	var bolt := ProjectileViewScene.instantiate() as MergeBolt
	if bolt == null:
		bolt = MergeBolt.new()
	bolt.name = "IceBolt"
	bolt.apply_event(event)
	bolt.configure_trail_history(MERGE_BOLT_DURATION, ICE_TRAIL_HISTORY_DURATION)
	# All staggered shots retain the merge block center as their fixed origin.
	bolt.start_pos = _global_to_layer_local(event.origin_position)
	bolt.end_pos = _global_to_layer_local(target_center)
	parent_layer.add_child(bolt)
	parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
	var particles = IceTrailParticlesScript.new()
	particles.name = "IceTrailParticles"
	parent_layer.add_child(particles)
	# Keep the moving orb and shader ribbon above the small snow particles.
	parent_layer.move_child(particles, bolt.get_index())
	particles.follow(bolt)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, MERGE_BOLT_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(bolt.begin_trail_collapse.bind(ICE_TRAIL_COLLAPSE_DURATION))
	tween.tween_interval(ICE_TRAIL_COLLAPSE_DURATION)
	tween.tween_callback(bolt.queue_free)


func play_crystal_bolt(_from_global: Vector2, _to_global: Vector2) -> void:
	# The crystal tower still attacks and resolves damage on its existing timer;
	# only its temporary bolt art is suppressed.
	pass


func play_lightning_link(from_global: Vector2, to_global: Vector2, event: MergeAttackEvent = null, source_target: Control = null, target_target: Control = null) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	var chain := ChainBolt.new()
	chain.name = "LightningLink"
	if event:
		chain.apply_event(event)
	chain.start_pos = _global_to_layer_local(from_global)
	chain.end_pos = _global_to_layer_local(to_global)
	chain.bind_targets(source_target, target_target)
	parent_layer.add_child(chain)
	parent_layer.move_child(chain, parent_layer.get_child_count() - 1)


func play_chain(from_global: Vector2, to_global: Vector2, event: MergeAttackEvent = null, source_target: Control = null, target_target: Control = null) -> void:
	play_lightning_link(from_global, to_global, event, source_target, target_target)


func _global_to_layer_local(global_pos: Vector2) -> Vector2:
	return parent_layer.get_global_transform_with_canvas().affine_inverse() * global_pos
