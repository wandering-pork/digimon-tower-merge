extends GutTest
## Unit tests for GameConfig autoload.
##
## Tests all calculation methods and constant validation in GameConfig.
## Verifies that game balance constants and helper methods work correctly.

# =============================================================================
# PRELOADS
# =============================================================================

# Use preload to ensure tests work even without autoload context
const GameConfigScript = preload("res://scripts/autoload/game_config.gd")

# =============================================================================
# SETUP AND TEARDOWN
# =============================================================================

func before_all() -> void:
	gut.p("Starting GameConfig unit tests")


func after_all() -> void:
	gut.p("Completed GameConfig unit tests")


# =============================================================================
# SPAWN COST TESTS
# =============================================================================

func test_get_spawn_cost_in_training_random() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_IN_TRAINING, "random")
	assert_eq(cost, 100, "In-Training random spawn should cost 100 DB")


func test_get_spawn_cost_in_training_specific() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_IN_TRAINING, "specific")
	assert_eq(cost, 150, "In-Training specific spawn should cost 150 DB")


func test_get_spawn_cost_in_training_free() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_IN_TRAINING, "free")
	assert_eq(cost, 200, "In-Training FREE spawn should cost 200 DB (2x random)")


func test_get_spawn_cost_rookie_random() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_ROOKIE, "random")
	assert_eq(cost, 300, "Rookie random spawn should cost 300 DB")


func test_get_spawn_cost_rookie_specific() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_ROOKIE, "specific")
	assert_eq(cost, 450, "Rookie specific spawn should cost 450 DB (1.5x random)")


func test_get_spawn_cost_rookie_free() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_ROOKIE, "free")
	assert_eq(cost, 600, "Rookie FREE spawn should cost 600 DB (2x random)")


func test_get_spawn_cost_champion_random() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_CHAMPION, "random")
	assert_eq(cost, 800, "Champion random spawn should cost 800 DB")


func test_get_spawn_cost_invalid_stage() -> void:
	var cost = GameConfigScript.get_spawn_cost(-1, "random")
	assert_eq(cost, -1, "Invalid stage should return -1")


func test_get_spawn_cost_invalid_spawn_type() -> void:
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_ROOKIE, "invalid_type")
	assert_eq(cost, -1, "Invalid spawn type should return -1")


func test_get_spawn_cost_ultra_not_spawnable() -> void:
	# Ultra stage (5) should not have spawn costs defined
	var cost = GameConfigScript.get_spawn_cost(GameConfigScript.STAGE_ULTRA, "random")
	assert_eq(cost, -1, "Ultra stage should not be directly spawnable")


# =============================================================================
# LEVEL UP COST TESTS
# =============================================================================

func test_get_level_up_cost_level_1() -> void:
	var cost = GameConfigScript.get_level_up_cost(1)
	assert_eq(cost, 5, "Level 1->2 should cost 5 DB (5 * 1)")


func test_get_level_up_cost_level_10() -> void:
	var cost = GameConfigScript.get_level_up_cost(10)
	assert_eq(cost, 50, "Level 10->11 should cost 50 DB (5 * 10)")


func test_get_level_up_cost_level_20() -> void:
	var cost = GameConfigScript.get_level_up_cost(20)
	assert_eq(cost, 100, "Level 20->21 should cost 100 DB (5 * 20)")


func test_get_level_up_cost_level_35() -> void:
	var cost = GameConfigScript.get_level_up_cost(35)
	assert_eq(cost, 175, "Level 35->36 should cost 175 DB (5 * 35)")


func test_get_level_up_cost_formula() -> void:
	# Test that the formula is correct: cost = LEVEL_UP_COST_MULTIPLIER * level
	for level in [1, 5, 15, 25, 50, 70, 100]:
		var expected = GameConfigScript.LEVEL_UP_COST_MULTIPLIER * level
		var actual = GameConfigScript.get_level_up_cost(level)
		assert_eq(actual, expected, "Level up cost for level %d should match formula" % level)


# =============================================================================
# DIGIVOLVE COST TESTS
# =============================================================================

