extends SceneTree
func _initialize() -> void:
	var output := "D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/"
	var root := "res://assets/runtime/ui/"
	var art := {"hud_pause":"interfaces/battle/top_hud/buttons/battle_pause_button.png", "hud_wave":"interfaces/battle/top_hud/backplates/battle_wave_panel.png", "hud_timer":"interfaces/battle/top_hud/backplates/battle_timer_panel.png", "hud_clock":"interfaces/battle/top_hud/icons/battle_timer_clock_icon.png", "hud_currency":"interfaces/battle/top_hud/backplates/battle_currency_panel.png", "currency_coin":"shared/currency/icons/currency_coin_v01.png", "currency_diamond":"shared/currency/icons/currency_diamond_v01.png"}
	art["hud_pause_shell"] = "interfaces/battle_pause/backplates/ui_battle_pause_shell_v03.png"
	art["exit_shell"] = "interfaces/exit_confirm/backplates/ui_exit_confirm_shell_v03.png"
	art["settings_panel"] = "interfaces/settings/backplates/settings_panel_v04.png"
	art["settings_row"] = "interfaces/settings/backplates/settings_option_row_music_on_v01.png"
	art["settings_divider"] = "interfaces/settings/decorations/settings_divider_v01.png"
	for id in ["music","sound","vibration","help","privacy","arrow_right"]:
		art["settings_"+id] = "interfaces/settings/icons/settings_"+id+"_v01.png"
	for id in ["on","off"]:
		art["settings_switch_"+id] = "interfaces/settings/controls/settings_switch_"+id+"_v01.png"
	for key in art:
		var texture: Texture2D = load(root + art[key])
		if texture == null:
			quit(1)
			return
		texture.get_image().save_png(output + key + ".png")
	var row: Texture2D = load(root+art.settings_row)
	row.get_image().get_region(Rect2i(104,14,62,54)).save_png(output+"settings_patch_icon.png")
	row.get_image().get_region(Rect2i(184,12,132,58)).save_png(output+"settings_patch_control.png")
	print("Exported navigation art: ", art.size())
	export_folder(root+"interfaces/daily_program/backplates/",output)
	export_folder(root+"interfaces/daily_program/icons/",output)
	quit()
func export_folder(path: String, output: String) -> void:
	for file in DirAccess.get_files_at(path):
		if file.ends_with(".png"):
			var texture: Texture2D = load(path+file)
			texture.get_image().save_png(output+file)
