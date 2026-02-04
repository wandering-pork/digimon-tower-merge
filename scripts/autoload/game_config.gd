# class_name GameConfig  # Removed: autoloads register as globals, class_name causes conflicts
extends Node
## Centralized game configuration and balance constants.
##
## This autoload singleton contains ALL game balance constants in one place,
## making it easy to tune game balance without searching through multiple files.
## Access via GameConfig.CONSTANT_NAME from any script.

# =============================================================================
# SECTION 1: ECONOMY CONFIGURATION
# =============================================================================

## Starting resources for a new game
const STARTING_DIGIBYTES: int = 200
const STARTING_LIVES: int = 20

## Life penalties when enemies escape
const NORMAL_LIFE_PENALTY: int = 1
const BOSS_LIFE_PENALTY: int = 3

## Sell value as percentage of total investment
const SELL_VALUE_PERCENTAGE: float = 0.5

## Valid game speed settings
const VALID_GAME_SPEEDS: Array[float] = [1.0, 1.5, 2.0]

## Wave completion rewards by wave range
## Format: { threshold: { "base": base_reward, "per_kill": kill_reward } }
const WAVE_REWARDS: Dictionary = {
	10: {"base": 50, "per_kill": 5},
	20: {"base": 75, "per_kill": 8},
	30: {"base": 100, "per_kill": 12},
	40: {"base": 150, "per_kill": 18},
	50: {"base": 200, "per_kill": 25}
}

# =============================================================================
# SECTION 2: TOWER PROGRESSION
# =============================================================================

## Stage constants for readability
const STAGE_IN_TRAINING: int = 0
const STAGE_ROOKIE: int = 1
const STAGE_CHAMPION: int = 2
const STAGE_ULTIMATE: int = 3
const STAGE_MEGA: int = 4
const STAGE_ULTRA: int = 5

## Base max levels per stage (before DP and Origin bonuses)
## Index corresponds to stage: [In-Training, Rookie, Champion, Ultimate, Mega, Ultra]
const BASE_MAX_LEVELS: Array[int] = [10, 20, 35, 50, 70, 100]

## DP (Digivolution Points) bonus levels per point, by stage
## Higher stages benefit more from DP
const DP_BONUS_PER_STAGE: Array[int] = [1, 2, 3, 4, 5, 5]

## Bonus levels gained per evolution from Origin
## Formula: (current_stage - origin_stage) * ORIGIN_BONUS_PER_EVOLUTION
const ORIGIN_BONUS_PER_EVOLUTION: int = 5

## Level up cost multiplier
## Formula: LEVEL_UP_COST_MULTIPLIER * current_level
const LEVEL_UP_COST_MULTIPLIER: int = 5

## Digivolve costs per stage transition
## Index 0 = In-Training->Rookie, 1 = Rookie->Champion, etc.
const DIGIVOLVE_COSTS: Array[int] = [100, 150, 200, 250]

## Stage names for lookup and display
const STAGE_NAMES: Array[String] = [
	"In-Training", "Rookie", "Champion", "Ultimate", "Mega", "Ultra"
]

## Stage name keys for spawn cost lookup (snake_case)
const STAGE_KEYS: Array[String] = [
	"in_training", "rookie", "champion", "ultimate", "mega", "ultra"
]

# =============================================================================
# SECTION 3: COMBAT BALANCE
# =============================================================================

## Damage scaling per level (2% per level)
const LEVEL_SCALE_PER_LEVEL: float = 0.02

## Damage scaling per DP (5% per DP)
const DP_SCALE_PER_DP: float = 0.05

## Critical hit damage multiplier
const CRITICAL_DAMAGE_MULT: float = 2.0

## Base critical hit chance (5%)
const BASE_CRITICAL_CHANCE: float = 0.05

## Metal Empire family crit bonus
const METAL_EMPIRE_CRIT_BONUS: float = 0.05

## Attribute effectiveness multiplier (super effective)
const ATTRIBUTE_SUPER_EFFECTIVE: float = 1.5

