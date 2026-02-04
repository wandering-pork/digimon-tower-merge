extends Node
## SaveSystem Autoload Singleton
##
## Handles saving and loading game state to persistent storage.
## Auto-saves after each wave completion for convenience.
##
## Save file location: user://savegame.json

# =============================================================================
# CONSTANTS
# =============================================================================

## Save file path
const SAVE_FILE_PATH: String = "user://savegame.json"

## Save file version for future compatibility
const SAVE_VERSION: int = 1

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when a save operation completes
## success: Whether the save was successful
signal save_completed(success: bool)

## Emitted when a load operation completes
## success: Whether the load was successful
signal load_completed(success: bool)

# =============================================================================
# STATE
# =============================================================================

## Reference to the current main level (set by main_level.gd)
var _current_level: Node = null

## Whether auto-save is enabled
var _auto_save_enabled: bool = true


# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Connect to wave_completed signal for auto-save
	if EventBus:
		EventBus.wave_completed.connect(_on_wave_completed)

	ErrorHandler.log_info("SaveSystem", "SaveSystem initialized")


func _exit_tree() -> void:
	# Disconnect signals
	if EventBus and EventBus.wave_completed.is_connected(_on_wave_completed):
		EventBus.wave_completed.disconnect(_on_wave_completed)

	_current_level = null


# =============================================================================
# PUBLIC API
# =============================================================================

## Set the current level reference (called by main_level.gd)
func set_current_level(level: Node) -> void:
	_current_level = level


## Enable or disable auto-save after waves
func set_auto_save_enabled(enabled: bool) -> void:
	_auto_save_enabled = enabled


## Check if a save file exists
## Returns: true if a save file exists, false otherwise
func has_save_game() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)


## Save the current game state
## Returns: true if save was successful, false otherwise
func save_game() -> bool:
	if not _current_level:
		ErrorHandler.log_warning("SaveSystem", "Cannot save: no current level set")
		save_completed.emit(false)
		return false

	var save_data = _build_save_data()
	if save_data.is_empty():
		ErrorHandler.log_error("SaveSystem", "Failed to build save data")
		save_completed.emit(false)
		return false

	var json_string = JSON.stringify(save_data, "\t")

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		ErrorHandler.log_error("SaveSystem", "Failed to open save file for writing: %s" % error_string(error))
		save_completed.emit(false)
		return false

	file.store_string(json_string)
	file.close()

	ErrorHandler.log_info("SaveSystem", "Game saved successfully to %s" % SAVE_FILE_PATH)
	save_completed.emit(true)
	return true


## Load the saved game state
## Returns: true if load was successful, false otherwise
func load_game() -> bool:
	if not has_save_game():
		ErrorHandler.log_warning("SaveSystem", "No save file found")
		load_completed.emit(false)
		return false

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		ErrorHandler.log_error("SaveSystem", "Failed to open save file for reading: %s" % error_string(error))
		load_completed.emit(false)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		ErrorHandler.log_error("SaveSystem", "Failed to parse save file: %s at line %d" % [json.get_error_message(), json.get_error_line()])
		load_completed.emit(false)
		return false

	var save_data = json.get_data()
	if not save_data is Dictionary:
		ErrorHandler.log_error("SaveSystem", "Save file has invalid format (expected Dictionary)")
		load_completed.emit(false)
		return false

	# Validate save version
	if not save_data.has("version") or save_data["version"] != SAVE_VERSION:
		ErrorHandler.log_warning("SaveSystem", "Save file version mismatch. Expected %d, got %s" % [SAVE_VERSION, str(save_data.get("version", "unknown"))])
		# For now, still attempt to load - future versions may need migration logic

	var success = _restore_save_data(save_data)

	if success:
		ErrorHandler.log_info("SaveSystem", "Game loaded successfully")
	else:
		ErrorHandler.log_error("SaveSystem", "Failed to restore save data")

	load_completed.emit(success)
	return success


