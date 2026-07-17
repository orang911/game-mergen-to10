extends Node
class_name ProjectileSystem

const ProjectileViewScene := preload("res://scenes/combat/projectile_view.tscn")
const MERGE_BOLT_DURATION := 0.24

var parent_layer: Control


func setup(layer: Control) -> void:
	parent_layer = layer


func reset() -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	for child in parent_layer.get_children():
		if child is MergeBolt or child is ChainBolt:
			child.queue_free()


func play_merge_attack(event: MergeAttackEvent, targets: Array = []) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	for target in targets:
		if not is_instance_valid(target):
			continue
		var bolt := ProjectileViewScene.instantiate() as MergeBolt
		if bolt == null:
			bolt = MergeBolt.new()
		bolt.name = "MergeBolt"
		bolt.apply_event(event)
		bolt.start_pos = _global_to_layer_local(event.origin_position)
		bolt.end_pos = _global_to_layer_local(target.global_position + target.size * 0.5)
		parent_layer.add_child(bolt)
		parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
		var tween := bolt.create_tween()
		tween.tween_property(bolt, "progress", 1.0, MERGE_BOLT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bolt, "modulate:a", 0.0, 0.12)
		tween.tween_callback(bolt.queue_free)


func play_crystal_bolt(from_global: Vector2, to_global: Vector2) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	var bolt := ProjectileViewScene.instantiate() as MergeBolt
	if bolt == null:
		bolt = MergeBolt.new()
	bolt.name = "CrystalBolt"
	bolt.start_pos = _global_to_layer_local(from_global)
	bolt.end_pos = _global_to_layer_local(to_global)
	parent_layer.add_child(bolt)
	parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
	var tween := bolt.create_tween()
	tween.tween_property(bolt, "progress", 1.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(bolt, "modulate:a", 0.0, 0.12)
	tween.tween_callback(bolt.queue_free)


func play_chain(from_global: Vector2, to_global: Vector2, event: MergeAttackEvent = null) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	var chain := ChainBolt.new()
	chain.name = "ChainBolt"
	if event:
		chain.apply_event(event)
	chain.start_pos = _global_to_layer_local(from_global)
	chain.end_pos = _global_to_layer_local(to_global)
	parent_layer.add_child(chain)
	var tween := chain.create_tween()
	tween.tween_interval(0.08)
	tween.tween_property(chain, "modulate:a", 0.0, 0.15)
	tween.tween_callback(chain.queue_free)


func _global_to_layer_local(global_pos: Vector2) -> Vector2:
	return parent_layer.get_global_transform_with_canvas().affine_inverse() * global_pos
