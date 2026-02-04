class_name GridManager
extends Node2D
## Manages the game grid, tower placement, and cell queries.
## Delegates path management to PathManager component.
##
## Refactored Feb 2026: Path logic extracted to path_manager.gd
## This file handles: grid state, tower placement validation, cell type queries
## PathManager handles: path initialization, waypoints, navigation

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const PathManager = preload("res://scripts/systems/path_manager.gd")
const LevelData = preload("res://scripts/data/level_data.gd")

signal tower_placed(grid_pos: Vector2i, tower: Node)  # DigimonTower - avoid circular dependency
signal tower_removed(grid_pos: Vector2i, tower: Node)  # DigimonTower - avoid circular dependency
signal cell_hovered(grid_pos: Vector2i, cell_type: CellType)

## Cell type enum for grid management
enum CellType {
	TOWER_SLOT,  ## Can place a tower here
	PATH,        ## Enemy path tile
	SPAWN,       ## Enemy spawn point
	END          ## Player base / enemy goal
}

## Grid dimensions
const GRID_COLS: int = 8
const GRID_ROWS: int = 18

## Tile size in pixels
const TILE_SIZE: int = 64

## Total counts based on GDD
const TOTAL_TOWER_SLOTS: int = 87
const TOTAL_PATH_TILES: int = 57

## The level data resource containing path waypoints
@export var level_data: LevelData

## Internal grid state
## Key: Vector2i (grid position), Value: CellType
var _grid: Dictionary = {}

## Placed towers
## Key: Vector2i (grid position), Value: Node (DigimonTower)
var _towers: Dictionary = {}

## Path manager component (handles path/waypoint logic)
var _path_manager: Node = null  # PathManager

func _ready() -> void:
	_initialize_grid()
	_initialize_path_manager()

func _exit_tree() -> void:
	# Clean up references to prevent memory leaks
	_towers.clear()
	_grid.clear()
	if _path_manager:
		_path_manager.queue_free()
		_path_manager = null

## Initialize the grid with all cells as tower slots
func _initialize_grid() -> void:
	_grid.clear()
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var pos = Vector2i(col, row)
			_grid[pos] = CellType.TOWER_SLOT

## Initialize the path manager component
func _initialize_path_manager() -> void:
	_path_manager = PathManager.new()
	_path_manager.name = "PathManager"
	add_child(_path_manager)
	_path_manager.initialize(self, level_data)

	# Mark path tiles in the grid based on PathManager data
	_mark_path_tiles()

## Mark path tiles in the grid from PathManager waypoints
func _mark_path_tiles() -> void:
	var waypoints = _path_manager.get_path_waypoints_grid()
	if waypoints.size() == 0:
		return

	# Mark spawn
	_grid[waypoints[0]] = CellType.SPAWN

	# Mark end
	_grid[waypoints[waypoints.size() - 1]] = CellType.END

	# Mark path tiles (all waypoints except first and last)
	for i in range(1, waypoints.size() - 1):
		_grid[waypoints[i]] = CellType.PATH

# =============================================================================
# CELL QUERIES
# =============================================================================

## Get the cell type at a grid position
func get_cell_type(grid_pos: Vector2i) -> CellType:
	if _grid.has(grid_pos):
		return _grid[grid_pos]
	return CellType.TOWER_SLOT

## Check if a position is a tower slot
func is_tower_slot(grid_pos: Vector2i) -> bool:
	return get_cell_type(grid_pos) == CellType.TOWER_SLOT

## Check if a grid position is within bounds
func _is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	return (
		grid_pos.x >= 0 and grid_pos.x < GRID_COLS and
		grid_pos.y >= 0 and grid_pos.y < GRID_ROWS
	)

# =============================================================================
# TOWER PLACEMENT
# =============================================================================

## Check if a tower can be placed at a position
func can_place_tower(grid_pos: Vector2i) -> bool:
	# Must be a valid tower slot
	if not is_tower_slot(grid_pos):
		return false
	# Must not already have a tower
	if _towers.has(grid_pos):
		return false
	# Must be within grid bounds
	if not _is_valid_grid_pos(grid_pos):
		return false
	return true

## Place a tower at a grid position
## Returns true if successful
func place_tower(grid_pos: Vector2i, tower: Node) -> bool:  # DigimonTower - avoid circular dependency
	if not can_place_tower(grid_pos):
		return false

	_towers[grid_pos] = tower
	tower.grid_position = grid_pos
	tower.position = grid_to_world(grid_pos)

	# Update adjacent towers
	_update_adjacent_towers(grid_pos)

	emit_signal("tower_placed", grid_pos, tower)
	return true

## Remove a tower from a grid position
## Returns the removed tower or null
func remove_tower(grid_pos: Vector2i) -> Node:  # DigimonTower - avoid circular dependency
	if not _towers.has(grid_pos):
		return null

	var tower = _towers[grid_pos]
	_towers.erase(grid_pos)

	# Update adjacent towers for neighbors
	_update_adjacent_towers(grid_pos)

	emit_signal("tower_removed", grid_pos, tower)
	return tower

