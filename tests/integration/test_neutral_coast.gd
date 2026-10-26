extends "res://tests/support/vehicle_test.gd"

func test_coasting_braking_and_no_reverse() -> void:
	vehicle.linear_velocity = Vector3(0, 0, -40)
	await frames(60)
	assert_almost_eq(vehicle.actual_speed, 39.23, 0.15)
	vehicle.command.brake = 0.5
	vehicle.command.throttle = 1.0
	vehicle.command.afterburner = true
	vehicle.command.ramjet = true
	vehicle.command.maneuver = true
	await frames(60)
	assert_almost_eq(vehicle.actual_speed, 11.8, 0.6)
	assert_eq(vehicle.boost_mode, "none")
	assert_eq(vehicle.maneuver_blend, 0.0)
	await frames(60)
	assert_almost_eq(vehicle.actual_speed, 0.0, 0.001)
	assert_eq(vehicle.fuel, 100.0)
	assert_eq(vehicle.heat, 0.0)

func test_lateral_force_dissipates_slip_without_rotating_velocity() -> void:
	vehicle.linear_velocity = Vector3(40, 0, 0)
	await frames(1)
	assert_gt(vehicle.linear_velocity.x, 35.0, "Finite force cannot instantly align motion")
	assert_almost_eq(vehicle.linear_velocity.z, 0.0, 0.01)
	await frames(30)
	assert_lt(vehicle.actual_speed, 1.0, "Side thrusters dissipate sideways energy")
	assert_almost_eq(vehicle.linear_velocity.z, 0.0, 0.01)
