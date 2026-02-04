class_name EnemyComposition
extends RefCounted
## Handles enemy group generation and composition logic.
##
## Builds enemy configurations for waves based on wave number and phase.
## Manages enemy data loading and runtime fallback creation.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const WaveConfigDatabase = preload("res://scripts/systems/wave_config_database.gd")

# =============================================================================
# ENEMY COUNT CALCULATION
# =============================================================================

## Get enemy count for a wave
static func get_enemy_count(wave: int) -> int:
	var base: float = 6.0 + (wave * 0.5)
	var swarm_bonus: float = 0.0

	if wave > 5:
		swarm_bonus = (wave - 5) * 0.3

	return int(minf(base + swarm_bonus, 100.0))


# =============================================================================
# ENEMY CONFIG CREATION
# =============================================================================

## Create an enemy config dictionary
static func create_enemy_config(enemy_name: String, tier: int, wave: int, modifier: int = 0) -> Dictionary:
	var enemy_data: EnemyData = _load_enemy_data(enemy_name, tier)

	return {
		"name": enemy_name,
		"enemy_data": enemy_data,
		"tier": tier,
		"is_boss": false,
		"modifier": modifier,
		"wave": wave
	}


## Create a boss config dictionary
static func create_boss_config(boss_name: String, tier: int, wave: int, boss_wave: int) -> Dictionary:
	var enemy_data: EnemyData = _load_boss_data(boss_name, boss_wave)

	return {
		"name": boss_name,
		"enemy_data": enemy_data,
		"tier": tier,
		"is_boss": true,
		"modifier": 0,  # EnemyModifier.ModifierType.NONE
		"wave": wave,
		"boss_wave": boss_wave
	}


# =============================================================================
# STAT SCALING
# =============================================================================

## Get enemy stats scaled for wave
static func get_scaled_stats(base_hp: int, base_dmg: int, wave: int, _tier: int) -> Dictionary:
	var phase_start: int = WaveConfigDatabase.get_phase_start(wave)
	var waves_into_phase: int = wave - phase_start

	# Within-phase scaling
	var hp_mult: float = 1.0 + (0.08 * waves_into_phase)
	var dmg_mult: float = 1.0 + (0.05 * waves_into_phase)

	# Endless mode exponential scaling
	if wave > 100:
		hp_mult *= pow(1.05, wave - 100)
		dmg_mult *= pow(1.03, wave - 100)

	return {
		"hp": int(base_hp * hp_mult),
		"damage": int(base_dmg * dmg_mult)
	}


## Get boss tier from wave number
static func get_boss_tier(boss_wave: int) -> int:
	if boss_wave <= 20:
		return 2  # Champion
	elif boss_wave <= 40:
		return 3  # Ultimate
	elif boss_wave <= 60:
		return 4  # Mega
	elif boss_wave <= 80:
		return 4  # Mega
	else:
		return 5  # Ultra


# =============================================================================
# RESOURCE LOADING
# =============================================================================

## Load enemy data resource
static func _load_enemy_data(enemy_name: String, tier: int) -> EnemyData:
	var folder: String = WaveConfigDatabase.get_tier_folder(tier)

	# Convert name to filename format
	var filename: String = enemy_name.to_lower().replace(" ", "_") + "_enemy.tres"
	var path: String = "res://resources/enemies/%s/%s" % [folder, filename]

	if ResourceLoader.exists(path):
		return load(path) as EnemyData

	# Fallback: create runtime enemy data
	return _create_runtime_enemy_data(enemy_name, tier)


## Load boss data resource
static func _load_boss_data(boss_name: String, boss_wave: int) -> EnemyData:
	var filename: String = "wave_%d_%s.tres" % [boss_wave, boss_name.to_lower().replace(" ", "_")]
	var path: String = "res://resources/waves/bosses/%s" % filename

	if ResourceLoader.exists(path):
		return load(path) as EnemyData

	# Fallback: create runtime boss data
	return _create_runtime_boss_data(boss_name, boss_wave)


# =============================================================================
# RUNTIME DATA CREATION
# =============================================================================

## Create enemy data at runtime if resource doesn't exist
static func _create_runtime_enemy_data(enemy_name: String, tier: int) -> EnemyData:
	var data := EnemyData.new()
	data.digimon_name = enemy_name
	data.base_hp = WaveConfigDatabase.get_base_hp(tier)

	# Try to find enemy definition
	var def: Dictionary = WaveConfigDatabase.find_enemy_definition(enemy_name)

	if not def.is_empty():
		_apply_enemy_type(data, def.get("type", "STANDARD"))
		_apply_enemy_attribute(data, def.get("attribute", "DATA"))
	else:
		data.enemy_type = EnemyData.EnemyType.STANDARD
		data.attribute = EnemyData.Attribute.DATA

	# Set reward based on tier
	data.reward = WaveConfigDatabase.get_base_reward(tier)

	# Set type-specific properties
	if data.enemy_type == EnemyData.EnemyType.REGEN:
		data.regen_percent = 0.02

	if data.enemy_type == EnemyData.EnemyType.SPLITTER:
		data.split_count = 2 if tier < 4 else 4  # Diaboromon splits into 4

	return data


## Create boss data at runtime if resource doesn't exist
static func _create_runtime_boss_data(boss_name: String, boss_wave: int) -> EnemyData:
	var data: EnemyData = _create_runtime_enemy_data(boss_name, get_boss_tier(boss_wave))

	data.is_boss = true
	data.base_hp = WaveConfigDatabase.get_boss_hp(boss_wave)
	data.reward = boss_wave * 10

	return data


## Apply enemy type from string definition
static func _apply_enemy_type(data: EnemyData, type_str: String) -> void:
	match type_str:
		"SWARM": data.enemy_type = EnemyData.EnemyType.SWARM
		"TANK": data.enemy_type = EnemyData.EnemyType.TANK
		"SPEEDSTER": data.enemy_type = EnemyData.EnemyType.SPEEDSTER
		"FLYING": data.enemy_type = EnemyData.EnemyType.FLYING
		"REGEN": data.enemy_type = EnemyData.EnemyType.REGEN
		"SHIELDED": data.enemy_type = EnemyData.EnemyType.SHIELDED
		"SPLITTER": data.enemy_type = EnemyData.EnemyType.SPLITTER
		_: data.enemy_type = EnemyData.EnemyType.STANDARD


## Apply enemy attribute from string definition
static func _apply_enemy_attribute(data: EnemyData, attr_str: String) -> void:
	match attr_str:
		"VACCINE": data.attribute = EnemyData.Attribute.VACCINE
		"VIRUS": data.attribute = EnemyData.Attribute.VIRUS
		"FREE": data.attribute = EnemyData.Attribute.FREE
		_: data.attribute = EnemyData.Attribute.DATA
