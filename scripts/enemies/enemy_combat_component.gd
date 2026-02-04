class_name EnemyCombatComponent
extends Node
## Handles combat-related logic for enemy Digimon.
##
## Manages HP tracking, damage taking, death handling, and visual feedback.
## Integrates with EnemyStateMachine for DYING/DEAD state transitions.
##
## Usage:
##   var combat = $EnemyCombatComponent
##   combat.take_damage(50.0, attacker_tower, "fire")
##   if combat.is_dead():
##       # Enemy has been defeated

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyStateMachine = preload("res://scripts/enemies/enemy_state_machine.gd")
const EnemyEffectsComponent = preload("res://scripts/enemies/enemy_effects_component.gd")
const EnemyData = preload("res://scripts/data/enemy_data.gd")

## Emitted when the enemy takes damage.
signal damaged(damage: float, source: Node)

## Emitted when HP changes (for health bar updates).
signal hp_changed(current: float, maximum: float)

## Emitted when the enemy dies.
signal died(killer: Node, reward: int)

## Emitted when the enemy escapes (reaches end of path).
signal escaped(is_boss: bool)

## Reference to the owning enemy (set by parent).
var enemy: Node = null

## Reference to the state machine for state changes.
var state_machine: EnemyStateMachine = null

## Reference to the effects component for effect interactions.
var effects_component: EnemyEffectsComponent = null

## Reference to the sprite for visual feedback.
var sprite: Sprite2D = null

## Reference to the health bar.
var health_bar: ProgressBar = null

## Current HP.
var current_hp: float = 0.0

## Maximum HP.
var max_hp: float = 0.0

## Current armor reduction percentage (0.0 to 1.0).
var current_armor: float = 0.0

## Cached original sprite color for damage flash.
var _original_sprite_color: Color = Color.WHITE

## Whether the enemy is marked as dead.
var _is_dead: bool = false


func _ready() -> void:
	# Will be configured by parent via setup()
	pass


## Setup the component with references and initial stats.
## [param owner_enemy]: The EnemyDigimon owning this component.
## [param machine]: The EnemyStateMachine for state changes.
## [param effects]: The EnemyEffectsComponent for effect interactions.
## [param hp]: Initial HP value.
## [param armor]: Initial armor value (0.0 to 1.0).
func setup(
	owner_enemy: Node,
	machine: EnemyStateMachine,
	effects: EnemyEffectsComponent,
	hp: float,
	armor: float
) -> void:
	enemy = owner_enemy
	state_machine = machine
	effects_component = effects
	max_hp = hp
	current_hp = hp
	current_armor = clampf(armor, 0.0, 0.9)  # Cap at 90%


## Set the sprite reference for visual feedback.
func set_sprite(enemy_sprite: Sprite2D) -> void:
	sprite = enemy_sprite
	if sprite:
		_original_sprite_color = sprite.modulate


## Set the health bar reference for HP display.
func set_health_bar(bar: ProgressBar) -> void:
	health_bar = bar
	_update_health_bar()


## Take damage from a source.
## [param amount]: Base damage amount before reductions.
## [param source]: The node dealing the damage.
## [param damage_type]: Optional damage type for special handling.
func take_damage(amount: float, source: Node, damage_type: String = "") -> void:
	if _is_dead:
		return

	# Check state machine allows damage
	if state_machine and not state_machine.can_take_damage():
		return

	var final_damage = _calculate_final_damage(amount, source)

	# Apply damage
	current_hp -= final_damage

	# Emit signals
	damaged.emit(final_damage, source)
	hp_changed.emit(current_hp, max_hp)

	# Update visuals
	_update_health_bar()
	_flash_damage()

	# Check for death
	if current_hp <= 0:
		_die(source)


## Apply DoT damage (bypasses armor).
## [param amount]: Damage amount.
## [param effect_name]: Name of the effect causing the damage.
func take_dot_damage(amount: float, effect_name: String = "") -> void:
	if _is_dead:
		return

	if state_machine and not state_machine.can_take_damage():
		return

	current_hp -= amount
	hp_changed.emit(current_hp, max_hp)
	_update_health_bar()

	if current_hp <= 0:
		_die(null)


