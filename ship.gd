extends CharacterBody3D

@export_group("Drive")
## Powered horizontal speed limit, in metres per second.
@export_range(0.0, 500.0, 1.0, "or_greater") var max_speed: float = 104.0
## Forward acceleration at full applied thrust, in metres per second squared.
@export_range(0.0, 1000.0, 1.0, "or_greater") var acceleration: float = 300.0
@export var coast_deceleration: float = 26.0 # Four seconds from 104 m/s.
@export var braking: float = 100.0
@export var thrust_grip: float = 6.5

@export_group("Thrust Envelope")
## Time to reach requested gas, in seconds.
@export_range(0.01, 2.0, 0.01, "or_greater") var thrust_attack: float = 0.12
## Time to settle from peak to sustain, in seconds.
@export_range(0.01, 2.0, 0.01, "or_greater") var thrust_decay: float = 0.18
## Held thrust as a fraction of gas input (0 to 1).
@export_range(0.0, 1.0, 0.01) var thrust_sustain: float = 0.92
## Time to ease down to zero after releasing gas, in seconds.
@export_range(0.01, 2.0, 0.01, "or_greater") var thrust_release: float = 0.28

@export_group("Steering")
## Held turn rate with both sticks fully deflected, in radians per second.
@export_range(0.0, 6.0, 0.1, "or_greater") var turn_speed: float = 1.8
## Turn onset and reversal acceleration, in radians per second squared.
@export_range(0.1, 120.0, 0.1, "or_greater") var turn_acceleration: float = 36.0
## Turn release deceleration, in radians per second squared.
@export_range(0.1, 120.0, 0.1, "or_greater") var turn_deceleration: float = 48.0
## Additional turn rate from pulling the inside stick down, in radians per second.
@export_range(0.0, 8.0, 0.1, "or_greater") var down_turn_boost: float = 3.0

@export_group("Visual Banking and Pitch")
@export var bank_degrees: float = 36.0
@export var down_bank_degrees: float = 18.0
@export var max_bank_degrees: float = 50.0
@export var down_pitch_degrees: float = 3.0
@export var power_pitch_degrees: float = 6.0
@export_group("Input")
@export_range(0.0, 0.25) var trigger_deadzone: float = 0.06
@export_range(0.0, 0.5) var stick_deadzone: float = 0.18
@export_group("Camera")
@export var camera_pullback: float = 1.1
@export var camera_kick_pullback: float = 0.4
@export var powered_fov: float = 6.0
@export var speed_fov: float = 4.0
@export var kick_fov: float = 2.0
@export_group("Hover")
@export var hover_amplitude: float = 0.10
@export var hover_height: float = 1.5
@export var hover_response: float = 40.0
@export var max_hover_vertical_speed: float = 65.0

@onready var visual: MeshInstance3D = $MeshInstance3D
@onready var camera: Camera3D = $Camera3D
var visual_rest_position: Vector3
var visual_rest_rotation: Vector3
var camera_rest_fov: float
var camera_rest_position: Vector3
var pod_visual
var engine_audio: Array[AudioStreamPlayer] = []
var wind_audio: AudioStreamPlayer
var hover_time := 0.0
var power_blend := 0.0
var throttle_kick := 0.0
var previous_power := 0.0
var road_normal := Vector3.UP
var engines: Array[MeshInstance3D] = []
var engine_levels := Vector2.ZERO
var left_thrust := 0.0
var right_thrust := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var left_steering := 0.0
var right_steering := 0.0
var thrust_envelope := preload("res://thrust_envelope.gd").new()
var applied_thrust := 0.0
var yaw_velocity := 0.0

func _ready() -> void:
	visual_rest_position = visual.position
	visual_rest_rotation = visual.rotation
	camera_rest_fov = camera.fov
	camera_rest_position = camera.position
	collision_mask = 3 # Road and barriers; road sampling ignores the barriers.
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	visual.mesh = null
	pod_visual = preload("res://pod_visual.gd").new()
	visual.add_child(pod_visual)
	engines = pod_visual.exhausts
	for side in ["Left", "Right"]:
		var player := _audio_loop("res://audio/engine.wav",side+"EngineAudio")
		engine_audio.append(player)
	wind_audio = _audio_loop("res://audio/wind.wav","WindAudio")

func _audio_loop(path: String, name_: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name_
	var stream := AudioStreamWAV.load_from_file(path)
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length()*stream.mix_rate)
	player.stream = stream
	player.volume_db = -60
	add_child(player)
	return player

