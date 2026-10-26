extends "res://tests/support/game_test.gd"
var ship: CharacterBody3D
var scene: Node3D
var camera_rotation: Vector3
var collision_rest: Transform3D
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
	for i in range(count): await get_tree().physics_frame
func horizontal() -> Vector3:
	return Vector3(ship.velocity.x,0,ship.velocity.z)
func reset() -> void:
	for index in [JOY_AXIS_LEFT_X,JOY_AXIS_RIGHT_X,JOY_AXIS_LEFT_Y,JOY_AXIS_RIGHT_Y,JOY_AXIS_TRIGGER_LEFT,JOY_AXIS_TRIGGER_RIGHT]: axis(index,0)
	ship.position = Vector3(55,2,30)
	ship.rotation = Vector3.ZERO
	ship.velocity = Vector3.ZERO
	ship.reset_visuals()

func before_each() -> void:
	super.before_each()
	scene = load("res://Main.tscn").instantiate()
	scene.get_node("TestTrack").free()
	scene.get_node("CanyonSlice").free()
	add_child_autofree(scene)
	ship = scene.get_node("SHIP")
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000,1,2000)
	shape.shape = box
	body.add_child(shape)
	scene.add_child(body)
	await frames(3)
	camera_rotation = ship.camera.rotation
	collision_rest = ship.get_node("CollisionShape3D").transform

func after_each() -> void:
	scene.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	super.after_each()

func test_defaults_and_deadzone() -> void:
	assert_true(ship.max_speed==104 and ship.acceleration==300,"Preserve speed/launch tuning")
	for old in ["left_forward","right_forward","left_reverse","right_reverse","left_left","right_left"]:
		assert_true(not InputMap.has_action(old),"Remove obsolete directional controls")
	reset()
	axis(JOY_AXIS_LEFT_Y,-1)
	axis(JOY_AXIS_RIGHT_Y,1)
	await frames(12)
	assert_true(horizontal().is_zero_approx() and ship.rotation.is_zero_approx(),"Vertical sticks must not control heading/propulsion")
	reset()
	axis(JOY_AXIS_TRIGGER_RIGHT,.04)
	axis(JOY_AXIS_TRIGGER_LEFT,.04)
	axis(JOY_AXIS_LEFT_X,.1)
	axis(JOY_AXIS_RIGHT_X,-.1)
	await frames(5)
	assert_true(ship.throttle_input==0 and ship.brake_input==0 and horizontal().is_zero_approx() and ship.rotation.is_zero_approx(),"Trigger/stick deadzones")

func test_analog_throttle_and_speed_cap() -> void:
	reset()
	axis(JOY_AXIS_TRIGGER_RIGHT,.5)
	await frames(10)
	var partial: float = horizontal().length()
	assert_true(partial>15 and partial<30,"Analog RT magnitude")
	reset()
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	await frames(10)
	assert_true(horizontal().length()>partial*1.8,"Full RT stronger than partial")
	await frames(25)
	assert_true(absf(horizontal().length()-104)<.01,"Active speed cap")
	assert_true(ship.engines[0].visible and ship.engines[1].visible and is_equal_approx(ship.engine_levels.x,ship.engine_levels.y),"Both engines share RT")

func test_additive_and_opposed_steering() -> void:
	reset()
	axis(JOY_AXIS_LEFT_X,1)
	await frames(15)
	var single_yaw: float = absf(ship.rotation.y)
	assert_true(ship.rotation.y<-.15 and horizontal().is_zero_approx(),"One right stick input rotates right without propulsion")
	reset()
	axis(JOY_AXIS_LEFT_X,1)
	axis(JOY_AXIS_RIGHT_X,1)
	await frames(15)
	assert_true(absf(absf(ship.rotation.y)-single_yaw*2)<.02,"Both sticks add to twice one-stick yaw")
	assert_true(ship.visual.rotation.z<-.2 and ship.visual.rotation.y<-.1,"Visible bank and stronger tail swing")
	reset()
	axis(JOY_AXIS_RIGHT_X,-1)
	await frames(15)
	assert_true(ship.rotation.y>.15 and ship.visual.rotation.z>.1,"Either stick left turns and banks left")
	reset()
	axis(JOY_AXIS_LEFT_X,-1)
	axis(JOY_AXIS_RIGHT_X,-1)
	await frames(15)
	assert_true(ship.rotation.y>.4,"Both left turns stronger left")
	reset()
	axis(JOY_AXIS_LEFT_X,-1)
	axis(JOY_AXIS_RIGHT_X,1)
	await frames(15)
	assert_true(ship.rotation.is_zero_approx() and absf(ship.visual.rotation.z)<.001,"Opposite horizontal inputs cancel")
	reset()
	axis(JOY_AXIS_LEFT_X,.5)
	await frames(15)
	assert_true(absf(ship.rotation.y)>0 and absf(ship.rotation.y)<single_yaw*.6,"Analog steering magnitude")

