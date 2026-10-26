extends "res://tests/support/game_test.gd"

var scene: Node3D
var ship

func horizontal(ship: VehicleController) -> Vector3:
	return Vector3(ship.linear_velocity.x,0,ship.linear_velocity.z)

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	scene.get_node("TestTrack").set_menu_open(false)
	await get_tree().physics_frame
	await get_tree().physics_frame
	ship = scene.get_node("SHIP")

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_road_cross_sections_and_barriers() -> void:
	var space = scene.get_world_3d().direct_space_state
	var samples = JSON.parse_string(FileAccess.get_file_as_string("res://tools/course_samples.json"))
	for sample in samples:
		var a: Array = sample.point
		var b: Array = sample.normal
		var center := Vector3(a[0],a[1],a[2])
		var normal := Vector3(b[0],b[1],b[2])
		for offset in [-12.0,0.0,12.0]:
			var point: Vector3 = center + normal * offset
			var ray := PhysicsRayQueryParameters3D.create(point+Vector3.UP*20,point-Vector3.UP*2,1,[ship.get_rid()])
			var road = space.intersect_ray(ray)
			assert_true(not road.is_empty(), "Road gap: %s" % point)
			if not road.is_empty():
				assert_true(absf(road.position.y-center.y)<0.05, "Uneven cross section: %s" % point)
		for side in [-1,1]:
			var point := center + Vector3.UP*1.5
			var wall = space.intersect_ray(PhysicsRayQueryParameters3D.create(point,point+normal*side*17,2))
			assert_true(not wall.is_empty(), "Barrier gap: %s" % point)


func test_grounded_hill_traversal_preserves_health_and_speed_bounds() -> void:
	for route in [[Vector3(55, 0.8, -5), 0.0, 10.0], [Vector3(-150, 0.8, -35), PI, 14.0]]:
		ship.respawn(Transform3D(Basis(Vector3.UP, route[1]), route[0]))
		ship.player_controlled = false
		ship.command.throttle = 1.0
		var peak := 0.0
		for frame in range(250):
			await get_tree().physics_frame
			peak = maxf(peak, ship.position.y)
			assert_false(ship.is_crashed, "Hill must not crash the vehicle")
			assert_lte(ship.actual_speed, 90.1, "No slope speed creation")
			if (ship.position.z < -110 and route[1] == 0.0) or (ship.position.z > 110 and route[1] != 0.0): break
		assert_gt(peak, route[2], "Follow the actual hill")
		assert_gt(ship.health, 95.0, "Ordinary floor support is not an impact")

func test_boost_speed_follows_crest_and_descent_at_60_and_120_hz() -> void:
	ship.player_controlled = false
	for rate in [60, 120]:
		Engine.physics_ticks_per_second = rate
		ship.respawn(Transform3D(Basis.IDENTITY, Vector3(55, 0.8, -8)))
		await get_tree().physics_frame
		await get_tree().physics_frame
		ship.linear_velocity = Vector3(0, 0, -140)
		var maximum_clearance := 0.0
		var missed := 0
		for frame in range(rate):
			await get_tree().physics_frame
			var point: Vector3 = ship.global_position
			# A finite footprint measures clearance across triangle seams without
			# depending on a zero-width ray hitting an exact shared edge.
			var query := PhysicsShapeQueryParameters3D.new()
			var probe := SphereShape3D.new()
			probe.radius = 0.02
			query.shape = probe
			query.transform = Transform3D(Basis.IDENTITY, point + Vector3.UP)
			query.motion = Vector3.DOWN * 16.0
			query.collision_mask = 1
			query.exclude = [ship.get_rid()]
			var travel: PackedFloat32Array = ship.get_world_3d().direct_space_state.cast_motion(query)
			assert_lt(travel[0], 1.0, "High-speed route retains a road below it at %s" % point)
			maximum_clearance = maxf(maximum_clearance, travel[0] * 16.0 - 1.0 + probe.radius)
			if not ship.supported: missed += 1
			if point.z < -112: break
		print("Crest ", rate, " Hz clearance ", maximum_clearance, " missed ", missed, " health ", ship.health)
		assert_lt(maximum_clearance, 2.0, "Hover attraction follows descending track without launching")
		assert_lte(missed, 1, "Support remains engaged across the crest")
		assert_gt(ship.health, 95.0)
