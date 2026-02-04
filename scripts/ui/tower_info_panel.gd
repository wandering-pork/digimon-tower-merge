extends PanelContainer
## Tower Info Panel - Displays selected tower information and actions.
## Shows stats, level, DP, origin, and action buttons for level up, digivolve, sell.

signal level_up_requested(tower: DigimonTower)
signal digivolve_requested(tower: DigimonTower)
signal merge_requested(tower: DigimonTower)
signal sell_requested(tower: DigimonTower)
signal target_cycle_requested(tower: DigimonTower)

## Currently displayed tower
var _current_tower: DigimonTower = null

## Economy system reference
var _economy_system: EconomySystem = null

## Evolution system reference
var _evolution_system: EvolutionSystem = null

## UI Node references
@onready var tower_sprite: TextureRect = $MarginContainer/VBoxContainer/Header/TowerSprite
@onready var tower_name: Label = $MarginContainer/VBoxContainer/Header/HeaderInfo/TowerName
@onready var stage_attribute: Label = $MarginContainer/VBoxContainer/Header/HeaderInfo/StageAttribute
@onready var level_info: Label = $MarginContainer/VBoxContainer/LevelInfo
@onready var origin_info: Label = $MarginContainer/VBoxContainer/OriginInfo
@onready var damage_info: Label = $MarginContainer/VBoxContainer/DamageInfo
@onready var effect_info: Label = $MarginContainer/VBoxContainer/EffectInfo
@onready var target_label: Label = $MarginContainer/VBoxContainer/TargetLabel
@onready var cycle_target_btn: Button = $MarginContainer/VBoxContainer/CycleTargetBtn
@onready var level_up_btn: Button = $MarginContainer/VBoxContainer/Actions/LevelUpBtn
@onready var digivolve_btn: Button = $MarginContainer/VBoxContainer/Actions/DigivolveBtn
@onready var merge_btn: Button = $MarginContainer/VBoxContainer/Actions/MergeBtn
@onready var sell_btn: Button = $MarginContainer/VBoxContainer/Actions/SellBtn
@onready var origin_cap_warning: Label = $MarginContainer/VBoxContainer/OriginCapWarning

## Merge system reference
var _merge_system: MergeSystem = null


func _ready() -> void:
	# Connect button signals
	cycle_target_btn.pressed.connect(_on_cycle_target_pressed)
	level_up_btn.pressed.connect(_on_level_up_pressed)
	digivolve_btn.pressed.connect(_on_digivolve_pressed)
	merge_btn.pressed.connect(_on_merge_pressed)
	sell_btn.pressed.connect(_on_sell_pressed)

	# Connect to EventBus
	if EventBus:
		EventBus.tower_selected.connect(_on_tower_selected)

	# Connect to GameManager for currency updates
	if GameManager:
		GameManager.digibytes_changed.connect(_on_digibytes_changed)

	# Start hidden
	visible = false


## Set economy system reference
func set_economy_system(system: EconomySystem) -> void:
	_economy_system = system


## Set evolution system reference
func set_evolution_system(system: EvolutionSystem) -> void:
	_evolution_system = system


## Set merge system reference
func set_merge_system(system: MergeSystem) -> void:
	_merge_system = system


## Handle tower selection from EventBus
func _on_tower_selected(tower: Node) -> void:
	if tower == null or not tower is DigimonTower:
		close()
		return

	_current_tower = tower as DigimonTower
	_update_display()
	visible = true


## Close the panel
func close() -> void:
	_current_tower = null
	visible = false


## Get the current tower
func get_current_tower() -> DigimonTower:
	return _current_tower


## Update all display elements
func _update_display() -> void:
	if not _current_tower or not _current_tower.digimon_data:
		return

	var data = _current_tower.digimon_data

	# Update header
	tower_name.text = data.digimon_name
	stage_attribute.text = "%s | %s" % [data.get_stage_name(), data.get_attribute_name()]

	# Update sprite if available
	_update_sprite()

	# Update level and DP info
	level_info.text = "Level %d/%d | DP: %d" % [
		_current_tower.current_level,
		_current_tower.get_max_level(),
		_current_tower.current_dp
	]

	# Update origin info
	origin_info.text = "Origin: %s" % _get_origin_name(_current_tower.origin_stage)

	# Update combat stats
	if data.can_attack():
		damage_info.text = "DMG: %d | SPD: %.1f/s | RNG: %.1f" % [
			data.base_damage,
			data.attack_speed,
			data.attack_range
		]
		damage_info.visible = true
	else:
		damage_info.visible = false

	# Update effect info
	if data.effect_type != "" and data.effect_chance > 0:
		var chance_percent = int(data.effect_chance * 100)
		effect_info.text = "%s %d%% (%.1fs)" % [
			data.effect_type,
			chance_percent,
			data.effect_duration
		]
		effect_info.visible = true
	else:
		effect_info.visible = false

	# Update targeting
	target_label.text = "Target: %s" % _current_tower.get_targeting_priority_name()

	# Update button states
	_update_button_states()

	# Show origin cap warning if applicable
	origin_cap_warning.visible = _current_tower.is_at_origin_cap()


