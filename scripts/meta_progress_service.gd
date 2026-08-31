extends RefCounted
class_name MetaProgressService

signal changed
signal reward_granted(reward: Dictionary)
signal purchase_finished(product_id: String, success: bool, result: Dictionary)

const TASK_ORDER := ["settle_once", "merge_20", "kill_30", "login"]
const TASKS := {
	"settle_once": {
		"title": "完成 1 次挑战",
		"target": 1,
		"reward": {"crystals": 10},
		"activity": 20,
		"icon_key": "challenge",
	},
	"merge_20": {
		"title": "合成 20 次",
		"target": 20,
		"reward": {"coins": 30},
		"activity": 20,
		"icon_key": "merge",
	},
	"kill_30": {
		"title": "击败 30 个怪物",
		"target": 30,
		"reward": {"coins": 50},
		"activity": 30,
		"icon_key": "monster",
	},
	"login": {
		"title": "今日登录",
		"target": 1,
		"reward": {"crystals": 20},
		"activity": 30,
		"icon_key": "login",
	},
}
const SIGNIN_REWARDS := [
	{"crystals": 20}, {"coins": 30}, {"crystals": 20}, {"coins": 50},
	{"crystals": 20}, {"coins": 30}, {"coins": 100},
]
const IMPRINT_IDS := ["ascension_hammer", "unity_dial", "fate_shuffler", "twin_mold", "castle_cannon", "dragon_catapult"]
const PRODUCTS := {
	"benefits_bundle": {"kind": "real", "price": "¥6", "permanent": true},
	# Legacy ids remain readable for old callers, but purchases are normalized to
	# the single formal benefits bundle in try_purchase().
	"double_coin": {"kind": "real", "price": "¥18", "permanent": true},
	"remove_ads": {"kind": "real", "price": "¥12", "permanent": true},
	"first_purchase": {"kind": "real", "price": "¥6", "once": true},
	"piggy_bank": {"kind": "real", "price": "¥12"},
	"coins_10000": {"kind": "crystals", "cost": 200, "reward": {"coins": 10000}, "daily_limit": 3},
	"crystals_500": {"kind": "real", "price": "¥12", "reward": {"crystals": 500}, "daily_limit": 5},
	"frag_fire_conduit": {"kind": "crystals", "cost": 120, "fragment": "fire_conduit", "amount": 5, "daily_limit": 5},
	"frag_poison_tank": {"kind": "crystals", "cost": 120, "fragment": "poison_tank", "amount": 5, "daily_limit": 5},
	"frag_star_boiler": {"kind": "crystals", "cost": 120, "fragment": "star_boiler", "amount": 5, "daily_limit": 5},
	"frag_rapid_clockwork": {"kind": "crystals", "cost": 180, "fragment": "rapid_clockwork", "amount": 5, "daily_limit": 5},
	"frag_twin_lens": {"kind": "crystals", "cost": 250, "fragment": "twin_lens", "amount": 5, "daily_limit": 5},
	"frag_piercing_cannon": {"kind": "crystals", "cost": 250, "fragment": "piercing_cannon", "amount": 5, "daily_limit": 5},
}

var music_enabled := true
var sound_enabled := true
var vibration_enabled := false
var coins := 0
var crystals := 0
var card_levels: Dictionary = {}
var fragments: Dictionary = {}
var last_sync_date := ""
var task_progress := {}
var task_claimed := {}
var activity_claimed := false
var signin_last_date := ""
var signin_streak := 0
var double_coin_owned := false
var remove_ads_owned := false
var first_purchase_owned := false
var piggy_coins := 0
var daily_limits := {}
var transaction_adapter := LocalTransactionAdapter.new()


func setup(initial_coins: int, initial_crystals: int, levels: Dictionary) -> void:
	coins = maxi(0, initial_coins)
	crystals = maxi(0, initial_crystals)
	card_levels = levels.duplicate(true)
	_ensure_defaults()


func _ensure_defaults() -> void:
	for task_id in TASK_ORDER:
		task_progress[task_id] = maxi(0, int(task_progress.get(task_id, 0)))
		task_claimed[task_id] = bool(task_claimed.get(task_id, false))
	for card_id in CardCatalog.ALL_CARD_IDS:
		fragments[card_id] = maxi(0, int(fragments.get(card_id, 0)))
		card_levels[card_id] = clampi(int(card_levels.get(card_id, 0)), 0, GameConfig.MAX_CARD_LEVEL)


