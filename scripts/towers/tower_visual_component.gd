class_name TowerVisualComponent
extends Node
## Handles all visual-related logic for DigimonTower.
## Includes sprite management, animations, range indicators, and flash effects.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const DigimonData = preload("res://scripts/data/digimon_data.gd")

## Reference to parent tower
var tower: Node  # DigimonTower - avoid circular dependency

## Node references (set during setup)
var sprite: Sprite2D
var range_indicator: Sprite2D
var range_shape: CollisionShape2D
var flash_timer: Timer

## Flash state
var _original_modulate: Color = Color.WHITE
var _is_selected: bool = false


func _init() -> void:
	name = "VisualComponent"


## Initialize the visual component with tower references
func setup(parent_tower: Node) -> void:  # DigimonTower - avoid circular dependency
	tower = parent_tower
	sprite = tower.sprite
	range_indicator = tower.range_indicator
	range_shape = tower.range_shape
	flash_timer = tower.flash_timer

	# Connect flash timer
	if flash_timer:
		flash_timer.timeout.connect(_on_flash_timer_timeout)


## Initialize visuals from digimon data
func initialize_from_data() -> void:
	if not tower.digimon_data:
		return

	# Load sprite texture if available
	var sprite_path = "res://assets/sprites/digimon/%s.png" % tower.digimon_data.digimon_name.to_lower()
	if ResourceLoader.exists(sprite_path):
		sprite.texture = load(sprite_path)
	else:
		# Use placeholder - create a colored rect based on attribute
		_create_placeholder_sprite()

	# Update range indicator and collision
	update_range_display()


## Create a simple colored placeholder based on attribute
func _create_placeholder_sprite() -> void:
	if not tower.digimon_data:
		return

	var img = Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color: Color

	match tower.digimon_data.attribute:
		DigimonData.Attribute.VACCINE:
			color = Color(0.2, 0.6, 1.0)  # Blue
		DigimonData.Attribute.DATA:
			color = Color(0.2, 0.8, 0.2)  # Green
		DigimonData.Attribute.VIRUS:
			color = Color(0.8, 0.2, 0.2)  # Red
		DigimonData.Attribute.FREE:
			color = Color(0.8, 0.8, 0.2)  # Yellow
		_:
			color = Color(0.5, 0.5, 0.5)  # Gray

	# Fill with color and create border
	for x in range(32):
		for y in range(32):
			if x < 2 or x > 29 or y < 2 or y > 29:
				img.set_pixel(x, y, color.darkened(0.3))
			else:
				img.set_pixel(x, y, color)

	# Add stage indicator (darker center for higher stages)
	var center_size = 8 + tower.digimon_data.stage * 2
	var half = center_size / 2
	for x in range(16 - half, 16 + half):
		for y in range(16 - half, 16 + half):
			img.set_pixel(x, y, color.lightened(0.3))

	var tex = ImageTexture.create_from_image(img)
	sprite.texture = tex


## Update range indicator and collision shape based on digimon data
func update_range_display() -> void:
	if not tower.digimon_data:
		return

	# Update range area collision shape
	var range_pixels = tower.digimon_data.attack_range * GameConfig.TILE_SIZE
	if range_shape and range_shape.shape is CircleShape2D:
		(range_shape.shape as CircleShape2D).radius = range_pixels

	# Update range indicator scale
	if range_indicator:
		# Scale based on attack range (assuming base indicator is for 1 tile)
		var scale_factor = tower.digimon_data.attack_range * 2
		range_indicator.scale = Vector2(scale_factor, scale_factor)


## Show range indicator circle
func show_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = true


## Hide range indicator circle
func hide_range_indicator() -> void:
	if range_indicator:
		range_indicator.visible = false


## Flash the sprite when attacking
func flash_on_attack() -> void:
	if sprite and flash_timer:
		_original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE * 1.5
		flash_timer.start()


## Update selection state (affects flash restoration and sprite modulation)
func set_selected(selected: bool) -> void:
	_is_selected = selected
	if sprite:
		sprite.modulate = Color(1.2, 1.2, 1.2) if selected else Color.WHITE


## Get whether currently selected
func is_selected() -> bool:
	return _is_selected


func _on_flash_timer_timeout() -> void:
	if sprite:
		sprite.modulate = _original_modulate if not _is_selected else Color(1.2, 1.2, 1.2)


func _exit_tree() -> void:
	# Disconnect flash timer
	if flash_timer and flash_timer.timeout.is_connected(_on_flash_timer_timeout):
		flash_timer.timeout.disconnect(_on_flash_timer_timeout)

	# Stop timer
	if flash_timer:
		flash_timer.stop()

	# Null references
	tower = null
	sprite = null
	range_indicator = null
	range_shape = null
	flash_timer = null
