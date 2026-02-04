class_name AttackTypes
extends RefCounted
## Defines different attack behaviors for towers.
## Handles creating projectiles and executing various attack patterns.

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const Projectile = preload("res://scripts/combat/projectile.gd")
const DamageCalculator = preload("res://scripts/combat/damage_calculator.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")

## Attack type enumeration matching Projectile.AttackType
enum Type {
	SINGLE,    ## Single target, one projectile
	PIERCE,    ## Projectile passes through multiple enemies
	CHAIN,     ## Damage chains to nearby enemies
	AOE,       ## Area of effect damage on impact
	MULTI_HIT, ## Multiple projectiles to different targets
	SPLASH,    ## Main target + reduced damage to nearby
	TRACKING,  ## Homing projectile
	INSTANT    ## Direct damage, no projectile
}

## Projectile scene path
const PROJECTILE_SCENE_PATH = "res://scenes/combat/projectile.tscn"

## Cached projectile scene
static var _projectile_scene: PackedScene = null


## Perform an attack from tower to target
## tower: The attacking tower
## target: The primary target enemy
## attack_type: The type of attack to perform
## Returns: Array of created projectiles (empty for instant attacks)
static func perform_attack(tower: Node, target: Node, attack_type: Type) -> Array:
	if not is_instance_valid(tower) or not is_instance_valid(target):
		return []

	var projectiles: Array = []

	match attack_type:
		Type.SINGLE:
			projectiles = _attack_single(tower, target)
		Type.PIERCE:
			projectiles = _attack_pierce(tower, target)
		Type.CHAIN:
			projectiles = _attack_chain(tower, target)
		Type.AOE:
			projectiles = _attack_aoe(tower, target)
		Type.MULTI_HIT:
			projectiles = _attack_multi_hit(tower, target)
		Type.SPLASH:
			projectiles = _attack_splash(tower, target)
		Type.TRACKING:
			projectiles = _attack_tracking(tower, target)
		Type.INSTANT:
			_attack_instant(tower, target)

	return projectiles


