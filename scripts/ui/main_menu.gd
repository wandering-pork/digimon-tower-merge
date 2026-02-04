extends Control
## Main Menu Script
##
## Handles main menu navigation and button interactions.
## Provides access to New Game, Continue, Settings, and Quit options.

## Scene paths - centralized for easy maintenance
const STARTER_SELECTION_SCENE = "res://scenes/ui/starter_selection.tscn"
const MAIN_LEVEL_SCENE = "res://scenes/levels/main_level.tscn"

## Button hover colors for visual feedback
const HOVER_COLOR = Color(1.2, 1.2, 1.2, 1.0)
const NORMAL_COLOR = Color.WHITE
const DISABLED_COLOR = Color(0.5, 0.5, 0.5, 1.0)

@onready var _new_game_button: Button = $VBoxContainer/NewGameButton
@onready var _continue_button: Button = $VBoxContainer/ContinueButton
@onready var _settings_button: Button = $VBoxContainer/SettingsButton
@onready var _quit_button: Button = $VBoxContainer/QuitButton
@onready var _settings_panel: Panel = $SettingsPanel

## Track all buttons for cleanup
var _buttons: Array[Button] = []


func _ready() -> void:
	_connect_signals()
	_setup_button_hover_effects()
	_check_save_data()

	# Ensure settings panel starts hidden
	if _settings_panel:
		_settings_panel.visible = false


func _exit_tree() -> void:
	# Disconnect all signals to prevent memory leaks
	_disconnect_signals()


func _connect_signals() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_continue_button.pressed.connect(_on_continue_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func _disconnect_signals() -> void:
	# Safely disconnect button signals
	for button in _buttons:
		if is_instance_valid(button):
			if button.mouse_entered.is_connected(_on_button_hover_enter.bind(button)):
				button.mouse_entered.disconnect(_on_button_hover_enter.bind(button))
			if button.mouse_exited.is_connected(_on_button_hover_exit.bind(button)):
				button.mouse_exited.disconnect(_on_button_hover_exit.bind(button))


func _setup_button_hover_effects() -> void:
	## Setup hover visual feedback for all menu buttons
	_buttons = [_new_game_button, _continue_button, _settings_button, _quit_button]

	for button in _buttons:
		if button:
			button.mouse_entered.connect(_on_button_hover_enter.bind(button))
			button.mouse_exited.connect(_on_button_hover_exit.bind(button))


func _on_button_hover_enter(button: Button) -> void:
	## Apply hover effect to button
	if button and not button.disabled:
		button.modulate = HOVER_COLOR
		AudioManager.play_sfx("button_hover")


func _on_button_hover_exit(button: Button) -> void:
	## Remove hover effect from button
	if button:
		if button.disabled:
			button.modulate = DISABLED_COLOR
		else:
			button.modulate = NORMAL_COLOR


func _check_save_data() -> void:
	## Check if save file exists and update Continue button state
	var save_exists = SaveSystem.has_save_game() if SaveSystem else false
	_continue_button.disabled = not save_exists

	# Visual feedback for disabled state
	if _continue_button.disabled:
		_continue_button.modulate = DISABLED_COLOR
	else:
		_continue_button.modulate = NORMAL_COLOR


func _on_new_game_pressed() -> void:
	## Start a new game - reset state and transition to starter selection or main level
	AudioManager.play_sfx("button_click")

	# Reset game state before starting
	GameManager.reset_game_state()

	# Emit event for any listeners (e.g., analytics, audio)
	if EventBus.has_signal("game_paused"):
		EventBus.game_paused.emit(false)

	# Check if starter selection scene exists, otherwise go directly to main level
	if ResourceLoader.exists(STARTER_SELECTION_SCENE):
		_transition_to_scene(STARTER_SELECTION_SCENE)
	elif ResourceLoader.exists(MAIN_LEVEL_SCENE):
		_transition_to_scene(MAIN_LEVEL_SCENE)
	else:
		ErrorHandler.log_error("MainMenu", "No game scene found to load - checked: %s, %s" % [STARTER_SELECTION_SCENE, MAIN_LEVEL_SCENE])


func _on_continue_pressed() -> void:
	## Continue from saved game
	AudioManager.play_sfx("button_click")

	if _continue_button.disabled:
		_show_no_save_message()
		return

	# Load saved game
	if _load_game():
		_transition_to_scene(MAIN_LEVEL_SCENE)
	else:
		_show_no_save_message()


func _on_settings_pressed() -> void:
	## Open the settings panel
	AudioManager.play_sfx("button_click")

	if _settings_panel:
		_settings_panel.visible = true
	else:
		ErrorHandler.log_warning("MainMenu", "Settings panel not found")
		# Fallback: print message to console
		print("[MainMenu] Settings functionality not yet implemented")


func _on_quit_pressed() -> void:
	## Quit the application
	AudioManager.play_sfx("button_click")
	ErrorHandler.log_info("MainMenu", "User requested quit")
	get_tree().quit()


func _transition_to_scene(scene_path: String) -> void:
	## Safely transition to a new scene with error handling
	var error = get_tree().change_scene_to_file(scene_path)
	if error != OK:
		ErrorHandler.log_error("MainMenu", "Failed to change scene to: %s (error: %d)" % [scene_path, error])


func _show_no_save_message() -> void:
	## Display a popup message when no save file is found
	var dialog = AcceptDialog.new()
	dialog.dialog_text = "No saved game found."
	dialog.title = "Continue"
	add_child(dialog)
	dialog.popup_centered()

	# Auto-cleanup when dialog is confirmed or closed
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)


func _load_game() -> bool:
	## Load saved game state from file using SaveSystem
	## Returns true if load was successful, false otherwise
	if not SaveSystem:
		ErrorHandler.log_error("MainMenu", "SaveSystem not available")
		return false

	if not SaveSystem.has_save_game():
		return false

	# Use SaveSystem to load the game state
	var success = SaveSystem.load_game()

	if success:
		ErrorHandler.log_info("MainMenu", "Game loaded successfully - Wave: %d, Lives: %d, DB: %d" % [
			GameManager.current_wave, GameManager.lives, GameManager.current_digibytes
		])

	return success


## Called when the settings panel close button is pressed
func _on_settings_close_pressed() -> void:
	if _settings_panel:
		_settings_panel.visible = false
