class_name SpawnMenu
extends PanelContainer
## UI Panel for spawning new Digimon towers.
## Allows player to select stage, type (random/specific/FREE), and attribute.
## Supports both direct spawn (at clicked position) and drag-drop placement mode.

signal spawn_requested(grid_pos: Vector2i, stage: int, attribute: int, cost: int)
signal placement_mode_requested(stage: int, attribute: int, cost: int, spawn_type: int)
signal menu_closed

## Spawn type enum
enum SpawnType {
	RANDOM,    ## Random attribute from pool
	SPECIFIC,  ## Player chooses attribute
	FREE       ## Always spawns FREE attribute
}

## Base costs per stage
const BASE_COSTS = {
	0: 100,  # In-Training
	1: 300,  # Rookie
	2: 800   # Champion
}

## Type multipliers
const TYPE_MULTIPLIERS = {
	SpawnType.RANDOM: 1.0,
	SpawnType.SPECIFIC: 1.5,
	SpawnType.FREE: 2.0
}

## Node references
@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var total_cost_label: Label = $MarginContainer/VBoxContainer/TotalCost

# Stage buttons
@onready var in_training_btn: Button = $MarginContainer/VBoxContainer/StageSelector/InTrainingBtn
@onready var rookie_btn: Button = $MarginContainer/VBoxContainer/StageSelector/RookieBtn
@onready var champion_btn: Button = $MarginContainer/VBoxContainer/StageSelector/ChampionBtn

# Type buttons
@onready var random_btn: Button = $MarginContainer/VBoxContainer/TypeSelector/RandomBtn
@onready var specific_btn: Button = $MarginContainer/VBoxContainer/TypeSelector/SpecificBtn
@onready var free_btn: Button = $MarginContainer/VBoxContainer/TypeSelector/FreeBtn

# Attribute section
@onready var attribute_label: Label = $MarginContainer/VBoxContainer/AttributeSelectorLabel
@onready var attribute_selector: HBoxContainer = $MarginContainer/VBoxContainer/AttributeSelector
@onready var vaccine_btn: Button = $MarginContainer/VBoxContainer/AttributeSelector/VaccineBtn
@onready var data_btn: Button = $MarginContainer/VBoxContainer/AttributeSelector/DataBtn
@onready var virus_btn: Button = $MarginContainer/VBoxContainer/AttributeSelector/VirusBtn

# Action buttons
@onready var spawn_btn: Button = $MarginContainer/VBoxContainer/Actions/SpawnBtn
@onready var place_btn: Button = $MarginContainer/VBoxContainer/Actions/PlaceBtn
@onready var cancel_btn: Button = $MarginContainer/VBoxContainer/Actions/CancelBtn

## Placement mode - when true, opens as placement selector without target position
var _placement_mode: bool = false

## Current selections
var _selected_stage: int = 0  # In-Training by default
var _selected_type: SpawnType = SpawnType.RANDOM
var _selected_attribute: int = 0  # Vaccine by default
var _target_grid_pos: Vector2i = Vector2i.ZERO
var _is_open: bool = false

