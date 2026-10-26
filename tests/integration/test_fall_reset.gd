extends "res://tests/support/game_test.gd"

func test_fall_reset() -> void:
	var scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	scene.get_node("TestTrack").set_menu_open(false)
	var ship = scene.get_node("SHIP")
	await get_tree().physics_frame
	await get_tree().physics_frame
	# A fall, rather than the reset button, must restore a playable vehicle.
	ship.position = Vector3(500, -29, 500)
	ship.rotation.y = 1.2
	ship.velocity = Vector3(20, -80, 10)
	for frame in range(3):
		await get_tree().physics_frame
	assert_true(ship.position.distance_to(Vector3(55, 2, 30)) < 0.1, "Falling off the course returns to spawn")
	assert_true(ship.rotation.is_zero_approx(), "Fall reset restores heading")
	assert_true(Vector2(ship.velocity.x, ship.velocity.z).is_zero_approx(), "Fall reset clears horizontal momentum")
	assert_true(ship.applied_thrust == 0 and ship.thrust_envelope.level == 0, "Fall reset clears thrust")
	assert_true(ship.camera.position.is_equal_approx(ship.camera_rest_position), "Fall reset restores camera")
	assert_true(not ship.wind_audio.playing, "Fall reset stops wind")
	Input.action_press("thrust")
	for frame in range(12):
		await get_tree().physics_frame
	assert_true(Vector2(ship.velocity.x, ship.velocity.z).length() > 20, "Vehicle can accelerate after a fall reset")
	Input.action_release("thrust")
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
