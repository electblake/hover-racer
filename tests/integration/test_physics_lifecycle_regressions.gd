extends "res://tests/support/vehicle_test.gd"

func test_respawn_clears_force_telemetry_before_first_tick() -> void:
	vehicle.command.throttle = 1.0
	await frames(30)
	assert_gt(vehicle.forces.thrust_n, 0.0)
	vehicle.crash("audit")
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
	assert_eq(vehicle.forces.thrust_n, 0.0)
	assert_eq(vehicle.forces.lift_n, 0.0)
	assert_eq(vehicle.forces.drag_n, 0.0)
	assert_eq(vehicle.forces.support_fraction, 0.0)

func test_sandbox_gate_holds_body_and_resumes_momentum() -> void:
	vehicle.command.throttle = 1.0
	await frames(45)
	var initial := vehicle.linear_velocity
	var location := vehicle.position
	vehicle.gate_input(false)
	await frames(30)
	assert_almost_eq(vehicle.position.distance_to(location), 0.0, 0.001)
	vehicle.gate_input(true)
	await frames(3)
	assert_gt(vehicle.linear_velocity.length(), initial.length() * 0.9)
	assert_lte(vehicle.linear_velocity.length(), initial.length() + 0.05, "Resume cannot inject thrust")

func test_spin_at_rest_stays_finite_and_reset_clears_angular_motion() -> void:
	vehicle.respawn(Transform3D(Basis(Vector3.FORWARD, PI), Vector3(0, 20, 0)))
	vehicle.angular_velocity = Vector3(3, 4, 2)
	await frames(30)
	assert_true(vehicle.linear_velocity.is_finite())
	assert_true(vehicle.angular_velocity.is_finite())
	vehicle.crash("audit")
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
	await frames(60)
	assert_false(vehicle.is_crashed)
	assert_lt(vehicle.angular_velocity.length(), 0.01)
	assert_eq(vehicle.health, 100.0)

func test_respawn_while_gated_does_not_restore_old_momentum() -> void:
	vehicle.command.throttle = 1.0
	await frames(60)
	vehicle.gate_input(false)
	await frames(10)
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
	vehicle.gate_input(true)
	await frames(10)
	assert_lt(vehicle.actual_speed, 0.05)
	assert_false(vehicle.freeze or vehicle.is_crashed)

func test_quick_repeated_gates_preserve_one_motion_snapshot() -> void:
	vehicle.command.throttle = 1.0
	await frames(60)
	var initial := vehicle.linear_velocity
	vehicle.gate_input(false)
	await frames(10)
	vehicle.gate_input(true)
	vehicle.gate_input(false)
	vehicle.gate_input(true)
	await frames(3)
	assert_gt(vehicle.linear_velocity.length(), initial.length() * 0.9)
	assert_lte(vehicle.linear_velocity.length(), initial.length() + 0.05)