## Attribute effectiveness multiplier (neutral)
const ATTRIBUTE_NEUTRAL: float = 1.0

## Maximum armor reduction cap (90%)
const MAX_ARMOR_REDUCTION: float = 0.9

## AoE damage falloff at edge (50% of center damage)
const AOE_EDGE_FALLOFF: float = 0.5

## Chain lightning damage falloff per bounce (50% of previous)
const CHAIN_DAMAGE_FALLOFF: float = 0.5

# =============================================================================
# SECTION 4: GRID CONFIGURATION
# =============================================================================

## Grid dimensions (8x18 serpentine path map)
const GRID_COLS: int = 8
const GRID_ROWS: int = 18

## Tile size in pixels
const TILE_SIZE: int = 64

## Total tower placement slots (from GDD)
const TOTAL_TOWER_SLOTS: int = 87

## Total path tiles (from GDD)
const TOTAL_PATH_TILES: int = 57

## Number of direction changes in path
const PATH_DIRECTION_CHANGES: int = 15

## Path traversal time at 1.0x speed (seconds)
const PATH_TIME_BASE: float = 47.5

# =============================================================================
# SECTION 5: SPAWN COSTS
# =============================================================================

## Spawn costs organized by stage and spawn type
## "random" = any attribute, "specific" = chosen attribute, "free" = FREE attribute
const SPAWN_COSTS: Dictionary = {
	"in_training": {"random": 100, "specific": 150, "free": 200},
	"rookie": {"random": 300, "specific": 450, "free": 600},
	"champion": {"random": 800, "specific": 1200, "free": 1600}
}

## Spawn type multipliers (relative to random)
const SPAWN_TYPE_MULTIPLIERS: Dictionary = {
	"random": 1.0,
	"specific": 1.5,
	"free": 2.0
}

## Resource paths by stage for loading DigimonData
const STAGE_RESOURCE_PATHS: Dictionary = {
	0: "res://resources/digimon/in_training/",
	1: "res://resources/digimon/rookie/",
	2: "res://resources/digimon/champion/",
	3: "res://resources/digimon/ultimate/",
	4: "res://resources/digimon/mega/",
	5: "res://resources/digimon/ultra/"
}

# =============================================================================
# SECTION 6: WAVE TIMING
# =============================================================================

## Intermission times by wave range (seconds)
const INTERMISSION_TIMES: Dictionary = {
	10: 20.0,   # Waves 1-10: 20s
	20: 18.0,   # Waves 11-20: 18s
	40: 15.0,   # Waves 21-40: 15s
	60: 12.0,   # Waves 41-60: 12s
	80: 10.0,   # Waves 61-80: 10s
	100: 8.0,   # Waves 81-100: 8s
	999: 6.0    # Waves 101+: 6s (endless)
}

## Spawn intervals by wave range (seconds)
const SPAWN_INTERVALS: Dictionary = {
	10: 2.0,    # Waves 1-10: 2.0s
	20: 1.8,    # Waves 11-20: 1.8s
	40: 1.5,    # Waves 21-40: 1.5s
	60: 1.2,    # Waves 41-60: 1.2s
	80: 1.0,    # Waves 61-80: 1.0s
	100: 0.8,   # Waves 81-100: 0.8s
	999: 0.6    # Waves 101+: 0.6s (min 0.3s)
}

## Minimum spawn interval in endless mode
const MIN_SPAWN_INTERVAL: float = 0.3

## Main game wave count before endless mode
const MAIN_GAME_WAVES: int = 100

## Bonus life every N waves
const BONUS_LIFE_WAVE_INTERVAL: int = 10

# =============================================================================
# SECTION 7: HELPER METHODS
# =============================================================================

## Get spawn cost for a stage and spawn type
## stage: 0=In-Training, 1=Rookie, 2=Champion
## spawn_type: "random", "specific", or "free"
static func get_spawn_cost(stage: int, spawn_type: String) -> int:
	if stage < 0 or stage >= STAGE_KEYS.size():
		return -1

	var stage_key = STAGE_KEYS[stage]
	if not SPAWN_COSTS.has(stage_key):
		return -1

	var stage_costs = SPAWN_COSTS[stage_key]
	if not stage_costs.has(spawn_type):
		return -1

	return stage_costs[spawn_type]


