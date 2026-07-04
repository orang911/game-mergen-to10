extends Node
class_name ProjectileSystem

const ProjectileViewScene := preload("res://scenes/combat/projectile_view.tscn")

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
		bolt.start_pos = event.origin - parent_layer.global_position
		bolt.end_pos = target.global_position + target.size * 0.5 - parent_layer.global_position
		parent_layer.add_child(bolt)
		parent_layer.move_child(bolt, parent_layer.get_child_count() - 1)
		var tween := bolt.create_tween()
		tween.tween_property(bolt, "progress", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(bolt, "modulate:a", 0.0, 0.12)
		tween.tween_callback(bolt.queue_free)


func play_chain(from_global: Vector2, to_global: Vector2) -> void:
	if parent_layer == null or not is_instance_valid(parent_layer):
		return
	var chain := ChainBolt.new()
	chain.name = "ChainBolt"
	chain.start_pos = from_global - parent_layer.global_position
	chain.end_pos = to_global - parent_layer.global_position
	parent_layer.add_child(chain)
	var tween := chain.create_tween()
	tween.tween_interval(0.08)
	tween.tween_property(chain, "modulate:a", 0.0, 0.15)
	tween.tween_callback(chain.queue_free)
