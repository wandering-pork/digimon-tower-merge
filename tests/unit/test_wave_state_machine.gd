extends GutTest
## Unit tests for WaveStateMachine.
##
## Tests state transitions, queries, and state machine behavior.
## This tests the state machine in isolation without requiring the full game.

# =============================================================================
# PRELOADS
# =============================================================================

const WaveStateMachineScript = preload("res://scripts/systems/wave_state_machine.gd")

# =============================================================================
# TEST VARIABLES
# =============================================================================

var _state_machine: Node = null


# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

func before_all() -> void:
	gut.p("Starting WaveStateMachine unit tests")


func after_all() -> void:
	gut.p("Completed WaveStateMachine unit tests")


func before_each() -> void:
	_state_machine = WaveStateMachineScript.new()
	add_child(_state_machine)


func after_each() -> void:
	if _state_machine:
		_state_machine.queue_free()
		_state_machine = null


# =============================================================================
# INITIAL STATE TESTS
# =============================================================================

func test_initial_state_is_idle() -> void:
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"Initial state should be IDLE")


func test_previous_state_starts_idle() -> void:
	assert_eq(_state_machine.previous_state, WaveStateMachineScript.State.IDLE,
		"Previous state should start as IDLE")


func test_elapsed_time_starts_at_zero() -> void:
	assert_eq(_state_machine.get_elapsed_time(), 0.0,
		"Elapsed time should start at 0")


# =============================================================================
# VALID TRANSITION TESTS
# =============================================================================

func test_transition_idle_to_countdown() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_true(result, "Should be able to transition from IDLE to COUNTDOWN")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.COUNTDOWN,
		"State should now be COUNTDOWN")


func test_transition_idle_to_boss_incoming() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_true(result, "Should be able to transition from IDLE to BOSS_INCOMING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.BOSS_INCOMING,
		"State should now be BOSS_INCOMING")


func test_transition_countdown_to_spawning() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.SPAWNING)
	assert_true(result, "Should be able to transition from COUNTDOWN to SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.SPAWNING,
		"State should now be SPAWNING")


func test_transition_spawning_to_in_progress() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.IN_PROGRESS)
	assert_true(result, "Should be able to transition from SPAWNING to IN_PROGRESS")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IN_PROGRESS,
		"State should now be IN_PROGRESS")


func test_transition_in_progress_to_intermission() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.INTERMISSION)
	assert_true(result, "Should be able to transition from IN_PROGRESS to INTERMISSION")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.INTERMISSION,
		"State should now be INTERMISSION")


func test_transition_in_progress_to_victory() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.VICTORY)
	assert_true(result, "Should be able to transition from IN_PROGRESS to VICTORY")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.VICTORY,
		"State should now be VICTORY")


func test_transition_in_progress_to_defeat() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_true(result, "Should be able to transition from IN_PROGRESS to DEFEAT")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should now be DEFEAT")


func test_transition_intermission_to_countdown() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_true(result, "Should be able to transition from INTERMISSION to COUNTDOWN")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.COUNTDOWN,
		"State should now be COUNTDOWN")


func test_transition_intermission_to_boss_incoming() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_true(result, "Should be able to transition from INTERMISSION to BOSS_INCOMING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.BOSS_INCOMING,
		"State should now be BOSS_INCOMING")


func test_transition_intermission_to_victory() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.VICTORY)
	assert_true(result, "Should be able to transition from INTERMISSION to VICTORY")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.VICTORY,
		"State should now be VICTORY")


func test_transition_boss_incoming_to_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.BOSS_INCOMING)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.SPAWNING)
	assert_true(result, "Should be able to transition from BOSS_INCOMING to SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.SPAWNING,
		"State should now be SPAWNING")


func test_transition_victory_to_idle() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.VICTORY)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.IDLE)
	assert_true(result, "Should be able to transition from VICTORY to IDLE")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"State should now be IDLE")


func test_transition_defeat_to_idle() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.DEFEAT)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.IDLE)
	assert_true(result, "Should be able to transition from DEFEAT to IDLE")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"State should now be IDLE")


# =============================================================================
# INVALID TRANSITION TESTS
# =============================================================================

func test_invalid_transition_idle_to_spawning() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.SPAWNING)
	assert_false(result, "Should NOT be able to transition directly from IDLE to SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"State should remain IDLE")


func test_invalid_transition_idle_to_in_progress() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.IN_PROGRESS)
	assert_false(result, "Should NOT be able to transition directly from IDLE to IN_PROGRESS")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"State should remain IDLE")


func test_invalid_transition_countdown_to_intermission() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.INTERMISSION)
	assert_false(result, "Should NOT be able to transition from COUNTDOWN to INTERMISSION")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.COUNTDOWN,
		"State should remain COUNTDOWN")


