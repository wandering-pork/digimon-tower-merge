# class_name CombatSystem  # Removed: autoloads register as globals, class_name causes conflicts
extends Node
## Central combat manager handling projectiles, damage, and combat events.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
# Autoload scripts load before regular scripts in Godot. We must preload
# non-autoload classes to ensure they're available for type hints.

const Projectile = preload("res://scripts/combat/projectile.gd")
const CombatProjectileFactory = preload("res://scripts/combat/combat_projectile_factory.gd")
const CombatDamageProcessor = preload("res://scripts/combat/combat_damage_processor.gd")
const AttackTypes = preload("res://scripts/combat/attack_types.gd")
const TraitEffect = preload("res://scripts/data/trait_effect.gd")
## This is designed to be an autoload singleton for global combat management.
## Delegates projectile creation to CombatProjectileFactory and damage
## processing to CombatDamageProcessor.
##
## Enemy list is cached and updated via EventBus signals for O(1) access.

## Emitted when any enemy takes damage
signal enemy_damaged(enemy: Node, damage: float, source: Node, damage_type: String)
## Emitted when any enemy dies
signal enemy_killed(enemy: Node, killer: Node, reward: int)
## Emitted when a projectile is fired
signal projectile_fired(projectile: Projectile, source: Node, target: Node)

## Tile size in pixels (for range calculations)
const TILE_SIZE: float = 64.0

## Track all active projectiles
var active_projectiles: Array[Node2D] = []

## Reference to the current level/game scene
var _current_level: Node = null

## Projectile factory for creating projectiles
var _projectile_factory: CombatProjectileFactory = null

## Damage processor for handling damage calculations
var _damage_processor: CombatDamageProcessor = null

## Cached list of active enemies - updated via EventBus signals
## Provides O(1) access instead of O(n) tree traversal
var _cached_enemies: Array[Node] = []

## Flag to track if cache is initialized
var _cache_initialized: bool = false


func _ready() -> void:
	# Add to combat_system group for easy finding
	add_to_group("combat_system")

	# Initialize subsystems
	_projectile_factory = CombatProjectileFactory.new()
	_projectile_factory.initialize(get_tree())

	_damage_processor = CombatDamageProcessor.new()
	_damage_processor.initialize(get_tree())

	# Connect to EventBus if available
	if EventBus:
		EventBus.tower_attack_started.connect(_on_tower_attack_started)
		# Connect to enemy lifecycle signals for cache management
		EventBus.enemy_spawned.connect(_on_enemy_spawned)
		EventBus.enemy_killed.connect(_on_enemy_killed)
		EventBus.enemy_escaped.connect(_on_enemy_escaped)
		_cache_initialized = true


func _process(_delta: float) -> void:
	# Clean up destroyed projectiles
	_cleanup_projectiles()


# =============================================================================
# PUBLIC API - Projectile Methods
# =============================================================================

## Create and launch a projectile from tower to enemy
## from: The attacking tower
## to: The target enemy
## damage: Base damage (before modifiers)
## attack_type: Type of attack (from AttackTypes.Type)
## Returns: The created projectile, or null on failure
func fire_projectile(
	from: Node,
	to: Node,
	damage: int,
	attack_type: int = AttackTypes.Type.SINGLE
) -> Projectile:
	var projectile = _projectile_factory.create_projectile(from, to, damage, attack_type)

	if projectile:
		# Track projectile
		active_projectiles.append(projectile)
		projectile.destroyed.connect(func(): _on_projectile_destroyed(projectile))

		# Emit signal
		projectile_fired.emit(projectile, from, to)

	return projectile


# =============================================================================
# PUBLIC API - Damage Methods
# =============================================================================

## Process a chain attack from an origin point
func chain_attack(
	origin: Vector2,
	damage: int,
	chain_count: int,
	exclude: Array,
	source: Node = null
) -> void:
	_damage_processor.process_chain_attack(origin, damage, chain_count, exclude, source)


## Process area of effect damage
func aoe_damage(
	center: Vector2,
	radius: float,
	damage: int,
	source: Node,
	falloff: float = 0.5
) -> void:
	_damage_processor.process_aoe_damage(center, radius, damage, source, falloff)


## Apply splash damage (full to main target, reduced to nearby)
func splash_damage(
	main_target: Node,
	center: Vector2,
	radius: float,
	damage: int,
	source: Node,
	damage_percent: float = 0.5
) -> void:
	_damage_processor.process_splash_damage(main_target, center, radius, damage, source, damage_percent)


## Apply status effect to all enemies in radius
func apply_effect_in_radius(
	center: Vector2,
	radius: float,
	effect: TraitEffect,
	source: Node = null
) -> void:
	_damage_processor.apply_effect_in_radius(center, radius, effect, source)


## Direct damage with no projectile (instant attack)
func instant_damage(
	source: Node,
	target: Node,
	damage: int,
	damage_type: String = "physical"
) -> void:
	_damage_processor.process_instant_damage(source, target, damage, damage_type)


# =============================================================================
# PUBLIC API - Query Methods
# =============================================================================

