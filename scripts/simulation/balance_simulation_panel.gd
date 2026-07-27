extends Control
class_name BalanceSimulationPanel

signal closed

const STANDARD_RUN_COUNT := 1000
const ATTACK_RUN_COUNT := 1000
const BOARD_RUN_COUNT := 100
const BOARD_MERGE_LIMIT := 500
const TAB_NAMES := ["总览", "棋盘", "战斗", "诊断"]

var _runner: BalanceSimulationRunner
var _status_label: Label
var _progress_bar: ProgressBar
var _progress_label: Label
var _start_button: Button
var _board_button: Button
var _attack_button: Button
var _cancel_button: Button
var _copy_button: Button
var _close_button: Button
var _tab_selector: OptionButton
var _result_text: RichTextLabel
var _result: Dictionary = {}
var _pending_close := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_as_relative = false
	z_index = 500
	_build_ui()
	_runner = BalanceSimulationRunner.new()
	_runner.name = "BalanceSimulationRunner"
	add_child(_runner)
	_runner.progress_changed.connect(_on_progress_changed)
	_runner.simulation_completed.connect(_on_simulation_completed)
	_runner.simulation_cancelled.connect(_on_simulation_cancelled)
	_runner.simulation_failed.connect(_on_simulation_failed)


func _build_ui() -> void:
	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.015, 0.035, 0.92)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)

	var panel := Panel.new()
	panel.name = "Panel"
	panel.anchor_left = 0.035
	panel.anchor_top = 0.025
	panel.anchor_right = 0.965
	panel.anchor_bottom = 0.975
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var title := _label("数值验证模拟器", 38, Color(0.90, 0.96, 1.0))
	title.anchor_left = 0.04
	title.anchor_top = 0.025
	title.anchor_right = 0.72
	title.anchor_bottom = 0.085
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(title)

	_close_button = _button("关闭", Color(0.36, 0.42, 0.60))
	_close_button.anchor_left = 0.78
	_close_button.anchor_top = 0.025
	_close_button.anchor_right = 0.96
	_close_button.anchor_bottom = 0.078
	_close_button.pressed.connect(_on_close_pressed)
	panel.add_child(_close_button)

	var description := _label("当前/V1/V2/V2动态 · 3种策略 · 棋盘攻击+基础水晶塔 · 不影响正式存档", 19, Color(0.68, 0.76, 0.91))
	description.anchor_left = 0.04
	description.anchor_top = 0.082
	description.anchor_right = 0.96
	description.anchor_bottom = 0.122
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(description)

	_start_button = _button("开始标准模拟（12000局）", Color(0.10, 0.55, 0.92))
	_start_button.anchor_left = 0.04
	_start_button.anchor_top = 0.135
	_start_button.anchor_right = 0.245
	_start_button.anchor_bottom = 0.19
	_start_button.pressed.connect(_start_standard_simulation)
	panel.add_child(_start_button)

	_board_button = _button("纯棋盘500步", Color(0.18, 0.62, 0.45))
	_board_button.anchor_left = 0.255
	_board_button.anchor_top = 0.135
	_board_button.anchor_right = 0.405
	_board_button.anchor_bottom = 0.19
	_board_button.pressed.connect(_start_board_simulation)
	panel.add_child(_board_button)

	_attack_button = _button("新旧攻击对比（6000局）", Color(0.50, 0.34, 0.78))
	_attack_button.anchor_left = 0.415
	_attack_button.anchor_top = 0.135
	_attack_button.anchor_right = 0.655
	_attack_button.anchor_bottom = 0.19
	_attack_button.pressed.connect(_start_attack_simulation)
	panel.add_child(_attack_button)

	_cancel_button = _button("取消", Color(0.72, 0.28, 0.25))
	_cancel_button.anchor_left = 0.665
	_cancel_button.anchor_top = 0.135
	_cancel_button.anchor_right = 0.775
	_cancel_button.anchor_bottom = 0.19
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_on_cancel_pressed)
	panel.add_child(_cancel_button)

	_copy_button = _button("复制CSV路径", Color(0.25, 0.50, 0.66))
	_copy_button.anchor_left = 0.785
	_copy_button.anchor_top = 0.135
	_copy_button.anchor_right = 0.96
	_copy_button.anchor_bottom = 0.19
	_copy_button.disabled = true
	_copy_button.pressed.connect(_copy_report_path)
	panel.add_child(_copy_button)

	_status_label = _label("等待开始。标准模式每种策略1000局。", 21, Color(0.85, 0.90, 1.0))
	_status_label.anchor_left = 0.04
	_status_label.anchor_top = 0.205
	_status_label.anchor_right = 0.96
	_status_label.anchor_bottom = 0.245
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	panel.add_child(_status_label)

	_progress_bar = ProgressBar.new()
	_progress_bar.anchor_left = 0.04
	_progress_bar.anchor_top = 0.25
	_progress_bar.anchor_right = 0.82
	_progress_bar.anchor_bottom = 0.285
	_progress_bar.min_value = 0.0
	_progress_bar.max_value = 12000.0
	_progress_bar.show_percentage = false
	panel.add_child(_progress_bar)

	_progress_label = _label("0 / 12000", 19, Color(0.82, 0.88, 1.0))
	_progress_label.anchor_left = 0.83
	_progress_label.anchor_top = 0.247
	_progress_label.anchor_right = 0.96
	_progress_label.anchor_bottom = 0.29
	panel.add_child(_progress_label)

	_tab_selector = OptionButton.new()
	_tab_selector.anchor_left = 0.04
	_tab_selector.anchor_top = 0.302
	_tab_selector.anchor_right = 0.35
	_tab_selector.anchor_bottom = 0.35
	_tab_selector.add_theme_font_size_override("font_size", 22)
	for tab_name in TAB_NAMES:
		_tab_selector.add_item(tab_name)
	_tab_selector.item_selected.connect(func(_index: int): _refresh_result_text())
	panel.add_child(_tab_selector)

	_result_text = RichTextLabel.new()
	_result_text.name = "ResultText"
	_result_text.anchor_left = 0.04
	_result_text.anchor_top = 0.365
	_result_text.anchor_right = 0.96
	_result_text.anchor_bottom = 0.96
	_result_text.bbcode_enabled = true
	_result_text.fit_content = false
	_result_text.scroll_active = true
	_result_text.selection_enabled = true
	_result_text.add_theme_font_size_override("normal_font_size", 20)
	_result_text.add_theme_color_override("default_color", Color(0.87, 0.91, 1.0))
	_result_text.text = "点击“开始标准模拟”后，界面会保持响应。\n完成后这里将显示三套候选规则相对当前版的结果。"
	panel.add_child(_result_text)


