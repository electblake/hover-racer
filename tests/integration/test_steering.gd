extends "res://tests/support/game_test.gd"

var scene: Node3D
var track
var ship

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	ship = scene.get_node("SHIP")

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	super.after_each()

func test_live_steering_tuning() -> void:
	track.start_new_race()
	Input.action_press("left_steer_right")
	Input.action_press("right_steer_right")
	for frame in range(30): await get_tree().physics_frame
	assert_almost_eq(ship.yaw_velocity, -1.8, 0.001, "Held steering uses authored turn speed")
	ship.turn_speed = 2.4
	for frame in range(30): await get_tree().physics_frame
	assert_almost_eq(ship.yaw_velocity, -2.4, 0.001, "Editing the exported property changes the running vehicle")
	Input.action_release("left_steer_right")
	Input.action_release("right_steer_right")

func test_angular_acceleration_release_and_reversal() -> void:
	ship.turn_speed = 2.4
	ship.turn_acceleration = 6.0
	ship.turn_deceleration = 3.0
	track.set_menu_open(false)
	await get_tree().physics_frame
	Input.action_press("left_steer_right")
	Input.action_press("right_steer_right")
	for frame in range(6): await get_tree().physics_frame
	assert_true(is_equal_approx(ship.yaw_velocity, -0.6), "Acceleration ramps angular velocity")
	assert_almost_eq(ship.rotation.y, -0.035, 0.001, "Physical yaw integrates the six fixed-step angular velocities")
	for frame in range(60): await get_tree().physics_frame
	assert_true(is_equal_approx(ship.yaw_velocity, -2.4), "Held steering sustains selected turn speed")
	Input.action_release("left_steer_right")
	Input.action_release("right_steer_right")
	for frame in range(6): await get_tree().physics_frame
	assert_true(is_equal_approx(ship.yaw_velocity, -2.1), "Release reduces yaw by selected deceleration")
	for frame in range(60): await get_tree().physics_frame
	assert_true(ship.yaw_velocity == 0, "Release stops exactly without residual turning")
	Input.action_press("left_steer_left")
	Input.action_press("right_steer_left")
	for frame in range(30): await get_tree().physics_frame
	assert_true(is_equal_approx(ship.yaw_velocity, 2.4), "Opposite steering has symmetric strength")
	Input.action_release("left_steer_left")
	Input.action_release("right_steer_left")
	Input.action_press("left_steer_right")
	Input.action_press("right_steer_right")
	for frame in range(6): await get_tree().physics_frame
	assert_true(is_equal_approx(ship.yaw_velocity, 1.8), "Reversal crosses from current velocity without snapping")
	Input.action_release("left_steer_right")
	Input.action_release("right_steer_right")
	ship.reset_visuals()
	assert_true(ship.yaw_velocity == 0, "Reset clears steering momentum")

