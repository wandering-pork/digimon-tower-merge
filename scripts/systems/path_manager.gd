class_name PathManager
extends Node
## Manages the enemy path, waypoints, and navigation.
## Handles path initialization, waypoint queries, and coordinate conversions for the path.
##
## This component was extracted from GridManager during the Feb 2026 refactoring.
## GridManager handles grid state and tower placement; PathManager handles path logic.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const LevelData = preload("res://scripts/data/level_data.gd")

## Path waypoints in world coordinates (cached for performance)
var _path_waypoints_world: Array[Vector2] = []

## Path waypoints in grid coordinates
var _path_waypoints_grid: Array[Vector2i] = []

## Reference to grid manager for coordinate conversion
var _grid_manager: Node = null

## Tile size in pixels (must match GridManager)
const TILE_SIZE: int = 64

func _ready() -> void:
	# PathManager is initialized by GridManager after being added as child
	pass

func _exit_tree() -> void:
	# Clear references to prevent memory leaks
	_grid_manager = null
	_path_waypoints_world.clear()
	_path_waypoints_grid.clear()

## Initialize the path manager with a reference to the grid manager
func initialize(grid_manager: Node, level_data: LevelData = null) -> void:
	_grid_manager = grid_manager

	if level_data:
		_load_path_from_level_data(level_data)
	else:
		_initialize_default_path()

	_cache_path_waypoints()

## Load path from LevelData resource
func _load_path_from_level_data(level_data: LevelData) -> void:
	if not level_data:
		return

	_path_waypoints_grid = level_data.path_waypoints.duplicate()

## Initialize the default serpentine path from GDD
## Path starts at (0,1) SPAWN and ends at (7,14) END
## Total: 57 path tiles, 15 direction changes
##
## ============================================================================
## ASCII MAP REFERENCE (from CLAUDE.md)
## ============================================================================
##
##      Col: 0    1    2    3    4    5    6    7
##         +----+----+----+----+----+----+----+----+
## Row 0   | T  | T  | T  | T  | T  | T  | T  | T  |
## Row 1   | S->| -> | v  | T  | T  | T  | T  | T  |
## Row 2   | T  | T  | v  | T  | -> | -> | v  | T  |
## Row 3   | T  | T  | v  | T  | ^  | T  | v  | T  |
## Row 4   | T  | v  | <- | T  | ^  | T  | v  | T  |
## Row 5   | T  | v  | T  | T  | ^  | T  | v  | T  |
## Row 6   | T  | -> | -> | -> | ^  | T  | v  | T  |
## Row 7   | T  | T  | T  | T  | T  | T  | v  | T  |
## Row 8   | <- | <- | ^  | T  | T  | T  | v  | T  |
## Row 9   | v  | T  | ^  | T  | T  | T  | v  | T  |
## Row 10  | v  | T  | ^  | T  | T  | T  | v  | T  |
## Row 11  | v  | T  | ^  | T  | T  | T  | v  | T  |
## Row 12  | v  | T  | <- | <- | <- | <- | v  | T  |
## Row 13  | v  | T  | T  | T  | T  | T  | T  | T  |
## Row 14  | v  | T  | T  | -> | -> | -> | -> | E  |
## Row 15  | v  | T  | T  | ^  | T  | T  | T  | T  |
## Row 16  | v  | T  | T  | ^  | T  | T  | T  | T  |
## Row 17  | -> | -> | -> | ^  | T  | T  | T  | T  |
##         +----+----+----+----+----+----+----+----+
##
## S = Spawn | E = End/Base | T = Tower Slot | ->v<-^ = Path Direction
##
## ============================================================================
## PATH TRACE (15 segments, 57 tiles)
## ============================================================================
##
## GDD uses 1-indexed columns and rows, code uses 0-indexed
## GDD Col 1 = Code col 0, GDD Row 1 = Code row 0
##
## Segment-by-segment trace showing enemy travel direction:
##
##  1. SPAWN -> RIGHT    (0,1) -> (2,1)     [3 tiles]
##  2. DOWN              (2,2) -> (2,4)     [3 tiles]
##  3. LEFT              (2,4) -> (1,4)     [1 tile]
##  4. DOWN              (1,5) -> (1,6)     [2 tiles]
##  5. RIGHT             (2,6) -> (4,6)     [3 tiles]
##  6. UP                (4,5) -> (4,2)     [4 tiles]
##  7. RIGHT             (5,2) -> (6,2)     [2 tiles]
##  8. DOWN              (6,3) -> (6,12)    [10 tiles]
##  9. LEFT              (5,12) -> (2,12)   [4 tiles]
## 10. UP                (2,11) -> (2,8)    [4 tiles]
## 11. LEFT              (1,8) -> (0,8)     [2 tiles]
## 12. DOWN              (0,9) -> (0,17)    [9 tiles]
## 13. RIGHT             (1,17) -> (3,17)   [3 tiles]
## 14. UP                (3,16) -> (3,14)   [3 tiles]
## 15. RIGHT -> END      (4,14) -> (7,14)   [4 tiles]
##
## Total: 57 tiles | 15 direction changes
## ============================================================================
func _initialize_default_path() -> void:
	_path_waypoints_grid.clear()

	# =========================================================================
	# Segment 1: SPAWN (0,1) -> RIGHT to (2,1) [3 tiles]
	# Row 1: S-> -> v
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(0, 1))  # SPAWN
	_path_waypoints_grid.append(Vector2i(1, 1))
	_path_waypoints_grid.append(Vector2i(2, 1))

	# =========================================================================
	# Segment 2: DOWN from (2,2) to (2,4) [3 tiles]
	# Cols 2, Rows 2-4: v v v
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(2, 2))
	_path_waypoints_grid.append(Vector2i(2, 3))
	_path_waypoints_grid.append(Vector2i(2, 4))

	# =========================================================================
	# Segment 3: LEFT from (2,4) to (1,4) [1 tile]
	# Row 4: v <-
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(1, 4))

	# =========================================================================
	# Segment 4: DOWN from (1,5) to (1,6) [2 tiles]
	# Col 1, Rows 5-6: v v
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(1, 5))
	_path_waypoints_grid.append(Vector2i(1, 6))

	# =========================================================================
	# Segment 5: RIGHT from (2,6) to (4,6) [3 tiles]
	# Row 6: -> -> -> ^
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(2, 6))
	_path_waypoints_grid.append(Vector2i(3, 6))
	_path_waypoints_grid.append(Vector2i(4, 6))

	# =========================================================================
	# Segment 6: UP from (4,5) to (4,2) [4 tiles]
	# Col 4, Rows 5-2: ^ ^ ^ ^
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(4, 5))
	_path_waypoints_grid.append(Vector2i(4, 4))
	_path_waypoints_grid.append(Vector2i(4, 3))
	_path_waypoints_grid.append(Vector2i(4, 2))

	# =========================================================================
	# Segment 7: RIGHT from (5,2) to (6,2) [2 tiles]
	# Row 2: -> -> v
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(5, 2))
	_path_waypoints_grid.append(Vector2i(6, 2))

	# =========================================================================
	# Segment 8: DOWN from (6,3) to (6,12) [10 tiles]
	# Col 6, Rows 3-12: v v v v v v v v v v
	# This is the longest vertical segment
	# =========================================================================
	for row in range(3, 13):
		_path_waypoints_grid.append(Vector2i(6, row))

	# =========================================================================
	# Segment 9: LEFT from (5,12) to (2,12) [4 tiles]
	# Row 12: <- <- <- <-
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(5, 12))
	_path_waypoints_grid.append(Vector2i(4, 12))
	_path_waypoints_grid.append(Vector2i(3, 12))
	_path_waypoints_grid.append(Vector2i(2, 12))

	# =========================================================================
	# Segment 10: UP from (2,11) to (2,8) [4 tiles]
	# Col 2, Rows 11-8: ^ ^ ^ ^
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(2, 11))
	_path_waypoints_grid.append(Vector2i(2, 10))
	_path_waypoints_grid.append(Vector2i(2, 9))
	_path_waypoints_grid.append(Vector2i(2, 8))

	# =========================================================================
	# Segment 11: LEFT from (1,8) to (0,8) [2 tiles]
	# Row 8: <- <-
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(1, 8))
	_path_waypoints_grid.append(Vector2i(0, 8))

	# =========================================================================
	# Segment 12: DOWN from (0,9) to (0,17) [9 tiles]
	# Col 0, Rows 9-17: v v v v v v v v v
	# Second longest vertical segment
	# =========================================================================
	for row in range(9, 18):
		_path_waypoints_grid.append(Vector2i(0, row))

	# =========================================================================
	# Segment 13: RIGHT from (1,17) to (3,17) [3 tiles]
	# Row 17: -> -> -> ^
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(1, 17))
	_path_waypoints_grid.append(Vector2i(2, 17))
	_path_waypoints_grid.append(Vector2i(3, 17))

	# =========================================================================
	# Segment 14: UP from (3,16) to (3,14) [3 tiles]
	# Col 3, Rows 16-14: ^ ^ ^
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(3, 16))
	_path_waypoints_grid.append(Vector2i(3, 15))
	_path_waypoints_grid.append(Vector2i(3, 14))

	# =========================================================================
	# Segment 15: RIGHT from (4,14) to (7,14) -> END [4 tiles]
	# Row 14: -> -> -> -> E
	# =========================================================================
	_path_waypoints_grid.append(Vector2i(4, 14))
	_path_waypoints_grid.append(Vector2i(5, 14))
	_path_waypoints_grid.append(Vector2i(6, 14))
	_path_waypoints_grid.append(Vector2i(7, 14))  # END

