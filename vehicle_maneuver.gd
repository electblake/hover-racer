class_name VehicleManeuver
extends RefCounted

var engaged := false
var blend := 0.0

func advance(held: bool, supported: bool, speed: float, braking: bool, delta: float, recovery: float, tuning: VehicleTuning) -> void:
	if braking or not supported:
		engaged = false
		blend = 0.0
		return
	if engaged:
		engaged = held and speed >= tuning.maneuver_exit_speed
	elif held and speed >= tuning.maneuver_entry_speed:
		engaged = true
	blend = move_toward(blend, 1.0 if engaged else 0.0, delta / (tuning.maneuver_entry_time if engaged else recovery))

func active() -> bool:
	return engaged or blend > 0.0
