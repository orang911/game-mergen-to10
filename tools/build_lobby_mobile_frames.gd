extends SceneTree

const SOURCE := "res://../art/production/lobby/2026-08-08_lobby_hd_reset_and_cutout_v01/cutouts/frames/"
const OUTPUT := "res://assets/runtime/ui/interfaces/main_hub/backplates/"
const MISSION_PANEL_WITH_SOCKET := "lobby_mission_panel_with_reward_slot_default_v01.png"
const MISSION_PANEL_PLAIN := "lobby_mission_panel_plain_default_v01.png"

# Scale each HD cutout uniformly until one axis matches its authored lobby
# slot. NinePatch then extends only the remaining safe centre axis.
const SCALES := {
	"lobby_settings_button_frame_default_v01.png": 0.7142857,
	"lobby_currency_counter_panel_default_v01.png": 0.4938525,
	"lobby_mission_panel_with_reward_slot_default_v01.png": 0.71875,
	"lobby_progress_track_default_v01.png": 0.4444444,
	"lobby_progress_fill_green_v01.png": 0.3953488,
	"lobby_reward_slot_purple_default_v02.png": 0.51953125,
	"lobby_side_menu_button_frame_default_v01.png": 0.6833333,
	"lobby_primary_level_button_default_v01.png": 0.6761905,
	"lobby_bottom_navigation_background_v01.png": 1.0,
	"lobby_navigation_tab_selected_v01.png": 0.625,
}


func _init() -> void:
	var output_dir := ProjectSettings.globalize_path(OUTPUT)
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Unable to create lobby mobile-frame output directory")
		quit(1)
		return
	for file_name in SCALES:
		var image := Image.load_from_file(ProjectSettings.globalize_path(SOURCE + file_name))
		if image == null or image.is_empty():
			push_error("Unable to load lobby frame: %s" % file_name)
			quit(1)
			return
		var scale_factor := float(SCALES[file_name])
		var target := Vector2i(
			maxi(1, roundi(image.get_width() * scale_factor)),
			maxi(1, roundi(image.get_height() * scale_factor))
		)
		if target != image.get_size():
			image.resize(target.x, target.y, Image.INTERPOLATE_LANCZOS)
		var error := image.save_png(ProjectSettings.globalize_path(OUTPUT + file_name))
		if error != OK:
			push_error("Unable to save lobby frame %s: %s" % [file_name, error_string(error)])
			quit(1)
			return
		print("LOBBY_MOBILE_FRAME %s %dx%d" % [file_name, target.x, target.y])
	if not _build_plain_mission_panel():
		quit(1)
		return
	quit(0)


func _build_plain_mission_panel() -> bool:
	var source := Image.load_from_file(ProjectSettings.globalize_path(OUTPUT + MISSION_PANEL_WITH_SOCKET))
	if source == null or source.is_empty():
		push_error("Unable to load the mobile mission panel for socket removal")
		return false
	# The old reward socket is baked into the right half. Mirror the clean left
	# half around the exact centreline so the outer frame, gradient and shadow
	# remain pixel-matched while the duplicate socket disappears completely.
	var plain := Image.create(source.get_width(), source.get_height(), false, source.get_format())
	for y in range(source.get_height()):
		for x in range(source.get_width()):
			var source_x := x if x < source.get_width() / 2 else source.get_width() - 1 - x
			plain.set_pixel(x, y, source.get_pixel(source_x, y))
	var error := plain.save_png(ProjectSettings.globalize_path(OUTPUT + MISSION_PANEL_PLAIN))
	if error != OK:
		push_error("Unable to save plain mission panel: %s" % error_string(error))
		return false
	print("LOBBY_MOBILE_FRAME %s %dx%d" % [MISSION_PANEL_PLAIN, plain.get_width(), plain.get_height()])
	return true