## Create a single projectile attack
static func _attack_single(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.SINGLE
		return [projectile]
	return []


## Create a piercing projectile attack
static func _attack_pierce(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.PIERCE
		# Configure pierce based on tower level/DP
		var pierce_count = 3
		if "current_level" in tower:
			pierce_count = 2 + int(tower.current_level / 10)
		if "current_dp" in tower:
			pierce_count += tower.current_dp
		projectile.set_pierce(mini(pierce_count, 10))
		return [projectile]
	return []


## Create a chain lightning attack
static func _attack_chain(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.CHAIN
		# Configure chain based on tower level/DP
		var chain_count = 3
		if "current_level" in tower:
			chain_count = 2 + int(tower.current_level / 15)
		if "current_dp" in tower:
			chain_count += int(tower.current_dp / 2)
		projectile.set_chain(mini(chain_count, 8), 0.5, 128.0)
		return [projectile]
	return []


## Create an AoE projectile attack
static func _attack_aoe(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.AOE
		# Configure AoE based on tower level/DP
		var radius = 64.0
		if "current_level" in tower:
			radius = 48.0 + tower.current_level * 2
		if "current_dp" in tower:
			radius += tower.current_dp * 4
		projectile.set_aoe(minf(radius, 160.0), 0.5)
		return [projectile]
	return []


## Create multiple projectiles to different targets
static func _attack_multi_hit(tower: Node, target: Node) -> Array:
	var projectiles: Array = []

	# Determine number of targets
	var hit_count = 3
	if "current_level" in tower:
		hit_count = 2 + int(tower.current_level / 20)
	if "current_dp" in tower:
		hit_count += int(tower.current_dp / 3)
	hit_count = mini(hit_count, 8)

	# Get enemies in range
	var enemies = _get_enemies_in_range(tower)
	if enemies.is_empty():
		return []

	# Limit to available targets
	var targets_to_hit = mini(hit_count, enemies.size())

	# Sort by distance (closest first)
	enemies.sort_custom(func(a, b):
		var dist_a = tower.global_position.distance_squared_to(a.global_position)
		var dist_b = tower.global_position.distance_squared_to(b.global_position)
		return dist_a < dist_b
	)

	# Create projectile for each target
	for i in range(targets_to_hit):
		var proj = _create_projectile(tower, enemies[i])
		if proj:
			proj.attack_type = Projectile.AttackType.SINGLE
			projectiles.append(proj)

	return projectiles


## Create a splash damage attack
static func _attack_splash(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.SPLASH
		# Configure splash based on tower level/DP
		var radius = 48.0
		var damage_percent = 0.5
		if "current_level" in tower:
			radius = 32.0 + tower.current_level * 1.5
			damage_percent = 0.4 + tower.current_level * 0.01
		if "current_dp" in tower:
			radius += tower.current_dp * 3
			damage_percent += tower.current_dp * 0.02
		projectile.set_splash(minf(radius, 120.0), minf(damage_percent, 0.75))
		return [projectile]
	return []


## Create a tracking/homing projectile
static func _attack_tracking(tower: Node, target: Node) -> Array:
	var projectile = _create_projectile(tower, target)
	if projectile:
		projectile.attack_type = Projectile.AttackType.TRACKING
		# Tracking projectiles are slightly slower but always hit
		projectile.speed = 300.0
		return [projectile]
	return []


## Perform an instant direct damage attack (no projectile)
static func _attack_instant(tower: Node, target: Node) -> void:
	if not is_instance_valid(tower) or not is_instance_valid(target):
		return

	# Calculate damage directly
	var base_damage = _get_base_damage(tower)
	var damage_result = DamageCalculator.calculate_damage(tower, target, base_damage)

	# Apply damage
	if target.has_method("take_damage"):
		var damage_type = _get_damage_type(tower)
		target.take_damage(damage_result["damage"], tower, damage_type)

	# Show damage number
	var event_bus = Engine.get_singleton("EventBus") if Engine.has_singleton("EventBus") else null
	if not event_bus:
		event_bus = tower.get_node_or_null("/root/EventBus")
	if event_bus:
		event_bus.show_damage_number(
			target.global_position,
			damage_result["damage"],
			damage_result["is_critical"]
		)

	# Visual flash on tower
	if tower.has_method("flash_on_attack"):
		tower.flash_on_attack()

	# Apply status effect
	DamageCalculator.apply_effect(tower, target)


## Create a projectile from tower to target
static func _create_projectile(tower: Node, target: Node) -> Projectile:
	# Load scene if not cached
	if not _projectile_scene:
		_projectile_scene = load(PROJECTILE_SCENE_PATH)
		if not _projectile_scene:
			ErrorHandler.log_error("AttackTypes", "Failed to load projectile scene: " + PROJECTILE_SCENE_PATH)
			return null

	# Instance projectile
	var projectile: Projectile = _projectile_scene.instantiate()
	if not projectile:
		return null

	# Get spawn position
	var spawn_pos = tower.global_position
	if "effect_spawn" in tower and tower.effect_spawn:
		spawn_pos = tower.effect_spawn.global_position

	projectile.global_position = spawn_pos

	# Configure projectile
	var base_damage = _get_base_damage(tower)
	var damage_type = _get_damage_type(tower)
	var speed = _get_projectile_speed(tower)

	projectile.setup(tower, target, base_damage, Projectile.AttackType.SINGLE, speed, damage_type)

	# Set projectile color based on damage type
	_set_projectile_visual(projectile, damage_type)

	# Add to scene
	var combat_container = tower.get_tree().get_first_node_in_group("projectile_container")
	if combat_container:
		combat_container.add_child(projectile)
	else:
		tower.get_parent().add_child(projectile)

	return projectile


## Get base damage from tower
static func _get_base_damage(tower: Node) -> int:
	if "digimon_data" in tower and tower.digimon_data:
		return tower.digimon_data.base_damage
	return 10


## Get damage type from tower
static func _get_damage_type(tower: Node) -> String:
	if "digimon_data" in tower and tower.digimon_data:
		var data = tower.digimon_data
		if data.effect_type != "":
			return data.effect_type.to_lower()
		match data.family:
			DigimonData.Family.DRAGONS_ROAR:
				return "fire"
			DigimonData.Family.DEEP_SAVERS:
				return "water"
			DigimonData.Family.VIRUS_BUSTERS:
				return "holy"
			DigimonData.Family.NIGHTMARE_SOLDIERS:
				return "dark"
			DigimonData.Family.METAL_EMPIRE:
				return "electric"
			DigimonData.Family.WIND_GUARDIANS:
				return "wind"
			DigimonData.Family.JUNGLE_TROOPERS:
				return "nature"
	return "physical"


## Get projectile speed based on tower
static func _get_projectile_speed(tower: Node) -> float:
	var base_speed = 400.0
	if "digimon_data" in tower and tower.digimon_data:
		# Faster attack speed = slightly faster projectiles
		base_speed = 350.0 + tower.digimon_data.attack_speed * 50
	return base_speed


## Get enemies in tower's range
static func _get_enemies_in_range(tower: Node) -> Array:
	var enemies: Array = []

	# Try to get from tower's tracking
	if "_enemies_in_range" in tower:
		for enemy in tower._enemies_in_range:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemies.append(enemy)
		return enemies

	# Fallback: manual range check
	var all_enemies = tower.get_tree().get_nodes_in_group("enemies")
	var attack_range = 128.0  # Default

	if "digimon_data" in tower and tower.digimon_data:
		attack_range = tower.digimon_data.attack_range * 64  # Convert tiles to pixels

	var range_squared = attack_range * attack_range

	for enemy in all_enemies:
		if is_instance_valid(enemy) and not enemy.is_dead:
			var dist_squared = tower.global_position.distance_squared_to(enemy.global_position)
			if dist_squared <= range_squared:
				enemies.append(enemy)

	return enemies


## Set projectile visual based on damage type
static func _set_projectile_visual(projectile: Projectile, damage_type: String) -> void:
	if not projectile.sprite:
		return

	var color: Color

	match damage_type:
		"fire":
			color = Color.ORANGE_RED
		"water":
			color = Color.DEEP_SKY_BLUE
		"holy":
			color = Color.GOLD
		"dark":
			color = Color.DARK_VIOLET
		"electric":
			color = Color.YELLOW
		"wind":
			color = Color.LIGHT_GREEN
		"nature":
			color = Color.FOREST_GREEN
		"ice":
			color = Color.CYAN
		"poison":
			color = Color.PURPLE
		_:
			color = Color.WHITE

	projectile.sprite.modulate = color


## Get attack type based on Digimon family
static func get_family_attack_type(family: int) -> Type:
	match family:
		DigimonData.Family.DRAGONS_ROAR:
			return Type.AOE  # Artillery - explosive damage
		DigimonData.Family.NATURE_SPIRITS:
			return Type.SINGLE  # Balanced - standard attacks
		DigimonData.Family.VIRUS_BUSTERS:
			return Type.CHAIN  # Support/Magic - chain holy
		DigimonData.Family.NIGHTMARE_SOLDIERS:
			return Type.SPLASH  # Debuff - splash dark damage
		DigimonData.Family.METAL_EMPIRE:
			return Type.MULTI_HIT  # High-Tech - multiple targets
		DigimonData.Family.DEEP_SAVERS:
			return Type.SPLASH  # Splash/AoE - water splash
		DigimonData.Family.WIND_GUARDIANS:
			return Type.TRACKING  # Anti-Air - homing attacks
		DigimonData.Family.JUNGLE_TROOPERS:
			return Type.PIERCE  # Barracks - piercing attacks
		_:
			return Type.SINGLE


## Convert attack type to string for display
static func type_to_string(attack_type: Type) -> String:
	match attack_type:
		Type.SINGLE: return "Single Target"
		Type.PIERCE: return "Pierce"
		Type.CHAIN: return "Chain"
		Type.AOE: return "Area of Effect"
		Type.MULTI_HIT: return "Multi-Hit"
		Type.SPLASH: return "Splash"
		Type.TRACKING: return "Tracking"
		Type.INSTANT: return "Instant"
		_: return "Unknown"
