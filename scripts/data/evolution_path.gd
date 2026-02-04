class_name EvolutionPath
extends Resource
## Defines a single evolution path from one Digimon to another.
## Contains DP (Digivolution Points) requirements for this path to be available.

## The name of the Digimon this path evolves into
@export var result_digimon: String = ""

## Minimum DP required to unlock this evolution
@export var min_dp: int = 0

## Maximum DP for this evolution (use 99 for no upper limit)
@export var max_dp: int = 99

## If true, this is the default/basic evolution (usually DP 0-2)
@export var is_default: bool = false

## Optional description shown in evolution choice UI
@export var description: String = ""

## Optional preview of key ability gained
@export var ability_preview: String = ""

## Check if this evolution path is available given the current DP
func is_available(dp: int) -> bool:
	return dp >= min_dp and dp <= max_dp

## Check if this path is locked (DP too low)
func is_locked(dp: int) -> bool:
	return dp < min_dp

## Check if this path is obsolete (DP too high, past the window)
func is_past(dp: int) -> bool:
	return dp > max_dp

## Get the DP requirement as a formatted string for UI
func get_requirement_text() -> String:
	if max_dp >= 99:
		return "DP %d+" % min_dp
	return "DP %d-%d" % [min_dp, max_dp]

## Get lock status text for UI
func get_status_text(dp: int) -> String:
	if is_available(dp):
		return "Available"
	elif is_locked(dp):
		return "Need DP %d" % min_dp
	else:
		return "Past DP window"
