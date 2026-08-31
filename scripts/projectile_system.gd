extends Node
class_name ProjectileSystem

const ProjectileViewScene := preload("res://scenes/combat/projectile_view.tscn")
const ElementTrailParticlesScript := preload("res://scripts/element_trail_particles.gd")
const MERGE_BOLT_DURATION := 0.14
const ELEMENT_TRAIL_HISTORY_DURATION := 0.10
const ELEMENT_TRAIL_COLLAPSE_FRAMES := 3.0
const ELEMENT_TRAIL_COLLAPSE_DURATION := ELEMENT_TRAIL_COLLAPSE_FRAMES / 60.0
const MULTI_SHOT_EARLY_GAP := 0.07
const MULTI_SHOT_FINAL_GAP := 0.20
# Kept as a source-compatible alias for older callers/tests. New code must use
# the schedule helpers below so every multi-shot path shares one cadence.
const MULTI_SHOT_STAGGER := MULTI_SHOT_EARLY_GAP
const LIGHTNING_LINK_STAGGER := ChainBolt.FRAME_DURATION
const CRYSTAL_RAIN_OFFSCREEN_MARGIN := 160.0
const CRYSTAL_RAIN_FLIGHT_DURATION := 0.20
const CRYSTAL_BEAM_FLIGHT_DURATION := 0.18
const CRYSTAL_BEAM_WIDTH_EXPAND_DURATION := 0.08
const CRYSTAL_BEAM_TEXTURE_PATH := "res://assets/runtime/fx/crystal_tower/attack_beam.png"

var parent_layer: Control
var _generation := 0
var _crystal_beams: Array[MergeBolt] = []


static func get_multi_shot_gap_before(shot_index: int, shot_count: int) -> float:
	var count := maxi(1, shot_count)
	if shot_index <= 0 or count <= 1:
		return 0.0
	if shot_index >= count:
		return 0.0
	return MULTI_SHOT_FINAL_GAP if shot_index == count - 1 else MULTI_SHOT_EARLY_GAP


static func get_multi_shot_launch_offset(shot_index: int, shot_count: int) -> float:
	var count := maxi(1, shot_count)
	var index := clampi(shot_index, 0, count - 1)
	if index <= 0:
		return 0.0
	if index == count - 1 and count >= 2:
		return float(count - 2) * MULTI_SHOT_EARLY_GAP + MULTI_SHOT_FINAL_GAP
	return float(index) * MULTI_SHOT_EARLY_GAP


static func get_multi_shot_post_hit_gap(completed_shot_index: int, shot_count: int) -> float:
	var count := maxi(1, shot_count)
	if completed_shot_index < 0 or completed_shot_index >= count - 1:
		return 0.0
	return MULTI_SHOT_FINAL_GAP if completed_shot_index == count - 2 else MULTI_SHOT_EARLY_GAP


func setup(layer: Control) -> void:
	parent_layer = layer


func reset() -> void:
	_generation += 1
	cancel_crystal_beams()
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	for child in parent_layer.get_children():
		if child is MergeBolt or child is ChainBolt or child.get_script() == ElementTrailParticlesScript:
			child.queue_free()


func play_merge_attack(event: MergeAttackEvent, targets: Array = []) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	# Lightning plus all standardized element projectiles are enabled here.
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
		if event.element != GameConfig.AttackElement.FREEZE and event.element != GameConfig.AttackElement.POISON and event.element != GameConfig.AttackElement.CRITICAL and event.element != GameConfig.AttackElement.FIRE:
			continue
		var shot_delay := get_multi_shot_launch_offset(i, targets.size())
		if shot_delay <= 0.0:
			_spawn_element_bolt(event, target, Callable(), i, targets.size())
		else:
			_schedule_element_bolt(event, target, shot_delay, generation, i, targets.size())


func play_merge_shot(event: MergeAttackEvent, target: Control, target_provider: Callable = Callable(), shot_index: int = 0, shot_count: int = 1) -> bool:
	if event == null or not ["poison", "ice", "lightning", "critical", "fire"].has(event.element_key):
		return false
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return false
	if event.element_key == "lightning":
		var target_center := target.global_position + target.size * 0.5
		play_lightning_link(event.origin_position, target_center, event, null, target)
		return true
	_spawn_element_bolt(event, target, target_provider, shot_index, shot_count)
	return true


