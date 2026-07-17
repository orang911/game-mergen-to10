extends Control
class_name MergeTrailGhost

const GHOST_SHADER := preload("res://shaders/merge_trail_ghost.gdshader")
const MAX_TRAIL_ALPHA := 0.38

var _materials: Array[ShaderMaterial] = []
var _trail_alpha := 0.0

var trail_alpha: float:
	get:
		return _trail_alpha
	set(value):
		_trail_alpha = clampf(value, 0.0, 1.0)
		for shader_material in _materials:
			if shader_material and is_instance_valid(shader_material):
				shader_material.set_shader_parameter("fade", _trail_alpha)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process_input(false)
	trail_alpha = 0.0


func setup_from_block(block: MergeBlock) -> void:
	if block == null or not is_instance_valid(block):
		return

	size = block.size
	pivot_offset = size * 0.5
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child_name in ["Shadow", "Bg", "LabelOverlay"]:
		var source := block.get_node_or_null(child_name) as TextureRect
		if source == null or source.texture == null:
			continue
		var copy := TextureRect.new()
		copy.name = "Ghost_%s" % child_name
		copy.texture = source.texture
		copy.expand_mode = source.expand_mode
		copy.stretch_mode = source.stretch_mode
		copy.position = source.position
		copy.size = source.size
		copy.rotation = source.rotation
		copy.pivot_offset = source.pivot_offset
		copy.modulate = Color.WHITE
		copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shader_material := ShaderMaterial.new()
		shader_material.shader = GHOST_SHADER
		shader_material.set_shader_parameter("fade", _trail_alpha)
		shader_material.set_shader_parameter("source_modulate", source.modulate)
		copy.material = shader_material
		_materials.append(shader_material)
		add_child(copy)

	trail_alpha = 0.0
	queue_redraw()


func play_to(target_position: Vector2, delay: float, duration: float) -> void:
	var travel_time := maxf(0.12, duration * 1.12)
	var fade_in_time := minf(0.06, travel_time * 0.45)
	var fade_out_time := 0.18
	var target_scale := scale * 0.74
	var tween := create_tween()
	if delay > 0.0:
		tween.tween_interval(delay)
	tween.tween_property(self, "trail_alpha", MAX_TRAIL_ALPHA, fade_in_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "position", target_position, travel_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "scale", target_scale, travel_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "trail_alpha", 0.0, fade_out_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
