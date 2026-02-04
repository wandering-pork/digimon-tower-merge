extends Control
## HUD Script
##
## Manages the in-game heads-up display showing DigiBytes, lives, wave counter,
## and game speed controls. Connects to GameManager signals to stay updated.

signal spawn_tower_requested()

@onready var _digibytes_label: Label = $TopBar/DigiBytes/AmountLabel
@onready var _lives_label: Label = $TopBar/Lives/AmountLabel
@onready var _wave_label: Label = $TopBar/Wave/WaveLabel
@onready var _speed_button: Button = $TopBar/SpeedButton
@onready var _spawn_panel: Panel = $BottomPanel
@onready var _spawn_tower_btn: Button = $BottomPanel/SpawnControls/SpawnTowerBtn


func _ready() -> void:
	_connect_signals()
	_update_all_displays()


func _connect_signals() -> void:
	# Connect to GameManager signals
	GameManager.digibytes_changed.connect(_on_digibytes_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.game_speed_changed.connect(_on_game_speed_changed)

	# Connect speed button
	if _speed_button:
		_speed_button.pressed.connect(_on_speed_button_pressed)

	# Connect spawn tower button
	if _spawn_tower_btn:
		_spawn_tower_btn.pressed.connect(_on_spawn_tower_pressed)


func _update_all_displays() -> void:
	_on_digibytes_changed(GameManager.current_digibytes)
	_on_lives_changed(GameManager.lives)
	_on_wave_changed(GameManager.current_wave)
	_on_game_speed_changed(GameManager.game_speed)


func _on_digibytes_changed(new_amount: int) -> void:
	if _digibytes_label:
		_digibytes_label.text = str(new_amount)

		# Flash effect for changes
		_flash_label(_digibytes_label)


func _on_lives_changed(new_lives: int) -> void:
	if _lives_label:
		_lives_label.text = str(new_lives)

		# Color changes based on lives
		if new_lives <= 5:
			_lives_label.add_theme_color_override("font_color", Color.RED)
		elif new_lives <= 10:
			_lives_label.add_theme_color_override("font_color", Color.YELLOW)
		else:
			_lives_label.remove_theme_color_override("font_color")

		_flash_label(_lives_label)


func _on_wave_changed(new_wave: int) -> void:
	if _wave_label:
		_wave_label.text = "Wave %d" % new_wave


func _on_game_speed_changed(new_speed: float) -> void:
	if _speed_button:
		_speed_button.text = "%.1fx" % new_speed

		# Visual feedback for speed
		match new_speed:
			1.0:
				_speed_button.modulate = Color.WHITE
			1.5:
				_speed_button.modulate = Color.YELLOW
			2.0:
				_speed_button.modulate = Color.ORANGE


func _on_speed_button_pressed() -> void:
	AudioManager.play_sfx("button_click")
	GameManager.cycle_game_speed()


func _on_spawn_tower_pressed() -> void:
	## Open spawn menu in placement mode
	AudioManager.play_sfx("button_click")
	spawn_tower_requested.emit()


func _flash_label(label: Label) -> void:
	# Simple flash effect using a tween
	var tween = create_tween()
	var original_color = label.modulate
	tween.tween_property(label, "modulate", Color.WHITE * 1.5, 0.1)
	tween.tween_property(label, "modulate", original_color, 0.1)


## Show/hide the spawn panel
func set_spawn_panel_visible(visible: bool) -> void:
	if _spawn_panel:
		_spawn_panel.visible = visible


## Get reference to spawn panel for external use
func get_spawn_panel() -> Panel:
	return _spawn_panel


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect GameManager signals
	if GameManager:
		if GameManager.digibytes_changed.is_connected(_on_digibytes_changed):
			GameManager.digibytes_changed.disconnect(_on_digibytes_changed)

		if GameManager.lives_changed.is_connected(_on_lives_changed):
			GameManager.lives_changed.disconnect(_on_lives_changed)

		if GameManager.wave_changed.is_connected(_on_wave_changed):
			GameManager.wave_changed.disconnect(_on_wave_changed)

		if GameManager.game_speed_changed.is_connected(_on_game_speed_changed):
			GameManager.game_speed_changed.disconnect(_on_game_speed_changed)

	# Disconnect button signals
	if _speed_button and _speed_button.pressed.is_connected(_on_speed_button_pressed):
		_speed_button.pressed.disconnect(_on_speed_button_pressed)

	if _spawn_tower_btn and _spawn_tower_btn.pressed.is_connected(_on_spawn_tower_pressed):
		_spawn_tower_btn.pressed.disconnect(_on_spawn_tower_pressed)