func test_coasting_heading_and_rethrust() -> void:
	# Coast while lining up: heading turns, velocity direction does not.
	reset()
	ship.velocity = Vector3(0,0,-104)
	axis(JOY_AXIS_LEFT_X,1)
	axis(JOY_AXIS_RIGHT_X,1)
	await frames(30)
	var coast := horizontal()
	assert_true(ship.rotation.y<-.8 and coast.normalized().dot(Vector3.FORWARD)>.999,"Off-gas facing independent of travel")
	assert_true(coast.length()>89 and coast.length()<93,"Passive slowing remains useful while steering")
	axis(JOY_AXIS_LEFT_X,0)
	axis(JOY_AXIS_RIGHT_X,0)
	var heading: Vector3 = -ship.global_transform.basis.z
	var before: float = absf(coast.normalized().signed_angle_to(heading,Vector3.UP))
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	await frames(12)
	assert_true(absf(horizontal().normalized().signed_angle_to(heading,Vector3.UP))<before*.5,"RT lurch/assist pulls into new heading")
	assert_true(horizontal().length()>40 and horizontal().length()<=104.01,"Strong capped rethrust")

func test_analog_and_full_braking() -> void:
	reset()
	ship.velocity = Vector3(0,0,-104)
	axis(JOY_AXIS_TRIGGER_LEFT,.5)
	await frames(15)
	var partial_brake: float = horizontal().length()
	assert_true(partial_brake<90 and partial_brake>80,"Analog air brake")
	reset()
	ship.velocity = Vector3(0,0,-104)
	axis(JOY_AXIS_TRIGGER_LEFT,1)
	await frames(60)
	assert_true(horizontal().is_zero_approx(),"Full air brake should stop in under a second")
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	await frames(10)
	assert_true(horizontal().is_zero_approx(),"Full brake overrides simultaneous gas")

func test_keyboard_throttle_steering_and_brake() -> void:
	reset()
	key(KEY_SPACE,true)
	key(KEY_RIGHT,true)
	await frames(10)
	assert_true(ship.velocity.length()>15 and ship.rotation.y<0,"Keyboard Space + Right thrust and steer")
	assert_true(ship.left_steering==1 and ship.right_steering==1,"Right arrow drives both sticks at full strength")
	var one: float = absf(ship.rotation.y)
	key(KEY_H,true)
	await frames(10)
	assert_true(is_equal_approx(absf(ship.rotation.y)-one,ship.turn_speed*10.0/60.0),"Right arrow plus H retains the same settled full turn rate")
	key(KEY_SPACE,false)
	key(KEY_RIGHT,false)
	key(KEY_H,false)
	key(KEY_SHIFT,true)
	await frames(60)
	assert_true(horizontal().is_zero_approx(),"Keyboard Shift air brake")
	key(KEY_SHIFT,false)

func test_keyboard_controller_steering_parity() -> void:
	# Compare digital keyboard inputs against the actual controller motion path.
	for direction in [-1,1]:
		reset()
		axis(JOY_AXIS_LEFT_X,direction)
		axis(JOY_AXIS_RIGHT_X,direction)
		await frames(10)
		var controller_yaw: float = ship.rotation.y
		reset()
		var steer_key: Key = KEY_LEFT if direction<0 else KEY_RIGHT
		key(steer_key,true)
		await frames(10)
		assert_true(is_equal_approx(ship.rotation.y,controller_yaw),"Left/Right matches both horizontal controller sticks")
		key(steer_key,false)
		for single_key in ([KEY_J,KEY_F] if direction<0 else [KEY_L,KEY_H]):
			reset()
			key(single_key,true)
			await frames(10)
			assert_true(is_equal_approx(ship.yaw_velocity,-direction*ship.turn_speed*.5),"Independent keyboard stick settles at half-strength turn rate")
			key(single_key,false)
		reset()
		axis(JOY_AXIS_LEFT_X,direction)
		axis(JOY_AXIS_RIGHT_X,direction)
		axis(JOY_AXIS_LEFT_Y,1)
		axis(JOY_AXIS_RIGHT_Y,1)
		await frames(10)
		var sharp_yaw: float = ship.rotation.y
		assert_true(absf(sharp_yaw)>absf(controller_yaw),"Controller pull-down strengthens inside turn")
		reset()
		key(steer_key,true)
		key(KEY_DOWN,true)
		await frames(10)
		assert_true(is_equal_approx(ship.rotation.y,sharp_yaw),"Down arrow sharp turn matches controller diagonals")
		key(steer_key,false)
		key(KEY_DOWN,false)