func load_from_config(config: ConfigFile, legacy_muted: bool = false) -> void:
	music_enabled = bool(config.get_value("settings", "music", not legacy_muted))
	sound_enabled = bool(config.get_value("settings", "sound", not legacy_muted))
	vibration_enabled = bool(config.get_value("settings", "vibration", false))
	last_sync_date = str(config.get_value("daily", "last_sync_date", ""))
	task_progress = (config.get_value("daily", "task_progress", {}) as Dictionary).duplicate(true)
	task_claimed = (config.get_value("daily", "task_claimed", {}) as Dictionary).duplicate(true)
	activity_claimed = bool(config.get_value("daily", "activity_claimed", false))
	signin_last_date = str(config.get_value("daily", "signin_last_date", ""))
	signin_streak = clampi(int(config.get_value("daily", "signin_streak", 0)), 0, 7)
	double_coin_owned = bool(config.get_value("commerce", "double_coin", false))
	remove_ads_owned = bool(config.get_value("commerce", "remove_ads", false))
	first_purchase_owned = bool(config.get_value("commerce", "first_purchase", false))
	piggy_coins = clampi(int(config.get_value("commerce", "piggy_coins", 0)), 0, 1000)
	daily_limits = (config.get_value("commerce", "daily_limits", {}) as Dictionary).duplicate(true)
	fragments = (config.get_value("cards", "fragments", {}) as Dictionary).duplicate(true)
	_ensure_defaults()


func save_to_config(config: ConfigFile) -> void:
	config.set_value("settings", "music", music_enabled)
	config.set_value("settings", "sound", sound_enabled)
	config.set_value("settings", "vibration", vibration_enabled)
	config.set_value("daily", "last_sync_date", last_sync_date)
	config.set_value("daily", "task_progress", task_progress.duplicate(true))
	config.set_value("daily", "task_claimed", task_claimed.duplicate(true))
	config.set_value("daily", "activity_claimed", activity_claimed)
	config.set_value("daily", "signin_last_date", signin_last_date)
	config.set_value("daily", "signin_streak", signin_streak)
	config.set_value("commerce", "double_coin", double_coin_owned)
	config.set_value("commerce", "remove_ads", remove_ads_owned)
	config.set_value("commerce", "first_purchase", first_purchase_owned)
	config.set_value("commerce", "piggy_coins", piggy_coins)
	config.set_value("commerce", "daily_limits", daily_limits.duplicate(true))
	config.set_value("cards", "fragments", fragments.duplicate(true))


func sync_day(date: String) -> bool:
	if not _is_valid_date(date):
		return false
	if last_sync_date.is_empty():
		_reset_daily(date)
		_record("login", 1)
		return true
	var comparison := _compare_dates(date, last_sync_date)
	if comparison < 0:
		return false
	if comparison > 0:
		_reset_daily(date)
		_record("login", 1)
		return true
	return false


func _reset_daily(date: String) -> void:
	last_sync_date = date
	task_progress.clear()
	task_claimed.clear()
	activity_claimed = false
	daily_limits.clear()
	_ensure_defaults()
	changed.emit()


func record_merge() -> void:
	_record("merge_20", 1)


func record_kill() -> void:
	_record("kill_30", 1)


func record_run_settled(base_coin_reward: int) -> void:
	_record("settle_once", 1)
	piggy_coins = mini(1000, piggy_coins + maxi(0, floori(float(base_coin_reward) * 0.2)))
	changed.emit()


func _record(task_id: String, amount: int) -> void:
	if not TASKS.has(task_id):
		return
	var target := int((TASKS[task_id] as Dictionary)["target"])
	task_progress[task_id] = mini(target, int(task_progress.get(task_id, 0)) + maxi(0, amount))
	changed.emit()


func claim_task(id: String) -> Dictionary:
	if not TASKS.has(id) or bool(task_claimed.get(id, false)):
		return {}
	var definition := TASKS[id] as Dictionary
	if int(task_progress.get(id, 0)) < int(definition["target"]):
		return {}
	task_claimed[id] = true
	var reward := (definition["reward"] as Dictionary).duplicate(true)
	_apply_reward(reward)
	return reward


