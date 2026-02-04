class_name EvolutionSystem
extends Node
## Handles evolution (digivolution) logic for Digimon towers.
## Manages evolution path validation, menu requests, and execution.

signal evolution_available(tower: DigimonTower)
signal evolution_menu_requested(tower: DigimonTower, options: Array[EvolutionPath])
signal evolution_completed(tower: DigimonTower, new_form: DigimonData)
signal evolution_failed(tower: DigimonTower, reason: String)

## Cache of all DigimonData resources by name
var _digimon_cache: Dictionary = {}

## Paths to Digimon resources by stage
const DIGIMON_RESOURCE_PATHS: Dictionary = {
	DigimonData.Stage.IN_TRAINING: "res://resources/digimon/in_training/",
	DigimonData.Stage.ROOKIE: "res://resources/digimon/rookie/",
	DigimonData.Stage.CHAMPION: "res://resources/digimon/champion/",
	DigimonData.Stage.ULTIMATE: "res://resources/digimon/ultimate/",
	DigimonData.Stage.MEGA: "res://resources/digimon/mega/",
	DigimonData.Stage.ULTRA: "res://resources/digimon/ultra/"
}

## Reference to GameManager for cost handling
var _game_manager: Node = null


func _ready() -> void:
	# Get GameManager reference
	_game_manager = get_node_or_null("/root/GameManager")

	# Load all DigimonData resources into cache
	_load_all_digimon_data()

	# Connect to EventBus
	if EventBus:
		EventBus.tower_selected.connect(_on_tower_selected)


## Load all DigimonData resources into the cache
func _load_all_digimon_data() -> void:
	_digimon_cache.clear()

	for stage in DIGIMON_RESOURCE_PATHS.keys():
		var path = DIGIMON_RESOURCE_PATHS[stage]
		_load_digimon_from_path(path)

	print("EvolutionSystem: Loaded %d Digimon into cache" % _digimon_cache.size())


