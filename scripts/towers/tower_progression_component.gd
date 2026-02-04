class_name TowerProgressionComponent
extends Node
## Handles all progression-related logic for DigimonTower.
## Includes leveling, evolution, DP tracking, Origin system, and merging.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonData = preload("res://scripts/data/digimon_data.gd")
const EvolutionPath = preload("res://scripts/data/evolution_path.gd")

signal level_up(new_level: int)
signal dp_changed(new_dp: int)
signal evolved(new_data: DigimonData)
signal merged(resulting_tower: Node)  # DigimonTower - avoid circular dependency

## Reference to parent tower
var tower: Node  # DigimonTower - avoid circular dependency

## Current DP (Digivolution Points) - gained through merging
var current_dp: int = 0

## Current level (gained by paying DigiBytes)
var current_level: int = 1

## Origin stage - the stage this Digimon was spawned at
## Determines maximum reachable stage
var origin_stage: int = 0

## Total DigiBytes invested in this tower (for sell value calculation)
var total_investment: int = 0


func _init() -> void:
	name = "ProgressionComponent"


## Initialize the progression component with tower reference
func setup(parent_tower: Node) -> void:  # DigimonTower - avoid circular dependency
	tower = parent_tower


## Get max level based on stage, DP, and Origin
func get_max_level() -> int:
	if not tower.digimon_data:
		return 1
	return GameConfig.calculate_max_level(
		tower.digimon_data.stage,
		current_dp,
		origin_stage
	)


## Get the base max level for current stage (digivolve threshold)
func get_digivolve_threshold() -> int:
	if not tower.digimon_data:
		return 1
	return GameConfig.get_base_max_level(tower.digimon_data.stage)


## Check if this tower can digivolve
func can_digivolve() -> bool:
	if not tower.digimon_data:
		return false
	# Must be at base max level for current stage
	if current_level < get_digivolve_threshold():
		return false
	# Must not be at Mega (unless DNA) or Ultra
	if tower.digimon_data.stage >= GameConfig.STAGE_MEGA:
		return false
	# Must not exceed Origin cap
	if tower.digimon_data.stage >= get_max_reachable_stage():
		return false
	# Must have evolutions available
	return tower.digimon_data.evolutions.size() > 0


## Get the maximum stage this Digimon can reach based on Origin
func get_max_reachable_stage() -> int:
	return GameConfig.get_max_reachable_stage(origin_stage)


## Check if this tower has hit its Origin ceiling
func is_at_origin_cap() -> bool:
	if not tower.digimon_data:
		return false
	return tower.digimon_data.stage >= get_max_reachable_stage()


## Get the cost to digivolve from current stage
func get_digivolve_cost() -> int:
	if not tower.digimon_data or tower.digimon_data.stage >= GameConfig.STAGE_MEGA:
		return 0
	return GameConfig.get_digivolve_cost(tower.digimon_data.stage)


## Get the cost to level up from current level
func get_level_up_cost() -> int:
	return GameConfig.get_level_up_cost(current_level)


## Check if leveling up is possible (not at max)
func can_level_up() -> bool:
	return current_level < get_max_level()


## Level up (call after payment is confirmed)
func do_level_up() -> void:
	if can_level_up():
		current_level += 1
		level_up.emit(current_level)

		if EventBus:
			EventBus.show_level_up_text(tower.global_position, current_level)


## Add to total investment tracking
func add_investment(amount: int) -> void:
	total_investment += amount


## Get sell value (percentage of total investment)
func get_sell_value() -> int:
	return int(total_investment * GameConfig.SELL_VALUE_PERCENTAGE)


## Check if this tower can merge with another
func can_merge_with(other: Node) -> bool:  # DigimonTower - avoid circular dependency
	if not other or not other.digimon_data or not tower.digimon_data:
		return false
	# Must be Rookie or higher
	if tower.digimon_data.stage < GameConfig.STAGE_ROOKIE:
		return false
	if other.digimon_data.stage < GameConfig.STAGE_ROOKIE:
		return false
	# Must be same stage
	if other.digimon_data.stage != tower.digimon_data.stage:
		return false
	# Must be same attribute OR one is FREE
	var my_attr = tower.digimon_data.attribute
	var other_attr = other.digimon_data.attribute
	if my_attr == DigimonData.Attribute.FREE or other_attr == DigimonData.Attribute.FREE:
		return true
	return my_attr == other_attr


## Calculate the new DP when merging with another tower
func calculate_merge_dp(other: Node) -> int:  # DigimonTower - avoid circular dependency
	if not can_merge_with(other):
		return -1
	# Use proxy property for backwards compatibility
	return maxi(current_dp, other.current_dp) + 1


## Merge this tower with another (other is sacrificed)
## Returns the new DP, or -1 if merge failed
func merge_with(other: Node) -> int:  # DigimonTower - avoid circular dependency
	if not can_merge_with(other):
		return -1

	var new_dp = calculate_merge_dp(other)
	current_dp = new_dp

	# Take the better (lower) origin - use proxy property for backwards compatibility
	if other.origin_stage < origin_stage:
		origin_stage = other.origin_stage

	# Add other's investment to this tower - use proxy property for backwards compatibility
	total_investment += other.total_investment

	dp_changed.emit(new_dp)
	merged.emit(tower)

	return new_dp


## Get all evolution paths for this Digimon
func get_evolution_paths() -> Array[EvolutionPath]:
	var paths: Array[EvolutionPath] = []
	for evolution in tower.digimon_data.evolutions:
		if evolution is EvolutionPath:
			paths.append(evolution)
	return paths


## Get only the unlocked evolution paths for current DP
func get_available_evolutions() -> Array[EvolutionPath]:
	var available: Array[EvolutionPath] = []
	for path in get_evolution_paths():
		if path.is_available(current_dp):
			available.append(path)
	return available


## Get the default evolution path
func get_default_evolution() -> EvolutionPath:
	for evolution in tower.digimon_data.evolutions:
		if evolution is EvolutionPath and evolution.is_default:
			return evolution
	return null


## Apply evolution - transform this tower into the evolved form
func evolve_to(new_digimon_data: DigimonData) -> void:
	tower.digimon_data = new_digimon_data
	current_level = 1  # Reset level on evolution
	# DP and Origin are preserved
	evolved.emit(new_digimon_data)


## Check if this tower can DNA Digivolve with another
func can_dna_with(other: Node) -> bool:  # DigimonTower - avoid circular dependency
	if not tower.digimon_data.can_dna_digivolve():
		return false
	if not other or not other.digimon_data:
		return false
	return other.digimon_data.digimon_name == tower.digimon_data.dna_partner


## Get DNA result name if compatible
func get_dna_result(other: Node) -> String:  # DigimonTower - avoid circular dependency
	if can_dna_with(other):
		return tower.digimon_data.dna_result
	return ""


## Get origin stage name for display
func get_origin_name() -> String:
	return GameConfig.get_stage_name(origin_stage)


func _exit_tree() -> void:
	# Null references
	tower = null
