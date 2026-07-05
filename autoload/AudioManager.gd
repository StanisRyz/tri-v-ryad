extends Node

const AUDIO_ASSET_CATALOG := preload("res://scripts/game/audio/audio_asset_catalog.gd")
const DEFAULT_MUSIC_KEY := "music_main"
const SFX_POOL_SIZE := 8
const MUSIC_BUS_NAME := "Music"
const SFX_BUS_NAME := "SFX"

var _music_enabled := true
var _sound_effects_enabled := true
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx_player_index := 0


func _ready() -> void:
	_setup_players()


func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not _music_enabled:
		stop_music()


func is_music_enabled() -> bool:
	return _music_enabled


func set_sound_effects_enabled(enabled: bool) -> void:
	_sound_effects_enabled = enabled
	if not _sound_effects_enabled:
		for player in _sfx_players:
			player.stop()


func is_sound_effects_enabled() -> bool:
	return _sound_effects_enabled


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


func play_match() -> void:
	play_sfx("sfx_match")


func play_invalid_swap() -> void:
	play_sfx("sfx_invalid_swap")


func play_special_activate() -> void:
	play_sfx("sfx_special_activate")


func play_enemy_damage() -> void:
	play_sfx("sfx_enemy_damage")


func play_victory() -> void:
	play_sfx("sfx_victory")


func play_defeat() -> void:
	play_sfx("sfx_defeat")


func _setup_players() -> void:
	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "MusicPlayer"
		_music_player.bus = MUSIC_BUS_NAME
		add_child(_music_player)

	if _sfx_players.is_empty():
		for index in range(SFX_POOL_SIZE):
			var player := AudioStreamPlayer.new()
			player.name = "SfxPlayer%d" % (index + 1)
			player.bus = SFX_BUS_NAME
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
