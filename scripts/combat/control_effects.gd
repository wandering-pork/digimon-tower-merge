class_name ControlEffects
extends RefCounted
## Crowd control effect processors.
## Handles: Stun, Slow, Freeze, Fear, Root, Knockback
##
## These effects impair enemy movement or actions.
## Speed modifiers are returned and combined by the main StatusEffects processor.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const TraitEffect = preload("res://scripts/data/trait_effect.gd")


## Process freeze effect (stun then slow)
## Returns speed modifier (0.0 = stopped, 1.0 = normal speed)
static func process_freeze(enemy: Node, effect: TraitEffect, _data: Dictionary, _delta: float) -> float:
	# Check if still in stun phase
	if "is_stunned" in enemy and enemy.is_stunned:
		# Stun is handled by enemy's own stun_timer
		return 0.0  # Complete stop during stun

	# After stun, apply slow
	return 1.0 - effect.slow_percent


## Process slow effect
## Returns speed modifier (0.0 = stopped, 1.0 = normal speed)
static func process_slow(_enemy: Node, effect: TraitEffect, data: Dictionary, _delta: float) -> float:
	# Apply slow based on stacks
	var slow_per_stack = effect.slow_percent
	var total_slow = slow_per_stack * data["stacks"]

	# Cap slow at 90%
	total_slow = minf(total_slow, 0.9)

	return 1.0 - total_slow


## Process fear effect (enemy moves backward)
static func process_fear(_enemy: Node, _effect: TraitEffect, data: Dictionary, _delta: float) -> void:
	# Fear causes enemy to move backward along the path
	# This is typically handled in the enemy's movement code
	# by checking for fear effect and reversing direction

	# Store fear state
	data["is_fleeing"] = true


## Process root effect (cannot move)
static func process_root(enemy: Node, _effect: TraitEffect, data: Dictionary, _delta: float) -> void:
	# Root is similar to stun but enemy can still "attack" (for enemies that attack)
	if "is_stunned" in enemy:
		enemy.is_stunned = true
		enemy.stun_timer = maxf(enemy.stun_timer, data["remaining_time"])


## Apply initial freeze stun (called on first application)
static func apply_freeze_stun(enemy: Node, effect: TraitEffect) -> void:
	# Apply initial stun
	if effect.stun_duration > 0 and "is_stunned" in enemy:
		enemy.is_stunned = true
		if "stun_timer" in enemy:
			enemy.stun_timer = maxf(enemy.stun_timer, effect.stun_duration)


## Apply root effect (called on first application)
static func apply_root(enemy: Node, effect: TraitEffect) -> void:
	# Apply root stun
	if "is_stunned" in enemy:
		enemy.is_stunned = true
		if "stun_timer" in enemy:
			enemy.stun_timer = maxf(enemy.stun_timer, effect.duration)


## Apply knockback to enemy (instant effect)
static func apply_knockback(enemy: Node, distance_tiles: float) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("_apply_knockback"):
		enemy._apply_knockback(distance_tiles)
		return

	# Fallback: move back along path
	if not "path_index" in enemy or not "path_waypoints" in enemy:
		return

	if enemy.path_index <= 0:
		return

	var pixels_to_move = distance_tiles * 64  # TILE_SIZE
	var remaining = pixels_to_move

	while remaining > 0 and enemy.path_index > 0:
		var prev_waypoint = enemy.path_waypoints[enemy.path_index - 1]
		var dist_to_prev = enemy.global_position.distance_to(prev_waypoint)

		if dist_to_prev <= remaining:
			enemy.global_position = prev_waypoint
			remaining -= dist_to_prev
			enemy.path_index -= 1
		else:
			var direction = (prev_waypoint - enemy.global_position).normalized()
			enemy.global_position += direction * remaining
			remaining = 0


## Apply stun to enemy directly
static func apply_stun(enemy: Node, duration: float) -> void:
	if not is_instance_valid(enemy):
		return

	if "is_stunned" in enemy:
		enemy.is_stunned = true
		if "stun_timer" in enemy:
			enemy.stun_timer = maxf(enemy.stun_timer, duration)


## Check if enemy is under any movement-impairing effect
static func is_movement_impaired(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return false

	if "is_stunned" in enemy and enemy.is_stunned:
		return true

	if not "active_effects" in enemy:
		return false

	# Check for specific control effects
	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect:
			match effect.effect_type:
				TraitEffect.EffectType.FREEZE, TraitEffect.EffectType.ROOT:
					return true

	return false


## Check if enemy is fleeing (under fear effect)
static func is_fleeing(enemy: Node) -> bool:
	if not is_instance_valid(enemy):
		return false

	if not "active_effects" in enemy:
		return false

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect and effect.effect_type == TraitEffect.EffectType.FEAR:
			return data.get("is_fleeing", false)

	return false


## Get total slow percentage on enemy (combined from all slow effects)
static func get_total_slow_percent(enemy: Node) -> float:
	if not is_instance_valid(enemy):
		return 0.0

	if not "active_effects" in enemy:
		return 0.0

	var total_slow: float = 0.0

	for effect_key in enemy.active_effects.keys():
		var data = enemy.active_effects[effect_key]
		var effect: TraitEffect = data.get("effect")
		if effect:
			match effect.effect_type:
				TraitEffect.EffectType.SLOW:
					var stacks = data.get("stacks", 1)
					total_slow += effect.slow_percent * stacks
				TraitEffect.EffectType.FREEZE:
					# Freeze slow only applies after stun ends
					if not ("is_stunned" in enemy and enemy.is_stunned):
						total_slow += effect.slow_percent

	# Cap at 90%
	return minf(total_slow, 0.9)


## Check if effect is a control effect
static func is_control_effect(effect_type: TraitEffect.EffectType) -> bool:
	match effect_type:
		TraitEffect.EffectType.FREEZE, TraitEffect.EffectType.SLOW, \
		TraitEffect.EffectType.FEAR, TraitEffect.EffectType.ROOT, \
		TraitEffect.EffectType.KNOCKBACK:
			return true
		_:
			return false