## Cache world coordinates for path waypoints
func _cache_path_waypoints() -> void:
	_path_waypoints_world.clear()
	for grid_pos in _path_waypoints_grid:
		_path_waypoints_world.append(_grid_to_world(grid_pos))

## Convert grid position to world position (center of cell)
## Internal helper - uses same logic as GridManager
func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)

# =============================================================================
# PUBLIC API - Path Queries
# =============================================================================

## Get the path waypoints in world coordinates
func get_path_waypoints() -> Array[Vector2]:
	return _path_waypoints_world

## Get the path waypoints in grid coordinates
func get_path_waypoints_grid() -> Array[Vector2i]:
	return _path_waypoints_grid

## Get the spawn position in world coordinates
func get_spawn_world() -> Vector2:
	if _path_waypoints_world.size() > 0:
		return _path_waypoints_world[0]
	return Vector2.ZERO

## Get the end position in world coordinates
func get_end_world() -> Vector2:
	if _path_waypoints_world.size() > 0:
		return _path_waypoints_world[_path_waypoints_world.size() - 1]
	return Vector2.ZERO

## Get the spawn position in grid coordinates
func get_spawn_grid() -> Vector2i:
	if _path_waypoints_grid.size() > 0:
		return _path_waypoints_grid[0]
	return Vector2i.ZERO

## Get the end position in grid coordinates
func get_end_grid() -> Vector2i:
	if _path_waypoints_grid.size() > 0:
		return _path_waypoints_grid[_path_waypoints_grid.size() - 1]
	return Vector2i.ZERO

## Get path length in tiles
func get_path_length() -> int:
	return _path_waypoints_grid.size()

## Check if a grid position is on the path
func is_path_tile(grid_pos: Vector2i) -> bool:
	return grid_pos in _path_waypoints_grid
