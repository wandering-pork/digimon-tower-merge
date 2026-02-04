class_name LevelData
extends Resource
## Resource class defining level-specific data including path waypoints.
## Used to configure different map layouts for each level.

## Grid positions for the path from spawn to end
## Each Vector2i represents a cell in the grid (column, row)
@export var path_waypoints: Array[Vector2i] = []

## The spawn point where enemies enter
@export var spawn_point: Vector2i = Vector2i.ZERO

## The end point where enemies exit (player's base)
@export var end_point: Vector2i = Vector2i.ZERO

## Level name for display
@export var level_name: String = "Level 1"

## Level description
@export var level_description: String = ""

## Number of waves in this level (0 = endless after base waves)
@export var total_waves: int = 100

## Starting DigiBytes for this level
@export var starting_digibytes: int = 200

## Starting lives for this level
@export var starting_lives: int = 20

## Get the total path length in tiles
func get_path_length() -> int:
	return path_waypoints.size()

## Get a waypoint at a specific index
func get_waypoint(index: int) -> Vector2i:
	if index >= 0 and index < path_waypoints.size():
		return path_waypoints[index]
	return Vector2i(-1, -1)

## Check if a grid position is on the path
func is_on_path(grid_pos: Vector2i) -> bool:
	return grid_pos in path_waypoints

## Check if a position is the spawn point
func is_spawn(grid_pos: Vector2i) -> bool:
	return grid_pos == spawn_point

## Check if a position is the end point
func is_end(grid_pos: Vector2i) -> bool:
	return grid_pos == end_point