func _start_standard_simulation() -> void:
	if _runner == null or _runner.is_running():
		return
	_result.clear()
	_result_text.text = "正在准备模拟数据……"
	_progress_bar.value = 0.0
	_progress_bar.max_value = float(STANDARD_RUN_COUNT * BalanceSimulationEngine.SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size())
	_progress_label.text = "0 / %d" % int(_progress_bar.max_value)
	_status_label.text = "后台模拟进行中，正常游戏界面不会被修改。"
	_start_button.disabled = true
	_board_button.disabled = true
	_attack_button.disabled = true
	_cancel_button.disabled = false
	_copy_button.disabled = true
	if not _runner.start_standard(STANDARD_RUN_COUNT):
		_start_button.disabled = false
		_board_button.disabled = false
		_attack_button.disabled = false
		_cancel_button.disabled = true


func _start_board_simulation() -> void:
	if _runner == null or _runner.is_running():
		return
	_result.clear()
	_result_text.text = "正在运行纯棋盘推进模拟……"
	_progress_bar.value = 0.0
	_progress_bar.max_value = float(BOARD_RUN_COUNT * BalanceSimulationEngine.BOARD_SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size())
	_progress_label.text = "0 / %d" % int(_progress_bar.max_value)
	_status_label.text = "只计算棋盘合成，不计攻击、怪物、卡牌和即时技能。"
	_start_button.disabled = true
	_board_button.disabled = true
	_attack_button.disabled = true
	_cancel_button.disabled = false
	_copy_button.disabled = true
	if not _runner.start_board_progression(BOARD_RUN_COUNT, BOARD_MERGE_LIMIT):
		_start_button.disabled = false
		_board_button.disabled = false
		_attack_button.disabled = false
		_cancel_button.disabled = true


