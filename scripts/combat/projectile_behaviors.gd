class_name ProjectileBehaviors
extends RefCounted
## Handles projectile movement behaviors: tracking, piercing, and chaining.
## Used as a component by the main Projectile class.

## Reference to the parent projectile
var _projectile: Node2D = null

## Reference to combat system for enemy queries
var _combat_system: Node = null

## Pierce state
var pierce_count: int = 0
var max_pierce: int = 3
var pierced_enemies: Array = []

## Chain state
var chain_count: int = 0
var max_chains: int = 3
var chain_damage_falloff: float = 0.5
var chain_range: float = 128.0
var chained_enemies: Array = []


## Initialize the behavior component
func initialize(projectile: Node2D, combat_system: Node = null) -> void:
	_projectile = projectile
	_combat_system = combat_system


## Move straight toward a target position
## Returns true if the projectile should continue, false if it should be destroyed
func move_straight(
	delta: float,
	current_pos: Vector2,
	velocity: Vector2,
	target_pos: Vector2,
	attack_type: int
) -> Dictionary:
	var new_pos = current_pos + velocity * delta
	var should_destroy = false

	# Check if past target position (for non-tracking projectiles)
	if target_pos != Vector2.ZERO:
		var to_target = target_pos - new_pos
		var dot = velocity.normalized().dot(to_target.normalized())
		if dot < 0:
			# We've passed the target
			# AttackType.PIERCE == 1
			if attack_type == 1 and pierce_count < max_pierce:
				# Continue moving for pierce
				pass
			else:
				should_destroy = true

	return {
		"position": new_pos,
		"should_destroy": should_destroy
	}


## Move with tracking toward current target
## Returns updated position and velocity
func move_tracking(
	delta: float,
	current_pos: Vector2,
	target: Node2D,
	speed: float
) -> Dictionary:
	var new_velocity: Vector2
	var should_destroy = false
	var new_target = target

	if is_instance_valid(target) and not _is_target_dead(target):
		var direction = (target.global_position - current_pos).normalized()
		new_velocity = direction * speed
	else:
		# Target lost, find new target
		new_target = find_new_target(current_pos, 200.0)
		if not is_instance_valid(new_target):
			should_destroy = true
			new_velocity = Vector2.ZERO
		else:
			var direction = (new_target.global_position - current_pos).normalized()
			new_velocity = direction * speed

	var new_pos = current_pos + new_velocity * delta

	return {
		"position": new_pos,
		"velocity": new_velocity,
		"target": new_target,
		"should_destroy": should_destroy
	}


## Check if target is dead
func _is_target_dead(target: Node) -> bool:
	if target.has_method("is_dead"):
		return target.is_dead
	if "is_dead" in target:
		return target.is_dead
	return false


## Handle pierce behavior after hitting an enemy
## Returns true if projectile should be destroyed
func handle_pierce(enemy: Node) -> bool:
	if pierced_enemies.has(enemy):
		return false  # Already pierced, skip

	pierced_enemies.append(enemy)
	pierce_count += 1
	return pierce_count >= max_pierce


## Check if enemy was already pierced
func was_pierced(enemy: Node) -> bool:
	return pierced_enemies.has(enemy)


## Check if enemy was already chained
func was_chained(enemy: Node) -> bool:
	return chained_enemies.has(enemy)


## Handle chain behavior after hitting an enemy
## Returns the next target to chain to, or null if chaining is complete
func handle_chain(current_enemy: Node) -> Node:
	if chained_enemies.has(current_enemy):
		return null

	chained_enemies.append(current_enemy)
	chain_count += 1

	if chain_count >= max_chains:
		return null

	return find_chain_target(current_enemy)


## Find the next target for chain lightning
func find_chain_target(current_enemy: Node) -> Node:
	var nearby = get_enemies_in_radius(current_enemy.global_position, chain_range)

	# Filter out already chained enemies
	var valid_targets: Array = []
	for enemy in nearby:
		if is_instance_valid(enemy) and not chained_enemies.has(enemy):
			valid_targets.append(enemy)

	if valid_targets.is_empty():
		return null

	# Find closest valid target
	var closest: Node = null
	var closest_dist: float = INF

	for enemy in valid_targets:
		var dist = current_enemy.global_position.distance_squared_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = enemy

	return closest


## Find a new target for tracking projectiles
func find_new_target(from_position: Vector2, search_radius: float) -> Node:
	var nearby = get_enemies_in_radius(from_position, search_radius)

	if nearby.is_empty():
		return null

	# Find closest living enemy
	var closest: Node = null
	var closest_dist: float = INF

	for enemy in nearby:
		if is_instance_valid(enemy) and not _is_target_dead(enemy):
			var dist = from_position.distance_squared_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	return closest


## Get all enemies in a radius
func get_enemies_in_radius(center: Vector2, radius: float) -> Array:
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


## Calculate chain damage with falloff
func get_chain_damage_multiplier() -> float:
	if chain_count <= 0:
		return 1.0
	return pow(chain_damage_falloff, chain_count)


## Configure pierce parameters
func set_pierce(max_p: int) -> void:
	max_pierce = max_p
	pierce_count = 0
	pierced_enemies.clear()


## Configure chain parameters
func set_chain(max_c: int, falloff: float = 0.5, c_range: float = 128.0) -> void:
	max_chains = max_c
	chain_damage_falloff = falloff
	chain_range = c_range
	chain_count = 0
	chained_enemies.clear()


## Reset all behavior state
func reset() -> void:
	pierce_count = 0
	pierced_enemies.clear()
	chain_count = 0
	chained_enemies.clear()


## Clean up references
func cleanup() -> void:
	_projectile = null
	_combat_system = null
	pierced_enemies.clear()
	chained_enemies.clear()