func test_get_digivolve_cost_in_training() -> void:
	var cost = GameConfigScript.get_digivolve_cost(GameConfigScript.STAGE_IN_TRAINING)
	assert_eq(cost, 100, "In-Training to Rookie digivolve should cost 100 DB")


func test_get_digivolve_cost_rookie() -> void:
	var cost = GameConfigScript.get_digivolve_cost(GameConfigScript.STAGE_ROOKIE)
	assert_eq(cost, 150, "Rookie to Champion digivolve should cost 150 DB")


func test_get_digivolve_cost_champion() -> void:
	var cost = GameConfigScript.get_digivolve_cost(GameConfigScript.STAGE_CHAMPION)
	assert_eq(cost, 200, "Champion to Ultimate digivolve should cost 200 DB")


func test_get_digivolve_cost_ultimate() -> void:
	var cost = GameConfigScript.get_digivolve_cost(GameConfigScript.STAGE_ULTIMATE)
	assert_eq(cost, 250, "Ultimate to Mega digivolve should cost 250 DB")


func test_get_digivolve_cost_mega_returns_zero() -> void:
	# Mega has no digivolve cost (only DNA which is special)
	var cost = GameConfigScript.get_digivolve_cost(GameConfigScript.STAGE_MEGA)
	assert_eq(cost, 0, "Mega stage should return 0 (no normal digivolve)")


func test_get_digivolve_cost_invalid_stage() -> void:
	var cost = GameConfigScript.get_digivolve_cost(-1)
	assert_eq(cost, 0, "Invalid stage should return 0")


# =============================================================================
# BASE MAX LEVEL TESTS
# =============================================================================

func test_get_base_max_level_all_stages() -> void:
	var expected_levels = [10, 20, 35, 50, 70, 100]
	for stage in range(6):
		var actual = GameConfigScript.get_base_max_level(stage)
		assert_eq(actual, expected_levels[stage],
			"Stage %d base max level should be %d" % [stage, expected_levels[stage]])


func test_get_base_max_level_invalid_returns_1() -> void:
	assert_eq(GameConfigScript.get_base_max_level(-1), 1, "Invalid stage should return 1")
	assert_eq(GameConfigScript.get_base_max_level(100), 1, "Out of range stage should return 1")


# =============================================================================
# CALCULATE MAX LEVEL TESTS
# =============================================================================

func test_calculate_max_level_no_bonuses() -> void:
	# Rookie at stage 1, 0 DP, spawned as Rookie (origin 1)
	var max_level = GameConfigScript.calculate_max_level(1, 0, 1)
	assert_eq(max_level, 20, "Rookie with no bonuses should have max level 20")


func test_calculate_max_level_with_dp() -> void:
	# Rookie at stage 1, 3 DP, spawned as Rookie (origin 1)
	# Base: 20, DP bonus: 3 * 2 = 6, Origin: 0
	var max_level = GameConfigScript.calculate_max_level(1, 3, 1)
	assert_eq(max_level, 26, "Rookie with 3 DP should have max level 26")


func test_calculate_max_level_with_origin_bonus() -> void:
	# Champion at stage 2, 0 DP, raised from In-Training (origin 0)
	# Base: 35, DP bonus: 0, Origin: (2-0) * 5 = 10
	var max_level = GameConfigScript.calculate_max_level(2, 0, 0)
	assert_eq(max_level, 45, "Champion raised from In-Training should have +10 origin bonus")


func test_calculate_max_level_full_bonuses() -> void:
	# Champion at stage 2, 5 DP, raised from In-Training (origin 0)
	# Base: 35, DP bonus: 5 * 3 = 15, Origin: (2-0) * 5 = 10
	var max_level = GameConfigScript.calculate_max_level(2, 5, 0)
	assert_eq(max_level, 60, "Champion with 5 DP and In-Training origin should be 35+15+10=60")


func test_calculate_max_level_mega_high_dp() -> void:
	# Mega at stage 4, 10 DP, raised from Rookie (origin 1)
	# Base: 70, DP bonus: 10 * 5 = 50, Origin: (4-1) * 5 = 15
	var max_level = GameConfigScript.calculate_max_level(4, 10, 1)
	assert_eq(max_level, 135, "Mega with 10 DP and Rookie origin should be 70+50+15=135")


