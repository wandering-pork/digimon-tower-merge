class_name LevelInputHandler
extends Node
## Level Input Handler
##
## Processes all input for the main level including mouse clicks,
## keyboard shortcuts, tower selection/deselection, and menu interactions.
## Coordinates with TowerPlacementSystem for drag-drop placement mode.

# Grid configuration (must match main level)
const GRID_COLUMNS: int = 8
const GRID_ROWS: int = 18

# References (set by main level)
var grid_manager: GridManager
var evolution_system: EvolutionSystem
var ui_coordinator: LevelUICoordinator
var main_level: Node2D

# State
var selected_tower: DigimonTower = null
var selected_spawn_position: Vector2i = Vector2i(-1, -1)
var _placement_mode_active: bool = false
var _merge_mode_active: bool = false

# Signals
signal spawn_menu_requested(grid_pos: Vector2i)
signal tower_selection_changed(tower: DigimonTower)


func _ready() -> void:
	# Connect to EventBus for tower selection
	EventBus.tower_selected.connect(_on_tower_selected)

	# Connect to placement mode signals
	EventBus.placement_mode_started.connect(_on_placement_mode_started)
	EventBus.placement_mode_ended.connect(_on_placement_mode_ended)

	# Connect to merge mode signals
	EventBus.merge_mode_entered.connect(_on_merge_mode_entered)
	EventBus.merge_mode_exited.connect(_on_merge_mode_exited)


## Initialize input handler with required references
func initialize(
	p_main_level: Node2D,
	p_grid_manager: GridManager,
	p_evolution_system: EvolutionSystem,
	p_ui_coordinator: LevelUICoordinator
) -> void:
	main_level = p_main_level
	grid_manager = p_grid_manager
	evolution_system = p_evolution_system
	ui_coordinator = p_ui_coordinator


func _input(event: InputEvent) -> void:
	# Handle mouse input for grid interactions
	if event is InputEventMouseButton:
		_handle_mouse_button(event)

	# Handle keyboard shortcuts
	_handle_keyboard_input(event)


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	## Process mouse button events
	# Skip if placement mode is active (TowerPlacementSystem handles input)
	if _placement_mode_active:
		return

	# Skip spawn menu request if merge mode is active (MergeSelectionHandler handles tower clicks)
	# The tower_selected signal will still be emitted by the tower itself

	if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_handle_grid_click(event.position)
	elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		# Right click to cancel/close menus or merge mode
		if _merge_mode_active:
			EventBus.merge_cancelled.emit()
		elif ui_coordinator and ui_coordinator.is_spawn_menu_open():
			ui_coordinator.close_spawn_menu()


func _handle_keyboard_input(event: InputEvent) -> void:
	## Process keyboard input events
	if event.is_action_pressed("ui_cancel"):
		# Cancel merge mode if active, otherwise deselect tower
		if _merge_mode_active:
			EventBus.merge_cancelled.emit()
		else:
			_deselect_tower()

	if event.is_action_pressed("toggle_speed"):
		GameManager.cycle_game_speed()

	if event.is_action_pressed("level_up") and selected_tower:
		_try_level_up_selected()

	if event.is_action_pressed("digivolve") and selected_tower:
		_try_digivolve_selected()

	if event.is_action_pressed("sell") and selected_tower:
		if ui_coordinator:
			ui_coordinator.show_sell_confirmation(selected_tower)


func _handle_grid_click(screen_pos: Vector2) -> void:
	## Handle clicks on the game grid
	if not main_level:
		return

	# Convert screen position to world position
	var world_pos = main_level.get_global_mouse_position()
	var grid_pos = grid_manager.world_to_grid(world_pos)

	# Check if click is within grid bounds
	if grid_pos.x < 0 or grid_pos.x >= GRID_COLUMNS:
		return
	if grid_pos.y < 0 or grid_pos.y >= GRID_ROWS:
		return

	# Check what's at this position
	var tower = grid_manager.get_tower_at(grid_pos)

	if tower:
		# Clicked on existing tower - select it
		EventBus.tower_selected.emit(tower)
	elif grid_manager.can_place_tower(grid_pos):
		# Clicked on empty tower slot - request spawn menu (but not during merge mode)
		if not _merge_mode_active:
			selected_spawn_position = grid_pos
			spawn_menu_requested.emit(grid_pos)


func _on_tower_selected(tower: Node) -> void:
	## Handle tower selection from EventBus
	if tower and tower is DigimonTower:
		selected_tower = tower as DigimonTower
	else:
		selected_tower = null

	tower_selection_changed.emit(selected_tower)


## Deselect current tower
func deselect_tower() -> void:
	_deselect_tower()


func _deselect_tower() -> void:
	## Internal deselection logic
	if selected_tower:
		selected_tower.deselect()
		selected_tower = null
		EventBus.tower_selected.emit(null)


func _try_level_up_selected() -> void:
	## Try to level up the selected tower
	if not selected_tower or not selected_tower.can_level_up():
		return

	if EconomySystem:
		EconomySystem.try_level_up(selected_tower)
	else:
		# Fallback
		var cost = selected_tower.get_level_up_cost()
		if GameManager.spend_digibytes(cost):
			selected_tower.do_level_up()


func _try_digivolve_selected() -> void:
	## Try to digivolve the selected tower
	if not selected_tower or not selected_tower.can_digivolve():
		return

	if evolution_system:
		evolution_system.request_evolution(selected_tower)


## Get the currently selected tower
func get_selected_tower() -> DigimonTower:
	return selected_tower


## Get the selected spawn position
func get_selected_spawn_position() -> Vector2i:
	return selected_spawn_position


## Clear the selected spawn position
func clear_spawn_position() -> void:
	selected_spawn_position = Vector2i(-1, -1)


# =============================================================================
# PLACEMENT MODE HANDLERS
# =============================================================================

func _on_placement_mode_started(_stage: int, _attribute: int, _cost: int) -> void:
	## Handle entering placement mode
	_placement_mode_active = true
	# Deselect current tower when entering placement mode
	_deselect_tower()


func _on_placement_mode_ended() -> void:
	## Handle exiting placement mode
	_placement_mode_active = false


## Check if placement mode is currently active
func is_placement_mode_active() -> bool:
	return _placement_mode_active


# =============================================================================
# MERGE MODE HANDLERS
# =============================================================================

func _on_merge_mode_entered(_source_tower: Node) -> void:
	## Handle entering merge mode
	_merge_mode_active = true


func _on_merge_mode_exited() -> void:
	## Handle exiting merge mode
	_merge_mode_active = false


## Check if merge mode is currently active
func is_merge_mode_active() -> bool:
	return _merge_mode_active


func _exit_tree() -> void:
	# Disconnect EventBus signals to prevent memory leaks
	if EventBus:
		if EventBus.tower_selected.is_connected(_on_tower_selected):
			EventBus.tower_selected.disconnect(_on_tower_selected)
		if EventBus.placement_mode_started.is_connected(_on_placement_mode_started):
			EventBus.placement_mode_started.disconnect(_on_placement_mode_started)
		if EventBus.placement_mode_ended.is_connected(_on_placement_mode_ended):
			EventBus.placement_mode_ended.disconnect(_on_placement_mode_ended)
		if EventBus.merge_mode_entered.is_connected(_on_merge_mode_entered):
			EventBus.merge_mode_entered.disconnect(_on_merge_mode_entered)
		if EventBus.merge_mode_exited.is_connected(_on_merge_mode_exited):
			EventBus.merge_mode_exited.disconnect(_on_merge_mode_exited)
