extends "res://tests/support/vehicle_test.gd"

func test_stationary_racer_can_turn_away_from_obstacle() -> void:
	vehicle.command.steering = 1.0
	await frames(90)
	assert_lt(vehicle.rotation.y, -0.2, "Steering must work without forward motion so a wall cannot trap the racer")

func test_braking_side_slip_never_reverses_it() -> void:
	vehicle.linear_velocity = Vector3(0.5, 0, 0)
	vehicle.command.brake = 1.0
	for frame in range(20):
		await frames(1)
		assert_gte(vehicle.linear_velocity.x, -0.001, "Brake and slip damping share the available stopping impulse")
	assert_lt(absf(vehicle.linear_velocity.x), 0.01)

func test_racers_collide_instead_of_passing_through() -> void:
	var other := make_vehicle()
	other.position = Vector3(0, 0.8, -12)
	other.freeze = true
	await frames(3)
	vehicle.linear_velocity = Vector3(0, 0, -20)
	await frames(60)
	assert_gt(vehicle.position.z, -10.0, "Other vehicle blocks passage")
	assert_lt(vehicle.actual_speed, 1.0)

func test_reset_clears_force_and_immersion_telemetry() -> void:
	vehicle.command.throttle = 1.0
	await frames(30)
	assert_gt(vehicle.telemetry().thrust_n, 0.0)
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
	assert_eq(vehicle.telemetry().thrust_n, 0.0)
	assert_eq(vehicle.telemetry().lift_n, 0.0)
	assert_eq(vehicle.telemetry().immersion, 0.0)
	await frames(30)
	assert_lt(vehicle.actual_speed, 0.05, "Reset cannot retain propulsion from the last run")

func test_submerged_racer_reacquires_hover_and_drive() -> void:
	floor_body.position.y = -11
	var water := FluidRegion3D.new()
	water.medium = preload("res://surfaces/water.tres")
	water.size_m = Vector3(10000, 10, 10000)
	water.position.y = -5
	add_child_autofree(water)
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, -1, 0)))
	vehicle.command.throttle = 1.0
	await frames(600)
	assert_true(vehicle.supported, "A floating hull can reacquire its powered hover field")
	assert_gt(vehicle.position.y, 0.5)
	assert_gt(vehicle.actual_speed, 10.0)
	assert_false(vehicle.is_crashed)

func test_overlapping_surface_uses_highest_priority_material() -> void:
	floor_body.position.y = -11
	for priority in [1, 2]:
		var water := FluidRegion3D.new()
		water.medium = preload("res://surfaces/water.tres")
		water.surface = TrackSurface.new()
		water.surface.lateral_coupling = 0.8 if priority == 1 else 0.2
		water.medium_priority = priority
		water.size_m = Vector3(1000, 10, 1000)
		water.position.y = -5
		add_child_autofree(water)
	await frames(30)
	assert_almost_eq(vehicle.forces.lateral_coupling, 0.2, 0.001)

func test_submerged_braking_does_not_reverse_forward_motion() -> void:
	floor_body.position.y = -11
	var water := FluidRegion3D.new()
	water.medium = preload("res://surfaces/water.tres")
	water.size_m = Vector3(1000, 10, 1000)
	water.position.y = -5
	add_child_autofree(water)
	vehicle.tuning.hover_trim_n = 0.0
	vehicle.tuning.hover_spring_n_m = 0.0
	vehicle.tuning.hover_damping_ns_m = 0.0
	vehicle.tuning.hover_attraction_n = 0.0
	vehicle.tuning.hover_max_n = 0.0
	vehicle.gravity_scale = 0.0
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, -1, 0)))
	await frames(3)
	vehicle.linear_velocity = Vector3(0, 0, -0.5)
	vehicle.command.brake = 1.0
	for frame in range(20):
		await frames(1)
		assert_lte(vehicle.linear_velocity.z, 0.001, "Fluid drag and braking cannot reverse forward motion")
