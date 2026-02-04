extends PanelContainer
## Wave Information Panel UI
##
## Displays current wave number, enemy count, intermission timer,
## and next wave preview information. Provides real-time updates
## during wave progression with visual feedback for boss waves.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var wave_label: Label = $VBoxContainer/WaveNumber
@onready var wave_status_label: Label = $VBoxContainer/WaveStatus
@onready var enemy_container: HBoxContainer = $VBoxContainer/EnemyContainer
@onready var enemy_label: Label = $VBoxContainer/EnemyContainer/EnemyCount
@onready var enemy_progress: ProgressBar = $VBoxContainer/EnemyContainer/EnemyProgress
@onready var intermission_container: VBoxContainer = $VBoxContainer/IntermissionContainer
@onready var countdown_label: Label = $VBoxContainer/IntermissionContainer/CountdownLabel
@onready var intermission_bar: ProgressBar = $VBoxContainer/IntermissionContainer/IntermissionBar
@onready var skip_button: Button = $VBoxContainer/IntermissionContainer/SkipButton
@onready var preview_label: Label = $VBoxContainer/NextWavePreview
@onready var boss_warning_container: PanelContainer = $VBoxContainer/BossWarningContainer
@onready var boss_warning_label: Label = $VBoxContainer/BossWarningContainer/BossWarningLabel

# =============================================================================
# CONSTANTS
# =============================================================================

## Colors for various UI states
const COLOR_WAVE_NORMAL: Color = Color(1.0, 0.85, 0.4, 1.0)  # Gold
const COLOR_WAVE_BOSS: Color = Color(1.0, 0.3, 0.3, 1.0)  # Red
const COLOR_ENEMIES_FULL: Color = Color(0.9, 0.9, 0.9, 1.0)  # White
const COLOR_ENEMIES_LOW: Color = Color(1.0, 1.0, 0.4, 1.0)  # Yellow
const COLOR_ENEMIES_CLEAR: Color = Color(0.4, 1.0, 0.4, 1.0)  # Green
const COLOR_COUNTDOWN: Color = Color(0.7, 0.9, 1.0, 1.0)  # Light blue

## Animation durations
const BOSS_FLASH_DURATION: float = 0.3
const BOSS_FLASH_LOOPS: int = 5

# =============================================================================
# STATE
# =============================================================================

## Current wave number
var _current_wave: int = 0

## Total enemies in current wave
var _total_enemies: int = 0

## Remaining enemies
var _remaining_enemies: int = 0

## Max intermission time (for progress bar)
var _max_intermission_time: float = 20.0

## Is a boss wave
var _is_boss_wave: bool = false

## Current countdown timer value
var _countdown_time: float = 0.0

## Active boss warning tween
var _boss_warning_tween: Tween = null

## Is currently in intermission
var _is_intermission: bool = true

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_setup_initial_state()
	_update_display()


func _setup_initial_state() -> void:
	# Initial state: waiting for first wave
	_is_intermission = true
	_current_wave = 1
	intermission_container.show()
	enemy_container.hide()
	_hide_boss_warning()


func _connect_signals() -> void:
	# Connect to EventBus wave signals
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)
	EventBus.wave_intermission.connect(_on_intermission)
	EventBus.enemy_spawned.connect(_on_enemy_spawned)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.enemy_escaped.connect(_on_enemy_escaped)
	EventBus.boss_spawned.connect(_on_boss_spawned)

	# Connect skip button
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)


func _exit_tree() -> void:
	# Clean up signal connections
	if EventBus:
		if EventBus.wave_started.is_connected(_on_wave_started):
			EventBus.wave_started.disconnect(_on_wave_started)
		if EventBus.wave_completed.is_connected(_on_wave_completed):
			EventBus.wave_completed.disconnect(_on_wave_completed)
		if EventBus.wave_intermission.is_connected(_on_intermission):
			EventBus.wave_intermission.disconnect(_on_intermission)
		if EventBus.enemy_spawned.is_connected(_on_enemy_spawned):
			EventBus.enemy_spawned.disconnect(_on_enemy_spawned)
		if EventBus.enemy_killed.is_connected(_on_enemy_killed):
			EventBus.enemy_killed.disconnect(_on_enemy_killed)
		if EventBus.enemy_escaped.is_connected(_on_enemy_escaped):
			EventBus.enemy_escaped.disconnect(_on_enemy_escaped)
		if EventBus.boss_spawned.is_connected(_on_boss_spawned):
			EventBus.boss_spawned.disconnect(_on_boss_spawned)

	# Clean up skip button
	if skip_button and skip_button.pressed.is_connected(_on_skip_pressed):
		skip_button.pressed.disconnect(_on_skip_pressed)

	# Kill any active tweens
	if _boss_warning_tween and _boss_warning_tween.is_valid():
		_boss_warning_tween.kill()
		_boss_warning_tween = null


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

