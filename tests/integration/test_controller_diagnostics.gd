extends "res://tests/support/game_test.gd"

var scene: Node3D
var track
var panel
var original_events := {}

func before_each() -> void:
	super.before_each()
	for entry in preload("res://controller_diagnostics.gd").ACTIONS:
		original_events[entry[0]] = InputMap.action_get_events(entry[0])
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	panel = track.diagnostics
	track.diagnostics_button.pressed.emit()
	await get_tree().process_frame

func after_each() -> void:
	for action in original_events:
		InputMap.action_erase_events(action)
		for event in original_events[action]: InputMap.action_add_event(action, event)
	scene.queue_free()
	await get_tree().process_frame
	super.after_each()

func button(index: JoyButton, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func axis(value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_LEFT_X
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_live_input_and_menu_isolation() -> void:
	var start: Transform3D = track.ship.transform
	button(JOY_BUTTON_START, true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(panel.is_visible_in_tree() and get_tree().paused)
	assert_eq(panel.meters["toggle_menu"].value, 1.0)
	assert_true(panel.raw_readout.text.contains("Button 6"))
	button(JOY_BUTTON_START, false)
	button(JOY_BUTTON_B, true)
	button(JOY_BUTTON_B, false)
	assert_true(panel.is_visible_in_tree())
	assert_eq(track.ship.transform, start)
	panel.back_button.pressed.emit()
	assert_true(track.game_layout.visible and not panel.visible)

func test_button_remap_preserves_keyboard_and_persists() -> void:
	panel.begin_binding("thrust")
	button(JOY_BUTTON_B, true)
	button(JOY_BUTTON_B, false)
	button(JOY_BUTTON_B, true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(panel.meters["thrust"].value, 1.0)
	assert_true(panel.pending_action.is_empty())
	var keys := 0
	for event in InputMap.action_get_events("thrust"):
		if event is InputEventKey: keys += 1
	assert_eq(keys, 1)
	button(JOY_BUTTON_B, false)
	var saved := ConfigFile.new()
	assert_eq(saved.load(panel.SETTINGS_PATH), OK)
	assert_eq(saved.get_value("bindings", "thrust"), {"button": JOY_BUTTON_B})
	var reopened := preload("res://controller_diagnostics.gd").new()
	add_child_autofree(reopened)
	assert_eq(reopened.binding_text("thrust"), "Button 1")

func test_axis_direction_capture_and_cancel() -> void:
	panel.begin_binding("brake")
	axis(0.0)
	axis(-0.2)
	assert_eq(panel.pending_action, "brake")
	axis(-0.9)
	assert_true(panel.pending_action.is_empty())
	axis(0.0)
	axis(-1.0)
	assert_eq(Input.get_action_strength("brake"), 1.0)
	axis(1.0)
	assert_eq(Input.get_action_strength("brake"), 0.0)
	axis(0.0)
	panel.begin_binding("reset_ship")
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	assert_true(panel.pending_action.is_empty() and panel.visible)
	event = InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = false
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_overlay_fits_small_viewport() -> void:
	get_tree().root.size = Vector2i(640, 480)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(track.menu.get_global_rect().encloses(panel.back_button.get_global_rect()))
	assert_true(panel.raw_readout.size.x <= panel.size.x)