## Load all DigimonData resources from a directory
func _load_digimon_from_path(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name.ends_with(".tres"):
			var full_path = dir_path + file_name
			var resource = load(full_path)
			if resource is DigimonData:
				_digimon_cache[resource.digimon_name] = resource
		file_name = dir.get_next()

	dir.list_dir_end()


## Check if a tower can evolve
func check_evolution_available(tower: DigimonTower) -> bool:
	if not tower or not tower.digimon_data:
		return false

	# Check basic digivolve requirements
	if not tower.can_digivolve():
		return false

	# Must have at least one available evolution path
	var paths = get_available_evolutions(tower)
	return paths.size() > 0


## Get all evolution paths for a tower (regardless of DP)
func get_all_evolutions(tower: DigimonTower) -> Array[EvolutionPath]:
	if not tower or not tower.digimon_data:
		return []

	return tower.get_evolution_paths()


## Get evolution paths unlocked by the tower's current DP
func get_available_evolutions(tower: DigimonTower) -> Array[EvolutionPath]:
	if not tower or not tower.digimon_data:
		return []

	return tower.get_available_evolutions()


## Request evolution menu to be shown for a tower
func request_evolution(tower: DigimonTower) -> void:
	if not tower or not tower.digimon_data:
		evolution_failed.emit(tower, "Invalid tower")
		return

	# Check if tower can digivolve
	if not tower.can_digivolve():
		var reason = _get_cannot_digivolve_reason(tower)
		evolution_failed.emit(tower, reason)
		return

	# Get all evolution paths (show locked ones grayed out)
	var all_paths = get_all_evolutions(tower)

	if all_paths.is_empty():
		evolution_failed.emit(tower, "No evolution paths available")
		return

	# Emit signal to show evolution menu
	evolution_menu_requested.emit(tower, all_paths)

	if EventBus:
		EventBus.ui_evolution_menu_opened.emit(tower, all_paths)


## Execute an evolution for a tower
func execute_evolution(tower: DigimonTower, evolution_path: EvolutionPath) -> void:
	if not tower or not tower.digimon_data:
		evolution_failed.emit(tower, "Invalid tower")
		return

	if not evolution_path:
		evolution_failed.emit(tower, "Invalid evolution path")
		return

	# Verify the path is available for current DP
	if not evolution_path.is_available(tower.current_dp):
		if evolution_path.is_locked(tower.current_dp):
			evolution_failed.emit(tower, "Need more DP for this evolution")
		else:
			evolution_failed.emit(tower, "DP is too high for this evolution")
		return

	# Get the new DigimonData
	var new_digimon = get_digimon_data(evolution_path.result_digimon)
	if not new_digimon:
		evolution_failed.emit(tower, "Evolution form not found: " + evolution_path.result_digimon)
		return

	# Check if player can afford the digivolve cost
	var cost = tower.get_digivolve_cost()
	if _game_manager and not _game_manager.can_afford(cost):
		evolution_failed.emit(tower, "Cannot afford evolution (need %d DB)" % cost)
		return

	# Deduct cost
	if _game_manager:
		_game_manager.spend_digibytes(cost)

	# Store old info for signal
	var old_stage = tower.digimon_data.stage
	var dp_used = tower.current_dp

	# Apply evolution
	tower.evolve_to(new_digimon)

	# Play evolution sound
	AudioManager.play_sfx("tower_evolve")

	# Emit signals
	evolution_completed.emit(tower, new_digimon)

	if EventBus:
		EventBus.tower_evolved.emit(tower, new_digimon.stage, new_digimon.digimon_name, dp_used)
		EventBus.floating_text_requested.emit(
			tower.global_position,
			"DIGIVOLVE!",
			Color.MAGENTA
		)
		EventBus.ui_evolution_menu_closed.emit()


## Get a DigimonData resource by name
func get_digimon_data(digimon_name: String) -> DigimonData:
	if _digimon_cache.has(digimon_name):
		return _digimon_cache[digimon_name]

	# Try to find it by searching (case insensitive)
	for name in _digimon_cache.keys():
		if name.to_lower() == digimon_name.to_lower():
			return _digimon_cache[name]

	ErrorHandler.log_warning("EvolutionSystem", "Digimon not found in cache: " + digimon_name)
	return null


## Get the reason why a tower cannot digivolve
func _get_cannot_digivolve_reason(tower: DigimonTower) -> String:
	if not tower or not tower.digimon_data:
		return "Invalid tower"

	if tower.current_level < tower.get_digivolve_threshold():
		return "Need level %d to digivolve" % tower.get_digivolve_threshold()

	if tower.digimon_data.stage >= GameConfig.STAGE_MEGA:
		return "Already at maximum stage"

	if tower.is_at_origin_cap():
		return "Origin prevents further evolution"

	if tower.digimon_data.evolutions.is_empty():
		return "No evolution paths defined"

	return "Cannot digivolve"


## Get evolution preview info for UI display
func get_evolution_preview(tower: DigimonTower, path: EvolutionPath) -> Dictionary:
	var preview: Dictionary = {
		"valid": false,
		"result_name": "",
		"result_stage": "",
		"dp_requirement": "",
		"is_locked": false,
		"is_past": false,
		"ability_preview": "",
		"description": "",
		"cost": 0,
		"can_afford": false
	}

	if not tower or not path:
		return preview

	preview["result_name"] = path.result_digimon
	preview["dp_requirement"] = path.get_requirement_text()
	preview["is_locked"] = path.is_locked(tower.current_dp)
	preview["is_past"] = path.is_past(tower.current_dp)
	preview["ability_preview"] = path.ability_preview
	preview["description"] = path.description
	preview["cost"] = tower.get_digivolve_cost()
	preview["can_afford"] = _game_manager.can_afford(preview["cost"]) if _game_manager else true

	# Get result DigimonData for stage info
	var result_data = get_digimon_data(path.result_digimon)
	if result_data:
		preview["result_stage"] = result_data.get_stage_name()
		preview["valid"] = true

	return preview


## Check all towers for evolution availability (useful for UI indicators)
func check_all_towers_for_evolution(grid_manager: GridManager) -> Array[DigimonTower]:
	var ready_towers: Array[DigimonTower] = []

	if not grid_manager:
		return ready_towers

	for tower in grid_manager.get_all_towers():
		if check_evolution_available(tower):
			ready_towers.append(tower)
			evolution_available.emit(tower)

	return ready_towers


## Handle tower selection - check if ready to evolve
func _on_tower_selected(tower: Node) -> void:
	if tower is DigimonTower:
		var digimon_tower = tower as DigimonTower
		if check_evolution_available(digimon_tower):
			evolution_available.emit(digimon_tower)


## Get all Digimon names in the cache
func get_all_digimon_names() -> Array[String]:
	var names: Array[String] = []
	for name in _digimon_cache.keys():
		names.append(name)
	return names


## Get all Digimon of a specific stage
func get_digimon_by_stage(stage: DigimonData.Stage) -> Array[DigimonData]:
	var result: Array[DigimonData] = []
	for data in _digimon_cache.values():
		if data.stage == stage:
			result.append(data)
	return result


## Get all Digimon of a specific attribute
func get_digimon_by_attribute(attribute: DigimonData.Attribute) -> Array[DigimonData]:
	var result: Array[DigimonData] = []
	for data in _digimon_cache.values():
		if data.attribute == attribute:
			result.append(data)
	return result


## Reload the Digimon cache (useful for hot reloading)
func reload_cache() -> void:
	_load_all_digimon_data()
