extends RefCounted
class_name ElementFxRequest

enum FxType { LAUNCH, HIT, CHAIN, AREA, STATUS_APPLY, STATUS_TICK, STATUS_END }

var fx_type: int = FxType.HIT
var element: int = 0
var element_key := "poison"
var tier := 1
var origin_position := Vector2.ZERO
var target_position := Vector2.ZERO
var target_node: Node = null
var radius := 0.0
var duration := 0.0
var color := Color.WHITE
var damage_value := 0.0
var chain_index := 0

static func make_launch(event: MergeAttackEvent) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.LAUNCH
	req.element = event.element
	req.element_key = event.element_key
	req.tier = event.element_tier
	req.origin_position = event.origin
	return req

static func make_hit(event: MergeAttackEvent, target_pos: Vector2, dmg: float) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.HIT
	req.element = event.element
	req.element_key = event.element_key
	req.tier = event.element_tier
	req.origin_position = event.origin
	req.target_position = target_pos
	req.damage_value = dmg
	return req

static func make_chain(event: MergeAttackEvent, from_pos: Vector2, to_pos: Vector2, ci: int, dmg: float) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.CHAIN
	req.element = event.element
	req.element_key = event.element_key
	req.tier = event.element_tier
	req.origin_position = from_pos
	req.target_position = to_pos
	req.chain_index = ci
	req.damage_value = dmg
	return req

static func make_area(event: MergeAttackEvent, center: Vector2, splash_radius: float) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.AREA
	req.element = event.element
	req.element_key = event.element_key
	req.tier = event.element_tier
	req.target_position = center
	req.radius = splash_radius
	return req

static func make_status_apply(monster: Monster, element: int, tier_value: int) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.STATUS_APPLY
	req.element = element
	req.tier = tier_value
	req.target_node = monster
	return req

static func make_status_tick(monster: Monster, element: int) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.STATUS_TICK
	req.element = element
	req.target_node = monster
	return req

static func make_status_end(monster: Monster, element: int) -> ElementFxRequest:
	var req := ElementFxRequest.new()
	req.fx_type = FxType.STATUS_END
	req.element = element
	req.target_node = monster
	return req
