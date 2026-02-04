class_name LevelUICoordinator
extends Node
## Level UI Coordinator
##
## Manages all UI panel interactions, menu coordination, and HUD state
## for the main level scene. Handles spawn menu, evolution menu, sell
## confirmation, merge confirmation, and tower info panel coordination.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonTower = preload("res://scripts/towers/digimon_tower.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")
const EvolutionPath = preload("res://scripts/data/evolution_path.gd")
const MergeSelectionHandler = preload("res://scripts/systems/merge_selection_handler.gd")

# UI panel references (set by main level)
var spawn_menu: Control  # SpawnMenu - avoid class resolution issues
var evolution_menu: Control
var tower_info_panel: PanelContainer
var sell_confirmation: PanelContainer
var merge_confirmation: Control
var hud: Control
var ui_layer: CanvasLayer

# System references (using Node type to avoid class resolution issues)
var evolution_system: Node  # EvolutionSystem
var grid_manager: Node  # GridManager
var merge_system: Node  # MergeSystem
var merge_selection_handler: Node  # MergeSelectionHandler

# Signals
signal starter_selection_completed(starter_data: DigimonData)
signal spawn_position_cleared
signal merge_requested(tower: DigimonTower)


func _ready() -> void:
	pass


## Initialize UI coordinator with required references
func initialize(
	p_ui_layer: CanvasLayer,
	p_hud: Control,
	p_spawn_menu: Control,  # SpawnMenu
	p_evolution_menu: Control,
	p_tower_info_panel: PanelContainer,
	p_sell_confirmation: PanelContainer,
	p_evolution_system: Node,  # EvolutionSystem
	p_grid_manager: Node,  # GridManager
	p_merge_system: Node = null,  # MergeSystem
	p_merge_confirmation: Control = null
) -> void:
	ui_layer = p_ui_layer
	hud = p_hud
	spawn_menu = p_spawn_menu
	evolution_menu = p_evolution_menu
	tower_info_panel = p_tower_info_panel
	sell_confirmation = p_sell_confirmation
	merge_confirmation = p_merge_confirmation
	evolution_system = p_evolution_system
	grid_manager = p_grid_manager
	merge_system = p_merge_system

	_setup_ui_references()
	_setup_merge_system()


func _setup_ui_references() -> void:
	## Set up all UI panel references and connections
	# Set up TowerInfoPanel references
	if tower_info_panel and tower_info_panel.has_method("set_economy_system"):
		if EconomySystem:
			tower_info_panel.set_economy_system(EconomySystem)
		tower_info_panel.set_evolution_system(evolution_system)
		if merge_system and tower_info_panel.has_method("set_merge_system"):
			tower_info_panel.set_merge_system(merge_system)
		tower_info_panel.sell_requested.connect(_on_sell_requested)
		if tower_info_panel.has_signal("merge_requested"):
			tower_info_panel.merge_requested.connect(_on_merge_requested_from_panel)

	# Set up EvolutionMenu references
	if evolution_menu and evolution_menu.has_method("set_evolution_system"):
		evolution_menu.set_evolution_system(evolution_system)
		# Connect evolution menu signals
		if evolution_menu.has_signal("evolution_confirmed"):
			evolution_menu.evolution_confirmed.connect(_on_evolution_confirmed_from_menu)
		if evolution_menu.has_signal("cancelled"):
			evolution_menu.cancelled.connect(_on_evolution_menu_cancelled)

	# Set up SellConfirmation references
	if sell_confirmation:
		if sell_confirmation.has_method("set_economy_system") and EconomySystem:
			sell_confirmation.set_economy_system(EconomySystem)
		if sell_confirmation.has_method("set_grid_manager"):
			sell_confirmation.set_grid_manager(grid_manager)

	# Connect evolution system signals
	if evolution_system:
		evolution_system.evolution_menu_requested.connect(_on_evolution_menu_requested)
		evolution_system.evolution_completed.connect(_on_evolution_completed)

	# Connect EventBus merge signals
	if EventBus:
		EventBus.merge_confirmation_requested.connect(_on_merge_confirmation_requested)


## Show starter selection UI
func show_starter_selection() -> void:
	var starter_scene = load("res://scenes/ui/starter_selection.tscn")
	if starter_scene:
		var starter_ui = starter_scene.instantiate()
		starter_ui.starter_selected.connect(_on_starter_selected)
		ui_layer.add_child(starter_ui)
	else:
		# Signal that starter selection failed (main level will handle fallback)
		starter_selection_completed.emit(null)


func _on_starter_selected(starter_data: DigimonData) -> void:
	## Handle starter selection from UI
	# Remove starter selection UI
	for child in ui_layer.get_children():
		if child is StarterSelection:
			child.queue_free()

	starter_selection_completed.emit(starter_data)


## Open spawn menu at a grid position (direct spawn mode)
func open_spawn_menu(grid_pos: Vector2i) -> void:
	if spawn_menu:
		spawn_menu.open_at_position(grid_pos)


## Open spawn menu for drag-drop placement mode
func open_spawn_menu_for_placement() -> void:
	if spawn_menu:
		spawn_menu.open_for_placement()


## Close spawn menu
func close_spawn_menu() -> void:
	if spawn_menu and spawn_menu.is_open():
		spawn_menu.close()


## Check if spawn menu is open
func is_spawn_menu_open() -> bool:
	return spawn_menu and spawn_menu.is_open()


