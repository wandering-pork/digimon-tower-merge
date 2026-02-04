extends Node
## WaveManager Autoload Singleton
##
## Manages wave progression, state orchestration, and wave rewards.
## Central system for controlling the flow of enemy waves throughout the game.
## Accessed globally via WaveManager singleton.
## Uses WaveStateMachine for state management and WaveSpawner for enemy instantiation.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
# Autoload scripts load before regular scripts in Godot. We must preload
# non-autoload classes to ensure they're available for type hints.

const WaveStateMachine = preload("res://scripts/systems/wave_state_machine.gd")
const WaveSpawner = preload("res://scripts/systems/wave_spawner.gd")
const WaveGenerator = preload("res://scripts/systems/wave_generator.gd")
const EnemyDigimon = preload("res://scripts/enemies/enemy_digimon.gd")

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when a new wave starts
signal wave_started(wave_number: int, enemy_count: int)

## Emitted when all enemies in a wave are defeated/escaped
signal wave_completed(wave_number: int, reward: int)

## Emitted during intermission with remaining time
signal wave_intermission(time_remaining: float)

## Emitted when an enemy is spawned
signal enemy_spawned(enemy: Node)

## Emitted when a boss is spawned
signal boss_spawned(boss: Node)

## Emitted when wave 100 is completed
signal all_waves_completed()

## Emitted when the player starts the wave early
signal wave_started_early()

## Emitted when the wave state changes (forwarded from state machine)
signal state_changed(old_state: WaveStateMachine.State, new_state: WaveStateMachine.State)

# =============================================================================
# COMPONENTS
# =============================================================================

## Reference to the wave state machine
var _state_machine: WaveStateMachine = null

## Reference to the wave spawner component
var _spawner: WaveSpawner = null

# =============================================================================
# STATE VARIABLES
# =============================================================================

## Current wave number (0 before game starts)
var current_wave: int = 0

## Number of enemies still alive (not killed or escaped)
var enemies_alive: int = 0

## Total enemies in current wave (for tracking)
var total_enemies_this_wave: int = 0

## Enemies killed this wave (for reward calculation)
var enemies_killed_this_wave: int = 0

## Timer for intermission countdown
var intermission_timer: float = 0.0

## Is endless mode active (wave 101+)
var is_endless_mode: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Create and add state machine as child
	_state_machine = WaveStateMachine.new()
	_state_machine.name = "WaveStateMachine"
	add_child(_state_machine)

	# Create and add spawner as child
	_spawner = WaveSpawner.new()
	_spawner.name = "WaveSpawner"
	add_child(_spawner)

	# Connect to state machine signals
	_state_machine.state_changed.connect(_on_state_machine_state_changed)

	# Connect to spawner signals
	_spawner.enemy_spawned.connect(_on_spawner_enemy_spawned)
	_spawner.spawn_queue_empty.connect(_on_spawn_queue_empty)

	# Connect to EventBus signals
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_escaped.connect(_on_enemy_escaped)
	EventBus.wave_start_requested.connect(_on_wave_start_requested)


func _process(delta: float) -> void:
	if not _state_machine:
		return

	match _state_machine.current_state:
		WaveStateMachine.State.INTERMISSION:
			_process_intermission(delta)
		WaveStateMachine.State.COUNTDOWN:
			_process_countdown(delta)
		WaveStateMachine.State.SPAWNING:
			_process_spawning(delta)
		WaveStateMachine.State.IN_PROGRESS:
			# All enemies spawned, waiting for them to be cleared
			pass
		WaveStateMachine.State.BOSS_INCOMING:
			_process_boss_incoming(delta)


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Set references to game nodes
func setup(enemy_container: Node, grid_manager: Node) -> void:
	if _spawner:
		_spawner.setup(enemy_container, grid_manager)


## Start the game from wave 1
func start_game() -> void:
	current_wave = 0
	is_endless_mode = false
	_start_first_wave()


## Skip intermission and start wave immediately
func skip_intermission() -> void:
	if _state_machine.current_state == WaveStateMachine.State.INTERMISSION:
		intermission_timer = 0.0
		_begin_wave()


## Pause the wave spawning
func pause() -> void:
	set_process(false)


## Resume wave spawning
func resume() -> void:
	set_process(true)


## Get current wave state as string (for debugging)
func get_state_string() -> String:
	if _state_machine:
		return _state_machine.get_state_name()
	return "NO_STATE_MACHINE"


