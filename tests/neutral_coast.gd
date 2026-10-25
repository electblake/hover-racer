extends SceneTree
var failures := 0
func require(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func axis(index: int, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.device = 0
	event.axis = index
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
func _initialize() -> void:
	call_deferred("check")
func check() -> void:
	var scene = load("res://Main.tscn").instantiate()
	scene.get_node("TestTrack").free()
	scene.get_node("CanyonSlice").free()
	root.add_child(scene)
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2000,1,2000)
	shape.shape = box
	floor_body.add_child(shape)
	scene.add_child(floor_body)
	var ship = scene.get_node("SHIP")
	for i in range(3): await physics_frame
	var heading: float = ship.rotation.y
	# Small radial stick noise must never generate power from rest.
	axis(JOY_AXIS_LEFT_X,.12)
	axis(JOY_AXIS_LEFT_Y,-.12)
	axis(JOY_AXIS_RIGHT_X,-.16)
	axis(JOY_AXIS_RIGHT_Y,.04)
	for i in range(60):
		await physics_frame
		require(ship.throttle_input==0 and ship.left_steering==0 and ship.right_steering==0,"Drift noise escaped radial deadzone")
		require(Vector2(ship.velocity.x,ship.velocity.z).is_zero_approx(),"No-input acceleration")
	require(ship.left_thrust==0 and ship.right_thrust==0 and ship.power_blend<.001,"Neutral must cut power")
	require(not ship.engines[0].visible and not ship.engines[1].visible,"Neutral exhaust must be off")
	var direction := Vector3(.6,0,-.8)
	ship.velocity = direction*ship.max_speed
	var initial_speed: float = ship.max_speed
	var stop_frame := -1
	var last_speed := initial_speed
	for frame in range(300):
		await physics_frame
		var horizontal := Vector3(ship.velocity.x,0,ship.velocity.z)
		var speed := horizontal.length()
		require(speed<=last_speed+.001,"Coasting must never accelerate")
		if speed>.01: require(horizontal.normalized().dot(direction)>.999,"Drag changed glide direction")
		if frame==8: require(speed>initial_speed*.9,"Initial glide too abrupt")
		if frame==59: require(speed<initial_speed-23 and speed>initial_speed-29,"Noticeable predictable deceleration")
		if stop_frame<0 and speed<.001: stop_frame=frame
		last_speed=speed
	require(stop_frame>=235 and stop_frame<=245,"Stop must take roughly four seconds")
	require(last_speed<.001 and is_equal_approx(ship.rotation.y,heading),"Neutral should stop without rotating")
	require(not ship.wind_audio.playing,"Wind must stop at rest")
	axis(JOY_AXIS_LEFT_X,0)
	axis(JOY_AXIS_RIGHT_X,0)
	axis(JOY_AXIS_TRIGGER_RIGHT,1)
	for i in range(30): await physics_frame
	require(Vector2(ship.velocity.x,ship.velocity.z).length()>50,"Active thrust should still reach cap")
	require(not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Engine audio must stay disabled at full power")
	require(ship.wind_audio.playing,"Wind retained during movement")
	axis(JOY_AXIS_TRIGGER_RIGHT,0)
	for i in range(35): await physics_frame
	require(ship.left_thrust==0 and ship.right_thrust==0 and ship.power_blend<.001,"Released controls must not stick")
	require(not ship.engines[0].visible and not ship.engines[1].visible,"Powered exhaust should fade after release")
	ship.velocity = Vector3.ZERO
	ship.reset_visuals()
	require(not ship.wind_audio.playing and not ship.engine_audio[0].playing and not ship.engine_audio[1].playing,"Reset stops audio")
	print("Neutral coast: stop from %.0fm/s in %.2fs; zero-input/noise no thrust; glide direction, active launch, disabled engines, wind and reset; failures=%d" % [initial_speed,float(stop_frame+1)/60,failures])
	scene.queue_free()
	await process_frame
	OS.delay_msec(120)
	await process_frame
	quit(0 if failures==0 else 1)
