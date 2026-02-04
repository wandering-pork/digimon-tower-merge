class_name EnemySplitterComponent
extends Node
## Component that handles split enemy behavior.
##
## Manages splitting logic when an enemy dies, spawning smaller
## child enemies at the death location.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const EnemyModifier = preload("res://scripts/enemies/enemy_modifier.gd")

# =============================================================================
# SIGNALS
# =============================================================================

## Emitted when split enemies are spawned
signal split_spawned(split_count: int)

# =============================================================================
# PROPERTIES
# =============================================================================

## For splitter enemies - the data to use for split children
## If null, uses the parent's enemy_data
var split_enemy_data: EnemyData = null

## Reference to the parent enemy
var _enemy: Node = null

# =============================================================================
# SETUP
# =============================================================================

## Setup the component with parent enemy reference.
func setup(enemy: Node) -> void:
	_enemy = enemy


## Set the enemy data to use for split children.
func set_split_data(data: EnemyData) -> void:
	split_enemy_data = data

# =============================================================================
# SPLIT LOGIC
# =============================================================================

## Check if this enemy should split on death.
func should_split() -> bool:
	if not _enemy:
		return false

	var enemy_data = _enemy.get_enemy_data() if _enemy.has_method("get_enemy_data") else null
	if not enemy_data:
		return false

	return enemy_data.does_split()


## Get the number of enemies to spawn on split.
func get_split_count() -> int:
	if not _enemy:
		return 0

	var enemy_data = _enemy.get_enemy_data() if _enemy.has_method("get_enemy_data") else null
	if not enemy_data:
		return 0

	return enemy_data.get_split_count()


## Spawn split enemies when the parent enemy dies.
## Returns true if split enemies were spawned.
func spawn_split_enemies() -> bool:
	if not should_split():
		return false

	var enemy_data = _enemy.get_enemy_data()
	var split_count = enemy_data.get_split_count()
	var data_to_use = split_enemy_data if split_enemy_data else enemy_data

	# Get spawn container (parent of enemy)
	var spawn_container = _enemy.get_parent()
	if not spawn_container:
		return false

	for i in range(split_count):
		var split_enemy = _enemy.duplicate()
		split_enemy.enemy_data = data_to_use
		split_enemy.path_index = _enemy.path_index
		split_enemy.wave_scale = _enemy.wave_scale * 0.5
		split_enemy.modifier_type = EnemyModifier.ModifierType.NONE

		# Clear splitter component's split data to prevent infinite splits
		# (unless split_enemy_data was explicitly set to a splitter)
		var splitter = split_enemy.get_node_or_null("EnemySplitterComponent")
		if splitter:
			splitter.split_enemy_data = null

		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		split_enemy.global_position = _enemy.global_position + offset

		spawn_container.add_child(split_enemy)

	split_spawned.emit(split_count)
	return true

# =============================================================================
# CLEANUP
# =============================================================================

func _exit_tree() -> void:
	_enemy = null
	split_enemy_data = null
