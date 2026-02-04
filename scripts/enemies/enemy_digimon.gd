class_name EnemyDigimon
extends Area2D
## Main enemy class for Digimon enemies.
##
## Handles movement along path and coordinates between components.
## Status effects are handled by EnemyEffectsComponent.
## Combat (damage, death) is handled by EnemyCombatComponent.
## State transitions are managed by EnemyStateMachine.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyData = preload("res://scripts/data/enemy_data.gd")
const EnemyModifier = preload("res://scripts/enemies/enemy_modifier.gd")
const EnemyStateMachine = preload("res://scripts/enemies/enemy_state_machine.gd")
const EnemyEffectsComponent = preload("res://scripts/enemies/enemy_effects_component.gd")
const EnemyCombatComponent = preload("res://scripts/enemies/enemy_combat_component.gd")
const TraitEffect = preload("res://scripts/data/trait_effect.gd")

## Emitted when the enemy dies
signal died(enemy: EnemyDigimon, killer: Node, reward: int)
## Emitted when the enemy escapes (reaches end of path)
signal escaped(enemy: EnemyDigimon, is_boss: bool)
## Emitted when the enemy takes damage
signal damaged(enemy: EnemyDigimon, damage: float, source: Node)
## Emitted when HP changes (for health bar updates)
signal hp_changed(current: float, maximum: float)

## The enemy data resource defining this enemy's stats
@export var enemy_data: EnemyData

## Reference to GridManager for path navigation
var grid_manager: Node = null

## Path following
var path_index: int = 0
var path_waypoints: Array[Vector2] = []

## Cached path data for O(1) progress calculations
var _cached_path_length: float = 0.0
var _cached_waypoint_distances: Array[float] = []

## Base movement speed (pixels per second at 1.0x speed)
var base_move_speed: float = 100.0

## Wave scaling factor (increases enemy stats per wave)
var wave_scale: float = 1.0

## Modifier from Wave 50+
var modifier_type: EnemyModifier.ModifierType = EnemyModifier.ModifierType.NONE
var _modifier_stats: Dictionary = {}

## For splitter enemies - the data to use for split children
var split_enemy_data: EnemyData = null

## Node references
@onready var sprite: Sprite2D = $Sprite
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Component references
var state_machine: EnemyStateMachine
var effects_component: EnemyEffectsComponent
var combat_component: EnemyCombatComponent


func _ready() -> void:
	_setup_components()

	if enemy_data:
		_initialize_from_data()

	# Find GridManager in the scene
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_node("GridManager"):
		grid_manager = level.get_node("GridManager")
		path_waypoints = grid_manager.get_path_waypoints()

	# Set initial position to spawn point
	if path_waypoints.size() > 0:
		global_position = path_waypoints[0]
		_cache_path_data()

	# Start moving
	if state_machine:
		state_machine.transition_to(EnemyStateMachine.State.MOVING)


func _process(delta: float) -> void:
	if not state_machine or not state_machine.is_alive():
		return

	# Process HP regeneration
	_process_regen(delta)

	# Handle movement based on state
	if not state_machine.is_movement_blocked():
		_follow_path(delta)


## Setup component nodes.
func _setup_components() -> void:
	# Create or get state machine
	state_machine = get_node_or_null("EnemyStateMachine")
	if not state_machine:
		state_machine = EnemyStateMachine.new()
		state_machine.name = "EnemyStateMachine"
		add_child(state_machine)

	# Create or get effects component
	effects_component = get_node_or_null("EnemyEffectsComponent")
	if not effects_component:
		effects_component = EnemyEffectsComponent.new()
		effects_component.name = "EnemyEffectsComponent"
		add_child(effects_component)

	# Create or get combat component
	combat_component = get_node_or_null("EnemyCombatComponent")
	if not combat_component:
		combat_component = EnemyCombatComponent.new()
		combat_component.name = "EnemyCombatComponent"
		add_child(combat_component)

	# Connect component signals
	_connect_component_signals()


## Connect signals between components.
func _connect_component_signals() -> void:
	# Effects component signals
	if effects_component:
		effects_component.dot_tick.connect(_on_dot_tick)

	# Combat component signals
	if combat_component:
		combat_component.died.connect(_on_combat_died)
		combat_component.escaped.connect(_on_combat_escaped)
		combat_component.damaged.connect(_on_combat_damaged)
		combat_component.hp_changed.connect(_on_combat_hp_changed)


