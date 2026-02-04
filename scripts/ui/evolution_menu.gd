extends Control
## Evolution menu UI - displays available evolution paths for a Digimon tower.
## Shows all paths with DP requirements, highlighting available ones.

signal evolution_selected(path: EvolutionPath)
signal cancelled()

## Current tower being evolved
var _current_tower: DigimonTower = null

## Currently selected path
var _selected_path: EvolutionPath = null

## Reference to evolution system (set by parent)
var _evolution_system: EvolutionSystem = null

## UI Node references
@onready var title_label: Label = $MainVBox/Header/Title
@onready var close_button: Button = $MainVBox/Header/CloseButton
@onready var current_info_label: Label = $MainVBox/CurrentInfo
@onready var options_container: VBoxContainer = $MainVBox/ScrollContainer/EvolutionOptions
@onready var cost_label: Label = $MainVBox/Footer/CostLabel
@onready var cancel_btn: Button = $MainVBox/Footer/CancelBtn

## Colors for evolution cards
const COLOR_AVAILABLE: Color = Color(0.2, 0.8, 0.2)
const COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5)
const COLOR_PAST: Color = Color(0.8, 0.5, 0.2)
const COLOR_SELECTED: Color = Color(0.3, 0.6, 1.0)

## Evolution card scene template (created dynamically)
var _card_template: PackedScene = null


func _ready() -> void:
	# Connect button signals
	cancel_btn.pressed.connect(_on_cancel_pressed)
	close_button.pressed.connect(_on_cancel_pressed)

	# Start hidden
	visible = false

	# Connect to EventBus
	if EventBus:
		EventBus.ui_evolution_menu_closed.connect(_on_external_close)


## Set the evolution system reference
func set_evolution_system(system: EvolutionSystem) -> void:
	_evolution_system = system


## Open the evolution menu for a tower
func open(tower: DigimonTower, paths: Array[EvolutionPath]) -> void:
	if not tower or paths.is_empty():
		return

	_current_tower = tower
	_selected_path = null

	# Update header info
	_update_current_info()

	# Update cost display
	cost_label.text = "Cost: %d DB" % tower.get_digivolve_cost()

	# Clear existing options
	_clear_options()

	# Create evolution cards for each path
	for path in paths:
		var card = _create_evolution_card(path)
		options_container.add_child(card)

	# Show the menu
	visible = true

	# Bring to front
	move_to_front()


## Update the current Digimon info display
func _update_current_info() -> void:
	if not _current_tower or not _current_tower.digimon_data:
		return

	var data = _current_tower.digimon_data
	var origin_name = _get_origin_name(_current_tower.origin_stage)
	current_info_label.text = "%s | DP: %d | Origin: %s" % [
		data.digimon_name,
		_current_tower.current_dp,
		origin_name
	]


## Clear all evolution option cards
func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


## Create an evolution card UI element for a path
func _create_evolution_card(path: EvolutionPath) -> Control:
	# Create card container
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)

	# Create style for the panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5

	# Set border color based on availability
	var is_available = path.is_available(_current_tower.current_dp) if _current_tower else false
	var is_locked = path.is_locked(_current_tower.current_dp) if _current_tower else true
	var is_past = path.is_past(_current_tower.current_dp) if _current_tower else false

	if is_available:
		style.border_color = COLOR_AVAILABLE
	elif is_locked:
		style.border_color = COLOR_LOCKED
	else:
		style.border_color = COLOR_PAST

	card.add_theme_stylebox_override("panel", style)

	# Main horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	# Sprite placeholder
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)
	var sprite_rect = ColorRect.new()
	sprite_rect.custom_minimum_size = Vector2(48, 48)
	sprite_rect.color = _get_attribute_color(path)
	sprite_container.add_child(sprite_rect)
	hbox.add_child(sprite_container)

	# Info VBox
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	# Name and DP requirement
	var name_hbox = HBoxContainer.new()
	info_vbox.add_child(name_hbox)

	var name_label = Label.new()
	name_label.text = path.result_digimon
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 18)
	name_hbox.add_child(name_label)

	var dp_label = Label.new()
	dp_label.text = path.get_requirement_text()
	dp_label.add_theme_font_size_override("font_size", 14)
	if is_locked:
		dp_label.add_theme_color_override("font_color", COLOR_LOCKED)
	elif is_past:
		dp_label.add_theme_color_override("font_color", COLOR_PAST)
	else:
		dp_label.add_theme_color_override("font_color", COLOR_AVAILABLE)
	name_hbox.add_child(dp_label)

	# Description
	if path.description != "":
		var desc_label = Label.new()
		desc_label.text = path.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		info_vbox.add_child(desc_label)

	# Ability preview
	if path.ability_preview != "":
		var ability_label = Label.new()
		ability_label.text = "Ability: " + path.ability_preview
		ability_label.add_theme_font_size_override("font_size", 12)
		ability_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		info_vbox.add_child(ability_label)

	# Status label for locked/past
	if not is_available:
		var status_label = Label.new()
		status_label.text = path.get_status_text(_current_tower.current_dp) if _current_tower else ""
		status_label.add_theme_font_size_override("font_size", 11)
		if is_locked:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
		else:
			status_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
		info_vbox.add_child(status_label)

	# Select button
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(80, 60)
	select_btn.text = "SELECT" if is_available else "LOCKED"
	select_btn.disabled = not is_available
	select_btn.pressed.connect(_on_evolution_card_selected.bind(path))
	hbox.add_child(select_btn)

	# Dim the whole card if not available
	if not is_available:
		card.modulate = Color(0.6, 0.6, 0.6)

	return card


## Get a color based on the evolution's attribute (if we can determine it)
func _get_attribute_color(path: EvolutionPath) -> Color:
	# Try to get the DigimonData for this evolution to determine color
	if _evolution_system:
		var data = _evolution_system.get_digimon_data(path.result_digimon)
		if data:
			match data.attribute:
				DigimonData.Attribute.VACCINE:
					return Color(0.2, 0.6, 1.0)  # Blue
				DigimonData.Attribute.DATA:
					return Color(0.2, 0.8, 0.2)  # Green
				DigimonData.Attribute.VIRUS:
					return Color(0.8, 0.2, 0.2)  # Red
				DigimonData.Attribute.FREE:
					return Color(0.8, 0.8, 0.2)  # Yellow

	# Default gray if unknown
	return Color(0.5, 0.5, 0.5)


## Handle evolution card selection
func _on_evolution_card_selected(path: EvolutionPath) -> void:
	if not path.is_available(_current_tower.current_dp) if _current_tower else false:
		return

	_selected_path = path
	evolution_selected.emit(path)
	close()


## Handle cancel button press
func _on_cancel_pressed() -> void:
	cancelled.emit()
	close()


## Handle external close request
func _on_external_close() -> void:
	if visible:
		close()


## Close the evolution menu
func close() -> void:
	_current_tower = null
	_selected_path = null
	_clear_options()
	visible = false


## Get the currently selected path
func get_selected_path() -> EvolutionPath:
	return _selected_path


## Get the current tower
func get_current_tower() -> DigimonTower:
	return _current_tower


## Check if the menu is open
func is_open() -> bool:
	return visible


## Get origin stage name
func _get_origin_name(origin: int) -> String:
	match origin:
		DigimonTower.STAGE_IN_TRAINING: return "In-Training"
		DigimonTower.STAGE_ROOKIE: return "Rookie"
		DigimonTower.STAGE_CHAMPION: return "Champion"
		DigimonTower.STAGE_ULTIMATE: return "Ultimate"
		DigimonTower.STAGE_MEGA: return "Mega"
		_: return "Unknown"
