## State machine for managing wave flow states.
##
## Provides a structured approach to wave management with proper state transitions,
## enter/exit callbacks, and duration tracking for timed states.
## Used by WaveManager to replace boolean flag approach.
class_name WaveStateMachine
extends Node

## Emitted when the state changes.
signal state_changed(old_state: State, new_state: State)

## All possible wave states.
enum State {
	IDLE,           ## No wave active, waiting to start
	COUNTDOWN,      ## Pre-wave countdown
	SPAWNING,       ## Actively spawning enemies
	IN_PROGRESS,    ## All enemies spawned, waiting for clear
	INTERMISSION,   ## Between waves, player prep time
	BOSS_INCOMING,  ## Special state before boss waves
	VICTORY,        ## All waves completed
	DEFEAT,         ## Player lost all lives
}

## The current active state.
var current_state: State = State.IDLE

## The previous state before the last transition.
var previous_state: State = State.IDLE

## Time elapsed in the current state (seconds).
var _state_elapsed_time: float = 0.0

## Duration settings for timed states (in seconds).
var countdown_duration: float = 3.0
var intermission_duration: float = 5.0
var boss_incoming_duration: float = 3.0

## Whether the current timed state has completed its duration.
var _timed_state_completed: bool = false

## State name lookup for UI display.
const STATE_NAMES: Dictionary = {
	State.IDLE: "Idle",
	State.COUNTDOWN: "Countdown",
	State.SPAWNING: "Spawning",
	State.IN_PROGRESS: "In Progress",
	State.INTERMISSION: "Intermission",
	State.BOSS_INCOMING: "Boss Incoming",
	State.VICTORY: "Victory",
	State.DEFEAT: "Defeat",
}

## Valid state transitions - defines which states can transition to which other states.
## DEFEAT can be reached from any non-terminal state (handled separately in _is_valid_transition).
const VALID_TRANSITIONS: Dictionary = {
	State.IDLE: [State.COUNTDOWN, State.BOSS_INCOMING],
	State.COUNTDOWN: [State.SPAWNING],
	State.SPAWNING: [State.IN_PROGRESS],
	State.IN_PROGRESS: [State.INTERMISSION, State.VICTORY, State.DEFEAT],
	State.INTERMISSION: [State.COUNTDOWN, State.BOSS_INCOMING, State.VICTORY],
	State.BOSS_INCOMING: [State.SPAWNING],
	State.VICTORY: [State.IDLE],
	State.DEFEAT: [State.IDLE]
}


func _ready() -> void:
	set_process(true)


func _process(delta: float) -> void:
	_state_elapsed_time += delta
	_update_timed_state()


## Transitions to a new state if the transition is valid.
## Returns true if the transition was successful, false otherwise.
func transition_to(new_state: State) -> bool:
	if new_state == current_state:
		return false

	if not _is_valid_transition(current_state, new_state):
		ErrorHandler.log_warning("WaveStateMachine", "Invalid transition from %s to %s" % [
			get_state_name(current_state),
			get_state_name(new_state)
		])
		return false

	var old_state := current_state

	_exit_state(current_state)

	previous_state = current_state
	current_state = new_state
	_state_elapsed_time = 0.0
	_timed_state_completed = false

	_enter_state(new_state)

	state_changed.emit(old_state, new_state)

	return true


## Called when entering a new state. Override in subclass for custom behavior.
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.COUNTDOWN:
			pass
		State.SPAWNING:
			pass
		State.IN_PROGRESS:
			pass
		State.INTERMISSION:
			pass
		State.BOSS_INCOMING:
			pass
		State.VICTORY:
			pass
		State.DEFEAT:
			pass


## Called when exiting a state. Override in subclass for custom behavior.
func _exit_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.COUNTDOWN:
			pass
		State.SPAWNING:
			pass
		State.IN_PROGRESS:
			pass
		State.INTERMISSION:
			pass
		State.BOSS_INCOMING:
			pass
		State.VICTORY:
			pass
		State.DEFEAT:
			pass


## Updates timed states and marks them as completed when duration is reached.
func _update_timed_state() -> void:
	if _timed_state_completed:
		return

	var duration := get_state_duration(current_state)
	if duration > 0.0 and _state_elapsed_time >= duration:
		_timed_state_completed = true


## Validates if a transition from one state to another is allowed.
func _is_valid_transition(from_state: State, to_state: State) -> bool:
	# DEFEAT can be reached from any non-terminal state
	if to_state == State.DEFEAT:
		return from_state != State.DEFEAT and from_state != State.VICTORY

	# Check if transition is in the valid transitions dictionary
	if not VALID_TRANSITIONS.has(from_state):
		return false

	return to_state in VALID_TRANSITIONS[from_state]


## Returns the human-readable name for a state.
func get_state_name(state: State = current_state) -> String:
	if STATE_NAMES.has(state):
		return STATE_NAMES[state]
	return "Unknown"


## Returns the configured duration for timed states, or 0.0 for non-timed states.
func get_state_duration(state: State = current_state) -> float:
	match state:
		State.COUNTDOWN:
			return countdown_duration
		State.INTERMISSION:
			return intermission_duration
		State.BOSS_INCOMING:
			return boss_incoming_duration
		_:
			return 0.0


## Returns the time elapsed in the current state.
func get_elapsed_time() -> float:
	return _state_elapsed_time


## Returns the time remaining for timed states, or 0.0 for non-timed states.
func get_remaining_time() -> float:
	var duration := get_state_duration(current_state)
	if duration <= 0.0:
		return 0.0
	return maxf(0.0, duration - _state_elapsed_time)


## Returns true if the current timed state has completed its duration.
func is_timed_state_completed() -> bool:
	return _timed_state_completed


## Returns true if the current state is a timed state.
func is_timed_state() -> bool:
	return get_state_duration(current_state) > 0.0


## Returns true if the state machine is in a terminal state (VICTORY or DEFEAT).
func is_terminal_state() -> bool:
	return current_state == State.VICTORY or current_state == State.DEFEAT


## Returns true if a wave is currently active (not IDLE, INTERMISSION, or terminal).
func is_wave_active() -> bool:
	return current_state in [State.COUNTDOWN, State.SPAWNING, State.IN_PROGRESS, State.BOSS_INCOMING]


## Resets the state machine to IDLE state.
func reset() -> void:
	_exit_state(current_state)
	previous_state = current_state
	current_state = State.IDLE
	_state_elapsed_time = 0.0
	_timed_state_completed = false
	_enter_state(State.IDLE)
	state_changed.emit(previous_state, State.IDLE)


## Forces a state change without validation. Use with caution.
func force_state(new_state: State) -> void:
	var old_state := current_state
	_exit_state(current_state)
	previous_state = current_state
	current_state = new_state
	_state_elapsed_time = 0.0
	_timed_state_completed = false
	_enter_state(new_state)
	state_changed.emit(old_state, new_state)