func _start_attack_simulation() -> void:
	if _runner == null or _runner.is_running():
		return
	_result.clear()
	_result_text.text = "正在配对比较旧多目标与新连续集火规则……"
	_progress_bar.value = 0.0
	_progress_bar.max_value = float(ATTACK_RUN_COUNT * BalanceSimulationEngine.ATTACK_RULE_SCENARIOS.size() * BalanceSimulationEngine.STRATEGIES.size())
	_progress_label.text = "0 / %d" % int(_progress_bar.max_value)
	_status_label.text = "两套攻击规则使用相同种子和正式动态掉落规则。"
	_start_button.disabled = true
	_board_button.disabled = true
	_attack_button.disabled = true
	_cancel_button.disabled = false
	_copy_button.disabled = true
	if not _runner.start_attack_rules(ATTACK_RUN_COUNT):
		_start_button.disabled = false
		_board_button.disabled = false
		_attack_button.disabled = false
		_cancel_button.disabled = true


func _on_progress_changed(completed: int, total: int) -> void:
	_progress_bar.max_value = float(maxi(1, total))
	_progress_bar.value = float(completed)
	_progress_label.text = "%d / %d" % [completed, total]
	var percent := float(completed) / float(maxi(1, total)) * 100.0
	_status_label.text = "正在模拟：%.1f%%（界面可继续响应）" % percent


func _on_simulation_completed(result: Dictionary) -> void:
	_result = result
	_start_button.disabled = false
	_board_button.disabled = false
	_attack_button.disabled = false
	_cancel_button.disabled = true
	_copy_button.disabled = false
	_progress_bar.value = _progress_bar.max_value
	_progress_label.text = "%d / %d" % [int(result.get("completed", 0)), int(result.get("total", 0))]
	_status_label.text = "模拟完成。CSV 已保存到：%s" % str(result.get("report_directory", ""))
	_refresh_result_text()
	if _pending_close:
		_finish_close()


func _on_simulation_cancelled() -> void:
	_start_button.disabled = false
	_board_button.disabled = false
	_attack_button.disabled = false
	_cancel_button.disabled = true
	_status_label.text = "模拟已取消，未生成不完整 CSV。"
	_result_text.text = "本次模拟已取消。可以重新开始。"
	if _pending_close:
		_finish_close()


func _on_simulation_failed(message: String) -> void:
	_start_button.disabled = false
	_board_button.disabled = false
	_attack_button.disabled = false
	_cancel_button.disabled = true
	_status_label.text = "模拟失败。"
	_result_text.text = "[color=#ff8b8b]错误：%s[/color]" % message
	if _pending_close:
		_finish_close()


func _on_cancel_pressed() -> void:
	if _runner and _runner.is_running():
		_runner.cancel()
		_cancel_button.disabled = true
		_status_label.text = "正在安全取消，请稍候……"


func _on_close_pressed() -> void:
	if _runner and _runner.is_running():
		_pending_close = true
		_runner.cancel()
		_start_button.disabled = true
		_board_button.disabled = true
		_attack_button.disabled = true
		_cancel_button.disabled = true
		_close_button.disabled = true
		_status_label.text = "正在停止后台模拟并关闭……"
		return
	_finish_close()


func _finish_close() -> void:
	closed.emit()
	queue_free()


func _copy_report_path() -> void:
	var path := str(_result.get("report_directory", ""))
	if path.is_empty():
		return
	DisplayServer.clipboard_set(path)
	_status_label.text = "CSV 目录已复制：%s" % path


