extends Node
## WaveSpawner Component
##
## Handles enemy instantiation, spawn timing, and spawn queue management.
## Created as a child of WaveManager and coordinates with it for spawning.
## Extracted from WaveManager to maintain the 300-line convention.

class_name WaveSpawner

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyModifier = preload("res://scripts/enemies/enemy_modifier.gd")

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when an enemy is spawned
signal enemy_spawned(enemy: Node, is_boss: bool)

## Emitted when spawn queue is empty (all enemies spawned this wave)
signal spawn_queue_empty()

# =============================================================================
# STATE VARIABLES
# =============================================================================

## Queue of enemies to spawn this wave
var enemies_to_spawn: Array = []

## Timer for spawning enemies
var spawn_timer: float = 0.0

## Current wave number (set by WaveManager)
var current_wave: int = 0

## Reference to the enemy container node
var _enemy_container: Node = null

## Reference to the grid manager for spawn position
var _grid_manager: Node = null

## Preloaded enemy scene
var _enemy_scene: PackedScene = null

## Track if we've already signaled queue empty this wave
var _queue_empty_signaled: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_enemy_scene = preload("res://scenes/enemies/enemy_digimon.tscn")


# =============================================================================
# PUBLIC METHODS
# =============================================================================

## Set references to game nodes
func setup(enemy_container: Node, grid_manager: Node) -> void:
	_enemy_container = enemy_container
	_grid_manager = grid_manager


## Prepare for a new wave with the given enemy list
func prepare_wave(wave_number: int, enemy_list: Array) -> void:
	current_wave = wave_number
	enemies_to_spawn = enemy_list.duplicate()
	spawn_timer = 0.0
	_queue_empty_signaled = false


## Get the total number of enemies in the current spawn queue
func get_queue_size() -> int:
	return enemies_to_spawn.size()


## Check if there are enemies left to spawn
func has_enemies_to_spawn() -> bool:
	return enemies_to_spawn.size() > 0


## Process spawning (called by WaveManager during SPAWNING state)
## Returns true if all enemies have been spawned
func process_spawning(delta: float) -> bool:
	if enemies_to_spawn.size() == 0:
		if not _queue_empty_signaled:
			_queue_empty_signaled = true
			spawn_queue_empty.emit()
		return true

	spawn_timer -= delta

	if spawn_timer <= 0:
		_spawn_next_enemy()
		spawn_timer = GameConfig.get_spawn_interval(current_wave)

	return false


## Clear the spawn queue (used during reset)
func clear_queue() -> void:
	enemies_to_spawn.clear()
	spawn_timer = 0.0
	_queue_empty_signaled = false


## Get the number of enemies still in queue
func get_remaining_spawn_count() -> int:
	return enemies_to_spawn.size()


# =============================================================================
# ENEMY SPAWNING
# =============================================================================

## Spawn the next enemy in the queue
func _spawn_next_enemy() -> void:
	if enemies_to_spawn.size() == 0:
		return

	if not _enemy_container or not _grid_manager:
		ErrorHandler.log_error("WaveSpawner", "Missing enemy_container or grid_manager reference")
		return

	var enemy_config = enemies_to_spawn.pop_front()
	var enemy = _spawn_enemy(enemy_config)

	if enemy:
		var is_boss = enemy_config.get("is_boss", false)
		enemy_spawned.emit(enemy, is_boss)


## Spawn a single enemy from config
func _spawn_enemy(config: Dictionary) -> Node:
	if not _enemy_scene:
		ErrorHandler.log_error("WaveSpawner", "Enemy scene not loaded")
		return null

	var enemy = _enemy_scene.instantiate()

	# Load enemy data resource
	var enemy_data = config.get("enemy_data")
	if enemy_data:
		# Setup with wave scaling and modifier
		var modifier_type = config.get("modifier", EnemyModifier.ModifierType.NONE)
		enemy.setup(enemy_data, current_wave, modifier_type)

	# Set spawn position
	if _grid_manager:
		enemy.global_position = _grid_manager.get_spawn_world()

	# Add to container
	_enemy_container.add_child(enemy)

	return enemy


# =============================================================================
# ENEMY SIGNAL MANAGEMENT
# =============================================================================

## Connect signals for a spawned enemy
## Called by WaveManager after receiving enemy_spawned signal
func connect_enemy_signals(enemy: Node, died_callback: Callable, escaped_callback: Callable) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_signal("died"):
		enemy.died.connect(died_callback)
	if enemy.has_signal("escaped"):
		enemy.escaped.connect(escaped_callback)


## Disconnect signals for an enemy
func disconnect_enemy_signals(enemy: Node, died_callback: Callable, escaped_callback: Callable) -> void:
	if not is_instance_valid(enemy):
		return

	if enemy.has_signal("died") and enemy.died.is_connected(died_callback):
		enemy.died.disconnect(died_callback)
	if enemy.has_signal("escaped") and enemy.escaped.is_connected(escaped_callback):
		enemy.escaped.disconnect(escaped_callback)


## Cleanup all enemy signal connections in the container
func cleanup_enemy_signals(died_callback: Callable, escaped_callback: Callable) -> void:
	if not _enemy_container:
		return

	for child in _enemy_container.get_children():
		disconnect_enemy_signals(child, died_callback, escaped_callback)


# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	# Clear references
	_enemy_container = null
	_grid_manager = null
	enemies_to_spawn.clear()
