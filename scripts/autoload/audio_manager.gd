extends Node
## AudioManager Autoload Singleton
##
## Manages all audio playback including sound effects and music.
## Provides volume controls and audio bus management.

# Constants
const MUSIC_FADE_DURATION: float = 1.0
const MAX_SIMULTANEOUS_SFX: int = 16
const SFX_BUS: String = "SFX"
const MUSIC_BUS: String = "Music"
const MASTER_BUS: String = "Master"

# Audio paths
const SFX_PATH: String = "res://assets/audio/sfx/"
const MUSIC_PATH: String = "res://assets/audio/music/"

# Volume settings (in linear scale 0.0 to 1.0)
var master_volume: float = 1.0:
	set(value):
		master_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume(MASTER_BUS, master_volume)

var music_volume: float = 0.8:
	set(value):
		music_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume(MUSIC_BUS, music_volume)

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clamp(value, 0.0, 1.0)
		_update_bus_volume(SFX_BUS, sfx_volume)

# Internal references
var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _current_sfx_index: int = 0
var _current_music_track: String = ""
var _music_fade_tween: Tween

# Preloaded common sounds cache
var _sound_cache: Dictionary = {}

# Common sound effect names for preloading
const COMMON_SFX: Array[String] = [
	"attack_hit",
	"attack_miss",
	"tower_spawn",
	"tower_sell",
	"tower_level_up",
	"tower_evolve",
	"merge_success",
	"enemy_death",
	"enemy_escape",
	"wave_start",
	"wave_complete",
	"boss_spawn",
	"button_click",
	"button_hover",
	"insufficient_funds",
	"game_over",
	"victory"
]


func _ready() -> void:
	_setup_audio_players()
	_preload_common_sounds()
	_initialize_volume_settings()


## Sets up the music player and SFX player pool
func _setup_audio_players() -> void:
	# Create music player
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = MUSIC_BUS
	_music_player.name = "MusicPlayer"
	add_child(_music_player)

	# Create SFX player pool
	for i in range(MAX_SIMULTANEOUS_SFX):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.bus = SFX_BUS
		sfx_player.name = "SFXPlayer_" + str(i)
		add_child(sfx_player)
		_sfx_players.append(sfx_player)


## Preloads commonly used sound effects into memory
func _preload_common_sounds() -> void:
	for sound_name in COMMON_SFX:
		var path = SFX_PATH + sound_name + ".wav"
		if ResourceLoader.exists(path):
			_sound_cache[sound_name] = load(path)
		else:
			# Try .ogg format as fallback
			path = SFX_PATH + sound_name + ".ogg"
			if ResourceLoader.exists(path):
				_sound_cache[sound_name] = load(path)


## Initialize volume from saved settings or defaults
func _initialize_volume_settings() -> void:
	# In a full implementation, load from ConfigFile or similar
	# For now, use defaults
	master_volume = 1.0
	music_volume = 0.8
	sfx_volume = 1.0


## Plays a sound effect by name
## sound_name: Name of the sound (without path or extension)
## pitch_variance: Random pitch variation (+/- this value)
## volume_db: Volume adjustment in decibels
func play_sfx(sound_name: String, pitch_variance: float = 0.0, volume_db: float = 0.0) -> void:
	var stream: AudioStream = _get_sound(sound_name)
	if stream == null:
		ErrorHandler.log_warning("AudioManager", "Sound not found - " + sound_name)
		return

	# Get next available player (round-robin)
	var player = _sfx_players[_current_sfx_index]
	_current_sfx_index = (_current_sfx_index + 1) % MAX_SIMULTANEOUS_SFX

	# Configure and play
	player.stream = stream
	player.volume_db = volume_db

	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)
	else:
		player.pitch_scale = 1.0

	player.play()


## Plays a sound effect at a specific position (for 2D positional audio)
## Returns the AudioStreamPlayer2D used (caller can connect to finished signal if needed)
func play_sfx_at_position(sound_name: String, position: Vector2,
		pitch_variance: float = 0.0, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	var stream: AudioStream = _get_sound(sound_name)
	if stream == null:
		ErrorHandler.log_warning("AudioManager", "Sound not found - " + sound_name)
		return null

	# Create a temporary positional player
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = SFX_BUS
	player.volume_db = volume_db
	player.position = position

	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)

	# Auto-cleanup when finished
	player.finished.connect(player.queue_free)

	get_tree().current_scene.add_child(player)
	player.play()

	return player


## Plays a music track with optional crossfade
## track_name: Name of the music track (without path or extension)
## crossfade: Whether to fade between tracks
func play_music(track_name: String, crossfade: bool = true) -> void:
	if track_name == _current_music_track and _music_player.playing:
		return  # Already playing this track

	var path = MUSIC_PATH + track_name + ".ogg"
	if not ResourceLoader.exists(path):
		path = MUSIC_PATH + track_name + ".mp3"
		if not ResourceLoader.exists(path):
			ErrorHandler.log_warning("AudioManager", "Music track not found - " + track_name)
			return

	var stream = load(path)

	if crossfade and _music_player.playing:
		_crossfade_to_track(stream, track_name)
	else:
		_music_player.stream = stream
		_music_player.play()
		_current_music_track = track_name


## Stops the currently playing music
## fade_out: Whether to fade out instead of stopping immediately
func stop_music(fade_out: bool = true) -> void:
	if not _music_player.playing:
		return

	if fade_out:
		_fade_out_music()
	else:
		_music_player.stop()
		_current_music_track = ""


