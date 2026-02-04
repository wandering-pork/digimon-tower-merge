extends Control
## Evolution menu UI - displays available evolution paths for a Digimon tower.
## Shows all paths with DP requirements, highlighting available ones.
## Includes stat preview and confirmation before executing evolution.

signal evolution_selected(path: EvolutionPath)
signal evolution_confirmed(tower: DigimonTower, path: EvolutionPath)
signal cancelled()

## Current tower being evolved
var _current_tower: DigimonTower = null

## Currently selected path (for confirmation)
var _selected_path: EvolutionPath = null

## Reference to evolution system (set by parent)
var _evolution_system: EvolutionSystem = null

## Reference to selected card for visual highlighting
var _selected_card: Control = null

## UI Node references
@onready var title_label: Label = $MainVBox/Header/Title
@onready var close_button: Button = $MainVBox/Header/CloseButton
@onready var current_info_label: Label = $MainVBox/CurrentInfo
@onready var options_container: VBoxContainer = $MainVBox/ScrollContainer/EvolutionOptions
@onready var cost_label: Label = $MainVBox/Footer/CostLabel
@onready var cancel_btn: Button = $MainVBox/Footer/CancelBtn
@onready var confirm_btn: Button = $MainVBox/Footer/ConfirmBtn

## Colors for evolution cards
const COLOR_AVAILABLE: Color = Color(0.2, 0.8, 0.2)
const COLOR_LOCKED: Color = Color(0.5, 0.5, 0.5)
const COLOR_PAST: Color = Color(0.8, 0.5, 0.2)
const COLOR_SELECTED: Color = Color(0.3, 0.6, 1.0)
const COLOR_HIGHLIGHT: Color = Color(0.4, 0.7, 1.0)

## Evolution card scene template (created dynamically)
var _card_template: PackedScene = null


func _ready() -> void:
	# Connect button signals
	cancel_btn.pressed.connect(_on_cancel_pressed)
	close_button.pressed.connect(_on_cancel_pressed)

	# Setup confirm button (may not exist in scene yet)
	_setup_confirm_button()

	# Start hidden
	visible = false

	# Connect to EventBus
	if EventBus:
		EventBus.ui_evolution_menu_closed.connect(_on_external_close)


## Setup confirm button - creates it if it doesn't exist in the scene
func _setup_confirm_button() -> void:
	# Try to get existing confirm button
	confirm_btn = get_node_or_null("MainVBox/Footer/ConfirmBtn")

	if not confirm_btn:
		# Create confirm button dynamically
		var footer = get_node_or_null("MainVBox/Footer")
		if footer:
			confirm_btn = Button.new()
			confirm_btn.name = "ConfirmBtn"
			confirm_btn.custom_minimum_size = Vector2(120, 40)
			confirm_btn.text = "CONFIRM"
			confirm_btn.disabled = true
			footer.add_child(confirm_btn)
			# Move cancel button to the left by moving confirm to right
			footer.move_child(confirm_btn, -1)

	if confirm_btn:
		confirm_btn.pressed.connect(_on_confirm_pressed)
		confirm_btn.disabled = true


## Set the evolution system reference
func set_evolution_system(system: EvolutionSystem) -> void:
	_evolution_system = system


## Open the evolution menu for a tower
func open(tower: DigimonTower, paths: Array[EvolutionPath]) -> void:
	if not tower or paths.is_empty():
		return

	_current_tower = tower
	_selected_path = null
	_selected_card = null

	# Update header info
	_update_current_info()

	# Update cost display
	var cost = tower.get_digivolve_cost()
	var can_afford = GameManager.can_afford(cost) if GameManager else true
	cost_label.text = "Cost: %d DB" % cost
	if not can_afford:
		cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		cost_label.remove_theme_color_override("font_color")

	# Clear existing options
	_clear_options()

	# Create evolution cards for each path
	for path in paths:
		var card = _create_evolution_card(path)
		options_container.add_child(card)

	# Reset confirm button state
	if confirm_btn:
		confirm_btn.disabled = true
		confirm_btn.text = "SELECT PATH"

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
	card.custom_minimum_size = Vector2(0, 100)

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

	# Store path reference on card for selection
	card.set_meta("evolution_path", path)
	card.set_meta("is_available", is_available)
	card.set_meta("base_style", style)

	# Main horizontal layout
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	card.add_child(hbox)

	# Sprite placeholder / actual sprite
	var sprite_container = CenterContainer.new()
	sprite_container.custom_minimum_size = Vector2(64, 64)

	# Try to load actual sprite
	var sprite_loaded = false
	var sprite_path = "res://assets/sprites/digimon/%s.png" % path.result_digimon.to_lower()
	if ResourceLoader.exists(sprite_path):
		var texture_rect = TextureRect.new()
		texture_rect.texture = load(sprite_path)
		texture_rect.custom_minimum_size = Vector2(48, 48)
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		sprite_container.add_child(texture_rect)
		sprite_loaded = true

	if not sprite_loaded:
		# Fallback to colored rectangle
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

	# Stat preview - show target Digimon stats
	var stat_label = _create_stat_preview_label(path)
	if stat_label:
		info_vbox.add_child(stat_label)

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

	# Select button - now selects for confirmation instead of immediate evolution
	var select_btn = Button.new()
	select_btn.custom_minimum_size = Vector2(80, 60)
	select_btn.text = "SELECT" if is_available else "LOCKED"
	select_btn.disabled = not is_available
	select_btn.pressed.connect(_on_evolution_card_clicked.bind(card, path))
	hbox.add_child(select_btn)

	# Dim the whole card if not available
	if not is_available:
		card.modulate = Color(0.6, 0.6, 0.6)

	return card