## Get level up cost for current level
static func get_level_up_cost(current_level: int) -> int:
	return LEVEL_UP_COST_MULTIPLIER * current_level


## Get digivolve cost for current stage
static func get_digivolve_cost(current_stage: int) -> int:
	if current_stage < 0 or current_stage >= DIGIVOLVE_COSTS.size():
		return 0
	return DIGIVOLVE_COSTS[current_stage]


## Get base max level for a stage
static func get_base_max_level(stage: int) -> int:
	if stage < 0 or stage >= BASE_MAX_LEVELS.size():
		return 1
	return BASE_MAX_LEVELS[stage]


## Calculate max level with DP and Origin bonuses
## stage: current evolution stage
## dp: current Digivolution Points
## origin_stage: stage at which Digimon was originally spawned
static func calculate_max_level(stage: int, dp: int, origin_stage: int) -> int:
	if stage < 0 or stage >= BASE_MAX_LEVELS.size():
		return 1

	var base = BASE_MAX_LEVELS[stage]
	var dp_bonus = dp * DP_BONUS_PER_STAGE[stage]
	var origin_bonus = (stage - origin_stage) * ORIGIN_BONUS_PER_EVOLUTION

	return base + dp_bonus + origin_bonus


## Get max reachable stage based on origin
static func get_max_reachable_stage(origin_stage: int) -> int:
	match origin_stage:
		STAGE_IN_TRAINING: return STAGE_CHAMPION
		STAGE_ROOKIE: return STAGE_ULTIMATE
		STAGE_CHAMPION: return STAGE_MEGA
		_: return STAGE_MEGA


## Get stage name for display
static func get_stage_name(stage: int) -> String:
	if stage < 0 or stage >= STAGE_NAMES.size():
		return "Unknown"
	return STAGE_NAMES[stage]


## Get wave reward values for a wave number
## Returns: { "base": int, "per_kill": int }
static func get_wave_reward_values(wave_number: int) -> Dictionary:
	for threshold in WAVE_REWARDS.keys():
		if wave_number <= threshold:
			return WAVE_REWARDS[threshold]

	# Beyond defined thresholds, use highest tier
	return WAVE_REWARDS[50]


## Get intermission time for a wave
static func get_intermission_time(wave_number: int) -> float:
	for threshold in INTERMISSION_TIMES.keys():
		if wave_number <= threshold:
			return INTERMISSION_TIMES[threshold]
	return INTERMISSION_TIMES[999]


## Get spawn interval for a wave
static func get_spawn_interval(wave_number: int) -> float:
	if wave_number > MAIN_GAME_WAVES:
		# Endless mode: gradually decrease interval
		return maxf(MIN_SPAWN_INTERVAL, 0.6 - (wave_number - 100) * 0.01)

	for threshold in SPAWN_INTERVALS.keys():
		if wave_number <= threshold:
			return SPAWN_INTERVALS[threshold]
	return SPAWN_INTERVALS[999]


## Calculate total wave reward
static func calculate_wave_reward(wave_number: int, kills: int) -> int:
	var reward_values = get_wave_reward_values(wave_number)
	var base_reward = reward_values["base"]
	var per_kill_reward = reward_values["per_kill"]

	# Bonus scaling for endless mode
	if wave_number > MAIN_GAME_WAVES:
		var endless_mult = 1.0 + (wave_number - 100) * 0.05
		var kill_mult = 1.0 + (wave_number - 100) * 0.02
		base_reward = int(base_reward * endless_mult)
		per_kill_reward = int(per_kill_reward * kill_mult)

	return base_reward + (kills * per_kill_reward)


## Convert grid position to world position (center of cell)
static func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)


## Convert world position to grid position
static func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)


## Get total grid size in pixels
static func get_grid_pixel_size() -> Vector2:
	return Vector2(GRID_COLS * TILE_SIZE, GRID_ROWS * TILE_SIZE)
