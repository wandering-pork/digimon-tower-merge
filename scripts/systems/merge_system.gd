class_name MergeSystem
extends Node
## Handles merge operations between Digimon towers.
## Manages drag-and-drop merge UI, validation, and execution.

signal merge_preview_shown(source: DigimonTower, target: DigimonTower, result: Dictionary)
signal merge_completed(survivor: DigimonTower, sacrificed: DigimonTower)
signal merge_cancelled()
signal valid_targets_found(targets: Array[DigimonTower])

## Currently dragging tower for merge
var _drag_source: DigimonTower = null

## All valid merge targets for current drag
var _valid_targets: Array[DigimonTower] = []

## Reference to grid manager (set by parent level)
var _grid_manager: GridManager = null

## Visual highlight color for valid merge targets
const HIGHLIGHT_COLOR: Color = Color(0.2, 1.0, 0.2, 0.8)
const LOCKED_HIGHLIGHT_COLOR: Color = Color(0.5, 0.5, 0.5, 0.5)

## Store original modulates for restoration
var _original_modulates: Dictionary = {}


func _ready() -> void:
	# Connect to EventBus merge signals
	if EventBus:
		EventBus.merge_initiated.connect(_on_merge_initiated)
		EventBus.merge_cancelled.connect(_on_merge_cancelled_external)


## Set the grid manager reference
func set_grid_manager(manager: GridManager) -> void:
	_grid_manager = manager


## Start a merge drag operation from a tower
func start_merge_drag(tower: DigimonTower) -> void:
	if not tower or not tower.digimon_data:
		return

	# Check if this tower can even merge
	if not tower.digimon_data.can_merge():
		ErrorHandler.log_warning("MergeSystem", "Tower cannot merge - stage too low")
		return

	_drag_source = tower
	_valid_targets = get_valid_merge_targets(tower)

	# Highlight valid targets
	_highlight_valid_targets()

	# Emit signal for UI
	valid_targets_found.emit(_valid_targets)

	if EventBus:
		EventBus.merge_initiated.emit(tower)


## Get all towers that can be merged with the source
func get_valid_merge_targets(source: DigimonTower) -> Array[DigimonTower]:
	var targets: Array[DigimonTower] = []

	if not _grid_manager or not source:
		return targets

	var all_towers = _grid_manager.get_all_towers()

	for tower in all_towers:
		if tower != source and can_merge(source, tower):
			targets.append(tower)

	return targets


## Check if two towers can merge together
func can_merge(source: DigimonTower, target: DigimonTower) -> bool:
	if not source or not target:
		return false

	return source.can_merge_with(target)


## Preview what the merge result would be
## Returns dictionary with: new_dp, new_origin, survivor_name, level_cap_change
func preview_merge(source: DigimonTower, target: DigimonTower) -> Dictionary:
	var result: Dictionary = {
		"valid": false,
		"new_dp": 0,
		"new_origin": 0,
		"survivor_name": "",
		"current_dp": 0,
		"current_origin": 0,
		"level_cap_before": 0,
		"level_cap_after": 0,
		"origin_name_before": "",
		"origin_name_after": ""
	}

	if not can_merge(source, target):
		return result

	result["valid"] = true
	result["survivor_name"] = target.digimon_data.digimon_name
	result["current_dp"] = target.current_dp
	result["current_origin"] = target.origin_stage
	result["origin_name_before"] = _get_origin_name(target.origin_stage)

	# Calculate new DP (max of both + 1)
	result["new_dp"] = target.calculate_merge_dp(source)

	# Calculate new origin (min = better)
	result["new_origin"] = mini(source.origin_stage, target.origin_stage)
	result["origin_name_after"] = _get_origin_name(result["new_origin"])

	# Calculate level cap changes
	result["level_cap_before"] = target.get_max_level()

	# Temporarily calculate what the new cap would be
	# Use GameConfig.calculate_max_level for consistency
	var stage = target.digimon_data.stage
	result["level_cap_after"] = GameConfig.calculate_max_level(stage, result["new_dp"], result["new_origin"])

	return result


