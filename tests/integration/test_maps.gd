extends "res://tests/support/game_test.gd"

func lap_length(samples: Array) -> float:
	var length := 0.0
	for i in range(samples.size()):
		var a: Array = samples[i].point
		var b: Array = samples[(i + 1) % samples.size()].point
		length += Vector3(a[0], a[1], a[2]).distance_to(Vector3(b[0], b[1], b[2]))
	return length

func test_long_canyon_length_and_corner_proportions() -> void:
	var first = load("res://maps/map_1.tres")
	var second = load("res://maps/map_2.tres")
	var original: Array = JSON.parse_string(FileAccess.get_file_as_string(first.samples_path))
	var extended: Array = JSON.parse_string(FileAccess.get_file_as_string(second.samples_path))
	assert_almost_eq(lap_length(extended) / lap_length(original), 3.0, 0.001)
	assert_eq(second.corners.size(), first.corners.size(), "Longer course retains six corners")
	assert_lt(second.corner_radius / first.corner_radius, 1.3, "Turns grow only modestly")

func test_long_canyon_continuous_surface_walls_and_clearance() -> void:
	var scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	var controller = scene.get_node("TestTrack")
	controller.select_map(1)
	controller.start_new_race()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var samples: Array = JSON.parse_string(FileAccess.get_file_as_string("res://maps/map_2_samples.json"))
	var space = scene.get_world_3d().direct_space_state
	for sample in samples:
		var p: Array = sample.point
		var n: Array = sample.normal
		var center := Vector3(p[0], p[1], p[2])
		var normal := Vector3(n[0], n[1], n[2])
		for offset in [-12.0, 0.0, 12.0]:
			var point: Vector3 = center + normal * offset
			var road = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2, point - Vector3.UP * 2, 1))
			assert_false(road.is_empty(), "Road covers full width at %s" % point)
			var obstacle = space.intersect_ray(PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.6, point + Vector3.UP * 12, 2))
			assert_true(obstacle.is_empty(), "Road and chase camera clear at %s" % point)
		for side in [-1, 1]:
			var point := center + Vector3.UP * 1.5
			var wall = space.intersect_ray(PhysicsRayQueryParameters3D.create(point, point + normal * side * 17, 2))
			assert_false(wall.is_empty(), "Continuous barriers at %s" % point)

