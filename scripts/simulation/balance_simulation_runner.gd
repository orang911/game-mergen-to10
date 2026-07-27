extends Node
class_name BalanceSimulationRunner

signal progress_changed(completed: int, total: int)
signal simulation_completed(result: Dictionary)
signal simulation_cancelled
signal simulation_failed(message: String)

const RUN_HEADERS := [
	"scenario", "strategy", "seed", "initial_board", "spawn_order_hash", "won", "waves_cleared", "failure_wave", "duration", "castle_remaining",
	"highest_level", "merge_count", "merges_to_5", "merges_to_6", "merges_to_7", "merges_to_8",
	"board_stalled", "avg_group_size", "generated_total", "generated_ones", "post5_generated_total",
	"post5_generated_ones", "adjacent_match_rate", "avg_dynamic_selected_probability", "avg_dynamic_selected_score",
	"avg_refill_group_count", "spawned", "killed", "leaked", "board_damage", "crystal_damage",
	"status_damage", "total_damage", "board_theoretical_damage", "board_effective_damage", "board_overkill_damage",
	"avg_front_kill_time", "merge_damage_2", "merge_damage_3", "merge_damage_4", "merge_damage_5", "merge_damage_6_plus",
	"death_progress_mean", "death_progress_p50", "death_progress_p90",
]
const SUMMARY_HEADERS := [
	"scenario", "scenario_name", "strategy", "strategy_name", "runs", "win_rate", "stall_rate",
	"wave_p50", "wave_p75", "wave_p90", "highest_p50", "highest_p90", "reach_5_rate", "reach_6_rate",
	"reach_7_rate", "reach_8_rate", "merges_to_5_p50",
	"merges_to_6_p50", "merges_to_7_p50", "merges_to_8_p50", "generated_one_rate",
	"post5_one_rate", "adjacent_match_rate", "avg_dynamic_selected_probability", "avg_dynamic_selected_score",
	"avg_refill_group_count", "avg_group_size", "avg_board_damage", "avg_crystal_damage", "avg_status_damage",
	"avg_total_damage", "avg_theoretical_damage", "avg_effective_damage", "avg_overkill_damage", "avg_front_kill_time",
	"avg_merge_damage_2", "avg_merge_damage_3", "avg_merge_damage_4", "avg_merge_damage_5", "avg_merge_damage_6_plus",
	"avg_spawned", "avg_killed", "avg_leaked", "avg_castle",
	"death_progress_mean", "death_progress_p50", "death_progress_p90", "avg_duration",
	"win_rate_relative_change", "stall_rate_relative_change", "wave_p50_relative_change",
	"wave_p75_relative_change", "wave_p90_relative_change", "highest_p50_relative_change",
	"highest_p90_relative_change", "reach_5_rate_relative_change", "reach_6_rate_relative_change",
	"reach_7_rate_relative_change", "reach_8_rate_relative_change", "merges_to_5_p50_relative_change", "merges_to_6_p50_relative_change",
	"merges_to_7_p50_relative_change", "merges_to_8_p50_relative_change", "generated_one_rate_relative_change",
	"post5_one_rate_relative_change", "adjacent_match_rate_relative_change", "avg_dynamic_selected_probability_relative_change",
	"avg_dynamic_selected_score_relative_change", "avg_refill_group_count_relative_change", "avg_group_size_relative_change", "avg_board_damage_relative_change",
	"avg_crystal_damage_relative_change", "avg_status_damage_relative_change", "avg_total_damage_relative_change",
	"avg_theoretical_damage_relative_change", "avg_effective_damage_relative_change", "avg_overkill_damage_relative_change",
	"avg_front_kill_time_relative_change", "avg_merge_damage_2_relative_change", "avg_merge_damage_3_relative_change",
	"avg_merge_damage_4_relative_change", "avg_merge_damage_5_relative_change", "avg_merge_damage_6_plus_relative_change",
	"avg_spawned_relative_change", "avg_killed_relative_change", "avg_leaked_relative_change",
	"avg_castle_relative_change", "death_progress_mean_relative_change", "death_progress_p50_relative_change",
	"death_progress_p90_relative_change", "avg_duration_relative_change",
]
const BOARD_RUN_HEADERS := [
	"scenario", "strategy", "seed", "initial_board", "merge_limit_reached", "board_stalled", "merge_count",
	"highest_level", "merges_to_10", "merges_to_11", "merges_to_12", "merges_to_15", "merges_to_20", "merges_to_26", "merges_to_36",
	"avg_generated_level", "avg_group_size", "adjacent_match_rate", "avg_refill_group_count",
	"avg_dynamic_selected_probability", "avg_dynamic_selected_score",
]
const BOARD_SUMMARY_HEADERS := [
	"scenario", "scenario_name", "strategy", "strategy_name", "runs", "completion_rate", "stall_rate",
	"avg_merges", "highest_p50", "highest_p75", "highest_p90", "reach_10_rate", "reach_11_rate",
	"reach_12_rate", "reach_15_rate", "reach_20_rate", "reach_26_rate", "reach_36_rate", "merges_to_10_p50", "merges_to_11_p50",
	"merges_to_12_p50", "merges_to_15_p50", "merges_to_20_p50", "merges_to_26_p50", "merges_to_36_p50", "avg_generated_level",
	"avg_group_size", "avg_refill_group_count",
]

