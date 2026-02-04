class_name WaveGenerator
extends RefCounted
## Main interface for generating wave compositions.
##
## Generates enemy spawn configurations based on wave number.
## Delegates to WaveConfigDatabase, EnemyComposition, and WaveModifierSystem.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyComposition = preload("res://scripts/systems/enemy_composition.gd")
const WaveModifierSystem = preload("res://scripts/systems/wave_modifier_system.gd")
const WaveConfigDatabase = preload("res://scripts/systems/wave_config_database.gd")

# =============================================================================
# MAIN GENERATION FUNCTION
# =============================================================================

## Generate a complete wave composition
## Returns array of enemy configs: { "enemy_data": EnemyData, "is_boss": bool, "modifier": int, "name": String }
static func generate_wave(wave_number: int) -> Array:
	if wave_number <= 5:
		return _generate_tutorial_wave(wave_number)
	elif wave_number <= 10:
		return _generate_phase1_early(wave_number)
	elif wave_number <= 20:
		return _generate_phase1_late(wave_number)
	elif wave_number <= 40:
		return _generate_phase2(wave_number)
	elif wave_number <= 60:
		return _generate_phase3(wave_number)
	elif wave_number <= 80:
		return _generate_phase4(wave_number)
	elif wave_number <= 100:
		return _generate_phase5(wave_number)
	else:
		return _generate_endless(wave_number)


# =============================================================================
# PUBLIC HELPER ACCESSORS (for backwards compatibility)
# =============================================================================

## Get enemy count for a wave
static func get_enemy_count(wave: int) -> int:
	return EnemyComposition.get_enemy_count(wave)


## Get modifier chance for a wave
static func get_modifier_chance(wave: int) -> float:
	return WaveModifierSystem.get_modifier_chance(wave)


## Get enemy stats scaled for wave
static func get_enemy_stats_for_wave(base_hp: int, base_dmg: int, wave: int, tier: int) -> Dictionary:
	return EnemyComposition.get_scaled_stats(base_hp, base_dmg, wave, tier)


# =============================================================================
# PHASE GENERATORS
# =============================================================================

## Tutorial waves (1-5): In-Training enemies
static func _generate_tutorial_wave(wave: int) -> Array:
	var enemies: Array = []

	match wave:
		1:
			_add_enemies(enemies, "Koromon", 0, wave, 6)
		2:
			_add_enemies(enemies, "Tsunomon", 0, wave, 4)
			_add_enemies(enemies, "Tokomon", 0, wave, 3)
		3:
			_add_enemies(enemies, "Pagumon", 0, wave, 6)
			_add_enemies(enemies, "Agumon", 1, wave, 2)
		4:
			_add_enemies(enemies, "Gigimon", 0, wave, 6)
			_add_enemies(enemies, "Gabumon", 1, wave, 3)
		5:
			_add_random_enemies(enemies, ["Koromon", "Tsunomon", "Tokomon", "Pagumon"], 0, wave, 5)
			_add_random_enemies(enemies, ["Agumon", "Gabumon", "Goblimon"], 1, wave, 5)

	return enemies


## Phase 1 Early (6-10): Rookie introduction
static func _generate_phase1_early(wave: int) -> Array:
	var enemies: Array = []

	match wave:
		6:
			_add_enemies(enemies, "Agumon", 1, wave, 4)
			_add_enemies(enemies, "Gabumon", 1, wave, 3)
			_add_enemies(enemies, "Goblimon", 1, wave, 3)
		7:
			_add_enemies(enemies, "Elecmon", 1, wave, 6)
			_add_enemies(enemies, "Impmon", 1, wave, 2)
			_add_enemies(enemies, "Gazimon", 1, wave, 3)
		8:
			_add_random_enemies(enemies, ["Agumon", "Gabumon", "Tentomon", "Elecmon"], 1, wave, 8)
			_add_enemies(enemies, "Patamon", 1, wave, 2)
			_add_enemies(enemies, "Gotsumon", 1, wave, 2)
		9:
			var rookies := ["Agumon", "Gabumon", "Patamon", "Impmon", "Goblimon", "Elecmon", "Biyomon"]
			_add_random_enemies(enemies, rookies, 1, wave, 14)
		10:
			var rookies := ["Agumon", "Gabumon", "Goblimon", "Patamon", "Impmon"]
			_add_random_enemies(enemies, rookies, 1, wave, 12)
			enemies.append(EnemyComposition.create_boss_config("Greymon", 2, wave, 10))

	return enemies