## Get all enemies in range of a position (tile-based)
func get_enemies_in_range(position: Vector2, attack_range: float) -> Array[Node]:
	var range_pixels = attack_range * TILE_SIZE
	return get_enemies_in_radius(position, range_pixels)


## Get all enemies within a pixel radius
func get_enemies_in_radius(position: Vector2, radius: float) -> Array[Node]:
	var enemies: Array[Node] = []
	var all_enemies = get_all_enemies()
	var radius_squared = radius * radius

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist_squared = position.distance_squared_to(enemy.global_position)
			if dist_squared <= radius_squared:
				enemies.append(enemy)

	return enemies


## Get all active enemies in the scene (uses cached list for O(1) access)
func get_all_enemies() -> Array[Node]:
	if _cache_initialized:
		return _cached_enemies.duplicate()
	# Fallback to tree traversal if cache not initialized
	return get_tree().get_nodes_in_group("enemies").duplicate()


## Get all active towers in the scene
func get_all_towers() -> Array[Node]:
	return get_tree().get_nodes_in_group("towers")


## Get the closest enemy to a position
func get_closest_enemy(position: Vector2, max_range: float = INF) -> Node:
	var all_enemies = get_all_enemies()
	var closest: Node = null
	var closest_dist: float = max_range * max_range

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist_squared = position.distance_squared_to(enemy.global_position)
			if dist_squared < closest_dist:
				closest_dist = dist_squared
				closest = enemy

	return closest


## Get enemy furthest along the path (closest to escaping)
func get_first_enemy() -> Node:
	var all_enemies = get_all_enemies()
	var first: Node = null
	var best_progress: float = -1.0

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var progress = -enemy.get_remaining_distance() if enemy.has_method("get_remaining_distance") else 0.0
			if "path_index" in enemy:
				progress = enemy.path_index
			if progress > best_progress:
				best_progress = progress
				first = enemy

	return first


## Get number of active enemies
func get_enemy_count() -> int:
	var count = 0
	for enemy in get_all_enemies():
		if is_instance_valid(enemy) and not enemy.is_dead:
			count += 1
	return count


# =============================================================================
# PUBLIC API - Level Management
# =============================================================================

## Set current level reference
func set_current_level(level: Node) -> void:
	_current_level = level
	_projectile_factory.set_current_level(level)


# =============================================================================
# INTERNAL METHODS
# =============================================================================

## Clean up destroyed projectiles from tracking array
func _cleanup_projectiles() -> void:
	var valid: Array[Node2D] = []
	for proj in active_projectiles:
		if is_instance_valid(proj):
			valid.append(proj)
	active_projectiles = valid


## Handle projectile destruction
func _on_projectile_destroyed(projectile: Projectile) -> void:
	active_projectiles.erase(projectile)


## Handle tower attack event
func _on_tower_attack_started(_tower: Node, _target: Node) -> void:
	# This can be used for global attack tracking/effects
	pass


# =============================================================================
# ENEMY CACHE MANAGEMENT
# =============================================================================

## Add enemy to cache when spawned
func _on_enemy_spawned(enemy: Node, _wave_number: int, _is_boss: bool) -> void:
	if is_instance_valid(enemy) and enemy not in _cached_enemies:
		_cached_enemies.append(enemy)


## Remove enemy from cache when killed
func _on_enemy_killed(enemy: Node, _killer: Node, _reward: int) -> void:
	_remove_from_cache(enemy)


## Remove enemy from cache when escaped
func _on_enemy_escaped(enemy: Node, _is_boss: bool) -> void:
	_remove_from_cache(enemy)


## Helper to safely remove enemy from cache
func _remove_from_cache(enemy: Node) -> void:
	var index = _cached_enemies.find(enemy)
	if index != -1:
		_cached_enemies.remove_at(index)


## Clear all enemies from cache (called on level reset/cleanup)
func clear_enemy_cache() -> void:
	_cached_enemies.clear()


## Refresh cache from scene tree (useful for recovery/debugging)
func refresh_enemy_cache() -> void:
	_cached_enemies.clear()
	if get_tree():
		_cached_enemies = get_tree().get_nodes_in_group("enemies")


## Get cached enemy count without iterating (for UI/debugging)
func get_cached_enemy_count() -> int:
	return _cached_enemies.size()


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Disconnect from EventBus signals to prevent memory leaks
	if EventBus:
		if EventBus.tower_attack_started.is_connected(_on_tower_attack_started):
			EventBus.tower_attack_started.disconnect(_on_tower_attack_started)
		if EventBus.enemy_spawned.is_connected(_on_enemy_spawned):
			EventBus.enemy_spawned.disconnect(_on_enemy_spawned)
		if EventBus.enemy_killed.is_connected(_on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)
		if EventBus.enemy_escaped.is_connected(_on_enemy_escaped):
			EventBus.enemy_escaped.disconnect(_on_enemy_escaped)

	# Clear cached data
	_cached_enemies.clear()
	active_projectiles.clear()

	# Clean up subsystems
	_projectile_factory = null
	_damage_processor = null
	_current_level = null
	_cache_initialized = false
