class_name SpawnSystem
extends Node
## Central spawn management system for Digimon towers.
## Handles loading DigimonData resources, spawning towers, and cost calculations.
##
## NOTE: Spawn costs and resource paths are defined in GameConfig autoload.

signal tower_spawned(tower: DigimonTower, grid_pos: Vector2i)

## Preloaded tower scene
const TOWER_SCENE_PATH = "res://scenes/towers/digimon_tower.tscn"
var _tower_scene: PackedScene

## Cached DigimonData resources
## Structure: { stage: { attribute: [DigimonData, ...] } }
var _digimon_cache: Dictionary = {}

## Lookup by name for quick access
## Structure: { "digimon_name": DigimonData }
var _name_lookup: Dictionary = {}

## Reference to grid manager (set externally)
var _grid_manager: GridManager = null

## Reference to tower container node (set externally)
var _tower_container: Node2D = null

func _ready() -> void:
	_load_tower_scene()
	_preload_all_digimon()

func _load_tower_scene() -> void:
	if ResourceLoader.exists(TOWER_SCENE_PATH):
		_tower_scene = load(TOWER_SCENE_PATH)
	else:
		ErrorHandler.log_error("SpawnSystem", "Tower scene not found at: %s" % TOWER_SCENE_PATH)

func _preload_all_digimon() -> void:
	## Load all DigimonData resources and cache them
	for stage in GameConfig.STAGE_RESOURCE_PATHS.keys():
		var path = GameConfig.STAGE_RESOURCE_PATHS[stage]
		_load_stage_resources(stage, path)

