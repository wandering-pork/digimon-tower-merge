extends Node2D
## Main Level Script
##
## Core gameplay scene that orchestrates the game board, game systems,
## and coordinates between UI, input, and gameplay components.

# Node references
@onready var _grid: Node2D = $Grid
@onready var _towers: Node2D = $Towers
@onready var _enemies: Node2D = $Enemies
@onready var _projectiles: Node2D = $Projectiles
@onready var _ui_layer: CanvasLayer = $UI
@onready var _hud: Control = $UI/HUD
@onready var _spawn_menu: SpawnMenu = $UI/SpawnMenu
@onready var _tower_info_panel: PanelContainer = $UI/TowerInfoPanel
@onready var _evolution_menu: Control = $UI/EvolutionMenu
@onready var _sell_confirmation: PanelContainer = $UI/SellConfirmation

# System references
var _grid_manager: GridManager
var _spawn_system: SpawnSystem
var _evolution_system: EvolutionSystem
var _merge_system: MergeSystem

# Component references
var _ui_coordinator: LevelUICoordinator
var _input_handler: LevelInputHandler

# Grid configuration (from CLAUDE.md specs)
const GRID_COLUMNS: int = 8
const GRID_ROWS: int = 18
const CELL_SIZE: int = 64

# Game state
var _is_wave_active: bool = false
var _enemies_remaining: int = 0
var _has_starter: bool = false


func _ready() -> void:
	_initialize_systems()
	_initialize_components()
	_connect_signals()
	_draw_grid_visuals()
	if not _has_starter:
		_ui_coordinator.show_starter_selection()


func _initialize_systems() -> void:
	_grid_manager = GridManager.new()
	_grid_manager.name = "GridManager"
	_grid.add_child(_grid_manager)

	_spawn_system = SpawnSystem.new()
	_spawn_system.name = "SpawnSystem"
	add_child(_spawn_system)

	_evolution_system = EvolutionSystem.new()
	_evolution_system.name = "EvolutionSystem"
	add_child(_evolution_system)

	_merge_system = MergeSystem.new()
	_merge_system.name = "MergeSystem"
	add_child(_merge_system)

	_spawn_system.set_grid_manager(_grid_manager)
	_spawn_system.set_tower_container(_towers)
	_merge_system.set_grid_manager(_grid_manager)

	if WaveManager:
		WaveManager.setup(_enemies, _grid_manager)


func _initialize_components() -> void:
	_ui_coordinator = LevelUICoordinator.new()
	_ui_coordinator.name = "UICoordinator"
	add_child(_ui_coordinator)
	_ui_coordinator.initialize(
		_ui_layer, _hud, _spawn_menu, _evolution_menu,
		_tower_info_panel, _sell_confirmation,
		_evolution_system, _grid_manager
	)

	_input_handler = LevelInputHandler.new()
	_input_handler.name = "InputHandler"
	add_child(_input_handler)
	_input_handler.initialize(self, _grid_manager, _evolution_system, _ui_coordinator)

	_ui_coordinator.starter_selection_completed.connect(_on_starter_selection_completed)
	_ui_coordinator.spawn_position_cleared.connect(func(): _input_handler.clear_spawn_position())
	_input_handler.spawn_menu_requested.connect(func(pos): _ui_coordinator.open_spawn_menu(pos))


func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_escaped.connect(_on_enemy_escaped)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)

	if _spawn_menu:
		_spawn_menu.spawn_requested.connect(_on_spawn_requested)
		_spawn_menu.menu_closed.connect(func(): _ui_coordinator.on_spawn_menu_closed())


func _draw_grid_visuals() -> void:
	for col in range(GRID_COLUMNS):
		for row in range(GRID_ROWS):
			var pos = Vector2i(col, row)
			var cell = ColorRect.new()
			cell.size = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			cell.position = Vector2(col * CELL_SIZE + 1, row * CELL_SIZE + 1)
			cell.color = Color(0.3, 0.25, 0.2, 0.5) if _grid_manager.is_path_tile(pos) else Color(0.2, 0.3, 0.2, 0.3)
			cell.name = "Cell_%d_%d" % [col, row]
			_grid.add_child(cell)


