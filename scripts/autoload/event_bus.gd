extends Node
## EventBus Autoload Singleton
##
## Central signal hub for loose coupling between game systems.
## All cross-system communication should go through this bus to avoid
## tight dependencies between components.

# =============================================================================
# TOWER SIGNALS
# =============================================================================

## Emitted when a new tower is spawned on the field
## tower: The tower node instance
## position: Grid position where it was placed
## stage: The evolution stage (0=In-Training, 1=Rookie, etc.)
## attribute: The attribute type (Vaccine, Data, Virus, Free)
signal tower_spawned(tower: Node, position: Vector2i, stage: int, attribute: String)

## Emitted when a tower is sold/removed from the field
## tower: The tower node being removed
## refund_amount: DigiBytes returned to player
signal tower_sold(tower: Node, refund_amount: int)

## Emitted when a tower levels up
## tower: The tower node
## new_level: The new level after leveling
## cost: How much was spent
signal tower_leveled(tower: Node, new_level: int, cost: int)

## Emitted when a tower digivolves to a new stage
## tower: The tower node
## new_stage: The new evolution stage
## new_digimon: The name/id of the new Digimon form
## dp_used: DP that determined the evolution path
signal tower_evolved(tower: Node, new_stage: int, new_digimon: String, dp_used: int)

## Emitted when two towers are merged
## survivor: The tower that absorbed the other
## sacrificed: The tower that was consumed
## new_dp: The survivor's new DP total
## new_origin: The survivor's new origin (if changed)
signal merge_completed(survivor: Node, sacrificed: Node, new_dp: int, new_origin: int)

## Emitted when a tower starts attacking
## tower: The attacking tower
## target: The enemy being attacked
signal tower_attack_started(tower: Node, target: Node)

## Emitted when a tower's attack deals damage
## tower: The attacking tower
## target: The enemy hit
## damage: Amount of damage dealt
## is_critical: Whether it was a critical hit
signal tower_attack_hit(tower: Node, target: Node, damage: float, is_critical: bool)

# =============================================================================
# ENEMY SIGNALS
# =============================================================================

## Emitted when an enemy spawns on the path
## enemy: The enemy node instance
## wave_number: Which wave this enemy belongs to
## is_boss: Whether this is a boss enemy
signal enemy_spawned(enemy: Node, wave_number: int, is_boss: bool)

## Emitted when an enemy is killed by towers
## enemy: The enemy node
## killer: The tower that got the kill (can be null for DoT)
## reward: DigiBytes earned from the kill
signal enemy_killed(enemy: Node, killer: Node, reward: int)

## Emitted when an enemy reaches the end of the path
## enemy: The enemy node
## is_boss: Whether this was a boss (affects life penalty)
signal enemy_escaped(enemy: Node, is_boss: bool)

## Emitted when an enemy takes damage
## enemy: The enemy node
## damage: Amount of damage taken
## source: The damage source (tower, effect, etc.)
## damage_type: Type of damage (physical, fire, ice, etc.)
signal enemy_damaged(enemy: Node, damage: float, source: Node, damage_type: String)

## Emitted when a status effect is applied to an enemy
## enemy: The affected enemy
## effect_name: Name of the effect (burn, freeze, slow, etc.)
## duration: How long the effect lasts
## source: What applied the effect
signal enemy_effect_applied(enemy: Node, effect_name: String, duration: float, source: Node)

# =============================================================================
# WAVE SIGNALS
# =============================================================================

## Emitted when a new wave starts
## wave_number: The wave number starting
## enemy_count: Total enemies in this wave
signal wave_started(wave_number: int, enemy_count: int)

## Emitted when all enemies in a wave are cleared
## wave_number: The completed wave
## reward: Bonus DigiBytes for completing the wave
signal wave_completed(wave_number: int, reward: int)

## Emitted when a boss enemy spawns (subset of enemy_spawned for special handling)
## boss: The boss enemy node
## wave_number: The wave this boss belongs to
## boss_name: Display name of the boss
signal boss_spawned(boss: Node, wave_number: int, boss_name: String)

## Emitted between waves during preparation phase
## next_wave: The upcoming wave number
## time_remaining: Seconds until wave starts
signal wave_intermission(next_wave: int, time_remaining: float)

# =============================================================================
# UI SIGNALS
# =============================================================================

## Emitted when the spawn menu is opened
## available_spawns: Dictionary of spawnable Digimon and their costs
signal ui_spawn_menu_opened(available_spawns: Dictionary)

## Emitted when the spawn menu is closed
signal ui_spawn_menu_closed()

## Emitted when the evolution menu is opened for a tower
## tower: The tower being evolved
## evolution_options: Array of available evolutions based on DP
signal ui_evolution_menu_opened(tower: Node, evolution_options: Array)

## Emitted when the evolution menu is closed
signal ui_evolution_menu_closed()

## Emitted when a tower is selected for inspection/interaction
## tower: The selected tower (null if deselected)
signal tower_selected(tower: Node)

## Emitted when a merge operation is initiated
## source_tower: The tower being dragged for merge
signal merge_initiated(source_tower: Node)

## Emitted when a merge operation is cancelled
signal merge_cancelled()

## Emitted to show floating text (damage numbers, rewards, etc.)
## position: World position to show text
## text: The text to display
## color: Text color
signal floating_text_requested(position: Vector2, text: String, color: Color)

# =============================================================================
# GAME STATE SIGNALS
# =============================================================================

## Emitted when the game is paused/unpaused
## is_paused: Whether the game is now paused
signal game_paused(is_paused: bool)

## Emitted when the player requests to start the next wave early
signal wave_start_requested()

## Emitted when a checkpoint/save point is reached
## wave_number: The wave at which checkpoint occurred
signal checkpoint_reached(wave_number: int)


# =============================================================================
# HELPER METHODS
# =============================================================================

## Convenience method to emit floating damage text
func show_damage_number(position: Vector2, damage: float, is_critical: bool = false) -> void:
	var color = Color.YELLOW if is_critical else Color.WHITE
	var text = str(int(damage))
	if is_critical:
		text = text + "!"
	floating_text_requested.emit(position, text, color)


## Convenience method to emit floating reward text
func show_reward_text(position: Vector2, amount: int) -> void:
	floating_text_requested.emit(position, "+" + str(amount) + " DB", Color.GOLD)


## Convenience method to emit floating level up text
func show_level_up_text(position: Vector2, new_level: int) -> void:
	floating_text_requested.emit(position, "Lv " + str(new_level), Color.CYAN)
