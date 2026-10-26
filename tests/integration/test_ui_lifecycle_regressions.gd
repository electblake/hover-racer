extends "res://tests/support/game_test.gd"
var scene: Node3D
var track
var ship: VehicleController

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	ship = scene.get_node("SHIP")

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func frames(count: int) -> void:
	for frame in range(count): await get_tree().physics_frame

func button(index: JoyButton) -> void:
	for pressed in [true, false]:
		var event := InputEventJoypadButton.new()
		event.button_index = index
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func test_controller_can_leave_setup_without_mouse_or_keyboard() -> void:
	track.show_controller_setup()
	button(JOY_BUTTON_B)
	assert_true(track.game_layout.visible, "Controller B must leave setup")
	track.show_controller_setup()
	button(JOY_BUTTON_START)
	assert_true(track.game_layout.visible, "Controller Menu must leave setup")
	track.show_controller_setup()
	button(JOY_BUTTON_A)
	assert_true(track.game_layout.visible, "Focused Back must accept controller A")
	assert_true(get_tree().paused)

func test_sandbox_focus_does_not_lock_resumed_race() -> void:
	track.start_new_race()
	await frames(10)
	track.sandbox.spinboxes.speed.get_line_edit().grab_focus()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(ship.gameplay_enabled)
	track.set_menu_open(true)
	track.set_menu_open(false)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(ship.gameplay_enabled, "Resume must clear hidden sandbox edit focus")
	Input.action_press("throttle")
	await frames(20)
	assert_gt(ship.actual_speed, 1.0)

func test_pause_resume_retains_momentum_and_resource_timers() -> void:
	track.start_new_race()
	track.sandbox.set_enabled(false)
	Input.action_press("throttle")
	await frames(60)
	Input.action_release("throttle")
	var velocity := ship.linear_velocity
	var timer := ship.time_without_boost
	track.set_menu_open(true)
	await frames(30)
	assert_eq(ship.time_without_boost, timer)
	track.set_menu_open(false)
	await frames(3)
	assert_gt(ship.linear_velocity.length(), velocity.length() * 0.9)
	assert_false(ship.freeze)

func test_crash_respawn_and_drive_on_each_map_repeatedly() -> void:
	for index in range(track.MAPS.size()):
		track.set_menu_open(true)
		track.selected_map = index
		track.start_new_race()
		track.sandbox.set_enabled(false)
		for life in range(2):
			await frames(20)
			assert_true(ship.supported, "Spawn has support on map %d" % index)
			ship.crash("audit")
			button(JOY_BUTTON_Y)
			await frames(3)
			assert_false(ship.is_crashed or ship.freeze)
			Input.action_press("throttle")
			await frames(30)
			assert_gt(ship.actual_speed, 1.0)
			Input.action_release("throttle")
