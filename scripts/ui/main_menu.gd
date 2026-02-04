extends Control
## Main Menu Script
##
## Handles main menu navigation and button interactions.
## Provides access to New Game, Continue, Settings, and Quit options.

@onready var _new_game_button: Button = $VBoxContainer/NewGameButton
@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _settings_button: Button = $VBoxContainer/SettingsButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton
@onready var _settings_panel: Panel = $SettingsPanel


func _ready() -> void:
	_connect_signals()
	_check_save_data()

	# Ensure settings panel starts hidden
	if _settings_panel:
		_settings_panel.visible = false


func _connect_signals() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _check_save_data() -> void:
	# Check if save file exists
	var save_exists = FileAccess.file_exists("user://savegame.save")
	_continue_button.disabled = not save_exists

	# Visual feedback for disabled state
	if _continue_button.disabled:
		_continue_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	else:
		_continue_button.modulate = Color.WHITE


func _on_new_game_pressed() -> void:
	# Reset game state before starting
	GameManager.reset_game_state()

	# Check if starter selection scene exists, otherwise go directly to main level
	var starter_scene = "res://scenes/main/starter_selection.tscn"
	var main_level_scene = "res://scenes/levels/main_level.tscn"

	if ResourceLoader.exists(starter_scene):
		get_tree().change_scene_to_file(starter_scene)
	elif ResourceLoader.exists(main_level_scene):
		get_tree().change_scene_to_file(main_level_scene)
	else:
		ErrorHandler.log_warning("MainMenu", "No game scene found to load")


func _on_continue_pressed() -> void:
	if _continue_button.disabled:
		_show_no_save_message()
		return

	# Load saved game
	if _load_game():
		get_tree().change_scene_to_file("res://scenes/levels/main_level.tscn")
	else:
		_show_no_save_message()


func _on_settings_pressed() -> void:
	if _settings_panel:
		_settings_panel.visible = true
	else:
		ErrorHandler.log_warning("MainMenu", "Settings panel not found")


func _on_quit_pressed() -> void:
	get_tree().quit()


func _show_no_save_message() -> void:
	# Create a simple popup message
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "No saved game found."
	dialog.title = "Continue"
	add_child(dialog)
	dialog.popup_centered()

	# Auto-cleanup
	dialog.confirmed.connect(dialog.queue_free)


func _load_game() -> bool:
	# Check if save file exists
	if not FileAccess.file_exists("user://savegame.save"):
		return false

	var save_file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if save_file == null:
		return false

	var json = JSON.new()
	var json_string = save_file.get_as_text()
	save_file.close()

	var parse_result = json.parse(json_string)
	if parse_result != OK:
		ErrorHandler.log_error("MainMenu", "Failed to parse save file")
		return false

	var save_data = json.get_data()
	if save_data is Dictionary:
		# Restore game state
		if save_data.has("digibytes"):
			GameManager.current_digibytes = save_data.digibytes
		if save_data.has("lives"):
			GameManager.lives = save_data.lives
		if save_data.has("wave"):
			GameManager.current_wave = save_data.wave
		return true

	return false


## Called when the settings panel close button is pressed
func _on_settings_close_pressed() -> void:
	if _settings_panel:
		_settings_panel.visible = false