func _load_stage_resources(stage: int, dir_path: String) -> void:
	## Load all .tres files from a stage directory
	if not _digimon_cache.has(stage):
		_digimon_cache[stage] = {
			DigimonData.Attribute.VACCINE: [],
			DigimonData.Attribute.DATA: [],
			DigimonData.Attribute.VIRUS: [],
			DigimonData.Attribute.FREE: []
		}

	var dir = DirAccess.open(dir_path)
	if dir == null:
		ErrorHandler.log_warning("SpawnSystem", "Could not open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path = dir_path + file_name
			var data = load(resource_path) as DigimonData

			if data:
				# Add to attribute-sorted cache
				var attr = data.attribute
				if _digimon_cache[stage].has(attr):
					_digimon_cache[stage][attr].append(data)
				else:
					_digimon_cache[stage][attr] = [data]

				# Add to name lookup
				_name_lookup[data.digimon_name.to_lower()] = data

		file_name = dir.get_next()

	dir.list_dir_end()

## Set the grid manager reference
func set_grid_manager(manager: GridManager) -> void:
	_grid_manager = manager

## Set the tower container node
func set_tower_container(container: Node2D) -> void:
	_tower_container = container

## Get a random Digimon for a specific stage and optionally attribute
## If attribute is -1, picks random attribute (excluding FREE)
func get_random_digimon_for_stage(stage: int, attribute: int = -1) -> DigimonData:
	if not _digimon_cache.has(stage):
		ErrorHandler.log_error("SpawnSystem", "No cached data for stage: %d" % stage)
		return null

	var stage_data = _digimon_cache[stage]

	if attribute == -1:
		# Random attribute (excluding FREE)
		var valid_attrs = [
			DigimonData.Attribute.VACCINE,
			DigimonData.Attribute.DATA,
			DigimonData.Attribute.VIRUS
		]
		attribute = valid_attrs[randi() % valid_attrs.size()]

	if not stage_data.has(attribute) or stage_data[attribute].is_empty():
		ErrorHandler.log_warning("SpawnSystem", "No Digimon found for stage %d, attribute %d" % [stage, attribute])
		# Try to find any Digimon at this stage
		for attr in stage_data.keys():
			if not stage_data[attr].is_empty():
				return stage_data[attr][randi() % stage_data[attr].size()]
		return null

	var candidates = stage_data[attribute]
	return candidates[randi() % candidates.size()]

## Get a specific Digimon by name
func get_digimon_by_name(digimon_name: String) -> DigimonData:
	var key = digimon_name.to_lower()
	if _name_lookup.has(key):
		return _name_lookup[key]
	return null

## Get all Digimon of a specific stage
func get_all_digimon_for_stage(stage: int) -> Array[DigimonData]:
	var result: Array[DigimonData] = []
	if not _digimon_cache.has(stage):
		return result

	for attr in _digimon_cache[stage].keys():
		for data in _digimon_cache[stage][attr]:
			result.append(data)

	return result

## Get all Digimon of a specific attribute at a stage
func get_digimon_by_attribute(stage: int, attribute: int) -> Array[DigimonData]:
	var result: Array[DigimonData] = []
	if not _digimon_cache.has(stage):
		return result

	if _digimon_cache[stage].has(attribute):
		for data in _digimon_cache[stage][attribute]:
			result.append(data)

	return result

## Calculate spawn cost for given parameters
func get_spawn_cost(stage: int, spawn_type: String, _attribute: int = -1) -> int:
	return GameConfig.get_spawn_cost(stage, spawn_type)

## Spawn a new tower at the given grid position
## Returns the spawned tower or null if spawn failed
func spawn_tower(grid_pos: Vector2i, digimon_data: DigimonData, origin: int) -> DigimonTower:
	if not _tower_scene:
		ErrorHandler.log_error("SpawnSystem", "Tower scene not loaded")
		return null

	if not _grid_manager:
		ErrorHandler.log_error("SpawnSystem", "Grid manager not set")
		return null

	if not _grid_manager.can_place_tower(grid_pos):
		ErrorHandler.log_warning("SpawnSystem", "Cannot place tower at position: %s" % str(grid_pos))
		return null

	# Instance the tower
	var tower = _tower_scene.instantiate() as DigimonTower
	if not tower:
		ErrorHandler.log_error("SpawnSystem", "Failed to instantiate tower scene")
		return null

	# Set up tower data
	tower.digimon_data = digimon_data
	tower.origin_stage = origin
	tower.current_level = 1
	tower.current_dp = 0
	tower.set_grid_manager(_grid_manager)

	# Add to container
	if _tower_container:
		_tower_container.add_child(tower)
	else:
		ErrorHandler.log_warning("SpawnSystem", "No tower container set, adding to spawn system")
		add_child(tower)

	# Place on grid
	_grid_manager.place_tower(grid_pos, tower)

	# Emit signals
	tower_spawned.emit(tower, grid_pos)

	if EventBus:
		EventBus.tower_spawned.emit(
			tower,
			grid_pos,
			digimon_data.stage,
			digimon_data.get_attribute_name()
		)

	return tower

## Spawn a random Digimon tower of the given stage
func spawn_random_tower(grid_pos: Vector2i, stage: int, attribute: int = -1) -> DigimonTower:
	var data = get_random_digimon_for_stage(stage, attribute)
	if not data:
		ErrorHandler.log_error("SpawnSystem", "Could not get random Digimon for stage: %d" % stage)
		return null

	return spawn_tower(grid_pos, data, stage)

## Spawn a specific Digimon by name
func spawn_named_tower(grid_pos: Vector2i, digimon_name: String) -> DigimonTower:
	var data = get_digimon_by_name(digimon_name)
	if not data:
		ErrorHandler.log_error("SpawnSystem", "Could not find Digimon: %s" % digimon_name)
		return null

	return spawn_tower(grid_pos, data, data.stage)

## Handle spawn request from SpawnMenu
func handle_spawn_request(grid_pos: Vector2i, stage: int, attribute: int, cost: int) -> bool:
	# Check if player can afford
	if not GameManager.spend_digibytes(cost):
		return false

	# Get appropriate Digimon
	var data = get_random_digimon_for_stage(stage, attribute)
	if not data:
		# Refund if spawn fails
		GameManager.add_digibytes(cost)
		return false

	# Spawn the tower
	var tower = spawn_tower(grid_pos, data, stage)
	if not tower:
		# Refund if spawn fails
		GameManager.add_digibytes(cost)
		return false

	# Track the initial investment for sell value calculation
	tower.total_investment = cost

	return true

## Spawn the player's free starter Digimon
func spawn_starter(grid_pos: Vector2i, starter_data: DigimonData) -> DigimonTower:
	if not starter_data:
		ErrorHandler.log_error("SpawnSystem", "No starter data provided")
		return null

	# Starters are always In-Training origin
	return spawn_tower(grid_pos, starter_data, DigimonData.Stage.IN_TRAINING)

## Get total count of cached Digimon
func get_total_digimon_count() -> int:
	var count = 0
	for stage in _digimon_cache.keys():
		for attr in _digimon_cache[stage].keys():
			count += _digimon_cache[stage][attr].size()
	return count

## Get count by stage
func get_stage_count(stage: int) -> int:
	var count = 0
	if _digimon_cache.has(stage):
		for attr in _digimon_cache[stage].keys():
			count += _digimon_cache[stage][attr].size()
	return count

## Debug: Print cached Digimon summary
func debug_print_cache() -> void:
	print("=== SpawnSystem Cache ===")
	print("Total Digimon: %d" % get_total_digimon_count())
	for stage in _digimon_cache.keys():
		var stage_name = ["In-Training", "Rookie", "Champion", "Ultimate", "Mega", "Ultra"][stage]
		print("  %s: %d" % [stage_name, get_stage_count(stage)])
		for attr in _digimon_cache[stage].keys():
			var attr_names = ["Vaccine", "Data", "Virus", "Free"]
			if _digimon_cache[stage][attr].size() > 0:
				print("    %s: %d" % [attr_names[attr], _digimon_cache[stage][attr].size()])
