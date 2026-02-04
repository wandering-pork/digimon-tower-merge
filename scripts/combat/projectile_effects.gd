class_name ProjectileEffects
extends RefCounted
## Handles projectile on-hit effects: damage application, AoE, splash, and visual effects.
## Used as a component by the main Projectile class.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DamageCalculator = preload("res://scripts/combat/damage_calculator.gd")

## Reference to the parent projectile
var _projectile: Node2D = null

## Reference to combat system for enemy queries
var _combat_system: Node = null

## Reference to the source tower
var source: Node = null

## Base damage
var damage: int = 10

## Damage type (physical, fire, water, etc.)
var damage_type: String = "physical"

## AoE configuration
var aoe_radius: float = 64.0
var aoe_damage_falloff: float = 0.5

## Splash configuration
var splash_radius: float = 48.0
var splash_damage_percent: float = 0.5


## Initialize the effects component
func initialize(projectile: Node2D, combat_system: Node = null) -> void:
	_projectile = projectile
	_combat_system = combat_system


## Set the source and damage parameters
func set_damage_params(p_source: Node, p_damage: int, p_damage_type: String) -> void:
	source = p_source
	damage = p_damage
	damage_type = p_damage_type


## Calculate damage for a hit
func calculate_damage(enemy: Node, chain_multiplier: float = 1.0) -> Dictionary:
	var result = {
		"damage": damage,
		"is_critical": false,
		"damage_type": damage_type
	}

	# Use DamageCalculator if available and we have a source
	if is_instance_valid(source):
		var base_dmg = damage
		if "digimon_data" in source and source.digimon_data:
			base_dmg = source.digimon_data.base_damage

		result = DamageCalculator.calculate_damage(source, enemy, base_dmg)
		result["damage_type"] = damage_type

	# Apply chain falloff if provided
	if chain_multiplier < 1.0:
		result["damage"] = maxi(1, int(result["damage"] * chain_multiplier))

	return result


## Apply damage to an enemy
func apply_damage(enemy: Node, damage_result: Dictionary) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_method("take_damage"):
		enemy.take_damage(
			damage_result["damage"],
			source,
			damage_result["damage_type"]
		)

	# Show damage number via EventBus
	_show_damage_number(enemy.global_position, damage_result)

	# Apply status effect from source
	if is_instance_valid(source):
		DamageCalculator.apply_effect(source, enemy)


## Show damage number floating text
func _show_damage_number(position: Vector2, damage_result: Dictionary) -> void:
	var event_bus = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if not event_bus and _projectile:
		event_bus = _projectile.get_node_or_null("/root/EventBus")

	if event_bus and event_bus.has_method("show_damage_number"):
		event_bus.show_damage_number(
			position,
			damage_result["damage"],
			damage_result["is_critical"]
		)


## Apply AoE damage around a point
func apply_aoe_damage(center: Vector2) -> void:
	var enemies = _get_enemies_in_radius(center, aoe_radius)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue

		var distance = center.distance_to(enemy.global_position)
		var damage_result: Dictionary

		if is_instance_valid(source):
			damage_result = DamageCalculator.calculate_aoe_damage(
				source, enemy, damage, distance, aoe_radius, aoe_damage_falloff
			)
		else:
			var falloff = 1.0 - (distance / aoe_radius) * (1.0 - aoe_damage_falloff)
			damage_result = {
				"damage": maxi(1, int(damage * falloff)),
				"is_critical": false,
				"damage_type": damage_type
			}

		apply_damage(enemy, damage_result)

	# Spawn visual effect
	spawn_aoe_effect(center)


## Apply splash damage (full to main target already applied, reduced to nearby)
func apply_splash_damage(main_target: Node, main_target_position: Vector2) -> void:
	var nearby_enemies = _get_enemies_in_radius(main_target_position, splash_radius)

	for enemy in nearby_enemies:
		if not is_instance_valid(enemy):
			continue

		# Skip main target (already damaged)
		if enemy == main_target:
			continue

		# Calculate splash damage
		var splash_damage = maxi(1, int(damage * splash_damage_percent))
		var damage_result = {
			"damage": splash_damage,
			"is_critical": false,
			"damage_type": damage_type
		}

		if is_instance_valid(source):
			damage_result = DamageCalculator.calculate_damage(source, enemy, splash_damage)
			damage_result["damage_type"] = damage_type

		apply_damage(enemy, damage_result)


## Get enemies in radius using combat system or scene tree
func _get_enemies_in_radius(center: Vector2, radius: float) -> Array:
	var enemies: Array = []
	var all_enemies: Array = []

	if _combat_system and _combat_system.has_method("get_all_enemies"):
		all_enemies = _combat_system.get_all_enemies()
	elif _projectile:
		all_enemies = _projectile.get_tree().get_nodes_in_group("enemies")

	var radius_squared = radius * radius

	for enemy in all_enemies:
		if is_instance_valid(enemy):
			var dist_squared = center.distance_squared_to(enemy.global_position)
			if dist_squared <= radius_squared:
				enemies.append(enemy)

	return enemies


## Spawn visual effect for AoE explosion
func spawn_aoe_effect(center: Vector2) -> void:
	# TODO: Implement particle effect or animation
	# This would create an expanding circle, explosion particles, etc.
	# For now, emit a signal that UI/effects system can listen to
	if _projectile and _projectile.has_signal("aoe_triggered"):
		_projectile.emit_signal("aoe_triggered", center, aoe_radius)


## Spawn visual effect for chain lightning
func spawn_chain_effect(from: Vector2, to: Vector2) -> void:
	# TODO: Implement line renderer or particle effect
	# This would draw a lightning bolt from one enemy to another
	# For now, emit a signal that UI/effects system can listen to
	if _projectile and _projectile.has_signal("chain_triggered"):
		_projectile.emit_signal("chain_triggered", from, to)


## Configure AoE parameters
func set_aoe(radius: float, falloff: float = 0.5) -> void:
	aoe_radius = radius
	aoe_damage_falloff = falloff


## Configure splash parameters
func set_splash(radius: float, damage_percent: float = 0.5) -> void:
	splash_radius = radius
	splash_damage_percent = damage_percent


## Clean up references
func cleanup() -> void:
	_projectile = null
	_combat_system = null
	source = null
