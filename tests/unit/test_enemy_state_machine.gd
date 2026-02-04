extends GutTest
## Unit tests for EnemyStateMachine.
##
## Tests state transitions, queries, and state machine behavior for enemies.
## This tests the state machine in isolation without requiring the full game.

# =============================================================================
# PRELOADS
# =============================================================================

const EnemyStateMachineScript = preload("res://scripts/enemies/enemy_state_machine.gd")

# =============================================================================
# TEST VARIABLES
# =============================================================================

var _state_machine: Node = null


# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

func before_all() -> void:
	gut.p("Starting EnemyStateMachine unit tests")


func after_all() -> void:
	gut.p("Completed EnemyStateMachine unit tests")


func before_each() -> void:
	_state_machine = EnemyStateMachineScript.new()
	add_child(_state_machine)


func after_each() -> void:
	if _state_machine:
		_state_machine.queue_free()
		_state_machine = null


# =============================================================================
# INITIAL STATE TESTS
# =============================================================================

func test_initial_state_is_idle() -> void:
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.IDLE,
		"Initial state should be IDLE")


func test_previous_state_starts_idle() -> void:
	assert_eq(_state_machine.previous_state, EnemyStateMachineScript.State.IDLE,
		"Previous state should start as IDLE")


func test_state_duration_starts_at_zero() -> void:
	assert_eq(_state_machine.state_duration, 0.0,
		"State duration should start at 0")


func test_state_modifier_starts_at_one() -> void:
	assert_eq(_state_machine.state_modifier, 1.0,
		"State modifier should start at 1.0")


# =============================================================================
# VALID TRANSITION TESTS - FROM IDLE
# =============================================================================

func test_transition_idle_to_moving() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(result, "Should be able to transition from IDLE to MOVING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.MOVING,
		"State should now be MOVING")


func test_transition_idle_to_dying() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DYING)
	assert_true(result, "Should be able to transition from IDLE to DYING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DYING,
		"State should now be DYING")


func test_transition_idle_to_dead() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DEAD)
	assert_true(result, "Should be able to transition from IDLE to DEAD")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DEAD,
		"State should now be DEAD")


# =============================================================================
# VALID TRANSITION TESTS - FROM MOVING
# =============================================================================

func test_transition_moving_to_stunned() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_true(result, "Should be able to transition from MOVING to STUNNED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.STUNNED,
		"State should now be STUNNED")


func test_transition_moving_to_slowed() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 3.0, 0.5)
	assert_true(result, "Should be able to transition from MOVING to SLOWED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.SLOWED,
		"State should now be SLOWED")


func test_transition_moving_to_feared() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 1.5)
	assert_true(result, "Should be able to transition from MOVING to FEARED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.FEARED,
		"State should now be FEARED")


func test_transition_moving_to_dying() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DYING)
	assert_true(result, "Should be able to transition from MOVING to DYING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DYING,
		"State should now be DYING")


func test_transition_moving_to_dead() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DEAD)
	assert_true(result, "Should be able to transition from MOVING to DEAD")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DEAD,
		"State should now be DEAD")


# =============================================================================
# VALID TRANSITION TESTS - CC STATES
# =============================================================================

func test_transition_stunned_to_moving() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(result, "Should be able to transition from STUNNED to MOVING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.MOVING,
		"State should now be MOVING")


func test_transition_stunned_to_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 2.0, 0.7)
	assert_true(result, "Should be able to transition from STUNNED to SLOWED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.SLOWED,
		"State should now be SLOWED")


func test_transition_stunned_to_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 1.0)
	assert_true(result, "Should be able to transition from STUNNED to FEARED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.FEARED,
		"State should now be FEARED")


func test_transition_stunned_to_dying() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DYING)
	assert_true(result, "Should be able to transition from STUNNED to DYING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DYING,
		"State should now be DYING")


func test_transition_slowed_to_moving() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(result, "Should be able to transition from SLOWED to MOVING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.MOVING,
		"State should now be MOVING")


func test_transition_slowed_to_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_true(result, "Should be able to transition from SLOWED to STUNNED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.STUNNED,
		"State should now be STUNNED")


