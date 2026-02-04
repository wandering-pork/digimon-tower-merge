class_name TowerCombatComponent
extends Node
## Handles all combat-related logic for DigimonTower.
## Includes targeting, attacking, damage calculation, and status effects.
##
## TODO: [DOCUMENTATION] Document calculate_damage() method with formula explanation
## Should include: base damage, level scaling, DP scaling, attribute multipliers
## See: docs/IMPLEMENTATION_TODO.md

# =============================================================================
# PRELOADED DEPENDENCIES
# =============================================================================
const Targeting = preload("res://scripts/combat/targeting.gd")
const AttackTypes = preload("res://scripts/combat/attack_types.gd")
const DamageCalculator = preload("res://scripts/combat/damage_calculator.gd")
const DigimonData = preload("res://scripts/data/digimon_data.gd")

signal attack_started(target: Node2D)
signal attack_hit(target: Node2D, damage: float, is_critical: bool)
signal target_changed(new_target: Node2D)

## Reference to parent tower
var tower: Node  # DigimonTower - avoid circular dependency

## Combat state
var _target: Node2D = null
var _enemies_in_range: Array[Node2D] = []

## Targeting priority (can be changed by player)
var targeting_priority: Targeting.Priority = Targeting.Priority.FIRST

## Timer reference (set by tower)
var attack_timer: Timer

## Selection state (for flash restoration)
var _is_selected: bool = false


func _init() -> void:
	name = "CombatComponent"


## Initialize the combat component with tower references
func setup(parent_tower: Node) -> void:  # DigimonTower - avoid circular dependency
	tower = parent_tower
	attack_timer = tower.attack_timer

	# Connect timer signal
	attack_timer.timeout.connect(_on_attack_timer_timeout)

	# Connect range area signals
	if tower.range_area:
		tower.range_area.body_entered.connect(_on_enemy_entered_range)
		tower.range_area.body_exited.connect(_on_enemy_exited_range)
		tower.range_area.area_entered.connect(_on_area_entered_range)
		tower.range_area.area_exited.connect(_on_area_exited_range)


## Get the current target
func get_target() -> Node2D:
	return _target


## Get enemies currently in range
func get_enemies_in_range() -> Array[Node2D]:
	return _enemies_in_range


## Flash the sprite when attacking (delegates to visual component)
func flash_on_attack() -> void:
	if tower and tower.visual:
		tower.visual.flash_on_attack()


## Update selection state
func set_selected(selected: bool) -> void:
	_is_selected = selected


func _on_attack_timer_timeout() -> void:
	_perform_attack()


