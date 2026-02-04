extends GutTest
## Unit tests for EconomySystem autoload.
##
## Tests economy calculations, transaction validation, and cost lookups.
## Note: Some tests require GameManager mock since EconomySystem depends on it.

# =============================================================================
# MOCK CLASSES
# =============================================================================

## Mock tower for testing economy functions
class MockTower extends Node:
	var current_level: int = 1
	var total_investment: int = 0
	var digimon_data: MockDigimonData = null
	var _can_level_up: bool = true
	var _can_digivolve: bool = true
	var _max_level: int = 20

	func can_level_up() -> bool:
		return _can_level_up and current_level < _max_level

	func can_digivolve() -> bool:
		return _can_digivolve

	func do_level_up() -> void:
		current_level += 1

	func get_max_level() -> int:
		return _max_level


## Mock DigimonData for testing
class MockDigimonData:
	var digimon_name: String = "TestMon"
	var stage: int = 0


# =============================================================================
# TEST VARIABLES
# =============================================================================

var _economy_system: Node = null


# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

func before_all() -> void:
	gut.p("Starting EconomySystem unit tests")


func after_all() -> void:
	gut.p("Completed EconomySystem unit tests")


func before_each() -> void:
	# Get reference to the autoloaded EconomySystem
	_economy_system = get_node_or_null("/root/EconomySystem")


func after_each() -> void:
	_economy_system = null


# =============================================================================
# SPAWN COST TESTS (DELEGATED TO GAMECONFIG)
# =============================================================================

func test_get_spawn_cost_delegates_to_game_config() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# These should match GameConfig values
	var cost = _economy_system.get_spawn_cost(GameConfig.STAGE_ROOKIE, "random")
	assert_eq(cost, 300, "Spawn cost should delegate to GameConfig")


func test_get_spawn_cost_in_training() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var random_cost = _economy_system.get_spawn_cost(0, "random")
	var specific_cost = _economy_system.get_spawn_cost(0, "specific")
	var free_cost = _economy_system.get_spawn_cost(0, "free")

	assert_eq(random_cost, 100, "In-Training random should cost 100 DB")
	assert_eq(specific_cost, 150, "In-Training specific should cost 150 DB")
	assert_eq(free_cost, 200, "In-Training FREE should cost 200 DB")


func test_get_spawn_cost_rookie() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var random_cost = _economy_system.get_spawn_cost(1, "random")
	var specific_cost = _economy_system.get_spawn_cost(1, "specific")
	var free_cost = _economy_system.get_spawn_cost(1, "free")

	assert_eq(random_cost, 300, "Rookie random should cost 300 DB")
	assert_eq(specific_cost, 450, "Rookie specific should cost 450 DB")
	assert_eq(free_cost, 600, "Rookie FREE should cost 600 DB")


func test_get_spawn_cost_champion() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var random_cost = _economy_system.get_spawn_cost(2, "random")
	var specific_cost = _economy_system.get_spawn_cost(2, "specific")
	var free_cost = _economy_system.get_spawn_cost(2, "free")

	assert_eq(random_cost, 800, "Champion random should cost 800 DB")
	assert_eq(specific_cost, 1200, "Champion specific should cost 1200 DB")
	assert_eq(free_cost, 1600, "Champion FREE should cost 1600 DB")


func test_get_spawn_cost_invalid_returns_negative() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var invalid_stage = _economy_system.get_spawn_cost(-1, "random")
	var invalid_type = _economy_system.get_spawn_cost(0, "invalid")

	assert_eq(invalid_stage, -1, "Invalid stage should return -1")
	assert_eq(invalid_type, -1, "Invalid spawn type should return -1")


# =============================================================================
# LEVEL UP COST TESTS
# =============================================================================

func test_get_level_up_cost() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Formula: 5 * current_level
	assert_eq(_economy_system.get_level_up_cost(1), 5, "Level 1->2 costs 5 DB")
	assert_eq(_economy_system.get_level_up_cost(10), 50, "Level 10->11 costs 50 DB")
	assert_eq(_economy_system.get_level_up_cost(20), 100, "Level 20->21 costs 100 DB")
	assert_eq(_economy_system.get_level_up_cost(50), 250, "Level 50->51 costs 250 DB")


