extends SceneTree

# Stage 66.1: Localization Foundation.
# Manual regeneration entry point. Run with:
#   godot --headless --script res://scripts/tools/GenerateLocalizationData.gd

const LOCALIZATION_DATA_GENERATOR_SCRIPT := preload("res://scripts/tools/LocalizationDataGenerator.gd")


func _initialize() -> void:
	var success: bool = LOCALIZATION_DATA_GENERATOR_SCRIPT.generate()
	if success:
		print("LocalizationData regenerated from res://localization/game_text.csv")
	else:
		printerr("LocalizationData generation failed.")
	quit(0 if success else 1)
