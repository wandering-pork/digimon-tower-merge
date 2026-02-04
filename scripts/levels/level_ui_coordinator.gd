class_name LevelUICoordinator
extends Node
## Level UI Coordinator
##
## Manages all UI panel interactions, menu coordination, and HUD state
## for the main level scene. Handles spawn menu, evolution menu, sell
## confirmation, and tower info panel coordination.

# UI panel references (set by main level)
var spawn_menu: SpawnMenu
var evolution_menu: Control
var tower_info_panel: PanelContainer
var sell_confirmation: PanelContainer
var hud: Control
var ui_layer: CanvasLayer

# System references
var evolution_system: EvolutionSystem
var grid_manager: GridManager

# Signals
signal starter_selection_completed(starter_data: DigimonData)
signal spawn_position_cleared


func _ready() -> void:
	pass


## Initialize UI coordinator with required references
func initialize(
	p_ui_layer: CanvasLayer,
	p_hud: Control,
	p_spawn_menu: SpawnMenu,
	p_evolution_menu: Control,
	p_tower_info_panel: PanelContainer,
	p_sell_confirmation: PanelContainer,
	p_evolution_system: EvolutionSystem,
	p_grid_manager: GridManager
) -> void:
	ui_layer = p_ui_layer
	hud = p_hud
	spawn_menu = p_spawn_menu
	evolution_menu = p_evolution_menu
	tower_info_panel = p_tower_info_panel
	sell_confirmation = p_sell_confirmation
	evolution_system = p_evolution_system
	grid_manager = p_grid_manager

	_setup_ui_references()


func _setup_ui_references() -> void:
	## Set up all UI panel references and connections
	# Set up TowerInfoPanel references
	if tower_info_panel and tower_info_panel.has_method("set_economy_system"):
		if EconomySystem:
			tower_info_panel.set_economy_system(EconomySystem)
		tower_info_panel.set_evolution_system(evolution_system)
		tower_info_panel.sell_requested.connect(_on_sell_requested)

	# Set up EvolutionMenu references
	if evolution_menu and evolution_menu.has_method("set_evolution_system"):
		evolution_menu.set_evolution_system(evolution_system)

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


## Open spawn menu at a grid position
func open_spawn_menu(grid_pos: Vector2i) -> void:
	if spawn_menu:
		spawn_menu.open_at_position(grid_pos)


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
	## Handle evolution completion - close menu and refresh UI
	# Close evolution menu
	if evolution_menu and evolution_menu.has_method("close"):
		evolution_menu.close()

	# Emit tower selected to refresh tower info panel
	EventBus.tower_selected.emit(tower)


## Get the HUD reference
func get_hud() -> Control:
	return hud
