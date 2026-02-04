class_name DamageCalculator
extends RefCounted
## Calculates damage with all modifiers including level scaling, DP bonus,
## attribute effectiveness, armor reduction, and critical hits.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const TraitEffect = preload("res://scripts/data/trait_effect.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")

## Damage result structure
## Returns a Dictionary with:
## - damage: int (final damage after all calculations)
## - is_critical: bool (whether this was a critical hit)
## - damage_type: String (physical, fire, ice, holy, dark, etc.)
## - base_damage: float (damage before armor)
## - attribute_mult: float (attribute effectiveness multiplier)

## Base constants for damage scaling
const LEVEL_SCALE_PER_LEVEL: float = 0.02      ## +2% damage per level
const DP_SCALE_PER_DP: float = 0.05            ## +5% damage per DP
const CRITICAL_DAMAGE_MULT: float = 2.0        ## Critical hits deal 2x damage
const BASE_CRITICAL_CHANCE: float = 0.05       ## 5% base crit chance


## Calculate final damage from attacker to target
## attacker: The attacking DigimonTower
## target: The target EnemyDigimon
## base_damage: Base damage value (from digimon_data)
## Returns: Dictionary with damage details
static func calculate_damage(
	attacker: Node,
	target: Node,
	base_damage: int
) -> Dictionary:
	var result = {
		"damage": 0,
		"is_critical": false,
		"damage_type": "physical",
		"base_damage": float(base_damage),
		"attribute_mult": 1.0,
		"armor_reduction": 0.0,
		"level_mult": 1.0,
		"dp_mult": 1.0
	}

	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return result

	var damage = float(base_damage)

	# 1. Apply level scaling: damage * (1 + level * 0.02)
	var attacker_level = _get_attacker_level(attacker)
	var level_multiplier = 1.0 + (attacker_level - 1) * LEVEL_SCALE_PER_LEVEL
	damage *= level_multiplier
	result["level_mult"] = level_multiplier

	# 2. Apply DP bonus: damage * (1 + dp * 0.05)
	var attacker_dp = _get_attacker_dp(attacker)
	var dp_multiplier = 1.0 + attacker_dp * DP_SCALE_PER_DP
	damage *= dp_multiplier
	result["dp_mult"] = dp_multiplier

	# 3. Apply attribute multiplier
	var attribute_mult = _get_attribute_multiplier(attacker, target)
	damage *= attribute_mult
	result["attribute_mult"] = attribute_mult
	result["base_damage"] = damage  # Damage before armor

	# 4. Apply armor reduction: damage * (1 - target.current_armor)
	var armor = _get_target_armor(target)

	# Check for armor shred effects on target
	var armor_shred = _get_armor_shred(target)
	armor = maxf(0.0, armor - armor_shred)

	var armor_multiplier = 1.0 - armor
	damage *= armor_multiplier
	result["armor_reduction"] = armor

	# 5. Check for critical hit
	var crit_chance = _get_critical_chance(attacker)
	var is_critical = randf() < crit_chance
	if is_critical:
		damage *= CRITICAL_DAMAGE_MULT
		result["is_critical"] = true

	# 6. Set damage type
	result["damage_type"] = _get_damage_type(attacker)

	# Floor the final damage (minimum 1)
	result["damage"] = maxi(1, int(damage))

	return result


## Calculate damage without applying (for previews/tooltips)
static func preview_damage(
	attacker: Node,
	target: Node,
	base_damage: int
) -> Dictionary:
	var result = calculate_damage(attacker, target, base_damage)
	# Remove random critical for preview - show average
	if result["is_critical"]:
		result["damage"] = int(result["damage"] / CRITICAL_DAMAGE_MULT)
		result["is_critical"] = false
	return result


