extends RefCounted
class_name CurrencyType

const GOLD := "gold"
const GEMS := "gems"

const ALL_IDS: Array[String] = [GOLD, GEMS]


static func is_valid(currency_id: String) -> bool:
	return ALL_IDS.has(currency_id)