var _thread: Thread
var _mutex := Mutex.new()
var _running := false
var _cancel_requested := false
var _completed_runs := 0
var _total_runs := 0
var _last_reported_progress := -1
var _settings: Dictionary = {}
var _mode := "combat"


func start_standard(run_count: int = 1000) -> bool:
	return _start(BalanceSimulationEngine.build_default_settings(run_count), "combat")


func start_board_progression(run_count: int = 1000, merge_limit: int = 500) -> bool:
	var settings := BalanceSimulationEngine.build_default_settings(run_count)
	settings["merge_limit"] = maxi(1, merge_limit)
	return _start(settings, "board")


func start_attack_rules(run_count: int = 1000) -> bool:
	return _start(BalanceSimulationEngine.build_default_settings(run_count), "attack_rules")


func _start(settings: Dictionary, mode: String) -> bool:
	if _running:
		return false
	_settings = settings
	_mode = mode
	_completed_runs = 0
	var scenario_count := BalanceSimulationEngine.SCENARIOS.size()
	if _mode == "board":
		scenario_count = BalanceSimulationEngine.BOARD_SCENARIOS.size()
	elif _mode == "attack_rules":
		scenario_count = BalanceSimulationEngine.ATTACK_RULE_SCENARIOS.size()
	_total_runs = int(_settings["run_count"]) * scenario_count * BalanceSimulationEngine.STRATEGIES.size()
	_last_reported_progress = -1
	_cancel_requested = false
	_thread = Thread.new()
	var error := _thread.start(_run_worker.bind(_settings.duplicate(true), _mode))
	if error != OK:
		_thread = null
		simulation_failed.emit("无法启动模拟线程，错误码：%d" % error)
		return false
	_running = true
	set_process(true)
	return true


func cancel() -> void:
	_mutex.lock()
	_cancel_requested = true
	_mutex.unlock()


func is_running() -> bool:
	return _running


func get_progress_snapshot() -> Vector2i:
	_mutex.lock()
	var snapshot := Vector2i(_completed_runs, _total_runs)
	_mutex.unlock()
	return snapshot


func _run_worker(settings_snapshot: Dictionary, mode: String) -> Dictionary:
	var engine := BalanceSimulationEngine.new()
	if mode == "board":
		return engine.run_board_progression_suite(settings_snapshot, _worker_set_progress, _worker_is_cancelled)
	if mode == "attack_rules":
		return engine.run_attack_rule_suite(settings_snapshot, _worker_set_progress, _worker_is_cancelled)
	return engine.run_suite(settings_snapshot, _worker_set_progress, _worker_is_cancelled)