func _refresh_result_text() -> void:
	if _result.is_empty():
		return
	if str(_result.get("mode", "combat")) == "board":
		match _tab_selector.selected:
			0, 1:
				_result_text.text = _board_progression_text()
			2:
				_result_text.text = "[font_size=28][b]战斗[/b][/font_size]\n\n本轮是纯棋盘模拟，没有计算攻击、怪物或城堡数据。"
			_:
				_result_text.text = _diagnostic_text()
		return
	if str(_result.get("mode", "combat")) == "attack_rules":
		match _tab_selector.selected:
			0, 2:
				_result_text.text = _attack_rule_text()
			1:
				_result_text.text = "[font_size=28][b]棋盘[/b][/font_size]\n\n两套攻击规则使用同一正式动态掉落和相同随机种子，棋盘差异已受控。"
			_:
				_result_text.text = _diagnostic_text()
		return
	match _tab_selector.selected:
		0:
			_result_text.text = _overview_text()
		1:
			_result_text.text = _board_text()
		2:
			_result_text.text = _combat_text()
		_:
			_result_text.text = _diagnostic_text()


func _board_progression_text() -> String:
	var text := "[font_size=28][b]五级滑窗棋盘推进[/b][/font_size]\n\n"
	for strategy in BalanceSimulationEngine.STRATEGIES:
		for scenario in BalanceSimulationEngine.BOARD_SCENARIOS:
			var row := _summary(scenario, strategy)
			if row.is_empty():
				continue
			text += "[b]%s / %s[/b]\n" % [row["strategy_name"], row["scenario_name"]]
			text += "  平均合成 %.1f 次；停盘 %s；最高等级 P50/P90：%.0f / %.0f\n" % [row["avg_merges"], _percent(row["stall_rate"]), row["highest_p50"], row["highest_p90"]]
			text += "  到达 10/A/B/E/J/P/Z：%s / %s / %s / %s / %s / %s / %s\n\n" % [
				_percent(row["reach_10_rate"]), _percent(row["reach_11_rate"]), _percent(row["reach_12_rate"]),
				_percent(row["reach_15_rate"]), _percent(row["reach_20_rate"]), _percent(row["reach_26_rate"]), _percent(row["reach_36_rate"]),
			]
	return text


func _attack_rule_text() -> String:
	var text := "[font_size=28][b]连续集火攻击配对结果[/b][/font_size]\n\n"
	for strategy in BalanceSimulationEngine.STRATEGIES:
		var legacy := _summary("attack_legacy", strategy)
		var combo := _summary("attack_combo_focus", strategy)
		if legacy.is_empty() or combo.is_empty():
			continue
		text += "[font_size=24][b]%s[/b][/font_size]\n" % str(combo["strategy_name"])
		text += "  通关率：%s；失败波次P50：%s\n" % [_comparison(legacy["win_rate"], combo["win_rate"], true), _comparison(legacy["wave_p50"], combo["wave_p50"])]
		text += "  理论伤害：%s\n" % _comparison(legacy["avg_theoretical_damage"], combo["avg_theoretical_damage"])
		text += "  有效伤害：%s；过量伤害：%s\n" % [_comparison(legacy["avg_effective_damage"], combo["avg_effective_damage"]), _comparison(legacy["avg_overkill_damage"], combo["avg_overkill_damage"])]
		text += "  平均击杀：%s；平均漏怪：%s\n" % [_comparison(legacy["avg_killed"], combo["avg_killed"]), _comparison(legacy["avg_leaked"], combo["avg_leaked"])]
		text += "  最前怪击杀时间：%s秒\n" % _comparison(legacy["avg_front_kill_time"], combo["avg_front_kill_time"])
		text += "  2/3/4/5/6+合并有效伤害：%.0f / %.0f / %.0f / %.0f / %.0f\n\n" % [combo["avg_merge_damage_2"], combo["avg_merge_damage_3"], combo["avg_merge_damage_4"], combo["avg_merge_damage_5"], combo["avg_merge_damage_6_plus"]]
	return text + "[color=#93bfff]逐局配对数据与聚合差异已写入 attack_*.csv。[/color]"


