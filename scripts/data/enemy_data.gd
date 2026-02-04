class_name EnemyData
extends Resource
## Resource class for enemy Digimon definitions.
## Contains base stats, type multipliers, and special properties.

## Enemy type categories affecting stats
enum EnemyType {
	SWARM,     ## 1.3x speed, 0.5x HP, 0% armor - weak but fast groups
	STANDARD,  ## 1.0x speed, 1.0x HP, 10% armor - baseline enemy
	TANK,      ## 0.6x speed, 2.5x HP, 40% armor - slow and tough
	SPEEDSTER, ## 2.0x speed, 0.4x HP, 0% armor - glass cannon speed
	FLYING,    ## 1.2x speed, 0.8x HP, 0% armor - aerial units
	REGEN,     ## 0.8x speed, 1.5x HP, 10% armor - heals 2% HP/sec
	SHIELDED,  ## 0.9x speed, 1.0x HP, 60% armor - high armor
	SPLITTER   ## 1.0x speed, 0.8x HP, 0% armor - splits on death
}

## Attribute types matching DigimonData for damage calculations
enum Attribute {
	VACCINE,  ## Strong vs Virus, weak vs Data
	DATA,     ## Strong vs Vaccine, weak vs Virus
	VIRUS,    ## Strong vs Data, weak vs Vaccine
	FREE      ## No weaknesses/strengths
}

## Type multipliers dictionary - speed, hp, armor
const TYPE_MULTIPLIERS: Dictionary = {
	EnemyType.SWARM: {"speed": 1.3, "hp": 0.5, "armor": 0.0},
	EnemyType.STANDARD: {"speed": 1.0, "hp": 1.0, "armor": 0.1},
	EnemyType.TANK: {"speed": 0.6, "hp": 2.5, "armor": 0.4},
	EnemyType.SPEEDSTER: {"speed": 2.0, "hp": 0.4, "armor": 0.0},
	EnemyType.FLYING: {"speed": 1.2, "hp": 0.8, "armor": 0.0},
	EnemyType.REGEN: {"speed": 0.8, "hp": 1.5, "armor": 0.1},
	EnemyType.SHIELDED: {"speed": 0.9, "hp": 1.0, "armor": 0.6},
	EnemyType.SPLITTER: {"speed": 1.0, "hp": 0.8, "armor": 0.0}
}

@export var digimon_name: String = ""
@export var enemy_type: EnemyType = EnemyType.STANDARD
@export var attribute: Attribute = Attribute.DATA

## Base stats (modified by type multipliers)
@export_group("Base Stats")
@export var base_hp: int = 100
@export var base_armor: float = 0.1  ## 0.0 to 1.0 (percentage reduction)
@export var base_speed: float = 1.0  ## Multiplier on movement

## Economy
@export_group("Economy")
@export var reward: int = 5  ## DigiBytes on kill

## Visuals
@export_group("Visuals")
@export var sprite_path: String = ""

## Special properties
@export_group("Special Properties")
@export var regen_percent: float = 0.0  ## HP per second as percentage (e.g., 0.02 = 2%)
@export var split_count: int = 0  ## How many to split into (0 = no split)
@export var is_boss: bool = false  ## Boss enemies take 3 lives when escaping

## Get effective HP after type multipliers
func get_effective_hp() -> int:
	var multipliers = TYPE_MULTIPLIERS[enemy_type]
	return int(base_hp * multipliers["hp"])

## Get effective speed after type multipliers
func get_effective_speed() -> float:
	var multipliers = TYPE_MULTIPLIERS[enemy_type]
	return base_speed * multipliers["speed"]

## Get effective armor after type multipliers
func get_effective_armor() -> float:
	var multipliers = TYPE_MULTIPLIERS[enemy_type]
	# Use type's armor value, not base_armor multiplied
	# Type armor overrides base armor
	return multipliers["armor"]

## Get the attribute multiplier when this enemy is attacked by a tower with given attribute
## Returns 1.5 for super effective, 0.75 for not very effective, 1.0 for neutral
static func get_attribute_multiplier(attacker_attr: int, defender_attr: Attribute) -> float:
	# FREE has no weaknesses or strengths
	if attacker_attr == Attribute.FREE or defender_attr == Attribute.FREE:
		return 1.0

	# Attribute triangle: Vaccine > Virus > Data > Vaccine
	match attacker_attr:
		Attribute.VACCINE:
			match defender_attr:
				Attribute.VIRUS: return 1.5
				Attribute.DATA: return 0.75
		Attribute.DATA:
			match defender_attr:
				Attribute.VACCINE: return 1.5
				Attribute.VIRUS: return 0.75
		Attribute.VIRUS:
			match defender_attr:
				Attribute.DATA: return 1.5
				Attribute.VACCINE: return 0.75

	return 1.0

## Get regen rate per second (0.02 base for REGEN type)
func get_regen_rate() -> float:
	if enemy_type == EnemyType.REGEN:
		return regen_percent if regen_percent > 0 else 0.02
	return regen_percent

## Check if this enemy splits on death
func does_split() -> bool:
	return enemy_type == EnemyType.SPLITTER or split_count > 0

## Get the number of enemies to spawn on split
func get_split_count() -> int:
	if enemy_type == EnemyType.SPLITTER and split_count <= 0:
		return 2  # Default split count for splitter type
	return split_count

## Get enemy type name as string
func get_type_name() -> String:
	match enemy_type:
		EnemyType.SWARM: return "Swarm"
		EnemyType.STANDARD: return "Standard"
		EnemyType.TANK: return "Tank"
		EnemyType.SPEEDSTER: return "Speedster"
		EnemyType.FLYING: return "Flying"
		EnemyType.REGEN: return "Regen"
		EnemyType.SHIELDED: return "Shielded"
		EnemyType.SPLITTER: return "Splitter"
		_: return "Unknown"

## Get attribute name as string
func get_attribute_name() -> String:
	match attribute:
		Attribute.VACCINE: return "Vaccine"
		Attribute.DATA: return "Data"
		Attribute.VIRUS: return "Virus"
		Attribute.FREE: return "Free"
		_: return "Unknown"
