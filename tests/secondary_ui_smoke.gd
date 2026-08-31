extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service := MetaProgressService.new()
	service.setup(1804, 120, {})
	service.sync_day("2026-08-13")
	var ui := SecondaryUiController.new()
	ui.size = Vector2(941, 1672)
	root.add_child(ui)
	ui.setup(service)
	await process_frame

	var expected_ratios := {
		"pause": 384.0 / 282.0, "exit_confirm": 299.0 / 176.0,
		"settings": 514.0 / 716.0, "clear_confirm": 326.0 / 226.0,
		"daily": 915.0 / 1513.0, "benefits": 700.0 / 714.0,
		"piggy": 700.0 / 714.0,
		"shop": 465.0 / 493.0, "purchase_confirm": 700.0 / 714.0,
	}
	var expected_sizes := {
		"pause": Vector2(384, 282), "exit_confirm": Vector2(299, 176),
		"settings": Vector2(514, 716), "clear_confirm": Vector2(326, 226),
		"daily": Vector2(915, 1513), "benefits": Vector2(700, 714),
		"piggy": Vector2(700, 714),
		"shop": Vector2(465, 493), "purchase_confirm": Vector2(700, 714),
	}
	for page_id in expected_ratios:
		ui.open(page_id)
		await process_frame
		var desired := SecondaryUiController.PAGE_SIZES[page_id] as Vector2
		_check(desired == expected_sizes[page_id], "%s should use the measured effect-image bounds" % page_id)
		_check(absf(desired.aspect() - float(expected_ratios[page_id])) < 0.004, "%s should retain the reference aspect ratio" % page_id)
		var expected_center := (ui.size - desired) * 0.5
		if page_id == "daily":
			expected_center.y = 78.0
		elif page_id == "benefits":
			expected_center.y += 22.0
		var snapped_center := Vector2(roundf(expected_center.x), roundf(expected_center.y))
		_check(ui._panel.position.is_equal_approx(snapped_center), "%s should stay centered and pixel-snapped" % page_id)
		_check(is_equal_approx(ui._panel.scale.x, ui._panel.scale.y), "%s should scale uniformly" % page_id)
		var has_v03_shell := ui._panel.texture != null and (
			ui._panel.texture.resource_path.begins_with("res://assets/runtime/ui/interfaces/")
			or ui._panel.texture.resource_path.begins_with("res://assets/runtime/ui/shared/confirmation/")
		)
		if page_id == "daily":
			has_v03_shell = ui._panel.texture == null and _has_texture(ui._content, "daily_task_panel_shell_complete_v03.png") and _has_texture(ui._content, "daily_signin_panel_shell_complete_v03.png")
		elif page_id == "benefits":
			has_v03_shell = ui._panel.texture != null and ui._panel.texture.resource_path.ends_with("piggy_bank_panel_v01.png")
		_check(has_v03_shell, "%s should use its complete V03 shell" % page_id)
	ui.close()
	ui.open("first_purchase", "hub")
	await process_frame
	_check(not ui.visible and ui.page_id.is_empty(), "first-purchase page should reject every legacy open request while disabled")

	service.piggy_coins = 680
	ui.open("piggy", "hub")
	await process_frame
	_check(ui._panel.size == Vector2(700, 714) and ui._content.size == Vector2(539, 583) and ui._content.scale.x > 1.0, "piggy bank should share the benefits window size while scaling its authored content uniformly")
	_check(ui._panel.texture != null and ui._panel.texture.resource_path.ends_with("piggy_bank_panel_v01.png"), "piggy bank should use the new clean panel art")
	_check(_has_named_texture(ui._content, "PiggyBankTitleRibbon", "piggy_bank_title_ribbon_v01.png"), "piggy bank should compose the supplied title ribbon separately")
	_check(_has_named_texture(ui._content, "PiggyBankStageIcon_1", "piggy_bank_stage_empty_v01.png") and _has_named_texture(ui._content, "PiggyBankStageIcon_4", "piggy_bank_stage_purchased_v01.png"), "piggy bank should render all four delivered stage icons")
	_check(ui._content.get_node_or_null("PiggyBankSelectedFrame_2") != null and ui._content.get_node_or_null("PiggyBankSelectedFrame_1") == null, "680 stored coins should select only the accumulating stage")
	var piggy_fill := ui._content.get_node_or_null("PiggyBankProgressFill") as NinePatchRect
	_check(piggy_fill != null and is_equal_approx(piggy_fill.size.x, 394.0 * 0.68), "piggy bank fill should preserve rounded caps at the live stored-coin ratio")
	var piggy_purchase := ui._content.get_node_or_null("PiggyBankPurchaseButton") as TextureButton
	_check(piggy_purchase != null and piggy_purchase.texture_normal.resource_path.ends_with("piggy_bank_purchase_button_default_v01.png") and _find_label(piggy_purchase, "¥12") != null, "piggy bank should use the supplied yellow purchase action with live price text")
	_check(_find_label(ui._content, "680/1000") != null and _find_label(ui._content, "挑战可积累金币") != null, "piggy bank should draw live progress and explanatory copy inside the supplied plates")
	service.piggy_coins = 1000
	service.changed.emit()
	await process_frame
	_check(ui._content.get_node_or_null("PiggyBankSelectedFrame_3") != null, "a full piggy bank should select the full stage")

	ui.open("crystal_upgrade", "hub")
	await process_frame
	_check(ui._panel.size == Vector2(941, 1672) and ui._content.size == Vector2(941, 1672), "crystal upgrade should use the approved full 941x1672 canvas")
	_check(_has_named_texture(ui._content, "CrystalUpgradeCurrentPanel", "crystal_upgrade_current_section_v03.png"), "crystal upgrade should render the complete v03 current section frame")
	_check(_has_named_texture(ui._content, "CrystalUpgradeCurrentStatsPanel", "crystal_upgrade_current_info_panel_v03.png"), "crystal upgrade should render the complete v03 current info panel")
	_check(_has_named_texture(ui._content, "CrystalUpgradeMaterialsPanel", "crystal_upgrade_materials_section_v03.png"), "crystal upgrade should render the complete v03 materials frame")
	_check(_has_named_texture(ui._content, "CrystalUpgradeMaterialCards", "crystal_upgrade_material_cards_v03.png"), "crystal upgrade should render the complete v03 material cards")
	_check(_has_named_texture(ui._content, "CrystalUpgradePreviewPanel", "crystal_upgrade_preview_section_v03.png"), "crystal upgrade should render the complete v03 preview frame")
	_check(_has_named_texture(ui._content, "CrystalUpgradePreviewStats", "crystal_upgrade_preview_stats_v03.png"), "crystal upgrade should render the complete v03 preview tables")
	_check(_has_named_texture(ui._content, "CrystalUpgradeDisabledButton", "crystal_upgrade_disabled_button_v02.png"), "crystal upgrade should use the delivered disabled action art")
	var crystal_back := ui._content.get_node_or_null("CrystalUpgradeBackButton") as Button
	var crystal_back_art := ui._content.get_node_or_null("CrystalUpgradeBackButton/CrystalUpgradeBackArt") as TextureRect
	_check(crystal_back_art != null and crystal_back_art.texture != null and crystal_back_art.texture.resource_path.ends_with("crystal_upgrade_back_button_default_v03.png"), "crystal upgrade should use the complete v03 return icon")
	_check(crystal_back != null and crystal_back.position == Vector2(23, 25) and crystal_back.size == Vector2(127, 121), "crystal upgrade return icon should occupy the same top-left footprint as the lobby settings control")
	_check(crystal_back_art != null and crystal_back_art.position == Vector2(6, 6) and crystal_back_art.size == Vector2(115, 109), "crystal upgrade return art should match the lobby settings frame's visible bounds instead of filling the complete hit target")
	_check(_find_label(ui._content, "水晶升级") == null, "crystal upgrade top bar should not repeat a page title")
	var crystal_tower := ui._content.get_node_or_null("CrystalUpgradeCurrentTower") as TextureRect
	var preview_current := ui._content.get_node_or_null("CrystalUpgradePreviewCurrent") as TextureRect
	var preview_next := ui._content.get_node_or_null("CrystalUpgradePreviewNext") as TextureRect
	var crystal_currency := ui._content.get_node_or_null("CrystalUpgradeDiamondCounterIcon") as TextureRect
	var coin_currency := ui._content.get_node_or_null("CrystalUpgradeCoinCounterIcon") as TextureRect
	var material_coin := ui._content.get_node_or_null("CrystalUpgradeCoinIcon") as TextureRect
	var crystal_counter := ui._content.get_node_or_null("CrystalUpgradeDiamondCounter") as TextureRect
	var coin_counter := ui._content.get_node_or_null("CrystalUpgradeCoinCounter") as TextureRect
	var crystal_counter_value := ui._content.get_node_or_null("CrystalUpgradeDiamondCounterValue") as Label
	var coin_counter_value := ui._content.get_node_or_null("CrystalUpgradeCoinCounterValue") as Label
	var crystal_counter_plus := ui._content.get_node_or_null("CrystalUpgradeDiamondCounterPlus") as TextureRect
	var coin_counter_plus := ui._content.get_node_or_null("CrystalUpgradeCoinCounterPlus") as TextureRect
	_check(crystal_counter != null and crystal_counter.position == Vector2(205, 53) and crystal_counter.size == CurrencyAssets.HUB_COUNTER_PANEL_SIZE, "crystal upgrade diamond counter should match the corrected native lobby HUD footprint")
	_check(coin_counter != null and coin_counter.position == Vector2(454, 53) and coin_counter.size == CurrencyAssets.HUB_COUNTER_PANEL_SIZE, "crystal upgrade coin counter should match the corrected native lobby HUD footprint")
	_check(crystal_counter != null and crystal_counter.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "crystal upgrade diamond frame should not be stretched")
	_check(coin_counter != null and coin_counter.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "crystal upgrade coin frame should not be stretched")
	_check(crystal_counter != null and crystal_counter.texture.resource_path.ends_with("lobby_currency_counter_panel_default_v01.png"), "crystal upgrade should reuse the lobby currency counter frame")
	_check(coin_counter != null and coin_counter.texture.resource_path.ends_with("lobby_currency_counter_panel_default_v01.png"), "both crystal upgrade counters should reuse the lobby frame")
	_check(crystal_counter_value != null and crystal_counter_value.text == "120" and coin_counter_value != null and coin_counter_value.text == "1804", "crystal upgrade HUD should show the live shared wallet instead of hard-coded sample values")
	_check(crystal_counter_plus != null and crystal_counter_plus.texture.resource_path.ends_with("lobby_icon_plus_v01.tres"), "diamond counter should reuse the lobby add icon")
	_check(coin_counter_plus != null and coin_counter_plus.texture.resource_path.ends_with("lobby_icon_plus_v01.tres"), "coin counter should reuse the lobby add icon")
	_check(crystal_currency != null and crystal_currency.texture.resource_path.ends_with("currency_diamond_v01.png"), "crystal upgrade should reuse the single shared diamond")
	_check(coin_currency != null and coin_currency.texture.resource_path.ends_with("currency_coin_v01.png"), "crystal upgrade top bar should reuse the single shared coin")
	_check(material_coin != null and material_coin.texture.resource_path.ends_with("currency_coin_v01.png"), "crystal upgrade materials should reuse the single shared coin")
	_check(crystal_tower != null and crystal_tower.position == Vector2(105, 272) and crystal_tower.size == Vector2(318, 374), "current crystal art should match the approved reference footprint")
	_check(preview_current != null and preview_current.size == Vector2(136, 174), "current preview crystal should stay clear of the stat table")
	_check(preview_next != null and preview_next.position == Vector2(760, 1256) and preview_next.size == Vector2(136, 178), "next preview crystal should be centered in the right-side safe area")
	var crystal_section_title := _find_label(ui._content, "当前水晶")
	_check(crystal_section_title != null and crystal_section_title.get_theme_font_size("font_size") == 46, "current crystal title should use the approved compact display size")
	var crystal_level := _find_label(ui._content, "Lv.03")
	var fragment_count := _find_label(ui._content, "18/30")
	var coin_count := _find_label(ui._content, "3766/5000")
	_check(crystal_level != null and crystal_level.position == Vector2(476, 268), "current crystal level should be centered inside the baked level badge")
	_check(fragment_count != null and fragment_count.position.y == 919.0, "fragment count should be vertically centered inside its value well")
	_check(coin_count != null and coin_count.position.y == 919.0, "coin count should share the fragment count baseline")
	_check(ui._content.get_node_or_null("CrystalUpgradeLevelBadge") == null and ui._content.get_node_or_null("CrystalUpgradeFeaturePanel") == null, "complete current info art should not be layered with duplicate level or feature plates")

	ui.open("pause", "battle")
	await process_frame
	_check(ui._title.position == Vector2(96, 24) and ui._title.size == Vector2(192, 55), "pause title should align to the approved reference bounds")
	_check(ui._title.get_theme_font_size("font_size") == 33, "pause title should use the approved 33px display size")
	var settings_label := _find_label(ui._content, "设置")
	var exit_label := _find_label(ui._content, "退出")
	_check(settings_label != null and settings_label.position == Vector2(29, 203) and settings_label.size == Vector2(157, 44), "pause settings label should align to its reference tile")
	_check(exit_label != null and exit_label.position == Vector2(199, 203) and exit_label.size == Vector2(156, 44), "pause exit label should align to its reference tile")
	_check(settings_label != null and settings_label.get_theme_font_size("font_size") == 26, "pause action labels should use the approved 26px size")
	var settings_button := ui._content.get_node_or_null("设置Button") as Button
	var exit_button := ui._content.get_node_or_null("退出Button") as Button
	_check(settings_button != null and settings_button.position == Vector2(29, 120) and settings_button.size == Vector2(157, 135), "pause settings hit target should cover the full blue tile")
	_check(exit_button != null and exit_button.position == Vector2(199, 120) and exit_button.size == Vector2(156, 135), "pause exit hit target should cover the full red tile")

	ui.open("exit_confirm", "pause")
	await process_frame
	var confirm_copy := _find_label(ui._content, "退出后将结束本次挑战")
	var continue_label := _find_label(ui._content, "继续挑战")
	var confirm_exit_label := _find_label(ui._content, "确认退出")
	_check(confirm_copy != null and confirm_copy.position == Vector2(20, 8) and confirm_copy.size == Vector2(259, 54), "exit copy should use the approved safe area")
	_check(confirm_copy != null and confirm_copy.get_theme_font_size("font_size") == 20, "exit copy should use the approved 20px size")
	_check(continue_label != null and continue_label.position == Vector2(14, 86) and continue_label.get_theme_font_size("font_size") == 23, "continue label should align above the blue button center")
	_check(confirm_exit_label != null and confirm_exit_label.position == Vector2(152, 86) and confirm_exit_label.get_theme_font_size("font_size") == 23, "confirm-exit label should align to the red button reference")

	ui.open("settings", "pause")
	await process_frame
	_check(ui._panel.texture.resource_path.ends_with("settings_panel_v04.png"), "settings should use the supplied V04 panel")
	_check(ui._content.get_node_or_null("SettingsToggle_music") != null and ui._content.get_node_or_null("SettingsToggle_sound") != null and ui._content.get_node_or_null("SettingsToggle_vibration") != null, "settings should expose all three supplied toggle rows")
	_check(ui._content.get_node_or_null("SettingsBackArt") == null and ui._content.get_node_or_null("SettingsBackButton") == null, "settings should not render a return button")
	_check(_has_named_texture(ui._content, "Switch_music", "settings_switch_on_v01.png"), "music should render the supplied on state")
	var blank_click := InputEventMouseButton.new()
	blank_click.pressed = true
	blank_click.button_index = MOUSE_BUTTON_LEFT
	ui._on_shade_input(blank_click)
	await process_frame
	_check(not ui.visible, "clicking the blank area outside settings should close it")
	ui.open("settings", "pause")
	await process_frame
	var music_toggle := ui._content.get_node_or_null("SettingsToggle_music/SettingsToggleButton_music") as Button
	_check(music_toggle != null, "music row should expose a clickable switch target")
	if music_toggle != null:
		music_toggle.pressed.emit()
	await process_frame
	_check(not service.music_enabled, "clicking the music switch should update the stored setting")
	_check(_has_named_texture(ui._content, "Switch_music", "settings_switch_off_v01.png"), "music should render the supplied off state")
	var clear_data_button := ui._content.get_node_or_null("SettingsClearDataButton") as Button
	_check(clear_data_button != null, "clear-local-data copy should expose a clickable target")
	if clear_data_button != null:
		clear_data_button.pressed.emit()
	await process_frame
	_check(ui.page_id == "clear_confirm", "clear-local-data should replace settings with the confirmation page")
	var clear_message := ui._content.get_node_or_null("ConfirmMessage") as Label
	var clear_cancel := ui._content.get_node_or_null("ClearDataCancelButton") as Button
	var clear_confirm := ui._content.get_node_or_null("ClearDataConfirmButton") as Button
	_check(ui._panel.size == Vector2(326, 226), "clear-data confirmation should use the taller effect-image proportion")
	_check(clear_message != null and clear_message.text == "将删除章节、新手及局内进度" and clear_message.position == Vector2(23, 54), "clear-data copy should remain on one centered line")
	_check(clear_cancel != null and clear_cancel.position == Vector2(30, 145) and clear_cancel.size == Vector2(129, 55), "clear-data cancel copy should align inside the blue button art")
	_check(clear_confirm != null and clear_confirm.position == Vector2(168, 145) and clear_confirm.size == Vector2(127, 55), "clear-data confirmation copy should align inside the red button art")
	if clear_cancel != null:
		clear_cancel.pressed.emit()
	await process_frame
	_check(not ui.visible and ui.page_id.is_empty(), "canceling clear-data confirmation should return directly to the hub")
	await process_frame

	ui.open_benefits("double_coin", "hub")
	await process_frame
	_check(ui.page_id == "benefits", "double-coin entry should open the shared benefits bundle page")
	_check(ui._panel.size == Vector2(700, 714), "benefits should use the approved large centered footprint")
	_check(ui._content.scale == Vector2.ONE and ui._content.size == Vector2(700, 714), "benefits must draw directly at final size instead of scaling a low-resolution overlay canvas")
	_check(int(ui._content.get_meta("benefits_layout_revision", -1)) == SecondaryUiController.BENEFITS_LAYOUT_REVISION, "benefits should expose the current live composition revision")
	_check(ui._title.position == Vector2(126, 25) and ui._title.size == Vector2(192, 75), "benefits title should sit optically centered beside the shield")
	_check(ui._title.get_theme_font_size("font_size") == 53 and ui._title.get_theme_constant("outline_size") == 3, "benefits title should rasterize at its final outlined reference size")
	_check(_find_label(ui._content, "双倍金币") != null and _find_label(ui._content, "去广告") != null, "benefits should show both formal product cards")
	var double_name := ui._content.get_node_or_null("BenefitName_double_coin") as Label
	var remove_ads_name := ui._content.get_node_or_null("BenefitName_remove_ads") as Label
	_check(double_name != null and remove_ads_name != null and double_name.position.y == 331.0 and remove_ads_name.position.y == 331.0, "both product names should sit 15 final pixels above their previous baseline")
	_check(ui._content.get_node_or_null("BenefitCard_double_coin") != null and ui._content.get_node_or_null("BenefitCard_remove_ads") != null, "benefits should render both approved offer-card cutouts")
	_check(ui._content.get_node_or_null("BenefitTitleRibbon") != null and ui._content.get_node_or_null("BenefitShieldIcon") != null, "benefits should render its dedicated ribbon and shield art")
	_check(ui._content.get_node_or_null("BenefitCoinIcon") != null and ui._content.get_node_or_null("BenefitNoAdIcon") != null, "benefits should render both updated product icons")
	var benefits_title_ribbon := ui._content.get_node_or_null("BenefitTitleRibbon") as TextureRect
	var double_card := ui._content.get_node_or_null("BenefitCard_double_coin") as TextureRect
	var remove_ads_card := ui._content.get_node_or_null("BenefitCard_remove_ads") as TextureRect
	_check(benefits_title_ribbon != null and benefits_title_ribbon.position == Vector2(-8, 0) and benefits_title_ribbon.size == Vector2(538, 118), "benefits ribbon should match the approved wide title proportion without cutting into the body frame")
	_check(double_card != null and double_card.position == Vector2(31, 129) and double_card.size == Vector2(315, 469), "double-coin card should retain the approved painted-edge alignment")
	_check(remove_ads_card != null and remove_ads_card.position == Vector2(354, 129) and remove_ads_card.size == Vector2(315, 469), "remove-ads card should share the approved painted-edge grid")
	var permanent_plate := ui._content.get_node_or_null("BenefitPermanentPlate") as TextureRect
	_check(double_card != null and permanent_plate != null and permanent_plate.position.y >= double_card.position.y and permanent_plate.position.y + permanent_plate.size.y <= double_card.position.y + double_card.size.y, "permanent-state button must stay inside the extended double-coin card")
	_check(permanent_plate != null and permanent_plate.position == Vector2(64, 461) and permanent_plate.size == Vector2(248, 72), "permanent-state button should use the approved narrow, right-aligned footprint")
	var permanent_text := ui._content.get_node_or_null("BenefitPermanent") as Label
	_check(permanent_text != null and permanent_text.position == Vector2(71, 467) and permanent_text.size == Vector2(236, 55), "permanent-state copy should be centered within its green plate")
	_check(_has_named_texture(ui._content, "BenefitCard_double_coin", "benefits_offer_card_v01.png") and _has_named_texture(ui._content, "BenefitTitleRibbon", "benefits_title_ribbon_v01.png"), "benefits card and ribbon must come from the approved v01 cutouts")
	_check(_has_named_texture(ui._content, "BenefitShieldIcon", "benefits_icon_shield_star_v01.png") and _has_named_texture(ui._content, "BenefitCoinIcon", "benefits_icon_coin_stack_v01.png") and _has_named_texture(ui._content, "BenefitNoAdIcon", "benefits_icon_no_ad_base_v01.png"), "benefits should retain the original dedicated double-coin icon")
	_check(_find_label(ui._content, "购买中") == null and _find_label(ui._content, "购买失败") == null and _find_label(ui._content, "恢复购买") == null, "benefits should not expose the old four-state art-review strip")
	var benefits_cta := ui._content.get_node_or_null("BenefitsPurchaseButton") as TextureButton
	_check(benefits_cta != null and benefits_cta.position == Vector2(164, 565) and benefits_cta.size == Vector2(365, 116), "benefits should expose one fully visible centered yellow purchase action")
	_check(benefits_cta != null and benefits_cta.texture_normal != null and benefits_cta.texture_normal.resource_path.ends_with("benefits_button_purchase_v01.png"), "benefits purchase should use its dedicated yellow art")
	_check(ui._content.get_node_or_null("BenefitPermanentPlate") != null, "benefits should use the dedicated green permanent-state art")
	_check(_find_label(benefits_cta, "¥6") != null and not benefits_cta.disabled, "fresh benefits bundle should show one enabled ¥6 action")
	service.double_coin_owned = true
	service.remove_ads_owned = false
	service.changed.emit()
	await process_frame
	benefits_cta = ui._content.get_node_or_null("BenefitsPurchaseButton") as TextureButton
	_check(benefits_cta != null and _find_label(benefits_cta, "¥6") != null and not benefits_cta.disabled, "a legacy profile owning only one benefit should still be able to buy the bundle")
	service.remove_ads_owned = true
	service.changed.emit()
	await process_frame
	benefits_cta = ui._content.get_node_or_null("BenefitsPurchaseButton") as TextureButton
	_check(benefits_cta != null and _find_label(benefits_cta, "已拥有") != null and benefits_cta.disabled, "the bundle should become owned only after both benefits are present")
	ui.close()
	await process_frame

	service.task_progress["settle_once"] = 0
	service.task_progress["merge_20"] = 12
	service.task_progress["kill_30"] = 30
	service.task_progress["login"] = 1
	service.task_claimed["login"] = true
	service.signin_last_date = "2026-08-12"
	service.signin_streak = 3
	ui.open("daily")
	await process_frame
	_check(ui._panel.size == Vector2(915, 1513), "daily should use the combined reference coordinate space")
	_check(ui._panel.position.is_equal_approx(Vector2(13, 78)), "combined daily sheet should align to the approved top inset")
	_check(ui._daily_tab == "combined", "daily should no longer switch between separate task and sign-in pages")
	_check(ui._panel.texture == null, "combined daily should not stack a generic panel below its two shells")
	_check(ui._content.get_node_or_null("DailyTaskSection") != null, "combined daily should contain the task section")
	_check(ui._content.get_node_or_null("DailySigninSection") != null, "combined daily should contain the sign-in section")
	_check(_has_texture(ui._content, "daily_task_panel_shell_complete_v03.png"), "combined daily should use the reviewed complete task shell")
	_check(_has_texture(ui._content, "daily_signin_panel_shell_complete_v03.png"), "combined daily should use the reviewed complete sign-in shell")
	var task_shell := ui._content.get_node_or_null("DailyTaskSection/TaskPanelShell") as TextureRect
	var signin_shell := ui._content.get_node_or_null("DailySigninSection/SigninShell") as TextureRect
	_check(task_shell != null and task_shell.position == Vector2(-6, 0) and task_shell.size == Vector2(927, 1041), "task shell should keep the reviewed layer_014 proportions")
	_check(signin_shell != null and signin_shell.position == Vector2(-6, 0) and signin_shell.size == Vector2(928, 434), "sign-in shell should keep the reviewed layer_013 proportions")
	_check(ui._content.get_node_or_null("DailyTaskSection/TaskTab") == null, "complete task shell should not stack the legacy title tab")
	_check(ui._content.get_node_or_null("DailySigninSection/SigninTab") == null, "complete sign-in shell should not stack the legacy title tab")
	_check(ui._content.get_node_or_null("DailySigninSection/SigninCardField") == null, "complete sign-in shell should not stack the legacy blue card field")
	_check(ui._content.get_node_or_null("DailyTaskSection/ActivityRow") == null, "today activity should use the blue state baked into the reviewed task shell without a second backplate")
	_check(ui._content.get_node_or_null("DailySigninSection/SigninShell") != null, "combined daily should include the seven-day sign-in strip")
	var signin_title := ui._content.get_node_or_null("DailySigninSection/DailySigninTitle") as Label
	_check(signin_title != null and signin_title.position == Vector2(31, 0) and signin_title.size == Vector2(292, 78), "sign-in title text should be optically centered in the tab body without counting its pointer")
	_check(_has_texture(ui._content, "daily_icon_merge_v01.png"), "combined daily should use the unified program-composition merge icon")
	for task_id in service.get_ordered_task_ids():
		var task_row := ui._content.get_node_or_null("DailyTaskSection/TaskRow_%s" % task_id) as Control
		_check(task_row != null, "combined daily should contain task row %s" % task_id)
		var task_name := task_row.get_node_or_null("TaskName_%s" % task_id) as Label if task_row != null else null
		var task_reward := task_row.get_node_or_null("TaskReward_%s" % task_id) as Label if task_row != null else null
		var task_reward_icon := task_row.get_node_or_null("TaskRewardIcon_%s" % task_id) as TextureRect if task_row != null else null
		var task_state := service.get_task_state(task_id)
		var reward := task_state.get("reward", {}) as Dictionary
		var reward_kind := "crystals" if reward.has("crystals") else "coins"
		_check(task_name != null and task_name.text == str(task_state.get("title", "")), "task row title should come from the shared task definition: %s" % task_id)
		_check(task_reward != null and task_reward.text == "×%d" % int(reward.get(reward_kind, 0)), "task row reward should come from the shared task definition: %s" % task_id)
		_check(task_reward_icon != null and task_reward_icon.texture.resource_path.ends_with("currency_diamond_v01.png" if reward_kind == "crystals" else "currency_coin_v01.png"), "task row should use the single shared currency icon: %s" % task_id)
	for day in range(1, 8):
		_check(ui._content.get_node_or_null("DailySigninSection/SigninCard_%d" % day) != null, "combined daily should contain sign-in card %d" % day)
	var day4_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_4") as TextureRect
	var day5_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_5") as Control
	var day1_label := ui._content.get_node_or_null("DailySigninSection/SigninDayLabel_1") as Label
	var day7_reward := ui._content.get_node_or_null("DailySigninSection/SigninReward_7") as TextureRect
	var day1_reward := ui._content.get_node_or_null("DailySigninSection/SigninReward_1") as TextureRect
	var day2_reward := ui._content.get_node_or_null("DailySigninSection/SigninReward_2") as TextureRect
	_check(day1_reward != null and day1_reward.texture.resource_path.ends_with("currency_diamond_v01.png"), "sign-in crystal rewards should use the single shared diamond")
	_check(day2_reward != null and day2_reward.texture.resource_path.ends_with("currency_coin_v01.png"), "sign-in coin rewards should use the single shared coin")
	_check(day4_card != null and day4_card.size == Vector2(138, 239) and day4_card.texture.resource_path.ends_with("daily_signin_card_selected_v02.png"), "day 4 available card should use the reviewed yellow card at native proportions")
	_check(day4_card != null and day5_card != null and day4_card.position.x + day4_card.size.x <= day5_card.position.x, "day 4 selected card should not cover day 5 content")
	_check(day1_label != null and day1_label.position.y == 168.0 and day1_label.get_theme_font_size("font_size") == 26, "sign-in day labels should use the enlarged shared header baseline")
	_check(day7_reward != null and day7_reward.size == Vector2(116, 104) and day7_reward.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "day seven chest should use the enlarged native-aspect footprint")
	service.signin_last_date = ""
	service.signin_streak = 0
	service.changed.emit()
	await process_frame
	var day1_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_1") as Control
	var day2_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_2") as Control
	var day7_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_7") as Control
	_check(day1_card != null and day1_card.size == Vector2(138, 239), "day 1 selected card should use the reviewed yellow native size")
	_check(day1_card != null and day2_card != null and day1_card.position.x + day1_card.size.x <= day2_card.position.x, "day 1 selected card should reflow instead of covering day 2")
	_check(day7_card != null and day7_card.position.x + day7_card.size.x <= 895.0, "dynamic sign-in row should stay inside the approved card field")
	service.signin_last_date = "2026-08-12"
	service.signin_streak = 3
	service.changed.emit()
	await process_frame
	var aligned_daily_close := ui._content.get_node_or_null("DailyCloseButton") as TextureButton
	var task_title := ui._content.get_node_or_null("DailyTaskSection/DailyTaskTitle") as Label
	var activity_icon := ui._content.get_node_or_null("DailyTaskSection/DailyActivityIcon") as TextureRect
	var activity_title := ui._content.get_node_or_null("DailyTaskSection/DailyActivityTitle") as Label
	var activity_progress_text := ui._content.get_node_or_null("DailyTaskSection/DailyActivityProgressText") as Label
	var activity_progress_track := ui._content.get_node_or_null("DailyTaskSection/ProgressTrack") as Control
	var activity_progress_fill := ui._content.get_node_or_null("DailyTaskSection/ProgressFill") as Control
	var activity_chest := ui._content.get_node_or_null("DailyTaskSection/DailyActivityChest") as TextureRect
	var activity_chest_reward := ui._content.get_node_or_null("DailyTaskSection/DailyActivityChestReward") as Label
	_check(aligned_daily_close != null and aligned_daily_close.position == Vector2(796, -4) and aligned_daily_close.size == Vector2(97, 92), "combined daily should lift the formal top-right close action above the task-panel border")
	_check(task_title != null and task_title.position == Vector2(43, 0) and task_title.size == Vector2(388, 90), "task title should be optically centered in the tab body without counting its pointer")
	_check(activity_icon != null and activity_icon.position == Vector2(64, 130) and activity_icon.size == Vector2(150, 150), "activity badge should use the compact reviewed footprint")
	_check(activity_title != null and activity_title.position == Vector2(195, 164) and activity_title.get_theme_font_size("font_size") == 32, "activity title should align above the extended progress track")
	_check(activity_progress_text != null and activity_progress_text.position == Vector2(199, 216) and activity_progress_text.size == Vector2(526, 40), "activity progress should extend to the reward safe area")
	_check(activity_progress_track != null and activity_progress_track.get_node_or_null("LeftCap") != null and activity_progress_track.get_node_or_null("RightCap") != null, "daily progress track should render its original rounded ends as separate caps")
	_check(activity_progress_fill != null and activity_progress_fill.get_node_or_null("LeftCap") != null and activity_progress_fill.get_node_or_null("RightCap") != null and activity_progress_fill.get_parent() == ui._content.get_node_or_null("DailyTaskSection"), "daily progress fill should preserve both rounded caps at partial width")
	_check(ui._content.get_node_or_null("DailyTaskSection/ProgressFillClip") == null, "daily progress should not use the pointed-edge clipping path")
	_check(activity_chest != null and activity_chest.position == Vector2(741, 161) and activity_chest.size == Vector2(96, 88), "activity chest should match the compact reference scale")
	_check(activity_chest_reward != null and activity_chest_reward.position == Vector2(733, 238), "activity chest reward should remain centered below the chest")
	_check(ui._content.get_node_or_null("DailyTaskSection/ActivityMilestoneDot_1") == null, "activity header should not restore the removed dotted path")
	var activity_button := ui._content.get_node_or_null("DailyTaskSection/ActivityChestButton") as Button
	_check(activity_button != null and activity_button.disabled, "activity chest should remain disabled below 100 activity")
	var kill_claim := ui._content.get_node_or_null("DailyTaskSection/TaskRow_kill_30/TaskStateButton_claim") as TextureButton
	_check(kill_claim != null and not kill_claim.disabled, "completed unclaimed task should expose the gold claim action")
	if kill_claim != null:
		kill_claim.pressed.emit()
		await process_frame
		_check(bool(service.task_claimed["kill_30"]), "task claim button should call the existing progress service")
	var signin_claim := ui._content.get_node_or_null("DailySigninSection/CurrentSigninButton") as TextureButton
	_check(signin_claim != null and not signin_claim.disabled, "current sign-in card should expose one claim action")
	if signin_claim != null:
		signin_claim.pressed.emit()
		await process_frame
		_check(service.signin_last_date == "2026-08-13", "sign-in action should claim through the existing progress service")
		var claimed_day4 := ui._content.get_node_or_null("DailySigninSection/SigninCard_4") as TextureRect
		var tomorrow_day5 := ui._content.get_node_or_null("DailySigninSection/SigninCard_5") as TextureRect
		var tomorrow_badge := ui._content.get_node_or_null("DailySigninSection/TomorrowSigninBadge") as TextureButton
		var claimed_day4_check := ui._content.get_node_or_null("DailySigninSection/SigninClaimedCheck_4") as TextureRect
		var claimed_day4_label := ui._content.get_node_or_null("DailySigninSection/SigninClaimedLabel_4") as Label
		var claimed_day4_day_label := ui._content.get_node_or_null("DailySigninSection/SigninDayLabel_4") as Label
		var claimed_day4_reward := ui._content.get_node_or_null("DailySigninSection/SigninReward_4") as TextureRect
		var claimed_day4_reward_label := ui._content.get_node_or_null("DailySigninSection/SigninRewardLabel_4") as Label
		_check(claimed_day4 != null and claimed_day4.size == Vector2(107, 239) and claimed_day4.texture.resource_path.ends_with("daily_signin_card_claimed_v02.png"), "claimed current day should turn into the reviewed compact blue claimed card")
		var tomorrow_size := tomorrow_day5.size if tomorrow_day5 != null else Vector2.ZERO
		_check(tomorrow_day5 != null and tomorrow_size.is_equal_approx(Vector2(138, 239)), "the next day should become the wider yellow card immediately after claiming (actual=%s)" % tomorrow_size)
		_check(tomorrow_day5 != null and tomorrow_day5.texture.resource_path.ends_with("daily_signin_card_selected_v02.png"), "tomorrow preview should use the reviewed yellow selected card art")
		_check(tomorrow_badge != null and tomorrow_badge.disabled and _find_label(tomorrow_badge, "明日领取") != null, "tomorrow preview should show a non-clickable 明日领取 badge")
		_check(tomorrow_badge != null and tomorrow_badge.position.is_equal_approx(tomorrow_day5.position + Vector2(12, 190)) and tomorrow_badge.size.is_equal_approx(Vector2(114, 39)), "tomorrow badge should use the reduced button footprint inside the yellow card")
		_check(claimed_day4_check != null and claimed_day4_check.size == Vector2(44, 36), "claimed sign-in state should retain the original green check treatment")
		_check(claimed_day4_label != null and claimed_day4_label.get_theme_font_size("font_size") == 20, "claimed sign-in state should retain its separate readable label")
		_check(ui._content.get_node_or_null("DailySigninSection/SigninClaimedButton_4") == null, "claimed sign-in state should not be converted into a button")
		for claimed_part in [claimed_day4, claimed_day4_day_label, claimed_day4_reward, claimed_day4_reward_label, claimed_day4_check, claimed_day4_label]:
			var grayscale_material := claimed_part.material as ShaderMaterial if claimed_part != null else null
			_check(grayscale_material != null and grayscale_material.shader != null and grayscale_material.shader.resource_path.ends_with("ui_claimed_grayscale.gdshader"), "every visual layer of a claimed sign-in card should use the grayscale shader")
		_check(tomorrow_day5 != null and tomorrow_day5.material == null, "tomorrow's yellow card should remain outside the claimed grayscale shader")
		service.sync_day("2026-08-14")
		await process_frame
		var next_day_claim := ui._content.get_node_or_null("DailySigninSection/CurrentSigninButton") as TextureButton
		_check(next_day_claim != null and not next_day_claim.disabled and _find_label(next_day_claim, "今日签到") != null, "the tomorrow preview should become today's enabled claim action after the date advances")
	_check(_find_label(ui._content, "任务") != null and _find_label(ui._content, "签到") != null, "both section tabs should be visible at the same time")
	for task_id in MetaProgressService.TASK_ORDER:
		service.task_claimed[task_id] = true
	service.changed.emit()
	await process_frame
	activity_button = ui._content.get_node_or_null("DailyTaskSection/ActivityChestButton") as Button
	_check(activity_button != null and not activity_button.disabled, "100 activity should enable the chest hit target")
	if activity_button != null:
		activity_button.pressed.emit()
		await process_frame
		_check(service.activity_claimed, "activity chest should claim through the existing progress service")
	ui.size = Vector2(568, 1012)
	await process_frame
	var narrow_scale := ui._panel.scale.x
	var narrow_visual_top := ui._panel.position.y + ui._panel.pivot_offset.y * (1.0 - narrow_scale)
	var narrow_visual_bottom := narrow_visual_top + ui._panel.size.y * narrow_scale
	_check(absf(narrow_visual_top - 78.0 * narrow_scale) <= 1.5, "narrow daily layout should compensate its centered scale pivot")
	_check(narrow_visual_bottom <= ui.size.y - 40.0, "narrow daily layout should keep the complete sign-in shell visible")
	ui.size = Vector2(941, 1672)
	await process_frame
	var daily_close := ui._content.get_node_or_null("DailyCloseButton") as TextureButton
	_check(daily_close != null and daily_close.texture_normal != null and daily_close.texture_normal.resource_path.ends_with("daily_return_button_v03.png"), "daily close action should use the approved v03 complete arrow button")
	if daily_close != null:
		daily_close.pressed.emit()
		await process_frame
	_check(not ui.visible, "daily close action should return to the lobby")
	ui.open("shop")
	await process_frame
	_check(ui._panel.texture.resource_path.ends_with("ui_shop_shell_v03.png"), "shop should use the complete V03 shell")
	var shop_hotspots := 0
	for child in ui._content.get_children():
		if child is Button and (child as Button).flat:
			shop_hotspots += 1
	_check(shop_hotspots >= 8, "shop should expose four category and four product hit targets without duplicate visual overlays")
	ui._request_purchase("coins_10000")
	await process_frame
	_check(ui.page_id == "purchase_confirm", "shop purchase should require confirmation")
	_check(ui._panel.texture != null and ui._panel.texture.resource_path.ends_with("piggy_bank_panel_v01.png"), "purchase confirmation should use the shared piggy-bank nine-patch shell")
	_check(ui._content.get_node_or_null("PurchaseDoubleCoinIcon") == null, "non-benefits purchases should keep the generic confirmation content")
	var generic_action_buttons: Array[TextureButton] = []
	for child in ui._content.get_children():
		if child is TextureButton and (child as TextureButton).texture_normal != null:
			var button_path := (child as TextureButton).texture_normal.resource_path
			if button_path.ends_with("button_blue_default.png") or button_path.ends_with("button_yellow_default.png"):
				generic_action_buttons.append(child as TextureButton)
	_check(generic_action_buttons.size() == 2, "generic purchase confirmation should expose two action buttons")
	if generic_action_buttons.size() == 2:
		var left_button := generic_action_buttons[0]
		var right_button := generic_action_buttons[1]
		_check(left_button.position == Vector2(35, 340) and left_button.size == Vector2(192, 80), "cancel button should use the unified purchase action size")
		_check(right_button.position == Vector2(291, 340) and right_button.size == Vector2(192, 80), "confirm button should use the unified purchase action size")
	_check(ui._title.position == Vector2(42, 72) and ui._title.size == Vector2(434, 72), "purchase title should use the centered reference title box")
	_check(ui._title.text == "确认购买" and ui._title.get_theme_font_size("font_size") == 34, "generic purchase title should match the benefits confirmation title")
	var generic_prompt := ui._content.get_node_or_null("PurchasePrompt") as Label
	var generic_price := ui._content.get_node_or_null("PurchasePrice") as Label
	_check(generic_prompt != null and generic_prompt.get_theme_font_size("font_size") == 26, "generic purchase prompt should use the unified body size")
	_check(generic_price != null and generic_price.get_theme_font_size("font_size") == 36, "generic purchase price should use the unified price size")
	ui._request_purchase("benefits_bundle")
	await process_frame
	_check(ui._content.get_node_or_null("PurchaseDoubleCoinIcon") != null, "benefits confirmation should show the double-coin icon")
	_check(_has_named_texture(ui._content, "PurchaseDoubleCoinIcon", "purchase_icon_double_coin_base_v01.png"), "benefits confirmation should retain its original double-coin art")
	_check(ui._content.get_node_or_null("PurchaseNoAdIcon") != null, "benefits confirmation should show the no-ad icon")
	_check(ui._content.get_node_or_null("PurchaseCancelButton") != null and ui._content.get_node_or_null("PurchaseConfirmButton") != null, "benefits confirmation should expose both art buttons")
	var purchase_cancel := ui._content.get_node_or_null("PurchaseCancelButton") as TextureButton
	var purchase_confirm := ui._content.get_node_or_null("PurchaseConfirmButton") as TextureButton
	_check(purchase_cancel != null and purchase_cancel.texture_normal != null and purchase_cancel.texture_normal.resource_path.ends_with("shared/buttons/states/button_blue_default.png"), "purchase cancel should use the shared blue button")
	_check(purchase_confirm != null and purchase_confirm.texture_normal != null and purchase_confirm.texture_normal.resource_path.ends_with("shared/buttons/states/button_yellow_default.png"), "purchase confirm should use the shared yellow button")
	_check(purchase_cancel != null and purchase_cancel.size == Vector2(192, 80) and _find_label(purchase_cancel, "取消").get_theme_font_size("font_size") == 28, "benefits cancel action should use the unified button and label size")
	_check(purchase_confirm != null and purchase_confirm.size == Vector2(192, 80) and _find_label(purchase_confirm, "确认购买").get_theme_font_size("font_size") == 28, "benefits confirmation action should use the unified button and label size")
	service.crystals = 0
	ui.open("shop")
	var state := ui._product_state("coins_10000")
	_check(not bool(state["enabled"]) and str(state["text"]) == "水晶不足", "shop should expose insufficient currency state")

	# First-purchase cleanup used to queue_free the permanent title nodes. The
	# next modal refresh then called add_theme_color_override on a freed Label.
	ui._play_first_purchase_reward()
	await process_frame
	await process_frame
	_check(is_instance_valid(ui._title), "first-purchase reward cleanup must preserve the permanent title label")
	_check(is_instance_valid(ui._title_bar), "first-purchase reward cleanup must preserve the permanent title bar")
	if is_instance_valid(ui._title) and is_instance_valid(ui._title_bar):
		ui.open("benefits")
		await process_frame
		_check(ui._title.text == "权益", "a secondary page should refresh normally after the first-purchase reward")

	ui.queue_free()
	await process_frame
	if failures.is_empty():
		print("SECONDARY_UI_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func _has_texture(node: Node, suffix: String) -> bool:
	for child in node.get_children():
		if child is TextureRect and (child as TextureRect).texture and (child as TextureRect).texture.resource_path.ends_with(suffix):
			return true
		if child is NinePatchRect and (child as NinePatchRect).texture and (child as NinePatchRect).texture.resource_path.ends_with(suffix):
			return true
		if _has_texture(child, suffix):
			return true
	return false


func _has_named_texture(node: Node, node_name: String, suffix: String) -> bool:
	for child in node.get_children():
		if child.name == node_name and (child is TextureRect or child is NinePatchRect):
			var texture: Texture2D = (child as TextureRect).texture if child is TextureRect else (child as NinePatchRect).texture
			return texture != null and texture.resource_path.ends_with(suffix)
		if _has_named_texture(child, node_name, suffix):
			return true
	return false


func _count_texture(node: Node, suffix: String) -> int:
	var count := 0
	for child in node.get_children():
		if child is TextureRect and (child as TextureRect).texture and (child as TextureRect).texture.resource_path.ends_with(suffix):
			count += 1
		if child is NinePatchRect and (child as NinePatchRect).texture and (child as NinePatchRect).texture.resource_path.ends_with(suffix):
			count += 1
		if child is TextureButton and (child as TextureButton).texture_normal and (child as TextureButton).texture_normal.resource_path.ends_with(suffix):
			count += 1
		count += _count_texture(child, suffix)
	return count


func _find_label(node: Node, text: String) -> Label:
	for child in node.get_children():
		if child is Label and (child as Label).text == text:
			return child as Label
		var nested := _find_label(child, text)
		if nested != null:
			return nested
	return null
