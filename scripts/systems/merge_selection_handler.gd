class_name MergeSelectionHandler
extends Node
## Merge Selection Handler
##
## Manages the merge selection flow:
## 1. Player selects first tower (source) - tower shows "merge source" state
## 2. Player selects second tower (target) - if compatible, request confirmation
## 3. Confirmation dialog shows merge preview
## 4. Confirm executes merge, cancel returns to normal state

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonTower = preload("res://scripts/towers/digimon_tower.gd")
const MergeSystemScript = preload("res://scripts/systems/merge_system.gd")
const GridManagerScript = preload("res://scripts/systems/grid_manager.gd")

# References (using Node type to avoid autoload resolution issues)
var merge_system: Node  # MergeSystem
var grid_manager: Node  # GridManager

# State
var _merge_source: DigimonTower = null
var _valid_targets: Array[DigimonTower] = []
var _is_merge_mode: bool = false


func _init() -> void:
	name = "MergeSelectionHandler"


func _ready() -> void:
	# Connect to EventBus signals
	if EventBus:
		EventBus.tower_selected.connect(_on_tower_selected)
		EventBus.merge_cancelled.connect(_on_merge_cancelled)


## Initialize with required references
func initialize(p_merge_system: Node, p_grid_manager: Node) -> void:  # MergeSystem, GridManager
	merge_system = p_merge_system
	grid_manager = p_grid_manager


## Start merge mode with a source tower
func start_merge_selection(source: DigimonTower) -> void:
	if not source or not source.digimon_data:
		return

	# Check if this tower can merge at all
	if not source.digimon_data.can_merge():
		ErrorHandler.log_warning("MergeSelectionHandler", "Tower stage too low to merge")
		return

	# Clear any previous state
	_clear_merge_state()

	# Set new merge source
	_merge_source = source
	_is_merge_mode = true

	# Get valid targets
	if merge_system:
		_valid_targets = merge_system.get_valid_merge_targets(source)

	# Show visual feedback
	_update_merge_visuals()

	# Emit signal for UI updates
	if EventBus:
		EventBus.merge_mode_entered.emit(source)


## Cancel merge mode and return to normal
func cancel_merge_selection() -> void:
	_clear_merge_state()

	if EventBus:
		EventBus.merge_mode_exited.emit()


## Check if merge mode is active
func is_merge_mode_active() -> bool:
	return _is_merge_mode


## Get the current merge source
func get_merge_source() -> DigimonTower:
	return _merge_source


## Get valid targets for current merge
func get_valid_targets() -> Array[DigimonTower]:
	return _valid_targets


## Check if a tower is a valid merge target
func is_valid_merge_target(tower: DigimonTower) -> bool:
	return tower in _valid_targets


## Handle tower selection during merge mode
func _on_tower_selected(tower: Node) -> void:
	if not _is_merge_mode:
		return

	if not tower or not tower is DigimonTower:
		# Clicked on nothing - cancel merge mode
		cancel_merge_selection()
		return

	var digimon_tower = tower as DigimonTower

	# If clicked on the same tower (source), cancel merge
	if digimon_tower == _merge_source:
		cancel_merge_selection()
		return

	# Check if this is a valid target
	if is_valid_merge_target(digimon_tower):
		# Valid target - request confirmation
		_request_merge_confirmation(digimon_tower)
	else:
		# Invalid target - could show feedback here
		ErrorHandler.log_warning("MergeSelectionHandler", "Invalid merge target selected")


## Request merge confirmation dialog
func _request_merge_confirmation(target: DigimonTower) -> void:
	if not _merge_source or not target:
		return

	# Emit signal to show confirmation dialog
	if EventBus:
		EventBus.merge_confirmation_requested.emit(_merge_source, target)


## Handle merge cancelled (from EventBus)
func _on_merge_cancelled() -> void:
	cancel_merge_selection()


## Update visual states for merge mode
func _update_merge_visuals() -> void:
	if not _merge_source:
		return

	# Mark source tower
	_merge_source.set_merge_source(true)

	# Mark valid targets
	for target in _valid_targets:
		if is_instance_valid(target):
			target.set_merge_target(true)


## Clear all merge visual states
func _clear_merge_state() -> void:
	# Clear source visual
	if _merge_source and is_instance_valid(_merge_source):
		_merge_source.clear_merge_state()

	# Clear target visuals
	for target in _valid_targets:
		if is_instance_valid(target):
			target.clear_merge_state()

	# Reset state
	_merge_source = null
	_valid_targets.clear()
	_is_merge_mode = false


## Execute the merge after confirmation
func execute_merge(source: DigimonTower, target: DigimonTower) -> void:
	if not merge_system:
		ErrorHandler.log_error("MergeSelectionHandler", "No merge system available")
		return

	# Clear visuals first
	_clear_merge_state()

	# Execute through merge system
	merge_system.execute_merge(source, target)


func _exit_tree() -> void:
	# Disconnect from EventBus
	if EventBus:
		if EventBus.tower_selected.is_connected(_on_tower_selected):
			EventBus.tower_selected.disconnect(_on_tower_selected)
		if EventBus.merge_cancelled.is_connected(_on_merge_cancelled):
			EventBus.merge_cancelled.disconnect(_on_merge_cancelled)

	# Clear state
	_clear_merge_state()
	merge_system = null
	grid_manager = null
