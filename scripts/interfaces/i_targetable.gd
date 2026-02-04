class_name ITargetable
extends RefCounted
## Interface for entities that can be targeted by towers.
##
## Implement this interface in any entity that can be selected as a target
## by towers or other targeting systems.
##
## GDScript does not have formal interfaces, so this serves as a contract
## and documentation. Implementing classes should match these method signatures.
##
## Usage:
##   # Check if an object implements ITargetable
##   if entity.has_method("is_valid_target") and entity.is_valid_target():
##       var priority = entity.get_priority_value()
##       var pos = entity.get_position()
##
## Implementing Classes:
##   - EnemyDigimon
##   - Any future targetable entities


## Get the world position of this entity.
## Used for distance calculations, projectile targeting, and line-of-sight checks.
## [returns]: The global position as a Vector2.
func get_position() -> Vector2:
	ErrorHandler.log_error("ITargetable", "get_position() must be implemented by subclass")
	return Vector2.ZERO


## Get the priority value for targeting decisions.
## Higher values indicate higher priority for targeting.
## Common priority factors:
##   - Path progress (closer to end = higher priority)
##   - Threat level (bosses = higher priority)
##   - HP remaining (low HP = easier to kill)
## [returns]: Priority value as a float.
func get_priority_value() -> float:
	ErrorHandler.log_error("ITargetable", "get_priority_value() must be implemented by subclass")
	return 0.0


## Check if this entity is a valid target.
## An entity is a valid target if:
##   - It is alive (not dead or dying)
##   - It is visible and in play
##   - It is not in an untargetable state (e.g., invulnerable, phased out)
## [returns]: True if valid target, false otherwise.
func is_valid_target() -> bool:
	ErrorHandler.log_error("ITargetable", "is_valid_target() must be implemented by subclass")
	return false
