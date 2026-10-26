extends "res://tests/support/vehicle_test.gd"

func test_wall_damage_uses_normal_speed_and_collision_loss_persists() -> void:
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 10, 1)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 4, -5)
	add_child_autofree(wall)
	await frames(2)
	watch_signals(vehicle)
	vehicle.linear_velocity = Vector3(0, 0, -50)
	await frames(5)
	assert_between(vehicle.health, 63.0, 66.0)
	assert_gt(vehicle.impairment_time, 0.9)
	assert_signal_emit_count(vehicle, "damage_taken", 1)
	assert_lt(vehicle.actual_speed, 1.0)
	await frames(30)
	assert_signal_emit_count(vehicle, "damage_taken", 1)
	assert_lt(vehicle.actual_speed, 1.0)

func test_hard_landing_crashes_and_blocks_subsequent_ability() -> void:
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 12, 0)))
	vehicle.linear_velocity = Vector3(0, -120, 0)
	watch_signals(vehicle)
	await frames(20)
	assert_true(vehicle.is_crashed)
	assert_false(vehicle.activate_ability())
	assert_eq(vehicle.energy, 200.0)
	assert_signal_emit_count(vehicle, "crashed", 1)
	assert_signal_not_emitted(vehicle, "ability_activated")

func test_resting_floor_is_not_damage() -> void:
	watch_signals(vehicle)
	await frames(120)
	assert_eq(vehicle.health, 100.0)
	assert_signal_not_emitted(vehicle, "damage_taken")

func test_moving_surface_relative_normal_damage() -> void:
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 10, 1)
	shape.shape = box
	wall.add_child(shape)
	wall.position = Vector3(0, 4, -5)
	wall.constant_linear_velocity = Vector3(0, 0, -20)
	add_child_autofree(wall)
	await frames(2)
	vehicle.linear_velocity = Vector3(0, 0, -50)
	await frames(5)
	assert_between(vehicle.health, 90.0, 92.0, "30 m/s relative impact instead of 50 m/s absolute")
	assert_eq(vehicle.impairment_time, 0.0)