## Get the tower at a grid position
func get_tower_at(grid_pos: Vector2i) -> Node:  # DigimonTower - avoid circular dependency
	if _towers.has(grid_pos):
		return _towers[grid_pos]
	return null

## Get adjacent towers (orthogonal only)
func get_adjacent_towers(grid_pos: Vector2i) -> Array[Node]:  # Array[DigimonTower] - avoid circular dependency
	var adjacent: Array[Node] = []  # Array[DigimonTower]
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	for dir in directions:
		var neighbor_pos = grid_pos + dir
		if _towers.has(neighbor_pos):
			adjacent.append(_towers[neighbor_pos])

	return adjacent

## Get all placed towers
func get_all_towers() -> Array[Node]:  # Array[DigimonTower] - avoid circular dependency
	var towers: Array[Node] = []  # Array[DigimonTower]
	for tower in _towers.values():
		towers.append(tower)
	return towers

## Get total number of placed towers
func get_tower_count() -> int:
	return _towers.size()

## Update adjacent tower references for a position and its neighbors
func _update_adjacent_towers(grid_pos: Vector2i) -> void:
	var directions = [
		Vector2i(0, -1),  # Up
		Vector2i(0, 1),   # Down
		Vector2i(-1, 0),  # Left
		Vector2i(1, 0)    # Right
	]

	# Update the tower at this position
	if _towers.has(grid_pos):
		_towers[grid_pos].set_adjacent_towers(get_adjacent_towers(grid_pos))

	# Update neighboring towers
	for dir in directions:
		var neighbor_pos = grid_pos + dir
		if _towers.has(neighbor_pos):
			_towers[neighbor_pos].set_adjacent_towers(get_adjacent_towers(neighbor_pos))

## Get all available tower slot positions
func get_available_slots() -> Array[Vector2i]:
	var slots: Array[Vector2i] = []
	for pos in _grid.keys():
		if can_place_tower(pos):
			slots.append(pos)
	return slots

## Get total available tower slots (including occupied)
func get_total_tower_slots() -> int:
	var count = 0
	for pos in _grid.keys():
		if _grid[pos] == CellType.TOWER_SLOT:
			count += 1
	return count

## Get towers within a certain range of a world position
func get_towers_in_range(world_pos: Vector2, range_tiles: float) -> Array[Node]:  # Array[DigimonTower] - avoid circular dependency
	var in_range: Array[Node] = []  # Array[DigimonTower]
	var range_pixels = range_tiles * TILE_SIZE

	for tower in _towers.values():
		var distance = tower.position.distance_to(world_pos)
		if distance <= range_pixels:
			in_range.append(tower)

	return in_range

# =============================================================================
# COORDINATE CONVERSION
# =============================================================================

## Convert grid position to world position (center of cell)
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)

## Convert world position to grid position
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

## Get the grid size in pixels
func get_grid_pixel_size() -> Vector2:
	return Vector2(GRID_COLS * TILE_SIZE, GRID_ROWS * TILE_SIZE)

# =============================================================================
# PATH DELEGATION (forwarded to PathManager)
# =============================================================================

## Get the path waypoints in world coordinates
func get_path_waypoints() -> Array[Vector2]:
	if _path_manager:
		return _path_manager.get_path_waypoints()
	return []

## Get the path waypoints in grid coordinates
func get_path_waypoints_grid() -> Array[Vector2i]:
	if _path_manager:
		return _path_manager.get_path_waypoints_grid()
	return []

## Get the spawn position in world coordinates
func get_spawn_world() -> Vector2:
	if _path_manager:
		return _path_manager.get_spawn_world()
	return Vector2.ZERO

## Get the end position in world coordinates
func get_end_world() -> Vector2:
	if _path_manager:
		return _path_manager.get_end_world()
	return Vector2.ZERO

## Get the spawn position in grid coordinates
func get_spawn_grid() -> Vector2i:
	if _path_manager:
		return _path_manager.get_spawn_grid()
	return Vector2i.ZERO

## Get the end position in grid coordinates
func get_end_grid() -> Vector2i:
	if _path_manager:
		return _path_manager.get_end_grid()
	return Vector2i.ZERO

## Get path length in tiles
func get_path_length() -> int:
	if _path_manager:
		return _path_manager.get_path_length()
	return 0

## Check if a grid position is on the path
func is_path_tile(grid_pos: Vector2i) -> bool:
	var cell_type = get_cell_type(grid_pos)
	return cell_type == CellType.PATH or cell_type == CellType.SPAWN or cell_type == CellType.END

# =============================================================================
# DEBUG
# =============================================================================

## Debug function to print grid state
func debug_print_grid() -> void:
	print("Grid State:")
	for row in range(GRID_ROWS):
		var line = ""
		for col in range(GRID_COLS):
			var pos = Vector2i(col, row)
			match get_cell_type(pos):
				CellType.SPAWN:
					line += "S "
				CellType.END:
					line += "E "
				CellType.PATH:
					line += ". "
				CellType.TOWER_SLOT:
					if _towers.has(pos):
						line += "T "
					else:
						line += "_ "
		print(line)