func _schedule_element_bolt(event: MergeAttackEvent, target: Control, delay: float, generation: int, shot_index: int = 0, shot_count: int = 1) -> void:
	await get_tree().create_timer(delay, false).timeout
	if generation != _generation or not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	_spawn_element_bolt(event, target, Callable(), shot_index, shot_count)


func _spawn_element_bolt(event: MergeAttackEvent, target, target_provider: Callable = Callable(), shot_index: int = 0, shot_count: int = 1) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var target_control := target as Control
	if target_control == null:
		return
	var target_center := target_control.global_position + target_control.size * 0.5
	var bolt := ProjectileViewScene.instantiate() as MergeBolt
	if bolt == null:
		bolt = MergeBolt.new()
	bolt.name = "%sBolt" % event.element_key.capitalize()
	bolt.apply_event(event)
	bolt.configure_sequence_presentation(shot_index, shot_count)
	bolt.configure_trail_history(MERGE_BOLT_DURATION, ELEMENT_TRAIL_HISTORY_DURATION)
	# All staggered shots retain the merge block center as their fixed origin.
	bolt.start_pos = _global_to_layer_local(event.origin_position)
	bolt.end_pos = _global_to_layer_local(target_center)
	if target_provider.is_valid():
		bolt.track_target_provider(target_provider)
	parent_layer.add_child(bolt)
	parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
	var particles = ElementTrailParticlesScript.new()
	particles.name = "%sTrailParticles" % event.element_key.capitalize()
	particles.configure_sequence_presentation(shot_index, shot_count)
	parent_layer.add_child(particles)
	# Keep the moving orb and shader ribbon above the dispersed element particles.
	parent_layer.move_child(particles, bolt.get_index())
	particles.follow(bolt, event.element_key)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, MERGE_BOLT_DURATION).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(bolt.begin_trail_collapse.bind(ELEMENT_TRAIL_COLLAPSE_DURATION))
	tween.tween_interval(ELEMENT_TRAIL_COLLAPSE_DURATION)
	tween.tween_callback(bolt.queue_free)


func play_crystal_bolt(from_global: Vector2, to_global: Vector2, delay: float = 0.0) -> void:
	if delay > 0.0:
		_schedule_crystal_bolt(from_global, to_global, delay, _generation)
	else:
		_spawn_crystal_bolt(from_global, to_global)


func _schedule_crystal_bolt(from_global: Vector2, to_global: Vector2, delay: float, generation: int) -> void:
	await get_tree().create_timer(delay, false).timeout
	if generation != _generation:
		return
	_spawn_crystal_bolt(from_global, to_global)


func _spawn_crystal_bolt(from_global: Vector2, to_global: Vector2) -> void:
	_spawn_crystal_bolt_visual(from_global, to_global, MERGE_BOLT_DURATION, "CrystalBolt")


func play_crystal_beam(from_global: Vector2, target: Control, flight_duration: float = CRYSTAL_BEAM_FLIGHT_DURATION) -> void:
	# Dedicated charged-shot visual: a single tracking column fired from the
	# crystal tip. Damage timing stays owned by CrystalSystem; this only draws
	# the projectile and follows the moving target until impact.
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return
	var bolt := ProjectileViewScene.instantiate() as MergeBolt
	if bolt == null:
		bolt = MergeBolt.new()
	bolt.name = "CrystalBeam"
	bolt.apply_element_key("crystal", 1)
	var duration := maxf(0.01, flight_duration)
	bolt.configure_trail_history(duration, ELEMENT_TRAIL_HISTORY_DURATION)
	bolt.start_pos = _global_to_layer_local(from_global)
	bolt.end_pos = _global_to_layer_local(target.global_position + target.size * 0.5)
	bolt.track_target_provider(_crystal_beam_target_provider.bind(target.get_instance_id()))
	parent_layer.add_child(bolt, true)
	parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
	# Configure after add_child so MergeBolt._ready() cannot overwrite the
	# supplied beam texture with the generic crystal projectile visuals.
	if ResourceLoader.exists(CRYSTAL_BEAM_TEXTURE_PATH):
		bolt.configure_crystal_beam_visual(load(CRYSTAL_BEAM_TEXTURE_PATH) as Texture2D)
	_crystal_beams.append(bolt)
	bolt.tree_exited.connect(_on_crystal_beam_exited.bind(bolt), CONNECT_ONE_SHOT)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, duration).set_trans(Tween.TRANS_LINEAR)
	# The beam reaches the target on its Y/length axis first. Only after it
	# arrives do we run the X/width 1→4→0 burst, while damage remains owned by
	# CrystalSystem at the original flight-duration boundary.
	tween.tween_callback(bolt.play_crystal_beam_burst.bind(CRYSTAL_BEAM_WIDTH_EXPAND_DURATION, ELEMENT_TRAIL_COLLAPSE_DURATION))
	tween.tween_interval(CRYSTAL_BEAM_WIDTH_EXPAND_DURATION + ELEMENT_TRAIL_COLLAPSE_DURATION)
	tween.tween_callback(bolt.queue_free)


