class_name EnemyEffectsComponent
extends Node
## Handles status effect processing for enemy Digimon.
##
## Manages application, tracking, and removal of status effects like slow,
## stun, burn, poison, fear, etc. Integrates with EnemyStateMachine for
## state-based effect behavior.
##
## Usage:
##   var effects_component = $EnemyEffectsComponent
##   effects_component.apply_effect(burn_effect)
##   var speed_mod = effects_component.get_speed_modifier()

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const EnemyStateMachine = preload("res://scripts/enemies/enemy_state_machine.gd")
const TraitEffect = preload("res://scripts/data/trait_effect.gd")

## Emitted when an effect is applied.
signal effect_applied(effect_name: String, stacks: int)

## Emitted when an effect is removed.
signal effect_removed(effect_name: String)

## Emitted when a DoT tick occurs.
signal dot_tick(effect_name: String, damage: float)

## Reference to the owning enemy (set by parent).
var enemy: Node = null

## Reference to the state machine for state changes.
var state_machine: EnemyStateMachine = null

## Reference to the sprite for visual effects.
var sprite: Sprite2D = null

## Active status effects. Key: effect_name (String), Value: Dictionary with effect data.
var active_effects: Dictionary = {}

## Effect timers for DoT processing.
var _effect_tick_timers: Dictionary = {}

## Cached speed modifier to avoid recalculating every frame.
var _cached_speed_modifier: float = 1.0
var _speed_modifier_dirty: bool = true


func _ready() -> void:
	# Will be configured by parent via setup()
	pass


func _process(delta: float) -> void:
	if active_effects.is_empty():
		return

	_process_effects(delta)


## Setup the component with references to required nodes.
## [param owner_enemy]: The EnemyDigimon owning this component.
## [param machine]: The EnemyStateMachine for state changes.
## [param enemy_sprite]: The sprite for visual effects.
func setup(owner_enemy: Node, machine: EnemyStateMachine, enemy_sprite: Sprite2D = null) -> void:
	enemy = owner_enemy
	state_machine = machine
	sprite = enemy_sprite


## Apply a status effect to the enemy.
## [param effect]: The TraitEffect resource to apply.
func apply_effect(effect: TraitEffect) -> void:
	if not effect:
		return

	# Check if state machine allows effects
	if state_machine and not state_machine.is_alive():
		return

	var effect_key = effect.effect_name

	# Handle stacking
	if active_effects.has(effect_key):
		var existing = active_effects[effect_key]

		if effect.refresh_on_reapply:
			existing["remaining_time"] = effect.duration

		if effect.is_stacking:
			existing["stacks"] = mini(existing["stacks"] + 1, effect.max_stacks)

		effect_applied.emit(effect_key, existing["stacks"])
	else:
		# Add new effect
		active_effects[effect_key] = {
			"effect": effect,
			"remaining_time": effect.duration,
			"stacks": 1
		}
		_effect_tick_timers[effect_key] = 0.0

		effect_applied.emit(effect_key, 1)

	# Mark speed modifier as needing recalculation
	_speed_modifier_dirty = true

	# Apply immediate effects
	_apply_effect_immediate(effect)


## Remove a status effect by name.
## [param effect_name]: The name of the effect to remove.
func remove_effect(effect_name: String) -> void:
	if active_effects.has(effect_name):
		active_effects.erase(effect_name)
		_effect_tick_timers.erase(effect_name)
		_speed_modifier_dirty = true
		effect_removed.emit(effect_name)


## Clear all active effects.
func clear_all_effects() -> void:
	var effect_names = active_effects.keys()
	active_effects.clear()
	_effect_tick_timers.clear()
	_speed_modifier_dirty = true
	_cached_speed_modifier = 1.0

	for effect_name in effect_names:
		effect_removed.emit(effect_name)


## Check if a specific effect is active.
## [param effect_name]: The name of the effect to check.
## Returns true if the effect is currently active.
func has_effect(effect_name: String) -> bool:
	return active_effects.has(effect_name)


## Get the number of stacks for an effect.
## [param effect_name]: The name of the effect.
## Returns the stack count, or 0 if not active.
func get_effect_stacks(effect_name: String) -> int:
	if active_effects.has(effect_name):
		return active_effects[effect_name]["stacks"]
	return 0


## Get the remaining duration for an effect.
## [param effect_name]: The name of the effect.
## Returns the remaining time in seconds, or 0 if not active.
func get_effect_remaining_time(effect_name: String) -> float:
	if active_effects.has(effect_name):
		return active_effects[effect_name]["remaining_time"]
	return 0.0


## Get the current armor shred amount from active effects.
## Returns the total armor reduction percentage (0.0 to 1.0).
func get_armor_shred() -> float:
	if not active_effects.has("armor_shred"):
		return 0.0

	var shred_data = active_effects["armor_shred"]
	return shred_data.get("reduction", 0.0)


