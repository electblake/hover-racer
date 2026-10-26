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
	await get_tree().process_frame

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_all_27_builds_are_cosmetic_and_keep_live_exhausts() -> void:
	track.garage_button.pressed.emit()
	var original_stats = ship.stats
	var original_tuning = ship.tuning
	var collider = ship.get_node("CollisionShape3D")
	var original_shape = collider.shape
	var original_size: Vector3 = collider.shape.size
	var original_mass: float = ship.mass
	var builds := {}
	for nose in range(3):
		for core in range(3):
			for engines in range(3):
				track.garage.select_part(nose, 0)
				track.garage.select_part(core, 1)
				track.garage.select_part(engines, 2)
				var expected := [nose, core, engines]
				assert_eq(ship.pod_visual.selections, expected)
				assert_eq(track.garage.preview.selections, expected)
				var visible_names := PackedStringArray()
				for slot in range(3):
					var count := 0
					for module in ship.pod_visual.modules[slot].get_children():
						if module.visible:
							count += 1
							visible_names.append(str(module.get_path()))
					assert_eq(count, 1, "Exactly one module per slot")
				builds["/".join(visible_names)] = true
				assert_same(ship.stats, original_stats)
				assert_same(ship.tuning, original_tuning)
				assert_same(collider.shape, original_shape)
				assert_eq(collider.shape.size, original_size)
				assert_eq(ship.mass, original_mass)
				ship.pod_visual.animate(1.0, 1.0, 0.016)
				for flame in ship.engines:
					assert_true(flame.is_visible_in_tree(), "Ship exhaust references follow the selected engine assembly")
	assert_eq(builds.size(), 27)
	assert_true(get_tree().paused)
	assert_false(ship.gameplay_enabled)

func test_presets_mixing_and_race_reset_retain_selection() -> void:
	track.show_garage()
	track.garage.kit_buttons[1].pressed.emit()
	assert_eq(ship.pod_visual.selections, [1, 1, 1])
	track.garage.selectors[0].item_selected.emit(2)
	assert_eq(ship.pod_visual.selections, [2, 1, 1])
	track.garage.back_button.pressed.emit()
	assert_true(track.game_layout.visible)
	track.select_map(1)
	track.start_new_race()
	await get_tree().physics_frame
	ship.reset_visuals()
	assert_eq(ship.pod_visual.selections, [2, 1, 1])
	for flame in ship.engines: assert_false(flame.visible)
	track.set_menu_open(true)
	track.show_garage()
	assert_eq(track.garage.preview.selections, [2, 1, 1])
	assert_eq(track.garage.selectors[0].selected, 2)

func test_garage_back_input_and_small_layout() -> void:
	get_tree().root.size = Vector2i(640, 480)
	track.show_garage()
	for i in range(4): await get_tree().process_frame
	var viewport := get_tree().root.get_visible_rect()
	assert_true(viewport.encloses(track.garage.back_button.get_global_rect()))
	assert_true(viewport.encloses(track.garage.preview_container.get_global_rect()))
	assert_true(track.garage.selectors[0].has_focus())
	var event := InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	assert_true(track.game_layout.visible)
	assert_false(track.garage.visible)
	assert_true(get_tree().paused)

func test_controller_reaches_garage_and_returns_without_driving() -> void:
	track.setup_button.grab_focus()
	var original_map: int = track.selected_map
	for button in [JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_A]:
		var press := InputEventJoypadButton.new()
		press.device = 0
		press.button_index = button
		press.pressed = true
		Input.parse_input_event(press)
		Input.flush_buffered_events()
		var release := InputEventJoypadButton.new()
		release.device = 0
		release.button_index = button
		release.pressed = false
		Input.parse_input_event(release)
		Input.flush_buffered_events()
	assert_eq(track.selected_map, original_map, "Horizontal navigation between customization buttons must not change maps")
	assert_true(track.garage.visible)
	assert_true(track.garage.selectors[0].has_focus())
	var back := InputEventJoypadButton.new()
	back.device = 0
	back.button_index = JOY_BUTTON_B
	back.pressed = true
	Input.parse_input_event(back)
	Input.flush_buffered_events()
	assert_true(track.game_layout.visible)
	assert_false(track.garage.visible)
	assert_false(ship.gameplay_enabled)
