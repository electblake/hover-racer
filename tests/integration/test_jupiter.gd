extends "res://tests/support/game_test.gd"

var scene: Node3D
var controller
var jupiter
var ship: VehicleController

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	controller = scene.get_node("TestTrack")
	controller.select_map(3)
	controller.start_new_race()
	jupiter = controller.map_instance
	ship = scene.get_node("SHIP")
	ship.player_controlled = false
	await get_tree().process_frame
	await get_tree().process_frame
	for i in range(5): await get_tree().physics_frame

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_ring_is_continuous_and_pull_is_left_around_whole_lap() -> void:
	assert_eq(controller.map_label.text, "Map 4 — Jupiter — Ringrunner")
	var space := scene.get_world_3d().direct_space_state
	for i in range(360):
		var angle := -TAU * (i + 0.5) / 360.0
		var radial := Vector3(cos(angle), 0, sin(angle))
		var forward := Vector3(sin(angle), 0, -cos(angle))
		var left := Vector3.UP.cross(forward)
		var pull: Vector3 = jupiter.gravity_at(radial * 360)
		assert_gt(pull.dot(left), 4.4, "Inward gravity stays on the left in race direction")
		assert_almost_eq(pull.y, 0.0, 0.001, "Additional gravity is lateral")
		for radius in [344.0, 360.0, 376.0]:
			var point: Vector3 = radial * radius
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 3, point - Vector3.UP, 1))
			assert_false(hit.is_empty(), "Ring support covers the entire circuit")
	assert_eq(jupiter.find_children("GreatRedSpot", "Label3D", true, false).size(), 1, "One storm viewing landmark per circuit")
	assert_eq(jupiter.get_node("GreatRedSpot").position, Vector3(0, 10, -360))

func test_pull_moves_vehicle_and_stops_when_map_is_removed() -> void:
	var start := ship.position
	for i in range(90): await get_tree().physics_frame
	assert_lt(ship.position.x, start.x - 0.3, "Gravity creates actual inward movement")
	assert_lt(ship.linear_velocity.x, -0.1, "Vehicle responds through the physics solver")
	assert_false(ship.is_crashed)
	controller.set_menu_open(true)
	var paused_position := ship.position
	for i in range(6): await get_tree().physics_frame
	assert_eq(ship.position, paused_position, "Pause stops gravity simulation")
	controller.select_map(-3)
	controller.start_new_race()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(is_instance_valid(jupiter), "Map-specific gravity is removed")
	for i in range(45): await get_tree().physics_frame
	assert_almost_eq(ship.position.x, 55.0, 0.05, "No Jupiter pull leaks into canyon")
	assert_almost_eq(ship.get_node("Camera3D").rotation.y, 0.0, 0.001, "Canyon camera restores")

func test_complete_ring_lap_with_ordinary_steering_at_both_tick_rates() -> void:
	for rate in [60, 120]:
		Engine.physics_ticks_per_second = rate
		ship.respawn(controller.MAPS[3].spawn)
		for i in range(5): await get_tree().physics_frame
		var previous_angle := atan2(ship.position.z, ship.position.x)
		var progress := 0.0
		var maximum_error := 0.0
		for frame in range(rate * 80):
			var angle := atan2(ship.position.z, ship.position.x)
			var target := Vector3(cos(angle - 0.12) * 360, ship.position.y, sin(angle - 0.12) * 360)
			var desired := (target - ship.position).normalized()
			var heading_error := (-ship.basis.z).signed_angle_to(desired, Vector3.UP)
			ship.command.steering = clampf(-heading_error * 3.0 + ship.yaw_velocity * 0.3, -1, 1)
			ship.command.throttle = clampf((45.0 - ship.actual_speed) * 0.15, 0, 1)
			await get_tree().physics_frame
			var current_angle := atan2(ship.position.z, ship.position.x)
			progress -= wrapf(current_angle - previous_angle, -PI, PI)
			previous_angle = current_angle
			maximum_error = maxf(maximum_error, absf(Vector2(ship.position.x, ship.position.z).length() - 360))
			if ship.is_crashed or progress >= TAU + 0.1: break
		assert_gt(progress, TAU, "Complete an entire lap using only normal driving commands at %d Hz" % rate)
		assert_lt(maximum_error, 15.0, "Route stays between the rails")
		assert_false(ship.is_crashed)
		assert_gt(ship.health, 95.0)

func test_escape_inner_rail_and_recover_after_fall() -> void:
	ship.respawn(Transform3D(Basis.IDENTITY, Vector3(344, 0.8, 0)))
	ship.command.steering = 1.0
	ship.command.throttle = 0.5
	for i in range(90): await get_tree().physics_frame
	assert_gt(Vector2(ship.position.x, ship.position.z).length(), 346.0, "Right steering overcomes inward pull at the inner edge")
	assert_false(ship.is_crashed)
	ship.respawn(Transform3D(Basis.IDENTITY, Vector3(500, -31, 0)))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(ship.is_crashed, "Off-course fall reaches recoverable crash state")
	controller.start_new_race()
	for i in range(15): await get_tree().physics_frame
	assert_false(ship.is_crashed or ship.freeze)
	assert_true(ship.supported)