## Get the current state from the state machine
func get_current_state() -> WaveStateMachine.State:
	if _state_machine:
		return _state_machine.current_state
	return WaveStateMachine.State.IDLE


## Check if the wave system is in an active state (wave in progress)
func is_wave_active() -> bool:
	if _state_machine:
		return _state_machine.is_wave_active()
	return false


## Trigger game over (defeat state)
func trigger_defeat() -> void:
	if _state_machine and not _state_machine.is_terminal_state():
		_state_machine.transition_to(WaveStateMachine.State.DEFEAT)


## Check if the game has ended (victory or defeat)
func is_game_over() -> bool:
	if _state_machine:
		return _state_machine.is_terminal_state()
	return false


## Get the remaining time for the current timed state
func get_remaining_time() -> float:
	if _state_machine:
		return _state_machine.get_remaining_time()
	return 0.0


## Reset the wave manager to initial state
func reset() -> void:
	current_wave = 0
	enemies_alive = 0
	total_enemies_this_wave = 0
	enemies_killed_this_wave = 0
	intermission_timer = 0.0
	is_endless_mode = false

	# Reset components
	if _state_machine:
		_state_machine.reset()
	if _spawner:
		_spawner.clear_queue()


# =============================================================================
# WAVE FLOW CONTROL
# =============================================================================

## Start the first wave (called at game start from IDLE state)
func _start_first_wave() -> void:
	current_wave = 1
	is_endless_mode = false

	# Update GameManager
	GameManager.current_wave = current_wave

	# First wave goes directly to countdown (no intermission from IDLE)
	var is_boss_wave := current_wave % 10 == 0
	if is_boss_wave:
		_state_machine.boss_incoming_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.BOSS_INCOMING)
	else:
		_state_machine.countdown_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


## Start the next wave (called after wave complete)
func _start_next_wave() -> void:
	current_wave += 1

	# Check for endless mode
	if current_wave > GameConfig.MAIN_GAME_WAVES:
		is_endless_mode = true

	# Update GameManager
	GameManager.current_wave = current_wave

	# Configure state machine intermission duration
	_state_machine.intermission_duration = GameConfig.get_intermission_time(current_wave)
	intermission_timer = _state_machine.intermission_duration

	# Transition to intermission state
	_state_machine.transition_to(WaveStateMachine.State.INTERMISSION)

	# Emit intermission signal with next wave info
	EventBus.wave_intermission.emit(current_wave, intermission_timer)


## Begin the actual wave (after intermission)
func _begin_wave() -> void:
	var is_boss_wave := current_wave % 10 == 0

	if _state_machine.current_state == WaveStateMachine.State.INTERMISSION:
		if is_boss_wave:
			_state_machine.boss_incoming_duration = 3.0
			_state_machine.transition_to(WaveStateMachine.State.BOSS_INCOMING)
		else:
			_state_machine.countdown_duration = 3.0
			_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


# =============================================================================
# WAVE PROCESSING
# =============================================================================

## Process intermission countdown
func _process_intermission(_delta: float) -> void:
	intermission_timer = _state_machine.get_remaining_time()

	# Emit signal for UI updates
	wave_intermission.emit(intermission_timer)
	EventBus.wave_intermission.emit(current_wave, intermission_timer)

	# Check if timed state is complete
	if _state_machine.is_timed_state_completed():
		_begin_wave()


## Process countdown before wave starts
func _process_countdown(_delta: float) -> void:
	if _state_machine.is_timed_state_completed():
		# Transition to spawning
		_state_machine.transition_to(WaveStateMachine.State.SPAWNING)

		# Generate and prepare enemy list for this wave
		var enemy_list = WaveGenerator.generate_wave(current_wave)
		_spawner.prepare_wave(current_wave, enemy_list)

		total_enemies_this_wave = _spawner.get_queue_size()
		enemies_alive = total_enemies_this_wave
		enemies_killed_this_wave = 0

		# Emit signals
		wave_started.emit(current_wave, total_enemies_this_wave)
		EventBus.wave_started.emit(current_wave, total_enemies_this_wave)


## Process boss incoming announcement
func _process_boss_incoming(_delta: float) -> void:
	if _state_machine.is_timed_state_completed():
		_state_machine.countdown_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


## Process active wave (spawning enemies)
func _process_spawning(delta: float) -> void:
	if _spawner:
		_spawner.process_spawning(delta)


# =============================================================================
# WAVE COMPLETION
# =============================================================================