func _update_audio(speed_ratio: float) -> void:
	# Engine sound is disabled. Preserve the assets for later, but never play them.
	for player in engine_audio:
		if player.playing: player.stop()
		player.volume_db = -80
	wind_audio.volume_db = lerpf(-48,-25,pow(speed_ratio,0.65))
	wind_audio.pitch_scale = 0.7+speed_ratio*0.65
	if speed_ratio>0.035 and not wind_audio.playing: wind_audio.play()
	elif speed_ratio<=0.035 and wind_audio.playing: wind_audio.stop()

func reset_visuals() -> void:
	yaw_velocity = 0.0
	thrust_envelope.reset()
	applied_thrust = 0.0
	hover_time = 0.0
	power_blend = 0.0
	throttle_kick = 0.0
	previous_power = 0.0
	road_normal = Vector3.UP
	visual.position = visual_rest_position
	visual.rotation = visual_rest_rotation
	camera.fov = camera_rest_fov
	camera.position = camera_rest_position
	for player in engine_audio:
		player.stop()
		player.volume_db = -60
	wind_audio.stop()
	wind_audio.volume_db = -60
	engine_levels = Vector2.ZERO
	left_thrust = 0.0
	right_thrust = 0.0
	throttle_input = 0.0
	brake_input = 0.0
	left_steering = 0.0
	right_steering = 0.0
	for engine in engines:
		engine.visible = false

func road_at(point: Vector3) -> Dictionary:
	# Jolt can miss a ray exactly on a shared triangle edge. Tiny fallback offsets
	# keep suspension continuous at seams without bridging any real track gaps.
	for offset in [Vector3.ZERO, Vector3(0.04,0,0), Vector3(-0.04,0,0), Vector3(0,0,0.04), Vector3(0,0,-0.04)]:
		var origin: Vector3 = point + offset
		var query := PhysicsRayQueryParameters3D.create(origin + Vector3.UP*8.0,origin - Vector3.UP*40.0,1,[get_rid()])
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			return hit
	return {}

func stick_vector(side: String) -> Vector2:
	var raw := Vector2(
		Input.get_action_raw_strength(side+"_steer_right")-Input.get_action_raw_strength(side+"_steer_left"),
		Input.get_action_raw_strength(side+"_pull_down")-Input.get_action_raw_strength(side+"_push_up")
	)
	var magnitude := minf(raw.length(),1.0)
	if magnitude<=stick_deadzone: return Vector2.ZERO
	return raw.normalized()*(magnitude-stick_deadzone)/(1.0-stick_deadzone)

func trigger_input(action: String) -> float:
	var raw := Input.get_action_raw_strength(action)
	if raw<=trigger_deadzone: return 0.0
	return (raw-trigger_deadzone)/(1.0-trigger_deadzone)

func _physics_process(delta: float) -> void:
	throttle_input = trigger_input("thrust")
	brake_input = trigger_input("brake")
	var left_stick := stick_vector("left")
	var right_stick := stick_vector("right")
	left_steering = left_stick.x
	right_steering = right_stick.x
	# Each stick contributes half the full yaw rate; opposed inputs cancel exactly.
	var steering := clampf((left_steering+right_steering)*0.5,-1.0,1.0)
	# Only the inside stick's pull-down strengthens the current turn. Smooth
	# gating near cancellation prevents down-alone or noisy sign changes turning.
	var pull_amount := 0.0
	if steering<0.0: pull_amount = maxf(left_stick.y,0.0)
	elif steering>0.0: pull_amount = maxf(right_stick.y,0.0)
	pull_amount *= smoothstep(0.0,0.35,absf(steering))
	var yaw_rate := -steering*turn_speed-signf(steering)*pull_amount*down_turn_boost
	var turn_response := turn_deceleration if absf(yaw_rate) < absf(yaw_velocity) else turn_acceleration
	yaw_velocity = move_toward(yaw_velocity, yaw_rate, turn_response * delta)
	rotate_y(yaw_velocity*delta)
	# Full air brake wins over throttle, including when both triggers are held.
	var propulsion: float = thrust_envelope.advance(throttle_input, delta, thrust_attack, thrust_decay, thrust_sustain, thrust_release)*(1.0-brake_input)
	applied_thrust = propulsion
	left_thrust = propulsion
	right_thrust = propulsion
	var horizontal := Vector3(velocity.x,0,velocity.z)
	if propulsion>0.001:
		var forward := -global_transform.basis.z
		horizontal += forward*acceleration*propulsion*delta
		var along := forward*horizontal.dot(forward)
		var sideways := horizontal-along
		horizontal = (along+sideways*exp(-thrust_grip*propulsion*delta)).limit_length(max_speed)
	else:
		# Steering changes facing, never the direction of off-throttle travel.
		horizontal = horizontal.move_toward(Vector3.ZERO,maxf(coast_deceleration,0.0)*delta)
	if brake_input>0.0:
		horizontal = horizontal.move_toward(Vector3.ZERO,maxf(braking,0.0)*brake_input*delta)
	velocity.x = horizontal.x
	velocity.z = horizontal.z

	# Look one physics step ahead; vertical suspension never feeds speed or grip.
	var road := road_at(global_position + horizontal * delta)
	if not road.is_empty():
		road_normal = road.normal
		var target_y: float = road.position.y + hover_height
		velocity.y = clampf((target_y - global_position.y) * hover_response, -max_hover_vertical_speed, max_hover_vertical_speed)
	else:
		velocity.y -= 25.0 * delta
	move_and_slide()
	if global_position.y < -30.0:
		global_position = Vector3(55, 2, 30)
		rotation = Vector3.ZERO
		velocity = Vector3.ZERO
		reset_visuals()

	_update_visuals(delta, propulsion, steering, yaw_velocity, horizontal.length(),pull_amount)

