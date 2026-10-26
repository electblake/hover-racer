extends "res://tests/support/game_test.gd"

var scene: Node3D
var track
var ship

func key(code: Key, pressed: bool, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	event.echo = echo
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func menu_button(pressed: bool, button: JoyButton = JOY_BUTTON_START) -> void:
	var event := InputEventJoypadButton.new()
	event.device = 0
	event.button_index = button
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	add_child_autofree(scene)
	track = scene.get_node("TestTrack")
	ship = scene.get_node("SHIP")
	await frames(3)

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_startup_blocks_driving_and_reset() -> void:
	assert_true(get_tree().paused and track.menu.visible and track.game_layout.visible and not track.readout.is_visible_in_tree(),"Game menu opens paused with controls hidden")
	assert_true(track.new_race_button.has_focus() and not track.resume_button.visible,"New Race is the startup default")
	var start: Transform3D = ship.transform
	Input.action_press("thrust")
	key(KEY_RIGHT,true)
	await frames(10)
	assert_true(ship.transform==start and ship.velocity==Vector3.ZERO,"Menu blocks throttle and steering")
	Input.action_release("thrust")
	key(KEY_RIGHT,false)
	ship.position.z = 20
	key(KEY_R,true)
	key(KEY_R,false)
	assert_true(ship.position.z==20,"Reset does not leak through menu")
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	assert_true(get_tree().paused and track.menu.visible,"Startup menu stays paused until New Race")

func test_keyboard_and_controller_navigation() -> void:
	key(KEY_DOWN,true)
	key(KEY_DOWN,false)
	assert_true(track.controls_button.has_focus(),"Keyboard navigation reaches Controls")
	key(KEY_ENTER,true)
	key(KEY_ENTER,false)
	assert_true(get_tree().paused and track.controls_layout.visible and track.readout.is_visible_in_tree(),"Controls opens current guide while paused")
	menu_button(true)
	menu_button(false)
	assert_true(get_tree().paused and track.game_layout.visible and track.new_race_button.has_focus(),"Menu backs out of Controls without starting race")
	menu_button(true, JOY_BUTTON_DPAD_DOWN)
	menu_button(false, JOY_BUTTON_DPAD_DOWN)
	assert_true(track.controls_button.has_focus(),"Controller D-pad selects Controls")
	menu_button(true, JOY_BUTTON_A)
	menu_button(false, JOY_BUTTON_A)
	assert_true(track.controls_layout.visible and get_tree().paused,"Controller A opens Controls")
	menu_button(true, JOY_BUTTON_B)
	menu_button(false, JOY_BUTTON_B)
	assert_true(track.game_layout.visible and get_tree().paused,"Controller B returns to game menu")
	key(KEY_ENTER,true)
	key(KEY_ENTER,false)
	assert_true(not get_tree().paused and ship.position==Vector3(55,2,30) and ship.velocity==Vector3.ZERO,"New Race resets vehicle and starts race")

func test_pause_resume_and_input_release() -> void:
	track.start_new_race()
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	assert_true(get_tree().paused and track.resume_button.has_focus(),"Pause menu defaults to Resume Race during a race")
	key(KEY_ESCAPE,true)
	assert_true(not get_tree().paused and not track.menu.visible and not track.readout.is_visible_in_tree(),"Escape hides all UI and resumes")
	key(KEY_ESCAPE,true,true)
	assert_true(not get_tree().paused,"Escape key repeat must not toggle")
	key(KEY_ESCAPE,false)
	key(KEY_SPACE,true)
	await frames(10)
	assert_true(ship.throttle_input==1 and ship.velocity.length()>15,"Keyboard driving resumes after menu")
	menu_button(true)
	menu_button(false)
	assert_true(get_tree().paused and track.menu.visible,"Controller Menu opens while driving")
	var frozen: Transform3D = ship.transform
	var velocity: Vector3 = ship.velocity
	await frames(10)
	assert_true(ship.transform==frozen and ship.velocity==velocity,"Pause preserves moving ship state")
	key(KEY_SPACE,false)
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)
	await frames(2)
	assert_true(not get_tree().paused and ship.throttle_input==0,"Releasing gas while paused does not stick after cross-device close")
	menu_button(true)
	menu_button(false)
	menu_button(true)
	menu_button(false)
	assert_true(not get_tree().paused and not track.menu.visible,"Controller Menu opens and closes")
	key(KEY_ESCAPE,true)
	key(KEY_ESCAPE,false)

func test_responsive_menu_and_controls() -> void:
	for viewport_size in [Vector2i(640,480),Vector2i(1280,720),Vector2i(1920,1080)]:
		get_tree().root.size = viewport_size
		await get_tree().process_frame
		await get_tree().process_frame
		assert_true(track.menu.size.x<=get_tree().root.get_visible_rect().size.x and track.menu.size.y<=get_tree().root.get_visible_rect().size.y,"Menu fits logical viewport %s: panel %s, viewport %s" % [viewport_size,track.menu.size,get_tree().root.get_visible_rect().size])
		assert_true(track.menu.get_global_rect().encloses(track.new_race_button.get_global_rect()),"Game menu actions fit viewport")
		track.show_controls()
		await get_tree().process_frame
		await get_tree().process_frame
		assert_true(track.readout.size.x<=track.menu.size.x,"Control text wraps within menu")
		track.back_button.pressed.emit()
		assert_true(get_tree().paused and track.game_layout.visible,"Back button returns to game menu")

func test_new_race_clears_existing_run() -> void:
	ship.position = Vector3(10,5,10)
	ship.velocity = Vector3(5,0,5)
	ship.yaw_velocity = 1.0
	track.new_race_button.pressed.emit()
	assert_true(ship.position==Vector3(55,2,30) and ship.velocity==Vector3.ZERO and ship.yaw_velocity==0,"New Race clears an existing run")
	track.set_menu_open(false)
