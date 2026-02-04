class_name DigimonData
extends Resource
## Resource class defining a Digimon's base stats, abilities, and evolution paths.
## Used as data container for all Digimon in the game.

## Evolution stage constants (Fresh removed - game starts at In-Training)
enum Stage {
	IN_TRAINING = 0, ## Baby II - Starting stage, weak attacks, cannot merge
	ROOKIE = 1,      ## Child - First merge-capable form
	CHAMPION = 2,    ## Adult - Standard evolved form
	ULTIMATE = 3,    ## Perfect - Powerful evolved form
	MEGA = 4,        ## Ultimate - Near-peak power
	ULTRA = 5        ## Super Ultimate - DNA fusion result
}

## Attribute types for damage calculations and merge compatibility
enum Attribute {
	VACCINE,  ## Strong vs Virus, weak vs Data
	DATA,     ## Strong vs Vaccine, weak vs Virus
	VIRUS,    ## Strong vs Data, weak vs Vaccine
	FREE      ## No weaknesses/strengths, can merge with any attribute
}

## Digimon family/field for tower category
enum Family {
	DRAGONS_ROAR,      ## Artillery - high damage, fire
	NATURE_SPIRITS,    ## Balanced - versatile
	VIRUS_BUSTERS,     ## Support/Magic - holy, buffs
	NIGHTMARE_SOLDIERS,## Debuff/Control - slows, weakens
	METAL_EMPIRE,      ## High-Tech - consistent damage
	DEEP_SAVERS,       ## Splash/AoE - water, crowd control
	WIND_GUARDIANS,    ## Anti-Air - fast, aerial
	JUNGLE_TROOPERS,   ## Barracks/Summon - traps, swarms
	UNKNOWN            ## Special/Unclassified
}

@export var digimon_name: String = ""
@export var stage: Stage = Stage.ROOKIE
@export var attribute: Attribute = Attribute.DATA
@export var family: Family = Family.UNKNOWN

## Base combat stats
@export_group("Combat Stats")
@export var base_damage: int = 10
@export var attack_speed: float = 1.0  ## Attacks per second
@export var attack_range: float = 2.0  ## Tile radius

## Status effect applied on attack
@export_group("Status Effect")
@export var effect_type: String = ""  ## Burn/Freeze/Slow/etc
@export var effect_chance: float = 0.0  ## 0.0 to 1.0
@export var effect_duration: float = 0.0

## Special ability (unlocked at Ultimate+)
@export_group("Special Ability")
@export var special_ability_name: String = ""
@export var special_ability_description: String = ""
@export var special_cooldown: float = 0.0

## Evolution configuration
@export_group("Evolution")
@export var evolutions: Array[Resource] = []  ## Array of EvolutionPath resources
@export var evolves_from: String = ""  ## Name of previous form (for reference)

## DNA Digivolution (for Mega-level Digimon)
@export_group("DNA Digivolution")
@export var dna_partner: String = ""  ## Name of compatible DNA partner
@export var dna_result: String = ""   ## Name of resulting Ultra Digimon

## Returns true if this Digimon can participate in combat
## All stages can attack, but In-Training is weak
func can_attack() -> bool:
	return true

## Returns true if this Digimon can merge with others
## Requires Rookie stage or higher
func can_merge() -> bool:
	return stage >= Stage.ROOKIE

## Returns true if this Digimon has a special ability
func has_special_ability() -> bool:
	return stage >= Stage.ULTIMATE and special_ability_name != ""

## Returns true if this Digimon can DNA Digivolve
func can_dna_digivolve() -> bool:
	return stage == Stage.MEGA and dna_partner != ""

## Get the attribute damage multiplier against a target attribute
static func get_attribute_multiplier(attacker: Attribute, defender: Attribute) -> float:
	if attacker == Attribute.FREE or defender == Attribute.FREE:
		return 1.0

	match attacker:
		Attribute.VACCINE:
			match defender:
				Attribute.VIRUS: return 1.5
				Attribute.DATA: return 0.75
		Attribute.DATA:
			match defender:
				Attribute.VACCINE: return 1.5
				Attribute.VIRUS: return 0.75
		Attribute.VIRUS:
			match defender:
				Attribute.DATA: return 1.5
				Attribute.VACCINE: return 0.75

	return 1.0  ## Same attribute or unhandled case

## Check if two attributes can merge
static func can_attributes_merge(attr_a: Attribute, attr_b: Attribute) -> bool:
	# FREE can merge with anything
	if attr_a == Attribute.FREE or attr_b == Attribute.FREE:
		return true
	# Otherwise must be same attribute
	return attr_a == attr_b

## Get family name as string for display
func get_family_name() -> String:
	match family:
		Family.DRAGONS_ROAR: return "Dragon's Roar"
		Family.NATURE_SPIRITS: return "Nature Spirits"
		Family.VIRUS_BUSTERS: return "Virus Busters"
		Family.NIGHTMARE_SOLDIERS: return "Nightmare Soldiers"
		Family.METAL_EMPIRE: return "Metal Empire"
		Family.DEEP_SAVERS: return "Deep Savers"
		Family.WIND_GUARDIANS: return "Wind Guardians"
		Family.JUNGLE_TROOPERS: return "Jungle Troopers"
		_: return "Unknown"

## Get stage name as string for display
func get_stage_name() -> String:
	match stage:
		Stage.IN_TRAINING: return "In-Training"
		Stage.ROOKIE: return "Rookie"
		Stage.CHAMPION: return "Champion"
		Stage.ULTIMATE: return "Ultimate"
		Stage.MEGA: return "Mega"
		Stage.ULTRA: return "Ultra"
		_: return "Unknown"

## Get attribute name as string for display
func get_attribute_name() -> String:
	match attribute:
		Attribute.VACCINE: return "Vaccine"
		Attribute.DATA: return "Data"
		Attribute.VIRUS: return "Virus"
		Attribute.FREE: return "Free"
		_: return "Unknown"
