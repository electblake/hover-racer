extends "res://tests/support/vehicle_test.gd"

func disable_support_actuators() -> void:
	vehicle.tuning.hover_trim_n = 0.0
	vehicle.tuning.hover_spring_n_m = 0.0
	vehicle.tuning.hover_damping_ns_m = 0.0
	vehicle.tuning.hover_attraction_n = 0.0
	vehicle.tuning.hover_max_n = 0.0
	vehicle.tuning.lateral_force_range_n = Vector2.ZERO
	vehicle.tuning.attitude_max_nm = 0.0
	vehicle.tuning.yaw_damping_nms = 0.0

func water_region() -> FluidRegion3D:
	var water := FluidRegion3D.new()
	water.medium = preload("res://surfaces/water.tres")
	water.size_m = Vector3(1000, 10, 1000)
	water.position.y = -5
	add_child_autofree(water)
	return water

func test_hover_settles_and_payload_sags_without_contact() -> void:
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 1.0, 0)))
	await frames(180)
	assert_almost_eq(vehicle.position.y, 0.8, 0.02)
	assert_true(vehicle.supported)
	assert_eq(vehicle.get_contact_count(), 0)
	vehicle.stats.mass_kg = 720.0
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 1.0, 0)))
	await frames(180)
	assert_almost_eq(vehicle.position.y, 0.79755, 0.001)
	assert_eq(vehicle.health, 100.0)

func test_gap_removes_attraction_and_vehicle_falls() -> void:
	await frames(30)
	floor_body.collision_layer = 0
	await frames(30)
	assert_false(vehicle.supported)
	assert_eq(vehicle.forces.lift_n, 0.0)
	assert_lt(vehicle.linear_velocity.y, -4.0)

func test_same_engine_accelerates_half_as_much_at_double_mass() -> void:
	disable_support_actuators()
	vehicle.gravity_scale = 0.0
	vehicle.tuning.drag_area_cd = Vector3.ZERO
	vehicle.stats.requires_support = false
	var changes: Array[float] = []
	for mass_kg in [600.0, 1200.0]:
		vehicle.stats.mass_kg = mass_kg
		vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 100, 0)))
		await frames(2)
		vehicle.command.throttle = 1.0
		await frames(2)
		var initial := vehicle.linear_velocity
		await frames(12)
		changes.append((vehicle.linear_velocity - initial).length())
	assert_between(changes[0], 5.4, 6.1)
	assert_almost_eq(changes[0] / changes[1], 2.0, 0.03)

func test_torque_uses_inertia_and_preserves_rotation_without_damping() -> void:
	disable_support_actuators()
	vehicle.gravity_scale = 0.0
	vehicle.tuning.drag_area_cd = Vector3.ZERO
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 100, 0)))
	await frames(2)
	var inertia_y := 1.0 / vehicle.get_inverse_inertia_tensor().y.y
	vehicle.constant_torque = Vector3(0, 1500, 0)
	await frames(60)
	vehicle.constant_torque = Vector3.ZERO
	assert_almost_eq(vehicle.angular_velocity.y, 1500.0 / inertia_y, 0.04)
	var spin := vehicle.angular_velocity.y
	await frames(120)
	assert_almost_eq(vehicle.angular_velocity.y, spin, 0.01)

func test_unpowered_hull_floats_at_displaced_weight() -> void:
	disable_support_actuators()
	floor_body.position.y = -11
	water_region()
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.5, 0)))
	await frames(900)
	assert_almost_eq(vehicle.forces.immersion * vehicle.stats.displacement_m3, 0.6, 0.025)
	assert_almost_eq(vehicle.forces.buoyancy_n, 5880.0, 250.0)
	assert_lt(absf(vehicle.linear_velocity.y), 0.1)
	assert_eq(vehicle.health, 100.0)

func test_current_moves_immersed_hull_and_air_does_not_support_it() -> void:
	disable_support_actuators()
	floor_body.position.y = -11
	var water := water_region()
	water.flow_velocity = Vector3(5, 0, 0)
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0, 0)))
	await frames(180)
	assert_gt(vehicle.linear_velocity.x, 2.0)
	assert_lt(vehicle.linear_velocity.x, 5.1)
	water.medium = preload("res://surfaces/air.tres")
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 2, 0)))
	await frames(30)
	assert_false(vehicle.supported)
	assert_lt(vehicle.linear_velocity.y, -4.0)

