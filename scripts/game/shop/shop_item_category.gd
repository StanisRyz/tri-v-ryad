extends RefCounted
class_name ShopItemCategory

const BOOSTERS := "boosters"
const GEMS := "gems"
const BUNDLES := "bundles"
const OFFERS := "offers"

const ALL_IDS: Array[String] = [BOOSTERS, GEMS, BUNDLES, OFFERS]


static func is_valid(category_id: String) -> bool:
	return ALL_IDS.has(category_id)
