extends Control
## HUD Script
##
## Manages the in-game heads-up display showing DigiBytes, lives, wave counter,
## and game speed controls. Connects to GameManager signals to stay updated.

@onready var _digibytes_label: Label = $TopBar/DigiBytes/AmountLabel
@onready var _lives_label: Label = $TopBar/Lives/AmountLabel
@onready var _wave_label: Label = $TopBar/Wave/WaveLabel
@onready var _speed_button: Button = $TopBar/SpeedButton
@onready var _spawn_panel: Panel = $BottomPanel


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
	GameManager.cycle_game_speed()


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
