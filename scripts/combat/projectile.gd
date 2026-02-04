class_name Projectile
extends Area2D
## Projectile for ranged tower attacks.
## Coordinates movement behaviors and on-hit effects through component classes.
## Base class handling movement, collision detection, and lifecycle management.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const ProjectileBehaviors = preload("res://scripts/combat/projectile_behaviors.gd")
const ProjectileEffects = preload("res://scripts/combat/projectile_effects.gd")

## Emitted when the projectile hits a target
signal hit_target(target: Node, damage: int, is_critical: bool)
## Emitted when the projectile is destroyed
signal destroyed()
## Emitted when AoE is triggered (for visual effects)
signal aoe_triggered(center: Vector2, radius: float)
## Emitted when chain lightning is triggered (for visual effects)
signal chain_triggered(from: Vector2, to: Vector2)

## Attack type for this projectile
enum AttackType {
	SINGLE,    ## Hits one target then destroys
	PIERCE,    ## Passes through multiple enemies
	CHAIN,     ## Bounces to nearby enemies
	AOE,       ## Explodes on impact, damaging area
	TRACKING,  ## Homes in on target
	SPLASH     ## Damages main target + reduced damage to nearby
}

## Configuration
@export var speed: float = 400.0
@export var attack_type: AttackType = AttackType.SINGLE
@export var damage: int = 10
@export var damage_type: String = "physical"

## Node references
@onready var sprite: Sprite2D = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

## Target tracking
var target: Node2D = null
var source: Node = null
var last_target_position: Vector2 = Vector2.ZERO

## State
var _is_destroyed: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _lifetime: float = 5.0

## Component references
var _behaviors: ProjectileBehaviors = null
var _effects: ProjectileEffects = null

## Combat system reference
var _combat_system: Node = null


func _ready() -> void:
	# Connect collision signals
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

	# Set collision layer/mask
	collision_layer = 0
	collision_mask = 4  # Enemies layer

	# Find combat system
	_combat_system = get_tree().get_first_node_in_group("combat_system")

	# Initialize components
	_init_components()

	# Initialize velocity toward target
	if is_instance_valid(target):
		last_target_position = target.global_position
		_velocity = (last_target_position - global_position).normalized() * speed
		_rotate_to_velocity()


func _init_components() -> void:
	_behaviors = ProjectileBehaviors.new()
	_behaviors.initialize(self, _combat_system)

	_effects = ProjectileEffects.new()
	_effects.initialize(self, _combat_system)
	_effects.set_damage_params(source, damage, damage_type)


func _exit_tree() -> void:
	# Disconnect signals to prevent memory leaks
	if body_entered.is_connected(_on_body_entered):
		body_entered.disconnect(_on_body_entered)
	if area_entered.is_connected(_on_area_entered):
		area_entered.disconnect(_on_area_entered)

	# Cleanup components
	if _behaviors:
		_behaviors.cleanup()
		_behaviors = null
	if _effects:
		_effects.cleanup()
		_effects = null


func _process(delta: float) -> void:
	if _is_destroyed:
		return

	# Update lifetime
	_lifetime -= delta
	if _lifetime <= 0:
		_destroy()
		return

	# Update movement based on attack type
	match attack_type:
		AttackType.TRACKING:
			_move_tracking(delta)
		_:
			_move_straight(delta)


## Move straight toward last known target position
func _move_straight(delta: float) -> void:
	var result = _behaviors.move_straight(
		delta, global_position, _velocity, last_target_position, attack_type
	)
	global_position = result["position"]
	if result["should_destroy"]:
		_destroy()


## Move with tracking toward current target
func _move_tracking(delta: float) -> void:
	var result = _behaviors.move_tracking(delta, global_position, target, speed)

	if result["should_destroy"]:
		_destroy()
		return

	global_position = result["position"]
	_velocity = result["velocity"]
	target = result["target"]
	if is_instance_valid(target):
		last_target_position = target.global_position
	_rotate_to_velocity()


## Rotate sprite to face velocity direction
func _rotate_to_velocity() -> void:
	if _velocity != Vector2.ZERO:
		rotation = _velocity.angle()


## Handle collision with body (CharacterBody2D enemies)
func _on_body_entered(body: Node2D) -> void:
	if _is_destroyed:
		return
	if body.is_in_group("enemies"):
		_handle_hit(body)


## Handle collision with area (Area2D enemies)
func _on_area_entered(area: Area2D) -> void:
	if _is_destroyed:
		return
	if area.is_in_group("enemies"):
		_handle_hit(area)


## Handle hitting an enemy
func _handle_hit(enemy: Node2D) -> void:
	if not is_instance_valid(enemy):
		return

	# Check if already hit this enemy
	if _behaviors.was_pierced(enemy) or _behaviors.was_chained(enemy):
		return

	# Calculate and apply damage
	var chain_mult = _behaviors.get_chain_damage_multiplier()
	var damage_result = _effects.calculate_damage(enemy, chain_mult)
	_effects.apply_damage(enemy, damage_result)

	# Emit hit signal
	hit_target.emit(enemy, damage_result["damage"], damage_result["is_critical"])

	# Handle post-hit behavior based on attack type
	match attack_type:
		AttackType.SINGLE:
			_destroy()

		AttackType.PIERCE:
			if _behaviors.handle_pierce(enemy):
				_destroy()

		AttackType.CHAIN:
			var next_target = _behaviors.handle_chain(enemy)
			if next_target:
				_chain_to_target(enemy, next_target)
			else:
				_destroy()

		AttackType.AOE:
			_effects.apply_aoe_damage(enemy.global_position)
			_destroy()

		AttackType.SPLASH:
			_effects.apply_splash_damage(enemy, enemy.global_position)
			_destroy()

		AttackType.TRACKING:
			_destroy()


## Chain to next target
func _chain_to_target(current_enemy: Node, next_target: Node) -> void:
	# Move to current enemy position
	global_position = current_enemy.global_position
	target = next_target
	last_target_position = next_target.global_position
	_velocity = (last_target_position - global_position).normalized() * speed
	_rotate_to_velocity()

	# Spawn visual effect
	_effects.spawn_chain_effect(current_enemy.global_position, next_target.global_position)


## Destroy this projectile
func _destroy() -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	destroyed.emit()
	queue_free()


## Setup the projectile with all parameters
func setup(
	p_source: Node,
	p_target: Node2D,
	p_damage: int,
	p_type: AttackType = AttackType.SINGLE,
	p_speed: float = 400.0,
	p_damage_type: String = "physical"
) -> void:
	source = p_source
	target = p_target
	damage = p_damage
	attack_type = p_type
	speed = p_speed
	damage_type = p_damage_type

	if is_instance_valid(target):
		last_target_position = target.global_position
		_velocity = (last_target_position - global_position).normalized() * speed
		_rotate_to_velocity()

	# Update effects component if already initialized
	if _effects:
		_effects.set_damage_params(source, damage, damage_type)


## Configure pierce parameters
func set_pierce(max_p: int) -> void:
	if _behaviors:
		_behaviors.set_pierce(max_p)


## Configure chain parameters
func set_chain(max_c: int, falloff: float = 0.5, c_range: float = 128.0) -> void:
	if _behaviors:
		_behaviors.set_chain(max_c, falloff, c_range)


## Configure AoE parameters
func set_aoe(radius: float, falloff: float = 0.5) -> void:
	if _effects:
		_effects.set_aoe(radius, falloff)


## Configure splash parameters
func set_splash(radius: float, damage_percent: float = 0.5) -> void:
	if _effects:
		_effects.set_splash(radius, damage_percent)
