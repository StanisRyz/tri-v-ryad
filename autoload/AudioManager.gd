extends Node

## Stage 68.1: full AudioManager integration.
## - One shared shuffled music playlist (5 common tracks), not per-screen music.
## - Pooled SFX playback (16 players) with recursive button-click auto-binding.
## - Old key/method names (play_music, play_sfx, play_match, play_special_activate,
##   play_level_select, play_enemy_damage) are kept working so existing callers
##   and existing tests are unaffected.

const AUDIO_ASSET_CATALOG := preload("res://scripts/game/audio/audio_asset_catalog.gd")
const AUDIO_CONFIG := preload("res://scripts/game/audio/audio_config.gd")
const DEFAULT_MUSIC_KEY := "music_main"
const SFX_POOL_SIZE := 16
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"
const BUTTON_BOUND_META := "audio_button_bound"
const BUTTON_SKIP_META := "audio_skip"

var _music_enabled := true
var _sound_effects_enabled := true
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player_index := 0
## Stage 69.5: bus muting is reason-based so an ad close cannot unmute audio
## while the Yandex Game API (or browser focus) still has the game paused.
var _audio_pause_reasons: Dictionary = {}

var _music_paths_loaded := false
var _music_stream_paths: Array[String] = []
var _music_bag: Array[int] = []
var _last_music_index := -1


func _ready() -> void:
	_setup_players()


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not _music_enabled:
		stop_music()
		return

	play_main_music()


func is_music_enabled() -> bool:
	return _music_enabled


func set_sound_effects_enabled(enabled: bool) -> void:
	_sound_effects_enabled = enabled
	if not _sound_effects_enabled:
		for player in _sfx_players:
			player.stop()


func is_sound_effects_enabled() -> bool:
	return _sound_effects_enabled


## naruto-clicker-style alias for set_sound_effects_enabled.
func set_sound_enabled(enabled: bool) -> void:
	set_sound_effects_enabled(enabled)


func play_music(audio_key: String = DEFAULT_MUSIC_KEY) -> void:
	_ensure_players_ready()
	if not _music_enabled:
		stop_music()
		return

	var stream: AudioStream = AUDIO_ASSET_CATALOG.try_load_audio_stream_cached(audio_key)
	if stream == null:
		return

	if _music_player.stream == stream and _music_player.playing:
		return

	_music_player.stream = stream
	_music_player.play()


## Starts the shared shuffled playlist if it is not already playing. Safe to
## call repeatedly (screen changes, app startup) — it never restarts a track
## that is already in progress.
func play_main_music() -> void:
	_ensure_players_ready()
	if not _music_enabled:
		return
	if _music_player.playing:
		return

	play_random_music_track()


## Plays a random track from the shared playlist (shuffle-bag: every track is
## played once before any track repeats, and the same track never repeats
## back-to-back when more than one valid track exists).
func play_random_music_track() -> void:
	_ensure_players_ready()
	_load_valid_music_paths()
	if not _music_enabled or _music_stream_paths.is_empty():
		return

	_play_next_bag_track()


## Advances to the next track in the shuffled playlist.
func play_next_music_track() -> void:
	play_random_music_track()


func stop_music() -> void:
	_ensure_players_ready()
	if _music_player != null:
		_music_player.stop()


func play_sfx(audio_key: String) -> void:
	_ensure_players_ready()
	if not _sound_effects_enabled:
		return

	var stream: AudioStream = AUDIO_ASSET_CATALOG.try_load_audio_stream_cached(audio_key)
	if stream == null:
		return

	var player := _get_available_sfx_player()
	if player == null:
		return

	player.stop()
	player.stream = stream
	player.play()


func play_button_click() -> void:
	play_sfx("sfx_button_click")


func play_level_select() -> void:
	play_sfx("sfx_level_select")


func play_tile_swap() -> void:
	play_sfx("sfx_tile_swap")


## Stage 68.1 hotfix: one call = one destroyed crystal (the caller loops per
## cleared cell), so every crystal in a match/cascade/booster clear gets its
## own burst sound, all free to overlap through the SFX pool. No throttling —
## an intentional per-crystal design, not per-clear-event.
func play_crystal_burst() -> void:
	play_sfx("sfx_crystal_burst")


## Compatibility alias: match clears are crystal bursts.
func play_match() -> void:
	play_crystal_burst()


func play_invalid_swap() -> void:
	play_sfx("sfx_invalid_swap")


func play_special_crystal() -> void:
	play_sfx("sfx_special_crystal")


## Compatibility alias: special-tile activation is a special-crystal sound.
func play_special_activate() -> void:
	play_special_crystal()


func play_booster_hammer() -> void:
	play_sfx("sfx_booster_hammer")


func play_booster_rocket_barrage() -> void:
	play_sfx("sfx_booster_rocket_barrage")


func play_booster_freeze_time() -> void:
	play_sfx("sfx_booster_freeze_time")


func play_enemy_hit() -> void:
	play_sfx("sfx_enemy_hit")


## Compatibility alias.
func play_enemy_damage() -> void:
	play_enemy_hit()


func play_victory() -> void:
	play_sfx("sfx_victory")


