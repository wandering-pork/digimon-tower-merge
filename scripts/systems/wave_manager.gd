extends Node
## WaveManager Autoload Singleton
##
## Manages wave progression, state orchestration, and wave rewards.
## Uses WaveStateMachine for state management and WaveSpawner for enemy instantiation.

const WaveStateMachine = preload("res://scripts/systems/wave_state_machine.gd")
const WaveSpawner = preload("res://scripts/systems/wave_spawner.gd")
const WaveGenerator = preload("res://scripts/systems/wave_generator.gd")
const WaveRewardCalculator = preload("res://scripts/systems/wave_reward_calculator.gd")
const EnemyDigimon = preload("res://scripts/enemies/enemy_digimon.gd")

# Signals
signal wave_started(wave_number: int, enemy_count: int)
signal wave_completed(wave_number: int, reward: int)
signal wave_intermission(time_remaining: float)
signal enemy_spawned(enemy: Node)
signal boss_spawned(boss: Node)
signal all_waves_completed()
signal wave_started_early()
signal state_changed(old_state: WaveStateMachine.State, new_state: WaveStateMachine.State)

# Components
var _state_machine: WaveStateMachine = null
var _spawner: WaveSpawner = null

# State
var current_wave: int = 0
var enemies_alive: int = 0
var total_enemies_this_wave: int = 0
var enemies_killed_this_wave: int = 0
var intermission_timer: float = 0.0
var is_endless_mode: bool = false


func _ready() -> void:
	_state_machine = WaveStateMachine.new()
	_state_machine.name = "WaveStateMachine"
	add_child(_state_machine)

	_spawner = WaveSpawner.new()
	_spawner.name = "WaveSpawner"
	add_child(_spawner)

	_state_machine.state_changed.connect(_on_state_machine_state_changed)
	_spawner.enemy_spawned.connect(_on_spawner_enemy_spawned)
	_spawner.spawn_queue_empty.connect(_on_spawn_queue_empty)

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
		WaveStateMachine.State.BOSS_INCOMING:
			_process_boss_incoming(delta)


# =============================================================================
# PUBLIC API
# =============================================================================

func setup(enemy_container: Node, grid_manager: Node) -> void:
	if _spawner:
		_spawner.setup(enemy_container, grid_manager)


func start_game() -> void:
	current_wave = 0
	is_endless_mode = false
	_start_first_wave()


func skip_intermission() -> void:
	if _state_machine.current_state == WaveStateMachine.State.INTERMISSION:
		intermission_timer = 0.0
		_begin_wave()


func pause() -> void:
	set_process(false)


func resume() -> void:
	set_process(true)


func get_state_string() -> String:
	return _state_machine.get_state_name() if _state_machine else "NO_STATE_MACHINE"


func get_current_state() -> WaveStateMachine.State:
	return _state_machine.current_state if _state_machine else WaveStateMachine.State.IDLE


func is_wave_active() -> bool:
	return _state_machine.is_wave_active() if _state_machine else false


func trigger_defeat() -> void:
	if _state_machine and not _state_machine.is_terminal_state():
		_state_machine.transition_to(WaveStateMachine.State.DEFEAT)


func is_game_over() -> bool:
	return _state_machine.is_terminal_state() if _state_machine else false


func get_remaining_time() -> float:
	return _state_machine.get_remaining_time() if _state_machine else 0.0


func reset() -> void:
	current_wave = 0
	enemies_alive = 0
	total_enemies_this_wave = 0
	enemies_killed_this_wave = 0
	intermission_timer = 0.0
	is_endless_mode = false

	if _state_machine:
		_state_machine.reset()
	if _spawner:
		_spawner.clear_queue()


# =============================================================================
# WAVE FLOW CONTROL
# =============================================================================

func _start_first_wave() -> void:
	current_wave = 1
	is_endless_mode = false
	GameManager.current_wave = current_wave

	var is_boss_wave := current_wave % 10 == 0
	if is_boss_wave:
		_state_machine.boss_incoming_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.BOSS_INCOMING)
	else:
		_state_machine.countdown_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


func _start_next_wave() -> void:
	current_wave += 1
	is_endless_mode = current_wave > GameConfig.MAIN_GAME_WAVES
	GameManager.current_wave = current_wave

	_state_machine.intermission_duration = GameConfig.get_intermission_time(current_wave)
	intermission_timer = _state_machine.intermission_duration
	_state_machine.transition_to(WaveStateMachine.State.INTERMISSION)
	EventBus.wave_intermission.emit(current_wave, intermission_timer)


func _begin_wave() -> void:
	if _state_machine.current_state != WaveStateMachine.State.INTERMISSION:
		return

	var is_boss_wave := current_wave % 10 == 0
	if is_boss_wave:
		_state_machine.boss_incoming_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.BOSS_INCOMING)
	else:
		_state_machine.countdown_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


# =============================================================================
# WAVE PROCESSING
# =============================================================================