func test_transition_slowed_to_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 1.5)
	assert_true(result, "Should be able to transition from SLOWED to FEARED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.FEARED,
		"State should now be FEARED")


func test_transition_feared_to_moving() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(result, "Should be able to transition from FEARED to MOVING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.MOVING,
		"State should now be MOVING")


func test_transition_feared_to_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 1.0)
	assert_true(result, "Should be able to transition from FEARED to STUNNED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.STUNNED,
		"State should now be STUNNED")


func test_transition_feared_to_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 2.5, 0.6)
	assert_true(result, "Should be able to transition from FEARED to SLOWED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.SLOWED,
		"State should now be SLOWED")


# =============================================================================
# VALID TRANSITION TESTS - DEATH STATES
# =============================================================================

func test_transition_dying_to_dead() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.DEAD)
	assert_true(result, "Should be able to transition from DYING to DEAD")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DEAD,
		"State should now be DEAD")


# =============================================================================
# INVALID TRANSITION TESTS
# =============================================================================

func test_invalid_transition_idle_to_stunned() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_false(result, "Should NOT be able to transition directly from IDLE to STUNNED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.IDLE,
		"State should remain IDLE")


func test_invalid_transition_idle_to_slowed() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 2.0)
	assert_false(result, "Should NOT be able to transition directly from IDLE to SLOWED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.IDLE,
		"State should remain IDLE")


func test_invalid_transition_idle_to_feared() -> void:
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 2.0)
	assert_false(result, "Should NOT be able to transition directly from IDLE to FEARED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.IDLE,
		"State should remain IDLE")


func test_invalid_transition_dying_to_moving() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_false(result, "Should NOT be able to transition from DYING to MOVING")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DYING,
		"State should remain DYING")


func test_invalid_transition_dying_to_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.STUNNED)
	assert_false(result, "Should NOT be able to transition from DYING to STUNNED")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DYING,
		"State should remain DYING")


func test_invalid_transition_dead_is_terminal() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DEAD)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_false(result, "DEAD is terminal - should NOT be able to transition out")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DEAD,
		"State should remain DEAD")


func test_invalid_transition_dead_to_idle() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DEAD)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.IDLE)
	assert_false(result, "DEAD is terminal - should NOT be able to transition to IDLE")
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.DEAD,
		"State should remain DEAD")


func test_invalid_transition_same_state() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var result = _state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_false(result, "Should NOT be able to transition to the same state")


# =============================================================================
# IS_ALIVE TESTS
# =============================================================================

func test_is_alive_idle() -> void:
	assert_true(_state_machine.is_alive(),
		"Enemy should be alive in IDLE state")


func test_is_alive_moving() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(_state_machine.is_alive(),
		"Enemy should be alive in MOVING state")


func test_is_alive_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	assert_true(_state_machine.is_alive(),
		"Enemy should be alive in STUNNED state")


func test_is_alive_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	assert_true(_state_machine.is_alive(),
		"Enemy should be alive in SLOWED state")


func test_is_alive_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	assert_true(_state_machine.is_alive(),
		"Enemy should be alive in FEARED state")


func test_is_alive_dying() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	assert_false(_state_machine.is_alive(),
		"Enemy should NOT be alive in DYING state")


func test_is_alive_dead() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DEAD)
	assert_false(_state_machine.is_alive(),
		"Enemy should NOT be alive in DEAD state")


# =============================================================================
# IS_MOVEMENT_BLOCKED TESTS
# =============================================================================

func test_is_movement_blocked_idle() -> void:
	assert_true(_state_machine.is_movement_blocked(),
		"Movement should be blocked in IDLE state")


func test_is_movement_blocked_moving() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_false(_state_machine.is_movement_blocked(),
		"Movement should NOT be blocked in MOVING state")


func test_is_movement_blocked_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	assert_true(_state_machine.is_movement_blocked(),
		"Movement should be blocked in STUNNED state")


func test_is_movement_blocked_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	assert_false(_state_machine.is_movement_blocked(),
		"Movement should NOT be blocked in SLOWED state (just slower)")


func test_is_movement_blocked_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	assert_false(_state_machine.is_movement_blocked(),
		"Movement should NOT be blocked in FEARED state (moves backwards)")


