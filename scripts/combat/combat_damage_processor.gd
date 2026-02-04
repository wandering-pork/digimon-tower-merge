class_name CombatDamageProcessor
extends RefCounted
## Handles damage calculations, application, and combat effects.
## Processes AoE, splash, chain, and instant damage.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DamageCalculator = preload("res://scripts/combat/damage_calculator.gd")
const StatusEffects = preload("res://scripts/combat/status_effects.gd")
const TraitEffect = preload("res://scripts/data/trait_effect.gd")

## Reference to scene tree for enemy queries
var _scene_tree: SceneTree = null

## Tile size in pixels (for range calculations)
const TILE_SIZE: float = 64.0


## Initialize the processor with scene tree reference
func initialize(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree


## Process a chain attack from an origin point
## origin: World position where chain starts
## damage: Base damage for the chain
## chain_count: Number of enemies to chain to
## exclude: Enemies to exclude (already hit)
## source: The source tower/node
func process_chain_attack(
	origin: Vector2,
	damage: int,
	chain_count: int,
	exclude: Array,
	source: Node = null
) -> void:
	if chain_count <= 0:
		return

	# Get nearby enemies
	var nearby = get_enemies_in_radius(origin, 128.0)

	# Filter excluded enemies
	var valid_targets: Array = []
	for enemy in nearby:
		if is_instance_valid(enemy) and not exclude.has(enemy) and not enemy.is_dead:
			valid_targets.append(enemy)

	if valid_targets.is_empty():
		return

	# Sort by distance from origin
	valid_targets.sort_custom(func(a, b):
		var dist_a = origin.distance_squared_to(a.global_position)
		var dist_b = origin.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)

	# Hit the closest target
	var target = valid_targets[0]

	# Calculate chain damage (50% falloff per chain)
	var current_damage = damage

	# Apply damage
	var damage_result = {
		"damage": current_damage,
		"is_critical": false,
		"damage_type": "electric"
	}

	if is_instance_valid(source):
		damage_result = DamageCalculator.calculate_damage(source, target, current_damage)

	_apply_damage_to_target(target, damage_result, source)

	# Visual: chain effect (placeholder)
	_draw_chain_effect(origin, target.global_position)

	# Add to exclude list
	exclude.append(target)

	# Continue chain with reduced damage
	var next_damage = int(damage * 0.5)
	if next_damage > 0 and chain_count > 1:
		process_chain_attack(target.global_position, next_damage, chain_count - 1, exclude, source)


## Process area of effect damage
## center: World position at center of AoE
## radius: Radius in pixels
## damage: Base damage at center
## source: The source tower/node
## falloff: Damage multiplier at edge (0.5 = 50% damage at edge)
func process_aoe_damage(
	center: Vector2,
	radius: float,
	damage: int,
	source: Node,
	falloff: float = 0.5
) -> void:
	var enemies = get_enemies_in_radius(center, radius)

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		# Calculate distance falloff
		var distance = center.distance_to(enemy.global_position)
		var distance_ratio = clampf(distance / radius, 0.0, 1.0)
		var damage_mult = lerpf(1.0, falloff, distance_ratio)

		# Calculate final damage
		var aoe_dmg = maxi(1, int(damage * damage_mult))

		var damage_result = {
			"damage": aoe_dmg,
			"is_critical": false,
			"damage_type": "physical"
		}

		if is_instance_valid(source):
			damage_result = DamageCalculator.calculate_aoe_damage(
				source, enemy, damage, distance, radius, falloff
			)

		_apply_damage_to_target(enemy, damage_result, source)

	# Visual: AoE effect (placeholder)
	_spawn_aoe_visual(center, radius)


## Apply splash damage (full to main target, reduced to nearby)
## main_target: The primary target that received full damage
## center: Position to splash from (usually main_target's position)
## radius: Splash radius in pixels
## damage: Base damage for splash targets
## source: The source tower/node
## damage_percent: Percentage of damage for splash targets
func process_splash_damage(
	main_target: Node,
	center: Vector2,
	radius: float,
	damage: int,
	source: Node,
	damage_percent: float = 0.5
) -> void:
	var enemies = get_enemies_in_radius(center, radius)

	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.is_dead:
			continue

		# Skip main target (already damaged)
		if enemy == main_target:
			continue

		# Calculate splash damage
		var splash_dmg = maxi(1, int(damage * damage_percent))

		var damage_result = {
			"damage": splash_dmg,
			"is_critical": false,
			"damage_type": "physical"
		}

		if is_instance_valid(source):
			damage_result = DamageCalculator.calculate_damage(source, enemy, splash_dmg)

		_apply_damage_to_target(enemy, damage_result, source)


## Apply status effect to all enemies in radius
## center: World position at center
## radius: Radius in pixels
## effect: The TraitEffect to apply
## source: The source node
func apply_effect_in_radius(
	center: Vector2,
	radius: float,
	effect: TraitEffect,
	source: Node = null
) -> void:
	var enemies = get_enemies_in_radius(center, radius)

	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			StatusEffects.apply_effect(enemy, effect, source)


## Direct damage with no projectile (instant attack)
## source: The attacking node
## target: The target enemy
## damage: Base damage
## damage_type: Type of damage
func process_instant_damage(
	source: Node,
	target: Node,
	damage: int,
	damage_type: String = "physical"
) -> void:
	if not is_instance_valid(target) or target.is_dead:
		return

	var damage_result = DamageCalculator.calculate_damage(source, target, damage)
	damage_result["damage_type"] = damage_type

	if target.has_method("take_damage"):
		target.take_damage(damage_result["damage"], source, damage_type)

	# Show damage number
	if EventBus:
		EventBus.show_damage_number(
			target.global_position,
			damage_result["damage"],
			damage_result["is_critical"]
		)

	# Apply effect
	DamageCalculator.apply_effect(source, target)


## Apply damage to a target and show damage number
func _apply_damage_to_target(target: Node, damage_result: Dictionary, source: Node) -> void:
	# Apply damage
	if target.has_method("take_damage"):
		target.take_damage(
			damage_result["damage"],
			source,
			damage_result.get("damage_type", "physical")
		)

	# Show damage number
	if EventBus:
		EventBus.show_damage_number(
			target.global_position,
			damage_result["damage"],
			damage_result.get("is_critical", false)
		)


## Get all enemies within a pixel radius
## position: World position to check from
## radius: Range in pixels
## Returns: Array of enemy nodes in range
func get_enemies_in_radius(position: Vector2, radius: float) -> Array:
	if not _scene_tree:
		ErrorHandler.log_error("CombatDamageProcessor", "Scene tree not initialized")
		return []

	var enemies: Array = []
	var all_enemies = _scene_tree.get_nodes_in_group("enemies")
	var radius_squared = radius * radius

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist_squared = position.distance_squared_to(enemy.global_position)
			if dist_squared <= radius_squared:
				enemies.append(enemy)

	return enemies


## Get all enemies in range of a position (tile-based)
## position: World position to check from
## attack_range: Range in tiles (will be converted to pixels)
## Returns: Array of enemy nodes in range
func get_enemies_in_range(position: Vector2, attack_range: float) -> Array:
	var range_pixels = attack_range * TILE_SIZE
	return get_enemies_in_radius(position, range_pixels)


## Draw chain lightning effect (placeholder)
func _draw_chain_effect(from: Vector2, to: Vector2) -> void:
	# TODO: Implement actual visual effect
	# Could use Line2D, particles, or custom shader
	pass


## Spawn AoE visual effect (placeholder)
func _spawn_aoe_visual(center: Vector2, radius: float) -> void:
	# TODO: Implement actual visual effect
	# Could use expanding circle, particles, etc.
	pass