func _on_starter_selection_completed(starter_data: DigimonData) -> void:
	if starter_data:
		_spawn_starter_at_best_slot(starter_data, Vector2i(2, 0), Vector2i(4, 3))
	else:
		var koromon = _spawn_system.get_digimon_by_name("Koromon")
		if koromon:
			_spawn_starter_at_best_slot(koromon, Vector2i(2, 3), Vector2i(5, 6))
	if WaveManager:
		WaveManager.start_game()


func _spawn_starter_at_best_slot(data: DigimonData, min_pos: Vector2i, max_pos: Vector2i) -> void:
	var slots = _grid_manager.get_available_slots()
	if slots.is_empty():
		return
	var best_slot = slots[0]
	for slot in slots:
		if slot.x >= min_pos.x and slot.x <= max_pos.x and slot.y >= min_pos.y and slot.y <= max_pos.y:
			best_slot = slot
			break
	_spawn_system.spawn_starter(best_slot, data)
	_has_starter = true


func _on_spawn_requested(grid_pos: Vector2i, stage: int, attribute: int, cost: int) -> void:
	_spawn_system.handle_spawn_request(grid_pos, stage, attribute, cost)


## Spawn a tower at a grid position (legacy method)
func spawn_tower(tower_scene: PackedScene, grid_pos: Vector2i) -> Node:
	if not tower_scene:
		ErrorHandler.log_error("MainLevel", "Cannot spawn null tower scene")
		return null
	if not _grid_manager.can_place_tower(grid_pos):
		ErrorHandler.log_warning("MainLevel", "Invalid tower position %s" % grid_pos)
		return null
	var tower = tower_scene.instantiate()
	tower.position = grid_to_world(grid_pos)
	_towers.add_child(tower)
	return tower


## Spawn an enemy that follows the path
func spawn_enemy(enemy_scene: PackedScene) -> Node:
	if not enemy_scene:
		ErrorHandler.log_error("MainLevel", "Cannot spawn null enemy scene")
		return null
	var enemy = enemy_scene.instantiate()
	if enemy.has_method("set_path"):
		enemy.set_path(_grid_manager.get_path_waypoints())
	_enemies.add_child(enemy)
	return enemy


## Spawn a projectile at a world position
func spawn_projectile(projectile_scene: PackedScene, world_pos: Vector2) -> Node:
	if not projectile_scene:
		ErrorHandler.log_error("MainLevel", "Cannot spawn null projectile scene")
		return null
	var projectile = projectile_scene.instantiate()
	projectile.position = world_pos
	_projectiles.add_child(projectile)
	return projectile


func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0, grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0)


func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))


func get_towers() -> Array:
	return _towers.get_children()


func get_enemies() -> Array:
	return _enemies.get_children()


func get_hud() -> Control:
	return _hud


func get_grid_manager() -> GridManager:
	return _grid_manager


func get_spawn_system() -> SpawnSystem:
	return _spawn_system


func get_evolution_system() -> EvolutionSystem:
	return _evolution_system


func get_merge_system() -> MergeSystem:
	return _merge_system


func _on_enemy_killed(_enemy: Node, _killer: Node, _reward: int) -> void:
	_enemies_remaining -= 1
	_check_wave_complete()


func _on_enemy_escaped(_enemy: Node, _is_boss: bool) -> void:
	_enemies_remaining -= 1
	_check_wave_complete()


func _on_wave_started(_wave_number: int, enemy_count: int) -> void:
	_is_wave_active = true
	_enemies_remaining = enemy_count


func _on_wave_completed(_wave_number: int, _reward: int) -> void:
	_is_wave_active = false


func _check_wave_complete() -> void:
	if _is_wave_active and _enemies_remaining <= 0:
		var wave = GameManager.current_wave
		var reward = 50 if wave <= 10 else 75 if wave <= 20 else 100 if wave <= 30 else 150 if wave <= 40 else 200
		EventBus.wave_completed.emit(wave, reward)


func _on_game_over() -> void:
	var game_over_scene = load("res://scenes/main/game_over.tscn")
	if game_over_scene:
		var instance = game_over_scene.instantiate()
		instance.wave_reached = GameManager.current_wave
		instance.enemies_killed = 0
		instance.digimon_evolved = 0
		get_tree().root.add_child(instance)
		queue_free()
