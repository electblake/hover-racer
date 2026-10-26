extends "res://tests/support/vehicle_test.gd"

func test_throttle_force_curve_and_boost_output() -> void:
	vehicle.command.throttle = 1.0
	await frames(60)
	assert_between(vehicle.actual_speed, 27.0, 30.0, "Force accelerates mass; thrust tapers with speed")
	await frames(900)
	assert_almost_eq(vehicle.actual_speed, 90.0, 1.0)
	vehicle.command.afterburner = true
	await frames(180)
	assert_eq(vehicle.reference_speed, 110.0)
	assert_between(vehicle.actual_speed, 105.0, 111.0)
	vehicle.command.ramjet = true
	await frames(180)
	assert_eq(vehicle.reference_speed, 140.0)
	assert_between(vehicle.actual_speed, 133.0, 141.0)
	vehicle.command.ramjet = false
	vehicle.command.afterburner = false
	var before := vehicle.actual_speed
	await frames(6)
	assert_between(vehicle.actual_speed, before - 2.0, before, "Excess momentum coasts rather than clamping")

func test_partial_throttle_has_lower_equilibrium_speed() -> void:
	vehicle.command.throttle = 0.25
	await frames(60)
	assert_almost_eq(vehicle.actual_speed, 7.5, 0.3)
	vehicle.linear_velocity = Vector3(0, 0, -89)
	await frames(600)
	assert_between(vehicle.actual_speed, 74.0, 79.0, "Quarter thrust settles below full-power reference")

func test_boost_priority_resource_timing_and_latch() -> void:
	vehicle.command.throttle = 1.0
	vehicle.command.afterburner = true
	await frames(240)
	assert_almost_eq(vehicle.fuel, 0.0, 0.5)
	await frames(2)
	assert_true(vehicle.depletion_latch)
	assert_eq(vehicle.boost_mode, "none")
	await frames(120)
	assert_gt(vehicle.fuel, 10.0)
	assert_eq(vehicle.boost_mode, "none")
	vehicle.command.afterburner = false
	await frames(2)
	vehicle.command.afterburner = true
	vehicle.command.ramjet = true
	var fuel := vehicle.fuel
	await frames(30)
	assert_eq(vehicle.boost_mode, "ramjet")
	assert_eq(vehicle.fuel, fuel)
	assert_almost_eq(vehicle.heat, 0.1, 0.005)

func test_heat_warning_crash_once_and_frozen_resources() -> void:
	watch_signals(vehicle)
	vehicle.command.throttle = 1.0
	vehicle.command.ramjet = true
	await frames(241)
	assert_signal_emit_count(vehicle, "heat_warning", 1)
	assert_false(vehicle.is_crashed)
	await frames(60)
	assert_true(vehicle.is_crashed)
	assert_signal_emit_count(vehicle, "crashed", 1)
	assert_eq(vehicle.linear_velocity, Vector3.ZERO)
	var frozen := Vector3(vehicle.fuel, vehicle.heat, vehicle.energy)
	await frames(60)
	assert_eq(Vector3(vehicle.fuel, vehicle.heat, vehicle.energy), frozen)
	vehicle.crash("again")
	assert_signal_emit_count(vehicle, "crashed", 1)