## Heal the enemy.
## [param amount]: Amount to heal.
## Returns the actual amount healed.
func heal(amount: float) -> float:
	if _is_dead:
		return 0.0

	# Apply heal reduction from effects
	var heal_reduction = 0.0
	if effects_component:
		heal_reduction = effects_component.get_heal_reduction()

	var actual_heal = amount * (1.0 - heal_reduction)
	var old_hp = current_hp
	current_hp = minf(current_hp + actual_heal, max_hp)
	var healed = current_hp - old_hp

	if healed > 0:
		hp_changed.emit(current_hp, max_hp)
		_update_health_bar()

	return healed


## Instantly kill the enemy (used by instakill effects).
func instant_kill() -> void:
	if _is_dead:
		return
	_die(null)


## Handle the enemy escaping (reaching end of path).
## [param enemy_data]: The EnemyData resource.
func handle_escape(enemy_data: Resource) -> void:
	if _is_dead:
		return

	_is_dead = true

	var is_boss = enemy_data.is_boss if enemy_data else false

	# Transition to dead state
	if state_machine:
		state_machine.transition_to(EnemyStateMachine.State.DEAD)

	# Play escape sound
	AudioManager.play_sfx("enemy_escape")

	# Emit signal
	escaped.emit(is_boss)

	# Reduce lives via GameManager
	if GameManager:
		GameManager.lose_life(is_boss)


## Check if the enemy is dead.
func is_dead() -> bool:
	return _is_dead


## Get the current HP percentage (0.0 to 1.0).
func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return current_hp / max_hp


## Set the armor value.
## [param armor]: New armor value (0.0 to 1.0).
func set_armor(armor: float) -> void:
	current_armor = clampf(armor, 0.0, 0.9)


## Calculate the final damage after all reductions.
func _calculate_final_damage(amount: float, source: Node) -> float:
	# Get effective armor (base armor minus shred)
	var effective_armor = current_armor
	if effects_component:
		var shred = effects_component.get_armor_shred()
		effective_armor = maxf(0.0, effective_armor - shred)

	var damage_after_armor = amount * (1.0 - effective_armor)

	# Apply attribute multiplier if source has attribute
	if source and source.has_method("get_attribute") and enemy:
		var attacker_attr = source.get_attribute()
		if enemy.has_method("get_enemy_data"):
			var enemy_data = enemy.get_enemy_data()
			if enemy_data:
				var multiplier = EnemyData.get_attribute_multiplier(attacker_attr, enemy_data.attribute)
				damage_after_armor *= multiplier

	return damage_after_armor


## Handle enemy death.
func _die(killer: Node) -> void:
	if _is_dead:
		return

	_is_dead = true

	# Transition to dying state
	if state_machine:
		state_machine.transition_to(EnemyStateMachine.State.DYING)

	# Clear effects
	if effects_component:
		effects_component.clear_all_effects()

	# Get reward
	var reward = 5
	if enemy and enemy.has_method("get_enemy_data"):
		var enemy_data = enemy.get_enemy_data()
		if enemy_data:
			reward = enemy_data.reward

	# Play death sound
	AudioManager.play_sfx("enemy_death", 0.15)

	# Emit signal
	died.emit(killer, reward)

	# Play death effect
	_play_death_effect()

	# Transition to dead state
	if state_machine:
		state_machine.transition_to(EnemyStateMachine.State.DEAD)


## Update the health bar display.
func _update_health_bar() -> void:
	if not health_bar:
		return

	health_bar.max_value = max_hp
	health_bar.value = current_hp

	# Hide health bar if full
	health_bar.visible = current_hp < max_hp


## Flash the sprite red when taking damage.
func _flash_damage() -> void:
	if not sprite:
		return

	sprite.modulate = Color.RED

	# Create tween to restore color
	var tween = create_tween()
	tween.tween_property(sprite, "modulate", _original_sprite_color, 0.15)


## Play death visual effect.
func _play_death_effect() -> void:
	if not sprite:
		return

	# Fade out effect
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_property(sprite, "scale", Vector2.ZERO, 0.1)


func _exit_tree() -> void:
	# Null references
	enemy = null
	state_machine = null
	effects_component = null
	sprite = null
	health_bar = null