## Handle wave started
func _on_wave_started(wave: int, count: int) -> void:
	_current_wave = wave
	_total_enemies = count
	_remaining_enemies = count
	_is_intermission = false

	# Update wave display
	_update_wave_label()
	wave_status_label.text = "In Progress"
	wave_status_label.modulate = COLOR_ENEMIES_FULL

	# Show enemy count, hide intermission
	enemy_container.show()
	intermission_container.hide()
	_update_enemy_count()

	# Check for boss wave - keep warning visible if it's a boss wave
	_is_boss_wave = _check_boss_wave(wave)
	if not _is_boss_wave:
		_hide_boss_warning()

	# Update preview for next wave
	_update_next_wave_preview(wave + 1)


## Handle wave completed
func _on_wave_completed(wave: int, reward: int) -> void:
	wave_status_label.text = "Complete! +%d DB" % reward
	wave_status_label.modulate = COLOR_ENEMIES_CLEAR

	# Hide boss warning on wave complete
	_hide_boss_warning()

	# Flash the reward briefly
	var tween = create_tween()
	tween.tween_property(wave_status_label, "modulate:a", 0.5, 0.2)
	tween.tween_property(wave_status_label, "modulate:a", 1.0, 0.2)


## Handle intermission timer updates
func _on_intermission(next_wave: int, time_remaining: float) -> void:
	_is_intermission = true
	_current_wave = next_wave
	_countdown_time = time_remaining

	# Show intermission UI, hide enemy count
	intermission_container.show()
	enemy_container.hide()

	# Store max time on first tick (when time is at or near max)
	if time_remaining > _max_intermission_time - 0.5:
		_max_intermission_time = time_remaining

	# Update progress bar
	intermission_bar.max_value = _max_intermission_time
	intermission_bar.value = time_remaining

	# Update countdown label with prominent formatting
	var seconds = ceili(time_remaining)
	countdown_label.text = "Wave %d starting in %d..." % [next_wave, seconds]
	countdown_label.modulate = COLOR_COUNTDOWN

	# Update wave number
	_update_wave_label()
	wave_status_label.text = "Preparing"
	wave_status_label.modulate = COLOR_COUNTDOWN

	# Check if next wave is a boss wave and show warning
	_is_boss_wave = _check_boss_wave(next_wave)
	if _is_boss_wave:
		_show_boss_warning(next_wave)
	else:
		_hide_boss_warning()

	# Update preview
	_update_next_wave_preview(next_wave)


## Handle enemy spawned
func _on_enemy_spawned(_enemy: Node, _wave_number: int, is_boss: bool) -> void:
	# Update status when spawning
	if is_boss:
		wave_status_label.text = "BOSS SPAWNING!"
		wave_status_label.modulate = COLOR_WAVE_BOSS
	else:
		wave_status_label.text = "Spawning..."
		wave_status_label.modulate = COLOR_ENEMIES_FULL


## Handle enemy killed
func _on_enemy_killed(_enemy: Node, _killer: Node, _reward: int) -> void:
	_remaining_enemies = maxi(0, _remaining_enemies - 1)
	_update_enemy_count()

	# Update status
	if _remaining_enemies > 0:
		wave_status_label.text = "In Progress"
		wave_status_label.modulate = COLOR_ENEMIES_FULL


## Handle enemy escaped
func _on_enemy_escaped(_enemy: Node, _is_boss: bool) -> void:
	_remaining_enemies = maxi(0, _remaining_enemies - 1)
	_update_enemy_count()


## Handle boss spawned - show prominent warning
func _on_boss_spawned(_boss: Node, _wave_number: int, boss_name: String) -> void:
	_show_boss_spawn_alert(boss_name)


## Handle skip button pressed
func _on_skip_pressed() -> void:
	EventBus.wave_start_requested.emit()
	skip_button.disabled = true
	# Re-enable after a short delay to prevent spam
	get_tree().create_timer(0.5).timeout.connect(func(): skip_button.disabled = false)


# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

## Update wave label with appropriate styling
func _update_wave_label() -> void:
	wave_label.text = "Wave %d" % _current_wave
	wave_label.modulate = COLOR_WAVE_BOSS if _is_boss_wave else COLOR_WAVE_NORMAL


## Update enemy count display with progress bar
func _update_enemy_count() -> void:
	enemy_label.text = "%d / %d" % [_remaining_enemies, _total_enemies]

	# Update progress bar
	if enemy_progress:
		enemy_progress.max_value = _total_enemies
		enemy_progress.value = _remaining_enemies

	# Color based on remaining enemies
	var progress_ratio = float(_remaining_enemies) / maxf(1.0, float(_total_enemies))
	if _remaining_enemies <= 0:
		enemy_label.modulate = COLOR_ENEMIES_CLEAR
	elif progress_ratio <= 0.25:
		enemy_label.modulate = COLOR_ENEMIES_LOW
	else:
		enemy_label.modulate = COLOR_ENEMIES_FULL


## Update full display
func _update_display() -> void:
	_update_wave_label()
	_update_enemy_count()
	if _is_intermission:
		wave_status_label.text = "Preparing"
	else:
		wave_status_label.text = "Waiting..."