func _on_enemy_entered_range(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		_enemies_in_range.append(body)
		_check_start_attacking()


func _on_enemy_exited_range(body: Node2D) -> void:
	_enemies_in_range.erase(body)
	if body == _target:
		_target = null
		_find_new_target()


func _on_area_entered_range(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		_enemies_in_range.append(area)
		_check_start_attacking()


func _on_area_exited_range(area: Area2D) -> void:
	_enemies_in_range.erase(area)
	if area == _target:
		_target = null
		_find_new_target()


func _check_start_attacking() -> void:
	if _target == null and _enemies_in_range.size() > 0 and attack_timer.is_stopped():
		_find_new_target()
		if _target:
			_perform_attack()


func _find_new_target() -> void:
	## Find the closest/first enemy in range
	var old_target = _target
	_target = _find_target()

	if _target != old_target:
		target_changed.emit(_target)

	if _target and attack_timer.is_stopped():
		# Start attack cycle
		var attack_interval = 1.0 / tower.digimon_data.attack_speed
		attack_timer.wait_time = attack_interval
		attack_timer.start()


func _find_target() -> Node2D:
	## Find best enemy target based on targeting priority
	if _enemies_in_range.is_empty():
		return null

	# Clean up invalid references
	var valid_enemies: Array[Node2D] = []
	for enemy in _enemies_in_range:
		if is_instance_valid(enemy) and not enemy.is_dead:
			valid_enemies.append(enemy)
	_enemies_in_range = valid_enemies

	if valid_enemies.is_empty():
		return null

	# Use Targeting system to find best target based on priority
	return Targeting.get_target(tower, valid_enemies, targeting_priority)


## Set targeting priority (called from UI)
func set_targeting_priority(priority: Targeting.Priority) -> void:
	targeting_priority = priority
	# Re-evaluate target with new priority
	_target = _find_target()


## Cycle to next targeting priority (for quick toggle)
func cycle_targeting_priority() -> void:
	var priorities = Targeting.get_all_priorities()
	var current_index = priorities.find(targeting_priority)
	var next_index = (current_index + 1) % priorities.size()
	set_targeting_priority(priorities[next_index])


## Get current targeting priority name for display
func get_targeting_priority_name() -> String:
	return Targeting.priority_to_string(targeting_priority)


func _perform_attack() -> void:
	## Execute an attack on the current target
	if not tower.digimon_data or not tower.digimon_data.can_attack():
		return

	if not is_instance_valid(_target):
		_target = null
		_find_new_target()
		return

	# Determine attack type based on family
	var attack_type = AttackTypes.get_family_attack_type(tower.digimon_data.family)

	# Use CombatSystem if available for projectile-based attacks
	if CombatSystem and attack_type != AttackTypes.Type.INSTANT:
		var projectile = CombatSystem.fire_projectile(
			tower,
			_target,
			tower.digimon_data.base_damage,
			attack_type
		)
		if projectile:
			# Visual feedback
			flash_on_attack()

			# Emit signals
			attack_started.emit(_target)
			if EventBus:
				EventBus.tower_attack_started.emit(tower, _target)
	else:
		# Fallback: Direct damage (instant attack)
		var damage_result = DamageCalculator.calculate_damage(tower, _target, tower.digimon_data.base_damage)

		# Apply damage to target
		if _target.has_method("take_damage"):
			_target.take_damage(damage_result["damage"], tower, damage_result["damage_type"])

		# Show damage number
		if EventBus:
			EventBus.show_damage_number(
				_target.global_position,
				damage_result["damage"],
				damage_result["is_critical"]
			)

		# Visual feedback
		flash_on_attack()

		# Emit signals
		attack_started.emit(_target)
		attack_hit.emit(_target, damage_result["damage"], damage_result["is_critical"])

		if EventBus:
			EventBus.tower_attack_started.emit(tower, _target)
			EventBus.tower_attack_hit.emit(tower, _target, damage_result["damage"], damage_result["is_critical"])

		# Apply status effect if applicable
		DamageCalculator.apply_effect(tower, _target)

	# Schedule next attack
	if is_instance_valid(_target) and tower.digimon_data:
		var attack_interval = 1.0 / tower.digimon_data.attack_speed
		attack_timer.wait_time = attack_interval
		attack_timer.start()


## Calculate damage including level scaling and attribute bonus
func calculate_damage() -> float:
	if not tower.digimon_data:
		return 0.0

	var base = float(tower.digimon_data.base_damage)

	# Level scaling using GameConfig constants
	var level_multiplier = 1.0 + (tower.current_level - 1) * GameConfig.LEVEL_SCALE_PER_LEVEL

	# DP bonus using GameConfig constants
	var dp_multiplier = 1.0 + tower.current_dp * GameConfig.DP_SCALE_PER_DP

	# Attribute multiplier (if target has attribute)
	var attr_multiplier = 1.0
	if is_instance_valid(_target) and _target.has_method("get_attribute"):
		var target_attr = _target.get_attribute()
		attr_multiplier = DigimonData.get_attribute_multiplier(tower.digimon_data.attribute, target_attr)

	return base * level_multiplier * dp_multiplier * attr_multiplier


## Get damage type based on family/effect
func get_damage_type() -> String:
	if tower.digimon_data.effect_type != "":
		return tower.digimon_data.effect_type.to_lower()

	match tower.digimon_data.family:
		DigimonData.Family.DRAGONS_ROAR:
			return "fire"
		DigimonData.Family.DEEP_SAVERS:
			return "water"
		DigimonData.Family.VIRUS_BUSTERS:
			return "holy"
		DigimonData.Family.NIGHTMARE_SOLDIERS:
			return "dark"
		_:
			return "physical"


## Try to apply status effect to target
func try_apply_effect() -> void:
	if not tower.digimon_data or tower.digimon_data.effect_type == "":
		return

	if not is_instance_valid(_target):
		return

	if randf() <= tower.digimon_data.effect_chance:
		if _target.has_method("apply_effect"):
			_target.apply_effect(
				tower.digimon_data.effect_type,
				tower.digimon_data.effect_duration,
				tower
			)

		if EventBus:
			EventBus.enemy_effect_applied.emit(
				_target,
				tower.digimon_data.effect_type,
				tower.digimon_data.effect_duration,
				tower
			)


func _exit_tree() -> void:
	# Disconnect timer signal
	if attack_timer and attack_timer.timeout.is_connected(_on_attack_timer_timeout):
		attack_timer.timeout.disconnect(_on_attack_timer_timeout)

	# Disconnect range area signals
	if tower and tower.range_area:
		if tower.range_area.body_entered.is_connected(_on_enemy_entered_range):
			tower.range_area.body_entered.disconnect(_on_enemy_entered_range)
		if tower.range_area.body_exited.is_connected(_on_enemy_exited_range):
			tower.range_area.body_exited.disconnect(_on_enemy_exited_range)
		if tower.range_area.area_entered.is_connected(_on_area_entered_range):
			tower.range_area.area_entered.disconnect(_on_area_entered_range)
		if tower.range_area.area_exited.is_connected(_on_area_exited_range):
			tower.range_area.area_exited.disconnect(_on_area_exited_range)

	# Stop timer
	if attack_timer:
		attack_timer.stop()

	# Clear collections
	_enemies_in_range.clear()

	# Null references
	_target = null
	tower = null
	attack_timer = null