func test_ice_only_changes_real_contact_friction() -> void:
	var speeds: Array[float] = []
	for surface in [preload("res://surfaces/road.tres"), preload("res://surfaces/ice.tres")]:
		floor_body.physics_material_override.friction = surface.friction
		vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.8, 0)))
		vehicle.linear_velocity = Vector3(0, 0, -30)
		await frames(30)
		speeds.append(vehicle.actual_speed)
	assert_almost_eq(speeds[0], speeds[1], 0.1, "No tyre friction while hovering")
	disable_support_actuators()
	speeds.clear()
	for surface in [preload("res://surfaces/road.tres"), preload("res://surfaces/ice.tres")]:
		floor_body.physics_material_override.friction = surface.friction
		vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.21, 0)))
		vehicle.linear_velocity = Vector3(0, 0, -30)
		await frames(60)
		speeds.append(vehicle.actual_speed)
	assert_gt(speeds[1], speeds[0] + 3.0, "Ice loses less momentum on contact")

func test_high_speed_water_entry_is_finite_and_dissipative_at_both_rates() -> void:
	disable_support_actuators()
	floor_body.position.y = -11
	water_region()
	var speeds: Array[float] = []
	for rate in [60, 120]:
		Engine.physics_ticks_per_second = rate
		vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, 0.1, 0)))
		vehicle.linear_velocity = Vector3(0, -5, -140)
		for frame in range(rate):
			await frames(1)
			assert_true(vehicle.linear_velocity.is_finite())
			assert_lt(vehicle.linear_velocity.length(), 141.0)
			assert_lte(vehicle.linear_velocity.z, 0.1, "Drag does not reverse travel")
		speeds.append(vehicle.linear_velocity.length())
	assert_almost_eq(speeds[0], speeds[1], 1.0)

func test_physics_lab_has_liquid_surface_and_wind_regions() -> void:
	var lab := preload("res://PhysicsTestTrack.tscn").instantiate()
	add_child_autofree(lab)
	assert_true(lab.get_node("WaterCurrent").medium.liquid)
	assert_eq(lab.get_node("WaterCurrent").surface_height(), 0.0)
	assert_eq(lab.get_node("Crosswind").flow_velocity, Vector3(20, 0, 0))

func test_overlapping_fluids_do_not_double_count_displacement() -> void:
	disable_support_actuators()
	floor_body.position.y = -11
	var water := water_region()
	water.medium_priority = 2
	var duplicate := water_region()
	duplicate.medium_priority = 1
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, -2, 0)))
	await frames(3)
	assert_almost_eq(vehicle.forces.immersion, 1.0, 0.001)
	assert_almost_eq(vehicle.forces.buoyancy_n, 11760.0, 2.0, "Only one liquid occupies each sample fraction")

func test_matching_flow_has_no_drag_and_one_sided_entry_turns_hull() -> void:
	disable_support_actuators()
	floor_body.position.y = -11
	var water := water_region()
	# A fresh zero-gravity body has no pending hover/gravity impulse from the fixture.
	vehicle.queue_free()
	vehicle = VehicleController.new()
	vehicle.player_controlled = false
	vehicle.gravity_scale = 0.0
	disable_support_actuators()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 0.4, 4.6)
	collider.shape = box
	vehicle.add_child(collider)
	vehicle.position = Vector3(0, -2, 0)
	add_child_autofree(vehicle)
	await frames(3)
	vehicle.linear_velocity = Vector3(10, 0, 0)
	vehicle.angular_velocity = Vector3.ZERO
	water.flow_velocity = Vector3(10, 0, 0)
	await frames(3)
	assert_almost_eq(vehicle.forces.drag_n, 0.0, 0.01)
	water.flow_velocity = Vector3.ZERO
	water.size_m.x = 100.0
	water.position.x = 50.0
	vehicle.respawn(Transform3D(Basis.IDENTITY, Vector3(0, -2, 0)))
	vehicle.linear_velocity = Vector3(0, 0, -30)
	await frames(5)
	assert_gt(absf(vehicle.angular_velocity.y), 0.1, "Drag on one side applies a yaw moment")
