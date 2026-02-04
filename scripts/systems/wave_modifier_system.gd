class_name WaveModifierSystem
extends RefCounted
## Handles wave modifier assignment and scaling for late-game waves.
##
## Manages modifier chances and application for waves 50+,
## including endless mode scaling.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyModifier = preload("res://scripts/enemies/enemy_modifier.gd")

# =============================================================================
# MODIFIER CHANCE CALCULATION
# =============================================================================

## Get modifier chance for a wave (0.0 to 1.0)
## Modifiers start appearing at wave 50
static func get_modifier_chance(wave: int) -> float:
	if wave < 50:
		return 0.0
	elif wave <= 60:
		# Phase 3: 20% chance
		return 0.2
	elif wave <= 80:
		# Phase 4: 40% chance
		return 0.4
	elif wave <= 100:
		# Phase 5: 60% to 100% scaling
		return 0.6 + (wave - 80) * 0.02
	else:
		# Endless: 80%+ scaling up to 100%
		return minf(1.0, 0.8 + (wave - 100) * 0.01)


# =============================================================================
# MODIFIER ROLLING
# =============================================================================

## Roll for a modifier based on chance
## Returns EnemyModifier.ModifierType value (0 = NONE)
static func roll_modifier(wave: int) -> int:
	var chance: float = get_modifier_chance(wave)
	return roll_modifier_with_chance(chance)


## Roll for a modifier with explicit chance value
static func roll_modifier_with_chance(chance: float) -> int:
	if randf() > chance:
		return EnemyModifier.ModifierType.NONE
	# Use wave 50 as reference to ensure modifier is rolled
	return EnemyModifier.get_random_modifier(50)


## Roll modifier for an enemy config in place
static func apply_modifier_roll(enemy_config: Dictionary, wave: int) -> void:
	enemy_config["modifier"] = roll_modifier(wave)


# =============================================================================
# ENDLESS MODE SCALING
# =============================================================================

## Get endless mode scaling multipliers for wave 101+
static func get_endless_scaling(wave: int) -> Dictionary:
	if wave <= 100:
		return {"hp_mult": 1.0, "damage_mult": 1.0}

	var waves_past_100: int = wave - 100
	return {
		"hp_mult": pow(1.05, waves_past_100),
		"damage_mult": pow(1.03, waves_past_100)
	}


## Check if wave is in endless mode
static func is_endless_mode(wave: int) -> bool:
	return wave > 100


## Check if wave should have a boss (every 10 waves in endless)
static func should_have_endless_boss(wave: int) -> bool:
	return wave > 100 and wave % 10 == 0


## Get boss pool for endless mode
static func get_endless_boss_pool() -> Array[String]:
	return ["Omegamon", "OmegamonZwart", "Apocalymon", "Millenniummon", "Armageddemon"]


# =============================================================================
# WAVE PHASE DETECTION
# =============================================================================

## Get current phase number (1-6, 6 = endless)
static func get_phase_number(wave: int) -> int:
	if wave <= 20:
		return 1
	elif wave <= 40:
		return 2
	elif wave <= 60:
		return 3
	elif wave <= 80:
		return 4
	elif wave <= 100:
		return 5
	else:
		return 6  # Endless


## Check if wave is a boss wave
static func is_boss_wave(wave: int) -> bool:
	# Mini-bosses at 10, 30, 50, 70, 90
	# Phase bosses at 20, 40, 60, 80, 100
	if wave <= 100:
		return wave % 10 == 0
	else:
		return should_have_endless_boss(wave)


## Check if wave is a phase boss wave (major boss)
static func is_phase_boss_wave(wave: int) -> bool:
	return wave in [20, 40, 60, 80, 100]


## Check if wave is a mini-boss wave
static func is_mini_boss_wave(wave: int) -> bool:
	return wave in [10, 30, 50, 70, 90]


# =============================================================================
# TIER PREVIEW LOGIC
# =============================================================================

## Get preview ratio for next tier enemies
## Returns 0.0 if no preview, otherwise percentage of enemies from next tier
static func get_tier_preview_ratio(wave: int) -> float:
	# Champion preview in waves 16-19
	if wave >= 16 and wave <= 19:
		return (wave - 15) * 0.15  # 15%, 30%, 45%, 60%

	# Ultimate preview in waves 36-39
	if wave >= 36 and wave <= 39:
		return (wave - 35) * 0.15

	# Mega preview in waves 56-59
	if wave >= 56 and wave <= 59:
		return (wave - 55) * 0.15

	# Ultra preview in waves 77-79
	if wave >= 77 and wave <= 79:
		return (wave - 76) * 0.1

	# Phase 5 Ultra scaling (81-99)
	if wave >= 81 and wave <= 99:
		var ratio: float = 0.4 + (wave - 80) * 0.03
		return minf(ratio, 1.0)

	return 0.0


## Check if wave is in a tier preview range
static func is_tier_preview_wave(wave: int) -> bool:
	return get_tier_preview_ratio(wave) > 0.0