# =============================================================================
# ORIGIN CAP TESTS
# =============================================================================

func test_get_max_reachable_stage_in_training_origin() -> void:
	var max_stage = GameConfigScript.get_max_reachable_stage(GameConfigScript.STAGE_IN_TRAINING)
	assert_eq(max_stage, GameConfigScript.STAGE_CHAMPION,
		"In-Training origin caps at Champion")


func test_get_max_reachable_stage_rookie_origin() -> void:
	var max_stage = GameConfigScript.get_max_reachable_stage(GameConfigScript.STAGE_ROOKIE)
	assert_eq(max_stage, GameConfigScript.STAGE_ULTIMATE,
		"Rookie origin caps at Ultimate")


func test_get_max_reachable_stage_champion_origin() -> void:
	var max_stage = GameConfigScript.get_max_reachable_stage(GameConfigScript.STAGE_CHAMPION)
	assert_eq(max_stage, GameConfigScript.STAGE_MEGA,
		"Champion origin caps at Mega")


# =============================================================================
# STAGE NAME TESTS
# =============================================================================

func test_get_stage_name_all_valid() -> void:
	var expected_names = ["In-Training", "Rookie", "Champion", "Ultimate", "Mega", "Ultra"]
	for stage in range(6):
		var actual = GameConfigScript.get_stage_name(stage)
		assert_eq(actual, expected_names[stage],
			"Stage %d name should be %s" % [stage, expected_names[stage]])


func test_get_stage_name_invalid() -> void:
	assert_eq(GameConfigScript.get_stage_name(-1), "Unknown", "Invalid stage should return 'Unknown'")
	assert_eq(GameConfigScript.get_stage_name(100), "Unknown", "Out of range stage should return 'Unknown'")


# =============================================================================
# WAVE REWARD TESTS
# =============================================================================

func test_get_wave_reward_values_early_waves() -> void:
	var rewards = GameConfigScript.get_wave_reward_values(5)
	assert_eq(rewards["base"], 50, "Waves 1-10 base reward should be 50")
	assert_eq(rewards["per_kill"], 5, "Waves 1-10 per kill reward should be 5")


func test_get_wave_reward_values_mid_waves() -> void:
	var rewards = GameConfigScript.get_wave_reward_values(25)
	assert_eq(rewards["base"], 100, "Waves 21-30 base reward should be 100")
	assert_eq(rewards["per_kill"], 12, "Waves 21-30 per kill reward should be 12")


func test_get_wave_reward_values_late_waves() -> void:
	var rewards = GameConfigScript.get_wave_reward_values(45)
	assert_eq(rewards["base"], 150, "Waves 41-50 base reward should be 150")
	assert_eq(rewards["per_kill"], 18, "Waves 41-50 per kill reward should be 18")


func test_get_wave_reward_values_beyond_50() -> void:
	var rewards = GameConfigScript.get_wave_reward_values(75)
	assert_eq(rewards["base"], 200, "Waves beyond 50 use tier 50 values")
	assert_eq(rewards["per_kill"], 25, "Waves beyond 50 use tier 50 per_kill")


func test_calculate_wave_reward() -> void:
	# Wave 10, 15 kills: base 50 + 15 * 5 = 125
	var reward = GameConfigScript.calculate_wave_reward(10, 15)
	assert_eq(reward, 125, "Wave 10 with 15 kills should give 125 DB")


func test_calculate_wave_reward_zero_kills() -> void:
	var reward = GameConfigScript.calculate_wave_reward(10, 0)
	assert_eq(reward, 50, "Wave 10 with 0 kills should give base 50 DB")


# =============================================================================
# TIMING TESTS
# =============================================================================

func test_get_intermission_time_early() -> void:
	var time = GameConfigScript.get_intermission_time(5)
	assert_eq(time, 20.0, "Waves 1-10 intermission should be 20s")


func test_get_intermission_time_late() -> void:
	var time = GameConfigScript.get_intermission_time(90)
	assert_eq(time, 8.0, "Waves 81-100 intermission should be 8s")


