class_name EnemyModifier
extends RefCounted
## Handles special modifiers for enemies from Wave 50+.
## Modifiers provide additional challenge by buffing enemy stats.

enum ModifierType {
	NONE,     ## No modifier
	ENRAGED,  ## +50% speed, +25% damage dealt to base
	ARMORED,  ## +30% armor
	HASTY,    ## +100% speed, -30% HP
	VAMPIRIC, ## Heals 10% of damage dealt to base (when reaching end)
	GIANT     ## +200% HP, +50% size, -20% speed
}

## Modifier stat adjustments
const MODIFIER_STATS: Dictionary = {
	ModifierType.NONE: {
		"speed_mult": 1.0,
		"hp_mult": 1.0,
		"armor_add": 0.0,
		"size_mult": 1.0,
		"lifesteal": 0.0,
		"damage_mult": 1.0
	},
	ModifierType.ENRAGED: {
		"speed_mult": 1.5,
		"hp_mult": 1.0,
		"armor_add": 0.0,
		"size_mult": 1.0,
		"lifesteal": 0.0,
		"damage_mult": 1.25  # +25% damage dealt to base
	},
	ModifierType.ARMORED: {
		"speed_mult": 1.0,
		"hp_mult": 1.0,
		"armor_add": 0.3,  # +30% armor
		"size_mult": 1.0,
		"lifesteal": 0.0,
		"damage_mult": 1.0
	},
	ModifierType.HASTY: {
		"speed_mult": 2.0,  # +100% speed
		"hp_mult": 0.7,     # -30% HP
		"armor_add": 0.0,
		"size_mult": 1.0,
		"lifesteal": 0.0,
		"damage_mult": 1.0
	},
	ModifierType.VAMPIRIC: {
		"speed_mult": 1.0,
		"hp_mult": 1.0,
		"armor_add": 0.0,
		"size_mult": 1.0,
		"lifesteal": 0.1,  # 10% lifesteal
		"damage_mult": 1.0
	},
	ModifierType.GIANT: {
		"speed_mult": 0.8,  # -20% speed
		"hp_mult": 3.0,     # +200% HP
		"armor_add": 0.0,
		"size_mult": 1.5,   # +50% size
		"lifesteal": 0.0,
		"damage_mult": 1.0
	}
}

## Modifier visual colors for identification
const MODIFIER_COLORS: Dictionary = {
	ModifierType.NONE: Color.WHITE,
	ModifierType.ENRAGED: Color.RED,
	ModifierType.ARMORED: Color.GRAY,
	ModifierType.HASTY: Color.YELLOW,
	ModifierType.VAMPIRIC: Color.PURPLE,
	ModifierType.GIANT: Color.ORANGE
}

## Apply a modifier to an enemy's stats
## Returns a dictionary with modified values
static func get_modifier_stats(modifier_type: ModifierType) -> Dictionary:
	if MODIFIER_STATS.has(modifier_type):
		return MODIFIER_STATS[modifier_type].duplicate()
	return MODIFIER_STATS[ModifierType.NONE].duplicate()

## Get the display color for a modifier
static func get_modifier_color(modifier_type: ModifierType) -> Color:
	if MODIFIER_COLORS.has(modifier_type):
		return MODIFIER_COLORS[modifier_type]
	return Color.WHITE

## Get the name of a modifier
static func get_modifier_name(modifier_type: ModifierType) -> String:
	match modifier_type:
		ModifierType.NONE: return "None"
		ModifierType.ENRAGED: return "Enraged"
		ModifierType.ARMORED: return "Armored"
		ModifierType.HASTY: return "Hasty"
		ModifierType.VAMPIRIC: return "Vampiric"
		ModifierType.GIANT: return "Giant"
		_: return "Unknown"

## Get a random modifier for waves 50+
static func get_random_modifier(wave_number: int) -> ModifierType:
	if wave_number < 50:
		return ModifierType.NONE

	# Higher waves have higher chance of stronger modifiers
	var roll = randf()
	var modifier_chance = minf(0.8, 0.3 + (wave_number - 50) * 0.01)  # Cap at 80%

	if roll > modifier_chance:
		return ModifierType.NONE

	# Equal chance for each modifier type
	var modifiers = [
		ModifierType.ENRAGED,
		ModifierType.ARMORED,
		ModifierType.HASTY,
		ModifierType.VAMPIRIC,
		ModifierType.GIANT
	]

	return modifiers[randi() % modifiers.size()]

## Get description of a modifier
static func get_modifier_description(modifier_type: ModifierType) -> String:
	match modifier_type:
		ModifierType.NONE:
			return "No special modifier"
		ModifierType.ENRAGED:
			return "+50% speed, +25% damage to base"
		ModifierType.ARMORED:
			return "+30% armor"
		ModifierType.HASTY:
			return "+100% speed, -30% HP"
		ModifierType.VAMPIRIC:
			return "Heals 10% of base damage dealt"
		ModifierType.GIANT:
			return "+200% HP, +50% size, -20% speed"
		_:
			return "Unknown modifier"