func test_is_movement_blocked_dying() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	assert_true(_state_machine.is_movement_blocked(),
		"Movement should be blocked in DYING state")


func test_is_movement_blocked_dead() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DEAD)
	assert_true(_state_machine.is_movement_blocked(),
		"Movement should be blocked in DEAD state")


# =============================================================================
# CAN_TAKE_DAMAGE TESTS
# =============================================================================

func test_can_take_damage_idle() -> void:
	assert_true(_state_machine.can_take_damage(),
		"Enemy should be able to take damage in IDLE state")


func test_can_take_damage_moving() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_true(_state_machine.can_take_damage(),
		"Enemy should be able to take damage in MOVING state")


func test_can_take_damage_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	assert_true(_state_machine.can_take_damage(),
		"Enemy should be able to take damage in STUNNED state")


func test_can_take_damage_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	assert_true(_state_machine.can_take_damage(),
		"Enemy should be able to take damage in SLOWED state")


func test_can_take_damage_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.FEARED)
	assert_true(_state_machine.can_take_damage(),
		"Enemy should be able to take damage in FEARED state")


func test_can_take_damage_dying() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DYING)
	assert_false(_state_machine.can_take_damage(),
		"Enemy should NOT be able to take damage in DYING state")


func test_can_take_damage_dead() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.DEAD)
	assert_false(_state_machine.can_take_damage(),
		"Enemy should NOT be able to take damage in DEAD state")


# =============================================================================
# TIMED STATE TESTS
# =============================================================================

func test_stunned_sets_duration() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.5)
	assert_eq(_state_machine.state_duration, 2.5,
		"STUNNED should set state duration")
	assert_eq(_state_machine.state_max_duration, 2.5,
		"STUNNED should set max duration")


func test_slowed_sets_duration_and_modifier() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 3.0, 0.5)
	assert_eq(_state_machine.state_duration, 3.0,
		"SLOWED should set state duration")
	assert_eq(_state_machine.state_modifier, 0.5,
		"SLOWED should set state modifier (slow amount)")


func test_feared_sets_duration() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 1.5)
	assert_eq(_state_machine.state_duration, 1.5,
		"FEARED should set state duration")


func test_is_in_timed_state_stunned() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_true(_state_machine.is_in_timed_state(),
		"Should be in timed state when STUNNED with duration")


func test_is_in_timed_state_slowed() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 3.0, 0.7)
	assert_true(_state_machine.is_in_timed_state(),
		"Should be in timed state when SLOWED with duration")


func test_is_in_timed_state_feared() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.FEARED, 1.5)
	assert_true(_state_machine.is_in_timed_state(),
		"Should be in timed state when FEARED with duration")


func test_is_in_timed_state_moving() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_false(_state_machine.is_in_timed_state(),
		"Should NOT be in timed state when MOVING")


func test_is_in_timed_state_no_duration() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	# force_state doesn't set duration
	assert_false(_state_machine.is_in_timed_state(),
		"Should NOT be in timed state when no duration set")


func test_get_remaining_duration() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_eq(_state_machine.get_remaining_duration(), 2.0,
		"Remaining duration should equal initial duration")


func test_get_state_progress_initial() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	assert_eq(_state_machine.get_state_progress(), 0.0,
		"State progress should be 0 at start")


# =============================================================================
# STATE NAME TESTS
# =============================================================================

func test_get_state_name_idle() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.IDLE), "IDLE",
		"IDLE state name should be 'IDLE'")


func test_get_state_name_moving() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.MOVING), "MOVING",
		"MOVING state name should be 'MOVING'")


func test_get_state_name_stunned() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.STUNNED), "STUNNED",
		"STUNNED state name should be 'STUNNED'")


func test_get_state_name_slowed() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.SLOWED), "SLOWED",
		"SLOWED state name should be 'SLOWED'")


func test_get_state_name_feared() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.FEARED), "FEARED",
		"FEARED state name should be 'FEARED'")


func test_get_state_name_dying() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.DYING), "DYING",
		"DYING state name should be 'DYING'")


