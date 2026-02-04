class_name CombatProjectileFactory
extends RefCounted
## Factory for creating and configuring projectiles.
## Handles projectile spawning, type configuration, and visual setup.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const Projectile = preload("res://scripts/combat/projectile.gd")
const AttackTypes = preload("res://scripts/combat/attack_types.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")

## Projectile scene for instantiation
const PROJECTILE_SCENE_PATH = "res://scenes/combat/projectile.tscn"

## Tile size in pixels (for range calculations)
const TILE_SIZE: float = 64.0

## Cache for projectile scene
var _projectile_scene: PackedScene = null

## Reference to scene tree for adding projectiles
var _scene_tree: SceneTree = null

## Reference to current level (for fallback parenting)
var _current_level: Node = null


## Initialize the factory with scene tree reference
func initialize(scene_tree: SceneTree) -> void:
	_scene_tree = scene_tree
	_projectile_scene = load(PROJECTILE_SCENE_PATH)
	if not _projectile_scene:
		ErrorHandler.log_error("CombatProjectileFactory", "Failed to load projectile scene")


## Set current level reference for projectile parenting
func set_current_level(level: Node) -> void:
	_current_level = level


## Create and configure a projectile from tower to enemy
## from: The attacking tower
## to: The target enemy
## damage: Base damage (before modifiers)
## attack_type: Type of attack (from AttackTypes.Type)
## Returns: The created projectile, or null on failure
func create_projectile(
	from: Node,
	to: Node,
	damage: int,
	attack_type: int = AttackTypes.Type.SINGLE
) -> Projectile:
	if not is_instance_valid(from) or not is_instance_valid(to):
		return null

	if not _projectile_scene:
		_projectile_scene = load(PROJECTILE_SCENE_PATH)
		if not _projectile_scene:
			ErrorHandler.log_error("CombatProjectileFactory", "Failed to load projectile scene")
			return null

	# Create projectile instance
	var projectile: Projectile = _projectile_scene.instantiate()
	if not projectile:
		return null

	# Get spawn position
	var spawn_pos = _get_spawn_position(from)
	projectile.global_position = spawn_pos

	# Get damage type from source
	var damage_type = get_damage_type(from)

	# Convert AttackTypes.Type to Projectile.AttackType
	var proj_attack_type = convert_attack_type(attack_type)

	# Setup projectile
	projectile.setup(from, to, damage, proj_attack_type, 400.0, damage_type)

	# Configure special attack types
	_configure_attack_type(projectile, from, attack_type)

	# Add visual based on damage type
	set_projectile_color(projectile, damage_type)

	# Add to scene
	add_projectile_to_scene(projectile)

	return projectile


## Get spawn position for projectile (effect spawn point or global position)
func _get_spawn_position(from: Node) -> Vector2:
	var spawn_pos = from.global_position
	if "effect_spawn" in from and from.effect_spawn:
		spawn_pos = from.effect_spawn.global_position
	return spawn_pos


## Configure projectile based on attack type
func _configure_attack_type(projectile: Projectile, source: Node, attack_type: int) -> void:
	match attack_type:
		AttackTypes.Type.PIERCE:
			projectile.set_pierce(get_pierce_count(source))
		AttackTypes.Type.CHAIN:
			projectile.set_chain(get_chain_count(source), 0.5, 128.0)
		AttackTypes.Type.AOE:
			projectile.set_aoe(get_aoe_radius(source), 0.5)
		AttackTypes.Type.SPLASH:
			projectile.set_splash(get_splash_radius(source), 0.5)


## Convert AttackTypes.Type to Projectile.AttackType
func convert_attack_type(attack_type: int) -> int:
	match attack_type:
		AttackTypes.Type.SINGLE: return Projectile.AttackType.SINGLE
		AttackTypes.Type.PIERCE: return Projectile.AttackType.PIERCE
		AttackTypes.Type.CHAIN: return Projectile.AttackType.CHAIN
		AttackTypes.Type.AOE: return Projectile.AttackType.AOE
		AttackTypes.Type.SPLASH: return Projectile.AttackType.SPLASH
		AttackTypes.Type.TRACKING: return Projectile.AttackType.TRACKING
		_: return Projectile.AttackType.SINGLE


## Get damage type from source tower
func get_damage_type(source: Node) -> String:
	if "digimon_data" in source and source.digimon_data:
		var data = source.digimon_data
		if data.effect_type != "":
			return data.effect_type.to_lower()
		match data.family:
			DigimonData.Family.DRAGONS_ROAR: return "fire"
			DigimonData.Family.DEEP_SAVERS: return "water"
			DigimonData.Family.VIRUS_BUSTERS: return "holy"
			DigimonData.Family.NIGHTMARE_SOLDIERS: return "dark"
			DigimonData.Family.METAL_EMPIRE: return "electric"
			DigimonData.Family.WIND_GUARDIANS: return "wind"
	return "physical"


## Get pierce count based on source tower stats
func get_pierce_count(source: Node) -> int:
	var count = 3
	if "current_level" in source:
		count = 2 + int(source.current_level / 10)
	if "current_dp" in source:
		count += source.current_dp
	return mini(count, 10)


## Get chain count based on source tower stats
func get_chain_count(source: Node) -> int:
	var count = 3
	if "current_level" in source:
		count = 2 + int(source.current_level / 15)
	if "current_dp" in source:
		count += int(source.current_dp / 2)
	return mini(count, 8)


## Get AoE radius based on source tower stats
func get_aoe_radius(source: Node) -> float:
	var radius = 64.0
	if "current_level" in source:
		radius = 48.0 + source.current_level * 2
	if "current_dp" in source:
		radius += source.current_dp * 4
	return minf(radius, 160.0)


## Get splash radius based on source tower stats
func get_splash_radius(source: Node) -> float:
	var radius = 48.0
	if "current_level" in source:
		radius = 32.0 + source.current_level * 1.5
	if "current_dp" in source:
		radius += source.current_dp * 3
	return minf(radius, 120.0)


## Set projectile color based on damage type
func set_projectile_color(projectile: Projectile, damage_type: String) -> void:
	if not projectile or not projectile.sprite:
		return

	var color: Color
	match damage_type:
		"fire": color = Color.ORANGE_RED
		"water": color = Color.DEEP_SKY_BLUE
		"holy": color = Color.GOLD
		"dark": color = Color.DARK_VIOLET
		"electric": color = Color.YELLOW
		"wind": color = Color.LIGHT_GREEN
		"ice": color = Color.CYAN
		"poison": color = Color.PURPLE
		_: color = Color.WHITE

	projectile.sprite.modulate = color


## Add projectile to scene tree
func add_projectile_to_scene(projectile: Projectile) -> void:
	if not _scene_tree:
		ErrorHandler.log_error("CombatProjectileFactory", "Scene tree not initialized")
		return

	# Try to find a projectile container first
	var container = _scene_tree.get_first_node_in_group("projectile_container")
	if container:
		container.add_child(projectile)
	elif _current_level:
		_current_level.add_child(projectile)
	else:
		# Fallback to adding to root
		_scene_tree.current_scene.add_child(projectile)


## Get color for a damage type (utility for external use)
func get_damage_type_color(damage_type: String) -> Color:
	match damage_type:
		"fire": return Color.ORANGE_RED
		"water": return Color.DEEP_SKY_BLUE
		"holy": return Color.GOLD
		"dark": return Color.DARK_VIOLET
		"electric": return Color.YELLOW
		"wind": return Color.LIGHT_GREEN
		"ice": return Color.CYAN
		"poison": return Color.PURPLE
		_: return Color.WHITE
