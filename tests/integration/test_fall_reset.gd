extends "res://tests/support/vehicle_test.gd"

func test_airborne_keeps_momentum_with_drag_and_disables_ground_actuators() -> void:
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 100, 0)))
	vehicle.linear_velocity = Vector3(20, 0, -30)
	vehicle.command.throttle = 1.0
	vehicle.command.brake = 1.0
	vehicle.command.steering = 1.0
	vehicle.command.ramjet = true
	vehicle.command.maneuver = true
	await frames(30)
	assert_between(vehicle.linear_velocity.x, 19.0, 20.0)
	assert_between(vehicle.linear_velocity.z, -30.0, -29.0)
	assert_lt(vehicle.linear_velocity.y, -4.0)
	assert_lt(vehicle.rotation.y, 0.0)
	assert_eq(vehicle.boost_mode, "none")
	assert_eq(vehicle.maneuver_blend, 0.0)
	assert_true(vehicle.activate_ability())

func test_respawn_resets_life_resources_and_transients() -> void:
	watch_signals(vehicle)
	vehicle.apply_damage(200)
	assert_true(vehicle.is_crashed)
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)))
	assert_false(vehicle.is_crashed)
	assert_eq(vehicle.health, 100.0)
	assert_eq(vehicle.energy, 200.0)
	assert_eq(vehicle.fuel, 100.0)
	assert_eq(vehicle.heat, 0.0)
	assert_eq(vehicle.linear_velocity, Vector3.ZERO)
	vehicle.crash("second life")
	assert_signal_emit_count(vehicle, "crashed", 2)
