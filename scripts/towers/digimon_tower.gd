class_name DigimonTower
extends Area2D
## Represents a Digimon tower on the game grid.
## Coordinates all tower components: combat, progression, visual, and UI.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonData = preload("res://scripts/data/digimon_data.gd")
const EvolutionPath = preload("res://scripts/data/evolution_path.gd")
const TowerCombatComponent = preload("res://scripts/towers/tower_combat_component.gd")
const TowerProgressionComponent = preload("res://scripts/towers/tower_progression_component.gd")
const TowerVisualComponent = preload("res://scripts/towers/tower_visual_component.gd")
const TowerUIComponent = preload("res://scripts/towers/tower_ui_component.gd")
const GridManager = preload("res://scripts/systems/grid_manager.gd")
const Targeting = preload("res://scripts/combat/targeting.gd")

signal evolution_choice_requested(available_paths: Array[EvolutionPath], new_dp: int)
signal merged(resulting_tower: DigimonTower)
signal level_up(new_level: int)
signal digivolved(new_data: DigimonData)
signal enemy_killed(enemy_type: String)
signal selected(tower: DigimonTower)
signal deselected(tower: DigimonTower)

## The Digimon data resource for this tower
@export var digimon_data: DigimonData

## Scene node references
@onready var sprite: Sprite2D = $Sprite
@onready var range_indicator: Sprite2D = $RangeIndicator
@onready var range_area: Area2D = $RangeArea
@onready var range_shape: CollisionShape2D = $RangeArea/RangeShape
@onready var level_label: Label = $LevelLabel
@onready var dp_indicator: ProgressBar = $DPIndicator
@onready var effect_spawn: Node2D = $EffectSpawn
@onready var attack_timer: Timer = $AttackTimer
@onready var flash_timer: Timer = $FlashTimer

## Component references (using Node type to avoid circular dependency issues)
var combat: Node  # TowerCombatComponent
var progression: Node  # TowerProgressionComponent
var visual: Node  # TowerVisualComponent
var ui: Node  # TowerUIComponent

## Grid position (set by grid manager)
var grid_position: Vector2i = Vector2i.ZERO

## Selection state
var _is_selected: bool = false

## Reference to adjacent towers (updated by grid manager)
var _adjacent_towers: Array = []  # Array[DigimonTower]

## Reference to managers (set by spawn system)
var _grid_manager: Node = null  # GridManager

## Proxy properties for backwards compatibility
var current_dp: int:
	get: return progression.current_dp if progression else 0
	set(value):
		if progression:
			progression.current_dp = value

var current_level: int:
	get: return progression.current_level if progression else 1
	set(value):
		if progression:
			progression.current_level = value

var origin_stage: int:
	get: return progression.origin_stage if progression else 0
	set(value):
		if progression:
			progression.origin_stage = value

var total_investment: int:
	get: return progression.total_investment if progression else 0
	set(value):
		if progression:
			progression.total_investment = value

var targeting_priority: Targeting.Priority:
	get: return combat.targeting_priority if combat else Targeting.Priority.FIRST
	set(value):
		if combat:
			combat.targeting_priority = value


func _ready() -> void:
	# Create and setup components
	_setup_components()

	# Connect signals
	input_event.connect(_on_input_event)

	if digimon_data:
		_initialize_from_data()

	# Connect to EventBus
	if EventBus:
		EventBus.tower_selected.connect(_on_tower_selected)


func _setup_components() -> void:
	# Create combat component
	combat = TowerCombatComponent.new()
	add_child(combat)
	combat.setup(self)

	# Create progression component
	progression = TowerProgressionComponent.new()
	add_child(progression)
	progression.setup(self)

	# Create visual component
	visual = TowerVisualComponent.new()
	add_child(visual)
	visual.setup(self)

	# Create UI component
	ui = TowerUIComponent.new()
	add_child(ui)
	ui.setup(self)

	# Connect component signals to tower signals
	progression.level_up.connect(_on_progression_level_up)
	progression.evolved.connect(_on_progression_evolved)
	progression.merged.connect(_on_progression_merged)
	progression.dp_changed.connect(_on_dp_changed)


func _on_progression_level_up(new_level: int) -> void:
	if ui:
		ui.update_level_display()
	level_up.emit(new_level)


func _on_progression_evolved(new_data: DigimonData) -> void:
	_initialize_from_data()
	digivolved.emit(new_data)


func _on_progression_merged(resulting_tower: DigimonTower) -> void:
	if ui:
		ui.update_dp_indicator()
	merged.emit(resulting_tower)


func _on_dp_changed(_new_dp: int) -> void:
	if ui:
		ui.update_dp_indicator()


func _initialize_from_data() -> void:
	## Set up tower based on digimon_data
	if not digimon_data:
		return

	# Delegate to visual component
	if visual:
		visual.initialize_from_data()

	# Update UI elements
	if ui:
		ui.update_all()


## Handle selection
func select() -> void:
	if _is_selected:
		return
	_is_selected = true
	if combat:
		combat.set_selected(true)
	if visual:
		visual.set_selected(true)
		visual.show_range_indicator()
	selected.emit(self)


## Handle deselection
func deselect() -> void:
	if not _is_selected:
		return
	_is_selected = false
	if combat:
		combat.set_selected(false)
	if visual:
		visual.set_selected(false)
		visual.hide_range_indicator()
	deselected.emit(self)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if _is_selected:
				deselect()
			else:
				# Emit to EventBus so other towers can deselect
				if EventBus:
					EventBus.tower_selected.emit(self)
				select()


