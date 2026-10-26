extends "res://tests/support/vehicle_test.gd"

func test_recorded_commands_across_render_and_physics_rates() -> void:
	var outcomes: Array[Vector3] = []
	for physics_rate in [60, 120]:
		Engine.physics_ticks_per_second = physics_rate
		for replay in range(2):
			vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)))
			await frames(20)
			vehicle.command.throttle = 1.0
			await frames(physics_rate)
			vehicle.command.afterburner = true
			await frames(physics_rate)
			vehicle.command.afterburner = false
			vehicle.command.maneuver = true
			vehicle.command.steering = 0.6
			await frames(physics_rate / 2)
			outcomes.append(Vector3(vehicle.actual_speed, vehicle.fuel, vehicle.rotation.y))
	print("Recorded outcomes at fixed render delta ", get_process_delta_time(), ": ", outcomes)
	for outcome in outcomes:
		assert_almost_eq(outcome.x, outcomes[0].x, 0.6)
		assert_almost_eq(outcome.y, outcomes[0].y, 0.5)
		assert_almost_eq(outcome.z, outcomes[0].z, 0.02)
