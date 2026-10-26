extends GutTest

func test_balanced_and_extreme_values() -> void:
	var stats := VehicleStats.new()
	var tuning := VehicleTuning.new()
	var d := tuning.derive(stats)
	assert_eq(d.base_speed_mps, 90.0)
	assert_eq(d.thrust_n, 18000.0)
	assert_eq(d.brake_force_n, 33000.0)
	assert_eq(d.afterburner_bonus_mps, 20.0)
	assert_eq(d.ramjet_bonus_mps, 50.0)
	assert_eq(d.lateral_force_n, 60000.0)
	assert_eq(d.energy_capacity, 200.0)
	for rating in [-20.0, 0.0, 100.0, 120.0]:
		for field in ["speed", "afterburner", "cornering", "maneuvering", "ramjet", "resilience", "battery"]: stats.set(field, rating)
		for value in tuning.derive(stats).values(): assert_true(is_finite(value) and value > 0.0)
	assert_eq(tuning.derive(stats).damage_multiplier, 0.5)

func test_rating_isolation() -> void:
	var groups := {
		"speed": ["base_speed_mps"],
		"afterburner": ["thrust_n", "afterburner_thrust_n", "brake_force_n", "afterburner_bonus_mps"],
		"cornering": ["yaw_torque_nm", "lateral_force_n", "lateral_damping_ns_m"],
		"maneuvering": ["maneuver_yaw_multiplier", "maneuver_recovery_s"],
		"ramjet": ["ramjet_bonus_mps", "ramjet_thrust_n"],
		"resilience": ["damage_multiplier", "negative_duration_multiplier", "impairment_threshold_mps"],
		"battery": ["energy_capacity"]}
	var tuning := VehicleTuning.new()
	var baseline := tuning.derive(VehicleStats.new())
	for field in groups:
		var stats := VehicleStats.new()
		stats.set(field, 100.0)
		var changed := tuning.derive(stats)
		for key in baseline:
			if key in groups[field]: assert_ne(changed[key], baseline[key], field + ": " + key)
			else: assert_eq(changed[key], baseline[key], field + " isolation: " + key)