func _on_tower_selected(tower: Node) -> void:
	# Deselect this tower if another was selected
	if tower != self and _is_selected:
		deselect()


# =============================================================================
# DELEGATION METHODS - Visual Component
# =============================================================================

## Show range indicator circle
func show_range_indicator() -> void:
	if visual:
		visual.show_range_indicator()


## Hide range indicator circle
func hide_range_indicator() -> void:
	if visual:
		visual.hide_range_indicator()


## Flash the sprite when attacking
func flash_on_attack() -> void:
	if visual:
		visual.flash_on_attack()


# =============================================================================
# DELEGATION METHODS - UI Component
# =============================================================================

## Update the level display label
func update_level_display() -> void:
	if ui:
		ui.update_level_display()


## Get stats formatted for UI display
func get_stats_display() -> String:
	if ui:
		return ui.get_stats_display()
	return ""


# =============================================================================
# DELEGATION METHODS - Combat Component
# =============================================================================

## Set targeting priority (called from UI)
func set_targeting_priority(priority: Targeting.Priority) -> void:
	if combat:
		combat.set_targeting_priority(priority)


## Cycle to next targeting priority (for quick toggle)
func cycle_targeting_priority() -> void:
	if combat:
		combat.cycle_targeting_priority()


## Get current targeting priority name for display
func get_targeting_priority_name() -> String:
	if combat:
		return combat.get_targeting_priority_name()
	return "First"


# =============================================================================
# DELEGATION METHODS - Progression Component
# =============================================================================

## Get max level based on stage, DP, and Origin
func get_max_level() -> int:
	if progression:
		return progression.get_max_level()
	return 1


## Get the base max level for current stage (digivolve threshold)
func get_digivolve_threshold() -> int:
	if progression:
		return progression.get_digivolve_threshold()
	return 1


## Check if this tower can digivolve
func can_digivolve() -> bool:
	if progression:
		return progression.can_digivolve()
	return false


## Get the maximum stage this Digimon can reach based on Origin
func get_max_reachable_stage() -> int:
	if progression:
		return progression.get_max_reachable_stage()
	return GameConfig.STAGE_MEGA


## Check if this tower has hit its Origin ceiling
func is_at_origin_cap() -> bool:
	if progression:
		return progression.is_at_origin_cap()
	return false


## Get the cost to digivolve from current stage
func get_digivolve_cost() -> int:
	if progression:
		return progression.get_digivolve_cost()
	return 0


## Get the cost to level up from current level
func get_level_up_cost() -> int:
	if progression:
		return progression.get_level_up_cost()
	return 0


## Check if leveling up is possible (not at max)
func can_level_up() -> bool:
	if progression:
		return progression.can_level_up()
	return false


## Level up (call after payment is confirmed)
func do_level_up() -> void:
	if progression:
		progression.do_level_up()


## Check if this tower can merge with another
func can_merge_with(other: DigimonTower) -> bool:
	if progression:
		return progression.can_merge_with(other)
	return false


## Calculate the new DP when merging with another tower
func calculate_merge_dp(other: DigimonTower) -> int:
	if progression:
		return progression.calculate_merge_dp(other)
	return -1


## Merge this tower with another (other is sacrificed)
func merge_with(other: DigimonTower) -> int:
	if progression:
		return progression.merge_with(other)
	return -1


## Get all evolution paths for this Digimon
func get_evolution_paths() -> Array[EvolutionPath]:
	if progression:
		return progression.get_evolution_paths()
	return []


## Get only the unlocked evolution paths for current DP
func get_available_evolutions() -> Array[EvolutionPath]:
	if progression:
		return progression.get_available_evolutions()
	return []


## Get the default evolution path
func get_default_evolution() -> EvolutionPath:
	if progression:
		return progression.get_default_evolution()
	return null


## Apply evolution - transform this tower into the evolved form
func evolve_to(new_digimon_data: DigimonData) -> void:
	if progression:
		progression.evolve_to(new_digimon_data)


## Check if this tower can DNA Digivolve with another
func can_dna_with(other: DigimonTower) -> bool:
	if progression:
		return progression.can_dna_with(other)
	return false


## Get DNA result name if compatible
func get_dna_result(other: DigimonTower) -> String:
	if progression:
		return progression.get_dna_result(other)
	return ""


# =============================================================================
# UTILITY METHODS
# =============================================================================

## Set adjacent towers (called by grid manager)
func set_adjacent_towers(towers: Array[DigimonTower]) -> void:
	_adjacent_towers = towers


## Set the grid manager reference
func set_grid_manager(manager: GridManager) -> void:
	_grid_manager = manager


## Called when this tower kills an enemy
func on_enemy_killed(enemy_type: String) -> void:
	enemy_killed.emit(enemy_type)


## Get this tower's attribute for damage calculations
func get_attribute() -> int:
	if digimon_data:
		return digimon_data.attribute
	return DigimonData.Attribute.DATA


func _exit_tree() -> void:
	# Disconnect signals to prevent memory leaks
	if input_event.is_connected(_on_input_event):
		input_event.disconnect(_on_input_event)

	# Disconnect from EventBus
	if EventBus and EventBus.tower_selected.is_connected(_on_tower_selected):
		EventBus.tower_selected.disconnect(_on_tower_selected)

	# Clear references
	_adjacent_towers.clear()
	_grid_manager = null