## Delete the save file
## Returns: true if deletion was successful or file didn't exist
func delete_save() -> bool:
	if not has_save_game():
		ErrorHandler.log_info("SaveSystem", "No save file to delete")
		return true

	var error = DirAccess.remove_absolute(SAVE_FILE_PATH)
	if error != OK:
		ErrorHandler.log_error("SaveSystem", "Failed to delete save file: %s" % error_string(error))
		return false

	ErrorHandler.log_info("SaveSystem", "Save file deleted")
	return true


## Get save file metadata without fully loading
## Returns: Dictionary with metadata or empty if no save exists
func get_save_info() -> Dictionary:
	if not has_save_game():
		return {}

	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file == null:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	if json.parse(json_string) != OK:
		return {}

	var save_data = json.get_data()
	if not save_data is Dictionary:
		return {}

	return {
		"version": save_data.get("version", 0),
		"timestamp": save_data.get("timestamp", ""),
		"current_wave": save_data.get("current_wave", 0),
		"digibytes": save_data.get("digibytes", 0),
		"lives": save_data.get("lives", 0),
		"tower_count": save_data.get("towers", []).size()
	}


# =============================================================================
# INTERNAL - SAVE DATA BUILDING
# =============================================================================

## Build the save data dictionary from current game state
func _build_save_data() -> Dictionary:
	var save_data: Dictionary = {
		"version": SAVE_VERSION,
		"timestamp": Time.get_datetime_string_from_system(),
		"current_wave": GameManager.current_wave,
		"digibytes": GameManager.current_digibytes,
		"lives": GameManager.lives,
		"game_speed": GameManager.game_speed,
		"towers": []
	}

	# Get all placed towers from the grid manager
	var grid_manager = _get_grid_manager()
	if not grid_manager:
		ErrorHandler.log_warning("SaveSystem", "Could not get grid manager for saving towers")
		return save_data

	var towers = grid_manager.get_all_towers()
	for tower in towers:
		var tower_data = _serialize_tower(tower)
		if not tower_data.is_empty():
			save_data["towers"].append(tower_data)

	ErrorHandler.log_info("SaveSystem", "Built save data with %d towers" % save_data["towers"].size())
	return save_data


## Serialize a single tower to a dictionary
func _serialize_tower(tower: Node) -> Dictionary:
	if not tower:
		return {}

	# Access tower properties
	var digimon_data = tower.get("digimon_data")
	if not digimon_data:
		ErrorHandler.log_warning("SaveSystem", "Tower has no digimon_data, skipping")
		return {}

	var tower_data: Dictionary = {
		"grid_position_x": tower.grid_position.x,
		"grid_position_y": tower.grid_position.y,
		"digimon_data_path": digimon_data.resource_path,
		"current_level": tower.current_level,
		"current_dp": tower.current_dp,
		"origin_stage": tower.origin_stage,
		"total_investment": tower.total_investment
	}

	return tower_data


# =============================================================================
# INTERNAL - SAVE DATA RESTORATION
# =============================================================================

## Restore game state from save data
func _restore_save_data(save_data: Dictionary) -> bool:
	# Restore GameManager state
	if save_data.has("current_wave"):
		GameManager.current_wave = int(save_data["current_wave"])

	if save_data.has("digibytes"):
		GameManager.current_digibytes = int(save_data["digibytes"])

	if save_data.has("lives"):
		GameManager.lives = int(save_data["lives"])

	if save_data.has("game_speed"):
		GameManager.set_game_speed(float(save_data["game_speed"]))

	# Restore towers
	if save_data.has("towers") and save_data["towers"] is Array:
		var success = _restore_towers(save_data["towers"])
		if not success:
			ErrorHandler.log_warning("SaveSystem", "Some towers failed to restore")

	return true


