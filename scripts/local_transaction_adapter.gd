extends RefCounted
class_name LocalTransactionAdapter

var next_result := true


func purchase(_product_id: String, _price_text: String) -> bool:
	var result := next_result
	next_result = true
	return result


func inject_next_result(success: bool) -> void:
	next_result = success