## Cache path data for O(1) progress calculations.
func _cache_path_data() -> void:
	_cached_path_length = 0.0
	_cached_waypoint_distances.clear()
	_cached_waypoint_distances.append(0.0)

	for i in range(1, path_waypoints.size()):
		var segment_length = path_waypoints[i - 1].distance_to(path_waypoints[i])
		_cached_path_length += segment_length
		_cached_waypoint_distances.append(_cached_path_length)


## Initialize stats from enemy_data.
func _initialize_from_data() -> void:
	if not enemy_data:
		return

	# Get modifier stats
	_modifier_stats = EnemyModifier.get_modifier_stats(modifier_type)

	# Calculate effective stats with wave scaling and modifiers
	var base_effective_hp = enemy_data.get_effective_hp()
	var max_hp = base_effective_hp * wave_scale * _modifier_stats["hp_mult"]
	var current_armor = enemy_data.get_effective_armor() + _modifier_stats["armor_add"]
	current_armor = clampf(current_armor, 0.0, 0.9)

	# Setup components
	if effects_component:
		effects_component.setup(self, state_machine, sprite)

	if combat_component:
		combat_component.setup(self, state_machine, effects_component, max_hp, current_armor)
		combat_component.set_sprite(sprite)
		combat_component.set_health_bar(health_bar)

	# Apply modifier visual
	if sprite and modifier_type != EnemyModifier.ModifierType.NONE:
		sprite.modulate = EnemyModifier.get_modifier_color(modifier_type)

	# Apply size modifier
	if _modifier_stats["size_mult"] != 1.0:
		scale = Vector2.ONE * _modifier_stats["size_mult"]


## Setup the enemy with data and wave parameters.
func setup(data: EnemyData, wave_number: int = 1, mod_type: EnemyModifier.ModifierType = EnemyModifier.ModifierType.NONE) -> void:
	enemy_data = data
	wave_scale = _calculate_wave_scale(wave_number)
	modifier_type = mod_type
	_initialize_from_data()


## Calculate wave scaling factor (HP scales roughly 10% per wave).
func _calculate_wave_scale(wave_number: int) -> float:
	return 1.0 + (wave_number - 1) * 0.1


## Follow the path to the end.
func _follow_path(delta: float) -> void:
	if path_waypoints.size() == 0 or path_index >= path_waypoints.size():
		_escape()
		return

	var target = path_waypoints[path_index]

	# Check if feared (moving backward)
	var is_feared = effects_component and effects_component.is_feared()
	if is_feared and path_index > 0:
		target = path_waypoints[path_index - 1]

	var direction = (target - global_position).normalized()
	var speed_modifier = _get_current_speed_modifier()
	var move_distance = base_move_speed * speed_modifier * delta

	# Check if we've reached the waypoint (using squared distance for performance)
	var distance_sq_to_target = global_position.distance_squared_to(target)
	var move_distance_sq = move_distance * move_distance

	if distance_sq_to_target <= move_distance_sq:
		global_position = target

		if is_feared:
			path_index = maxi(0, path_index - 1)
		else:
			path_index += 1

		# Check if we've reached the end
		if path_index >= path_waypoints.size():
			_escape()
			return
	else:
		global_position += direction * move_distance

		# Rotate sprite to face movement direction
		if sprite:
			sprite.flip_h = direction.x < 0


## Get the current speed modifier from all sources.
func _get_current_speed_modifier() -> float:
	var base_speed = enemy_data.get_effective_speed() if enemy_data else 1.0
	var modifier_speed = _modifier_stats.get("speed_mult", 1.0)
	var effects_speed = effects_component.get_speed_modifier() if effects_component else 1.0

	return base_speed * modifier_speed * effects_speed


## Process HP regeneration.
func _process_regen(delta: float) -> void:
	if not enemy_data or not combat_component:
		return

	var regen_rate = enemy_data.get_regen_rate()
	if regen_rate <= 0:
		return

	var heal_amount = combat_component.max_hp * regen_rate * delta
	combat_component.heal(heal_amount)


## Take damage from a source (delegates to combat component).
func take_damage(amount: float, source: Node, damage_type: String = "") -> void:
	if combat_component:
		combat_component.take_damage(amount, source, damage_type)


## Apply a status effect (delegates to effects component).
func apply_effect(effect: TraitEffect) -> void:
	if effects_component:
		effects_component.apply_effect(effect)


