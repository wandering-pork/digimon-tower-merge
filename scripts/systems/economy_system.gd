# class_name EconomySystem  # Removed: autoloads register as globals, class_name causes conflicts
extends Node
## Central economy management system for Digimon Tower Merge.
## Handles all financial transactions: spawning, leveling, digivolving, and selling.
##
## NOTE: All economy constants are defined in GameConfig autoload.
## This system provides transaction logic and validation using those constants.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
# Autoload scripts load before regular scripts in Godot. We must preload
# non-autoload classes to ensure they're available for type hints.

const DigimonTower = preload("res://scripts/towers/digimon_tower.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")

signal purchase_failed(reason: String)
signal purchase_succeeded(item_type: String, cost: int)
signal sell_completed(tower_name: String, value: int)

## Reference to GameManager
var _game_manager: Node = null


func _ready() -> void:
	_game_manager = get_node_or_null("/root/GameManager")
	if not _game_manager:
		ErrorHandler.log_warning("EconomySystem", "GameManager not found")


## Get spawn cost for a specific stage and spawn type
## stage: 0=In-Training, 1=Rookie, 2=Champion
## spawn_type: "random", "specific", or "free"
func get_spawn_cost(stage: int, spawn_type: String) -> int:
	var cost = GameConfig.get_spawn_cost(stage, spawn_type)
	if cost < 0:
		ErrorHandler.log_error("EconomySystem", "Invalid spawn configuration (stage=%d, type=%s)" % [stage, spawn_type])
	return cost


## Get the cost to level up from current level
func get_level_up_cost(current_level: int) -> int:
	return GameConfig.get_level_up_cost(current_level)


## Get the cost to digivolve from current stage
func get_digivolve_cost(current_stage: int) -> int:
	return GameConfig.get_digivolve_cost(current_stage)


## Get the sell value for a tower (50% of total investment)
func get_sell_value(tower: Node) -> int:
	if not tower:
		return 0
	var total = tower.total_investment if tower.get("total_investment") else 0
	return int(total * GameConfig.SELL_VALUE_PERCENTAGE)


## Check if player can afford a purchase
func can_afford(cost: int) -> bool:
	if not _game_manager:
		return false
	return _game_manager.can_afford(cost)


## Try to spawn a Digimon - returns true if successful
func try_spawn(stage: int, spawn_type: String) -> bool:
	var cost = get_spawn_cost(stage, spawn_type)
	if cost < 0:
		purchase_failed.emit("Invalid spawn configuration")
		return false

	if not _game_manager:
		purchase_failed.emit("Game manager not available")
		return false

	if _game_manager.spend_digibytes(cost):
		purchase_succeeded.emit("spawn", cost)
		return true

	purchase_failed.emit("Not enough DigiBytes (need %d DB)" % cost)
	return false


## Try to level up a tower - returns true if successful
func try_level_up(tower: Node) -> bool:
	if not tower:
		purchase_failed.emit("Invalid tower")
		return false

	if not tower.can_level_up():
		purchase_failed.emit("Tower is at max level")
		return false

	var cost = get_level_up_cost(tower.current_level)

	if not _game_manager:
		purchase_failed.emit("Game manager not available")
		return false

	if _game_manager.spend_digibytes(cost):
		tower.do_level_up()
		# Track investment
		if tower.has_method("get") and tower.get("total_investment") != null:
			tower.total_investment += cost
		purchase_succeeded.emit("level_up", cost)

		if EventBus:
			EventBus.tower_leveled.emit(tower, tower.current_level, cost)

		return true

	purchase_failed.emit("Not enough DigiBytes (need %d DB)" % cost)
	return false


## Try to digivolve a tower - returns true if cost was paid
## Note: This only handles the cost, actual evolution is done by EvolutionSystem
func try_digivolve(tower: Node) -> bool:
	if not tower or not tower.digimon_data:
		purchase_failed.emit("Invalid tower")
		return false

	if not tower.can_digivolve():
		purchase_failed.emit("Tower cannot digivolve")
		return false

	var cost = get_digivolve_cost(tower.digimon_data.stage)

	if not _game_manager:
		purchase_failed.emit("Game manager not available")
		return false

	if _game_manager.can_afford(cost):
		# Don't spend yet - EvolutionSystem will handle the cost
		# This just validates affordability
		return true

	purchase_failed.emit("Not enough DigiBytes (need %d DB)" % cost)
	return false


## Sell a tower and get DigiBytes back
func sell_tower(tower: Node) -> int:
	if not tower:
		return 0

	var value = get_sell_value(tower)
	var tower_name = tower.digimon_data.digimon_name if tower.digimon_data else "Unknown"

	if _game_manager:
		_game_manager.add_digibytes(value)

	sell_completed.emit(tower_name, value)

	if EventBus:
		EventBus.tower_sold.emit(tower, value)
		EventBus.floating_text_requested.emit(
			tower.global_position,
			"+%d DB" % value,
			Color.GOLD
		)

	return value


## Get a formatted cost string for display
func format_cost(cost: int) -> String:
	return "%d DB" % cost


## Get spawn cost info as a dictionary (for UI)
func get_spawn_costs_info() -> Dictionary:
	return GameConfig.SPAWN_COSTS.duplicate(true)


## Calculate total cost to max level a tower from current level
func get_cost_to_max_level(tower: Node) -> int:
	if not tower:
		return 0

	var current = tower.current_level
	var max_level = tower.get_max_level()
	var total = 0

	for level in range(current, max_level):
		total += get_level_up_cost(level)

	return total


## Get wave completion reward based on wave number
func get_wave_reward(wave_number: int) -> int:
	var reward_values = GameConfig.get_wave_reward_values(wave_number)
	return reward_values["base"]


## Get per-kill reward based on wave number
func get_kill_reward(wave_number: int) -> int:
	var reward_values = GameConfig.get_wave_reward_values(wave_number)
	return reward_values["per_kill"]
