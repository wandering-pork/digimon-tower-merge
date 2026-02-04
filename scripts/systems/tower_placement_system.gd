class_name TowerPlacementSystem
extends Node2D
## Tower Placement System
##
## Handles drag-drop tower placement with ghost preview, cell highlighting,
## and visual feedback for valid/invalid positions.
##
## Usage:
##   1. Call start_placement() with spawn parameters to enter placement mode
##   2. Ghost tower follows mouse, cells highlight valid/invalid
##   3. Left-click places tower if valid and affordable
##   4. Right-click or ESC cancels placement mode

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonData = preload("res://scripts/data/digimon_data.gd")

# =============================================================================
# SIGNALS
# =============================================================================
signal placement_started(stage: int, attribute: int, cost: int)
signal placement_completed(grid_pos: Vector2i, stage: int, attribute: int, cost: int)
signal placement_cancelled()
signal position_invalid(grid_pos: Vector2i, reason: String)

# =============================================================================
# CONFIGURATION
# =============================================================================
## Colors for cell highlighting
const COLOR_VALID: Color = Color(0.2, 0.8, 0.2, 0.4)        # Green - can place
const COLOR_INVALID: Color = Color(0.8, 0.2, 0.2, 0.4)      # Red - cannot place
const COLOR_OCCUPIED: Color = Color(0.8, 0.6, 0.2, 0.4)     # Orange - tower present
const COLOR_PATH: Color = Color(0.4, 0.4, 0.4, 0.3)         # Gray - path tile

## Ghost preview transparency
const GHOST_ALPHA_VALID: float = 0.7
const GHOST_ALPHA_INVALID: float = 0.3

# =============================================================================
# STATE
# =============================================================================
## Whether placement mode is active
var _is_placing: bool = false

## Current spawn parameters
var _placement_stage: int = 0
var _placement_attribute: int = -1  # -1 means random
var _placement_cost: int = 0
var _placement_spawn_type: int = 0  # SpawnMenu.SpawnType

## Current hovered grid position
var _current_grid_pos: Vector2i = Vector2i(-1, -1)
var _last_valid_pos: Vector2i = Vector2i(-1, -1)

# =============================================================================
# REFERENCES
# =============================================================================
var _grid_manager: Node = null  # GridManager
var _spawn_system: Node = null  # SpawnSystem

## Visual components
var _ghost_sprite: Sprite2D = null
var _ghost_container: Node2D = null
var _cell_highlights: Dictionary = {}  # Vector2i -> ColorRect

## Cell size (must match GridManager.TILE_SIZE)
const CELL_SIZE: int = 64
const GRID_COLS: int = 8
const GRID_ROWS: int = 18

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	# Create containers for visual elements
	_setup_ghost_container()
	_setup_cell_highlights()

	# Connect to EventBus for spawn menu interactions
	if EventBus:
		EventBus.ui_spawn_menu_closed.connect(_on_spawn_menu_closed)


func _exit_tree() -> void:
	# Clean up visual elements
	_cleanup_highlights()
	_cleanup_ghost()

	# Disconnect signals
	if EventBus and EventBus.ui_spawn_menu_closed.is_connected(_on_spawn_menu_closed):
		EventBus.ui_spawn_menu_closed.disconnect(_on_spawn_menu_closed)

	# Clear references
	_grid_manager = null
	_spawn_system = null


## Handle spawn menu closed - cancel placement if active
func _on_spawn_menu_closed() -> void:
	if _is_placing:
		cancel_placement()


func _setup_ghost_container() -> void:
	_ghost_container = Node2D.new()
	_ghost_container.name = "GhostContainer"
	_ghost_container.z_index = 100  # Above other elements
	add_child(_ghost_container)

	_ghost_sprite = Sprite2D.new()
	_ghost_sprite.name = "GhostSprite"
	_ghost_sprite.visible = false
	_ghost_container.add_child(_ghost_sprite)


func _setup_cell_highlights() -> void:
	# Pre-create highlight rects for all cells (hidden by default)
	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var pos = Vector2i(col, row)
			var rect = ColorRect.new()
			rect.size = Vector2(CELL_SIZE - 2, CELL_SIZE - 2)
			rect.position = Vector2(col * CELL_SIZE + 1, row * CELL_SIZE + 1)
			rect.color = Color.TRANSPARENT
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block clicks
			rect.z_index = 50  # Below ghost but above grid
			rect.visible = false
			add_child(rect)
			_cell_highlights[pos] = rect


func _cleanup_highlights() -> void:
	for rect in _cell_highlights.values():
		if is_instance_valid(rect):
			rect.queue_free()
	_cell_highlights.clear()


func _cleanup_ghost() -> void:
	if _ghost_sprite and is_instance_valid(_ghost_sprite):
		_ghost_sprite.queue_free()
	if _ghost_container and is_instance_valid(_ghost_container):
		_ghost_container.queue_free()
	_ghost_sprite = null
	_ghost_container = null