func cancel_crystal_beams() -> void:
	for beam in _crystal_beams:
		if is_instance_valid(beam):
			beam.queue_free()
	_crystal_beams.clear()


func _on_crystal_beam_exited(beam: MergeBolt) -> void:
	_crystal_beams.erase(beam)


func _crystal_beam_target_provider(instance_id: int) -> Control:
	var target := instance_from_id(instance_id) as Control
	if not is_instance_valid(target) or target.is_queued_for_deletion():
		return null
	return target


func play_vertical_crystal_drop(target, fallback_global: Vector2, delay: float = 0.0, impact_callback: Callable = Callable()) -> void:
	var generation := _generation
	if delay > 0.0:
		_schedule_vertical_crystal_drop(target, fallback_global, delay, impact_callback, generation)
	else:
		_spawn_vertical_crystal_drop(target, fallback_global, impact_callback, generation)


func _schedule_vertical_crystal_drop(target, fallback_global: Vector2, delay: float, impact_callback: Callable, generation: int) -> void:
	await get_tree().create_timer(delay, false).timeout
	if generation != _generation:
		return
	_spawn_vertical_crystal_drop(target, fallback_global, impact_callback, generation)


func _spawn_vertical_crystal_drop(target, fallback_global: Vector2, impact_callback: Callable, generation: int) -> void:
	if generation != _generation:
		return
	var impact_position := fallback_global
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		var target_control := target as Control
		if target_control:
			impact_position = target_control.global_position + target_control.size * 0.5
	# Enter from above the actual viewport instead of starting a fixed distance
	# over each monster. This keeps every drop visibly screen-high on tall phones
	# and on centered letterboxed layouts.
	var viewport_top := get_viewport().get_visible_rect().position.y
	var start_position := Vector2(impact_position.x, viewport_top - CRYSTAL_RAIN_OFFSCREEN_MARGIN)
	_spawn_crystal_bolt_visual(
		start_position,
		impact_position,
		CRYSTAL_RAIN_FLIGHT_DURATION,
		"CrystalRainBolt",
		_complete_vertical_crystal_drop.bind(target, impact_position, impact_callback, generation)
	)


func _complete_vertical_crystal_drop(target, impact_position: Vector2, impact_callback: Callable, generation: int) -> void:
	if generation != _generation:
		return
	if impact_callback.is_valid():
		impact_callback.call(target, impact_position)


func _spawn_crystal_bolt_visual(from_global: Vector2, to_global: Vector2, duration: float, node_name: String, impact_callback: Callable = Callable()) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	var bolt := ProjectileViewScene.instantiate() as MergeBolt
	if bolt == null:
		bolt = MergeBolt.new()
	bolt.name = node_name
	bolt.apply_element_key("crystal", 1)
	var flight_duration := maxf(0.01, duration)
	bolt.configure_trail_history(flight_duration, ELEMENT_TRAIL_HISTORY_DURATION)
	bolt.start_pos = _global_to_layer_local(from_global)
	bolt.end_pos = _global_to_layer_local(to_global)
	parent_layer.add_child(bolt, true)
	parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, flight_duration).set_trans(Tween.TRANS_LINEAR)
	if impact_callback.is_valid():
		tween.tween_callback(impact_callback)
	tween.tween_callback(bolt.begin_trail_collapse.bind(ELEMENT_TRAIL_COLLAPSE_DURATION))
	tween.tween_interval(ELEMENT_TRAIL_COLLAPSE_DURATION)
	tween.tween_callback(bolt.queue_free)


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