## Phase 1 Late (11-20): Difficulty ramp and Phase Boss
static func _generate_phase1_late(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	if wave >= 16 and wave <= 19:
		var champion_count: int = (wave - 15) * 2
		var rookie_count: int = count - champion_count
		_add_random_enemies(enemies, ["Agumon", "Gabumon", "Impmon", "Patamon", "Gotsumon"], 1, wave, rookie_count)
		_add_random_enemies(enemies, ["Greymon", "Garurumon", "Leomon"], 2, wave, champion_count)

	elif wave == 20:
		var champion_pool := ["Greymon", "Garurumon", "Leomon", "Tyrannomon", "Ogremon"]
		_add_random_enemies(enemies, champion_pool, 2, wave, 18)
		enemies.append(EnemyComposition.create_boss_config("Greymon", 2, wave, 20))

	else:
		var tank_count: int = int(count * 0.25)
		var speedster_count: int = int(count * 0.2)
		var flying_count: int = int(count * 0.15)
		var standard_count: int = count - tank_count - speedster_count - flying_count

		_add_random_enemies(enemies, ["Agumon", "Gabumon", "Goblimon", "Elecmon", "Tentomon"], 1, wave, standard_count)
		_add_random_enemies(enemies, ["Gotsumon", "Guilmon"], 1, wave, tank_count)
		_add_enemies(enemies, "Impmon", 1, wave, speedster_count)
		_add_random_enemies(enemies, ["Patamon", "Biyomon"], 1, wave, flying_count)

	enemies.shuffle()
	return enemies


## Phase 2 (21-40): Champion enemies
static func _generate_phase2(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	if wave == 30:
		_add_random_enemies(enemies, ["Greymon", "Garurumon", "Tyrannomon", "Ogremon", "Bakemon"], 2, wave, 16)
		enemies.append(EnemyComposition.create_boss_config("Devimon", 2, wave, 30))

	elif wave == 40:
		_add_random_enemies(enemies, ["Greymon", "Garurumon", "Devimon", "Tyrannomon"], 2, wave, 12)
		_add_random_enemies(enemies, ["MetalGreymon", "WereGarurumon", "Zudomon"], 3, wave, 10)
		enemies.append(EnemyComposition.create_boss_config("Myotismon", 3, wave, 40))

	elif wave >= 36:
		var ultimate_ratio: float = (wave - 35) * 0.15
		var ultimate_count: int = int(count * ultimate_ratio)
		var champion_count: int = count - ultimate_count
		_add_random_enemies(enemies, ["Greymon", "Garurumon", "Devimon", "Ogremon", "Birdramon", "Meramon"], 2, wave, champion_count)
		_add_random_enemies(enemies, ["MetalGreymon", "WereGarurumon", "Zudomon", "SkullGreymon"], 3, wave, ultimate_count)

	else:
		var champion_pool: Array = WaveConfigDatabase.CHAMPION_ENEMIES.keys()
		_add_random_enemies(enemies, champion_pool, 2, wave, count)

	enemies.shuffle()
	return enemies


## Phase 3 (41-60): Ultimate enemies with modifiers
static func _generate_phase3(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	if wave == 50:
		_add_modified_enemies(enemies, ["MetalGreymon", "WereGarurumon", "Zudomon", "Andromon", "Myotismon"], 3, wave, 25)
		enemies.append(EnemyComposition.create_boss_config("SkullGreymon", 3, wave, 50))

	elif wave == 60:
		_add_modified_enemies(enemies, ["MetalGreymon", "SkullGreymon", "Myotismon", "Andromon"], 3, wave, 15)
		_add_modified_enemies(enemies, ["WarGreymon", "MetalGarurumon", "Machinedramon"], 4, wave, 13)
		enemies.append(EnemyComposition.create_boss_config("VenomMyotismon", 4, wave, 60))

	elif wave >= 56:
		var mega_ratio: float = (wave - 55) * 0.15
		var mega_count: int = int(count * mega_ratio)
		var ult_count: int = count - mega_count
		var ult_pool: Array = WaveConfigDatabase.ULTIMATE_ENEMIES.keys()
		_add_modified_enemies(enemies, ult_pool, 3, wave, ult_count)
		_add_modified_enemies(enemies, ["WarGreymon", "MetalGarurumon", "Piedmon", "VenomMyotismon"], 4, wave, mega_count)

	else:
		var ult_pool: Array = WaveConfigDatabase.ULTIMATE_ENEMIES.keys()
		_add_modified_enemies(enemies, ult_pool, 3, wave, count)

	enemies.shuffle()
	return enemies


## Phase 4 (61-80): Mega enemies
static func _generate_phase4(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	if wave == 70:
		_add_modified_enemies(enemies, ["WarGreymon", "MetalGarurumon", "VenomMyotismon", "Daemon"], 4, wave, 35)
		enemies.append(EnemyComposition.create_boss_config("Machinedramon", 4, wave, 70))

	elif wave == 80:
		_add_modified_enemies(enemies, ["WarGreymon", "MetalGarurumon", "Machinedramon", "Daemon"], 4, wave, 25)
		_add_modified_enemies(enemies, ["Omegamon", "OmegamonZwart"], 5, wave, 15)
		enemies.append(EnemyComposition.create_boss_config("Omegamon", 5, wave, 80))

	elif wave >= 77:
		var ultra_ratio: float = (wave - 76) * 0.1
		var ultra_count: int = int(count * ultra_ratio)
		var mega_count: int = count - ultra_count
		var mega_pool: Array = WaveConfigDatabase.MEGA_ENEMIES.keys()
		var ultra_pool: Array = WaveConfigDatabase.ULTRA_ENEMIES.keys()
		_add_modified_enemies(enemies, mega_pool, 4, wave, mega_count)
		_add_modified_enemies(enemies, ultra_pool, 5, wave, ultra_count)

	else:
		var mega_pool: Array = WaveConfigDatabase.MEGA_ENEMIES.keys()
		_add_modified_enemies(enemies, mega_pool, 4, wave, count)

	enemies.shuffle()
	return enemies


## Phase 5 (81-100): Ultra enemies
static func _generate_phase5(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	if wave == 90:
		_add_modified_enemies(enemies, ["Omegamon", "OmegamonZwart", "ImperialdramonDM"], 5, wave, 45)
		enemies.append(EnemyComposition.create_boss_config("OmegamonZwart", 5, wave, 90))

	elif wave == 100:
		_add_modified_enemies(enemies, ["Omegamon", "OmegamonZwart", "ImperialdramonDM", "Armageddemon"], 5, wave, 50)
		enemies.append(EnemyComposition.create_boss_config("Apocalymon", 5, wave, 100))

	else:
		var ultra_ratio: float = minf(0.4 + (wave - 80) * 0.03, 1.0)
		var ultra_count: int = int(count * ultra_ratio)
		var mega_count: int = count - ultra_count
		var mega_pool: Array = WaveConfigDatabase.MEGA_ENEMIES.keys()
		var ultra_pool: Array = WaveConfigDatabase.ULTRA_ENEMIES.keys()
		_add_modified_enemies(enemies, mega_pool, 4, wave, mega_count)
		_add_modified_enemies(enemies, ultra_pool, 5, wave, ultra_count)

	enemies.shuffle()
	return enemies


## Endless mode (101+): Scaled mixed enemies
static func _generate_endless(wave: int) -> Array:
	var enemies: Array = []
	var count: int = EnemyComposition.get_enemy_count(wave)

	var mega_pool: Array = WaveConfigDatabase.MEGA_ENEMIES.keys()
	var ultra_pool: Array = WaveConfigDatabase.ULTRA_ENEMIES.keys()

	for i in range(count):
		var pool: Array = [mega_pool, ultra_pool].pick_random()
		var name: String = pool.pick_random()
		var tier: int = 4 if pool == mega_pool else 5
		var mod: int = WaveModifierSystem.roll_modifier(wave)
		enemies.append(EnemyComposition.create_enemy_config(name, tier, wave, mod))

	if WaveModifierSystem.should_have_endless_boss(wave):
		var boss_pool: Array[String] = WaveModifierSystem.get_endless_boss_pool()
		enemies.append(EnemyComposition.create_boss_config(boss_pool.pick_random(), 5, wave, wave))

	enemies.shuffle()
	return enemies


# =============================================================================
# INTERNAL HELPER FUNCTIONS
# =============================================================================

## Add multiple enemies of the same type
static func _add_enemies(enemies: Array, name: String, tier: int, wave: int, count: int) -> void:
	for i in range(count):
		enemies.append(EnemyComposition.create_enemy_config(name, tier, wave))


## Add multiple random enemies from a pool
static func _add_random_enemies(enemies: Array, pool: Array, tier: int, wave: int, count: int) -> void:
	for i in range(count):
		enemies.append(EnemyComposition.create_enemy_config(pool.pick_random(), tier, wave))


## Add multiple random enemies from a pool with modifier rolls
static func _add_modified_enemies(enemies: Array, pool: Array, tier: int, wave: int, count: int) -> void:
	for i in range(count):
		var mod: int = WaveModifierSystem.roll_modifier(wave)
		enemies.append(EnemyComposition.create_enemy_config(pool.pick_random(), tier, wave, mod))
