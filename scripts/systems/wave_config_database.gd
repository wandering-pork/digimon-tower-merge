class_name WaveConfigDatabase
extends RefCounted
## Static database for wave configuration data.
##
## Contains all enemy definitions, tier constants, and phase configurations.
## Used by WaveGenerator to determine wave compositions.

# =============================================================================
# CONSTANTS - BASE STATS BY TIER
# =============================================================================

## Base HP values by evolution tier
const BASE_HP_BY_TIER: Dictionary = {
	0: 15,     # In-Training
	1: 40,     # Rookie
	2: 120,    # Champion
	3: 350,    # Ultimate
	4: 1000,   # Mega
	5: 3000    # Ultra
}

## Base damage values by evolution tier
const BASE_DMG_BY_TIER: Dictionary = {
	0: 2,      # In-Training
	1: 5,      # Rookie
	2: 12,     # Champion
	3: 25,     # Ultimate
	4: 50,     # Mega
	5: 100     # Ultra
}

## Phase start waves
const PHASE_STARTS: Array[int] = [1, 21, 41, 61, 81, 101]

## Tier folder names for resource loading
const TIER_FOLDERS: Array[String] = ["in_training", "rookie", "champion", "ultimate", "mega", "ultra"]

## Base reward by tier
const REWARD_BY_TIER: Array[int] = [2, 5, 12, 25, 50, 100]

# =============================================================================
# ENEMY DEFINITIONS
# =============================================================================

## In-Training enemy definitions (Waves 1-5)
const IN_TRAINING_ENEMIES: Dictionary = {
	"Koromon": {"type": "SWARM", "attribute": "VACCINE"},
	"Tsunomon": {"type": "SWARM", "attribute": "DATA"},
	"Tokomon": {"type": "SWARM", "attribute": "VACCINE"},
	"Pagumon": {"type": "SWARM", "attribute": "VIRUS"},
	"Gigimon": {"type": "STANDARD", "attribute": "VIRUS"}
}

## Rookie enemy definitions (Waves 1-20)
const ROOKIE_ENEMIES: Dictionary = {
	"Agumon": {"type": "STANDARD", "attribute": "VACCINE"},
	"Gabumon": {"type": "STANDARD", "attribute": "DATA"},
	"Patamon": {"type": "FLYING", "attribute": "VACCINE"},
	"Guilmon": {"type": "TANK", "attribute": "VIRUS"},
	"Impmon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Goblimon": {"type": "STANDARD", "attribute": "VIRUS"},
	"Gazimon": {"type": "SWARM", "attribute": "VIRUS"},
	"Elecmon": {"type": "STANDARD", "attribute": "DATA"},
	"Gotsumon": {"type": "TANK", "attribute": "DATA"},
	"Kunemon": {"type": "SWARM", "attribute": "VIRUS"},
	"Biyomon": {"type": "FLYING", "attribute": "DATA"},
	"Tentomon": {"type": "STANDARD", "attribute": "DATA"},
	"Betamon": {"type": "STANDARD", "attribute": "VIRUS"},
	"Floramon": {"type": "REGEN", "attribute": "DATA"}
}

## Champion enemy definitions (Waves 21-40)
const CHAMPION_ENEMIES: Dictionary = {
	"Greymon": {"type": "STANDARD", "attribute": "VACCINE"},
	"Garurumon": {"type": "STANDARD", "attribute": "DATA"},
	"Devimon": {"type": "TANK", "attribute": "VIRUS"},
	"Angemon": {"type": "FLYING", "attribute": "VACCINE"},
	"Ogremon": {"type": "TANK", "attribute": "VIRUS"},
	"Tyrannomon": {"type": "TANK", "attribute": "DATA"},
	"Leomon": {"type": "STANDARD", "attribute": "VACCINE"},
	"Meramon": {"type": "SPEEDSTER", "attribute": "DATA"},
	"Bakemon": {"type": "SWARM", "attribute": "VIRUS"},
	"Seadramon": {"type": "STANDARD", "attribute": "DATA"},
	"Birdramon": {"type": "FLYING", "attribute": "DATA"},
	"Kuwagamon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Centarumon": {"type": "SHIELDED", "attribute": "DATA"},
	"Wizardmon": {"type": "STANDARD", "attribute": "DATA"},
	"Numemon": {"type": "SWARM", "attribute": "VIRUS"},
	"Monochromon": {"type": "TANK", "attribute": "DATA"},
	"Airdramon": {"type": "FLYING", "attribute": "VIRUS"},
	"DarkTyrannomon": {"type": "TANK", "attribute": "VIRUS"},
	"Kabuterimon": {"type": "FLYING", "attribute": "DATA"},
	"Togemon": {"type": "REGEN", "attribute": "DATA"}
}