func claim_activity_chest() -> Dictionary:
	if activity_claimed or get_activity() < 100:
		return {}
	activity_claimed = true
	var reward := {"coins": 100}
	_apply_reward(reward)
	return reward


func get_ordered_task_ids() -> Array[String]:
	var ordered_ids: Array[String] = []
	for task_id in TASK_ORDER:
		ordered_ids.append(str(task_id))
	return ordered_ids


func get_task_state(task_id: String) -> Dictionary:
	if not TASKS.has(task_id):
		return {}
	var definition := TASKS[task_id] as Dictionary
	var target := int(definition["target"])
	var progress := clampi(int(task_progress.get(task_id, 0)), 0, target)
	var claimed := bool(task_claimed.get(task_id, false))
	return {
		"id": task_id,
		"title": str(definition["title"]),
		"target": target,
		"progress": progress,
		"reward": (definition["reward"] as Dictionary).duplicate(true),
		"activity": int(definition["activity"]),
		"icon_key": str(definition["icon_key"]),
		"claimed": claimed,
		"claimable": progress >= target and not claimed,
	}


func get_first_unclaimed_task_state() -> Dictionary:
	for task_id in TASK_ORDER:
		if not bool(task_claimed.get(task_id, false)):
			return get_task_state(str(task_id))
	return {}


func has_claimable_task() -> bool:
	for task_id in TASK_ORDER:
		if bool(get_task_state(str(task_id)).get("claimable", false)):
			return true
	return false


func get_activity() -> int:
	var total := 0
	for task_id in TASK_ORDER:
		if bool(task_claimed.get(task_id, false)):
			total += int((TASKS[task_id] as Dictionary)["activity"])
	return total


func is_signin_available() -> bool:
	return not last_sync_date.is_empty() and signin_last_date != last_sync_date


func get_signin_preview_day() -> int:
	if not last_sync_date.is_empty() and signin_last_date == last_sync_date:
		return clampi(signin_streak, 1, 7)
	if signin_last_date.is_empty() or last_sync_date.is_empty() or _days_between(signin_last_date, last_sync_date) != 1:
		return 1
	return (signin_streak % 7) + 1


func get_signin_claimed_days() -> int:
	if last_sync_date.is_empty():
		return 0
	if signin_last_date == last_sync_date:
		return clampi(signin_streak, 0, 7)
	return 0 if get_signin_preview_day() == 1 else clampi(signin_streak, 0, 7)


func claim_signin() -> Dictionary:
	if last_sync_date.is_empty() or signin_last_date == last_sync_date:
		return {}
	if signin_last_date.is_empty() or _days_between(signin_last_date, last_sync_date) != 1:
		signin_streak = 1
	else:
		signin_streak = signin_streak % 7 + 1
	signin_last_date = last_sync_date
	var reward := (SIGNIN_REWARDS[signin_streak - 1] as Dictionary).duplicate(true)
	_apply_reward(reward)
	return reward


func try_purchase(product_id: String) -> Dictionary:
	if product_id == "double_coin" or product_id == "remove_ads":
		product_id = "benefits_bundle"
	var product := _product(product_id)
	if product.is_empty():
		return _purchase_result(product_id, false, "missing")
	if bool(product.get("permanent", false)) and _is_owned(product_id):
		return _purchase_result(product_id, false, "owned")
	if bool(product.get("once", false)) and first_purchase_owned:
		return _purchase_result(product_id, false, "owned")
	var limit := int(product.get("daily_limit", 0))
	if limit > 0 and int(daily_limits.get(product_id, 0)) >= limit:
		return _purchase_result(product_id, false, "limit")
	if product_id == "piggy_bank" and piggy_coins <= 0:
		return _purchase_result(product_id, false, "empty")
	var kind := str(product.get("kind", ""))
	if kind == "crystals":
		var cost := int(product.get("cost", 0))
		if crystals < cost:
			return _purchase_result(product_id, false, "insufficient")
		crystals -= cost
	elif kind == "coins":
		var cost := int(product.get("cost", 0))
		if coins < cost:
			return _purchase_result(product_id, false, "insufficient")
		coins -= cost
	elif kind == "real" and not transaction_adapter.purchase(product_id, str(product.get("price", ""))):
		return _purchase_result(product_id, false, "payment_failed")
	if limit > 0:
		daily_limits[product_id] = int(daily_limits.get(product_id, 0)) + 1
	var reward := (product.get("reward", {}) as Dictionary).duplicate(true)
	if product.has("fragment"):
		_grant_fragments(str(product["fragment"]), int(product.get("amount", 0)))
	match product_id:
		"benefits_bundle":
			double_coin_owned = true
			remove_ads_owned = true
		"first_purchase":
			first_purchase_owned = true
			reward = {"crystals": 980, "coins": 30000}
			_grant_fragments("ascension_hammer", 10)
			_grant_fragments("fire_conduit", 10)
		"piggy_bank":
			reward = {"coins": piggy_coins}
			piggy_coins = 0
	_apply_reward(reward)
	return _purchase_result(product_id, true, "ok", reward)


