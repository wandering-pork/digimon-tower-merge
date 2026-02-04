class_name TraitEffect
extends Resource
## Defines a status effect that can be applied by tower attacks.
## Examples: Burn, Freeze, Slow, Poison, Fear, etc.

## Effect type identifiers
enum EffectType {
	BURN,        ## Damage over time (fire)
	FREEZE,      ## Stun then slow (ice)
	SLOW,        ## Movement reduction
	POISON,      ## DoT + heal reduction
	FEAR,        ## Enemy runs away
	ARMOR_SHRED, ## Defense reduction
	ROOT,        ## Cannot move, can attack
	KNOCKBACK,   ## Push back instantly
	LIFESTEAL,   ## Heal attacker on hit
	INSTAKILL,   ## Execute chance
	BUFF_DAMAGE, ## Increase ally damage
	BUFF_SPEED   ## Increase ally attack speed
}

@export var effect_name: String = ""
@export var effect_type: EffectType = EffectType.SLOW

## Duration in seconds (0 for instant effects like knockback)
@export var duration: float = 3.0

## For DoT effects (Burn, Poison)
@export_group("Damage Over Time")
@export var damage_per_tick: float = 5.0
@export var tick_interval: float = 1.0

## For slow/speed effects
@export_group("Movement Modification")
@export var slow_percent: float = 0.3  ## 0.3 = 30% slow
@export var stun_duration: float = 0.0  ## Freeze has initial stun

## For defense modification
@export_group("Defense Modification")
@export var armor_reduction_percent: float = 0.2  ## 0.2 = 20% armor shred

## For healing effects
@export_group("Healing")
@export var lifesteal_percent: float = 0.15  ## 0.15 = 15% of damage healed
@export var heal_reduction_percent: float = 0.0  ## For poison

## For instant effects
@export_group("Instant Effects")
@export var knockback_distance: float = 1.0  ## Tiles
@export var instakill_chance: float = 0.05  ## 5% execute

## For buff effects
@export_group("Buff Effects")
@export var damage_buff_percent: float = 0.25  ## 25% damage increase
@export var speed_buff_percent: float = 0.25  ## 25% attack speed increase
@export var buff_radius: float = 2.0  ## Tile radius for aura

## Stacking behavior
@export_group("Stacking")
@export var is_stacking: bool = false
@export var max_stacks: int = 3
@export var refresh_on_reapply: bool = true  ## Reset duration when reapplied

## Visual indicator color (for particles/overlays)
@export_group("Visuals")
@export var effect_color: Color = Color.WHITE

## Calculate total DoT damage over full duration
func get_total_dot_damage() -> float:
	if damage_per_tick <= 0 or tick_interval <= 0:
		return 0.0
	var ticks = floori(duration / tick_interval)
	return damage_per_tick * ticks

## Check if this is a debuff (negative effect on enemies)
func is_debuff() -> bool:
	match effect_type:
		EffectType.BURN, EffectType.FREEZE, EffectType.SLOW, \
		EffectType.POISON, EffectType.FEAR, EffectType.ARMOR_SHRED, \
		EffectType.ROOT, EffectType.KNOCKBACK, EffectType.INSTAKILL:
			return true
		_:
			return false

## Check if this is a buff (positive effect on allies)
func is_buff() -> bool:
	match effect_type:
		EffectType.BUFF_DAMAGE, EffectType.BUFF_SPEED, EffectType.LIFESTEAL:
			return true
		_:
			return false

## Get effect description for UI
func get_description() -> String:
	match effect_type:
		EffectType.BURN:
			return "Burns for %.0f damage every %.1fs for %.1fs" % [damage_per_tick, tick_interval, duration]
		EffectType.FREEZE:
			return "Stuns for %.1fs, then slows by %.0f%% for %.1fs" % [stun_duration, slow_percent * 100, duration]
		EffectType.SLOW:
			return "Slows by %.0f%% for %.1fs" % [slow_percent * 100, duration]
		EffectType.POISON:
			return "Poisons for %.0f damage/tick, reduces healing by %.0f%%" % [damage_per_tick, heal_reduction_percent * 100]
		EffectType.FEAR:
			return "Causes enemy to flee for %.1fs" % [duration]
		EffectType.ARMOR_SHRED:
			return "Reduces armor by %.0f%% for %.1fs" % [armor_reduction_percent * 100, duration]
		EffectType.ROOT:
			return "Roots in place for %.1fs" % [duration]
		EffectType.KNOCKBACK:
			return "Knocks back %.1f tiles" % [knockback_distance]
		EffectType.LIFESTEAL:
			return "Heals for %.0f%% of damage dealt" % [lifesteal_percent * 100]
		EffectType.INSTAKILL:
			return "%.0f%% chance to instantly kill" % [instakill_chance * 100]
		EffectType.BUFF_DAMAGE:
			return "Allies in range deal +%.0f%% damage" % [damage_buff_percent * 100]
		EffectType.BUFF_SPEED:
			return "Allies in range attack %.0f%% faster" % [speed_buff_percent * 100]
		_:
			return effect_name