func _update_visuals(delta: float, propulsion: float, steering: float, yaw_rate: float, speed: float, pull_amount: float = 0.0) -> void:
	hover_time += delta
	var movement := clampf(speed / maxf(max_speed, 0.01), 0.0, 1.0)
	var smoothing := 1.0 - exp(-8.0 * delta)
	var activity := (absf(left_thrust) + absf(right_thrust)) * 0.5
	# The onset cue is visual only, bounded even during repeated gas taps.
	throttle_kick = minf(1.0,throttle_kick+maxf(activity-previous_power,0.0))
	previous_power = activity
	if activity<0.001: throttle_kick = 0.0
	throttle_kick *= exp(-8.0*delta)
	power_blend = lerpf(power_blend, activity, 1.0 - exp(-18.0 * delta))
	var forward := -global_transform.basis.z
	var slope_pitch := atan2(-road_normal.dot(forward), maxf(road_normal.y, 0.01))
	var bank := clampf(-steering*bank_degrees+signf(yaw_rate)*pull_amount*down_bank_degrees,-max_bank_degrees,max_bank_degrees)
	visual.rotation.z = lerp_angle(visual.rotation.z, visual_rest_rotation.z+deg_to_rad(bank),smoothing)
	# Boat-like visual oversteer: stronger tail swing while lining up off gas.
	var combined := absf(steering)
	var stern_swing := clampf(yaw_rate * 0.13 * (1.0 + combined * 0.4), -0.30, 0.30)
	stern_swing *= 1.0 - power_blend * 0.35
	visual.rotation.y = lerp_angle(visual.rotation.y, visual_rest_rotation.y + stern_swing, 1.0-exp(-4.5*delta))
	visual.rotation.x = lerp_angle(visual.rotation.x, visual_rest_rotation.x + slope_pitch - propulsion * deg_to_rad(power_pitch_degrees) + pull_amount*deg_to_rad(down_pitch_degrees), smoothing)
	# Released throttle has a light, rhythmic skip; only the mesh bobs.
	var skip := pow(maxf(sin(hover_time * 7.5), 0.0), 2.0) * 0.18 * movement * (1.0-power_blend)
	var bob := sin(hover_time * 4.2) * hover_amplitude * (0.3 + movement * 0.25)
	visual.position = visual_rest_position + Vector3.UP * (bob + skip)
	engine_levels = engine_levels.lerp(Vector2(left_thrust, right_thrust), 1.0-exp(-14.0*delta))
	pod_visual.animate(engine_levels.x,engine_levels.y,delta)
	_update_audio(movement)
	# A short smooth pullback on power; no shake, roll or camera bob.
	camera.position = camera.position.lerp(camera_rest_position+Vector3(0,0,power_blend*camera_pullback+throttle_kick*camera_kick_pullback),1.0-exp(-8.0*delta))
	camera.fov = lerpf(camera.fov, camera_rest_fov + movement * speed_fov + power_blend * powered_fov + throttle_kick * kick_fov, 1.0-exp(-7.0*delta))

func _exit_tree() -> void:
	for player in engine_audio:
		if is_instance_valid(player): player.stop()
	if is_instance_valid(wind_audio): wind_audio.stop()
