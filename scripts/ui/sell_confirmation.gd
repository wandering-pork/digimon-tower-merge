extends PanelContainer
## Sell Confirmation Dialog - Confirms tower sell action with value display.
## Shows tower info and sell value before confirming deletion.

signal sell_confirmed(tower: DigimonTower)
signal sell_cancelled()

## Tower to be sold
var _tower_to_sell: DigimonTower = null

## Economy system reference
var _economy_system: EconomySystem = null

## Grid manager reference for removal
var _grid_manager: GridManager = null

## UI Node references
@onready var title_label: Label = $MarginContainer/VBoxContainer/Title
@onready var tower_sprite: TextureRect = $MarginContainer/VBoxContainer/TowerInfo/TowerSprite
@onready var tower_name: Label = $MarginContainer/VBoxContainer/TowerInfo/Details/TowerName
@onready var tower_level: Label = $MarginContainer/VBoxContainer/TowerInfo/Details/TowerLevel
@onready var tower_dp: Label = $MarginContainer/VBoxContainer/TowerInfo/Details/TowerDP
@onready var sell_value: Label = $MarginContainer/VBoxContainer/SellValue
@onready var warning_label: Label = $MarginContainer/VBoxContainer/Warning
@onready var confirm_btn: Button = $MarginContainer/VBoxContainer/ButtonContainer/ConfirmBtn
@onready var cancel_btn: Button = $MarginContainer/VBoxContainer/ButtonContainer/CancelBtn


func _ready() -> void:
	# Connect button signals
	confirm_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Start hidden
	visible = false


## Set economy system reference
func set_economy_system(system: EconomySystem) -> void:
	_economy_system = system


## Set grid manager reference
func set_grid_manager(manager: GridManager) -> void:
	_grid_manager = manager


## Open the confirmation dialog for a tower
func show_for_tower(tower: DigimonTower) -> void:
	if not tower or not tower.digimon_data:
		return

	_tower_to_sell = tower
	_update_display()
	visible = true

	# Bring to front
	move_to_front()


## Close the dialog
func close() -> void:
	_tower_to_sell = null
	visible = false


## Update all display elements
func _update_display() -> void:
	if not _tower_to_sell or not _tower_to_sell.digimon_data:
		return

	var data = _tower_to_sell.digimon_data

	# Update tower info
	tower_name.text = data.digimon_name
	tower_level.text = "Level %d | %s" % [_tower_to_sell.current_level, data.get_stage_name()]
	tower_dp.text = "DP: %d | Origin: %s" % [
		_tower_to_sell.current_dp,
		_get_origin_name(_tower_to_sell.origin_stage)
	]

	# Update sprite if available
	_update_sprite()

	# Update sell value
	var value = 0
	if _economy_system:
		value = _economy_system.get_sell_value(_tower_to_sell)
	else:
		# Fallback calculation (50% of investment)
		var investment = _tower_to_sell.get("total_investment")
		if investment:
			value = int(investment * 0.5)

	sell_value.text = "Sell Value: %d DB" % value

	# Update warning for high-value towers
	if _tower_to_sell.current_dp > 0 or _tower_to_sell.digimon_data.stage >= DigimonData.Stage.CHAMPION:
		warning_label.text = "WARNING: This Digimon has significant progress!"
		warning_label.add_theme_color_override("font_color", Color.RED)
	else:
		warning_label.text = "This cannot be undone!"
		warning_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))


## Update the tower sprite display
func _update_sprite() -> void:
	if not _tower_to_sell or not _tower_to_sell.digimon_data:
		return

	var data = _tower_to_sell.digimon_data
	var sprite_path = "res://assets/sprites/digimon/%s.png" % data.digimon_name.to_lower()

	if ResourceLoader.exists(sprite_path):
		tower_sprite.texture = load(sprite_path)
	else:
		# Create placeholder color based on attribute
		tower_sprite.texture = null
		tower_sprite.modulate = _get_attribute_color(data.attribute)


## Handle confirm button press
func _on_confirm_pressed() -> void:
	AudioManager.play_sfx("button_click")

	if not _tower_to_sell:
		close()
		return

	var tower = _tower_to_sell
	var grid_pos = tower.grid_position

	# Play sell sound
	AudioManager.play_sfx("tower_sell")

	# Sell the tower and get value
	var value = 0
	if _economy_system:
		value = _economy_system.sell_tower(tower)
	else:
		# Fallback - add value directly
		var investment = tower.get("total_investment")
		if investment:
			value = int(investment * 0.5)
		if GameManager:
			GameManager.add_digibytes(value)

	# Remove from grid
	if _grid_manager:
		_grid_manager.remove_tower(grid_pos)

	# Deselect the tower
	if EventBus:
		EventBus.tower_selected.emit(null)

	# Remove tower from scene
	tower.queue_free()

	# Emit signal
	sell_confirmed.emit(tower)

	# Close dialog
	close()


## Handle cancel button press
func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("button_click")
	sell_cancelled.emit()
	close()


## Get origin stage name
func _get_origin_name(origin: int) -> String:
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


## Handle input for closing with escape
func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect button signals
	if confirm_btn and confirm_btn.pressed.is_connected(_on_confirm_pressed):
		confirm_btn.pressed.disconnect(_on_confirm_pressed)

	if cancel_btn and cancel_btn.pressed.is_connected(_on_cancel_pressed):
		cancel_btn.pressed.disconnect(_on_cancel_pressed)

	# Clear references
	_tower_to_sell = null
	_economy_system = null
	_grid_manager = null
