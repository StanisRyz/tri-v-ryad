extends RefCounted
class_name ShopPurchaseKind

## currency: item can be bought with existing gold/gems through ProgressManager.
## external_payment: item is listed but cannot be purchased yet because real
## payments are not connected.
const CURRENCY := "currency"
const EXTERNAL_PAYMENT := "external_payment"

const ALL_IDS: Array[String] = [CURRENCY, EXTERNAL_PAYMENT]


static func is_valid(purchase_kind: String) -> bool:
	return ALL_IDS.has(purchase_kind)
