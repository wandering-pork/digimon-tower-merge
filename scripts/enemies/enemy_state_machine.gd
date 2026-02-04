## State machine for enemy Digimon behavior.
##
## Manages enemy states and transitions, replacing boolean flags with a proper
## state machine pattern. Add as a child node to EnemyDigimon.
##
## Usage:
##   var state_machine = $EnemyStateMachine
##   state_machine.transition_to(EnemyStateMachine.State.STUNNED, 2.0)
##   if state_machine.current_state == EnemyStateMachine.State.MOVING:
##       # Handle moving logic
class_name EnemyStateMachine
extends Node

## Emitted when the state changes.
signal state_changed(old_state: State, new_state: State)

## Emitted when a timed state expires.
signal state_expired(state: State)

## All possible enemy states.
enum State {
	IDLE,      ## Initial state, waiting to be activated
	MOVING,    ## Normal movement along the path
	STUNNED,   ## Cannot move, taking damage
	SLOWED,    ## Reduced movement speed
	FEARED,    ## Moving backwards/erratically
	DYING,     ## Playing death animation
	DEAD       ## Final state, ready for cleanup
}

## The current active state.
var current_state: State = State.IDLE

## The previous state before the last transition.
var previous_state: State = State.IDLE

## Time remaining for timed states (STUNNED, SLOWED, FEARED).
var state_duration: float = 0.0

## Maximum duration for the current timed state.
var state_max_duration: float = 0.0

## Modifier value for states that need it (e.g., slow percentage).
var state_modifier: float = 1.0

## Valid state transitions. Key = from state, Value = array of valid to states.
var _valid_transitions: Dictionary = {
	State.IDLE: [State.MOVING, State.DYING, State.DEAD],
	State.MOVING: [State.STUNNED, State.SLOWED, State.FEARED, State.DYING, State.DEAD],
	State.STUNNED: [State.MOVING, State.SLOWED, State.FEARED, State.DYING, State.DEAD],
	State.SLOWED: [State.MOVING, State.STUNNED, State.FEARED, State.DYING, State.DEAD],
	State.FEARED: [State.MOVING, State.STUNNED, State.SLOWED, State.DYING, State.DEAD],
	State.DYING: [State.DEAD],
	State.DEAD: []  # Terminal state, no transitions out
}

## States that have a duration and auto-expire.
var _timed_states: Array[State] = [State.STUNNED, State.SLOWED, State.FEARED]


func _ready() -> void:
	set_process(false)  # Only process when in a timed state


func _process(delta: float) -> void:
	if state_duration > 0.0:
		state_duration -= delta
		if state_duration <= 0.0:
			_on_state_timer_expired()


## Attempts to transition to a new state.
## Returns true if the transition was successful.
## [param new_state]: The state to transition to.
## [param duration]: Optional duration for timed states (default: 0.0 = infinite).
## [param modifier]: Optional modifier value for states like SLOWED (default: 1.0).
func transition_to(new_state: State, duration: float = 0.0, modifier: float = 1.0) -> bool:
	if not can_transition_to(new_state):
		ErrorHandler.log_warning("EnemyStateMachine", "Invalid transition from %s to %s" % [
			State.keys()[current_state],
			State.keys()[new_state]
		])
		return false

	var old_state := current_state

	# Exit current state
	_exit_state(current_state)

	# Update state tracking
	previous_state = current_state
	current_state = new_state

	# Set up duration tracking for timed states
	if new_state in _timed_states and duration > 0.0:
		state_duration = duration
		state_max_duration = duration
		state_modifier = modifier
		set_process(true)
	else:
		state_duration = 0.0
		state_max_duration = 0.0
		state_modifier = modifier
		set_process(false)

	# Enter new state
	_enter_state(new_state)

	# Emit signal
	state_changed.emit(old_state, new_state)

	return true


## Checks if a transition to the given state is valid from the current state.
## [param target_state]: The state to check.
## Returns true if the transition is allowed.
func can_transition_to(target_state: State) -> bool:
	# Cannot transition to the same state
	if target_state == current_state:
		return false

	# Check valid transitions dictionary
	if current_state in _valid_transitions:
		return target_state in _valid_transitions[current_state]

	return false


## Returns true if the enemy is in a state that prevents movement.
func is_movement_blocked() -> bool:
	return current_state in [State.IDLE, State.STUNNED, State.DYING, State.DEAD]


## Returns true if the enemy is in a state that allows taking damage.
func can_take_damage() -> bool:
	return current_state not in [State.DYING, State.DEAD]


## Returns true if the enemy is considered alive.
func is_alive() -> bool:
	return current_state not in [State.DYING, State.DEAD]


## Returns true if the enemy is in a timed state.
func is_in_timed_state() -> bool:
	return current_state in _timed_states and state_duration > 0.0


## Returns the remaining duration of the current timed state.
func get_remaining_duration() -> float:
	return max(0.0, state_duration)


## Returns the progress of the current timed state (0.0 to 1.0).
func get_state_progress() -> float:
	if state_max_duration <= 0.0:
		return 0.0
	return 1.0 - (state_duration / state_max_duration)


## Returns the name of the given state as a string.
func get_state_name(state: State) -> String:
	return State.keys()[state]


## Returns the name of the current state as a string.
func get_current_state_name() -> String:
	return get_state_name(current_state)


## Forces the state machine to a specific state, bypassing validation.
## Use with caution - primarily for initialization or debugging.
## [param state]: The state to force.
func force_state(state: State) -> void:
	var old_state := current_state
	_exit_state(current_state)
	previous_state = current_state
	current_state = state
	state_duration = 0.0
	state_max_duration = 0.0
	set_process(false)
	_enter_state(state)
	state_changed.emit(old_state, state)


## Resets the state machine to IDLE state.
func reset() -> void:
	_exit_state(current_state)
	previous_state = State.IDLE
	current_state = State.IDLE
	state_duration = 0.0
	state_max_duration = 0.0
	state_modifier = 1.0
	set_process(false)


## Called when entering a new state. Override in subclass for custom behavior.
## [param state]: The state being entered.
func _enter_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.MOVING:
			pass
		State.STUNNED:
			pass
		State.SLOWED:
			pass
		State.FEARED:
			pass
		State.DYING:
			pass
		State.DEAD:
			set_process(false)


## Called when exiting a state. Override in subclass for custom behavior.
## [param state]: The state being exited.
func _exit_state(state: State) -> void:
	match state:
		State.IDLE:
			pass
		State.MOVING:
			pass
		State.STUNNED:
			pass
		State.SLOWED:
			state_modifier = 1.0  # Reset speed modifier
		State.FEARED:
			pass
		State.DYING:
			pass
		State.DEAD:
			pass


## Called when a timed state's duration expires.
func _on_state_timer_expired() -> void:
	var expired_state := current_state
	state_expired.emit(expired_state)

	# Auto-transition back to MOVING when timed state expires
	if current_state in _timed_states:
		if can_transition_to(State.MOVING):
			transition_to(State.MOVING)


func _exit_tree() -> void:
	# Stop processing
	set_process(false)

	# Clear collections
	_valid_transitions.clear()
	_timed_states.clear()