## Get the current speed modifier from all active effects.
## Returns a multiplier (e.g., 0.7 means 70% speed).
func get_speed_modifier() -> float:
	if _speed_modifier_dirty:
		_recalculate_speed_modifier()
	return _cached_speed_modifier


## Get the current heal reduction from poison effects.
## Returns the reduction percentage (0.0 to 1.0).
func get_heal_reduction() -> float:
	if not active_effects.has("Poison"):
		return 0.0

	var poison_effect: TraitEffect = active_effects["Poison"]["effect"]
	return poison_effect.heal_reduction_percent


## Check if the enemy is currently feared (moving backward).
func is_feared() -> bool:
	for data in active_effects.values():
		var effect: TraitEffect = data["effect"]
		if effect.effect_type == TraitEffect.EffectType.FEAR:
			return true
	return false


## Apply immediate effects like knockback or stun.
func _apply_effect_immediate(effect: TraitEffect) -> void:
	match effect.effect_type:
		TraitEffect.EffectType.FREEZE:
			# Transition to stunned state
			if state_machine:
				state_machine.transition_to(EnemyStateMachine.State.STUNNED, effect.stun_duration)
			if sprite:
				sprite.modulate = effect.effect_color

		TraitEffect.EffectType.KNOCKBACK:
			if enemy and enemy.has_method("apply_knockback"):
				enemy.apply_knockback(effect.knockback_distance)

		TraitEffect.EffectType.ROOT:
			if state_machine:
				state_machine.transition_to(EnemyStateMachine.State.STUNNED, effect.duration)

		TraitEffect.EffectType.FEAR:
			if state_machine:
				state_machine.transition_to(EnemyStateMachine.State.FEARED, effect.duration)

		TraitEffect.EffectType.INSTAKILL:
			if randf() < effect.instakill_chance:
				if enemy and enemy.has_method("instant_kill"):
					enemy.instant_kill()


## Process all active status effects each frame.
func _process_effects(delta: float) -> void:
	var effects_to_remove: Array[String] = []

	for effect_key in active_effects.keys():
		var data = active_effects[effect_key]
		var effect: TraitEffect = data["effect"]

		# Update timer
		data["remaining_time"] -= delta

		# Process DoT effects
		match effect.effect_type:
			TraitEffect.EffectType.BURN, TraitEffect.EffectType.POISON:
				_effect_tick_timers[effect_key] += delta
				if _effect_tick_timers[effect_key] >= effect.tick_interval:
					_effect_tick_timers[effect_key] = 0.0
					var dot_damage = effect.damage_per_tick * data["stacks"]
					dot_tick.emit(effect_key, dot_damage)

			TraitEffect.EffectType.ARMOR_SHRED:
				# Update stored reduction value
				data["reduction"] = effect.armor_reduction_percent * data["stacks"]

		# Check if effect expired
		if data["remaining_time"] <= 0:
			effects_to_remove.append(effect_key)

	# Remove expired effects
	for effect_key in effects_to_remove:
		remove_effect(effect_key)


## Recalculate the speed modifier from all active effects.
func _recalculate_speed_modifier() -> void:
	var speed_mod: float = 1.0
	var is_stunned = state_machine and state_machine.current_state == EnemyStateMachine.State.STUNNED

	for data in active_effects.values():
		var effect: TraitEffect = data["effect"]

		match effect.effect_type:
			TraitEffect.EffectType.SLOW:
				speed_mod *= (1.0 - effect.slow_percent)

			TraitEffect.EffectType.FREEZE:
				# Only apply slow portion if not stunned
				if not is_stunned:
					speed_mod *= (1.0 - effect.slow_percent)

	_cached_speed_modifier = speed_mod
	_speed_modifier_dirty = false


## Get a list of all active effect names.
func get_active_effect_names() -> Array[String]:
	var names: Array[String] = []
	for key in active_effects.keys():
		names.append(key)
	return names


## Get visual indicator color for the strongest active effect.
## Returns the effect color for visual feedback.
func get_dominant_effect_color() -> Color:
	if active_effects.is_empty():
		return Color.WHITE

	# Priority order for visual display
	var priority_types = [
		TraitEffect.EffectType.FREEZE,
		TraitEffect.EffectType.FEAR,
		TraitEffect.EffectType.ROOT,
		TraitEffect.EffectType.BURN,
		TraitEffect.EffectType.POISON,
		TraitEffect.EffectType.SLOW,
		TraitEffect.EffectType.ARMOR_SHRED
	]

	for effect_type in priority_types:
		for data in active_effects.values():
			var effect: TraitEffect = data["effect"]
			if effect.effect_type == effect_type:
				return effect.effect_color

	return Color.WHITE


func _exit_tree() -> void:
	# Clear collections
	active_effects.clear()
	_effect_tick_timers.clear()

	# Null references
	enemy = null
	state_machine = null
	sprite = null
