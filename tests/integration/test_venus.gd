extends "res://tests/support/game_test.gd"

var scene: Node3D
var controller
var venus
var ship

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	controller = scene.get_node("TestTrack")
	controller.select_map(2)
	controller.start_new_race()
	venus = controller.map_instance
	ship = scene.get_node("SHIP")
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

func after_each() -> void:
	var wind_stream: WeakRef = weakref(ship.wind_audio.stream)
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	# AudioServer retires stopped playback on its mixer thread, independently
	# of fixed-FPS simulation ticks. Observe release before ending the fixture.
	while wind_stream.get_ref() != null:
		await get_tree().process_frame
	super.after_each()

func test_flat_liquid_course_has_continuous_support() -> void:
	assert_eq(controller.map_label.text, "Map 3 — Venus — Aureate Sea")
	assert_same(controller.environment.environment, load("res://maps/venus_environment.tres"))
	var samples: Array = JSON.parse_string(FileAccess.get_file_as_string("res://maps/map_3_samples.json"))
	var sea: FluidRegion3D = venus.get_node("AureateSeaPhysics")
	assert_eq(venus.get_node("Road/RoadCollision").collision_layer, 0, "Liquid permits penetration")
	assert_eq(sea.surface_height(), 0.5, "Physics matches the rendered liquid plane")
	for sample in samples:
		var p: Array = sample.point
		var n: Array = sample.normal
		for offset in [-12.0, 0.0, 12.0]:
			var point: Vector3 = Vector3(p[0], p[1], p[2]) + Vector3(n[0], n[1], n[2]) * offset
			assert_true(sea.contains_horizontal(point), "Liquid supports the whole marked course")
	assert_true(ship.supported)

func test_wet_surface_retains_more_sideways_momentum_and_brakes_slower() -> void:
	ship.player_controlled = false
	for i in range(60): await get_tree().physics_frame
	var placement: Transform3D = ship.global_transform
	var sea: FluidRegion3D = venus.get_node("AureateSeaPhysics")
	var wet_surface := sea.surface
	var sideways_speeds: Array[float] = []
	var braking_speeds: Array[float] = []
	for surface in [wet_surface, preload("res://surfaces/road.tres")]:
		sea.surface = surface
		ship.respawn(placement)
		for i in range(2): await get_tree().physics_frame
		ship.linear_velocity = placement.basis * Vector3(8, 0, -40)
		for i in range(20): await get_tree().physics_frame
		sideways_speeds.append(absf(ship.linear_velocity.dot(ship.global_basis.x)))
		assert_true(ship.supported, "Wet handling preserves hover support")
		ship.respawn(placement)
		for i in range(2): await get_tree().physics_frame
		ship.linear_velocity = -placement.basis.z * 40.0
		ship.command.brake = 1.0
		for i in range(20): await get_tree().physics_frame
		braking_speeds.append(ship.actual_speed)
		assert_false(ship.is_crashed)
	sea.surface = wet_surface
	assert_gt(sideways_speeds[0], sideways_speeds[1] + 2.0, "Venus retains sideways slide longer than dry-road grip")
	assert_gt(braking_speeds[0], braking_speeds[1] + 2.0, "Venus takes longer to brake than dry-road grip")

func test_wakes_follow_racer_and_pause_with_weather() -> void:
	ship.player_controlled = false
	ship.command.throttle = 1.0
	for i in range(90): await get_tree().physics_frame
	var strongest := 0.0
	for wake in venus.wakes: strongest = maxf(strongest, wake.w)
	assert_gt(strongest, 0.2, "Moving racer disturbs the liquid")
	assert_almost_eq(venus.rain.global_position.x, ship.global_position.x, 2.0)
	assert_almost_eq(venus.rain.global_position.z, ship.global_position.z, 2.0)
	assert_false(ship.is_crashed, "Liquid straight remains driveable")
	controller.set_menu_open(true)
	var paused_time: float = venus.elapsed
	for i in range(5): await get_tree().process_frame
	assert_eq(venus.elapsed, paused_time, "Liquid animations stop with race pause")
	controller.select_map(-2)
	controller.start_new_race()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(is_instance_valid(venus), "Venus weather is removed when changing maps")
	assert_same(controller.environment.environment, load("res://maps/canyon_environment.tres"), "Canyon lighting restored")

