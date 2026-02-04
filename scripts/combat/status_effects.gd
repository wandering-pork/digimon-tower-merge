class_name StatusEffects
extends RefCounted
## Status effect manager for enemies.
## Handles applying, processing, and removing status effects.
##
## Split into categories:
##   - status_effects.gd - Base interface, registry, common utilities
##   - damage_effects.gd - Burn, poison, bleed (DoT effects)
##   - control_effects.gd - Stun, slow, freeze, fear, root
##   - debuff_effects.gd - Armor shred, weakness, vulnerability

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const TraitEffect = preload("res://scripts/data/trait_effect.gd")
const DamageEffects = preload("res://scripts/combat/damage_effects.gd")
const ControlEffects = preload("res://scripts/combat/control_effects.gd")
const DebuffEffects = preload("res://scripts/combat/debuff_effects.gd")

## Effect data structure stored on enemies:
## {
##   "effect": TraitEffect resource,
##   "remaining_time": float,
##   "stacks": int,
##   "source": Node (optional)
## }


## Apply a TraitEffect to an enemy
## enemy: The target enemy
## effect: The TraitEffect resource to apply
## source: The source node that applied this effect (optional)
static func apply_effect(enemy: Node, effect: TraitEffect, source: Node = null) -> void:
	if not is_instance_valid(enemy) or not effect:
		return

	if "is_dead" in enemy and enemy.is_dead:
		return

	# Ensure enemy has the required properties
	if not "active_effects" in enemy:
		return

	var effect_key = effect.effect_name
	if effect_key == "":
		effect_key = TraitEffect.EffectType.keys()[effect.effect_type]

	# Handle existing effects
	if enemy.active_effects.has(effect_key):
		var existing = enemy.active_effects[effect_key]

		# Refresh duration if allowed
		if effect.refresh_on_reapply:
			existing["remaining_time"] = effect.duration

		# Add stacks if stackable
		if effect.is_stacking:
			existing["stacks"] = mini(existing["stacks"] + 1, effect.max_stacks)

		# Update source
		if source:
			existing["source"] = source
	else:
		# Add new effect
		enemy.active_effects[effect_key] = {
			"effect": effect,
			"remaining_time": effect.duration,
			"stacks": 1,
			"source": source
		}

		# Initialize tick timer if needed
		if "_effect_tick_timers" in enemy:
			enemy._effect_tick_timers[effect_key] = 0.0

	# Apply immediate effects
	_apply_immediate_effect(enemy, effect)

	# Visual feedback
	apply_visual_indicator(enemy, effect)


## Process all active effects on an enemy (called each frame)
## enemy: The enemy to process effects for
## delta: Frame time delta
static func process_effects(enemy: Node, delta: float) -> void:
	if not is_instance_valid(enemy):
		return

	if "is_dead" in enemy and enemy.is_dead:
		return

	if not "active_effects" in enemy:
		return

	var effects_to_remove: Array[String] = []
	var total_speed_modifier: float = 1.0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data["effect"]

		if not effect:
			effects_to_remove.append(effect_key)
			continue

		# Update remaining time
		data["remaining_time"] -= delta

		# Process effect based on type - delegate to specialized classes
		match effect.effect_type:
			TraitEffect.EffectType.BURN:
				DamageEffects.process_burn(enemy, effect, data, delta)
			TraitEffect.EffectType.POISON:
				DamageEffects.process_poison(enemy, effect, data, delta)
			TraitEffect.EffectType.FREEZE:
				var speed_mod = ControlEffects.process_freeze(enemy, effect, data, delta)
				total_speed_modifier *= speed_mod
			TraitEffect.EffectType.SLOW:
				var speed_mod = ControlEffects.process_slow(enemy, effect, data, delta)
				total_speed_modifier *= speed_mod
			TraitEffect.EffectType.FEAR:
				ControlEffects.process_fear(enemy, effect, data, delta)
			TraitEffect.EffectType.ROOT:
				ControlEffects.process_root(enemy, effect, data, delta)
			TraitEffect.EffectType.ARMOR_SHRED:
				DebuffEffects.process_armor_shred(enemy, effect, data, delta)

		# Check if effect expired
		if data["remaining_time"] <= 0:
			effects_to_remove.append(effect_key)

		# Check if enemy died from DoT
		if "is_dead" in enemy and enemy.is_dead:
			return

	# Remove expired effects
	for effect_key in effects_to_remove:
		remove_effect(enemy, effect_key)

	# Apply cumulative speed modifier
	apply_speed_modifier(enemy, total_speed_modifier)


