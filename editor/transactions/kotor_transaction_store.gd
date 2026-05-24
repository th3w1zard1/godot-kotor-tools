@tool
extends RefCounted
class_name KotorTransactionStore

var _transactions: Array[Dictionary] = []
var _next_id := 1


func record_transaction(entry: Dictionary) -> Dictionary:
	var stored := entry.duplicate(true)
	if str(stored.get("id", "")).is_empty():
		stored["id"] = "tx-%04d" % _next_id
		_next_id += 1
	_transactions.append(stored)
	return stored.duplicate(true)


func get_transaction(transaction_id: String) -> Dictionary:
	for entry in _transactions:
		if str(entry.get("id", "")) == transaction_id:
			return entry.duplicate(true)
	return {}


func list_transactions() -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	for entry in _transactions:
		results.append(entry.duplicate(true))
	return results
