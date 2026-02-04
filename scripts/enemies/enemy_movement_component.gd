class_name EnemyMovementComponent
extends Node
## Component that handles enemy path following and movement.
##
## Manages path waypoints, movement along the path, knockback,
## and path progress calculations with O(1) cached lookups.

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when enemy reaches end of path
signal path_completed

# =============================================================================
# PATH DATA
# =============================================================================

## Current path waypoint index
var path_index: int = 0

## Array of path waypoint positions
var path_waypoints: Array[Vector2] = []

## Cached path data for O(1) progress calculations
var _cached_path_length: float = 0.0
var _cached_waypoint_distances: Array[float] = []

# =============================================================================
# REFERENCES
# =============================================================================

## Reference to parent enemy
var _enemy: Node = null

## Reference to effects component for speed modifiers
var _effects_component: Node = null

## Reference to sprite for flip
var _sprite: Sprite2D = null

# =============================================================================
# SETUP
# =============================================================================

## Setup the component with enemy reference and path waypoints.
func setup(enemy: Node, waypoints: Array[Vector2], effects_comp: Node = null, sprite: Sprite2D = null) -> void:
	_enemy = enemy
	_effects_component = effects_comp
	_sprite = sprite
	path_waypoints = waypoints
	path_index = 0

	if path_waypoints.size() > 0:
		_cache_path_data()


## Set position to spawn point (first waypoint).
func set_to_spawn() -> void:
	if _enemy and path_waypoints.size() > 0:
		_enemy.global_position = path_waypoints[0]

# =============================================================================
# PATH DATA CACHING
# =============================================================================

## Cache path data for O(1) progress calculations.
func _cache_path_data() -> void:
	_cached_path_length = 0.0
	_cached_waypoint_distances.clear()
	_cached_waypoint_distances.append(0.0)

	for i in range(1, path_waypoints.size()):
		var segment_length = path_waypoints[i - 1].distance_to(path_waypoints[i])
		_cached_path_length += segment_length
		_cached_waypoint_distances.append(_cached_path_length)

# =============================================================================
# MOVEMENT
# =============================================================================

## Follow the path to the end. Returns true if still moving, false if path complete.
func follow_path(delta: float, base_speed: float, enemy_speed_mult: float, modifier_speed_mult: float) -> bool:
	if not _enemy:
		return false

	if path_waypoints.size() == 0 or path_index >= path_waypoints.size():
		path_completed.emit()
		return false

	var target = path_waypoints[path_index]

	# Check if feared (moving backward)
	var is_feared = _effects_component and _effects_component.is_feared()
	if is_feared and path_index > 0:
		target = path_waypoints[path_index - 1]

	var direction = (target - _enemy.global_position).normalized()
	var effects_speed = _effects_component.get_speed_modifier() if _effects_component else 1.0
	var speed_modifier = enemy_speed_mult * modifier_speed_mult * effects_speed
	var move_distance = base_speed * speed_modifier * delta

	# Check if we've reached the waypoint (using squared distance for performance)
	var distance_sq_to_target = _enemy.global_position.distance_squared_to(target)
	var move_distance_sq = move_distance * move_distance

	if distance_sq_to_target <= move_distance_sq:
		_enemy.global_position = target

		if is_feared:
			path_index = maxi(0, path_index - 1)
		else:
			path_index += 1

		# Check if we've reached the end
		if path_index >= path_waypoints.size():
			path_completed.emit()
			return false
	else:
		_enemy.global_position += direction * move_distance

		# Rotate sprite to face movement direction
		if _sprite:
			_sprite.flip_h = direction.x < 0

	return true


## Apply knockback effect, pushing enemy backward along the path.
func apply_knockback(distance_tiles: float, tile_size: float = 64.0) -> void:
	if not _enemy or path_index <= 0:
		return

	var pixels_to_move = distance_tiles * tile_size
	var remaining = pixels_to_move

	while remaining > 0 and path_index > 0:
		var prev_waypoint = path_waypoints[path_index - 1]
		var dist_to_prev = _enemy.global_position.distance_to(prev_waypoint)

		if dist_to_prev <= remaining:
			_enemy.global_position = prev_waypoint
			remaining -= dist_to_prev
			path_index -= 1
		else:
			var direction = (prev_waypoint - _enemy.global_position).normalized()
			_enemy.global_position += direction * remaining
			remaining = 0

# =============================================================================
# PATH PROGRESS QUERIES
# =============================================================================

## Get remaining distance to end of path (O(1) using cached data).
func get_remaining_distance() -> float:
	if not _enemy or path_waypoints.size() == 0 or _cached_path_length <= 0.0:
		return 0.0

	var distance_to_current: float = 0.0
	if path_index < path_waypoints.size():
		distance_to_current = _enemy.global_position.distance_to(path_waypoints[path_index])

	var distance_from_waypoint_to_end: float = 0.0
	if path_index < _cached_waypoint_distances.size():
		distance_from_waypoint_to_end = _cached_path_length - _cached_waypoint_distances[path_index]

	return distance_to_current + distance_from_waypoint_to_end


## Get path progress as a value from 0.0 to 1.0 (1.0 = at end).
## O(1) complexity using cached path data.
func get_path_progress() -> float:
	if not _enemy or _cached_path_length <= 0.0:
		return 0.0

	var distance_traveled: float = 0.0
	if path_index > 0 and path_index < _cached_waypoint_distances.size():
		distance_traveled = _cached_waypoint_distances[path_index - 1]
		var prev_waypoint = path_waypoints[path_index - 1]
		distance_traveled += prev_waypoint.distance_to(_enemy.global_position)
	elif path_index > 0:
		distance_traveled = _cached_path_length

	return clampf(distance_traveled / _cached_path_length, 0.0, 1.0)

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	_enemy = null
	_effects_component = null
	_sprite = null
	path_waypoints.clear()
	_cached_waypoint_distances.clear()
