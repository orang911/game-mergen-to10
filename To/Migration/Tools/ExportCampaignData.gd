extends SceneTree
func _initialize() -> void:
	var config = load("res://scripts/chapter_one_config.gd")
	var data := {"chapter_id": config.CHAPTER_ID, "title": config.TITLE, "waves": config.get_waves()}
	var output := "D:/UGit/T0/To/Assets/MergeTo10/Resources/Campaign"
	DirAccess.make_dir_recursive_absolute(output)
	var file := FileAccess.open(output + "/chapter.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	print("Exported chapter waves: ", data.waves.size())
	var catalog = load("res://scripts/card_catalog.gd")
	var rules = load("res://scripts/game_config.gd")
	var cards := []
	for id in catalog.ALL_CARD_IDS:
		var definition: Dictionary = catalog.get_definition(id)
		definition["id"] = id
		cards.append(definition)
		var texture: Texture2D = load(str(definition.icon))
		if texture:
			texture.get_image().save_png(output + "/" + str(id) + ".png")
	var levels := []
	for level in range(1, 10):
		levels.append(rules.get_base_attack(level))
	var card_data := {"cards": cards, "baseAttack": levels,
		"damageUp": rules.CRYSTAL_DAMAGE_UP_BY_LEVEL, "interval": rules.CRYSTAL_INTERVAL_BY_LEVEL,
		"extraTargets": rules.CRYSTAL_EXTRA_TARGETS_BY_LEVEL, "pierceRatio": rules.CRYSTAL_PIERCE_DAMAGE_RATIO,
		"fireDps": rules.CRYSTAL_FIRE_DPS_RATIO, "fireDuration": rules.CRYSTAL_FIRE_DURATION,
		"poisonDps": rules.CRYSTAL_POISON_DPS_RATIO, "poisonDuration": rules.CRYSTAL_POISON_DURATION,
		"thunderRatio": rules.CRYSTAL_THUNDER_CHAIN_RATIO}
	file = FileAccess.open(output + "/cards.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(card_data, "\t"))
	file.close()
	print("Exported active cards and crystal rules: ", cards.size())
	for family in ["goblin", "zombie"]:
		var boss_texture: Texture2D = load("res://assets/runtime/characters/monsters/" + family + "_stage_03.png")
		boss_texture.get_image().save_png(output + "/" + family + "_stage_03.png")
	var node_art := {"node_panel": "backplates/popup_panel_v02.png", "node_title": "decorations/title_plaque_v02.png", "node_divider": "decorations/crystal_divider.png", "node_button": "buttons/primary_button_v02.png"}
	for key in node_art:
		var node_texture: Texture2D = load("res://assets/runtime/ui/interfaces/chapter_node_complete/" + str(node_art[key]))
		node_texture.get_image().save_png(output + "/" + str(key) + ".png")
	var choices := {"choice_title": "interfaces/crystal_card_choice/decorations/ui_title_ribbon_blank_1070x216_2x_v01.png", "choice_confirm": "interfaces/crystal_card_choice/buttons/ui_button_confirm_blank_464x152_2x_v01.png", "choice_front": "interfaces/crystal_card_choice/backplates/ui_choice_card_with_slot_blank_450x840_2x_v01.png", "choice_star": "components/rating_stars/icons/star_active.png", "choice_star_slot": "components/rating_stars/icons/star_slot.png"}
	for key in choices:
		var choice_texture: Texture2D = load("res://assets/runtime/ui/" + str(choices[key]))
		choice_texture.get_image().save_png(output + "/" + str(key) + ".png")
	var card_back: Texture2D = load(catalog.CRYSTAL_BACK) if ResourceLoader.exists(catalog.CRYSTAL_BACK) else null
	var new_badge: Texture2D = load("res://assets/runtime/ui/interfaces/crystal_card_choice/decorations/ui_badge_corner_blank_96x96_2x_v01.png")
	new_badge.get_image().save_png(output + "/choice_new.png")
	if card_back:
		card_back.get_image().save_png(output + "/choice_back.png")
	else:
		# Source CrystalChoiceCardViewV2 leaves this missing texture empty.
		var blank := Image.create(1, 1, false, Image.FORMAT_RGBA8)
		blank.fill(Color.TRANSPARENT)
		blank.save_png(output + "/choice_back.png")
		print("Source card back missing: exported transparent source-equivalent placeholder")
	var energy_art := {"energy_panel": "backplates/skill_panel_frame.png", "energy_disabled": "icons/skill_disabled_icon.png", "energy_slot": "icons/skill_disabled_icon1.png", "energy_swap": "icons/instant_cluster_swap.png", "energy_rain": "icons/instant_crystal_rain.png", "energy_locked": "icons/locked_item_slot.png"}
	for key in energy_art:
		var texture: Texture2D = load("res://assets/runtime/ui/interfaces/battle/energy_hud/" + str(energy_art[key]))
		texture.get_image().save_png(output + "/" + str(key) + ".png")
	var imprint_art := {"imprint_card": "backplates/ui_item_card_blank_300x636_2x_v01.png", "imprint_confirm": "buttons/ui_button_confirm_blank_330x120_2x_v01.png", "imprint_ad": "buttons/ui_button_ad_unlock_blank_316x92_2x_v01.png", "imprint_new": "decorations/ui_badge_new_blank_128x120_2x_v01.png", "imprint_title": "decorations/ui_title_banner_blank_304x52_v01.png"}
	for key in imprint_art:
		var texture: Texture2D = load("res://assets/runtime/ui/interfaces/imprint_choice/" + str(imprint_art[key]))
		texture.get_image().save_png(output + "/" + str(key) + ".png")
	quit()
