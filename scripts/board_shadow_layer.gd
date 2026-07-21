extends ColorRect
class_name BoardShadowLayer

const MAX_BLOCKS := 25
const SHADOW_SHADER := preload("res://shaders/board_block_shadow.gdshader")

@export var light_shadow_offset := Vector2(3.0, 6.0)
@export var shadow_softness := 3.5
@export var shadow_corner_radius := 18.0
@export var shadow_color := Color(0.025, 0.045, 0.09, 0.28)

var _shadow_material: ShaderMaterial
var _block_centers := PackedVector2Array()
var _block_half_sizes := PackedVector2Array()
var _block_opacities := PackedFloat32Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	_block_centers.resize(MAX_BLOCKS)
	_block_half_sizes.resize(MAX_BLOCKS)
	_block_opacities.resize(MAX_BLOCKS)
	_shadow_material = ShaderMaterial.new()
	_shadow_material.shader = SHADOW_SHADER
	material = _shadow_material
	_apply_settings()
	_sync_blocks()
	if not RenderingServer.frame_pre_draw.is_connected(_sync_blocks):
		RenderingServer.frame_pre_draw.connect(_sync_blocks)


func configure(board_size: Vector2) -> void:
	position = Vector2.ZERO
	size = board_size
	custom_minimum_size = board_size
	pivot_offset = board_size * 0.5
	if _shadow_material:
		_shadow_material.set_shader_parameter("canvas_size", board_size)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_sync_blocks):
		RenderingServer.frame_pre_draw.disconnect(_sync_blocks)


func _apply_settings() -> void:
	if _shadow_material == null:
		return
	_shadow_material.set_shader_parameter("canvas_size", size)
	_shadow_material.set_shader_parameter("shadow_offset", light_shadow_offset)
	_shadow_material.set_shader_parameter("softness", shadow_softness)
	_shadow_material.set_shader_parameter("corner_radius", shadow_corner_radius)
	_shadow_material.set_shader_parameter("shadow_color", shadow_color)


func _sync_blocks() -> void:
	if _shadow_material == null or get_parent() == null or not is_visible_in_tree():
		return

	var count := 0
	for child in get_parent().get_children():
		if count >= MAX_BLOCKS:
			break
		var block := child as MergeBlock
		if block == null or not is_instance_valid(block) or not block.visible:
			continue
		var opacity := block.modulate.a * block.self_modulate.a
		if opacity <= 0.001:
			continue
		var block_scale := Vector2(absf(block.scale.x), absf(block.scale.y))
		_block_centers[count] = block.position + block.size * 0.5
		_block_half_sizes[count] = GameConfig.BLOCK_VISUAL_SIZE * 0.5 * block_scale
		_block_opacities[count] = opacity
		count += 1

	_shadow_material.set_shader_parameter("block_count", count)
	_shadow_material.set_shader_parameter("block_centers", _block_centers)
	_shadow_material.set_shader_parameter("block_half_sizes", _block_half_sizes)
	_shadow_material.set_shader_parameter("block_opacities", _block_opacities)
