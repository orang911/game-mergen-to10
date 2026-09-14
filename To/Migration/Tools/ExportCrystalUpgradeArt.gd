extends SceneTree
func _initialize() -> void:
	var output := "D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign/"
	var root := "res://assets/runtime/ui/"
	for folder in ["backplates", "buttons", "icons"]:
		var path: String = root+"interfaces/crystal_upgrade/"+folder+"/"
		for file in DirAccess.get_files_at(path):
			if file.ends_with(".png"):
				var texture: Texture2D = load(path+file)
				texture.get_image().save_png(output+file)
	var extra := {"crystal_background":"interfaces/main_hub/standalone/lobby_background_clean_v01.png","crystal_counter":"interfaces/main_hub/backplates/lobby_currency_counter_panel_default_v01.png","crystal_plus":"shared/meta_icons/atlas_regions/lobby_icon_plus_v01.tres"}
	for key in extra:
		var texture: Texture2D = load(root+extra[key])
		texture.get_image().save_png(output+key+".png")
	print("Crystal upgrade art exported")
	quit()