func test_get_intermission_time_endless() -> void:
	var time = GameConfigScript.get_intermission_time(150)
	assert_eq(time, 6.0, "Endless mode intermission should be 6s")


func test_get_spawn_interval_early() -> void:
	var interval = GameConfigScript.get_spawn_interval(5)
	assert_eq(interval, 2.0, "Waves 1-10 spawn interval should be 2.0s")


func test_get_spawn_interval_late() -> void:
	var interval = GameConfigScript.get_spawn_interval(90)
	assert_eq(interval, 0.8, "Waves 81-100 spawn interval should be 0.8s")


func test_get_spawn_interval_endless_min() -> void:
	# At very high waves, interval should not go below MIN_SPAWN_INTERVAL
	var interval = GameConfigScript.get_spawn_interval(200)
	assert_true(interval >= GameConfigScript.MIN_SPAWN_INTERVAL,
		"Spawn interval should not go below minimum")


# =============================================================================
# GRID CONVERSION TESTS
# =============================================================================

func test_grid_to_world() -> void:
	var world_pos = GameConfigScript.grid_to_world(Vector2i(0, 0))
	# Center of tile 0,0 with TILE_SIZE 64: (32, 32)
	assert_eq(world_pos, Vector2(32, 32), "Grid (0,0) should convert to world (32,32)")


func test_grid_to_world_offset() -> void:
	var world_pos = GameConfigScript.grid_to_world(Vector2i(2, 3))
	# Center: (2*64+32, 3*64+32) = (160, 224)
	assert_eq(world_pos, Vector2(160, 224), "Grid (2,3) should convert to world (160,224)")


func test_world_to_grid() -> void:
	var grid_pos = GameConfigScript.world_to_grid(Vector2(100, 150))
	# 100/64 = 1, 150/64 = 2
	assert_eq(grid_pos, Vector2i(1, 2), "World (100,150) should convert to grid (1,2)")


func test_world_to_grid_exact() -> void:
	var grid_pos = GameConfigScript.world_to_grid(Vector2(64, 128))
	assert_eq(grid_pos, Vector2i(1, 2), "World (64,128) should convert to grid (1,2)")


func test_get_grid_pixel_size() -> void:
	var size = GameConfigScript.get_grid_pixel_size()
	# 8 cols * 64 = 512, 18 rows * 64 = 1152
	assert_eq(size, Vector2(512, 1152), "Grid pixel size should be 512x1152")


# =============================================================================
# CONSTANT VALIDATION TESTS
# =============================================================================

func test_starting_resources() -> void:
	assert_eq(GameConfigScript.STARTING_DIGIBYTES, 200, "Starting DigiBytes should be 200")
	assert_eq(GameConfigScript.STARTING_LIVES, 20, "Starting lives should be 20")


func test_life_penalties() -> void:
	assert_eq(GameConfigScript.NORMAL_LIFE_PENALTY, 1, "Normal enemy penalty should be 1 life")
	assert_eq(GameConfigScript.BOSS_LIFE_PENALTY, 3, "Boss penalty should be 3 lives")


func test_combat_constants() -> void:
	assert_eq(GameConfigScript.CRITICAL_DAMAGE_MULT, 2.0, "Critical damage multiplier should be 2.0")
	assert_eq(GameConfigScript.BASE_CRITICAL_CHANCE, 0.05, "Base crit chance should be 5%")
	assert_eq(GameConfigScript.ATTRIBUTE_SUPER_EFFECTIVE, 1.5, "Super effective multiplier should be 1.5")


func test_grid_constants() -> void:
	assert_eq(GameConfigScript.GRID_COLS, 8, "Grid columns should be 8")
	assert_eq(GameConfigScript.GRID_ROWS, 18, "Grid rows should be 18")
	assert_eq(GameConfigScript.TILE_SIZE, 64, "Tile size should be 64")
	assert_eq(GameConfigScript.TOTAL_TOWER_SLOTS, 87, "Total tower slots should be 87")
	assert_eq(GameConfigScript.TOTAL_PATH_TILES, 57, "Total path tiles should be 57")
