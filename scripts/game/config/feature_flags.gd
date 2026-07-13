extends RefCounted
class_name FeatureFlags

## Stage 32: hero/RPG systems are frozen in favor of direct match-3 damage.
## Flip HERO_SYSTEMS_ENABLED back to true to resume the hero battle path.
static var HERO_SYSTEMS_ENABLED := false
static var DIRECT_MATCH_DAMAGE_ENABLED := true

## Stage 69.5.3: F12/F1/F2/F3 are editor/debug-build tooling only. A release
## export must never enable them merely because a source flag was left on.
static var DEBUG_MODE_ENABLED := OS.is_debug_build()
