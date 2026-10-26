extends "res://tests/support/game_test.gd"
func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame
func test_power_contrast() -> void:
	var scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	scene.get_node("TestTrack").set_menu_open(false)
	await frames(3)
	var ship = scene.get_node("SHIP")
	ship.position = Vector3(55,2,70)
	ship.velocity = Vector3.ZERO
	ship.reset_visuals()
	Input.action_press("thrust")
	await frames(6)
	var speed: float = Vector2(ship.velocity.x,ship.velocity.z).length()
	assert_true(speed>=14 and speed<=16,"Attack ramps launch to about 15m/s in 0.1s")
	assert_true(ship.camera.position.z-ship.camera_rest_position.z>.25,"Prompt camera pullback on gas")
	assert_true(ship.camera.fov-ship.camera_rest_fov>1,"Prompt FOV response on gas")
	var reached_cap := -1
	var max_pull := 0.0
	var max_fov := 0.0
	var prior_camera: Vector3 = ship.camera.position
	var prior_fov: float = ship.camera.fov
	for frame in range(24):
		await get_tree().physics_frame
		var current: float = Vector2(ship.velocity.x,ship.velocity.z).length()
		if current>=ship.max_speed-.01 and reached_cap<0: reached_cap=frame+7
		assert_true(current<=ship.max_speed+.01,"No speed overshoot")
		max_pull=maxf(max_pull,ship.camera.position.z-ship.camera_rest_position.z)
		max_fov=maxf(max_fov,ship.camera.fov-ship.camera_rest_fov)
		assert_true(ship.camera.position.distance_to(prior_camera)<.2 and absf(ship.camera.fov-prior_fov)<1.5,"Camera onset must stay smooth")
		prior_camera=ship.camera.position
		prior_fov=ship.camera.fov
	assert_true(reached_cap>=24 and reached_cap<=27,"Attack and sustain reach cap in about 0.42 seconds")
	assert_true(max_pull>.9 and max_pull<=1.5,"Stronger bounded pullback")
	assert_true(max_fov>8 and max_fov<=12,"Stronger bounded FOV")
	var powered_fov: float = ship.camera.fov
	Input.action_release("thrust")
	await frames(ceili(ship.thrust_release * 60) + 1)
	await frames(30)
	assert_true(ship.camera.position.distance_to(ship.camera_rest_position)<.08,"Camera returns when coasting")
	assert_true(powered_fov-ship.camera.fov>4,"Clear power/coast FOV contrast")
	assert_true(not ship.engines[0].visible and not ship.engines[1].visible,"Exhaust switches off on release")
	for pulse in range(6):
		Input.action_press("thrust")
		await frames(2)
		Input.action_release("thrust")
		await frames(2)
		assert_true(Vector2(ship.velocity.x,ship.velocity.z).length()<=104.01,"Gas taps must not stack physical boosts")
		assert_true(ship.throttle_kick<=1 and ship.camera.position.z-ship.camera_rest_position.z<=1.5,"Gas taps must not stack camera kick")
	ship.reset_visuals()
	assert_true(ship.throttle_kick==0 and ship.previous_power==0 and ship.camera.position.is_equal_approx(ship.camera_rest_position),"Reset clears onset effect")
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
