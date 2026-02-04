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
const EnemySplitterComponent = preload("res://scripts/enemies/enemy_splitter_component.gd")
const EnemyMovementComponent = preload("res://scripts/enemies/enemy_movement_component.gd")
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

## Base movement speed (pixels per second at 1.0x speed)
var base_move_speed: float = 100.0

## Wave scaling factor (increases enemy stats per wave)
var wave_scale: float = 1.0

## Modifier from Wave 50+
var modifier_type: EnemyModifier.ModifierType = EnemyModifier.ModifierType.NONE
var _modifier_stats: Dictionary = {}

## Node references
@onready var sprite: Sprite2D = $Sprite
@onready var health_bar: ProgressBar = $HealthBar
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Component references
var state_machine: EnemyStateMachine
var effects_component: EnemyEffectsComponent
var combat_component: EnemyCombatComponent
var splitter_component: EnemySplitterComponent
var movement_component: EnemyMovementComponent


func _ready() -> void:
	_setup_components()

	if enemy_data:
		_initialize_from_data()

	# Find GridManager and setup movement
	var level = get_tree().get_first_node_in_group("level")
	if level and level.has_node("GridManager"):
		grid_manager = level.get_node("GridManager")
		var waypoints = grid_manager.get_path_waypoints()
		if movement_component:
			movement_component.setup(self, waypoints, effects_component, sprite)
			movement_component.set_to_spawn()

	# Start moving
	if state_machine:
		state_machine.transition_to(EnemyStateMachine.State.MOVING)


func _process(delta: float) -> void:
	if not state_machine or not state_machine.is_alive():
		return

	# Process HP regeneration
	_process_regen(delta)

	# Handle movement based on state
	if not state_machine.is_movement_blocked() and movement_component:
		var speed_mult = enemy_data.get_effective_speed() if enemy_data else 1.0
		var modifier_mult = _modifier_stats.get("speed_mult", 1.0)
		movement_component.follow_path(delta, base_move_speed, speed_mult, modifier_mult)


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

	# Create or get splitter component
	splitter_component = get_node_or_null("EnemySplitterComponent")
	if not splitter_component:
		splitter_component = EnemySplitterComponent.new()
		splitter_component.name = "EnemySplitterComponent"
		add_child(splitter_component)

	# Create or get movement component
	movement_component = get_node_or_null("EnemyMovementComponent")
	if not movement_component:
		movement_component = EnemyMovementComponent.new()
		movement_component.name = "EnemyMovementComponent"
		add_child(movement_component)

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

	# Splitter component setup
	if splitter_component:
		splitter_component.setup(self)


## Cache path data for O(1) progress calculations.
## Delegated to EnemyMovementComponent.
func _cache_path_data() -> void:
	pass  # Handled by movement_component


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
## Delegated to EnemyMovementComponent.
func _follow_path(_delta: float) -> void:
	pass  # Handled by movement_component in _process()


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
## Delegated to EnemyMovementComponent.
func apply_knockback(distance_tiles: float) -> void:
	if movement_component:
		movement_component.apply_knockback(distance_tiles)


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
	# Handle splitter via component
	if splitter_component:
		splitter_component.spawn_split_enemies()

	queue_free()


## Check if this enemy is flying (for targeting purposes).
func is_flying() -> bool:
	if enemy_data:
		return enemy_data.enemy_type == EnemyData.EnemyType.FLYING
	return false


## Get remaining distance to end of path (O(1) using cached data).
## Delegated to EnemyMovementComponent.
func get_remaining_distance() -> float:
	if movement_component:
		return movement_component.get_remaining_distance()
	return 0.0


## Get path progress as a value from 0.0 to 1.0 (1.0 = at end).
## O(1) complexity using cached path data.
## Delegated to EnemyMovementComponent.
func get_path_progress() -> float:
	if movement_component:
		return movement_component.get_path_progress()
	return 0.0


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


## Set the split enemy data (for external configuration).
func set_split_data(data: EnemyData) -> void:
	if splitter_component:
		splitter_component.set_split_data(data)


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
