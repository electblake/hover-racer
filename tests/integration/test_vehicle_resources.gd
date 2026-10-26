extends "res://tests/support/vehicle_test.gd"

func test_energy_delay_failed_requests_and_capacity_changes() -> void:
	vehicle.command.ability_primary = true
	await frames(2)
	assert_almost_eq(vehicle.energy, 160.0, 0.001)
	assert_false(vehicle.activate_ability())
	await frames(59)
	assert_almost_eq(vehicle.energy, 160.0, 0.4)
	await frames(240)
	assert_almost_eq(vehicle.energy, 200.0, 0.4)
	vehicle.energy = 150.0
	vehicle.stats.battery = 100.0
	await frames(2)
	assert_eq(vehicle.derived.energy_capacity, 300.0)
	assert_lt(vehicle.energy, 151.0)
	vehicle.stats.battery = 0.0
	await frames(2)
	assert_eq(vehicle.energy, 100.0)

func test_resilience_and_impairment() -> void:
	vehicle.apply_damage(40.0)
	assert_eq(vehicle.health, 70.0)
	vehicle.apply_impairment(2.0)
	assert_eq(vehicle.impairment_time, 1.5)
	vehicle.apply_impairment(1.0)
	assert_eq(vehicle.impairment_time, 1.5)
	vehicle.command.throttle = 1.0
	vehicle.command.ramjet = true
	assert_false(vehicle.activate_ability())
	await frames(30)
	assert_almost_eq(vehicle.actual_speed, 9.0, 0.35)
	assert_eq(vehicle.boost_mode, "none")

func test_shared_presets_independent_resources() -> void:
	var other := make_vehicle()
	other.position.x = 20
	other.stats = vehicle.stats
	vehicle.command.throttle = 1.0
	vehicle.command.afterburner = true
	vehicle.apply_damage(40)
	vehicle.activate_ability()
	await frames(60)
	assert_lt(vehicle.fuel, 80.0)
	assert_eq(other.fuel, 100.0)
	assert_eq(other.health, 100.0)
	assert_eq(other.energy, 200.0)
	assert_eq(vehicle.stats.speed, 50.0)

func test_partial_tick_recovery_and_heat_cooling_during_afterburner() -> void:
	vehicle.fuel = 20.0
	vehicle.time_without_boost = 0.745
	await frames(1)
	assert_almost_eq(vehicle.fuel, 20.23333, 0.01)
	vehicle.heat = 0.5
	vehicle.time_without_ramjet = 0.5
	vehicle.command.throttle = 1.0
	vehicle.command.afterburner = true
	await frames(30)
	assert_almost_eq(vehicle.heat, 0.375, 0.01)
	assert_lt(vehicle.fuel, 10.0)

func test_live_speed_rating_changes_thrust_curve_without_velocity_snap() -> void:
	vehicle.linear_velocity = Vector3(0, 0, -90)
	vehicle.stats.speed = 0.0
	vehicle.command.throttle = 1.0
	await frames(6)
	assert_eq(vehicle.reference_speed, 60.0)
	assert_between(vehicle.actual_speed, 89.0, 90.0, "Existing momentum survives a lower reference speed")

func test_extreme_ratings_keep_runtime_meters_finite() -> void:
	for rating in [0.0, 100.0]:
		for field in ["speed", "afterburner", "cornering", "maneuvering", "ramjet", "resilience", "battery"]: vehicle.stats.set(field, rating)
		vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)))
		await frames(10)
		vehicle.command.throttle = 1.0
		vehicle.command.ramjet = true
		vehicle.command.steering = 1.0
		await frames(60)
		assert_true(vehicle.linear_velocity.is_finite())
		assert_between(vehicle.fuel, 0.0, 100.0)
		assert_between(vehicle.heat, 0.0, 1.0)
		assert_between(vehicle.energy, 0.0, vehicle.derived.energy_capacity)
		assert_false(vehicle.is_crashed)