## Update the tower sprite display
func _update_sprite() -> void:
	if not _current_tower or not _current_tower.digimon_data:
		return

	var data = _current_tower.digimon_data
	var sprite_path = "res://assets/sprites/digimon/%s.png" % data.digimon_name.to_lower()

	if ResourceLoader.exists(sprite_path):
		tower_sprite.texture = load(sprite_path)
	else:
		# Create placeholder color based on attribute
		tower_sprite.texture = null
		tower_sprite.modulate = _get_attribute_color(data.attribute)


## Update button enabled states and text
func _update_button_states() -> void:
	if not _current_tower:
		return

	var data = _current_tower.digimon_data
	var current_db = GameManager.current_digibytes if GameManager else 0

	# Level Up button
	var level_up_cost = _current_tower.get_level_up_cost()
	var can_level = _current_tower.can_level_up()
	var can_afford_level = current_db >= level_up_cost

	level_up_btn.text = "Level Up (%d DB)" % level_up_cost
	level_up_btn.disabled = not can_level or not can_afford_level

	if not can_level:
		level_up_btn.text = "MAX LEVEL"
	elif not can_afford_level:
		level_up_btn.add_theme_color_override("font_color", Color.RED)
	else:
		level_up_btn.remove_theme_color_override("font_color")

	# Digivolve button
	var digivolve_cost = _current_tower.get_digivolve_cost()
	var can_digivolve = _current_tower.can_digivolve()
	var can_afford_digivolve = current_db >= digivolve_cost

	digivolve_btn.text = "Digivolve (%d DB)" % digivolve_cost
	digivolve_btn.disabled = not can_digivolve or not can_afford_digivolve

	if _current_tower.is_at_origin_cap():
		digivolve_btn.text = "Origin Cap"
		digivolve_btn.disabled = true
	elif data.stage >= GameConfig.STAGE_MEGA:
		digivolve_btn.text = "MAX STAGE"
		digivolve_btn.disabled = true
	elif _current_tower.current_level < _current_tower.get_digivolve_threshold():
		var needed_level = _current_tower.get_digivolve_threshold()
		digivolve_btn.text = "Need Lv %d" % needed_level
		digivolve_btn.disabled = true
	elif not can_afford_digivolve:
		digivolve_btn.add_theme_color_override("font_color", Color.RED)
	else:
		digivolve_btn.remove_theme_color_override("font_color")

	# Merge button
	var can_merge = data.can_merge()
	var merge_partners_count = 0

	if can_merge and _merge_system:
		var stats = _merge_system.get_merge_stats(_current_tower)
		merge_partners_count = stats.get("potential_partners", 0)

	merge_btn.disabled = not can_merge or merge_partners_count == 0

	if not can_merge:
		merge_btn.text = "Cannot Merge"
		merge_btn.tooltip_text = "In-Training stage cannot merge"
	elif merge_partners_count == 0:
		merge_btn.text = "No Partners"
		merge_btn.tooltip_text = "No compatible merge targets available"
	else:
		merge_btn.text = "Merge (+1 DP)"
		merge_btn.tooltip_text = "%d merge partners available" % merge_partners_count

	# Sell button
	var sell_value = 0
	if _economy_system:
		sell_value = _economy_system.get_sell_value(_current_tower)
	else:
		# Fallback calculation
		sell_value = int(_current_tower.get("total_investment") * 0.5) if _current_tower.get("total_investment") else 0

	sell_btn.text = "Sell (%d DB)" % sell_value
	sell_btn.disabled = false


## Handle currency change - update button affordability
func _on_digibytes_changed(_amount: int) -> void:
	if visible and _current_tower:
		_update_button_states()