func test_wet_braking_can_stop_and_accelerate_again_at_both_tick_rates() -> void:
	ship.player_controlled = false
	for hz in [60, 120]:
		Engine.physics_ticks_per_second = hz
		controller.start_new_race()
		for i in range(hz): await get_tree().physics_frame
		ship.linear_velocity = Vector3(0, 0, -40)
		ship.command.brake = 1.0
		for i in range(hz * 6): await get_tree().physics_frame
		assert_lt(ship.actual_speed, 0.2, "Wet brakes can stop at %d Hz" % hz)
		assert_false(ship.is_crashed)
		assert_true(ship.supported)
		ship.command.brake = 0.0
		ship.command.throttle = 1.0
		for i in range(hz): await get_tree().physics_frame
		assert_gt(ship.actual_speed, 10.0, "Driving resumes after a wet stop")
	Engine.physics_ticks_per_second = 60

func test_crash_reset_and_map_switch_do_not_lock_driving() -> void:
	var lab_index: int = controller.MAPS.find(preload("res://maps/physics_lab.tres"))
	for index in [2, 0, 2, lab_index, 2, 1]:
		controller.set_menu_open(true)
		controller.select_map(index - controller.selected_map)
		controller.start_new_race()
		for i in range(30): await get_tree().physics_frame
		ship.crash("test impact")
		controller.set_menu_open(true)
		controller.resume_button.pressed.emit()
		assert_true(ship.freeze, "Resuming keeps a crashed ship stopped")
		var press := InputEventAction.new()
		press.action = "reset_ship"
		press.pressed = true
		Input.parse_input_event(press)
		var release := InputEventAction.new()
		release.action = "reset_ship"
		Input.parse_input_event(release)
		Input.flush_buffered_events()
		assert_false(ship.is_crashed, "Reset clears crash on map %d" % index)
		assert_false(ship.freeze, "Reset unfreezes ship")
		Input.action_press("throttle")
		for i in range(60): await get_tree().physics_frame
		Input.action_release("throttle")
		assert_gt(ship.actual_speed, 5.0, "Driving remains available after reset")
		assert_false(get_tree().paused)
		assert_eq(get_tree().get_nodes_in_group("fluid_regions").size(), 1 if index == 2 else (2 if index == lab_index else 0), "Old map fluid regions are removed")

func test_wet_turn_and_countersteer_remain_controllable() -> void:
	ship.player_controlled = false
	for hz in [60, 120]:
		Engine.physics_ticks_per_second = hz
		controller.start_new_race()
		for i in range(hz): await get_tree().physics_frame
		ship.linear_velocity = Vector3(0, 0, -20)
		ship.command.steering = 0.5
		for i in range(hz): await get_tree().physics_frame
		assert_lt(ship.rotation.y, -0.3, "Wet vehicle can turn at a safe corner speed")
		ship.command.steering = -0.5
		for i in range(hz): await get_tree().physics_frame
		assert_gt(ship.yaw_velocity, 0.1, "Countersteering reverses the turn")
		ship.command.steering = 0.0
		ship.command.brake = 1.0
		for i in range(hz * 3): await get_tree().physics_frame
		assert_lt(absf(ship.yaw_velocity), 0.05, "Releasing steering arrests rotation")
		assert_lt(ship.actual_speed, 0.2, "A slide can be brought to a stop")
		assert_false(ship.is_crashed)
		assert_true(ship.supported)
	Engine.physics_ticks_per_second = 60

func test_off_course_fall_can_restart_on_venus() -> void:
	ship.respawn(Transform3D(Basis.IDENTITY, Vector3(1000, -31, 1000)))
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(ship.is_crashed)
	assert_true(ship.freeze)
	assert_eq(ship.crash_reason, "fell off course")
	controller.set_menu_open(true)
	controller.new_race_button.pressed.emit()
	Input.action_press("throttle")
	for i in range(60): await get_tree().physics_frame
	Input.action_release("throttle")
	assert_false(ship.is_crashed)
	assert_false(ship.freeze)
	assert_true(ship.supported)
	assert_gt(ship.actual_speed, 10.0)

func test_submerged_venus_racer_can_recover_without_reset() -> void:
	ship.player_controlled = false
	ship.respawn(Transform3D(Basis.IDENTITY, Vector3(55, -0.5, 30)))
	ship.command.throttle = 1.0
	for i in range(600): await get_tree().physics_frame
	assert_gt(ship.position.y, 0.5, "A submerged racer returns above the Venus liquid")
	assert_true(ship.supported)
	assert_gt(ship.actual_speed, 10.0, "Liquid entry does not trap the racer without propulsion")
	assert_false(ship.is_crashed)
