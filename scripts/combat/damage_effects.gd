class_name DamageEffects
extends RefCounted
## Damage-over-time (DoT) effect processors.
## Handles: Burn, Poison, Bleed
##
## These effects deal periodic damage to enemies over time.
## Damage is calculated per tick and scales with stacks.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const TraitEffect = preload("res://scripts/data/trait_effect.gd")


# =============================================================================
# UTILITY FUNCTIONS (inlined to avoid circular dependency with StatusEffects)
# =============================================================================

## Apply DoT damage to an enemy
static func _apply_dot_damage(enemy: Node, damage: float, damage_type: String, source: Node) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, source, damage_type)
	elif "current_hp" in enemy:
		enemy.current_hp -= damage
		if enemy.current_hp <= 0 and enemy.has_method("die"):
			enemy.die()


## Flash the enemy sprite with a color
static func _flash_effect_color(enemy: Node, color: Color) -> void:
	if not is_instance_valid(enemy):
		return

	if "sprite" in enemy and enemy.sprite:
		var original = enemy.sprite.modulate
		enemy.sprite.modulate = color

		if enemy.has_method("create_tween"):
			var tween = enemy.create_tween()
			tween.tween_property(enemy.sprite, "modulate", original, 0.15)


# =============================================================================
# DOT EFFECT PROCESSORS
# =============================================================================

## Process burn damage over time
## Burns deal fire damage at regular intervals
static func process_burn(enemy: Node, effect: TraitEffect, data: Dictionary, delta: float) -> void:
	if effect.damage_per_tick <= 0 or effect.tick_interval <= 0:
		return

	# Update tick timer
	if not "_effect_tick_timers" in enemy:
		return

	var effect_key = effect.effect_name if effect.effect_name != "" else "Burn"
	if not enemy._effect_tick_timers.has(effect_key):
		enemy._effect_tick_timers[effect_key] = 0.0

	enemy._effect_tick_timers[effect_key] += delta

	# Check if tick should occur
	if enemy._effect_tick_timers[effect_key] >= effect.tick_interval:
		enemy._effect_tick_timers[effect_key] -= effect.tick_interval

		# Calculate damage with stacks
		var damage = effect.damage_per_tick * data["stacks"]

		# Apply damage
		_apply_dot_damage(enemy, damage, "burn", data.get("source"))

		# Visual feedback
		_flash_effect_color(enemy, effect.effect_color)


## Process poison damage and heal reduction
## Poison deals nature damage and reduces incoming healing
static func process_poison(enemy: Node, effect: TraitEffect, data: Dictionary, delta: float) -> void:
	if effect.damage_per_tick <= 0 or effect.tick_interval <= 0:
		return

	# Update tick timer
	if not "_effect_tick_timers" in enemy:
		return

	var effect_key = effect.effect_name if effect.effect_name != "" else "Poison"
	if not enemy._effect_tick_timers.has(effect_key):
		enemy._effect_tick_timers[effect_key] = 0.0

	enemy._effect_tick_timers[effect_key] += delta

	# Check if tick should occur
	if enemy._effect_tick_timers[effect_key] >= effect.tick_interval:
		enemy._effect_tick_timers[effect_key] -= effect.tick_interval

		# Calculate damage with stacks
		var damage = effect.damage_per_tick * data["stacks"]

		# Apply damage
		_apply_dot_damage(enemy, damage, "poison", data.get("source"))

		# Visual feedback
		_flash_effect_color(enemy, effect.effect_color)

	# Note: Heal reduction is applied automatically when enemy regenerates
	# by checking for poison in active_effects


## Process bleed damage over time
## Bleed deals physical damage that ignores armor
static func process_bleed(enemy: Node, effect: TraitEffect, data: Dictionary, delta: float) -> void:
	if effect.damage_per_tick <= 0 or effect.tick_interval <= 0:
		return

	# Update tick timer
	if not "_effect_tick_timers" in enemy:
		return

	var effect_key = effect.effect_name if effect.effect_name != "" else "Bleed"
	if not enemy._effect_tick_timers.has(effect_key):
		enemy._effect_tick_timers[effect_key] = 0.0

	enemy._effect_tick_timers[effect_key] += delta

	# Check if tick should occur
	if enemy._effect_tick_timers[effect_key] >= effect.tick_interval:
		enemy._effect_tick_timers[effect_key] -= effect.tick_interval

		# Calculate damage with stacks - bleed typically stacks more aggressively
		var damage = effect.damage_per_tick * data["stacks"]

		# Apply damage as "true" damage (ignores armor)
		_apply_dot_damage(enemy, damage, "bleed", data.get("source"))

		# Visual feedback - blood red
		_flash_effect_color(enemy, effect.effect_color)


## Calculate total DoT damage remaining for an effect
static func get_remaining_dot_damage(effect: TraitEffect, data: Dictionary) -> float:
	if effect.damage_per_tick <= 0 or effect.tick_interval <= 0:
		return 0.0

	var remaining_time = data.get("remaining_time", 0.0)
	var remaining_ticks = floori(remaining_time / effect.tick_interval)
	var stacks = data.get("stacks", 1)

	return effect.damage_per_tick * remaining_ticks * stacks


## Check if an effect is a DoT effect
static func is_dot_effect(effect_type: TraitEffect.EffectType) -> bool:
	match effect_type:
		TraitEffect.EffectType.BURN, TraitEffect.EffectType.POISON:
			return true
		_:
			return false


## Get the damage type string for a DoT effect
static func get_damage_type(effect_type: TraitEffect.EffectType) -> String:
	match effect_type:
		TraitEffect.EffectType.BURN:
			return "burn"
		TraitEffect.EffectType.POISON:
			return "poison"
		_:
			return "dot"