func _product(product_id: String) -> Dictionary:
	if PRODUCTS.has(product_id):
		return (PRODUCTS[product_id] as Dictionary).duplicate(true)
	if product_id.begins_with("frag_imprint_"):
		var card_id := product_id.trim_prefix("frag_imprint_")
		if IMPRINT_IDS.has(card_id):
			return {"kind": "crystals", "cost": 250, "fragment": card_id, "amount": 5, "daily_limit": 3}
	return {}


func _grant_fragments(card_id: String, amount: int) -> void:
	if not CardCatalog.ALL_CARD_IDS.has(card_id):
		return
	var pending := maxi(0, int(fragments.get(card_id, 0)) + amount)
	var level := clampi(int(card_levels.get(card_id, 0)), 0, GameConfig.MAX_CARD_LEVEL)
	while pending >= 10 and level < GameConfig.MAX_CARD_LEVEL:
		pending -= 10
		level += 1
	card_levels[card_id] = level
	if level >= GameConfig.MAX_CARD_LEVEL and pending > 0:
		coins += pending * 20
		pending = 0
	fragments[card_id] = pending


func _apply_reward(reward: Dictionary) -> void:
	coins += maxi(0, int(reward.get("coins", 0)))
	crystals += maxi(0, int(reward.get("crystals", 0)))
	changed.emit()
	if not reward.is_empty():
		reward_granted.emit(reward.duplicate(true))


func restore_purchases() -> Dictionary:
	changed.emit()
	return {"double_coin": double_coin_owned, "remove_ads": remove_ads_owned, "benefits_bundle": is_benefits_bundle_owned()}


func reset_profile() -> void:
	music_enabled = true
	sound_enabled = true
	vibration_enabled = false
	coins = 0
	crystals = 0
	card_levels.clear()
	fragments.clear()
	last_sync_date = ""
	task_progress.clear()
	task_claimed.clear()
	activity_claimed = false
	signin_last_date = ""
	signin_streak = 0
	double_coin_owned = false
	remove_ads_owned = false
	first_purchase_owned = false
	piggy_coins = 0
	daily_limits.clear()
	_ensure_defaults()
	changed.emit()


func should_auto_pass_ad(rewarded: bool) -> bool:
	return remove_ads_owned and not rewarded


func is_benefits_bundle_owned() -> bool:
	return double_coin_owned and remove_ads_owned


func _is_owned(product_id: String) -> bool:
	if product_id == "benefits_bundle":
		return is_benefits_bundle_owned()
	return (product_id == "double_coin" and double_coin_owned) or (product_id == "remove_ads" and remove_ads_owned)


func _purchase_result(product_id: String, success: bool, reason: String, reward: Dictionary = {}) -> Dictionary:
	var result := {"success": success, "reason": reason, "reward": reward.duplicate(true)}
	purchase_finished.emit(product_id, success, result.duplicate(true))
	changed.emit()
	return result


func _is_valid_date(date: String) -> bool:
	var parts := date.split("-")
	return parts.size() == 3 and parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()


func _date_dict(date: String) -> Dictionary:
	var parts := date.split("-")
	return {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 12, "minute": 0, "second": 0}


func _compare_dates(a: String, b: String) -> int:
	var delta := Time.get_unix_time_from_datetime_dict(_date_dict(a)) - Time.get_unix_time_from_datetime_dict(_date_dict(b))
	return signi(int(delta))


func _days_between(a: String, b: String) -> int:
	return roundi((Time.get_unix_time_from_datetime_dict(_date_dict(b)) - Time.get_unix_time_from_datetime_dict(_date_dict(a))) / 86400.0)
