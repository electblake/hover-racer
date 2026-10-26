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
	await get_tree().process_frame
	super.after_each()

func test_authored_defaults() -> void:
	assert_true(ship.thrust_attack == 0.12 and ship.thrust_decay == 0.18 and ship.thrust_sustain == 0.92 and ship.thrust_release == 0.28, "Fresh settings use authored vehicle defaults")

func test_sandbox_controls_and_persistence() -> void:
	track.sandbox.sliders.acceleration.value = 450
	track.sandbox.spinboxes.max_speed.value = 80
	track.sandbox.spinboxes.thrust_attack.value = 0.23
	track.sandbox.sliders.turn_speed.value = 2.4
	assert_eq(ship.acceleration, 450.0)
	assert_eq(track.sandbox.spinboxes.acceleration.value, 450.0)
	assert_eq(track.sandbox.sliders.max_speed.value, 80.0)
	assert_eq(ship.thrust_attack, 0.23)
	assert_eq(ship.turn_speed, 2.4)
	track.sandbox.position = Vector2i(40,60)
	track.sandbox.size = Vector2i(420,280)
	await get_tree().process_frame
	await get_tree().process_frame
	scene.queue_free()
	await get_tree().process_frame
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	ship = scene.get_node("SHIP")
	assert_eq(ship.acceleration, 450.0, "Saved acceleration restored")
	assert_eq(ship.max_speed, 80.0, "Saved speed restored")
	assert_eq(ship.thrust_attack, 0.23, "Saved thrust restored")
	assert_eq(ship.turn_speed, 2.4, "Saved steering restored")
	assert_eq(track.sandbox.position, Vector2i(40,60), "Position restored")
	assert_eq(track.sandbox.size, Vector2i(420,280), "Size restored")
	track.set_menu_open(false)
	track.sandbox.close_requested.emit()
	assert_false(track.sandbox.visible or track.sandbox_toggle.button_pressed)
	track.set_menu_open(true)
	track.sandbox_toggle.button_pressed = true
	track.set_menu_open(false)
	assert_true(track.sandbox.visible, "Settings reopens closed debug window")

func test_sandbox_mouse_drag_resize() -> void:
	track.set_menu_open(false)
	track.sandbox.position = Vector2i(40,60)
	track.sandbox.size = Vector2i(384,260)
	await get_tree().process_frame
	await get_tree().process_frame
	drag_mouse(Vector2(100,48), Vector2(180,88))
	assert_eq(track.sandbox.position, Vector2i(120,100), "Native title drag")
	var corner := Vector2(track.sandbox.position + track.sandbox.size) + Vector2(1,1)
	drag_mouse(corner, corner + Vector2(60,40))
	assert_eq(track.sandbox.size, Vector2i(444,300), "Native border resize")

func drag_mouse(from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	press.global_position = from
	get_tree().root.push_input(press, true)
	Input.flush_buffered_events()
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_tree().root.push_input(motion, true)
	Input.flush_buffered_events()
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = to
	release.global_position = to
	get_tree().root.push_input(release, true)
	Input.flush_buffered_events()

func test_physics_meter_and_brake() -> void:
	ship.acceleration = 300
	ship.max_speed = 104
	track.set_menu_open(false)
	ship.thrust_attack = 0.12
	ship.thrust_decay = 0.18
	ship.thrust_sustain = 0.92
	ship.thrust_release = 0.28
	Input.action_press("thrust")
	for frame in range(6):
		await get_tree().physics_frame
	assert_true(ship.applied_thrust > 0 and ship.applied_thrust < 1, "Physics ramps attack instead of applying full gas immediately")
	assert_true(Vector2(ship.velocity.x, ship.velocity.z).length() > 10, "Envelope drives actual vehicle acceleration")
	# Observe after the UI process callback and before the next physics update.
	await get_tree().process_frame
	await get_tree().physics_frame
	assert_true(track.thrust_meter.level == ship.applied_thrust, "Meter reads applied thrust directly")
	Input.action_press("brake")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_true(ship.applied_thrust == 0, "Full brake overrides envelope")
	Input.action_release("thrust")
	Input.action_release("brake")
	ship.reset_visuals()
	assert_true(ship.applied_thrust == 0 and ship.thrust_envelope.level == 0, "Reset clears envelope")

func test_live_drive_limits() -> void:
	track.start_new_race()
	ship.acceleration = 0
	Input.action_press("thrust")
	for frame in range(25): await get_tree().physics_frame
	assert_true(Vector2(ship.velocity.x, ship.velocity.z).length() < 0.01, "Zero acceleration produces no horizontal propulsion")
	ship.acceleration = 450
	ship.max_speed = 20
	for frame in range(12): await get_tree().physics_frame
	assert_true(absf(Vector2(ship.velocity.x, ship.velocity.z).length() - 20) < 0.1, "Live drive settings accelerate to the selected speed cap")
	Input.action_release("thrust")

func test_overlay_layout() -> void:
	track.set_menu_open(false)
	for viewport_size in [Vector2i(640,480), Vector2i(1280,720), Vector2i(1920,1080)]:
		get_tree().root.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		assert_true(get_tree().root.get_visible_rect().encloses(track.thrust_hud.get_global_rect()), "Meter fits viewport")