## Handle spawn menu closed signal
func on_spawn_menu_closed() -> void:
	spawn_position_cleared.emit()


## Show sell confirmation dialog for a tower
func show_sell_confirmation(tower: DigimonTower) -> void:
	if sell_confirmation and sell_confirmation.has_method("show_for_tower"):
		sell_confirmation.show_for_tower(tower)


func _on_sell_requested(tower: DigimonTower) -> void:
	## Handle sell request from tower info panel
	show_sell_confirmation(tower)


func _on_evolution_menu_requested(tower: DigimonTower, paths: Array) -> void:
	## Handle evolution menu request
	if evolution_menu and evolution_menu.has_method("open"):
		# Cast paths to correct type
		var typed_paths: Array[EvolutionPath] = []
		for path in paths:
			if path is EvolutionPath:
				typed_paths.append(path)
		evolution_menu.open(tower, typed_paths)


func _on_evolution_completed(tower: DigimonTower, _new_form: DigimonData) -> void:
	## Handle evolution completion from evolution_system - close menu and refresh UI
	# Close evolution menu
	if evolution_menu and evolution_menu.has_method("close"):
		evolution_menu.close()

	# Emit tower selected to refresh tower info panel
	if EventBus:
		EventBus.tower_selected.emit(tower)


func _on_evolution_confirmed_from_menu(tower: DigimonTower, _path: EvolutionPath) -> void:
	## Handle evolution confirmation from the menu UI
	## Note: The menu itself calls evolution_system.execute_evolution()
	## This handler is for any additional UI coordination needed
	pass  # The evolution_system.evolution_completed signal will handle the rest


func _on_evolution_menu_cancelled() -> void:
	## Handle evolution menu cancellation
	# Refresh tower selection state
	if EventBus:
		EventBus.ui_evolution_menu_closed.emit()


## Get the HUD reference
func get_hud() -> Control:
	return hud


# =============================================================================
# MERGE SYSTEM
# =============================================================================

## Setup merge selection handler
func _setup_merge_system() -> void:
	if not merge_system:
		return

	# Create merge selection handler
	merge_selection_handler = MergeSelectionHandler.new()
	add_child(merge_selection_handler)
	merge_selection_handler.initialize(merge_system, grid_manager)

	# Setup merge confirmation dialog
	if merge_confirmation:
		merge_confirmation.confirmed.connect(_on_merge_confirmed)
		merge_confirmation.cancelled.connect(_on_merge_confirmation_cancelled)


## Handle merge request from tower info panel
func _on_merge_requested_from_panel(tower: DigimonTower) -> void:
	start_merge_mode(tower)


## Start merge mode for a tower
func start_merge_mode(tower: DigimonTower) -> void:
	if merge_selection_handler:
		merge_selection_handler.start_merge_selection(tower)


## Cancel merge mode
func cancel_merge_mode() -> void:
	if merge_selection_handler:
		merge_selection_handler.cancel_merge_selection()


## Check if merge mode is active
func is_merge_mode_active() -> bool:
	return merge_selection_handler and merge_selection_handler.is_merge_mode_active()


## Handle merge confirmation request from EventBus
func _on_merge_confirmation_requested(source: Node, target: Node) -> void:
	if not source is DigimonTower or not target is DigimonTower:
		return

	var source_tower = source as DigimonTower
	var target_tower = target as DigimonTower

	# Get merge preview from merge system
	if not merge_system:
		ErrorHandler.log_error("LevelUICoordinator", "No merge system for confirmation")
		return

	var preview = merge_system.preview_merge(source_tower, target_tower)
	if not preview.get("valid", false):
		ErrorHandler.log_error("LevelUICoordinator", "Invalid merge preview")
		cancel_merge_mode()
		return

	# Show confirmation dialog
	if merge_confirmation and merge_confirmation.has_method("show_confirmation"):
		merge_confirmation.show_confirmation(source_tower, target_tower, preview)


## Handle merge confirmed from dialog
func _on_merge_confirmed(source: DigimonTower, target: DigimonTower) -> void:
	if merge_selection_handler:
		merge_selection_handler.execute_merge(source, target)


## Handle merge confirmation cancelled
func _on_merge_confirmation_cancelled() -> void:
	cancel_merge_mode()


## Get the merge selection handler
func get_merge_selection_handler() -> Node:  # MergeSelectionHandler
	return merge_selection_handler


func _exit_tree() -> void:
	# Disconnect EventBus signals
	if EventBus:
		if EventBus.merge_confirmation_requested.is_connected(_on_merge_confirmation_requested):
			EventBus.merge_confirmation_requested.disconnect(_on_merge_confirmation_requested)

	# Disconnect evolution system signals
	if evolution_system:
		if evolution_system.evolution_menu_requested.is_connected(_on_evolution_menu_requested):
			evolution_system.evolution_menu_requested.disconnect(_on_evolution_menu_requested)
		if evolution_system.evolution_completed.is_connected(_on_evolution_completed):
			evolution_system.evolution_completed.disconnect(_on_evolution_completed)

	# Clear references
	spawn_menu = null
	evolution_menu = null
	tower_info_panel = null
	sell_confirmation = null
	merge_confirmation = null
	hud = null
	ui_layer = null
	evolution_system = null
	grid_manager = null
	merge_system = null
	merge_selection_handler = null
