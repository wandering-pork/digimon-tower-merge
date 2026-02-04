class_name IEffectReceiver
extends RefCounted
## Interface for entities that can receive status effects.
##
## Implement this interface in any entity that can have status effects applied,
## such as slow, burn, poison, freeze, fear, etc.
##
## GDScript does not have formal interfaces, so this serves as a contract
## and documentation. Implementing classes should match these method signatures.
##
## Usage:
##   # Check if an object implements IEffectReceiver
##   if target.has_method("apply_effect"):
##       target.apply_effect("Burn", 3.0, 10.0)
##       if target.has_effect("Burn"):
##           print("Target is burning!")
##
## Implementing Classes:
##   - EnemyDigimon (via EnemyEffectsComponent)
##   - Any future entities that can receive effects


## Apply a status effect to this entity.
## Effects include: Slow, Burn, Poison, Freeze, Fear, Root, Knockback, etc.
## [param effect_name]: The name of the effect (e.g., "Burn", "Slow", "Poison").
## [param duration]: How long the effect lasts in seconds.
## [param potency]: The strength of the effect (damage per tick, slow percentage, etc.).
func apply_effect(effect_name: String, duration: float, potency: float) -> void:
	ErrorHandler.log_error("IEffectReceiver", "apply_effect() must be implemented by subclass")


## Check if a specific effect is currently active on this entity.
## [param effect_name]: The name of the effect to check.
## [returns]: True if the effect is active, false otherwise.
func has_effect(effect_name: String) -> bool:
	ErrorHandler.log_error("IEffectReceiver", "has_effect() must be implemented by subclass")
	return false


## Remove all active status effects from this entity.
## Typically called on death, cleanse abilities, or state transitions.
func clear_effects() -> void:
	ErrorHandler.log_error("IEffectReceiver", "clear_effects() must be implemented by subclass")


## Get a list of all currently active effects.
## Each entry contains effect data (name, remaining duration, stacks, etc.).
## [returns]: Array of active effect data. Structure depends on implementation.
##            Typically: [{ "name": String, "duration": float, "stacks": int }, ...]
func get_active_effects() -> Array:
	ErrorHandler.log_error("IEffectReceiver", "get_active_effects() must be implemented by subclass")
	return []
