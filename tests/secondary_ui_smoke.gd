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
		"settings": 512.0 / 717.0, "clear_confirm": 326.0 / 189.0,
		"daily": 915.0 / 1513.0, "benefits": 700.0 / 714.0,
		"first_purchase": 461.0 / 454.0, "piggy": 445.0 / 493.0,
		"shop": 465.0 / 493.0,
	}
	var expected_sizes := {
		"pause": Vector2(384, 282), "exit_confirm": Vector2(299, 176),
		"settings": Vector2(512, 717), "clear_confirm": Vector2(326, 189),
		"daily": Vector2(915, 1513), "benefits": Vector2(700, 714),
		"first_purchase": Vector2(461, 454), "piggy": Vector2(445, 493),
		"shop": Vector2(465, 493),
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
			has_v03_shell = ui._panel.texture == null and _has_texture(ui._content, "daily_task_panel_shell_fixed_v01.png") and _has_texture(ui._content, "daily_signin_panel_shell_fixed_v01.png")
		elif page_id == "benefits":
			has_v03_shell = ui._panel.texture != null and ui._panel.texture.resource_path.ends_with("benefits_popup_shell_fixed_v01.png")
		_check(has_v03_shell, "%s should use its complete V03 shell" % page_id)

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
	_check(ui._panel.texture.resource_path.ends_with("ui_settings_shell_v03.png"), "settings should use its complete V03 shell")
	_check(ui._content.get_child_count() >= 6, "settings should expose all five formal V03 interaction rows")
	_check(_has_named_texture(ui._content, "Switch_music", "switch_on.png"), "music should render its current on state")
	service.music_enabled = false
	service.changed.emit()
	await process_frame
	_check(_has_named_texture(ui._content, "Switch_music", "switch_off.png"), "music should visually change to off")
	ui.close()
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
	_check(_has_named_texture(ui._content, "BenefitShieldIcon", "benefits_icon_shield_star_v01.png") and _has_named_texture(ui._content, "BenefitCoinIcon", "benefits_icon_coin_stack_v01.png") and _has_named_texture(ui._content, "BenefitNoAdIcon", "benefits_icon_no_ad_base_v01.png"), "benefits must not fall back to any legacy product icon")
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
	_check(_has_texture(ui._content, "daily_task_panel_shell_fixed_v01.png"), "combined daily should use the new continuous task shell")
	_check(_has_texture(ui._content, "daily_signin_panel_shell_fixed_v01.png"), "combined daily should use the new continuous sign-in shell")
	var activity_row := ui._content.get_node_or_null("DailyTaskSection/ActivityRow") as NinePatchRect
	_check(activity_row != null and activity_row.texture != null and activity_row.texture.resource_path.ends_with("daily_task_row_selected_v01.png"), "today activity should use the highlighted gold backplate")
	_check(activity_row != null and activity_row.position == Vector2(24, 126) and activity_row.size == Vector2(872, 179), "today activity backplate should retain the supplied long-panel proportion while aligning to the task-row grid")
	_check(ui._content.get_node_or_null("DailySigninSection/SigninShell") != null, "combined daily should include the seven-day sign-in strip")
	var signin_tab := ui._content.get_node_or_null("DailySigninSection/SigninTab") as Control
	var signin_title := _find_label(ui._content.get_node("DailySigninSection"), "签到")
	_check(signin_tab != null and signin_title != null and signin_tab.position.x == 31.0 and signin_title.position.x == 31.0, "sign-in title art and title text should share the task-section alignment grid")
	_check(_has_texture(ui._content, "daily_icon_merge_v01.png"), "combined daily should use the unified program-composition merge icon")
	for task_id in ["settle_once", "merge_20", "kill_30", "login"]:
		_check(ui._content.get_node_or_null("DailyTaskSection/TaskRow_%s" % task_id) != null, "combined daily should contain task row %s" % task_id)
	for day in range(1, 8):
		_check(ui._content.get_node_or_null("DailySigninSection/SigninCard_%d" % day) != null, "combined daily should contain sign-in card %d" % day)
	var day4_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_4") as Control
	var day5_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_5") as Control
	var day1_label := _find_label(ui._content.get_node("DailySigninSection"), "第1天")
	var day7_reward := ui._content.get_node_or_null("DailySigninSection/SigninReward_7") as TextureRect
	_check(day4_card != null and day5_card != null and day4_card.position.x + day4_card.size.x <= day5_card.position.x + 10.0, "day 4 selected card should not cover day 5 content")
	_check(day1_label != null and day1_label.position.y == 174.0, "compact sign-in day labels should sit in the vertical center of their headers")
	_check(day7_reward != null and day7_reward.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "day seven chest must preserve its native aspect ratio")
	service.signin_last_date = ""
	service.signin_streak = 0
	service.changed.emit()
	await process_frame
	var day1_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_1") as Control
	var day2_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_2") as Control
	var day7_card := ui._content.get_node_or_null("DailySigninSection/SigninCard_7") as Control
	_check(day1_card != null and day2_card != null and day1_card.position.x + day1_card.size.x <= day2_card.position.x + 6.0, "day 1 selected card should reflow instead of covering day 2")
	_check(day7_card != null and day7_card.position.x + day7_card.size.x <= 895.0, "dynamic sign-in row should stay inside the approved card field")
	service.signin_last_date = "2026-08-12"
	service.signin_streak = 3
	service.changed.emit()
	await process_frame
	_check(ui._content.get_node_or_null("DailyCloseButton") != null, "combined daily should expose the formal top-right close action")
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
		_check(claimed_day4 != null and claimed_day4.size.x == 105.0, "claimed current day should return to the compact card width")
		_check(tomorrow_day5 != null and tomorrow_day5.size == Vector2(178, 280), "the next day should become the enlarged selected card immediately after claiming")
		_check(tomorrow_day5 != null and tomorrow_day5.texture.resource_path.ends_with("daily_signin_card_selected_v01.png"), "tomorrow preview should use the yellow selected card art")
		_check(tomorrow_badge != null and tomorrow_badge.disabled and _find_label(tomorrow_badge, "明日领取") != null, "tomorrow preview should show a non-clickable 明日领取 badge")
		service.sync_day("2026-08-14")
		await process_frame
		var next_day_claim := ui._content.get_node_or_null("DailySigninSection/CurrentSigninButton") as TextureButton
		_check(next_day_claim != null and not next_day_claim.disabled and _find_label(next_day_claim, "今日签到") != null, "the tomorrow preview should become today's enabled claim action after the date advances")
	_check(_find_label(ui._content, "任务") != null and _find_label(ui._content, "签到") != null, "both section tabs should be visible at the same time")
	for task_id in MetaProgressService.TASKS:
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
	_check(ui._panel.texture != null and ui._panel.texture.resource_path.ends_with("purchase_popup_shell_fixed_v01.png"), "purchase confirmation should use the dedicated shell")
	_check(ui._content.get_node_or_null("PurchaseDoubleCoinIcon") == null, "non-benefits purchases should keep the generic confirmation content")
	ui._request_purchase("benefits_bundle")
	await process_frame
	_check(ui._content.get_node_or_null("PurchaseDoubleCoinIcon") != null, "benefits confirmation should show the double-coin icon")
	_check(ui._content.get_node_or_null("PurchaseNoAdIcon") != null, "benefits confirmation should show the no-ad icon")
	_check(ui._content.get_node_or_null("PurchaseCancelButton") != null and ui._content.get_node_or_null("PurchaseConfirmButton") != null, "benefits confirmation should expose both art buttons")
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
		if child.name == node_name and child is TextureRect:
			var texture := (child as TextureRect).texture
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