func test_get_state_name_dead() -> void:
	assert_eq(_state_machine.get_state_name(EnemyStateMachineScript.State.DEAD), "DEAD",
		"DEAD state name should be 'DEAD'")


func test_get_current_state_name() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_eq(_state_machine.get_current_state_name(), "MOVING",
		"get_current_state_name should return current state name")


# =============================================================================
# RESET TESTS
# =============================================================================

func test_reset_returns_to_idle() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.reset()
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.IDLE,
		"Reset should return to IDLE state")


func test_reset_clears_duration() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	_state_machine.reset()
	assert_eq(_state_machine.state_duration, 0.0,
		"Reset should clear state duration")


func test_reset_clears_modifier() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 2.0, 0.5)
	_state_machine.reset()
	assert_eq(_state_machine.state_modifier, 1.0,
		"Reset should restore state modifier to 1.0")


func test_reset_sets_previous_to_idle() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.reset()
	assert_eq(_state_machine.previous_state, EnemyStateMachineScript.State.IDLE,
		"Reset should set previous state to IDLE")


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func test_state_changed_signal_emitted() -> void:
	watch_signals(_state_machine)
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_signal_emitted(_state_machine, "state_changed",
		"state_changed signal should be emitted on transition")


func test_state_changed_signal_parameters() -> void:
	watch_signals(_state_machine)
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	var signal_params = get_signal_parameters(_state_machine, "state_changed")
	assert_eq(signal_params[0], EnemyStateMachineScript.State.IDLE,
		"First parameter should be old state (IDLE)")
	assert_eq(signal_params[1], EnemyStateMachineScript.State.MOVING,
		"Second parameter should be new state (MOVING)")


func test_previous_state_updated_after_transition() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_eq(_state_machine.previous_state, EnemyStateMachineScript.State.IDLE,
		"Previous state should be updated to IDLE after transition")


func test_previous_state_chain() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 1.0)
	assert_eq(_state_machine.previous_state, EnemyStateMachineScript.State.MOVING,
		"Previous state should track the last state")


# =============================================================================
# FORCE STATE TESTS
# =============================================================================

func test_force_state_bypasses_validation() -> void:
	# This transition would normally be invalid (IDLE -> STUNNED)
	_state_machine.force_state(EnemyStateMachineScript.State.STUNNED)
	assert_eq(_state_machine.current_state, EnemyStateMachineScript.State.STUNNED,
		"force_state should bypass validation and set state directly")


func test_force_state_emits_signal() -> void:
	watch_signals(_state_machine)
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	assert_signal_emitted(_state_machine, "state_changed",
		"force_state should emit state_changed signal")


func test_force_state_clears_duration() -> void:
	_state_machine.force_state(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.STUNNED, 2.0)
	_state_machine.force_state(EnemyStateMachineScript.State.SLOWED)
	assert_eq(_state_machine.state_duration, 0.0,
		"force_state should clear duration")


# =============================================================================
# CAN_TRANSITION_TO TESTS
# =============================================================================

func test_can_transition_to_returns_true_for_valid() -> void:
	assert_true(_state_machine.can_transition_to(EnemyStateMachineScript.State.MOVING),
		"can_transition_to should return true for valid transition")


func test_can_transition_to_returns_false_for_invalid() -> void:
	assert_false(_state_machine.can_transition_to(EnemyStateMachineScript.State.STUNNED),
		"can_transition_to should return false for invalid transition")


func test_can_transition_to_returns_false_for_same_state() -> void:
	assert_false(_state_machine.can_transition_to(EnemyStateMachineScript.State.IDLE),
		"can_transition_to should return false for same state")


# =============================================================================
# SLOWED STATE MODIFIER RESET TEST
# =============================================================================

func test_slowed_modifier_resets_on_exit() -> void:
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	_state_machine.transition_to(EnemyStateMachineScript.State.SLOWED, 2.0, 0.5)
	assert_eq(_state_machine.state_modifier, 0.5, "Modifier should be 0.5 while slowed")
	_state_machine.transition_to(EnemyStateMachineScript.State.MOVING)
	assert_eq(_state_machine.state_modifier, 1.0,
		"Modifier should reset to 1.0 when exiting SLOWED state")
