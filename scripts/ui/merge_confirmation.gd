extends Control
## Merge confirmation dialog UI.
## Shows a preview of the merge result and asks for confirmation.

signal confirmed(source: DigimonTower, target: DigimonTower)
signal cancelled()

## Source tower (will be sacrificed)
var _source: DigimonTower = null

## Target tower (will survive and gain DP)
var _target: DigimonTower = null

## Merge preview data
var _preview: Dictionary = {}

## UI Node references
@onready var source_sprite: ColorRect = $MainVBox/Preview/SourcePreview/SourceSprite
@onready var source_name: Label = $MainVBox/Preview/SourcePreview/SourceName
@onready var source_dp: Label = $MainVBox/Preview/SourcePreview/SourceDP
@onready var source_origin: Label = $MainVBox/Preview/SourcePreview/SourceOrigin

@onready var target_sprite: ColorRect = $MainVBox/Preview/TargetPreview/TargetSprite
@onready var target_name: Label = $MainVBox/Preview/TargetPreview/TargetName
@onready var target_dp: Label = $MainVBox/Preview/TargetPreview/TargetDP
@onready var target_origin: Label = $MainVBox/Preview/TargetPreview/TargetOrigin

@onready var result_sprite: ColorRect = $MainVBox/Preview/ResultPreview/ResultSprite
@onready var result_name: Label = $MainVBox/Preview/ResultPreview/ResultName
@onready var result_dp: Label = $MainVBox/Preview/ResultPreview/ResultDP
@onready var result_origin: Label = $MainVBox/Preview/ResultPreview/ResultOrigin

@onready var warning_label: Label = $MainVBox/Warning
@onready var confirm_btn: Button = $MainVBox/Buttons/ConfirmBtn
@onready var cancel_btn: Button = $MainVBox/Buttons/CancelBtn


func _ready() -> void:
	# Connect button signals
	confirm_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

	# Start hidden
	visible = false


## Show the merge confirmation dialog
func show_confirmation(source: DigimonTower, target: DigimonTower, preview: Dictionary) -> void:
	if not source or not target:
		return

	_source = source
	_target = target
	_preview = preview

	# Update source preview
	_update_tower_display(
		source,
		source_sprite,
		source_name,
		source_dp,
		source_origin
	)

	# Update target preview
	_update_tower_display(
		target,
		target_sprite,
		target_name,
		target_dp,
		target_origin
	)

	# Update result preview
	_update_result_display()

	# Show warning
	warning_label.text = "%s will be consumed!" % source.digimon_data.digimon_name

	# Show the dialog
	visible = true
	move_to_front()


## Update a tower's display section
func _update_tower_display(
	tower: DigimonTower,
	sprite: ColorRect,
	name_lbl: Label,
	dp_lbl: Label,
	origin_lbl: Label
) -> void:
	if not tower or not tower.digimon_data:
		return

	# Set sprite color based on attribute
	sprite.color = _get_attribute_color(tower.digimon_data.attribute)

	# Set name
	name_lbl.text = tower.digimon_data.digimon_name

	# Set DP
	dp_lbl.text = "DP: %d" % tower.current_dp

	# Set Origin
	origin_lbl.text = "Origin: %s" % _get_origin_name(tower.origin_stage)


## Update the result preview display
func _update_result_display() -> void:
	if not _preview.get("valid", false):
		return

	# Result keeps target's name and attribute
	result_sprite.color = _get_attribute_color(_target.digimon_data.attribute)
	result_name.text = _preview.get("survivor_name", "???")

	# Show DP change
	var new_dp = _preview.get("new_dp", 0)
	var dp_change = new_dp - _preview.get("current_dp", 0)
	result_dp.text = "DP: %d (+%d)" % [new_dp, dp_change]

	# Show Origin (might change if source has better origin)
	var new_origin = _preview.get("new_origin", 0)
	var origin_changed = new_origin != _preview.get("current_origin", 0)
	if origin_changed:
		result_origin.text = "Origin: %s (improved!)" % _preview.get("origin_name_after", "???")
		result_origin.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		result_origin.text = "Origin: %s" % _preview.get("origin_name_after", "???")

	# Show level cap change if significant
	var cap_before = _preview.get("level_cap_before", 0)
	var cap_after = _preview.get("level_cap_after", 0)
	if cap_after > cap_before:
		warning_label.text = "%s will be consumed! (Level cap +%d)" % [
			_source.digimon_data.digimon_name,
			cap_after - cap_before
		]


## Get color based on attribute
func _get_attribute_color(attribute: DigimonData.Attribute) -> Color:
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


## Handle confirm button press
func _on_confirm_pressed() -> void:
	var source = _source
	var target = _target
	hide()
	confirmed.emit(source, target)


## Handle cancel button press
func _on_cancel_pressed() -> void:
	hide()
	cancelled.emit()


## Hide the dialog and clear state
func hide() -> void:
	visible = false
	_source = null
	_target = null
	_preview = {}


## Check if the dialog is showing
func is_showing() -> bool:
	return visible


## Get the current source tower
func get_source() -> DigimonTower:
	return _source


## Get the current target tower
func get_target() -> DigimonTower:
	return _target


## Cleanup when removed from scene tree
func _exit_tree() -> void:
	# Disconnect button signals
	if confirm_btn and confirm_btn.pressed.is_connected(_on_confirm_pressed):
		confirm_btn.pressed.disconnect(_on_confirm_pressed)

	if cancel_btn and cancel_btn.pressed.is_connected(_on_cancel_pressed):
		cancel_btn.pressed.disconnect(_on_cancel_pressed)

	# Clear references
	_source = null
	_target = null
	_preview = {}