func _ready() -> void:
	# Connect stage buttons
	in_training_btn.pressed.connect(_on_stage_selected.bind(0))
	rookie_btn.pressed.connect(_on_stage_selected.bind(1))
	champion_btn.pressed.connect(_on_stage_selected.bind(2))

	# Connect type buttons
	random_btn.pressed.connect(_on_type_selected.bind(SpawnType.RANDOM))
	specific_btn.pressed.connect(_on_type_selected.bind(SpawnType.SPECIFIC))
	free_btn.pressed.connect(_on_type_selected.bind(SpawnType.FREE))

	# Connect attribute buttons
	vaccine_btn.pressed.connect(_on_attribute_selected.bind(DigimonData.Attribute.VACCINE))
	data_btn.pressed.connect(_on_attribute_selected.bind(DigimonData.Attribute.DATA))
	virus_btn.pressed.connect(_on_attribute_selected.bind(DigimonData.Attribute.VIRUS))

	# Connect action buttons
	spawn_btn.pressed.connect(_on_spawn_pressed)
	if place_btn:
		place_btn.pressed.connect(_on_place_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Initial state
	_update_cost_display()
	_update_attribute_visibility()
	hide()

## Open the spawn menu for a specific grid position (direct spawn mode)
func open_at_position(grid_pos: Vector2i) -> void:
	_target_grid_pos = grid_pos
	_is_open = true
	_placement_mode = false

	# Reset to defaults
	_selected_stage = 0
	_selected_type = SpawnType.RANDOM
	_selected_attribute = DigimonData.Attribute.VACCINE

	# Update button states
	in_training_btn.button_pressed = true
	random_btn.button_pressed = true
	vaccine_btn.button_pressed = true

	_update_cost_display()
	_update_attribute_visibility()
	_update_affordability()
	_update_button_visibility()

	show()

	# Emit UI signal
	if EventBus:
		var spawns = _get_available_spawns()
		EventBus.ui_spawn_menu_opened.emit(spawns)


## Open the spawn menu for drag-drop placement (no target position)
func open_for_placement() -> void:
	_target_grid_pos = Vector2i(-1, -1)
	_is_open = true
	_placement_mode = true

	# Reset to defaults
	_selected_stage = 0
	_selected_type = SpawnType.RANDOM
	_selected_attribute = DigimonData.Attribute.VACCINE

	# Update button states
	in_training_btn.button_pressed = true
	random_btn.button_pressed = true
	vaccine_btn.button_pressed = true

	_update_cost_display()
	_update_attribute_visibility()
	_update_affordability()
	_update_button_visibility()

	show()

	# Emit UI signal
	if EventBus:
		var spawns = _get_available_spawns()
		EventBus.ui_spawn_menu_opened.emit(spawns)

## Close the spawn menu
func close() -> void:
	_is_open = false
	hide()
	menu_closed.emit()

	if EventBus:
		EventBus.ui_spawn_menu_closed.emit()

## Check if menu is currently open
func is_open() -> bool:
	return _is_open

## Get the current target grid position
func get_target_position() -> Vector2i:
	return _target_grid_pos

func _on_stage_selected(stage: int) -> void:
	AudioManager.play_sfx("button_click")
	_selected_stage = stage
	_update_cost_display()
	_update_affordability()

func _on_type_selected(spawn_type: SpawnType) -> void:
	AudioManager.play_sfx("button_click")
	_selected_type = spawn_type
	_update_attribute_visibility()
	_update_cost_display()
	_update_affordability()

func _on_attribute_selected(attribute: int) -> void:
	AudioManager.play_sfx("button_click")
	_selected_attribute = attribute

func _on_spawn_pressed() -> void:
	var cost = _calculate_cost()

	# Check if player can afford
	if not GameManager.can_afford(cost):
		# Show cannot afford feedback and play insufficient funds sound
		AudioManager.play_sfx("insufficient_funds")
		_flash_cost_label()
		return

	AudioManager.play_sfx("button_click")

	# Determine final attribute
	var final_attribute: int
	match _selected_type:
		SpawnType.RANDOM:
			# Random attribute (excluding FREE for random spawns)
			final_attribute = randi() % 3  # 0, 1, or 2 (Vaccine, Data, Virus)
		SpawnType.SPECIFIC:
			final_attribute = _selected_attribute
		SpawnType.FREE:
			final_attribute = DigimonData.Attribute.FREE

	# Emit spawn request
	spawn_requested.emit(_target_grid_pos, _selected_stage, final_attribute, cost)

	close()

func _on_place_pressed() -> void:
	## Handle "Drag to Place" button - enters placement mode
	var cost = _calculate_cost()

	# Check if player can afford
	if not GameManager.can_afford(cost):
		AudioManager.play_sfx("insufficient_funds")
		_flash_cost_label()
		return

	AudioManager.play_sfx("button_click")

	# Determine final attribute for placement mode
	var final_attribute: int
	match _selected_type:
		SpawnType.RANDOM:
			final_attribute = -1  # Random will be determined at spawn time
		SpawnType.SPECIFIC:
			final_attribute = _selected_attribute
		SpawnType.FREE:
			final_attribute = DigimonData.Attribute.FREE

	# Emit placement mode signal
	placement_mode_requested.emit(_selected_stage, final_attribute, cost, _selected_type)

	close()


func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("button_click")
	close()


func _update_button_visibility() -> void:
	## Show/hide spawn vs place buttons based on mode
	if spawn_btn:
		spawn_btn.visible = not _placement_mode
	if place_btn:
		place_btn.visible = _placement_mode


## Calculate total spawn cost based on selections
func _calculate_cost() -> int:
	var base = BASE_COSTS.get(_selected_stage, 100)
	var multiplier = TYPE_MULTIPLIERS.get(_selected_type, 1.0)
	return int(base * multiplier)

## Get the spawn cost for external queries
func get_spawn_cost(stage: int, spawn_type: SpawnType) -> int:
	var base = BASE_COSTS.get(stage, 100)
	var multiplier = TYPE_MULTIPLIERS.get(spawn_type, 1.0)
	return int(base * multiplier)

func _update_cost_display() -> void:
	var cost = _calculate_cost()
	total_cost_label.text = "Total: %d DB" % cost

func _update_attribute_visibility() -> void:
	# Show attribute selector only when Specific is selected
	var show_attrs = _selected_type == SpawnType.SPECIFIC
	attribute_label.visible = show_attrs
	attribute_selector.visible = show_attrs

func _update_affordability() -> void:
	var cost = _calculate_cost()
	var can_afford = GameManager.can_afford(cost)

	if spawn_btn:
		spawn_btn.disabled = not can_afford
	if place_btn:
		place_btn.disabled = not can_afford

	if can_afford:
		total_cost_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		total_cost_label.add_theme_color_override("font_color", Color.RED)

func _flash_cost_label() -> void:
	# Brief red flash to indicate cannot afford
	var original_color = total_cost_label.get_theme_color("font_color")
	total_cost_label.add_theme_color_override("font_color", Color.RED)

	var tween = create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(func():
		total_cost_label.add_theme_color_override("font_color", original_color)
	)

func _get_available_spawns() -> Dictionary:
	## Build dictionary of available spawn options for EventBus signal
	var spawns = {}

	for stage in range(3):  # In-Training, Rookie, Champion
		var stage_name = ["In-Training", "Rookie", "Champion"][stage]
		spawns[stage_name] = {
			"random": get_spawn_cost(stage, SpawnType.RANDOM),
			"specific": get_spawn_cost(stage, SpawnType.SPECIFIC),
			"free": get_spawn_cost(stage, SpawnType.FREE)
		}

	return spawns

## Handle input for closing menu with escape
func _input(event: InputEvent) -> void:
	if not _is_open:
		return

	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect stage buttons
	if in_training_btn and in_training_btn.pressed.is_connected(_on_stage_selected):
		in_training_btn.pressed.disconnect(_on_stage_selected)

	if rookie_btn and rookie_btn.pressed.is_connected(_on_stage_selected):
		rookie_btn.pressed.disconnect(_on_stage_selected)

	if champion_btn and champion_btn.pressed.is_connected(_on_stage_selected):
		champion_btn.pressed.disconnect(_on_stage_selected)

	# Disconnect type buttons
	if random_btn and random_btn.pressed.is_connected(_on_type_selected):
		random_btn.pressed.disconnect(_on_type_selected)

	if specific_btn and specific_btn.pressed.is_connected(_on_type_selected):
		specific_btn.pressed.disconnect(_on_type_selected)

	if free_btn and free_btn.pressed.is_connected(_on_type_selected):
		free_btn.pressed.disconnect(_on_type_selected)

	# Disconnect attribute buttons
	if vaccine_btn and vaccine_btn.pressed.is_connected(_on_attribute_selected):
		vaccine_btn.pressed.disconnect(_on_attribute_selected)

	if data_btn and data_btn.pressed.is_connected(_on_attribute_selected):
		data_btn.pressed.disconnect(_on_attribute_selected)

	if virus_btn and virus_btn.pressed.is_connected(_on_attribute_selected):
		virus_btn.pressed.disconnect(_on_attribute_selected)

	# Disconnect action buttons
	if spawn_btn and spawn_btn.pressed.is_connected(_on_spawn_pressed):
		spawn_btn.pressed.disconnect(_on_spawn_pressed)

	if place_btn and place_btn.pressed.is_connected(_on_place_pressed):
		place_btn.pressed.disconnect(_on_place_pressed)

	if cancel_btn and cancel_btn.pressed.is_connected(_on_cancel_pressed):
		cancel_btn.pressed.disconnect(_on_cancel_pressed)
