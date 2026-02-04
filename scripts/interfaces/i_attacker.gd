class_name IAttacker
extends RefCounted
## Interface for entities that can deal damage.
##
## Implement this interface in any entity that can attack or deal damage,
## such as towers (DigimonTower) or potentially enemy Digimon with abilities.
##
## GDScript does not have formal interfaces, so this serves as a contract
## and documentation. Implementing classes should match these method signatures.
##
## Usage:
##   # Check if an object implements IAttacker
##   if entity.has_method("get_base_damage"):
##       var damage = entity.get_base_damage()
##
## Implementing Classes:
##   - DigimonTower (via TowerCombatComponent)
##   - Any future damage-dealing entities


## Get the base damage value before any modifiers.
## Returns the raw damage value from the entity's stats.
## [returns]: Base damage as a float.
func get_base_damage() -> float:
	ErrorHandler.log_error("IAttacker", "get_base_damage() must be implemented by subclass")
	return 0.0


## Get the attribute type of the attacker.
## Attributes affect damage multipliers (Vaccine > Virus > Data > Vaccine).
## [returns]: Attribute string ("Vaccine", "Virus", "Data", or "Free").
func get_attribute() -> String:
	ErrorHandler.log_error("IAttacker", "get_attribute() must be implemented by subclass")
	return ""


## Get the attack speed in attacks per second.
## Higher values mean faster attack rate.
## [returns]: Attack speed as a float (attacks per second).
func get_attack_speed() -> float:
	ErrorHandler.log_error("IAttacker", "get_attack_speed() must be implemented by subclass")
	return 0.0