func test_keyboard_modifiers_and_cancellation() -> void:
	reset()
	for pair in [[KEY_LEFT,KEY_RIGHT],[KEY_J,KEY_H],[KEY_L,KEY_F]]:
		key(pair[0],true)
		key(pair[1],true)
		await frames(5)
		assert_true(ship.rotation.is_zero_approx(),"Opposed keyboard steering cancels")
		key(pair[0],false)
		key(pair[1],false)
	for binding in [[KEY_A,"left",1.0],[KEY_D,"right",1.0],[KEY_Q,"left",1.0],[KEY_K,"left",1.0],[KEY_I,"left",-1.0],[KEY_E,"right",1.0],[KEY_G,"right",1.0],[KEY_T,"right",-1.0]]:
		key(binding[0],true)
		await frames(2)
		assert_true(ship.stick_vector(binding[1]).is_equal_approx(Vector2(0,binding[2])),"Keyboard vertical binding: %s" % [binding])
		assert_true(ship.rotation.is_zero_approx() and horizontal().is_zero_approx(),"Vertical keys alone cannot turn or propel")
		key(binding[0],false)
	key(KEY_DOWN,true)
	await frames(5)
	assert_true(ship.stick_vector("left")==Vector2.DOWN and ship.stick_vector("right")==Vector2.DOWN,"Down arrow pulls both sticks")
	assert_true(ship.rotation.is_zero_approx() and horizontal().is_zero_approx(),"Down arrow alone cannot turn or propel")
	key(KEY_DOWN,false)
	for modifier in [KEY_W,KEY_UP,KEY_S]:
		key(modifier,true)
		await frames(2)
		var expected := Vector2.DOWN if modifier==KEY_S else Vector2.UP
		assert_true(ship.stick_vector("left")==expected and ship.stick_vector("right")==expected,"W/Up push both sticks; S pulls both")
		assert_true(ship.throttle_input==0 and ship.brake_input==0 and horizontal().is_zero_approx() and ship.rotation.is_zero_approx(),"Modifiers alone do not power, brake or steer")
		key(modifier,false)

func test_cross_device_release_and_brake_precedence() -> void:
	key(KEY_SPACE,true)
	key(KEY_SHIFT,true)
	await frames(10)
	assert_true(ship.throttle_input==1 and ship.brake_input==1 and horizontal().is_zero_approx(),"Space+Shift: full keyboard brake overrides gas")
	key(KEY_SPACE,false)
	key(KEY_SHIFT,false)
	await frames(2)
	assert_true(ship.throttle_input==0 and ship.brake_input==0 and ship.stick_vector("left")==Vector2.ZERO and ship.stick_vector("right")==Vector2.ZERO,"Released keyboard inputs do not stick")
	axis(JOY_AXIS_TRIGGER_RIGHT,.5)
	await frames(10)
	assert_true(horizontal().length()>15 and ship.throttle_input<1,"Controller analog gas works immediately after keyboard release")

func test_reset_bindings_and_visual_invariants() -> void:
	reset()
	var course = load("res://TestTrack.tscn").instantiate()
	scene.add_child(course)
	course.set_menu_open(false)
	var button := InputEventJoypadButton.new()
	button.device = 0
	button.button_index = JOY_BUTTON_Y
	button.pressed = true
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	assert_true(ship.position.is_equal_approx(Vector3(55,2,30)) and ship.velocity.is_zero_approx(),"Y reset")
	button = button.duplicate()
	button.pressed = false
	Input.parse_input_event(button)
	Input.flush_buffered_events()
	ship.position.z = 10
	key(KEY_R,true)
	assert_eq(ship.position, Vector3(55,2,30), "R resets synchronously before suspension advances")
	key(KEY_R,false)
	assert_true(ship.camera.rotation.is_equal_approx(camera_rotation) and ship.get_node("CollisionShape3D").transform.is_equal_approx(collision_rest),"Stable camera rotation/collider")
	assert_true(not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Engine sound remains disabled")
