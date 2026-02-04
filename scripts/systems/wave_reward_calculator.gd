class_name WaveRewardCalculator
extends RefCounted
## Static utility class for calculating wave rewards.
##
## Handles all reward calculations for the wave system including:
## - Base wave completion rewards
## - Per-kill rewards
## - Endless mode scaling multipliers
##
## All methods are static and use GameConfig for base values.

# =============================================================================
# CONSTANTS
# =============================================================================

## Endless mode base reward multiplier increase per wave (5% per wave past 100)
const ENDLESS_BASE_MULT_PER_WAVE: float = 0.05

## Endless mode kill reward multiplier increase per wave (2% per wave past 100)
const ENDLESS_KILL_MULT_PER_WAVE: float = 0.02

## Starting wave number for endless mode
const ENDLESS_START_WAVE: int = 100

# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Calculate total wave completion reward
## wave_number: Current wave number (1-based)
## kills: Number of enemies killed this wave
## Returns: Total reward in DigiBytes
static func calculate_wave_reward(wave_number: int, kills: int) -> int:
	var base_reward := calculate_base_reward(wave_number)
	var kill_reward := calculate_kill_reward(wave_number) * kills
	return base_reward + kill_reward


## Calculate the base reward for completing a wave (before kills)
## wave_number: Current wave number (1-based)
## Returns: Base reward in DigiBytes
static func calculate_base_reward(wave_number: int) -> int:
	var reward_values := GameConfig.get_wave_reward_values(wave_number)
	var base_reward: int = reward_values["base"]

	# Apply endless mode scaling
	if wave_number > ENDLESS_START_WAVE:
		var endless_mult := get_endless_base_multiplier(wave_number)
		base_reward = int(base_reward * endless_mult)

	return base_reward


## Calculate the per-kill reward for a wave
## wave_number: Current wave number (1-based)
## Returns: Reward per kill in DigiBytes
static func calculate_kill_reward(wave_number: int) -> int:
	var reward_values := GameConfig.get_wave_reward_values(wave_number)
	var per_kill_reward: int = reward_values["per_kill"]

	# Apply endless mode scaling
	if wave_number > ENDLESS_START_WAVE:
		var endless_mult := get_endless_kill_multiplier(wave_number)
		per_kill_reward = int(per_kill_reward * endless_mult)

	return per_kill_reward


## Get the endless mode multiplier for base rewards
## wave_number: Current wave number (must be > 100 for any scaling)
## Returns: Multiplier (1.0 for waves 1-100, increases after)
static func get_endless_base_multiplier(wave_number: int) -> float:
	if wave_number <= ENDLESS_START_WAVE:
		return 1.0
	return 1.0 + (wave_number - ENDLESS_START_WAVE) * ENDLESS_BASE_MULT_PER_WAVE


## Get the endless mode multiplier for kill rewards
## wave_number: Current wave number (must be > 100 for any scaling)
## Returns: Multiplier (1.0 for waves 1-100, increases after)
static func get_endless_kill_multiplier(wave_number: int) -> float:
	if wave_number <= ENDLESS_START_WAVE:
		return 1.0
	return 1.0 + (wave_number - ENDLESS_START_WAVE) * ENDLESS_KILL_MULT_PER_WAVE


## Get the overall endless mode multiplier (average of base and kill)
## wave_number: Current wave number (must be > 100 for any scaling)
## Returns: Average multiplier for display purposes
static func get_endless_multiplier(wave_number: int) -> float:
	if wave_number <= ENDLESS_START_WAVE:
		return 1.0
	var base_mult := get_endless_base_multiplier(wave_number)
	var kill_mult := get_endless_kill_multiplier(wave_number)
	return (base_mult + kill_mult) / 2.0


## Check if a wave is in endless mode
## wave_number: Current wave number (1-based)
## Returns: True if wave > 100
static func is_endless_wave(wave_number: int) -> bool:
	return wave_number > ENDLESS_START_WAVE


## Get reward breakdown for UI display
## wave_number: Current wave number (1-based)
## kills: Number of enemies killed this wave
## Returns: Dictionary with reward breakdown
static func get_reward_breakdown(wave_number: int, kills: int) -> Dictionary:
	var base_reward := calculate_base_reward(wave_number)
	var per_kill := calculate_kill_reward(wave_number)
	var kill_total := per_kill * kills
	var total := base_reward + kill_total

	return {
		"base_reward": base_reward,
		"per_kill_reward": per_kill,
		"kills": kills,
		"kill_total": kill_total,
		"total": total,
		"is_endless": is_endless_wave(wave_number),
		"endless_multiplier": get_endless_multiplier(wave_number)
	}
