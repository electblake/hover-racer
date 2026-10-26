extends "res://tests/support/vehicle_test.gd"

func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_keyboard_bindings_and_opposed_steering() -> void:
	vehicle.player_controlled = true
	key(KEY_W, true)
	key(KEY_D, true)
	key(KEY_A, true)
	await frames(20)
	assert_eq(vehicle.throttle_input, 1.0)
	assert_eq(vehicle.steering, 0.0)
	key(KEY_A, false)
	await frames(20)
	assert_eq(vehicle.steering, 1.0)
	key(KEY_SHIFT, true)
	await frames(2)
	assert_eq(vehicle.boost_mode, "afterburner")
	key(KEY_CTRL, true)
	await frames(2)
	assert_eq(vehicle.boost_mode, "ramjet")
	key(KEY_S, true)
	await frames(2)
	assert_eq(vehicle.boost_mode, "none")
	for code in [KEY_W, KEY_D, KEY_SHIFT, KEY_CTRL, KEY_S]: key(code, false)

func test_trigger_deadzone_and_analog_input() -> void:
	vehicle.player_controlled = true
	for value in [0.04, 0.525, 1.0]:
		var event := InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_RIGHT
		event.axis_value = value
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await frames(2)
		assert_almost_eq(vehicle.throttle_input, 0.0 if value == 0.04 else (0.5 if value == 0.525 else 1.0), 0.001)
	assert_almost_eq(InputMap.action_get_deadzone("steer_left"), 0.15, 0.000001)
	assert_almost_eq(InputMap.action_get_deadzone("steer_right"), 0.15, 0.000001)

func test_gate_requires_special_release_and_discards_ability() -> void:
	vehicle.player_controlled = true
	await frames(2)
	Input.action_press("throttle")
	Input.action_press("ramjet")
	Input.action_press("ability_primary")
	vehicle.gate_input(false)
	await frames(2)
	vehicle.gate_input(true)
	await frames(10)
	assert_eq(vehicle.boost_mode, "none")
	assert_eq(vehicle.energy, 200.0)
	Input.action_release("ramjet")
	Input.action_release("ability_primary")
	await frames(2)
	Input.action_press("ramjet")
	Input.action_press("ability_primary")
	await frames(2)
	assert_eq(vehicle.boost_mode, "ramjet")
	assert_almost_eq(vehicle.energy, 160.0, 0.01)
	await frames(180)
	assert_gt(vehicle.energy, 160.0)

func test_menu_discarded_press_release_cannot_activate_on_rearm_tick() -> void:
	vehicle.player_controlled = true
	Input.action_press("ability_primary")
	Input.action_release("ability_primary")
	vehicle.gate_input(true)
	await frames(2)
	assert_eq(vehicle.energy, 200.0)