## Handle cycle target button press
func _on_cycle_target_pressed() -> void:
	if _current_tower:
		_current_tower.cycle_targeting_priority()
		target_label.text = "Target: %s" % _current_tower.get_targeting_priority_name()
		target_cycle_requested.emit(_current_tower)


## Handle level up button press
func _on_level_up_pressed() -> void:
	if not _current_tower:
		return

	if _economy_system:
		if _economy_system.try_level_up(_current_tower):
			_update_display()
	else:
		# Fallback - try direct level up
		var cost = _current_tower.get_level_up_cost()
		if GameManager and GameManager.spend_digibytes(cost):
			_current_tower.do_level_up()
			_update_display()

	level_up_requested.emit(_current_tower)


## Handle digivolve button press
func _on_digivolve_pressed() -> void:
	if not _current_tower or not _current_tower.can_digivolve():
		return

	# Request evolution menu from EvolutionSystem
	if _evolution_system:
		_evolution_system.request_evolution(_current_tower)
	else:
		# Try to find EvolutionSystem in tree
		var evolution_system = get_tree().root.find_child("EvolutionSystem", true, false)
		if evolution_system and evolution_system.has_method("request_evolution"):
			evolution_system.request_evolution(_current_tower)

	digivolve_requested.emit(_current_tower)


## Handle merge button press
func _on_merge_pressed() -> void:
	if not _current_tower:
		return

	if not _current_tower.digimon_data.can_merge():
		return

	# Emit merge request - the LevelUICoordinator will handle starting merge mode
	# which will emit merge_mode_entered signal from the MergeSelectionHandler
	merge_requested.emit(_current_tower)


## Handle sell button press
func _on_sell_pressed() -> void:
	if not _current_tower:
		return

	# Emit sell request - let parent handle confirmation dialog
	sell_requested.emit(_current_tower)


## Get origin stage name
func _get_origin_name(origin: int) -> String:
	if GameConfig:
		return GameConfig.get_stage_name(origin)
	match origin:
		GameConfig.STAGE_IN_TRAINING: return "In-Training"
		GameConfig.STAGE_ROOKIE: return "Rookie"
		GameConfig.STAGE_CHAMPION: return "Champion"
		GameConfig.STAGE_ULTIMATE: return "Ultimate"
		GameConfig.STAGE_MEGA: return "Mega"
		_: return "Unknown"


## Get attribute color for sprite placeholder
func _get_attribute_color(attribute: int) -> Color:
	match attribute:
		DigimonData.Attribute.VACCINE:
			return Color(0.2, 0.6, 1.0)  # Blue
		DigimonData.Attribute.DATA:
			return Color(0.2, 0.8, 0.2)  # Green
		DigimonData.Attribute.VIRUS:
			return Color(0.8, 0.2, 0.2)  # Red
		DigimonData.Attribute.FREE:
			return Color(0.8, 0.8, 0.2)  # Yellow
		_:
			return Color(0.5, 0.5, 0.5)  # Gray


## Handle input for closing panel
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		if EventBus:
			EventBus.tower_selected.emit(null)
		close()


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect button signals
	if cycle_target_btn and cycle_target_btn.pressed.is_connected(_on_cycle_target_pressed):
		cycle_target_btn.pressed.disconnect(_on_cycle_target_pressed)

	if level_up_btn and level_up_btn.pressed.is_connected(_on_level_up_pressed):
		level_up_btn.pressed.disconnect(_on_level_up_pressed)

	if digivolve_btn and digivolve_btn.pressed.is_connected(_on_digivolve_pressed):
		digivolve_btn.pressed.disconnect(_on_digivolve_pressed)

	if merge_btn and merge_btn.pressed.is_connected(_on_merge_pressed):
		merge_btn.pressed.disconnect(_on_merge_pressed)

	if sell_btn and sell_btn.pressed.is_connected(_on_sell_pressed):
		sell_btn.pressed.disconnect(_on_sell_pressed)

	# Disconnect EventBus signals
	if EventBus and EventBus.tower_selected.is_connected(_on_tower_selected):
		EventBus.tower_selected.disconnect(_on_tower_selected)

	# Disconnect GameManager signals
	if GameManager and GameManager.digibytes_changed.is_connected(_on_digibytes_changed):
		GameManager.digibytes_changed.disconnect(_on_digibytes_changed)

	# Clear references
	_current_tower = null
	_economy_system = null
	_evolution_system = null
	_merge_system = null