## Ultimate enemy definitions (Waves 41-60)
const ULTIMATE_ENEMIES: Dictionary = {
	"MetalGreymon": {"type": "TANK", "attribute": "VACCINE"},
	"WereGarurumon": {"type": "SPEEDSTER", "attribute": "DATA"},
	"MagnaAngemon": {"type": "FLYING", "attribute": "VACCINE"},
	"Myotismon": {"type": "STANDARD", "attribute": "VIRUS"},
	"SkullGreymon": {"type": "TANK", "attribute": "VIRUS"},
	"Andromon": {"type": "SHIELDED", "attribute": "VACCINE"},
	"MegaKabuterimon": {"type": "FLYING", "attribute": "DATA"},
	"Garudamon": {"type": "FLYING", "attribute": "DATA"},
	"Zudomon": {"type": "TANK", "attribute": "VACCINE"},
	"MegaSeadramon": {"type": "STANDARD", "attribute": "DATA"},
	"Angewomon": {"type": "FLYING", "attribute": "VACCINE"},
	"LadyDevimon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Pumpkinmon": {"type": "SWARM", "attribute": "DATA"},
	"Mamemon": {"type": "SPLITTER", "attribute": "DATA"},
	"MetalMamemon": {"type": "SHIELDED", "attribute": "DATA"},
	"BlueMeramon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Megadramon": {"type": "FLYING", "attribute": "VIRUS"},
	"Gigadramon": {"type": "TANK", "attribute": "VIRUS"},
	"WaruMonzaemon": {"type": "TANK", "attribute": "VIRUS"},
	"SkullMeramon": {"type": "STANDARD", "attribute": "VIRUS"}
}

## Mega enemy definitions (Waves 61-80)
const MEGA_ENEMIES: Dictionary = {
	"WarGreymon": {"type": "TANK", "attribute": "VACCINE"},
	"MetalGarurumon": {"type": "SPEEDSTER", "attribute": "DATA"},
	"VenomMyotismon": {"type": "TANK", "attribute": "VIRUS"},
	"Piedmon": {"type": "STANDARD", "attribute": "VIRUS"},
	"Puppetmon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"MetalSeadramon": {"type": "TANK", "attribute": "DATA"},
	"Machinedramon": {"type": "TANK", "attribute": "VIRUS"},
	"Phoenixmon": {"type": "FLYING", "attribute": "VACCINE"},
	"HerculesKabuterimon": {"type": "FLYING", "attribute": "VACCINE"},
	"SaberLeomon": {"type": "SPEEDSTER", "attribute": "DATA"},
	"Boltmon": {"type": "TANK", "attribute": "DATA"},
	"Diaboromon": {"type": "SPLITTER", "attribute": "VIRUS"},
	"BlackWarGreymon": {"type": "TANK", "attribute": "VIRUS"},
	"GranKuwagamon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Daemon": {"type": "TANK", "attribute": "VIRUS"},
	"Beelzemon": {"type": "SPEEDSTER", "attribute": "VIRUS"},
	"Leviamon": {"type": "TANK", "attribute": "VIRUS"},
	"CherubimonEvil": {"type": "TANK", "attribute": "VIRUS"}
}

## Ultra enemy definitions (Waves 81-100)
const ULTRA_ENEMIES: Dictionary = {
	"Omegamon": {"type": "TANK", "attribute": "VACCINE"},
	"OmegamonZwart": {"type": "TANK", "attribute": "VIRUS"},
	"ImperialdramonDM": {"type": "TANK", "attribute": "VIRUS"},
	"Armageddemon": {"type": "TANK", "attribute": "VIRUS"},
	"Millenniummon": {"type": "TANK", "attribute": "VIRUS"}
}

## Boss HP values by wave number
const BOSS_HP_VALUES: Dictionary = {
	10: 500,
	20: 1500,
	30: 2000,
	40: 6000,
	50: 8000,
	60: 20000,
	70: 25000,
	80: 60000,
	90: 80000,
	100: 200000
}

# =============================================================================
# STATIC QUERY METHODS
# =============================================================================

## Get all enemy pools as an array for iteration
static func get_all_enemy_pools() -> Array[Dictionary]:
	return [IN_TRAINING_ENEMIES, ROOKIE_ENEMIES, CHAMPION_ENEMIES,
			ULTIMATE_ENEMIES, MEGA_ENEMIES, ULTRA_ENEMIES]


## Get enemy pool for a specific tier
static func get_enemy_pool_for_tier(tier: int) -> Dictionary:
	var pools = get_all_enemy_pools()
	return pools[mini(tier, pools.size() - 1)]


## Find enemy definition by name across all pools
static func find_enemy_definition(enemy_name: String) -> Dictionary:
	var pools = get_all_enemy_pools()
	for pool in pools:
		if pool.has(enemy_name):
			return pool[enemy_name]
	return {}


## Get tier folder name for resource path
static func get_tier_folder(tier: int) -> String:
	return TIER_FOLDERS[mini(tier, TIER_FOLDERS.size() - 1)]


## Get base HP for a tier
static func get_base_hp(tier: int) -> int:
	return BASE_HP_BY_TIER.get(tier, 40)


## Get base reward for a tier
static func get_base_reward(tier: int) -> int:
	return REWARD_BY_TIER[mini(tier, REWARD_BY_TIER.size() - 1)]


## Get boss HP for a specific wave
static func get_boss_hp(boss_wave: int) -> int:
	return BOSS_HP_VALUES.get(boss_wave, 10000 + boss_wave * 500)


## Get phase start wave for a given wave number
static func get_phase_start(wave: int) -> int:
	for i in range(PHASE_STARTS.size() - 1, -1, -1):
		if wave >= PHASE_STARTS[i]:
			return PHASE_STARTS[i]
	return 1