## Apply immediate effect on first application
static func _apply_immediate_effect(enemy: Node, effect: TraitEffect) -> void:
	match effect.effect_type:
		TraitEffect.EffectType.FREEZE:
			ControlEffects.apply_freeze_stun(enemy, effect)
		TraitEffect.EffectType.KNOCKBACK:
			ControlEffects.apply_knockback(enemy, effect.knockback_distance)
		TraitEffect.EffectType.ROOT:
			ControlEffects.apply_root(enemy, effect)
		TraitEffect.EffectType.INSTAKILL:
			DebuffEffects.apply_instakill(enemy, effect)


## Remove an effect from enemy
static func remove_effect(enemy: Node, effect_key: String) -> void:
	if not is_instance_valid(enemy):
		return

	if "active_effects" in enemy:
		enemy.active_effects.erase(effect_key)

	if "_effect_tick_timers" in enemy:
		enemy._effect_tick_timers.erase(effect_key)

	# Reset visual if no more effects
	if "active_effects" in enemy and enemy.active_effects.is_empty():
		reset_visual(enemy)


## Apply DoT damage to enemy
static func apply_dot_damage(enemy: Node, damage: float, damage_type: String, source: Node) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("take_damage"):
		enemy.take_damage(damage, source, damage_type)
	elif "current_hp" in enemy:
		enemy.current_hp -= damage

		# Check for death
		if enemy.current_hp <= 0:
			if enemy.has_method("_die"):
				enemy._die(source)
			elif "is_dead" in enemy:
				enemy.is_dead = true


## Apply speed modifier to enemy
static func apply_speed_modifier(enemy: Node, modifier: float) -> void:
	if not is_instance_valid(enemy):
		return

	# Speed modifier is typically applied in the enemy's _process_effects
	# This is a helper for external systems
	if "current_speed" in enemy and "enemy_data" in enemy and enemy.enemy_data:
		var base_speed = enemy.enemy_data.get_effective_speed()
		var modifier_mult = 1.0
		if "_modifier_stats" in enemy:
			modifier_mult = enemy._modifier_stats.get("speed_mult", 1.0)
		enemy.current_speed = base_speed * modifier_mult * modifier


## Apply visual indicator for effect
static func apply_visual_indicator(enemy: Node, effect: TraitEffect) -> void:
	if not is_instance_valid(enemy):
		return

	# Tint the sprite with effect color
	if "sprite" in enemy and enemy.sprite:
		# Blend effect color with current modulate
		var current = enemy.sprite.modulate
		var target = effect.effect_color
		enemy.sprite.modulate = current.lerp(target, 0.3)


## Flash effect color on enemy sprite
static func flash_effect_color(enemy: Node, color: Color) -> void:
	if not is_instance_valid(enemy):
		return

	if "sprite" in enemy and enemy.sprite:
		var original = enemy.sprite.modulate
		enemy.sprite.modulate = color

		# Create tween to restore
		if enemy.has_method("create_tween"):
			var tween = enemy.create_tween()
			tween.tween_property(enemy.sprite, "modulate", original, 0.15)


## Reset enemy visual to default
static func reset_visual(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return

	if "sprite" in enemy and enemy.sprite:
		enemy.sprite.modulate = Color.WHITE


## Check if enemy has a specific effect active
static func has_effect(enemy: Node, effect_name: String) -> bool:
	if not is_instance_valid(enemy):
		return false

	if not "active_effects" in enemy:
		return false

	return enemy.active_effects.has(effect_name)


## Get remaining duration of an effect
static func get_effect_duration(enemy: Node, effect_name: String) -> float:
	if not has_effect(enemy, effect_name):
		return 0.0

	var data = enemy.active_effects[effect_name]
	return data.get("remaining_time", 0.0)


## Get stack count of an effect
static func get_effect_stacks(enemy: Node, effect_name: String) -> int:
	if not has_effect(enemy, effect_name):
		return 0

	var data = enemy.active_effects[effect_name]
	return data.get("stacks", 0)


## Clear all effects from enemy
static func clear_all_effects(enemy: Node) -> void:
	if not is_instance_valid(enemy):
		return

	if "active_effects" in enemy:
		enemy.active_effects.clear()

	if "_effect_tick_timers" in enemy:
		enemy._effect_tick_timers.clear()

	if "is_stunned" in enemy:
		enemy.is_stunned = false

	reset_visual(enemy)


## Get list of all active effect names on enemy
static func get_active_effect_names(enemy: Node) -> Array[String]:
	var names: Array[String] = []

	if not is_instance_valid(enemy):
		return names

	if not "active_effects" in enemy:
		return names

	for key in enemy.active_effects.keys():
		names.append(key)

	return names
