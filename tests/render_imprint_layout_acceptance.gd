extends SceneTree

const MODAL_SCENE := preload("res://scenes/ui/imprint_choice_modal_v2.tscn")
const ENERGY_HUD_SCRIPT := preload("res://scripts/energy_hud.gd")
const OUTPUT_DIR := "user://imprint_layout_acceptance/"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(941, 1672)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.transparent_bg = false
	root.add_child(viewport)

	var background := ColorRect.new()
	background.color = Color(0.22, 0.39, 0.20, 1.0)
	background.size = Vector2(941.0, 1672.0)
	viewport.add_child(background)

	var modal := MODAL_SCENE.instantiate() as ImprintChoiceModalV2
	viewport.add_child(modal)
	await _render_modal_batch(viewport, modal, ["ascension_hammer", "unity_dial", "fate_shuffler"], "cards_a.png")
	await _render_modal_batch(viewport, modal, ["twin_mold", "castle_cannon", "dragon_catapult"], "cards_b.png")
	modal.queue_free()
	paused = false
	await process_frame

	var hud := ENERGY_HUD_SCRIPT.new() as EnergyHud
	hud.position = Vector2(14.0, 1435.0)
	viewport.add_child(hud)
	await process_frame
	hud.set_energy(100, 100)
	hud.set_pending_skill("unity_dial")
	await process_frame
	_save(viewport, "hud.png")
	print("IMPRINT_LAYOUT_ACCEPTANCE_RENDER_OK: %s" % ProjectSettings.globalize_path(OUTPUT_DIR))
	hud.queue_free()
	viewport.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _render_modal_batch(viewport: SubViewport, modal: ImprintChoiceModalV2, ids: Array[String], filename: String) -> void:
	modal.setup(ids, Vector2.ZERO, [1, 5, 5], [false, false, false], [false, false, false], false)
	for _frame in range(3):
		await process_frame
	_save(viewport, filename)


func _save(viewport: SubViewport, filename: String) -> void:
	var image := viewport.get_texture().get_image()
	var error := image.save_png(ProjectSettings.globalize_path(OUTPUT_DIR + filename))
	if error != OK:
		push_error("Failed to save %s: %s" % [filename, error_string(error)])