## Execute the merge - source is sacrificed into target
func execute_merge(source: DigimonTower, target: DigimonTower) -> void:
	if not can_merge(source, target):
		ErrorHandler.log_error("MergeSystem", "Cannot execute invalid merge")
		cancel_merge()
		return

	# Store source grid position before merge
	var source_grid_pos = source.grid_position

	# Perform the merge - target absorbs source
	var new_dp = target.merge_with(source)

	if new_dp < 0:
		ErrorHandler.log_error("MergeSystem", "Merge failed unexpectedly")
		cancel_merge()
		return

	# Remove source from grid
	if _grid_manager:
		_grid_manager.remove_tower(source_grid_pos)

	# Remove source from scene tree
	source.queue_free()

	# Clear drag state
	_clear_highlights()
	_drag_source = null
	_valid_targets.clear()

	# Play merge success sound
	AudioManager.play_sfx("merge_success")

	# Emit signals
	merge_completed.emit(target, source)

	if EventBus:
		EventBus.merge_completed.emit(target, source, new_dp, target.origin_stage)

	# Show floating text
	if EventBus:
		EventBus.floating_text_requested.emit(
			target.global_position,
			"+1 DP",
			Color.GOLD
		)


## Cancel the current merge operation
func cancel_merge() -> void:
	_clear_highlights()
	_drag_source = null
	_valid_targets.clear()
	merge_cancelled.emit()


## Check if a merge is currently in progress
func is_merge_in_progress() -> bool:
	return _drag_source != null


## Get the current drag source
func get_drag_source() -> DigimonTower:
	return _drag_source


## Get valid targets for current drag
func get_current_valid_targets() -> Array[DigimonTower]:
	return _valid_targets


## Check if a tower is a valid target for current merge
func is_valid_target(tower: DigimonTower) -> bool:
	return tower in _valid_targets


## Highlight all valid merge targets
func _highlight_valid_targets() -> void:
	_original_modulates.clear()

	for tower in _valid_targets:
		if tower and is_instance_valid(tower) and tower.sprite:
			_original_modulates[tower] = tower.sprite.modulate
			tower.sprite.modulate = HIGHLIGHT_COLOR


## Clear all highlights and restore original colors
func _clear_highlights() -> void:
	for tower in _original_modulates.keys():
		if is_instance_valid(tower) and tower.sprite:
			tower.sprite.modulate = _original_modulates[tower]
	_original_modulates.clear()


## Get origin stage name
func _get_origin_name(origin: int) -> String:
	if GameConfig:
		return GameConfig.get_stage_name(origin)
	match origin:
		GameConfig.STAGE_IN_TRAINING: return "In-Training"
		GameConfig.STAGE_ROOKIE: return "Rookie"
		GameConfig.STAGE_CHAMPION: return "Champion"
		GameConfig.STAGE_ULTIMATE: return "Ultimate"
		GameConfig.STAGE_MEGA: return "Mega"
		_: return "Unknown"


## Handle external merge initiation from EventBus
func _on_merge_initiated(tower: Node) -> void:
	if tower is DigimonTower and tower != _drag_source:
		start_merge_drag(tower as DigimonTower)


## Handle external merge cancellation
func _on_merge_cancelled_external() -> void:
	if is_merge_in_progress():
		cancel_merge()


## Get merge statistics for a tower
## Returns info about potential merge partners
func get_merge_stats(tower: DigimonTower) -> Dictionary:
	var stats: Dictionary = {
		"can_merge": false,
		"potential_partners": 0,
		"same_attribute_count": 0,
		"free_attribute_count": 0
	}

	if not tower or not tower.digimon_data:
		return stats

	stats["can_merge"] = tower.digimon_data.can_merge()

	if not stats["can_merge"]:
		return stats

	var targets = get_valid_merge_targets(tower)
	stats["potential_partners"] = targets.size()

	for target in targets:
		if target.digimon_data.attribute == DigimonData.Attribute.FREE:
			stats["free_attribute_count"] += 1
		elif target.digimon_data.attribute == tower.digimon_data.attribute:
			stats["same_attribute_count"] += 1

	return stats


func _exit_tree() -> void:
	# Disconnect from EventBus signals to prevent memory leaks
	if EventBus:
		if EventBus.merge_initiated.is_connected(_on_merge_initiated):
			EventBus.merge_initiated.disconnect(_on_merge_initiated)
		if EventBus.merge_cancelled.is_connected(_on_merge_cancelled_external):
			EventBus.merge_cancelled.disconnect(_on_merge_cancelled_external)

	# Clear any active merge state
	_clear_highlights()
	_drag_source = null
	_valid_targets.clear()
	_original_modulates.clear()
	_grid_manager = null