func _worker_set_progress(completed: int, total: int) -> void:
	_mutex.lock()
	_completed_runs = completed
	_total_runs = total
	_mutex.unlock()


func _worker_is_cancelled() -> bool:
	_mutex.lock()
	var requested := _cancel_requested
	_mutex.unlock()
	return requested


func _process(_delta: float) -> void:
	if not _running or _thread == null:
		return
	var progress := get_progress_snapshot()
	if progress.x != _last_reported_progress:
		_last_reported_progress = progress.x
		progress_changed.emit(progress.x, progress.y)
	if _thread.is_alive():
		return
	var result_value: Variant = _thread.wait_to_finish()
	_thread = null
	_running = false
	set_process(false)
	var result := result_value as Dictionary
	if result.is_empty():
		simulation_failed.emit("模拟线程没有返回结果。")
		return
	if bool(result.get("cancelled", false)):
		simulation_cancelled.emit()
		return
	var report_result := _write_reports(result)
	if not bool(report_result.get("ok", false)):
		simulation_failed.emit(str(report_result.get("error", "CSV 报告写入失败。")))
		return
	result["summary_path"] = report_result["summary_path"]
	result["runs_path"] = report_result["runs_path"]
	result["report_directory"] = report_result["report_directory"]
	simulation_completed.emit(result)


func _write_reports(result: Dictionary) -> Dictionary:
	var directory_user := "user://simulation_reports"
	var directory_absolute := ProjectSettings.globalize_path(directory_user)
	var dir_error := DirAccess.make_dir_recursive_absolute(directory_absolute)
	if dir_error != OK and dir_error != ERR_ALREADY_EXISTS:
		return {"ok": false, "error": "无法创建报告目录：%s" % directory_absolute}
	var timestamp := Time.get_datetime_string_from_system(false, true).replace("-", "").replace(":", "").replace("T", "_")
	var result_mode := str(result.get("mode", "combat"))
	var board_mode := result_mode == "board"
	var prefix := "board_" if board_mode else ("attack_" if result_mode == "attack_rules" else "")
	var summary_user := "%s/%ssummary_%s.csv" % [directory_user, prefix, timestamp]
	var runs_user := "%s/%sruns_%s.csv" % [directory_user, prefix, timestamp]
	var summary_headers := BOARD_SUMMARY_HEADERS if board_mode else SUMMARY_HEADERS
	var run_headers := BOARD_RUN_HEADERS if board_mode else RUN_HEADERS
	var summary_error := _write_csv(summary_user, summary_headers, result.get("summary", []) as Array)
	if summary_error != OK:
		return {"ok": false, "error": "汇总 CSV 写入失败：%d" % summary_error}
	var runs_error := _write_csv(runs_user, run_headers, result.get("rows", []) as Array)
	if runs_error != OK:
		return {"ok": false, "error": "逐局 CSV 写入失败：%d" % runs_error}
	return {
		"ok": true,
		"summary_path": ProjectSettings.globalize_path(summary_user),
		"runs_path": ProjectSettings.globalize_path(runs_user),
		"report_directory": directory_absolute,
	}


func _write_csv(path: String, headers: Array, rows: Array) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var header_line := PackedStringArray()
	for header in headers:
		header_line.append(str(header))
	file.store_csv_line(header_line)
	for row_value in rows:
		var row := row_value as Dictionary
		var line := PackedStringArray()
		for header in headers:
			line.append(_csv_value(row.get(str(header), "")))
		file.store_csv_line(line)
	file.close()
	return OK


func _csv_value(value: Variant) -> String:
	if value is float:
		return "%.6f" % float(value)
	if value is bool:
		return "true" if bool(value) else "false"
	return str(value)


func _exit_tree() -> void:
	if _thread != null and _thread.is_started():
		cancel()
		_thread.wait_to_finish()
		_thread = null
	_running = false