# =============================================================================
# INITIALIZATION
# =============================================================================

## Initialize with required system references
func initialize(grid_manager: Node, spawn_system: Node) -> void:
	_grid_manager = grid_manager
	_spawn_system = spawn_system


# =============================================================================
# PLACEMENT MODE CONTROL
# =============================================================================

## Start placement mode with given spawn parameters
func start_placement(stage: int, attribute: int, cost: int, spawn_type: int = 0) -> void:
	if _is_placing:
		cancel_placement()

	_is_placing = true
	_placement_stage = stage
	_placement_attribute = attribute
	_placement_cost = cost
	_placement_spawn_type = spawn_type
	_current_grid_pos = Vector2i(-1, -1)
	_last_valid_pos = Vector2i(-1, -1)

	# Setup ghost preview
	_setup_ghost_preview()

	# Show cell highlights
	_update_all_cell_highlights()

	# Emit signal
	placement_started.emit(stage, attribute, cost)

	# Enable input processing
	set_process_input(true)


## Cancel current placement mode
func cancel_placement() -> void:
	if not _is_placing:
		return

	_is_placing = false
	_placement_stage = 0
	_placement_attribute = -1
	_placement_cost = 0

	# Hide visual elements
	_hide_all_highlights()
	_hide_ghost()

	# Disable input processing
	set_process_input(false)

	# Emit signal
	placement_cancelled.emit()


## Check if currently in placement mode
func is_placing() -> bool:
	return _is_placing


## Get current placement cost
func get_placement_cost() -> int:
	return _placement_cost


# =============================================================================
# INPUT HANDLING
# =============================================================================

func _input(event: InputEvent) -> void:
	if not _is_placing:
		return

	# Handle mouse movement - update ghost position
	if event is InputEventMouseMotion:
		_handle_mouse_move(event)

	# Handle mouse clicks
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_left_click(event)
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			cancel_placement()
			get_viewport().set_input_as_handled()

	# Handle keyboard
	elif event.is_action_pressed("ui_cancel"):
		cancel_placement()
		get_viewport().set_input_as_handled()


func _handle_mouse_move(event: InputEventMouseMotion) -> void:
	# Convert to world coordinates (accounting for camera/viewport)
	var world_pos = _get_world_mouse_position()
	var grid_pos = _world_to_grid(world_pos)

	# Update ghost position
	_update_ghost_position(world_pos, grid_pos)

	# Update current position tracking
	if grid_pos != _current_grid_pos:
		_current_grid_pos = grid_pos
		_update_current_cell_highlight(grid_pos)


func _handle_left_click(event: InputEventMouseButton) -> void:
	var world_pos = _get_world_mouse_position()
	var grid_pos = _world_to_grid(world_pos)

	# Check if position is valid
	if not _is_valid_grid_pos(grid_pos):
		position_invalid.emit(grid_pos, "Out of bounds")
		return

	if not _grid_manager:
		ErrorHandler.log_error("TowerPlacementSystem", "Grid manager not set")
		return

	if not _grid_manager.can_place_tower(grid_pos):
		var reason = _get_invalid_reason(grid_pos)
		position_invalid.emit(grid_pos, reason)
		_flash_invalid_cell(grid_pos)
		return

	# Check affordability
	if not GameManager.can_afford(_placement_cost):
		position_invalid.emit(grid_pos, "Cannot afford")
		_flash_invalid_cell(grid_pos)
		return

	# Valid placement - emit completion signal
	placement_completed.emit(grid_pos, _placement_stage, _placement_attribute, _placement_cost)

	# End placement mode
	cancel_placement()

	get_viewport().set_input_as_handled()


# =============================================================================
# VISUAL UPDATES
# =============================================================================

func _setup_ghost_preview() -> void:
	if not _ghost_sprite:
		return

	# Try to get a representative sprite for the stage
	var texture = _get_stage_preview_texture(_placement_stage)
	if texture:
		_ghost_sprite.texture = texture
	else:
		# Fallback: create a placeholder
		_create_placeholder_ghost()

	_ghost_sprite.modulate = Color(1, 1, 1, GHOST_ALPHA_VALID)
	_ghost_sprite.visible = true


func _get_stage_preview_texture(_stage: int) -> Texture2D:
	# Try to get a texture from spawn system
	if _spawn_system and _spawn_system.has_method("get_random_digimon_for_stage"):
		var data = _spawn_system.get_random_digimon_for_stage(_placement_stage, _placement_attribute)
		if data:
			# Look for sprite in resources
			var sprite_path = "res://assets/sprites/digimon/%s.png" % data.digimon_name.to_lower()
			if ResourceLoader.exists(sprite_path):
				return load(sprite_path)

	# Fallback to stage-specific placeholder
	var placeholder_path = "res://assets/sprites/ui/tower_placeholder.png"
	if ResourceLoader.exists(placeholder_path):
		return load(placeholder_path)

	return null


