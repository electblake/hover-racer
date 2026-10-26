extends "res://tests/support/game_test.gd"

var scene: Node3D
var track
var panel
var original_events := {}

func before_each() -> void:
	super.before_each()
	for entry in preload("res://controller_setup.gd").ACTIONS:
		original_events[entry[0]] = InputMap.action_get_events(entry[0])
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	panel = track.controller_setup
	track.setup_button.pressed.emit()
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
	button(JOY_BUTTON_RIGHT_SHOULDER, true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(panel.is_visible_in_tree() and get_tree().paused)
	assert_eq(panel.meters["afterburner"].value, 1.0)
	assert_true(panel.raw_readout.text.contains("Button 10"))
	button(JOY_BUTTON_RIGHT_SHOULDER, false)
	assert_true(panel.is_visible_in_tree())
	assert_eq(track.ship.transform, start)
	panel.back_button.pressed.emit()
	assert_true(track.game_layout.visible and not panel.visible)

func test_button_remap_preserves_keyboard_and_persists() -> void:
	panel.begin_binding("throttle")
	button(JOY_BUTTON_X, true)
	button(JOY_BUTTON_X, false)
	button(JOY_BUTTON_X, true)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(panel.meters["throttle"].value, 1.0)
	assert_true(panel.pending_action.is_empty())
	var keys := 0
	for event in InputMap.action_get_events("throttle"):
		if event is InputEventKey: keys += 1
	assert_eq(keys, 1)
	button(JOY_BUTTON_X, false)
	var saved := ConfigFile.new()
	assert_eq(saved.load(panel.SETTINGS_PATH), OK)
	assert_eq(saved.get_value("bindings", "throttle"), {"button": JOY_BUTTON_X})
	var reopened := preload("res://controller_setup.gd").new()
	add_child_autofree(reopened)
	assert_eq(reopened.binding_text("throttle"), "W, X (west)")

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

func test_keyboard_remap_preserves_controller() -> void:
	panel.begin_binding("afterburner")
	var event := InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.keycode = KEY_Q
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	assert_true(panel.pending_action.is_empty())
	assert_true(panel.binding_text("afterburner").contains("Q"))
	assert_true(panel.binding_text("afterburner").contains("RB"))
	event = InputEventKey.new()
	event.physical_keycode = KEY_Q
	event.keycode = KEY_Q
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_presets_preserve_keyboard_and_name_controller_buttons() -> void:
	panel.apply_binding("maneuver", {"key": KEY_Q})
	for profile in panel.PRESETS:
		panel.load_profile(profile)
		assert_eq(panel.active_profile, profile)
		assert_true(panel.binding_text("maneuver").contains("Q"))
		assert_eq(InputMap.action_get_events("throttle")[1].axis, JOY_AXIS_TRIGGER_RIGHT)
		assert_eq(InputMap.action_get_events("reset_ship")[1].button_index, JOY_BUTTON_Y)
	assert_true(panel.binding_text("maneuver").contains("B (south)"))
	assert_true(panel.binding_text("ability_primary").contains("A (east)"))
	assert_true(panel.binding_text("throttle").contains("R2"))

func test_named_profiles_round_trip_and_remain_independent() -> void:
	panel.load_profile("SN30 Pro")
	panel.begin_binding("afterburner")
	button(JOY_BUTTON_X, true)
	button(JOY_BUTTON_X, false)
	assert_eq(panel.active_profile, "Custom")
	panel.save_profile("Evening racer")
	panel.load_profile("Xbox Wireless Controller")
	panel.save_profile("Default racing")
	panel.load_profile("Evening racer")
	assert_true(panel.binding_text("afterburner").contains("Y (west)"))
	assert_eq(panel.controller_layout, "SN30 Pro")
	var reopened := preload("res://controller_setup.gd").new()
	add_child_autofree(reopened)
	assert_eq(reopened.active_profile, "Evening racer")
	assert_eq(reopened.profiles.size(), 2)
	assert_true(reopened.binding_text("afterburner").contains("Y (west)"))
	reopened.load_profile("Default racing")
	assert_true(reopened.binding_text("afterburner").contains("RB"))
	reopened.load_profile("Custom")
	assert_true(reopened.binding_text("afterburner").contains("RB"), "Custom starts from current controls")
	reopened.apply_binding("afterburner", {"button": JOY_BUTTON_B})
	reopened.save_profile("Default racing")
	reopened.load_profile("Evening racer")
	assert_true(reopened.binding_text("afterburner").contains("Y (west)"), "Replacing another profile leaves this snapshot intact")
	reopened.load_profile("Default racing")
	assert_true(reopened.binding_text("afterburner").contains("B (east)"))

func test_save_name_prompt_and_cancel_do_not_remap() -> void:
	panel.begin_binding("throttle")
	panel.save_button.pressed.emit()
	assert_true(panel.save_dialog.visible)
	assert_true(panel.pending_action.is_empty())
	assert_true(panel.save_dialog.get_ok_button().disabled)
	panel.profile_name.text = "My controller"
	panel.profile_name.text_changed.emit(panel.profile_name.text)
	assert_false(panel.save_dialog.get_ok_button().disabled)
	panel.save_dialog.get_ok_button().pressed.emit()
	assert_eq(panel.active_profile, "My controller")
	assert_true(panel.profiles.has("My controller"))
	panel.prompt_save_profile()
	assert_eq(panel.save_dialog.get_ok_button().text, "Replace profile")
	panel.profile_name.text = "SN30 Pro"
	panel.profile_name.text_changed.emit(panel.profile_name.text)
	assert_true(panel.save_dialog.get_ok_button().disabled, "Built-in sets cannot be overwritten")
	panel.save_dialog.get_cancel_button().pressed.emit()
	assert_eq(panel.active_profile, "My controller")

func test_hud_and_controls_follow_loaded_profile_and_custom_bindings() -> void:
	panel.load_profile("SN30 Pro")
	track.start_new_race()
	track.update_vehicle_overlay()
	assert_true(track.ability_status.text.contains("A (east)"), "SN30 prompt uses physical face label")
	panel.apply_binding("reset_ship", {"key": KEY_T})
	panel.apply_binding("reset_ship", {"button": JOY_BUTTON_X})
	track.ship.crash("audit")
	track.update_vehicle_overlay()
	assert_true(track.warning_label.text.contains("T, Y (west)"), "Crash prompt follows current respawn controls")
	panel.apply_binding("toggle_menu", {"key": KEY_F1})
	await get_tree().process_frame
	assert_true(track.menu_hint.text.contains("F1"))
	track.set_menu_open(true)
	track.show_controls()
	await get_tree().process_frame
	assert_true(track.readout.text.contains("Respawn: T, Y (west)"))

func test_trigger_direction_labels_distinguish_custom_negative_axis() -> void:
	panel.apply_binding("brake", {"axis": JOY_AXIS_TRIGGER_RIGHT, "direction": -1.0})
	assert_ne(panel.binding_text("brake"), panel.binding_text("throttle"), "Opposite trigger directions must not look identical")
	assert_true(panel.binding_text("brake").contains("negative"))

func test_setup_capture_consumes_menu_button_then_can_exit_and_drive() -> void:
	panel.begin_binding("maneuver")
	button(JOY_BUTTON_START, true)
	button(JOY_BUTTON_START, false)
	assert_true(panel.visible, "Capturing Start must not exit the setup")
	panel.load_profile("Xbox Wireless Controller")
	button(JOY_BUTTON_B, true)
	button(JOY_BUTTON_B, false)
	assert_true(track.game_layout.visible)
	track.start_new_race()
	Input.action_press("throttle")
	for frame in range(20): await get_tree().physics_frame
	assert_gt(track.ship.actual_speed, 1.0)

func test_focus_loss_closes_profile_dialog_without_saving_or_blocking_menu() -> void:
	panel.prompt_save_profile()
	panel.profile_name.text = "Unfinished profile"
	track._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert_false(panel.save_dialog.visible, "A hidden setup must not leave a modal dialog over the game menu")
	assert_false(panel.profiles.has("Unfinished profile"))
	assert_true(track.game_layout.visible)
	track.start_new_race()
	Input.action_press("throttle")
	for frame in range(20): await get_tree().physics_frame
	assert_gt(track.ship.actual_speed, 1.0)