## Update next wave preview text
func _update_next_wave_preview(next_wave: int) -> void:
	var preview_text = _get_wave_preview_text(next_wave)
	preview_label.text = "Next: %s" % preview_text

	# Highlight boss previews in red
	if _check_boss_wave(next_wave):
		preview_label.modulate = COLOR_WAVE_BOSS
	else:
		preview_label.modulate = Color(0.6, 0.6, 0.7, 1.0)


## Check if wave is a boss wave
func _check_boss_wave(wave: int) -> bool:
	# Boss waves: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100
	return wave % 10 == 0


## Get preview text for a wave
func _get_wave_preview_text(wave: int) -> String:
	# Determine wave type/phase
	if wave <= 5:
		return "Tutorial Wave"
	elif wave <= 10:
		if wave == 10:
			return "Mini-Boss: Greymon"
		return "Rookie Swarm"
	elif wave <= 20:
		if wave == 20:
			return "Phase Boss: Greymon"
		return "Rookie Mixed"
	elif wave <= 30:
		if wave == 30:
			return "Mini-Boss: Devimon"
		return "Champion Wave"
	elif wave <= 40:
		if wave == 40:
			return "Phase Boss: Myotismon"
		return "Champion Mixed"
	elif wave <= 50:
		if wave == 50:
			return "Mini-Boss: SkullGreymon"
		return "Ultimate Wave"
	elif wave <= 60:
		if wave == 60:
			return "Phase Boss: VenomMyotismon"
		return "Ultimate + Modifiers"
	elif wave <= 70:
		if wave == 70:
			return "Mini-Boss: Machinedramon"
		return "Mega Wave"
	elif wave <= 80:
		if wave == 80:
			return "Phase Boss: Omegamon"
		return "Mega + Ultra Preview"
	elif wave <= 90:
		if wave == 90:
			return "Mini-Boss: Omegamon Zwart"
		return "Ultra Wave"
	elif wave <= 100:
		if wave == 100:
			return "FINAL BOSS: Apocalymon"
		return "Ultra Chaos"
	else:
		if wave % 10 == 0:
			return "Endless Boss Wave"
		return "Endless Mode"


# =============================================================================
# BOSS WARNING FUNCTIONS
# =============================================================================

## Show boss warning with animation
func _show_boss_warning(wave: int) -> void:
	if not boss_warning_container:
		return

	var boss_name = _get_boss_name(wave)
	boss_warning_label.text = "BOSS WAVE: %s" % boss_name

	boss_warning_container.show()
	_start_boss_warning_animation()


## Show alert when boss actually spawns
func _show_boss_spawn_alert(boss_name: String) -> void:
	if not boss_warning_container:
		return

	boss_warning_label.text = "BOSS: %s" % boss_name
	boss_warning_container.show()

	# Intense flash animation for spawn
	_start_boss_warning_animation()


## Start pulsing animation for boss warning
func _start_boss_warning_animation() -> void:
	# Kill existing tween if any
	if _boss_warning_tween and _boss_warning_tween.is_valid():
		_boss_warning_tween.kill()

	_boss_warning_tween = create_tween()
	_boss_warning_tween.set_loops(BOSS_FLASH_LOOPS)
	_boss_warning_tween.tween_property(boss_warning_container, "modulate:a", 0.4, BOSS_FLASH_DURATION)
	_boss_warning_tween.tween_property(boss_warning_container, "modulate:a", 1.0, BOSS_FLASH_DURATION)


## Hide boss warning
func _hide_boss_warning() -> void:
	if boss_warning_container:
		boss_warning_container.hide()

	if _boss_warning_tween and _boss_warning_tween.is_valid():
		_boss_warning_tween.kill()
		_boss_warning_tween = null


## Get boss name for a wave number
func _get_boss_name(wave: int) -> String:
	match wave:
		10: return "Greymon"
		20: return "Greymon"
		30: return "Devimon"
		40: return "Myotismon"
		50: return "SkullGreymon"
		60: return "VenomMyotismon"
		70: return "Machinedramon"
		80: return "Omegamon"
		90: return "Omegamon Zwart"
		100: return "Apocalymon"
		_:
			if wave > 100 and wave % 10 == 0:
				return "Endless Boss"
			return "Unknown"


# =============================================================================
# PUBLIC API
# =============================================================================

## Set visibility of the panel
func set_panel_visible(is_visible: bool) -> void:
	visible = is_visible


## Force update wave display
func refresh_display(wave: int, enemies_remaining: int, enemies_total: int) -> void:
	_current_wave = wave
	_remaining_enemies = enemies_remaining
	_total_enemies = enemies_total
	_is_boss_wave = _check_boss_wave(wave)
	_update_display()


## Set intermission mode (for external control)
func set_intermission_mode(is_intermission: bool) -> void:
	_is_intermission = is_intermission
	if is_intermission:
		intermission_container.show()
		enemy_container.hide()
	else:
		intermission_container.hide()
		enemy_container.show()


## Get current wave number
func get_current_wave() -> int:
	return _current_wave


## Get remaining enemy count
func get_remaining_enemies() -> int:
	return _remaining_enemies


## Check if currently in intermission
func is_in_intermission() -> bool:
	return _is_intermission