## Pauses or unpauses music
func set_music_paused(paused: bool) -> void:
	_music_player.stream_paused = paused


## Returns whether music is currently playing
func is_music_playing() -> bool:
	return _music_player.playing and not _music_player.stream_paused


## Gets the name of the currently playing music track
func get_current_music_track() -> String:
	return _current_music_track


## Sets master volume (0.0 to 1.0)
func set_master_volume(volume: float) -> void:
	master_volume = volume


## Sets music volume (0.0 to 1.0)
func set_music_volume(volume: float) -> void:
	music_volume = volume


## Sets SFX volume (0.0 to 1.0)
func set_sfx_volume(volume: float) -> void:
	sfx_volume = volume


## Mutes all audio
func mute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), true)


## Unmutes all audio
func unmute_all() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MASTER_BUS), false)


## Toggles mute state
func toggle_mute() -> bool:
	var bus_index = AudioServer.get_bus_index(MASTER_BUS)
	var is_muted = AudioServer.is_bus_mute(bus_index)
	AudioServer.set_bus_mute(bus_index, not is_muted)
	return not is_muted


## Returns whether audio is muted
func is_muted() -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(MASTER_BUS))


# =============================================================================
# INTERNAL METHODS
# =============================================================================

## Gets a sound from cache or loads it
func _get_sound(sound_name: String) -> AudioStream:
	# Check cache first
	if _sound_cache.has(sound_name):
		return _sound_cache[sound_name]

	# Try to load
	var path = SFX_PATH + sound_name + ".wav"
	if ResourceLoader.exists(path):
		var stream = load(path)
		_sound_cache[sound_name] = stream
		return stream

	# Try .ogg format
	path = SFX_PATH + sound_name + ".ogg"
	if ResourceLoader.exists(path):
		var stream = load(path)
		_sound_cache[sound_name] = stream
		return stream

	return null


## Updates an audio bus volume
func _update_bus_volume(bus_name: String, linear_volume: float) -> void:
	var bus_index = AudioServer.get_bus_index(bus_name)
	if bus_index == -1:
		ErrorHandler.log_warning("AudioManager", "Bus not found - " + bus_name)
		return

	# Convert linear to decibels (0.0 linear = -80db, 1.0 linear = 0db)
	var db = linear_to_db(linear_volume)
	AudioServer.set_bus_volume_db(bus_index, db)


## Crossfades from current track to new track
func _crossfade_to_track(new_stream: AudioStream, track_name: String) -> void:
	# Cancel any existing fade
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	# Store original volume
	var original_volume = _music_player.volume_db

	# Create crossfade tween
	_music_fade_tween = create_tween()

	# Fade out current
	_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION / 2)

	# Switch track and fade in
	_music_fade_tween.tween_callback(func():
		_music_player.stream = new_stream
		_music_player.play()
		_current_music_track = track_name
	)

	_music_fade_tween.tween_property(_music_player, "volume_db", original_volume, MUSIC_FADE_DURATION / 2)


## Fades out current music
func _fade_out_music() -> void:
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	_music_fade_tween = create_tween()
	_music_fade_tween.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_DURATION)
	_music_fade_tween.tween_callback(func():
		_music_player.stop()
		_music_player.volume_db = 0.0
		_current_music_track = ""
	)


## Array to track positional audio players for cleanup
var _active_positional_players: Array[AudioStreamPlayer2D] = []


## Plays a sound effect at a specific position (for 2D positional audio) - tracked version
## Returns the AudioStreamPlayer2D used (caller can connect to finished signal if needed)
func play_sfx_at_position_tracked(sound_name: String, position: Vector2,
		pitch_variance: float = 0.0, volume_db: float = 0.0) -> AudioStreamPlayer2D:
	var stream: AudioStream = _get_sound(sound_name)
	if stream == null:
		ErrorHandler.log_warning("AudioManager", "Sound not found - " + sound_name)
		return null

	# Create a temporary positional player
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.bus = SFX_BUS
	player.volume_db = volume_db
	player.position = position

	if pitch_variance > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variance, pitch_variance)

	# Track the player for cleanup
	_active_positional_players.append(player)

	# Auto-cleanup when finished
	player.finished.connect(_on_positional_player_finished.bind(player))

	get_tree().current_scene.add_child(player)
	player.play()

	return player


## Handle positional player finished - remove from tracking and free
func _on_positional_player_finished(player: AudioStreamPlayer2D) -> void:
	_active_positional_players.erase(player)
	if is_instance_valid(player):
		player.queue_free()


## Cleanup all active positional audio players (call on scene change)
func cleanup_positional_audio() -> void:
	for player in _active_positional_players:
		if is_instance_valid(player):
			if player.finished.is_connected(_on_positional_player_finished):
				player.finished.disconnect(_on_positional_player_finished.bind(player))
			player.queue_free()
	_active_positional_players.clear()


func _exit_tree() -> void:
	# Kill any active music fade tween
	if _music_fade_tween and _music_fade_tween.is_valid():
		_music_fade_tween.kill()

	# Cleanup all positional audio players
	cleanup_positional_audio()

	# Clear sound cache
	_sound_cache.clear()

	# Stop all SFX players
	for player in _sfx_players:
		if is_instance_valid(player):
			player.stop()

	# Stop music
	if _music_player and is_instance_valid(_music_player):
		_music_player.stop()
