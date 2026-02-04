class_name Targeting
extends RefCounted
## Targeting priority system for tower combat.
## Determines which enemy a tower should attack based on various strategies.

## Available targeting priorities
enum Priority {
	FIRST,     ## Enemy closest to reaching the end (highest path progress)
	LAST,      ## Enemy furthest from reaching the end (lowest path progress)
	STRONGEST, ## Enemy with highest current HP
	WEAKEST,   ## Enemy with lowest current HP
	FASTEST,   ## Enemy with highest movement speed
	CLOSEST,   ## Enemy nearest to the tower
	FLYING     ## Prioritize flying enemies only
}


## Get the best target for a tower based on priority
## tower: The attacking tower
## enemies: Array of potential enemy targets
## priority: The targeting priority to use
## Returns: The best target enemy, or null if none available
static func get_target(tower: Node2D, enemies: Array, priority: Priority) -> Node2D:
	if enemies.is_empty():
		return null

	# Filter out invalid references and dead enemies
	var valid_enemies: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			valid_enemies.append(enemy)

	if valid_enemies.is_empty():
		return null

	# Handle FLYING priority specially - only target flying enemies
	if priority == Priority.FLYING:
		var flying_enemies = filter_flying(valid_enemies)
		if flying_enemies.is_empty():
			# Fall back to FIRST if no flying enemies
			return _get_sorted_target(valid_enemies, Priority.FIRST)
		return _get_sorted_target(flying_enemies, Priority.FIRST)

	return _get_sorted_target(valid_enemies, priority, tower)


## Get the target after sorting by priority
static func _get_sorted_target(enemies: Array, priority: Priority, tower: Node2D = null) -> Node2D:
	if enemies.is_empty():
		return null

	if enemies.size() == 1:
		return enemies[0]

	var sorted = enemies.duplicate()

	match priority:
		Priority.FIRST:
			sorted.sort_custom(sort_by_first)
		Priority.LAST:
			sorted.sort_custom(sort_by_last)
		Priority.STRONGEST:
			sorted.sort_custom(sort_by_strongest)
		Priority.WEAKEST:
			sorted.sort_custom(sort_by_weakest)
		Priority.FASTEST:
			sorted.sort_custom(sort_by_fastest)
		Priority.CLOSEST:
			if tower:
				sorted.sort_custom(func(a, b): return sort_by_closest(a, b, tower))
			else:
				sorted.sort_custom(sort_by_first)

	return sorted[0] if sorted.size() > 0 else null


## Sort by path progress - highest progress first (closest to end)
static func sort_by_first(a: Node2D, b: Node2D) -> bool:
	var progress_a = _get_path_progress(a)
	var progress_b = _get_path_progress(b)
	return progress_a > progress_b


## Sort by path progress - lowest progress first (furthest from end)
static func sort_by_last(a: Node2D, b: Node2D) -> bool:
	var progress_a = _get_path_progress(a)
	var progress_b = _get_path_progress(b)
	return progress_a < progress_b


## Sort by current HP - highest HP first
static func sort_by_strongest(a: Node2D, b: Node2D) -> bool:
	var hp_a = _get_current_hp(a)
	var hp_b = _get_current_hp(b)
	return hp_a > hp_b


## Sort by current HP - lowest HP first
static func sort_by_weakest(a: Node2D, b: Node2D) -> bool:
	var hp_a = _get_current_hp(a)
	var hp_b = _get_current_hp(b)
	return hp_a < hp_b


## Sort by movement speed - fastest first
static func sort_by_fastest(a: Node2D, b: Node2D) -> bool:
	var speed_a = _get_move_speed(a)
	var speed_b = _get_move_speed(b)
	return speed_a > speed_b


## Sort by distance to tower - nearest first
static func sort_by_closest(a: Node2D, b: Node2D, tower: Node2D) -> bool:
	var dist_a = tower.global_position.distance_squared_to(a.global_position)
	var dist_b = tower.global_position.distance_squared_to(b.global_position)
	return dist_a < dist_b


## Filter to only flying enemies
static func filter_flying(enemies: Array) -> Array:
	var flying: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy) and enemy.has_method("is_flying") and enemy.is_flying():
			flying.append(enemy)
	return flying


## Filter enemies within a specific range from a position
static func filter_in_range(enemies: Array, position: Vector2, attack_range: float) -> Array:
	var in_range: Array = []
	var range_squared = attack_range * attack_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist_squared = position.distance_squared_to(enemy.global_position)
			if dist_squared <= range_squared:
				in_range.append(enemy)

	return in_range


## Get enemies sorted by distance from a position
static func get_enemies_by_distance(enemies: Array, position: Vector2) -> Array:
	var valid_enemies: Array = []
	for enemy in enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			valid_enemies.append(enemy)

	valid_enemies.sort_custom(func(a, b):
		var dist_a = position.distance_squared_to(a.global_position)
		var dist_b = position.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)

	return valid_enemies


## Get the closest N enemies to a position
static func get_closest_n_enemies(enemies: Array, position: Vector2, count: int) -> Array:
	var sorted = get_enemies_by_distance(enemies, position)
	return sorted.slice(0, mini(count, sorted.size()))


# =============================================================================
# HELPER METHODS
# =============================================================================

## Get path progress from an enemy (0.0 to 1.0, or path_index if no method)
static func _get_path_progress(enemy: Node2D) -> float:
	if enemy.has_method("get_path_progress"):
		return enemy.get_path_progress()
	elif "path_index" in enemy:
		# Use remaining distance as inverse progress (lower = closer to end)
		if enemy.has_method("get_remaining_distance"):
			# Invert so higher value = closer to end
			return -enemy.get_remaining_distance()
		return float(enemy.path_index)
	return 0.0


## Get current HP from an enemy
static func _get_current_hp(enemy: Node2D) -> float:
	if "current_hp" in enemy:
		return enemy.current_hp
	return 0.0


## Get movement speed from an enemy
static func _get_move_speed(enemy: Node2D) -> float:
	if "current_speed" in enemy:
		return enemy.current_speed
	return 1.0


## Convert priority enum to string for display
static func priority_to_string(priority: Priority) -> String:
	match priority:
		Priority.FIRST: return "First"
		Priority.LAST: return "Last"
		Priority.STRONGEST: return "Strongest"
		Priority.WEAKEST: return "Weakest"
		Priority.FASTEST: return "Fastest"
		Priority.CLOSEST: return "Closest"
		Priority.FLYING: return "Flying"
		_: return "Unknown"


## Get all priority options for UI
static func get_all_priorities() -> Array[Priority]:
	return [
		Priority.FIRST,
		Priority.LAST,
		Priority.STRONGEST,
		Priority.WEAKEST,
		Priority.FASTEST,
		Priority.CLOSEST,
		Priority.FLYING
	]
