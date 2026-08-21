extends RefCounted
class_name RuntimeAtlas

const PADDED_ATLAS_PATHS := {
	"res://assets/runtime/characters/monsters/atlases/slime_stage_01_walk_sheet.png": 4,
	"res://assets/runtime/characters/monsters/atlases/slime_stage_01_hit_sheet.png": 4,
	"res://assets/runtime/characters/monsters/atlases/monster_death_sheet.png": 4,
	"res://assets/runtime/characters/monsters/atlases/tutorial_armored_walk_sheet.png": 4,
	"res://assets/runtime/characters/monsters/atlases/tutorial_armored_hit_sheet.png": 4,
	"res://assets/runtime/fx/merge/atlases/merge_sheet.png": 4,
	"res://assets/runtime/fx/elements/lightning/atlases/beam_sheet.png": 4,
	"res://assets/runtime/fx/portal/atlases/gate_portal_sheet_mobile.png": 4,
}


static func load_grid(
	sheet_path: String,
	frame_size: Vector2,
	frame_count: int,
	columns: int
) -> Array[Texture2D]:
	var frames: Array[Texture2D] = []
	if frame_count <= 0 or columns <= 0:
		push_error("Invalid atlas grid arguments: %s" % sheet_path)
		return frames
	var padding := int(PADDED_ATLAS_PATHS.get(sheet_path, 0))
	if not ResourceLoader.exists(sheet_path):
		push_error("Missing runtime atlas: %s" % sheet_path)
		return frames
	var sheet := ResourceLoader.load(sheet_path, "Texture2D") as Texture2D
	if sheet == null:
		push_error("Failed to load runtime atlas: %s" % sheet_path)
		return frames
	var pitch := frame_size + Vector2.ONE * float(padding * 2)
	var required_rows := ceili(float(frame_count) / float(columns))
	var required_size := Vector2(float(columns), float(required_rows)) * pitch
	if sheet.get_size().x < required_size.x or sheet.get_size().y < required_size.y:
		push_error("Runtime atlas is smaller than its declared grid: %s" % sheet_path)
		return frames
	for frame_index in range(frame_count):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			Vector2(float(frame_index % columns), floorf(float(frame_index) / float(columns))) * pitch
				+ Vector2.ONE * float(padding),
			frame_size
		)
		atlas.filter_clip = true
		frames.append(atlas)
	return frames