func _overview_text() -> String:
	var text := "[font_size=28][b]核心结果[/b][/font_size]\n\n"
	for strategy in BalanceSimulationEngine.STRATEGIES:
		var current := _summary("current", strategy)
		if current.is_empty():
			continue
		text += "[font_size=24][b]%s[/b][/font_size]\n" % str(current["strategy_name"])
		for scenario in BalanceSimulationEngine.SCENARIOS:
			if scenario == "current":
				continue
			var candidate := _summary(scenario, strategy)
			if candidate.is_empty():
				continue
			text += "[b]%s[/b]\n" % str(candidate["scenario_name"])
			text += "  失败波次P50：%s；最高数字P50：%s\n" % [_comparison(current["wave_p50"], candidate["wave_p50"]), _comparison(current["highest_p50"], candidate["highest_p50"])]
			text += "  停滞率：%s\n" % _comparison(current["stall_rate"], candidate["stall_rate"], true)
			text += "  总伤害：%s；平均漏怪：%s\n\n" % [_comparison(current["avg_total_damage"], candidate["avg_total_damage"]), _comparison(current["avg_leaked"], candidate["avg_leaked"])]
	text += "[color=#93bfff]完整逐局数据与聚合数据已经写入 CSV。[/color]"
	return text


func _board_text() -> String:
	var text := "[font_size=28][b]棋盘与合成[/b][/font_size]\n\n"
	for strategy in BalanceSimulationEngine.STRATEGIES:
		for scenario in BalanceSimulationEngine.SCENARIOS:
			var row := _summary(scenario, strategy)
			if row.is_empty():
				continue
			text += "[b]%s / %s[/b]\n" % [row["strategy_name"], row["scenario_name"]]
			text += "  数字1占比：%s；达到5后数字1占比：%s\n" % [_percent(row["generated_one_rate"]), _percent(row["post5_one_rate"])]
			text += "  新块落点同数邻接率：%s\n" % _percent(row["adjacent_match_rate"])
			text += "  每次补块后可合成组：%.2f" % row["avg_refill_group_count"]
			if scenario == "candidate_v2_dynamic":
				text += "；动态命中概率：%s；选中评分：%.2f" % [_percent(row["avg_dynamic_selected_probability"]), row["avg_dynamic_selected_score"]]
			text += "\n"
			text += "  最高数字 P50/P90：%.1f / %.1f；平均合成组：%.2f\n" % [row["highest_p50"], row["highest_p90"], row["avg_group_size"]]
			text += "  到达5/6/7/8比例：%s / %s / %s / %s\n" % [_percent(row["reach_5_rate"]), _percent(row["reach_6_rate"]), _percent(row["reach_7_rate"]), _percent(row["reach_8_rate"])]
			text += "  到达5/6/7/8的合成次数P50：%s / %s / %s / %s\n\n" % [_metric(row["merges_to_5_p50"]), _metric(row["merges_to_6_p50"]), _metric(row["merges_to_7_p50"]), _metric(row["merges_to_8_p50"])]
	return text


func _combat_text() -> String:
	var text := "[font_size=28][b]战斗压力[/b][/font_size]\n\n"
	for strategy in BalanceSimulationEngine.STRATEGIES:
		for scenario in BalanceSimulationEngine.SCENARIOS:
			var row := _summary(scenario, strategy)
			if row.is_empty():
				continue
			text += "[b]%s / %s[/b]\n" % [row["strategy_name"], row["scenario_name"]]
			text += "  平均伤害：总 %.0f｜棋盘 %.0f｜水晶 %.0f｜持续 %.0f\n" % [row["avg_total_damage"], row["avg_board_damage"], row["avg_crystal_damage"], row["avg_status_damage"]]
			text += "  平均生成/击杀/漏怪：%.1f / %.1f / %.1f；城堡剩余 %.1f\n" % [row["avg_spawned"], row["avg_killed"], row["avg_leaked"], row["avg_castle"]]
			text += "  死亡路径进度：均值 %s｜P50 %s｜P90 %s\n\n" % [_percent(row["death_progress_mean"]), _percent(row["death_progress_p50"]), _percent(row["death_progress_p90"])]
	return text


