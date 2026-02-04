extends Node
## GameManager Autoload Singleton
##
## Manages core game state including currency, lives, waves, and game speed.
## This is the central source of truth for the game's economic and progress systems.
##
## NOTE: All game balance constants are defined in GameConfig autoload.
## This manager uses those constants for initial values and game rules.

# Signals
signal digibytes_changed(new_amount: int)
signal lives_changed(new_lives: int)
signal wave_changed(new_wave: int)
signal game_speed_changed(new_speed: float)
signal game_over

# Game State
var current_digibytes: int = GameConfig.STARTING_DIGIBYTES:
	set(value):
		var old_value = current_digibytes
		current_digibytes = max(0, value)
		if current_digibytes != old_value:
			digibytes_changed.emit(current_digibytes)

var lives: int = GameConfig.STARTING_LIVES:
	set(value):
		var old_value = lives
		lives = max(0, value)
		if lives != old_value:
			lives_changed.emit(lives)
			if lives <= 0:
				_trigger_game_over()

var current_wave: int = 0:
	set(value):
		var old_value = current_wave
		current_wave = max(0, value)
		if current_wave != old_value:
			wave_changed.emit(current_wave)

var game_speed: float = 1.0:
	set(value):
		if value in GameConfig.VALID_GAME_SPEEDS:
			var old_value = game_speed
			game_speed = value
			Engine.time_scale = game_speed
			if game_speed != old_value:
				game_speed_changed.emit(game_speed)

var _is_game_over: bool = false


func _ready() -> void:
	reset_game_state()


## Resets all game state to initial values
func reset_game_state() -> void:
	_is_game_over = false
	current_digibytes = GameConfig.STARTING_DIGIBYTES
	lives = GameConfig.STARTING_LIVES
	current_wave = 0
	game_speed = 1.0


## Adds DigiBytes to the player's balance
## Returns the new total
func add_digibytes(amount: int) -> int:
	if amount > 0:
		current_digibytes += amount
	return current_digibytes


## Attempts to spend DigiBytes
## Returns true if successful, false if insufficient funds
func spend_digibytes(amount: int) -> bool:
	if amount <= 0:
		return true

	if current_digibytes >= amount:
		current_digibytes -= amount
		return true

	return false


## Checks if player can afford a purchase
func can_afford(amount: int) -> bool:
	return current_digibytes >= amount


## Reduces lives when an enemy escapes
## Use is_boss=true for boss enemies (3 life penalty)
func lose_life(is_boss: bool = false) -> void:
	if _is_game_over:
		return

	var penalty = GameConfig.BOSS_LIFE_PENALTY if is_boss else GameConfig.NORMAL_LIFE_PENALTY
	lives -= penalty


## Grants bonus lives (e.g., every 10 waves)
func gain_life(amount: int = 1) -> void:
	if amount > 0:
		lives += amount


## Sets the game speed to a specific value
## Only accepts valid speeds: 1.0, 1.5, 2.0
func set_game_speed(speed: float) -> void:
	game_speed = speed


## Cycles through game speeds: 1.0 -> 1.5 -> 2.0 -> 1.0
func cycle_game_speed() -> void:
	var current_index = GameConfig.VALID_GAME_SPEEDS.find(game_speed)
	var next_index = (current_index + 1) % GameConfig.VALID_GAME_SPEEDS.size()
	game_speed = GameConfig.VALID_GAME_SPEEDS[next_index]


## Advances to the next wave
func advance_wave() -> void:
	current_wave += 1

	# Bonus life every N waves (from GameConfig)
	if current_wave % GameConfig.BONUS_LIFE_WAVE_INTERVAL == 0:
		gain_life(1)


## Returns true if the game is over
func is_game_over() -> bool:
	return _is_game_over


## Internal function to trigger game over state
func _trigger_game_over() -> void:
	if _is_game_over:
		return

	_is_game_over = true
	Engine.time_scale = 1.0  # Reset speed on game over
	game_over.emit()
