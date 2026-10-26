extends "res://tests/support/game_test.gd"

var scene: Node3D
var ship

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	scene.get_node("TestTrack").set_menu_open(false)
	await frames(3)
	ship = scene.get_node("SHIP")

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_road_and_camera_clearance() -> void:
	var space = scene.get_world_3d().direct_space_state
	var count := 0
	for z in range(-106,82,2):
		var road: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(55, 40, z), Vector3(55, -2, z), 1, [ship.get_rid()]))
		assert_true(not road.is_empty(),"Missing canyon road")
		if road.is_empty(): continue
		for x in [43.5,49.0,55.0,61.0,66.5]:
			var point := Vector3(x,road.position.y+.6,z)
			var obstacles = space.intersect_ray(PhysicsRayQueryParameters3D.create(point,point+Vector3.UP*12,2))
			assert_true(obstacles.is_empty(),"Scenery/arch blocks road or camera at %s" % point)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = ship.get_node("CollisionShape3D").shape
			query.transform = Transform3D(Basis.IDENTITY,Vector3(x,road.position.y+1.5,z))
			query.collision_mask = 2
			var hits = space.intersect_shape(query)
			assert_true(hits.is_empty(),"Ship envelope hits canyon at %s" % point)
			count += 1

func test_model_audio_and_power_feedback() -> void:
	# Model silhouette and independent visual response.
	assert_true(ship.visual.mesh == null,"Old box must be replaced")
	assert_true(ship.pod_visual.has_node("Engines/Terra/LeftEnginePod") and ship.pod_visual.has_node("Engines/Terra/RightEnginePod") and ship.pod_visual.has_node("Core/Terra/TrailingCockpit"),"Twin engines and cockpit belong to cosmetic modules")
	assert_true(ship.engines.size()==2 and ship.engines[0].position.x<-.9 and ship.engines[1].position.x>.9,"Separated independent exhausts")
	for player in ship.engine_audio+[ship.wind_audio]:
		assert_true(player.stream is AudioStreamWAV and player.stream.get_length()>1.9,"Audio loaded")
		assert_true(player.stream.loop_mode==AudioStreamWAV.LOOP_FORWARD,"Audio must loop")
	ship.reset_visuals()
	ship.respawn(Transform3D(Basis.IDENTITY, Vector3(55,0.8,60)))
	ship.linear_velocity = Vector3.ZERO
	var camera_rotation: Vector3 = ship.camera.rotation
	var collider_transform: Transform3D = ship.get_node("CollisionShape3D").transform
	Input.action_press("throttle")
	await frames(12)
	assert_true(ship.engines[0].visible and ship.engines[1].visible,"Both exhausts share RT")
	assert_true(not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Engine audio must remain disabled under power")
	await frames(18)
	assert_true(not ship.engine_audio[0].playing and not ship.engine_audio[1].playing and ship.wind_audio.playing,"Wind retained, engines disabled")
	assert_true(ship.camera.position.z>ship.camera_rest_position.z+.4 and ship.camera.position.z<ship.camera_rest_position.z+ship.camera_pullback+ship.camera_kick_pullback+.01,"Restrained thrust pullback")
	assert_true(ship.camera.rotation.is_equal_approx(camera_rotation),"Camera must not roll or shake")
	assert_true(ship.get_node("CollisionShape3D").transform.is_equal_approx(collider_transform),"Visuals must not alter collider")
	Input.action_release("throttle")
	await frames(2)
	assert_true(ship.applied_thrust==0,"Release completes before passive coast")
	var coast_speed: float = Vector2(ship.linear_velocity.x,ship.linear_velocity.z).length()
	await frames(30)
	assert_true(not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Engine audio stops after release")
	assert_true(ship.wind_audio.playing,"Wind must continue during coast")
	assert_between(Vector2(ship.linear_velocity.x,ship.linear_velocity.z).length(), coast_speed * 0.95, coast_speed, "Low-speed passive drag preserves momentum")
	assert_true(ship.camera.position.distance_to(ship.camera_rest_position)<.08,"Camera returns on release")
	ship.reset_visuals()
	assert_true(not ship.wind_audio.playing and not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Reset stops all audio")
	assert_true(ship.visual_reset_pending, "Camera placement waits for the physics tick")
	await frames(2)
	assert_false(ship.visual_reset_pending)
	assert_true(ship.camera.position.is_equal_approx(ship.camera_rest_position),"Reset restores camera")