func _diagnostic_text() -> String:
	var settings := _result.get("settings", {}) as Dictionary
	if str(_result.get("mode", "combat")) == "board":
		return "[font_size=28][b]纯棋盘诊断[/b][/font_size]\n\n" + \
			"基础种子：%d\n每组局数：%d\n单局合成上限：%d\n总完成局数：%d\n\n" % [BalanceSimulationEngine.BASE_SEED, int(settings.get("run_count", 0)), int(settings.get("merge_limit", 0)), int(_result.get("completed", 0))] + \
			"不计攻击、怪物、卡牌、即时技能和复活。\n\n汇总CSV：%s\n逐局CSV：%s" % [str(_result.get("summary_path", "")), str(_result.get("runs_path", ""))]
	return "[font_size=28][b]诊断信息[/b][/font_size]\n\n" + \
		"基础种子：%d\n每种策略局数：%d\n玩家操作间隔：%.2f秒\n总完成局数：%d\n\n" % [BalanceSimulationEngine.BASE_SEED, int(settings.get("run_count", 0)), float(settings.get("action_interval", 1.0)), int(_result.get("completed", 0))] + \
		"计入：棋盘合成攻击、全部基础属性、水晶塔、20波怪物和城堡耐久。\n" + \
		"不计入：卡牌、换位、水晶雨、清底道具和复活。\n\n" + \
		"汇总CSV：%s\n逐局CSV：%s" % [str(_result.get("summary_path", "")), str(_result.get("runs_path", ""))]


func _summary(scenario: String, strategy: String) -> Dictionary:
	for row_value in _result.get("summary", []) as Array:
		var row := row_value as Dictionary
		if row.get("scenario", "") == scenario and row.get("strategy", "") == strategy:
			return row
	return {}


func _percent(value: Variant) -> String:
	return "%.1f%%" % (float(value) * 100.0)


func _signed_percent(value: float) -> String:
	return "%+.1f个百分点" % (value * 100.0)


func _comparison(current_value: Variant, candidate_value: Variant, percentage_points := false) -> String:
	var current_float := float(current_value)
	var candidate_float := float(candidate_value)
	var absolute_change := candidate_float - current_float
	var relative := "相对 N/A" if is_zero_approx(current_float) else "相对 %+.1f%%" % (absolute_change / absf(current_float) * 100.0)
	if percentage_points:
		return "%s → %s（%s，%s）" % [_percent(current_float), _percent(candidate_float), _signed_percent(absolute_change), relative]
	return "%.1f → %.1f（%+.1f，%s）" % [current_float, candidate_float, absolute_change, relative]


func _metric(value: Variant) -> String:
	return "未达到" if float(value) < 0.0 else "%.0f" % float(value)


func _label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.07, 0.95))
	label.add_theme_constant_override("outline_size", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text_value: String, color: Color) -> Button:
	var button := Button.new()
	button.text = text_value
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 21)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color(0.03, 0.04, 0.08, 1.0))
	button.add_theme_constant_override("outline_size", 2)
	button.add_theme_stylebox_override("normal", _button_style(color))
	button.add_theme_stylebox_override("hover", _button_style(color.lightened(0.12)))
	button.add_theme_stylebox_override("pressed", _button_style(color.darkened(0.13)))
	button.add_theme_stylebox_override("disabled", _button_style(Color(0.25, 0.28, 0.36)))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.075, 0.14, 0.985)
	style.border_color = Color(0.34, 0.57, 0.92, 0.9)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 12
	return style


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.25)
	style.set_border_width_all(2)
	style.set_corner_radius_all(11)
	return style