func test_get_level_up_cost_cumulative() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Calculate total cost to level from 1 to 10
	var total = 0
	for level in range(1, 10):
		total += _economy_system.get_level_up_cost(level)

	# Sum of 5*1 + 5*2 + ... + 5*9 = 5 * (1+2+...+9) = 5 * 45 = 225
	assert_eq(total, 225, "Total cost 1->10 should be 225 DB")


# =============================================================================
# DIGIVOLVE COST TESTS
# =============================================================================

func test_get_digivolve_cost() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	assert_eq(_economy_system.get_digivolve_cost(0), 100, "In-Training->Rookie costs 100 DB")
	assert_eq(_economy_system.get_digivolve_cost(1), 150, "Rookie->Champion costs 150 DB")
	assert_eq(_economy_system.get_digivolve_cost(2), 200, "Champion->Ultimate costs 200 DB")
	assert_eq(_economy_system.get_digivolve_cost(3), 250, "Ultimate->Mega costs 250 DB")


func test_get_digivolve_cost_mega_is_zero() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Mega (4) doesn't have a standard digivolve cost
	assert_eq(_economy_system.get_digivolve_cost(4), 0, "Mega digivolve cost should be 0")


# =============================================================================
# SELL VALUE TESTS
# =============================================================================

func test_get_sell_value_50_percent() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.total_investment = 200

	var value = _economy_system.get_sell_value(tower)
	assert_eq(value, 100, "Sell value should be 50% of investment")

	tower.queue_free()


func test_get_sell_value_zero_investment() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.total_investment = 0

	var value = _economy_system.get_sell_value(tower)
	assert_eq(value, 0, "Sell value of 0 investment should be 0")

	tower.queue_free()


func test_get_sell_value_null_tower() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var value = _economy_system.get_sell_value(null)
	assert_eq(value, 0, "Sell value of null tower should be 0")


func test_get_sell_value_large_investment() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.total_investment = 5000

	var value = _economy_system.get_sell_value(tower)
	assert_eq(value, 2500, "Sell value should be 2500 for 5000 investment")

	tower.queue_free()


# =============================================================================
# COST TO MAX LEVEL TESTS
# =============================================================================

func test_get_cost_to_max_level() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.current_level = 1
	tower._max_level = 10

	var cost = _economy_system.get_cost_to_max_level(tower)
	# Sum of 5*1 + 5*2 + ... + 5*9 = 5 * 45 = 225
	assert_eq(cost, 225, "Cost to max from level 1 to 10 should be 225 DB")

	tower.queue_free()


func test_get_cost_to_max_level_partially_leveled() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.current_level = 5
	tower._max_level = 10

	var cost = _economy_system.get_cost_to_max_level(tower)
	# Sum of 5*5 + 5*6 + 5*7 + 5*8 + 5*9 = 5 * (5+6+7+8+9) = 5 * 35 = 175
	assert_eq(cost, 175, "Cost to max from level 5 to 10 should be 175 DB")

	tower.queue_free()


func test_get_cost_to_max_level_already_maxed() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var tower = MockTower.new()
	tower.current_level = 10
	tower._max_level = 10

	var cost = _economy_system.get_cost_to_max_level(tower)
	assert_eq(cost, 0, "Cost to max when already maxed should be 0")

	tower.queue_free()


func test_get_cost_to_max_level_null_tower() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var cost = _economy_system.get_cost_to_max_level(null)
	assert_eq(cost, 0, "Cost to max null tower should be 0")


# =============================================================================
# WAVE REWARD TESTS
# =============================================================================

func test_get_wave_reward_early_waves() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var reward = _economy_system.get_wave_reward(5)
	assert_eq(reward, 50, "Wave 5 base reward should be 50 DB")


func test_get_wave_reward_mid_waves() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var reward = _economy_system.get_wave_reward(25)
	assert_eq(reward, 100, "Wave 25 base reward should be 100 DB")


