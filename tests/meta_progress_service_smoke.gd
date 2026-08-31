extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var service := MetaProgressService.new()
	service.setup(1000, 1000, {})
	_check(service.sync_day("2026-08-13"), "first day sync should initialize daily state")
	_check(int(service.task_progress["login"]) == 1, "day sync should record today's login")
	_check(service.get_ordered_task_ids() == ["settle_once", "merge_20", "kill_30", "login"], "task order should be explicit and stable")
	_check(str(service.get_first_unclaimed_task_state().get("id", "")) == "settle_once", "fresh queue should begin with the challenge task even when login is already complete")
	_check(not service.sync_day("2026-08-12"), "clock rollback must not reset or grant daily progress")
	_check(service.is_signin_available() and service.get_signin_preview_day() == 1 and service.get_signin_claimed_days() == 0, "fresh profile should preview an unclaimed day one")
	var login_reward := service.claim_task("login")
	_check(int(login_reward.get("crystals", 0)) == 20, "login task should grant twenty crystals")
	_check(service.claim_task("login").is_empty(), "same task must not be claimed twice")
	for _index in range(20):
		service.record_merge()
	_check(not service.claim_task("merge_20").is_empty(), "a later completed task should be claimable before the queue reaches it")
	_check(str(service.get_first_unclaimed_task_state().get("id", "")) == "settle_once", "claiming a later task must not advance the unclaimed queue head")
	for _index in range(30):
		service.record_kill()
	service.record_run_settled(99)
	_check(service.piggy_coins == 19, "piggy bank should store floor twenty percent of base coins")
	_check(not service.claim_task("settle_once").is_empty(), "the queue head should claim after its target is complete")
	_check(str(service.get_first_unclaimed_task_state().get("id", "")) == "kill_30", "queue scan should skip the already claimed merge task")
	for task_id in ["kill_30"]:
		_check(not service.claim_task(task_id).is_empty(), "completed task should claim: %s" % task_id)
	_check(service.get_first_unclaimed_task_state().is_empty(), "queue scan should also skip the login task claimed ahead of the queue")
	_check(service.get_activity() == 100, "four claimed tasks should total one hundred activity")
	_check(int(service.claim_activity_chest().get("coins", 0)) == 100, "activity chest should grant one hundred coins once")
	var signin := service.claim_signin()
	_check(int(signin.get("crystals", 0)) == 20 and service.signin_streak == 1, "first signin should grant day one")
	_check(not service.is_signin_available() and service.get_signin_preview_day() == 1 and service.get_signin_claimed_days() == 1, "claimed day one should remain selected and checked")
	_check(service.claim_signin().is_empty(), "same day signin must not repeat")
	service.sync_day("2026-08-14")
	_check(str(service.get_first_unclaimed_task_state().get("id", "")) == "settle_once" and not bool(service.task_claimed["login"]), "daily reset should clear every claimed state and restore the first queue item")
	_check(service.is_signin_available() and service.get_signin_preview_day() == 2 and service.get_signin_claimed_days() == 1, "consecutive day should preview the next card and retain prior checks")
	_check(int(service.claim_signin().get("coins", 0)) == 30 and service.signin_streak == 2, "consecutive signin should advance")
	service.sync_day("2026-08-16")
	_check(service.is_signin_available() and service.get_signin_preview_day() == 1 and service.get_signin_claimed_days() == 0, "missed day should preview a clean day-one cycle")
	_check(int(service.claim_signin().get("crystals", 0)) == 20 and service.signin_streak == 1, "missed day should reset signin")

	service.transaction_adapter.inject_next_result(false)
	_check(str(service.try_purchase("benefits_bundle").get("reason", "")) == "payment_failed" and not service.double_coin_owned and not service.remove_ads_owned, "failed bundle payment must not grant either benefit")
	service.transaction_adapter.inject_next_result(true)
	_check(bool(service.try_purchase("benefits_bundle").get("success", false)) and service.double_coin_owned and service.remove_ads_owned, "the ¥6 bundle should grant both permanent benefits")
	_check(not bool(service.try_purchase("benefits_bundle").get("success", true)), "owned benefits bundle must not repeat")
	_check(service.should_auto_pass_ad(false) and not service.should_auto_pass_ad(true), "bundle ad removal should auto-pass only non-reward ads")

	var partial_config := ConfigFile.new()
	partial_config.set_value("commerce", "double_coin", true)
	partial_config.set_value("commerce", "remove_ads", false)
	var partial := MetaProgressService.new()
	partial.setup(0, 0, {})
	partial.load_from_config(partial_config)
	_check(partial.double_coin_owned and not partial.remove_ads_owned and not partial.is_benefits_bundle_owned(), "a legacy one-benefit profile should retain its entitlement without owning the whole bundle")
	_check(bool(partial.try_purchase("benefits_bundle").get("success", false)) and partial.is_benefits_bundle_owned(), "a partial legacy profile should be able to buy the bundle and fill the missing benefit")

	service.card_levels["fire_conduit"] = 4
	service.fragments["fire_conduit"] = 5
	_check(bool(service.try_purchase("frag_fire_conduit").get("success", false)), "fragment product should purchase with crystals")
	_check(int(service.card_levels["fire_conduit"]) == 5 and int(service.fragments["fire_conduit"]) == 0, "ten fragments should add one permanent level")
	var coins_before := service.coins
	service.fragments["fire_conduit"] = 9
	service._grant_fragments("fire_conduit", 1)
	_check(service.coins == coins_before + 200 and int(service.fragments["fire_conduit"]) == 0, "max-level fragments should convert at twenty coins each")

	var config := ConfigFile.new()
	service.save_to_config(config)
	var restored := MetaProgressService.new()
	restored.setup(service.coins, service.crystals, service.card_levels)
	restored.load_from_config(config)
	_check(restored.double_coin_owned and restored.remove_ads_owned, "permanent purchases should restore")
	_check(restored.signin_last_date == service.signin_last_date, "daily state should restore")
	_check(restored.task_progress == service.task_progress and restored.task_claimed == service.task_claimed, "task progress and claim state should restore without migration")
	_check(str(restored.get_first_unclaimed_task_state().get("id", "")) == str(service.get_first_unclaimed_task_state().get("id", "")), "restored queue head should match the saved queue head")

	if failures.is_empty():
		print("META_PROGRESS_SERVICE_SMOKE_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