func _create_placeholder_ghost() -> void:
	# Create a simple colored rectangle as placeholder
	var img = Image.create(CELL_SIZE - 8, CELL_SIZE - 8, false, Image.FORMAT_RGBA8)
	var color = _get_attribute_color(_placement_attribute)
	img.fill(color)
	_ghost_sprite.texture = ImageTexture.create_from_image(img)


func _get_attribute_color(attribute: int) -> Color:
	match attribute:
		DigimonData.Attribute.VACCINE:
			return Color(0.2, 0.5, 0.9, 1.0)  # Blue
		DigimonData.Attribute.DATA:
			return Color(0.9, 0.8, 0.2, 1.0)  # Yellow
		DigimonData.Attribute.VIRUS:
			return Color(0.6, 0.2, 0.8, 1.0)  # Purple
		DigimonData.Attribute.FREE:
			return Color(0.5, 0.5, 0.5, 1.0)  # Gray
		_:
			return Color(0.3, 0.3, 0.3, 1.0)  # Dark gray for random


func _update_ghost_position(world_pos: Vector2, grid_pos: Vector2i) -> void:
	if not _ghost_sprite:
		return

	# Snap to grid center
	var snapped_pos = _grid_to_world(grid_pos)
	_ghost_sprite.position = snapped_pos

	# Update ghost appearance based on validity
	var is_valid = _is_valid_grid_pos(grid_pos) and _grid_manager and _grid_manager.can_place_tower(grid_pos)
	var can_afford = GameManager.can_afford(_placement_cost)

	if is_valid and can_afford:
		_ghost_sprite.modulate = Color(0.5, 1, 0.5, GHOST_ALPHA_VALID)
	else:
		_ghost_sprite.modulate = Color(1, 0.5, 0.5, GHOST_ALPHA_INVALID)


func _hide_ghost() -> void:
	if _ghost_sprite:
		_ghost_sprite.visible = false


func _update_all_cell_highlights() -> void:
	if not _grid_manager:
		return

	for col in range(GRID_COLS):
		for row in range(GRID_ROWS):
			var pos = Vector2i(col, row)
			_update_cell_highlight(pos)


func _update_cell_highlight(grid_pos: Vector2i) -> void:
	if not _cell_highlights.has(grid_pos):
		return

	var rect = _cell_highlights[grid_pos]
	if not _grid_manager:
		rect.visible = false
		return

	# Determine cell type and set color
	if _grid_manager.can_place_tower(grid_pos):
		rect.color = COLOR_VALID
		rect.visible = true
	elif _grid_manager.get_tower_at(grid_pos) != null:
		rect.color = COLOR_OCCUPIED
		rect.visible = true
	elif _grid_manager.is_path_tile(grid_pos):
		rect.color = COLOR_PATH
		rect.visible = true
	else:
		rect.color = COLOR_INVALID
		rect.visible = true


func _update_current_cell_highlight(grid_pos: Vector2i) -> void:
	# Could add special highlighting for currently hovered cell
	# For now, the ghost preview handles this
	pass


func _hide_all_highlights() -> void:
	for rect in _cell_highlights.values():
		if is_instance_valid(rect):
			rect.visible = false


func _flash_invalid_cell(grid_pos: Vector2i) -> void:
	if not _cell_highlights.has(grid_pos):
		return

	var rect = _cell_highlights[grid_pos]
	var original_color = rect.color

	# Flash red
	rect.color = Color(1, 0, 0, 0.6)

	# Create tween to restore
	var tween = create_tween()
	tween.tween_property(rect, "color", original_color, 0.2)


# =============================================================================
# COORDINATE HELPERS
# =============================================================================

func _get_world_mouse_position() -> Vector2:
	return get_global_mouse_position()


func _world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / CELL_SIZE),
		int(world_pos.y / CELL_SIZE)
	)


func _grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE + CELL_SIZE / 2.0,
		grid_pos.y * CELL_SIZE + CELL_SIZE / 2.0
	)


func _is_valid_grid_pos(grid_pos: Vector2i) -> bool:
	return (
		grid_pos.x >= 0 and grid_pos.x < GRID_COLS and
		grid_pos.y >= 0 and grid_pos.y < GRID_ROWS
	)


func _get_invalid_reason(grid_pos: Vector2i) -> String:
	if not _grid_manager:
		return "System error"

	if not _is_valid_grid_pos(grid_pos):
		return "Out of bounds"

	if _grid_manager.get_tower_at(grid_pos) != null:
		return "Tower already placed"

	if _grid_manager.is_path_tile(grid_pos):
		return "Cannot place on path"

	return "Invalid position"
