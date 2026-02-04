class_name TowerUIComponent
extends Node
## Handles all UI-related logic for DigimonTower.
## Includes label updates, DP indicator, and stats display formatting.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const AttackTypes = preload("res://scripts/combat/attack_types.gd")

## Reference to parent tower
var tower: Node  # DigimonTower - avoid circular dependency

## Node references (set during setup)
var level_label: Label
var dp_indicator: ProgressBar


func _init() -> void:
	name = "UIComponent"


## Initialize the UI component with tower references
func setup(parent_tower: Node) -> void:  # DigimonTower - avoid circular dependency
	tower = parent_tower
	level_label = tower.level_label
	dp_indicator = tower.dp_indicator


## Update the level display label
func update_level_display() -> void:
	if level_label and tower.progression:
		level_label.text = "Lv %d" % tower.progression.current_level


## Update DP progress indicator
func update_dp_indicator() -> void:
	if dp_indicator and tower.progression:
		dp_indicator.value = tower.progression.current_dp
		dp_indicator.visible = tower.progression.current_dp > 0


## Update all UI elements
func update_all() -> void:
	update_level_display()
	update_dp_indicator()


## Get stats formatted for UI display
func get_stats_display() -> String:
	if not tower.digimon_data or not tower.progression:
		return ""

	var lines: Array[String] = []
	lines.append(tower.digimon_data.digimon_name)
	lines.append("%s | %s" % [tower.digimon_data.get_stage_name(), tower.digimon_data.get_attribute_name()])
	lines.append("Lv %d/%d | DP %d" % [tower.progression.current_level, tower.get_max_level(), tower.progression.current_dp])
	lines.append("Origin: %s" % tower.progression.get_origin_name())

	if tower.is_at_origin_cap():
		lines.append("(At Origin Cap)")
	elif tower.can_digivolve():
		lines.append("Ready to Digivolve!")

	if tower.digimon_data.can_attack():
		lines.append("DMG: %d | SPD: %.1f | RNG: %.1f" % [
			tower.digimon_data.base_damage,
			tower.digimon_data.attack_speed,
			tower.digimon_data.attack_range
		])
		lines.append("Target: %s" % tower.get_targeting_priority_name())
		lines.append("Attack: %s" % AttackTypes.type_to_string(
			AttackTypes.get_family_attack_type(tower.digimon_data.family)
		))

	return "\n".join(lines)


func _exit_tree() -> void:
	# Null references
	tower = null
	level_label = null
	dp_indicator = null
