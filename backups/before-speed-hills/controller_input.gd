# Run: Godot --headless --path . --script res://tests/controller_input.gd
extends SceneTree

func require(condition: bool, message: String) -> void:
	if not condition:
		push_error(message)
		quit(1)
		assert(condition, message)

func axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame

func _initialize() -> void:
	call_deferred("check")

func check() -> void:
	var scene = load("res://Main.tscn").instantiate()
	root.add_child(scene)
	await frames(3)
	var ship = scene.get_node("SHIP")
	require(ship.max_speed == 40 and ship.acceleration == 50, "Saved tuning changed")
	for action in ["thrust", "brake", "steer_left", "steer_right", "gentle_left", "gentle_right", "reset_ship"]:
		require(InputMap.has_action(action), "Missing action: " + action)
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.03)
	require(Input.get_action_strength("thrust") == 0, "Trigger deadzone")
	axis(JOY_AXIS_TRIGGER_RIGHT, 0.5)
	var half := Input.get_action_strength("thrust")
	require(half > 0 and half < 1, "Partial trigger response")
	await frames(15)
	var partial_speed: float = ship.velocity.length()
	require(partial_speed > 0 and partial_speed < 12, "Partial throttle movement")
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	await frames(15)
	require(ship.velocity.length() > partial_speed + 8, "Full throttle movement")
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	var coast: Vector3 = ship.velocity
	var camera = ship.get_node("Camera3D")
	var collision = ship.get_node("CollisionShape3D")
	var camera_rest: Transform3D = camera.transform
	var collision_rest: Transform3D = collision.transform
	var body_height: float = ship.position.y
	axis(JOY_AXIS_LEFT_X, 0.1)
	require(Input.get_action_strength("gentle_right") == 0, "Gentle stick deadzone")
	axis(JOY_AXIS_LEFT_X, 1.0)
	require(Input.get_axis("steer_right", "steer_left") == 0, "Left stick must not activate strong yaw")
	var gentle_yaw: float = ship.rotation.y
	await frames(12)
	var gentle_change: float = absf(ship.rotation.y - gentle_yaw)
	require(gentle_change > 0.05, "Gentle steering rotates ship")
	require(ship.visual.rotation.z < -0.1, "Right gentle steering banks right")
	require(ship.velocity.is_equal_approx(coast), "Gentle coast steering preserves momentum")
	axis(JOY_AXIS_LEFT_X, -1.0)
	await frames(18)
	require(ship.visual.rotation.z > 0.1, "Left gentle steering banks left")
	axis(JOY_AXIS_LEFT_X, 0.0)
	var bank_before: float = absf(ship.visual.rotation.z)
	await frames(12)
	require(absf(ship.visual.rotation.z) < bank_before, "Bank returns smoothly to level")
	require(ship.visual.position.distance_to(ship.visual_rest_position) > 0.001, "Visible hover bob")
	require(camera.transform.is_equal_approx(camera_rest) and collision.transform.is_equal_approx(collision_rest), "Visual effects moved camera or collision")
	require(is_equal_approx(ship.position.y, body_height) and ship.rotation.x == 0 and ship.rotation.z == 0, "Physical body must remain level")
	axis(JOY_AXIS_RIGHT_X, 1.0)
	require(Input.get_action_strength("gentle_right") == 0, "Right stick must not activate gentle steering")
	var strong_yaw: float = ship.rotation.y
	await frames(12)
	require(absf(ship.rotation.y - strong_yaw) > gentle_change * 2.0, "Right stick provides stronger yaw")
	axis(JOY_AXIS_RIGHT_X, 0.0)
	axis(JOY_AXIS_RIGHT_X, 0.1)
	require(Input.get_axis("steer_right", "steer_left") == 0, "Stick deadzone")
	axis(JOY_AXIS_RIGHT_X, 0.5)
	require(Input.get_action_strength("steer_right") > 0 and Input.get_action_strength("steer_right") < 1, "Analog steering")
	var yaw: float = ship.rotation.y
	await frames(10)
	require(ship.rotation.y < yaw, "Right steering direction")
	require(ship.velocity.is_equal_approx(coast), "Coasting momentum changed while rotating")
	axis(JOY_AXIS_RIGHT_X, -0.5)
	yaw = ship.rotation.y
	await frames(5)
	require(ship.rotation.y > yaw, "Left steering direction")
	axis(JOY_AXIS_RIGHT_X, 0)
	axis(JOY_AXIS_TRIGGER_RIGHT, 1)
	await frames(10)
	require(not ship.velocity.normalized().is_equal_approx(coast.normalized()), "Thrust should redirect momentum")
	axis(JOY_AXIS_TRIGGER_RIGHT, 0)
	var before_brake: float = ship.velocity.length()
	axis(JOY_AXIS_TRIGGER_LEFT, 0.5)
	await frames(10)
	require(ship.velocity.length() < before_brake, "Analog braking")
	axis(JOY_AXIS_TRIGGER_LEFT, 0)
	# Neutral controller input leaves the keyboard fully usable.
	key(KEY_UP, true)
	require(Input.get_action_strength("thrust") == 1, "Keyboard thrust")
	key(KEY_UP, false)
	key(KEY_DOWN, true)
	require(Input.get_action_strength("brake") == 1, "Keyboard brake")
	key(KEY_DOWN, false)
	key(KEY_LEFT, true)
	require(Input.get_action_strength("steer_left") == 1, "Keyboard steering")
	key(KEY_LEFT, false)
	var button := InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_Y
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	await frames(2)
	require(ship.position.is_equal_approx(Vector3(55, 2, 30)) and ship.velocity == Vector3.ZERO, "Y reset")
	button.pressed = false
	Input.parse_input_event(button)
	ship.position.z = 10
	key(KEY_R, true)
	await frames(2)
	require(ship.position.is_equal_approx(Vector3(55, 2, 30)), "Keyboard reset")
	key(KEY_R, false)
	print("PASS: separate gentle/strong sticks, banking, hover, stable body/camera/collision, analog movement, momentum, keyboard and Y/R reset. Connected controllers: ", Input.get_connected_joypads())
	quit()
