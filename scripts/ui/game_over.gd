extends Control
## Game Over Screen Script
##
## Displays game over statistics and provides navigation options.
## Shows wave reached, enemies killed, and Digimon evolved.

@onready var _wave_label: Label = $VBoxContainer/StatsContainer/WaveLabel
@onready var _kills_label: Label = $VBoxContainer/StatsContainer/KillsLabel
@onready var _evolved_label: Label = $VBoxContainer/StatsContainer/EvolvedLabel
@onready var _try_again_button: Button = $VBoxContainer/ButtonContainer/TryAgainButton
@onready var _main_menu_button: Button = $VBoxContainer/ButtonContainer/MainMenuButton

# Stats to display (set these before transitioning to this scene)
var wave_reached: int = 0
var enemies_killed: int = 0
var digimon_evolved: int = 0


func _ready() -> void:
	_connect_signals()
	_update_stats_display()

	# Play game over sound when screen appears
	AudioManager.play_sfx("game_over")


func _connect_signals() -> void:
	_try_again_button.pressed.connect(_on_try_again_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)


func _update_stats_display() -> void:
	if _wave_label:
		_wave_label.text = "Wave Reached: %d" % wave_reached

	if _kills_label:
		_kills_label.text = "Enemies Killed: %d" % enemies_killed

	if _evolved_label:
		_evolved_label.text = "Digimon Evolved: %d" % digimon_evolved


## Set stats from external source before scene loads
func set_stats(wave: int, kills: int, evolved: int) -> void:
	wave_reached = wave
	enemies_killed = kills
	digimon_evolved = evolved
	_update_stats_display()


func _on_try_again_pressed() -> void:
	AudioManager.play_sfx("button_click")

	# Reset game state and start fresh
	GameManager.reset_game_state()

	# Check if starter selection exists, otherwise go to main level
	var starter_scene = "res://scenes/main/starter_selection.tscn"
	var main_level_scene = "res://scenes/levels/main_level.tscn"

	if ResourceLoader.exists(starter_scene):
		get_tree().change_scene_to_file(starter_scene)
	elif ResourceLoader.exists(main_level_scene):
		get_tree().change_scene_to_file(main_level_scene)
	else:
		ErrorHandler.log_warning("GameOver", "No game scene found to load")


func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button_click")

	# Reset game state
	GameManager.reset_game_state()

	# Return to main menu
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect button signals
	if _try_again_button and _try_again_button.pressed.is_connected(_on_try_again_pressed):
		_try_again_button.pressed.disconnect(_on_try_again_pressed)

	if _main_menu_button and _main_menu_button.pressed.is_connected(_on_main_menu_pressed):
		_main_menu_button.pressed.disconnect(_on_main_menu_pressed)
