extends RefCounted
class_name FeatureFlags

## Stage 32: hero/RPG systems are frozen in favor of direct match-3 damage.
## Flip HERO_SYSTEMS_ENABLED back to true to resume the hero battle path.
static var HERO_SYSTEMS_ENABLED := false
static var DIRECT_MATCH_DAMAGE_ENABLED := true

## Stage 64.16: gates the F12/F1/F2 developer debug hotkeys (see GameScreen).
## Leave false for production builds; flip to true only for local dev/testing.
static var DEBUG_MODE_ENABLED := true
