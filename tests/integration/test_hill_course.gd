extends "res://tests/support/game_test.gd"

var scene: Node3D
var ship

func horizontal(ship: CharacterBody3D) -> Vector3:
	return Vector3(ship.velocity.x,0,ship.velocity.z)

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

func test_hover_clearance_on_both_hills() -> void:
	# Traverse each complete hill under power at maximum speed.
	var min_clearance := 100.0
	var max_clearance := -100.0
	for route in [[Vector3(55,2,-5),Vector3(0,0,-ship.max_speed),75],[Vector3(-150,2,-35),Vector3(0,0,ship.max_speed),88]]:
		ship.position = route[0]
		ship.rotation = Vector3(0,atan2(-route[1].x,-route[1].z),0)
		ship.velocity = route[1]
		ship.reset_visuals()
		Input.action_press("thrust")
		var peak := 0.0
		for frame in range(route[2]):
			await get_tree().physics_frame
			var road: Dictionary = ship.road_at(ship.global_position)
			assert_true(not road.is_empty(), "Lost road on hill at %s frame %d" % [ship.position,frame])
			if not road.is_empty():
				var clearance: float = ship.global_position.y-road.position.y
				min_clearance = minf(min_clearance,clearance)
				max_clearance = maxf(max_clearance,clearance)
				assert_true(clearance>0.85 and clearance<2.2, "Unsafe hover clearance: %.3f" % clearance)
			peak = maxf(peak,ship.position.y)
			assert_true(absf(horizontal(ship).length()-ship.max_speed)<0.01, "Hill altered horizontal coast momentum")
			assert_true(ship.rotation.x == 0 and ship.rotation.z == 0, "Physical roll or pitch")
		assert_true(peak>11.0,"Ship failed to follow actual hill height")
	Input.action_release("thrust")

func test_launch_release_and_feedback_bounds() -> void:
	# Powered launch reaches strong speed promptly and repeated taps cannot stack speed.
	ship.position = Vector3(55,2,70)
	ship.velocity = Vector3.ZERO
	ship.rotation = Vector3.ZERO
	ship.reset_visuals()
	Input.action_press("thrust")
	for frame in range(13): await get_tree().physics_frame
	assert_true(horizontal(ship).length()>20,"Launch acceleration too weak")
	for pulse in range(4):
		Input.action_press("thrust")
		for frame in range(5): await get_tree().physics_frame
		Input.action_release("thrust")
		for frame in range(5): await get_tree().physics_frame
		assert_true(horizontal(ship).length()<=ship.max_speed+0.01,"Repeated throttle stacked speed")
	var coast := horizontal(ship)
	for frame in range(30): await get_tree().physics_frame
	assert_true(horizontal(ship).length()<coast.length() and horizontal(ship).length()>0,"Release should glide while slowing")
	assert_true(ship.power_blend<0.02 and not ship.engines[0].visible and not ship.engines[1].visible,"Powered cue did not fade")
	assert_true(ship.camera.fov>=ship.camera_rest_fov and ship.camera.fov<=ship.camera_rest_fov+ship.speed_fov+ship.powered_fov+ship.kick_fov+.01,"Excessive FOV")
	assert_true(ship.visual.position.distance_to(ship.visual_rest_position)<0.25,"Skip too strong")