func _process_intermission(_delta: float) -> void:
	intermission_timer = _state_machine.get_remaining_time()
	wave_intermission.emit(intermission_timer)
	EventBus.wave_intermission.emit(current_wave, intermission_timer)

	if _state_machine.is_timed_state_completed():
		_begin_wave()


func _process_countdown(_delta: float) -> void:
	if not _state_machine.is_timed_state_completed():
		return

	_state_machine.transition_to(WaveStateMachine.State.SPAWNING)

	var enemy_list = WaveGenerator.generate_wave(current_wave)
	_spawner.prepare_wave(current_wave, enemy_list)

	total_enemies_this_wave = _spawner.get_queue_size()
	enemies_alive = total_enemies_this_wave
	enemies_killed_this_wave = 0

	# Play wave start sound
	AudioManager.play_sfx("wave_start")

	wave_started.emit(current_wave, total_enemies_this_wave)
	EventBus.wave_started.emit(current_wave, total_enemies_this_wave)


func _process_boss_incoming(_delta: float) -> void:
	if _state_machine.is_timed_state_completed():
		_state_machine.countdown_duration = 3.0
		_state_machine.transition_to(WaveStateMachine.State.COUNTDOWN)


func _process_spawning(delta: float) -> void:
	if _spawner:
		_spawner.process_spawning(delta)


# =============================================================================
# WAVE COMPLETION
# =============================================================================

func _check_wave_complete() -> void:
	var current := _state_machine.current_state
	if current != WaveStateMachine.State.SPAWNING and current != WaveStateMachine.State.IN_PROGRESS:
		return

	var no_enemies_to_spawn = not _spawner or not _spawner.has_enemies_to_spawn()
	if enemies_alive <= 0 and no_enemies_to_spawn:
		_complete_wave()


func _complete_wave() -> void:
	var reward = WaveRewardCalculator.calculate_wave_reward(current_wave, enemies_killed_this_wave)
	GameManager.add_digibytes(reward)

	# Play wave complete sound
	AudioManager.play_sfx("wave_complete")

	wave_completed.emit(current_wave, reward)
	EventBus.wave_completed.emit(current_wave, reward)

	if current_wave >= GameConfig.MAIN_GAME_WAVES and not is_endless_mode:
		# Play victory sound
		AudioManager.play_sfx("victory")
		_state_machine.transition_to(WaveStateMachine.State.VICTORY)
		all_waves_completed.emit()
		return

	_start_next_wave()


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_spawner_enemy_spawned(enemy: Node, is_boss: bool) -> void:
	_spawner.connect_enemy_signals(enemy, _on_enemy_died, _on_enemy_escaped_direct)

	if is_boss:
		# Play boss spawn sound
		AudioManager.play_sfx("boss_spawn")
		boss_spawned.emit(enemy)
		EventBus.boss_spawned.emit(enemy, current_wave, "Boss")
	else:
		enemy_spawned.emit(enemy)

	EventBus.enemy_spawned.emit(enemy, current_wave, is_boss)


func _on_spawn_queue_empty() -> void:
	if _state_machine.current_state == WaveStateMachine.State.SPAWNING:
		_state_machine.transition_to(WaveStateMachine.State.IN_PROGRESS)


func _on_enemy_killed(_enemy: Node, _killer: Node, _reward: int) -> void:
	enemies_alive -= 1
	enemies_killed_this_wave += 1
	_check_wave_complete()


func _on_enemy_escaped(_enemy: Node, _is_boss: bool) -> void:
	enemies_alive -= 1
	_check_wave_complete()


func _on_enemy_died(enemy: EnemyDigimon, killer: Node, reward: int) -> void:
	GameManager.add_digibytes(reward)
	EventBus.enemy_killed.emit(enemy, killer, reward)


func _on_enemy_escaped_direct(_enemy: EnemyDigimon, _is_boss: bool) -> void:
	pass


func _on_wave_start_requested() -> void:
	if _state_machine.current_state == WaveStateMachine.State.INTERMISSION:
		skip_intermission()
		wave_started_early.emit()


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
	if _state_machine and _state_machine.state_changed.is_connected(_on_state_machine_state_changed):
		_state_machine.state_changed.disconnect(_on_state_machine_state_changed)

	if _spawner:
		if _spawner.enemy_spawned.is_connected(_on_spawner_enemy_spawned):
			_spawner.enemy_spawned.disconnect(_on_spawner_enemy_spawned)
		if _spawner.spawn_queue_empty.is_connected(_on_spawn_queue_empty):
			_spawner.spawn_queue_empty.disconnect(_on_spawn_queue_empty)
		_spawner.cleanup_enemy_signals(_on_enemy_died, _on_enemy_escaped_direct)

	if EventBus:
		if EventBus.enemy_killed.is_connected(_on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)
		if EventBus.enemy_escaped.is_connected(_on_enemy_escaped):
			EventBus.enemy_escaped.disconnect(_on_enemy_escaped)
		if EventBus.wave_start_requested.is_connected(_on_wave_start_requested):
			EventBus.wave_start_requested.disconnect(_on_wave_start_requested)

	_state_machine = null
	_spawner = null
