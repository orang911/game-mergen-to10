extends SceneTree

var _failed := false


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var battle := game.combat_system.battle_layer as BattleLayerView
	var pause_button := battle.get_node("DesignRoot/HudLayer/BackButton") as TextureButton
	var sound_button := battle.get_node_or_null("DesignRoot/HudLayer/MusicButton") as TextureButton
	var home_button := battle.get_node_or_null("DesignRoot/HudLayer/HomeButton") as TextureButton
	var wave_icon := battle.get_node_or_null("DesignRoot/HudLayer/WaveStatusIcon") as TextureRect
	var timer_icon := battle.get_node("DesignRoot/HudLayer/TimerStatusIcon") as TextureRect
	var currency_icon := battle.get_node("DesignRoot/HudLayer/CurrencyIcon") as TextureRect
	var coin_label := battle.get_node("DesignRoot/HudLayer/CurrencyLabel") as Label
	var time_label := battle.get_node("DesignRoot/HudLayer/TimeLabel") as Label
	var wave_label := battle.get_node("DesignRoot/HudLayer/WaveLabel") as Label
	var wave_count_label := battle.get_node("DesignRoot/HudLayer/WaveCountLabel") as Label
	var wave_frame := battle.get_node("DesignRoot/HudLayer/WaveBanner/Frame") as NinePatchRect
	var time_frame := battle.get_node("DesignRoot/HudLayer/TimeBanner/Frame") as NinePatchRect
	var currency_frame := battle.get_node("DesignRoot/HudLayer/CurrencyBanner/Frame") as NinePatchRect

	_check(_path_ends(pause_button.texture_normal, "ui/interfaces/battle/top_hud/buttons/battle_pause_button.png"), "pause should use the organized battle HUD art")
	_check(_path_ends(timer_icon.texture, "ui/interfaces/battle/top_hud/icons/battle_timer_clock_icon.png"), "timer should use the organized clock icon")
	_check(_path_ends(currency_icon.texture, "ui/shared/currency/icons/currency_coin_v01.png"), "battle currency should use the single shared coin icon")
	_check(sound_button == null and home_button == null and wave_icon == null, "removed v2 controls and status icon should not remain in the scene")
	_check(wave_frame != null and time_frame != null and currency_frame != null, "all three information plates should use nine-patch frames")
	_check(_path_ends(wave_frame.texture, "ui/interfaces/battle/top_hud/backplates/battle_wave_panel.png"), "wave plate should use the organized frame")
	_check(_path_ends(time_frame.texture, "ui/interfaces/battle/top_hud/backplates/battle_timer_panel.png"), "time plate should use the organized frame")
	_check(_path_ends(currency_frame.texture, "ui/interfaces/battle/top_hud/backplates/battle_currency_panel.png"), "currency plate should use the organized frame")
	_check(wave_frame.patch_margin_left > 0 and wave_frame.axis_stretch_horizontal == 0, "wave frame should preserve its border without tiling")
	_check(time_frame.patch_margin_top > 0 and currency_frame.patch_margin_right > 0, "time and currency frames should preserve their corners")
	_check(_rect_matches(timer_icon, Vector2(519, 39), Vector2(37, 37)), "clock should remain centered in the bottom-aligned timer frame")
	_check(coin_label.get_theme_font_size("font_size") == 28, "coin text should match the new program-font scale")
	_check(wave_label.get_theme_constant("outline_size") == 5 and wave_label.get_theme_constant("shadow_offset_y") == 3, "wave text should keep the requested outline and shadow")
	_check(time_label.get_theme_constant("outline_size") == 5 and coin_label.get_theme_constant("outline_size") == 5, "numeric text should keep a strong dark outline")
	_check(battle.get_node_or_null("DesignRoot/HudLayer/TopTrack") == null, "duplicated top durability track should be removed")
	_check(battle.get_node_or_null("DesignRoot/HudLayer/TopFillClip") == null, "duplicated top durability fill should be removed")
	_check(battle.get_node_or_null("DesignRoot/HudLayer/TopLevel") == null, "duplicated top level badge should be removed")
	_check(_rect_matches(pause_button, Vector2(30, 11), Vector2(84, 88)), "pause bottom edge should align with the complete top HUD row")
	_check(_rect_matches(battle.get_node("DesignRoot/HudLayer/WaveBanner"), Vector2(216, 15), Vector2(268, 84)), "wave frame should use the shared top-HUD baseline")
	_check(_rect_matches(battle.get_node("DesignRoot/HudLayer/TimeBanner"), Vector2(506, 15), Vector2(178, 84)), "timer frame should use the shared top-HUD baseline")
	_check(_rect_matches(battle.get_node("DesignRoot/HudLayer/CurrencyBanner"), Vector2(772, 15), Vector2(153, 84)), "currency frame should retain the approved legacy battle-reference position")
	_check(currency_frame.position == Vector2.ZERO and currency_frame.pivot_offset == Vector2.ZERO, "scaled currency frame must stay anchored to the banner top-left")
	var currency_banner := battle.get_node("DesignRoot/HudLayer/CurrencyBanner") as Control
	var currency_visual_right: float = currency_banner.position.x + currency_frame.position.x + currency_frame.size.x * currency_frame.scale.x
	_check(currency_visual_right <= 925.1, "currency frame must keep its rounded right edge inside the 941px design viewport")
	var blue_hud_visible_bottoms := PackedFloat32Array([
		pause_button.position.y + pause_button.size.y,
		15.0 + 84.0 * (189.0 / 190.0),
		15.0 + 84.0 * (208.0 / 209.0),
	])
	for visible_bottom in blue_hud_visible_bottoms:
		_check(absf(visible_bottom - 99.0) <= 0.6, "the blue top-HUD frames should meet the shared Y=99 baseline")
	_check(_visual_size_matches(currency_frame, Vector2(153, 84)), "currency nine-patch should retain the approved reference footprint")
	_check(_rect_matches(currency_icon, Vector2(713, 14), Vector2(82, 86)), "coin icon should retain the approved battle-reference position")
	_check(_rect_matches(coin_label, Vector2(795, 19), Vector2(127, 75)), "coin amount should retain the approved battle-reference position")
	_check(absf((currency_icon.position.y + currency_icon.size.y * 0.5) - (coin_label.position.y + coin_label.size.y * 0.5)) <= 1.0, "coin icon and amount should remain vertically centered with each other")
	_check(_visual_size_matches(wave_frame, Vector2(268, 84)), "wave nine-patch should fill its updated visual bounds")
	_check(_visual_size_matches(time_frame, Vector2(178, 84)), "timer nine-patch should fill its updated visual bounds")
	_check(wave_frame.patch_margin_left == 90 and time_frame.patch_margin_left == 90, "blue plates should protect the complete source-art corners")
	_check(currency_frame.patch_margin_top == 65, "currency plate should include its transparent source padding in the protected edge")
	battle.set_wave_text("续战 01")
	_check(wave_label.text == "续战01" and wave_label.get_theme_font_size("font_size") == 28, "continuation label should fit without adding duplicate wave wording")

	var energy_hud := game.energy_hud as EnergyHud
	var skill_panel := energy_hud.get_node("SkillPanelFrame") as TextureRect
	var skill_meter := energy_hud.get_node("EnergyMeterFrame") as Panel
	var skill_disabled := energy_hud.get_node("SkillDisabledIcon") as TextureRect
	var skill_inactive := energy_hud.get_node("SkillInactiveIcon") as TextureRect
	var pending_skill_icon := energy_hud.get_node("PendingSkillIcon") as TextureRect
	var refresh_icon := energy_hud.get_node("ClusterSwapItem/Icon") as TextureRect
	var wand_icon := energy_hud.get_node("CrystalRainItem/Icon") as TextureRect
	var locked_icon := energy_hud.get_node("LockedItem") as TextureRect
	_check(_path_ends(skill_panel.texture, "ui/interfaces/battle/energy_hud/backplates/skill_panel_frame.png"), "bottom skill panel should use the organized art")
	_check(skill_meter != null, "energy meter should remain available as a dynamic program-drawn control")
	_check(_path_ends(skill_disabled.texture, "ui/interfaces/battle/energy_hud/icons/skill_disabled_icon.png"), "skill slot should use the permanent outer frame")
	_check(_path_ends(skill_inactive.texture, "ui/interfaces/battle/energy_hud/icons/skill_disabled_icon1.png"), "inactive skill should use the supplied inner glyph")
	_check(skill_disabled.get_index() < skill_inactive.get_index() and skill_inactive.get_index() < pending_skill_icon.get_index(), "skill slot frame and content should use the approved back-to-front layer order")
	_check(_rect_matches(skill_disabled, EnergyHud.PENDING_ICON_POS, EnergyHud.PENDING_ICON_SIZE) and _rect_matches(skill_inactive, EnergyHud.PENDING_ICON_POS, EnergyHud.PENDING_ICON_SIZE), "frame and inactive glyph should share the authored canvas")
	_check(_rect_matches(pending_skill_icon, EnergyHud.PENDING_CONTENT_POS, EnergyHud.PENDING_CONTENT_SIZE), "selected imprint should stay inside the frame safe area")
	_check(_path_ends(refresh_icon.texture, "ui/interfaces/battle/energy_hud/icons/instant_cluster_swap.png"), "first item should use the organized cluster-swap icon")
	_check(_path_ends(wand_icon.texture, "ui/interfaces/battle/energy_hud/icons/instant_crystal_rain.png"), "second item should use the organized crystal-rain icon")
	_check(_path_ends(locked_icon.texture, "ui/interfaces/battle/energy_hud/icons/locked_item_slot.png"), "third item should use the organized locked-slot icon")
	_check(_rect_matches(skill_panel, Vector2(22, 31), Vector2(400, 147)), "skill panel should match the supplied reference")
	_check(_rect_matches(energy_hud.get_node("ClusterSwapItem"), Vector2(529, 43), Vector2(115, 129)), "refresh item should match the supplied preview scale and alignment")
	_check(_rect_matches(energy_hud.get_node("CrystalRainItem"), Vector2(657, 43), Vector2(114, 129)), "wand item should match the supplied preview scale and alignment")
	_check(_rect_matches(locked_icon, Vector2(785, 43), Vector2(115, 125)), "locked item should share the supplied preview top edge and visual baseline")
	_check(not game.score_label.visible and not game.best_label.visible, "legacy score labels should not leak below the new bottom HUD")

	energy_hud.set_energy(100, 100)
	energy_hud.set_pending_skill("")
	_check(skill_disabled.visible and skill_inactive.visible and not pending_skill_icon.visible, "inactive state should keep the frame and show only the inactive glyph")
	_check(energy_hud._ready_label.text == "能量已满\n等待选择印记", "a restored full meter should show the automatic-choice waiting state")
	_check(energy_hud._ready_label.get_theme_font_size("font_size") == EnergyHud.READY_LABEL_DOUBLE_FONT_SIZE, "full-energy two-line copy must use the compact font size")
	energy_hud.set_pending_skill("ascension_hammer")
	_check(skill_disabled.visible and not skill_inactive.visible and pending_skill_icon.visible and pending_skill_icon.texture != null, "selected imprint should replace only the inner glyph while retaining the frame")
	_check(energy_hud._ready_label.text == "下一次合成：待触发\n星阶铸锤", "pending imprint copy must retain both approved rows")
	_check(energy_hud._ready_label.get_theme_font_size("font_size") == EnergyHud.READY_LABEL_DOUBLE_FONT_SIZE, "pending imprint copy must use the compact two-line font size")
	_check(energy_hud._ready_label.get_theme_constant("line_spacing") == EnergyHud.READY_LABEL_DOUBLE_LINE_SPACING, "pending imprint rows must use compact line spacing")
	_check(energy_hud._ready_label.position.y + energy_hud._ready_label.size.y <= EnergyHud.ENERGY_FRAME_POS.y, "two-line copy must not overlap the energy meter")
	_check(energy_hud._ready_label.get_minimum_size().x <= energy_hud._ready_label.size.x + 0.01, "pending imprint copy must fit inside the skill panel width")
	for imprint_id in GameConfig.ENERGY_IMPRINT_POOL_IDS:
		energy_hud.set_pending_skill(imprint_id)
		_check(energy_hud._ready_label.get_theme_font_size("font_size") <= EnergyHud.READY_LABEL_DOUBLE_FONT_SIZE, "%s pending copy must use the compact font size" % imprint_id)
		_check(energy_hud._ready_label.get_minimum_size().x <= energy_hud._ready_label.size.x + 0.01, "%s pending copy must remain inside the HUD text safe area" % imprint_id)
		_check(energy_hud._ready_label.position.y + energy_hud._ready_label.size.y <= EnergyHud.ENERGY_FRAME_POS.y, "%s pending copy must stay above the meter" % imprint_id)
	energy_hud.set_pending_skill("")
	_check(skill_disabled.visible and skill_inactive.visible and not pending_skill_icon.visible, "consuming or clearing an imprint should restore the framed inactive glyph")

	battle.set_wave_base_state(false)
	_check(battle.get_wave_status_name() == "wave", "normal wave state should remain available behind the textless HUD")
	battle.set_wave_base_state(true)
	_check(battle.get_wave_status_name() == "boss", "boss wave state should remain available behind the textless HUD")
	battle.set_wave_danger(true)
	_check(battle.get_wave_status_name() == "warning", "danger should override boss status")
	battle.set_wave_complete(true)
	_check(battle.get_wave_status_name() == "complete", "wave complete should have the highest priority")
	battle.set_wave_complete(false)
	battle.set_wave_danger(false)

	battle.set_coin_value(4321)
	_check(coin_label.text == "4321", "coin value should update from the shared wallet")
	battle.start_run_hud(77.8)
	_check(absf(battle.get_elapsed_seconds() - 77.8) < 0.01 and time_label.text == "01:17", "revive should restore the previous run time")
	battle.stop_run_hud()
	battle.set_wave_base_state(true)

	var threat := Monster.new()
	threat.path_progress = 0.86
	game.combat_system.monster_system.monsters.append(threat)
	game.combat_system._hud_durability_ratio = 1.0
	game.combat_system._refresh_hud_danger_state()
	_check(battle.get_wave_status_name() == "warning", "a monster at 85 percent path progress should enable warning")
	threat.path_progress = 0.20
	game.combat_system._refresh_hud_danger_state()
	_check(battle.get_wave_status_name() == "boss", "cleared path danger should restore the current boss state")
	game.combat_system._hud_durability_ratio = 0.25
	game.combat_system._refresh_hud_danger_state()
	_check(battle.get_wave_status_name() == "warning", "25 percent crystal durability should enable warning")
	game.combat_system.monster_system.monsters.erase(threat)
	threat.free()
	game.combat_system._hud_durability_ratio = 1.0
	game.combat_system._refresh_hud_danger_state()

	var coins_before: int = game.get_coin_balance()
	var crystals_before: int = game.get_crystal_balance()
	game._run_rewards_committed = false
	_check(game._apply_run_rewards_once({"reward_coins": 17, "reward_crystals": 3}), "first settlement reward should be credited")
	_check(not game._apply_run_rewards_once({"reward_coins": 17, "reward_crystals": 3}), "same run settlement reward should not be credited twice")
	_check(game.get_coin_balance() == coins_before + 17 and game.get_crystal_balance() == crystals_before + 3, "wallet should receive the unchanged settlement rewards once")

	battle.set_run_hud_paused(true)
	_check(battle._timer_paused, "paused HUD should retain the existing pause state")
	battle.set_run_hud_paused(false)
	_check(not battle._timer_paused, "running HUD should leave the pause state")
	battle.set_sound_muted(true)
	_check(battle._sound_muted, "removed sound control must not break mute state")
	battle.set_sound_muted(false)
	_check(not battle._sound_muted, "removed sound control must not break unmute state")

	game.game_layer.visible = true
	game.game_status = game.GameStatus.START
	game._success_popup_active = false
	game._chapter_transition_active = false
	game.active_card_modal = null
	game._manual_paused = false
	game._toggle_manual_pause()
	_check(paused, "the live pause action should still pause the tree")
	game._toggle_manual_pause()
	_check(not paused, "the live resume action should still resume the tree")
	game.muted = false
	game._toggle_mute()
	_check(game.muted, "the live mute action should still update audio state")
	game._toggle_mute()
	_check(not game.muted, "the live unmute action should still restore audio state")
	if game.click_player:
		game.click_player.stop()
	if game.merge_player:
		game.merge_player.stop()
	for player in game._combo_audio_players:
		player.stop()

	game.queue_free()
	await process_frame
	await process_frame
	print("BATTLE_TOP_HUD_SMOKE_OK" if not _failed else "BATTLE_TOP_HUD_SMOKE_FAILED")
	quit(1 if _failed else 0)


func _path_ends(texture: Texture2D, suffix: String) -> bool:
	if texture == null:
		return false
	if texture is AtlasTexture:
		return (texture as AtlasTexture).atlas.resource_path.ends_with(suffix)
	return texture.resource_path.ends_with(suffix)


func _rect_matches(control: Control, expected_position: Vector2, expected_size: Vector2) -> bool:
	return control.position.is_equal_approx(expected_position) and control.size.is_equal_approx(expected_size)


func _visual_size_matches(control: Control, expected_size: Vector2) -> bool:
	return (control.size * control.scale).is_equal_approx(expected_size)


func _check(condition: bool, message: String) -> void:
	if condition:
		return
	_failed = true
	push_error(message)
