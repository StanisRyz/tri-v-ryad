extends RefCounted
class_name ShopPurchaseKind

## currency: item can be bought with existing gold/gems through ProgressManager.
## external_payment: item is listed but cannot be purchased yet because real
## payments are not connected.
## ad_watch: item is listed but cannot be purchased yet because a rewarded-ad
## SDK is not connected (same "listed, not wired up yet" shape as
## external_payment, kept as a distinct kind so it can read/format
## differently once ads are integrated).
const CURRENCY := "currency"
const EXTERNAL_PAYMENT := "external_payment"
const AD_WATCH := "ad_watch"

const ALL_IDS: Array[String] = [CURRENCY, EXTERNAL_PAYMENT, AD_WATCH]


static func is_valid(purchase_kind: String) -> bool:
	return ALL_IDS.has(purchase_kind)