## Apply knockback effect.
func apply_knockback(distance_tiles: float) -> void:
	if path_index <= 0:
		return

	var pixels_to_move = distance_tiles * 64  # TILE_SIZE
	var remaining = pixels_to_move

	while remaining > 0 and path_index > 0:
		var prev_waypoint = path_waypoints[path_index - 1]
		var dist_to_prev = global_position.distance_to(prev_waypoint)

		if dist_to_prev <= remaining:
			global_position = prev_waypoint
			remaining -= dist_to_prev
			path_index -= 1
		else:
			var direction = (prev_waypoint - global_position).normalized()
			global_position += direction * remaining
			remaining = 0


## Instant kill (for instakill effects).
func instant_kill() -> void:
	if combat_component:
		combat_component.instant_kill()


## Handle enemy escaping (reaching end of path).
func _escape() -> void:
	if combat_component:
		combat_component.handle_escape(enemy_data)
	queue_free()


## Handle enemy death (called internally).
func _handle_death(killer: Node) -> void:
	# Handle splitter
	if enemy_data and enemy_data.does_split():
		_spawn_split_enemies()

	queue_free()


## Spawn split enemies when a splitter dies.
func _spawn_split_enemies() -> void:
	if not enemy_data or not enemy_data.does_split():
		return

	var split_count = enemy_data.get_split_count()
	var data_to_use = split_enemy_data if split_enemy_data else enemy_data

	for i in range(split_count):
		var split_enemy = duplicate()
		split_enemy.enemy_data = data_to_use
		split_enemy.path_index = path_index
		split_enemy.wave_scale = wave_scale * 0.5
		split_enemy.modifier_type = EnemyModifier.ModifierType.NONE

		var offset = Vector2(randf_range(-20, 20), randf_range(-20, 20))
		split_enemy.global_position = global_position + offset

		get_parent().add_child(split_enemy)


## Check if this enemy is flying (for targeting purposes).
func is_flying() -> bool:
	if enemy_data:
		return enemy_data.enemy_type == EnemyData.EnemyType.FLYING
	return false


## Get remaining distance to end of path (O(1) using cached data).
func get_remaining_distance() -> float:
	if path_waypoints.size() == 0 or _cached_path_length <= 0.0:
		return 0.0

	var distance_to_current: float = 0.0
	if path_index < path_waypoints.size():
		distance_to_current = global_position.distance_to(path_waypoints[path_index])

	var distance_from_waypoint_to_end: float = 0.0
	if path_index < _cached_waypoint_distances.size():
		distance_from_waypoint_to_end = _cached_path_length - _cached_waypoint_distances[path_index]

	return distance_to_current + distance_from_waypoint_to_end


## Get path progress as a value from 0.0 to 1.0 (1.0 = at end).
## O(1) complexity using cached path data.
func get_path_progress() -> float:
	if _cached_path_length <= 0.0:
		return 0.0

	var distance_traveled: float = 0.0
	if path_index > 0 and path_index < _cached_waypoint_distances.size():
		distance_traveled = _cached_waypoint_distances[path_index - 1]
		var prev_waypoint = path_waypoints[path_index - 1]
		distance_traveled += prev_waypoint.distance_to(global_position)
	elif path_index > 0:
		distance_traveled = _cached_path_length

	return clampf(distance_traveled / _cached_path_length, 0.0, 1.0)


## Get the attribute of this enemy (for damage calculations).
func get_attribute() -> int:
	if enemy_data:
		return enemy_data.attribute
	return EnemyData.Attribute.DATA


## Get the enemy data resource.
func get_enemy_data() -> EnemyData:
	return enemy_data


## Check if the enemy is dead.
func is_dead() -> bool:
	if combat_component:
		return combat_component.is_dead()
	return false


# -----------------------------------------------------------------------------
# Signal handlers for component integration
# -----------------------------------------------------------------------------

func _on_dot_tick(effect_name: String, damage: float) -> void:
	if combat_component:
		combat_component.take_dot_damage(damage, effect_name)
		if combat_component.is_dead():
			_handle_death(null)


func _on_combat_died(killer: Node, reward: int) -> void:
	died.emit(self, killer, reward)
	_handle_death(killer)


func _on_combat_escaped(is_boss: bool) -> void:
	escaped.emit(self, is_boss)


func _on_combat_damaged(damage: float, source: Node) -> void:
	damaged.emit(self, damage, source)


func _on_combat_hp_changed(current: float, maximum: float) -> void:
	hp_changed.emit(current, maximum)