func play_defeat() -> void:
	play_sfx("sfx_defeat")


func play_lose_continue() -> void:
	play_sfx("sfx_lose_continue")


func play_purchase_success() -> void:
	play_sfx("sfx_purchase_success")


func play_purchase_error() -> void:
	play_sfx("sfx_purchase_error")


## Stage 69.2: mutes Music/SFX bus output for the duration of a rewarded ad
## without touching `_music_enabled`/`_sound_effects_enabled` — the player's
## actual Settings toggles are never overwritten, so resume_after_ad() never
## re-starts music the player had turned off.
func pause_for_ad() -> void:
	pause_audio("rewarded_ad")


func resume_after_ad() -> void:
	resume_audio("rewarded_ad")


func pause_audio(reason: String) -> void:
	if reason == "" or _audio_pause_reasons.has(reason):
		return
	var was_paused := not _audio_pause_reasons.is_empty()
	_audio_pause_reasons[reason] = true
	if not was_paused:
		_set_bus_mute(MUSIC_BUS_NAME, true)
		_set_bus_mute(SFX_BUS_NAME, true)


func resume_audio(reason: String) -> void:
	if reason == "" or not _audio_pause_reasons.has(reason):
		return
	_audio_pause_reasons.erase(reason)
	if _audio_pause_reasons.is_empty():
		_set_bus_mute(MUSIC_BUS_NAME, false)
		_set_bus_mute(SFX_BUS_NAME, false)


func is_audio_paused() -> bool:
	return not _audio_pause_reasons.is_empty()


func get_audio_pause_reasons() -> Array[String]:
	var reasons: Array[String] = []
	for reason in _audio_pause_reasons:
		reasons.append(str(reason))
	return reasons


func _set_bus_mute(bus_name: String, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_mute(bus_index, muted)


## Recursively binds every BaseButton under root_node to play_button_click()
## on press. Idempotent (won't double-bind a button already bound) and
## respects a per-button "audio_skip" metadata flag for buttons that already
## have their own click-sound wiring (avoids double click sounds).
func bind_buttons_in_tree(root_node: Node) -> void:
	if root_node == null:
		return

	if root_node is BaseButton:
		bind_button(root_node)

	for child in root_node.get_children():
		bind_buttons_in_tree(child)


func bind_button(button: BaseButton) -> void:
	if button == null:
		return
	if button.has_meta(BUTTON_SKIP_META) and bool(button.get_meta(BUTTON_SKIP_META)):
		return
	if button.has_meta(BUTTON_BOUND_META) and bool(button.get_meta(BUTTON_BOUND_META)):
		return

	button.set_meta(BUTTON_BOUND_META, true)
	button.pressed.connect(play_button_click)


func _setup_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.bus = MUSIC_BUS_NAME
		_music_player.volume_db = AUDIO_CONFIG.DEFAULT_MUSIC_VOLUME_DB
		_music_player.finished.connect(_on_music_player_finished)
		add_child(_music_player)

	if _sfx_players.is_empty():
		for index in range(SFX_POOL_SIZE):
			var player := AudioStreamPlayer.new()
			player.name = "SfxPlayer%d" % (index + 1)
			player.bus = SFX_BUS_NAME
			player.volume_db = AUDIO_CONFIG.DEFAULT_SFX_VOLUME_DB
			_sfx_players.append(player)
			add_child(player)


func _ensure_players_ready() -> void:
	if _music_player == null or _sfx_players.is_empty():
		_setup_players()


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_players:
		if not player.playing:
			return player

	var player: AudioStreamPlayer = _sfx_players[_next_sfx_player_index]
	_next_sfx_player_index = (_next_sfx_player_index + 1) % _sfx_players.size()
	return player


func _load_valid_music_paths() -> void:
	if _music_paths_loaded:
		return
	_music_paths_loaded = true

	for path in AUDIO_CONFIG.MUSIC_TRACK_PATHS:
		if ResourceLoader.exists(path):
			_music_stream_paths.append(path)


func _play_next_bag_track() -> void:
	if _music_bag.is_empty():
		_refill_music_bag()
	if _music_bag.is_empty():
		return

	var index: int = _music_bag.pop_back()
	_last_music_index = index

	var stream := ResourceLoader.load(_music_stream_paths[index]) as AudioStream
	if stream == null:
		return

	_music_player.stream = stream
	_music_player.play()


## Shuffle-bag refill: every valid track index appears exactly once, ordered
## randomly, with the track that just finished never landing as the next pick
## (the array is popped from the back) when more than one track is valid.
func _refill_music_bag() -> void:
	var indices: Array[int] = []
	for index in range(_music_stream_paths.size()):
		indices.append(index)

	indices.shuffle()

	if indices.size() > 1 and indices[indices.size() - 1] == _last_music_index:
		var swap_index := randi_range(0, indices.size() - 2)
		var last_index := indices.size() - 1
		var tmp: int = indices[last_index]
		indices[last_index] = indices[swap_index]
		indices[swap_index] = tmp

	_music_bag = indices


func _on_music_player_finished() -> void:
	if not _music_enabled:
		return
	_play_next_bag_track()