## Restore all towers from save data
## Note: This must be called after the level scene is loaded
func _restore_towers(towers_data: Array) -> bool:
	if not _current_level:
		ErrorHandler.log_error("SaveSystem", "Cannot restore towers: no current level")
		return false

	var spawn_system = _get_spawn_system()
	var grid_manager = _get_grid_manager()

	if not spawn_system or not grid_manager:
		ErrorHandler.log_error("SaveSystem", "Cannot restore towers: missing spawn system or grid manager")
		return false

	var success_count = 0
	var fail_count = 0

	for tower_data in towers_data:
		if _restore_single_tower(tower_data, spawn_system, grid_manager):
			success_count += 1
		else:
			fail_count += 1

	ErrorHandler.log_info("SaveSystem", "Restored %d towers, %d failed" % [success_count, fail_count])
	return fail_count == 0


## Restore a single tower from save data
func _restore_single_tower(tower_data: Dictionary, spawn_system: Node, grid_manager: Node) -> bool:
	# Validate required fields
	if not tower_data.has("grid_position_x") or not tower_data.has("grid_position_y"):
		ErrorHandler.log_warning("SaveSystem", "Tower data missing grid position")
		return false

	if not tower_data.has("digimon_data_path"):
		ErrorHandler.log_warning("SaveSystem", "Tower data missing digimon_data_path")
		return false

	var grid_pos = Vector2i(
		int(tower_data["grid_position_x"]),
		int(tower_data["grid_position_y"])
	)

	# Check if position is available
	if not grid_manager.can_place_tower(grid_pos):
		ErrorHandler.log_warning("SaveSystem", "Cannot restore tower at %s: position unavailable" % str(grid_pos))
		return false

	# Load the DigimonData resource
	var digimon_data_path = str(tower_data["digimon_data_path"])
	if not ResourceLoader.exists(digimon_data_path):
		ErrorHandler.log_error("SaveSystem", "DigimonData resource not found: %s" % digimon_data_path)
		return false

	var digimon_data = load(digimon_data_path)
	if not digimon_data:
		ErrorHandler.log_error("SaveSystem", "Failed to load DigimonData: %s" % digimon_data_path)
		return false

	# Get origin stage (defaults to current stage if not saved)
	var origin_stage = int(tower_data.get("origin_stage", digimon_data.stage))

	# Spawn the tower
	var tower = spawn_system.spawn_tower(grid_pos, digimon_data, origin_stage)
	if not tower:
		ErrorHandler.log_error("SaveSystem", "Failed to spawn tower at %s" % str(grid_pos))
		return false

	# Restore additional properties
	if tower_data.has("current_level"):
		tower.current_level = int(tower_data["current_level"])

	if tower_data.has("current_dp"):
		tower.current_dp = int(tower_data["current_dp"])

	if tower_data.has("total_investment"):
		tower.total_investment = int(tower_data["total_investment"])

	return true


# =============================================================================
# INTERNAL - HELPERS
# =============================================================================

## Get the grid manager from the current level
func _get_grid_manager() -> Node:
	if not _current_level:
		return null

	if _current_level.has_method("get_grid_manager"):
		return _current_level.get_grid_manager()

	# Fallback: search for GridManager child
	for child in _current_level.get_children():
		if child.get_class() == "GridManager" or child.name == "GridManager":
			return child
		# Check in Grid node
		if child.name == "Grid":
			for subchild in child.get_children():
				if subchild.name == "GridManager":
					return subchild

	return null


## Get the spawn system from the current level
func _get_spawn_system() -> Node:
	if not _current_level:
		return null

	if _current_level.has_method("get_spawn_system"):
		return _current_level.get_spawn_system()

	# Fallback: search for SpawnSystem child
	for child in _current_level.get_children():
		if child.get_class() == "SpawnSystem" or child.name == "SpawnSystem":
			return child

	return null


## Handle wave completion for auto-save
func _on_wave_completed(_wave_number: int, _reward: int) -> void:
	if _auto_save_enabled:
		# Delay slightly to ensure all state is updated
		await get_tree().create_timer(0.1).timeout
		save_game()