## Apply a status effect from attacker to target
## attacker: The attacking tower
## target: The target enemy
## Returns: true if effect was successfully applied
static func apply_effect(attacker: Node, target: Node) -> bool:
	if not is_instance_valid(attacker) or not is_instance_valid(target):
		return false

	# Get effect data from attacker's digimon_data
	var digimon_data = _get_digimon_data(attacker)
	if not digimon_data:
		return false

	# Check if attacker has an effect
	if digimon_data.effect_type == "" or digimon_data.effect_chance <= 0:
		return false

	# Roll for effect chance
	if randf() > digimon_data.effect_chance:
		return false

	# Try to apply effect to target
	if target.has_method("apply_effect"):
		# Try to load the TraitEffect resource based on effect type
		var effect = _create_effect_from_data(digimon_data)
		if effect:
			target.apply_effect(effect)
			return true
		else:
			# Fallback: call with string parameters
			target.apply_effect(
				digimon_data.effect_type,
				digimon_data.effect_duration,
				attacker
			)
			return true

	return false


## Apply effect with a specific TraitEffect resource
static func apply_trait_effect(target: Node, effect: TraitEffect, source: Node = null) -> bool:
	if not is_instance_valid(target) or not effect:
		return false

	if target.has_method("apply_effect"):
		target.apply_effect(effect)

		# Emit event via EventBus
		var event_bus = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
		if event_bus:
			event_bus.enemy_effect_applied.emit(
				target,
				effect.effect_name,
				effect.duration,
				source
			)

		return true

	return false


## Calculate damage for AoE attacks (may have falloff)
static func calculate_aoe_damage(
	attacker: Node,
	target: Node,
	base_damage: int,
	distance_from_center: float,
	aoe_radius: float,
	falloff: float = 0.5  ## Damage at edge as percentage of center damage
) -> Dictionary:
	# Calculate base damage first
	var result = calculate_damage(attacker, target, base_damage)

	# Apply distance falloff
	if distance_from_center > 0 and aoe_radius > 0:
		var distance_ratio = clampf(distance_from_center / aoe_radius, 0.0, 1.0)
		var falloff_mult = lerpf(1.0, falloff, distance_ratio)
		result["damage"] = maxi(1, int(result["damage"] * falloff_mult))
		result["aoe_falloff"] = falloff_mult

	return result


## Calculate chain lightning damage with falloff per bounce
static func calculate_chain_damage(
	attacker: Node,
	target: Node,
	base_damage: int,
	chain_index: int,
	damage_falloff: float = 0.5  ## Each chain deals this % of previous
) -> Dictionary:
	# Calculate base damage first
	var result = calculate_damage(attacker, target, base_damage)

	# Apply chain falloff
	if chain_index > 0:
		var chain_mult = pow(damage_falloff, chain_index)
		result["damage"] = maxi(1, int(result["damage"] * chain_mult))
		result["chain_falloff"] = chain_mult
		result["chain_index"] = chain_index

	return result


# =============================================================================
# HELPER METHODS
# =============================================================================

## Get attacker's current level
static func _get_attacker_level(attacker: Node) -> int:
	if "current_level" in attacker:
		return attacker.current_level
	return 1


## Get attacker's current DP
static func _get_attacker_dp(attacker: Node) -> int:
	if "current_dp" in attacker:
		return attacker.current_dp
	return 0


## Get attribute multiplier between attacker and target
static func _get_attribute_multiplier(attacker: Node, target: Node) -> float:
	var attacker_attr = _get_attacker_attribute(attacker)
	var target_attr = _get_target_attribute(target)

	if attacker_attr < 0 or target_attr < 0:
		return 1.0

	# Use DigimonData's static method if available
	return DigimonData.get_attribute_multiplier(attacker_attr, target_attr)


## Get attacker's attribute
static func _get_attacker_attribute(attacker: Node) -> int:
	var digimon_data = _get_digimon_data(attacker)
	if digimon_data:
		return digimon_data.attribute
	return -1


## Get target's attribute
static func _get_target_attribute(target: Node) -> int:
	if target.has_method("get_attribute"):
		return target.get_attribute()
	if "enemy_data" in target and target.enemy_data:
		return target.enemy_data.attribute
	return -1


## Get target's current armor value
static func _get_target_armor(target: Node) -> float:
	if "current_armor" in target:
		return clampf(target.current_armor, 0.0, 0.9)  # Cap at 90%
	return 0.0


