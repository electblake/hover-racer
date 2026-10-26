class_name VehicleTuning
extends Resource

@export var base_speed_range := Vector2(60, 120)
@export var thrust_range_n := Vector2(12000, 24000)
@export var afterburner_thrust_range_n := Vector2(18000, 36000)
@export var ramjet_thrust_range_n := Vector2(24000, 48000)
@export var brake_range_n := Vector2(24000, 42000)
@export var afterburner_bonus_range := Vector2(10, 30)
@export var yaw_torque_range_nm := Vector2(7000, 11000)
@export var lateral_force_range_n := Vector2(45000, 75000)
@export var lateral_damping_range_ns_m := Vector2(7000, 11000)
@export var maneuver_yaw_range := Vector2(1.2, 1.8)
@export var maneuver_recovery_range := Vector2(0.50, 0.15)
@export var ramjet_bonus_range := Vector2(30, 70)
@export var damage_multiplier_range := Vector2(1.0, 0.5)
@export var negative_duration_range := Vector2(1.0, 0.5)
@export var impairment_threshold_range := Vector2(30, 60)
@export var energy_capacity_range := Vector2(100, 300)
@export var steering_smoothing := 8.0
@export var low_speed_authority := 15.0
@export var high_speed_authority := 100.0
@export var high_speed_yaw_factor := 0.65
@export var air_yaw_factor := 0.25
@export var fuel_capacity := 100.0
@export var fuel_consumption := 25.0
@export var fuel_regeneration := 20.0
@export var fuel_delay := 0.75
@export var fuel_reserve := 10.0
@export var heat_gain := 0.20
@export var heat_warning := 0.80
@export var heat_cooling := 0.25
@export var heat_delay := 0.50
@export var energy_regeneration := 10.0
@export var energy_delay := 1.0
@export var maneuver_entry_speed := 15.0
@export var maneuver_exit_speed := 12.0
@export var maneuver_entry_time := 0.10
@export var impact_damage_threshold := 10.0
@export var impact_damage_coefficient := 0.03
@export var impact_repeat_interval := 0.25
@export var impairment_duration := 1.5
@export var impairment_factor := 0.6
@export var floor_angle_degrees := 50.0

# Podracer airbrake: additional steering/grip costs forward momentum.
@export var maneuver_grip_multiplier := 1.3
@export var maneuver_brake_n := 14000.0
@export var yaw_damping_nms := 6500.0
@export var hover_height_m := 0.8
@export var hover_reach_m := 4.0
@export var hover_trim_n := 1470.0
@export var hover_spring_n_m := 120000.0
@export var hover_damping_ns_m := 6000.0
@export var hover_max_n := 80000.0
@export var hover_attraction_n := 80000.0
@export var attitude_stiffness_nm := 24000.0
@export var attitude_damping_nms := 5000.0
@export var attitude_max_nm := 24000.0
@export var atmosphere: FluidMedium = preload("res://surfaces/air.tres")
@export var wind_velocity := Vector3.ZERO
@export var drag_area_cd := Vector3(1.5, 2.0, 0.49382716)
@export var liquid_drag_area_cd := Vector3(1.5, 2.0, 0.5)

func mapped(endpoints: Vector2, rating: float) -> float:
	return lerpf(endpoints.x, endpoints.y, clampf(rating, 0.0, 100.0) / 100.0)

func derive(stats: VehicleStats) -> Dictionary:
	return {
		"base_speed_mps": mapped(base_speed_range, stats.speed),
		"thrust_n": mapped(thrust_range_n, stats.afterburner),
		"afterburner_thrust_n": mapped(afterburner_thrust_range_n, stats.afterburner),
		"ramjet_thrust_n": mapped(ramjet_thrust_range_n, stats.ramjet),
		"brake_force_n": mapped(brake_range_n, stats.afterburner),
		"afterburner_bonus_mps": mapped(afterburner_bonus_range, stats.afterburner),
		"yaw_torque_nm": mapped(yaw_torque_range_nm, stats.cornering),
		"lateral_force_n": mapped(lateral_force_range_n, stats.cornering),
		"lateral_damping_ns_m": mapped(lateral_damping_range_ns_m, stats.cornering),
		"maneuver_yaw_multiplier": mapped(maneuver_yaw_range, stats.maneuvering),
		"maneuver_recovery_s": mapped(maneuver_recovery_range, stats.maneuvering),
		"ramjet_bonus_mps": mapped(ramjet_bonus_range, stats.ramjet),
		"damage_multiplier": mapped(damage_multiplier_range, stats.resilience),
		"negative_duration_multiplier": mapped(negative_duration_range, stats.resilience),
		"impairment_threshold_mps": mapped(impairment_threshold_range, stats.resilience),
		"energy_capacity": mapped(energy_capacity_range, stats.battery),
	}
