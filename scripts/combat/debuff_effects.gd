class_name DebuffEffects
extends RefCounted
## Debuff effect processors.
## Handles: Armor Shred, Weakness, Vulnerability, Instakill
##
## These effects reduce enemy defenses or apply special conditions.
## Debuffs make enemies take more damage or become more susceptible to attacks.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const TraitEffect = preload("res://scripts/data/trait_effect.gd")


## Process armor shred effect
## Reduces enemy's armor/defense, making them take more damage
static func process_armor_shred(_enemy: Node, effect: TraitEffect, data: Dictionary, _delta: float) -> void:
	# Calculate total armor reduction with stacks
	var reduction = effect.armor_reduction_percent * data["stacks"]

	# Cap at 50% armor reduction
	reduction = minf(reduction, 0.5)

	# Store in data for damage calculations
	data["reduction"] = reduction


## Apply instakill chance (called on first application)
static func apply_instakill(enemy: Node, effect: TraitEffect) -> void:
	# Roll for instant kill
	if randf() < effect.instakill_chance:
		if enemy.has_method("take_damage"):
			# Deal massive damage to kill
			enemy.take_damage(999999, null, "execute")
		elif "current_hp" in enemy:
			enemy.current_hp = 0


## Get total armor reduction on enemy (combined from all armor shred effects)
static func get_total_armor_reduction(enemy: Node) -> float:
	if not is_instance_valid(enemy):
		return 0.0

	if not "active_effects" in enemy:
		return 0.0

	var total_reduction: float = 0.0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect and effect.effect_type == TraitEffect.EffectType.ARMOR_SHRED:
			total_reduction += data.get("reduction", 0.0)

	# Cap at 80% total armor reduction
	return minf(total_reduction, 0.8)


## Calculate damage after armor reduction modifiers
## base_damage: The original damage amount
## enemy: The target enemy
## Returns: Modified damage amount
static func calculate_modified_damage(base_damage: float, enemy: Node) -> float:
	if not is_instance_valid(enemy):
		return base_damage

	var armor_reduction = get_total_armor_reduction(enemy)
	var vulnerability = get_vulnerability_modifier(enemy)

	# Armor shred increases damage taken
	var shred_multiplier = 1.0 + armor_reduction

	# Vulnerability further increases damage
	var total_multiplier = shred_multiplier * vulnerability

	return base_damage * total_multiplier


## Get vulnerability modifier on enemy
## Returns multiplier (1.0 = normal, >1.0 = takes more damage)
static func get_vulnerability_modifier(enemy: Node) -> float:
	if not is_instance_valid(enemy):
		return 1.0

	if not "active_effects" in enemy:
		return 1.0

	var vulnerability: float = 1.0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		# Check for vulnerability-type effects (custom effect names)
		if effect and "vulnerability" in effect_key.to_lower():
			var stacks = data.get("stacks", 1)
			# Each stack increases damage taken by a percentage
			vulnerability += 0.1 * stacks  # 10% per stack

	return vulnerability


## Get weakness modifier for specific damage type
## enemy: The target enemy
## damage_type: Type of damage being dealt (fire, ice, etc.)
## Returns multiplier (1.0 = normal, >1.0 = weak to this type)
static func get_weakness_modifier(enemy: Node, damage_type: String) -> float:
	if not is_instance_valid(enemy):
		return 1.0

	if not "active_effects" in enemy:
		return 1.0

	var weakness: float = 1.0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		# Check for weakness effects that match the damage type
		if "weakness" in effect_key.to_lower() and damage_type.to_lower() in effect_key.to_lower():
			var stacks = data.get("stacks", 1)
			weakness += 0.25 * stacks  # 25% weakness per stack

	return weakness


## Check if enemy has any active debuffs
static func has_any_debuff(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return false

	if not "active_effects" in enemy:
		return false

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect and is_debuff_effect(effect.effect_type):
			return true

	return false


## Check if effect is a debuff effect
static func is_debuff_effect(effect_type: TraitEffect.EffectType) -> bool:
	match effect_type:
		TraitEffect.EffectType.ARMOR_SHRED, TraitEffect.EffectType.INSTAKILL:
			return true
		_:
			return false


## Get count of debuff stacks on enemy
static func get_total_debuff_stacks(enemy: Node) -> int:
	if not is_instance_valid(enemy):
		return 0

	if not "active_effects" in enemy:
		return 0

	var total_stacks: int = 0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect and is_debuff_effect(effect.effect_type):
			total_stacks += data.get("stacks", 1)

	return total_stacks


## Apply a generic weakness debuff
## enemy: The target enemy
## weakness_type: Type of weakness (fire, ice, physical, etc.)
## duration: How long the weakness lasts
## stacks: Number of stacks to apply
static func apply_weakness(enemy: Node, weakness_type: String, duration: float, stacks: int = 1) -> void:
	if not is_instance_valid(enemy):
		return

	if not "active_effects" in enemy:
		return

	var effect_key = "weakness_" + weakness_type.to_lower()

	if enemy.active_effects.has(effect_key):
		var existing = enemy.active_effects[effect_key]
		existing["remaining_time"] = duration
		existing["stacks"] = mini(existing["stacks"] + stacks, 5)  # Max 5 stacks
	else:
		enemy.active_effects[effect_key] = {
			"effect": null,  # Custom effect, not TraitEffect resource
			"remaining_time": duration,
			"stacks": stacks,
			"weakness_type": weakness_type
		}