func test_invalid_transition_spawning_to_countdown() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_false(result, "Should NOT be able to transition from SPAWNING to COUNTDOWN")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.SPAWNING,
		"State should remain SPAWNING")


func test_invalid_transition_victory_to_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.VICTORY)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.SPAWNING)
	assert_false(result, "Should NOT be able to transition from VICTORY to SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.VICTORY,
		"State should remain VICTORY")


func test_invalid_transition_defeat_to_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.DEFEAT)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.SPAWNING)
	assert_false(result, "Should NOT be able to transition from DEFEAT to SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should remain DEFEAT")


func test_invalid_transition_same_state() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.IDLE)
	assert_false(result, "Should NOT be able to transition to the same state")


# =============================================================================
# DEFEAT SPECIAL CASE TESTS
# =============================================================================

func test_defeat_reachable_from_idle() -> void:
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_true(result, "DEFEAT should be reachable from IDLE (non-terminal)")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should now be DEFEAT")


func test_defeat_reachable_from_countdown() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_true(result, "DEFEAT should be reachable from COUNTDOWN")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should now be DEFEAT")


func test_defeat_reachable_from_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_true(result, "DEFEAT should be reachable from SPAWNING")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should now be DEFEAT")


func test_defeat_reachable_from_intermission() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_true(result, "DEFEAT should be reachable from INTERMISSION")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should now be DEFEAT")


func test_defeat_not_reachable_from_victory() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.VICTORY)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_false(result, "DEFEAT should NOT be reachable from VICTORY (terminal state)")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.VICTORY,
		"State should remain VICTORY")


func test_defeat_not_reachable_from_defeat() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.DEFEAT)
	var result = _state_machine.transition_to(WaveStateMachineScript.State.DEFEAT)
	assert_false(result, "Cannot transition to same state")
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.DEFEAT,
		"State should remain DEFEAT")


# =============================================================================
# STATE QUERY TESTS
# =============================================================================

func test_is_wave_active_idle() -> void:
	assert_false(_state_machine.is_wave_active(),
		"Wave should NOT be active in IDLE state")


func test_is_wave_active_countdown() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_true(_state_machine.is_wave_active(),
		"Wave should be active in COUNTDOWN state")


func test_is_wave_active_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	assert_true(_state_machine.is_wave_active(),
		"Wave should be active in SPAWNING state")


func test_is_wave_active_in_progress() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	assert_true(_state_machine.is_wave_active(),
		"Wave should be active in IN_PROGRESS state")


func test_is_wave_active_boss_incoming() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_true(_state_machine.is_wave_active(),
		"Wave should be active in BOSS_INCOMING state")


func test_is_wave_active_intermission() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	assert_false(_state_machine.is_wave_active(),
		"Wave should NOT be active in INTERMISSION state")


func test_is_wave_active_victory() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.VICTORY)
	assert_false(_state_machine.is_wave_active(),
		"Wave should NOT be active in VICTORY state")


func test_is_wave_active_defeat() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.DEFEAT)
	assert_false(_state_machine.is_wave_active(),
		"Wave should NOT be active in DEFEAT state")


func test_is_terminal_state_idle() -> void:
	assert_false(_state_machine.is_terminal_state(),
		"IDLE should NOT be a terminal state")


func test_is_terminal_state_countdown() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_false(_state_machine.is_terminal_state(),
		"COUNTDOWN should NOT be a terminal state")


func test_is_terminal_state_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	assert_false(_state_machine.is_terminal_state(),
		"SPAWNING should NOT be a terminal state")


func test_is_terminal_state_in_progress() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	assert_false(_state_machine.is_terminal_state(),
		"IN_PROGRESS should NOT be a terminal state")


func test_is_terminal_state_intermission() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	assert_false(_state_machine.is_terminal_state(),
		"INTERMISSION should NOT be a terminal state")


func test_is_terminal_state_boss_incoming() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_false(_state_machine.is_terminal_state(),
		"BOSS_INCOMING should NOT be a terminal state")


func test_is_terminal_state_victory() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.VICTORY)
	assert_true(_state_machine.is_terminal_state(),
		"VICTORY should be a terminal state")


func test_is_terminal_state_defeat() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.DEFEAT)
	assert_true(_state_machine.is_terminal_state(),
		"DEFEAT should be a terminal state")


# =============================================================================
# STATE NAME TESTS
# =============================================================================

func test_get_state_name_idle() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.IDLE), "Idle",
		"IDLE state name should be 'Idle'")


func test_get_state_name_countdown() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.COUNTDOWN), "Countdown",
		"COUNTDOWN state name should be 'Countdown'")


