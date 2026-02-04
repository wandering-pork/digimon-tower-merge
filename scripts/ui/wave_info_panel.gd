extends PanelContainer
## Wave Information Panel UI
##
## Displays current wave number, enemy count, intermission timer,
## and next wave preview information.

# =============================================================================
# NODE REFERENCES
# =============================================================================

@onready var wave_label: Label = $VBoxContainer/WaveNumber
@onready var enemy_label: Label = $VBoxContainer/EnemyCount
@onready var intermission_container: VBoxContainer = $VBoxContainer/IntermissionContainer
@onready var intermission_bar: ProgressBar = $VBoxContainer/IntermissionContainer/IntermissionBar
@onready var intermission_label: Label = $VBoxContainer/IntermissionContainer/IntermissionLabel
@onready var skip_button: Button = $VBoxContainer/IntermissionContainer/SkipButton
@onready var preview_label: Label = $VBoxContainer/NextWavePreview
@onready var boss_warning: Label = $VBoxContainer/BossWarning

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

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_update_display()

	# Initial state: show intermission for wave 1
	intermission_container.show()
	boss_warning.hide()


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


# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

## Handle wave started
func _on_wave_started(wave: int, count: int) -> void:
	_current_wave = wave
	_total_enemies = count
	_remaining_enemies = count

	# Update display
	wave_label.text = "Wave %d" % wave
	_update_enemy_count()

	# Hide intermission UI during wave
	intermission_container.hide()

	# Check for boss wave and show warning
	_is_boss_wave = _check_boss_wave(wave)
	boss_warning.visible = _is_boss_wave

	# Update preview for next wave
	_update_next_wave_preview(wave + 1)


## Handle wave completed
func _on_wave_completed(wave: int, reward: int) -> void:
	# Show reward notification could be added here
	pass


## Handle intermission timer updates
func _on_intermission(next_wave: int, time_remaining: float) -> void:
	# Show intermission UI
	intermission_container.show()

	# Store max time on first tick
	if time_remaining > _max_intermission_time - 0.1:
		_max_intermission_time = time_remaining

	# Update bar
	intermission_bar.max_value = _max_intermission_time
	intermission_bar.value = time_remaining

	# Update label
	intermission_label.text = "Next wave in: %ds" % ceili(time_remaining)

	# Update wave number to show upcoming wave
	wave_label.text = "Wave %d" % next_wave

	# Check if next wave is a boss wave
	_is_boss_wave = _check_boss_wave(next_wave)
	boss_warning.visible = _is_boss_wave

	# Update preview
	_update_next_wave_preview(next_wave)


## Handle enemy spawned
func _on_enemy_spawned(_enemy: Node, _wave_number: int, _is_boss: bool) -> void:
	# Enemy count stays the same, just visual update if needed
	pass


## Handle enemy killed
func _on_enemy_killed(_enemy: Node, _killer: Node, _reward: int) -> void:
	_remaining_enemies -= 1
	_update_enemy_count()


## Handle enemy escaped
func _on_enemy_escaped(_enemy: Node, _is_boss: bool) -> void:
	_remaining_enemies -= 1
	_update_enemy_count()


## Handle boss spawned
func _on_boss_spawned(_boss: Node, _wave_number: int, boss_name: String) -> void:
	# Flash boss warning
	boss_warning.text = "BOSS: %s" % boss_name
	boss_warning.show()

	# Create pulse animation
	var tween = create_tween()
	tween.set_loops(3)
	tween.tween_property(boss_warning, "modulate:a", 0.3, 0.2)
	tween.tween_property(boss_warning, "modulate:a", 1.0, 0.2)


## Handle skip button pressed
func _on_skip_pressed() -> void:
	EventBus.wave_start_requested.emit()


# =============================================================================
# UPDATE FUNCTIONS
# =============================================================================

## Update enemy count display
func _update_enemy_count() -> void:
	enemy_label.text = "Enemies: %d/%d" % [_remaining_enemies, _total_enemies]

	# Color based on remaining enemies
	if _remaining_enemies <= 0:
		enemy_label.modulate = Color.GREEN
	elif _remaining_enemies <= _total_enemies * 0.25:
		enemy_label.modulate = Color.YELLOW
	else:
		enemy_label.modulate = Color.WHITE


## Update full display
func _update_display() -> void:
	wave_label.text = "Wave %d" % _current_wave
	_update_enemy_count()


## Update next wave preview text
func _update_next_wave_preview(next_wave: int) -> void:
	var preview_text = _get_wave_preview_text(next_wave)
	preview_label.text = "Next: %s" % preview_text


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
	_update_display()