func test_get_wave_reward_late_waves() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var reward = _economy_system.get_wave_reward(45)
	assert_eq(reward, 150, "Wave 45 base reward should be 150 DB")


func test_get_kill_reward_early_waves() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var reward = _economy_system.get_kill_reward(5)
	assert_eq(reward, 5, "Wave 5 kill reward should be 5 DB")


func test_get_kill_reward_late_waves() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var reward = _economy_system.get_kill_reward(45)
	assert_eq(reward, 18, "Wave 45 kill reward should be 18 DB")


# =============================================================================
# FORMAT COST TESTS
# =============================================================================

func test_format_cost() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	assert_eq(_economy_system.format_cost(100), "100 DB", "Format should be '100 DB'")
	assert_eq(_economy_system.format_cost(0), "0 DB", "Format zero should be '0 DB'")
	assert_eq(_economy_system.format_cost(1500), "1500 DB", "Format should be '1500 DB'")


# =============================================================================
# SPAWN COSTS INFO TESTS
# =============================================================================

func test_get_spawn_costs_info_returns_dict() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var info = _economy_system.get_spawn_costs_info()
	assert_not_null(info, "Spawn costs info should not be null")
	assert_true(info is Dictionary, "Should return a Dictionary")


func test_get_spawn_costs_info_contains_stages() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var info = _economy_system.get_spawn_costs_info()
	assert_true(info.has("in_training"), "Should have in_training key")
	assert_true(info.has("rookie"), "Should have rookie key")
	assert_true(info.has("champion"), "Should have champion key")


func test_get_spawn_costs_info_contains_spawn_types() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	var info = _economy_system.get_spawn_costs_info()
	var rookie_costs = info.get("rookie", {})

	assert_true(rookie_costs.has("random"), "Should have random spawn type")
	assert_true(rookie_costs.has("specific"), "Should have specific spawn type")
	assert_true(rookie_costs.has("free"), "Should have free spawn type")


# =============================================================================
# SIGNAL TESTS (WITHOUT GAMEMANAGER)
# =============================================================================

func test_try_spawn_invalid_config_emits_purchase_failed() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	watch_signals(_economy_system)

	var result = _economy_system.try_spawn(-1, "random")

	assert_false(result, "Invalid spawn should return false")
	assert_signal_emitted(_economy_system, "purchase_failed")


# =============================================================================
# INTEGRATION-STYLE TESTS (PURE CALCULATION)
# =============================================================================

func test_full_level_progression_cost() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Calculate total cost to fully level a Rookie (1->20)
	var total = 0
	for level in range(1, 20):
		total += _economy_system.get_level_up_cost(level)

	# Sum of 5*1 + 5*2 + ... + 5*19 = 5 * (1+2+...+19) = 5 * 190 = 950
	assert_eq(total, 950, "Total cost to max Rookie (1->20) should be 950 DB")


func test_full_champion_progression_cost() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Calculate total cost to fully level a Champion (1->35)
	var total = 0
	for level in range(1, 35):
		total += _economy_system.get_level_up_cost(level)

	# Sum of 5*(1+2+...+34) = 5 * (34*35/2) = 5 * 595 = 2975
	assert_eq(total, 2975, "Total cost to max Champion (1->35) should be 2975 DB")


func test_spawn_cost_multiplier_ratios() -> void:
	if not _economy_system:
		pending("EconomySystem not available - test requires running game")
		return

	# Verify specific is 1.5x random and free is 2x random
	for stage in range(3):  # In-Training, Rookie, Champion
		var random_cost = _economy_system.get_spawn_cost(stage, "random")
		var specific_cost = _economy_system.get_spawn_cost(stage, "specific")
		var free_cost = _economy_system.get_spawn_cost(stage, "free")

		assert_eq(specific_cost, int(random_cost * 1.5),
			"Specific should be 1.5x random for stage %d" % stage)
		assert_eq(free_cost, random_cost * 2,
			"FREE should be 2x random for stage %d" % stage)
