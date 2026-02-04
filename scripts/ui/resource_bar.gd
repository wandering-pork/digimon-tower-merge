extends PanelContainer
## Resource Bar - Top HUD showing DigiBytes, Lives, Wave, and game controls.
## Connects to GameManager signals to stay updated.

signal speed_changed(new_speed: float)
signal pause_toggled(is_paused: bool)

## UI Node references
@onready var digibyte_amount: Label = $HBoxContainer/DigiByteSection/DigiByteAmount
@onready var lives_label: Label = $HBoxContainer/LivesSection/LivesLabel
@onready var lives_amount: Label = $HBoxContainer/LivesSection/LivesAmount
@onready var wave_label: Label = $HBoxContainer/WaveSection/WaveLabel
@onready var speed_btn: Button = $HBoxContainer/SpeedBtn
@onready var pause_btn: Button = $HBoxContainer/PauseBtn

## Pause state
var _is_paused: bool = false

## Colors for lives display
const COLOR_LIVES_NORMAL: Color = Color.WHITE
const COLOR_LIVES_LOW: Color = Color.YELLOW
const COLOR_LIVES_CRITICAL: Color = Color.RED


func _ready() -> void:
	_connect_signals()
	_update_all()


func _connect_signals() -> void:
	# Connect to GameManager signals
	if GameManager:
		GameManager.digibytes_changed.connect(_on_digibytes_changed)
		GameManager.lives_changed.connect(_on_lives_changed)
		GameManager.wave_changed.connect(_on_wave_changed)
		GameManager.game_speed_changed.connect(_on_speed_changed)

	# Connect button signals
	if speed_btn:
		speed_btn.pressed.connect(_on_speed_btn_pressed)
	if pause_btn:
		pause_btn.pressed.connect(_on_pause_btn_pressed)


func _update_all() -> void:
	if GameManager:
		_on_digibytes_changed(GameManager.current_digibytes)
		_on_lives_changed(GameManager.lives)
		_on_wave_changed(GameManager.current_wave)
		_on_speed_changed(GameManager.game_speed)


## Handle DigiBytes change
func _on_digibytes_changed(amount: int) -> void:
	if digibyte_amount:
		digibyte_amount.text = "%d DB" % amount
		_flash_label(digibyte_amount)


## Handle lives change
func _on_lives_changed(lives: int) -> void:
	if lives_amount:
		lives_amount.text = str(lives)

		# Color based on lives remaining
		if lives <= 5:
			lives_amount.add_theme_color_override("font_color", COLOR_LIVES_CRITICAL)
			lives_label.add_theme_color_override("font_color", COLOR_LIVES_CRITICAL)
		elif lives <= 10:
			lives_amount.add_theme_color_override("font_color", COLOR_LIVES_LOW)
			lives_label.add_theme_color_override("font_color", COLOR_LIVES_LOW)
		else:
			lives_amount.remove_theme_color_override("font_color")
			lives_label.remove_theme_color_override("font_color")

		_flash_label(lives_amount)


## Handle wave change
func _on_wave_changed(wave: int) -> void:
	if wave_label:
		wave_label.text = "Wave: %d" % wave


## Handle speed change
func _on_speed_changed(new_speed: float) -> void:
	if speed_btn:
		speed_btn.text = "%.1fx" % new_speed

		# Visual feedback for speed
		match new_speed:
			1.0:
				speed_btn.modulate = Color.WHITE
			1.5:
				speed_btn.modulate = Color.YELLOW
			2.0:
				speed_btn.modulate = Color.ORANGE


## Handle speed button press
func _on_speed_btn_pressed() -> void:
	if GameManager:
		GameManager.cycle_game_speed()
		speed_changed.emit(GameManager.game_speed)


## Handle pause button press
func _on_pause_btn_pressed() -> void:
	_is_paused = not _is_paused

	if _is_paused:
		pause_btn.text = ">"
		pause_btn.modulate = Color.GREEN
		get_tree().paused = true
	else:
		pause_btn.text = "||"
		pause_btn.modulate = Color.WHITE
		get_tree().paused = false

	pause_toggled.emit(_is_paused)

	if EventBus:
		EventBus.game_paused.emit(_is_paused)


## Flash a label for visual feedback
func _flash_label(label: Label) -> void:
	if not label:
		return

	var tween = create_tween()
	var original_color = label.modulate
	tween.tween_property(label, "modulate", Color.WHITE * 1.5, 0.1)
	tween.tween_property(label, "modulate", original_color, 0.1)


## Check if game is paused
func is_paused() -> bool:
	return _is_paused


## Force unpause (for game over, etc.)
func force_unpause() -> void:
	if _is_paused:
		_is_paused = false
		pause_btn.text = "||"
		pause_btn.modulate = Color.WHITE
		get_tree().paused = false


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

		if GameManager.game_speed_changed.is_connected(_on_speed_changed):
			GameManager.game_speed_changed.disconnect(_on_speed_changed)

	# Disconnect button signals
	if speed_btn and speed_btn.pressed.is_connected(_on_speed_btn_pressed):
		speed_btn.pressed.disconnect(_on_speed_btn_pressed)

	if pause_btn and pause_btn.pressed.is_connected(_on_pause_btn_pressed):
		pause_btn.pressed.disconnect(_on_pause_btn_pressed)