## Create a stat preview label for an evolution path
func _create_stat_preview_label(path: EvolutionPath) -> Label:
	if not _evolution_system:
		return null

	var target_data = _evolution_system.get_digimon_data(path.result_digimon)
	if not target_data:
		return null

	# Format stat preview: DMG | SPD | RNG | Effect
	var stat_text = "DMG: %d | SPD: %.1f/s | RNG: %.1f" % [
		target_data.base_damage,
		target_data.attack_speed,
		target_data.attack_range
	]

	# Add effect info if present
	if target_data.effect_type != "" and target_data.effect_chance > 0:
		var chance_pct = int(target_data.effect_chance * 100)
		stat_text += " | %s %d%%" % [target_data.effect_type, chance_pct]

	var label = Label.new()
	label.text = stat_text
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))

	return label


## Handle evolution card click - select for confirmation
func _on_evolution_card_clicked(card: Control, path: EvolutionPath) -> void:
	if not path or not _current_tower:
		return

	var is_available = card.get_meta("is_available") if card.has_meta("is_available") else false
	if not is_available:
		return

	AudioManager.play_sfx("button_click")

	# Deselect previous card
	if _selected_card and _selected_card != card:
		_deselect_card(_selected_card)

	# Select this card
	_select_card(card)
	_selected_card = card
	_selected_path = path

	# Enable confirm button
	if confirm_btn:
		confirm_btn.disabled = false
		confirm_btn.text = "CONFIRM: %s" % path.result_digimon

	# Emit selection signal (not confirmation yet)
	evolution_selected.emit(path)


## Select a card visually
func _select_card(card: Control) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.25, 0.35)
	style.border_width_bottom = 3
	style.border_width_top = 3
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_color = COLOR_HIGHLIGHT
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	card.add_theme_stylebox_override("panel", style)


## Deselect a card visually
func _deselect_card(card: Control) -> void:
	if card.has_meta("base_style"):
		var base_style = card.get_meta("base_style")
		card.add_theme_stylebox_override("panel", base_style)


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


## Handle confirm button press - execute the evolution
func _on_confirm_pressed() -> void:
	if not _selected_path or not _current_tower:
		return

	# Verify path is still available
	if not _selected_path.is_available(_current_tower.current_dp):
		ErrorHandler.log_warning("EvolutionMenu", "Selected path no longer available")
		return

	# Check if player can afford the evolution
	var cost = _current_tower.get_digivolve_cost()
	if GameManager and not GameManager.can_afford(cost):
		AudioManager.play_sfx("insufficient_funds")
		ErrorHandler.log_warning("EvolutionMenu", "Cannot afford evolution cost: %d DB" % cost)
		if EventBus:
			EventBus.floating_text_requested.emit(
				_current_tower.global_position,
				"Need %d DB!" % cost,
				Color.RED
			)
		return

	AudioManager.play_sfx("button_click")

	# Execute evolution via evolution system
	if _evolution_system:
		_evolution_system.execute_evolution(_current_tower, _selected_path)
	else:
		ErrorHandler.log_error("EvolutionMenu", "No evolution system reference")

	# Emit confirmed signal
	evolution_confirmed.emit(_current_tower, _selected_path)

	# Close the menu (evolution_system will also request close via EventBus)
	close()


## Handle cancel button press
func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("button_click")
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
	_selected_card = null
	_clear_options()

	# Reset confirm button
	if confirm_btn:
		confirm_btn.disabled = true
		confirm_btn.text = "SELECT PATH"

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


## Handle input for keyboard shortcuts
func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Enter to confirm selection
	if event.is_action_pressed("ui_accept") and _selected_path:
		_on_confirm_pressed()
		get_viewport().set_input_as_handled()

	# Escape to cancel
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


## Get origin stage name
func _get_origin_name(origin: int) -> String:
	return GameConfig.get_stage_name(origin)


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect signals to prevent memory leaks
	if cancel_btn and cancel_btn.pressed.is_connected(_on_cancel_pressed):
		cancel_btn.pressed.disconnect(_on_cancel_pressed)

	if close_button and close_button.pressed.is_connected(_on_cancel_pressed):
		close_button.pressed.disconnect(_on_cancel_pressed)

	if confirm_btn and confirm_btn.pressed.is_connected(_on_confirm_pressed):
		confirm_btn.pressed.disconnect(_on_confirm_pressed)

	if EventBus and EventBus.ui_evolution_menu_closed.is_connected(_on_external_close):
		EventBus.ui_evolution_menu_closed.disconnect(_on_external_close)

	# Clear references
	_current_tower = null
	_selected_path = null
	_selected_card = null
	_evolution_system = null