## Check if the wave is complete
func _check_wave_complete() -> void:
	var current := _state_machine.current_state
	if current != WaveStateMachine.State.SPAWNING and current != WaveStateMachine.State.IN_PROGRESS:
		return

	# Wave is complete when no enemies left to spawn and no enemies alive
	var no_enemies_to_spawn = not _spawner or not _spawner.has_enemies_to_spawn()
	if enemies_alive <= 0 and no_enemies_to_spawn:
		_complete_wave()


## Complete the current wave
func _complete_wave() -> void:
	# Calculate and award reward
	var reward = GameConfig.calculate_wave_reward(current_wave, enemies_killed_this_wave)
	GameManager.add_digibytes(reward)

	# Emit signals
	wave_completed.emit(current_wave, reward)
	EventBus.wave_completed.emit(current_wave, reward)

	# Check if all main waves completed (victory)
	if current_wave >= GameConfig.MAIN_GAME_WAVES and not is_endless_mode:
		_state_machine.transition_to(WaveStateMachine.State.VICTORY)
		all_waves_completed.emit()
		return

	# Start next wave
	_start_next_wave()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

## Handle spawner enemy spawned signal
func _on_spawner_enemy_spawned(enemy: Node, is_boss: bool) -> void:
	# Connect enemy signals
	_spawner.connect_enemy_signals(enemy, _on_enemy_died, _on_enemy_escaped_direct)

	# Emit appropriate signal
	if is_boss:
		boss_spawned.emit(enemy)
		EventBus.boss_spawned.emit(enemy, current_wave, "Boss")
	else:
		enemy_spawned.emit(enemy)

	EventBus.enemy_spawned.emit(enemy, current_wave, is_boss)


## Handle spawn queue empty signal
func _on_spawn_queue_empty() -> void:
	if _state_machine.current_state == WaveStateMachine.State.SPAWNING:
		_state_machine.transition_to(WaveStateMachine.State.IN_PROGRESS)


## Handle enemy death from EventBus
func _on_enemy_killed(_enemy: Node, _killer: Node, _reward: int) -> void:
	enemies_alive -= 1
	enemies_killed_this_wave += 1
	_check_wave_complete()


## Handle enemy escape from EventBus
func _on_enemy_escaped(_enemy: Node, _is_boss: bool) -> void:
	enemies_alive -= 1
	_check_wave_complete()


## Handle enemy death directly from enemy signal
func _on_enemy_died(enemy: EnemyDigimon, killer: Node, reward: int) -> void:
	GameManager.add_digibytes(reward)
	EventBus.enemy_killed.emit(enemy, killer, reward)


## Handle enemy escape directly from enemy signal
func _on_enemy_escaped_direct(_enemy: EnemyDigimon, _is_boss: bool) -> void:
	pass


## Handle player requesting early wave start
func _on_wave_start_requested() -> void:
	if _state_machine.current_state == WaveStateMachine.State.INTERMISSION:
		skip_intermission()
		wave_started_early.emit()


## Handle state machine state changes
func _on_state_machine_state_changed(old_state: WaveStateMachine.State, new_state: WaveStateMachine.State) -> void:
	state_changed.emit(old_state, new_state)

	if OS.is_debug_build():
		print("WaveManager: State changed from %s to %s" % [
			_state_machine.get_state_name(old_state),
			_state_machine.get_state_name(new_state)
		])


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Disconnect from state machine signals
	if _state_machine and _state_machine.state_changed.is_connected(_on_state_machine_state_changed):
		_state_machine.state_changed.disconnect(_on_state_machine_state_changed)

	# Disconnect from spawner signals
	if _spawner:
		if _spawner.enemy_spawned.is_connected(_on_spawner_enemy_spawned):
			_spawner.enemy_spawned.disconnect(_on_spawner_enemy_spawned)
		if _spawner.spawn_queue_empty.is_connected(_on_spawn_queue_empty):
			_spawner.spawn_queue_empty.disconnect(_on_spawn_queue_empty)
		# Cleanup enemy signals through spawner
		_spawner.cleanup_enemy_signals(_on_enemy_died, _on_enemy_escaped_direct)

	# Disconnect from EventBus signals
	if EventBus:
		if EventBus.enemy_killed.is_connected(_on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)
		if EventBus.enemy_escaped.is_connected(_on_enemy_escaped):
			EventBus.enemy_escaped.disconnect(_on_enemy_escaped)
		if EventBus.wave_start_requested.is_connected(_on_wave_start_requested):
			EventBus.wave_start_requested.disconnect(_on_wave_start_requested)

	# Clear references
	_state_machine = null
	_spawner = null