func test_get_state_name_spawning() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.SPAWNING), "Spawning",
		"SPAWNING state name should be 'Spawning'")


func test_get_state_name_in_progress() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.IN_PROGRESS), "In Progress",
		"IN_PROGRESS state name should be 'In Progress'")


func test_get_state_name_intermission() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.INTERMISSION), "Intermission",
		"INTERMISSION state name should be 'Intermission'")


func test_get_state_name_boss_incoming() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.BOSS_INCOMING), "Boss Incoming",
		"BOSS_INCOMING state name should be 'Boss Incoming'")


func test_get_state_name_victory() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.VICTORY), "Victory",
		"VICTORY state name should be 'Victory'")


func test_get_state_name_defeat() -> void:
	assert_eq(_state_machine.get_state_name(WaveStateMachineScript.State.DEFEAT), "Defeat",
		"DEFEAT state name should be 'Defeat'")


# =============================================================================
# TIMED STATE TESTS
# =============================================================================

func test_is_timed_state_countdown() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_true(_state_machine.is_timed_state(),
		"COUNTDOWN should be a timed state")


func test_is_timed_state_intermission() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.INTERMISSION)
	assert_true(_state_machine.is_timed_state(),
		"INTERMISSION should be a timed state")


func test_is_timed_state_boss_incoming() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_true(_state_machine.is_timed_state(),
		"BOSS_INCOMING should be a timed state")


func test_is_timed_state_spawning() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	assert_false(_state_machine.is_timed_state(),
		"SPAWNING should NOT be a timed state")


func test_is_timed_state_idle() -> void:
	assert_false(_state_machine.is_timed_state(),
		"IDLE should NOT be a timed state")


func test_state_duration_countdown() -> void:
	var duration = _state_machine.get_state_duration(WaveStateMachineScript.State.COUNTDOWN)
	assert_eq(duration, _state_machine.countdown_duration,
		"COUNTDOWN duration should match configured countdown_duration")


func test_state_duration_intermission() -> void:
	var duration = _state_machine.get_state_duration(WaveStateMachineScript.State.INTERMISSION)
	assert_eq(duration, _state_machine.intermission_duration,
		"INTERMISSION duration should match configured intermission_duration")


func test_state_duration_boss_incoming() -> void:
	var duration = _state_machine.get_state_duration(WaveStateMachineScript.State.BOSS_INCOMING)
	assert_eq(duration, _state_machine.boss_incoming_duration,
		"BOSS_INCOMING duration should match configured boss_incoming_duration")


func test_state_duration_non_timed() -> void:
	var duration = _state_machine.get_state_duration(WaveStateMachineScript.State.IDLE)
	assert_eq(duration, 0.0,
		"Non-timed states should have duration 0")


# =============================================================================
# RESET TESTS
# =============================================================================

func test_reset_returns_to_idle() -> void:
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	_state_machine.reset()
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IDLE,
		"Reset should return to IDLE state")


func test_reset_clears_elapsed_time() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	# Simulate some time passing would require frame processing
	_state_machine.reset()
	assert_eq(_state_machine.get_elapsed_time(), 0.0,
		"Reset should clear elapsed time")


# =============================================================================
# SIGNAL TESTS
# =============================================================================

func test_state_changed_signal_emitted() -> void:
	watch_signals(_state_machine)
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_signal_emitted(_state_machine, "state_changed",
		"state_changed signal should be emitted on transition")


func test_state_changed_signal_parameters() -> void:
	watch_signals(_state_machine)
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	var signal_params = get_signal_parameters(_state_machine, "state_changed")
	assert_eq(signal_params[0], WaveStateMachineScript.State.IDLE,
		"First parameter should be old state (IDLE)")
	assert_eq(signal_params[1], WaveStateMachineScript.State.COUNTDOWN,
		"Second parameter should be new state (COUNTDOWN)")


func test_previous_state_updated_after_transition() -> void:
	_state_machine.transition_to(WaveStateMachineScript.State.COUNTDOWN)
	assert_eq(_state_machine.previous_state, WaveStateMachineScript.State.IDLE,
		"Previous state should be updated to IDLE after transition")


# =============================================================================
# FORCE STATE TESTS
# =============================================================================

func test_force_state_bypasses_validation() -> void:
	# This transition would normally be invalid
	_state_machine.force_state(WaveStateMachineScript.State.IN_PROGRESS)
	assert_eq(_state_machine.current_state, WaveStateMachineScript.State.IN_PROGRESS,
		"force_state should bypass validation and set state directly")


func test_force_state_emits_signal() -> void:
	watch_signals(_state_machine)
	_state_machine.force_state(WaveStateMachineScript.State.SPAWNING)
	assert_signal_emitted(_state_machine, "state_changed",
		"force_state should emit state_changed signal")
