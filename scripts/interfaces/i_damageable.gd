class_name IDamageable
extends RefCounted
## Interface for entities that can take damage.
##
## Implement this interface in any entity that has health and can be damaged,
## such as enemy Digimon or destructible objects.
##
## GDScript does not have formal interfaces, so this serves as a contract
## and documentation. Implementing classes should match these method signatures.
##
## Usage:
##   # Check if an object implements IDamageable
##   if target.has_method("take_damage"):
##       target.take_damage(50.0, "fire")
##       if target.is_alive():
##           print("Target still alive with ", target.get_hp(), " HP")
##
## Implementing Classes:
##   - EnemyDigimon (via EnemyCombatComponent)
##   - Any future damageable entities


## Apply damage to this entity.
## [param amount]: The amount of damage to apply (before reductions).
## [param damage_type]: The type of damage ("physical", "fire", "water", "holy", "dark", etc.).
func take_damage(amount: float, damage_type: String) -> void:
	ErrorHandler.log_error("IDamageable", "take_damage() must be implemented by subclass")


## Get the current HP of this entity.
## [returns]: Current HP as a float.
func get_hp() -> float:
	ErrorHandler.log_error("IDamageable", "get_hp() must be implemented by subclass")
	return 0.0


## Get the maximum HP of this entity.
## [returns]: Maximum HP as a float.
func get_max_hp() -> float:
	ErrorHandler.log_error("IDamageable", "get_max_hp() must be implemented by subclass")
	return 0.0


## Check if this entity is still alive.
## An entity is considered alive if current HP > 0 and not in a dead state.
## [returns]: True if alive, false if dead or dying.
func is_alive() -> bool:
	ErrorHandler.log_error("IDamageable", "is_alive() must be implemented by subclass")
	return false