## Get armor shred amount from active effects
static func _get_armor_shred(target: Node) -> float:
	if "active_effects" in target:
		var effects = target.active_effects
		if effects.has("armor_shred") or effects.has("Armor Shred"):
			var shred_data = effects.get("armor_shred", effects.get("Armor Shred", {}))
			return shred_data.get("reduction", 0.0)
	return 0.0


## Get critical hit chance for attacker
static func _get_critical_chance(attacker: Node) -> float:
	# Base crit chance
	var crit_chance = BASE_CRITICAL_CHANCE

	# Check for crit buffs from traits or other sources
	var digimon_data = _get_digimon_data(attacker)
	if digimon_data:
		# Some families might have higher crit (e.g., Metal Empire)
		if digimon_data.family == DigimonData.Family.METAL_EMPIRE:
			crit_chance += 0.05  # +5% crit for Metal Empire

	return crit_chance


## Get damage type from attacker
static func _get_damage_type(attacker: Node) -> String:
	var digimon_data = _get_digimon_data(attacker)
	if not digimon_data:
		return "physical"

	# Check effect type first
	if digimon_data.effect_type != "":
		return digimon_data.effect_type.to_lower()

	# Determine by family
	match digimon_data.family:
		DigimonData.Family.DRAGONS_ROAR:
			return "fire"
		DigimonData.Family.DEEP_SAVERS:
			return "water"
		DigimonData.Family.VIRUS_BUSTERS:
			return "holy"
		DigimonData.Family.NIGHTMARE_SOLDIERS:
			return "dark"
		DigimonData.Family.METAL_EMPIRE:
			return "electric"
		DigimonData.Family.WIND_GUARDIANS:
			return "wind"
		DigimonData.Family.JUNGLE_TROOPERS:
			return "nature"
		DigimonData.Family.NATURE_SPIRITS:
			return "earth"
		_:
			return "physical"


## Get DigimonData from attacker
static func _get_digimon_data(attacker: Node) -> DigimonData:
	if "digimon_data" in attacker:
		return attacker.digimon_data
	return null


## Create a TraitEffect resource from DigimonData effect settings
static func _create_effect_from_data(digimon_data: DigimonData) -> TraitEffect:
	if not digimon_data or digimon_data.effect_type == "":
		return null

	var effect = TraitEffect.new()
	effect.effect_name = digimon_data.effect_type
	effect.duration = digimon_data.effect_duration

	# Set effect type based on name
	match digimon_data.effect_type.to_lower():
		"burn":
			effect.effect_type = TraitEffect.EffectType.BURN
			effect.damage_per_tick = digimon_data.base_damage * 0.1
			effect.tick_interval = 1.0
			effect.effect_color = Color.ORANGE_RED
		"freeze":
			effect.effect_type = TraitEffect.EffectType.FREEZE
			effect.stun_duration = 0.5
			effect.slow_percent = 0.5
			effect.effect_color = Color.CYAN
		"slow":
			effect.effect_type = TraitEffect.EffectType.SLOW
			effect.slow_percent = 0.3
			effect.effect_color = Color.LIGHT_BLUE
		"poison":
			effect.effect_type = TraitEffect.EffectType.POISON
			effect.damage_per_tick = digimon_data.base_damage * 0.05
			effect.tick_interval = 0.5
			effect.heal_reduction_percent = 0.5
			effect.effect_color = Color.PURPLE
		"fear":
			effect.effect_type = TraitEffect.EffectType.FEAR
			effect.effect_color = Color.DARK_VIOLET
		"armor_shred", "shred":
			effect.effect_type = TraitEffect.EffectType.ARMOR_SHRED
			effect.armor_reduction_percent = 0.2
			effect.effect_color = Color.DARK_GRAY
		"root":
			effect.effect_type = TraitEffect.EffectType.ROOT
			effect.effect_color = Color.DARK_GREEN
		"knockback":
			effect.effect_type = TraitEffect.EffectType.KNOCKBACK
			effect.knockback_distance = 1.0
			effect.duration = 0.0  # Instant
		_:
			# Default to slow
			effect.effect_type = TraitEffect.EffectType.SLOW
			effect.slow_percent = 0.2

	return effect
