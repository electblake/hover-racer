extends "res://tests/support/vehicle_test.gd"

func test_steering_sign_smoothing_and_rest_authority() -> void:
	vehicle.command.steering = 1.0
	await frames(20)
	assert_lt(vehicle.rotation.y, -0.01, "Low-speed yaw allows turning away from obstacles")
	vehicle.command.throttle = 1.0
	await frames(60)
	assert_lt(vehicle.rotation.y, -0.2)
	assert_eq(vehicle.steering, 1.0)
	vehicle.command.steering = -1.0
	await frames(5)
	assert_gt(vehicle.steering, -1.0)
	await frames(20)
	assert_eq(vehicle.steering, -1.0)

func test_airbrake_loses_speed_and_blocks_boost_until_recovery() -> void:
	vehicle.linear_velocity = Vector3(0, 0, -90)
	vehicle.command.throttle = 1.0
	vehicle.command.maneuver = true
	vehicle.command.ramjet = true
	await frames(60)
	assert_eq(vehicle.reference_speed, 90.0)
	assert_between(vehicle.actual_speed, 65.0, 80.0, "Airbrake spends momentum without a maneuver speed cap")
	assert_eq(vehicle.boost_mode, "none")
	vehicle.command.maneuver = false
	var speed := vehicle.actual_speed
	await frames(2)
	assert_lt(vehicle.actual_speed - speed, 1.1)
	assert_true(vehicle.maneuver_module.active())
	assert_eq(vehicle.boost_mode, "none")
	await frames(25)
	assert_eq(vehicle.boost_mode, "ramjet")

func test_maneuver_hysteresis_brake_and_air_exit() -> void:
	vehicle.linear_velocity = Vector3(0, 0, -14)
	vehicle.command.maneuver = true
	await frames(2)
	assert_false(vehicle.maneuver_module.engaged)
	vehicle.linear_velocity = Vector3(0, 0, -16)
	await frames(8)
	assert_true(vehicle.maneuver_module.engaged)
	vehicle.linear_velocity = Vector3(0, 0, -13)
	await frames(2)
	assert_true(vehicle.maneuver_module.engaged)
	vehicle.command.brake = 0.1
	await frames(2)
	assert_eq(vehicle.maneuver_blend, 0.0)
