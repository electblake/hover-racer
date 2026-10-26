extends VehicleController

@export var bank_degrees := 8.0
@export var down_bank_degrees := 18.0
@export var max_bank_degrees := 50.0
@export var down_pitch_degrees := 3.0
@export var power_pitch_degrees := 6.0
@export var camera_pullback := 1.1
@export var camera_kick_pullback := 0.4
@export var powered_fov := 6.0
@export var speed_fov := 4.0
@export var kick_fov := 2.0
@export var hover_amplitude := 0.02
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
var engines: Array[MeshInstance3D] = []
var engine_levels := Vector2.ZERO
var visual_reset_pending := false

func _ready() -> void:
	super._ready()
	# The chassis supplies interpolated travel. Camera-local presentation also
	# responds to viewport resizing and map glances outside the physics tick.
	camera.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	visual.position.y = 0.0
	visual_rest_position = visual.position
	visual_rest_rotation = visual.rotation
	camera_rest_fov = camera.fov
	camera_rest_position = camera.position
	visual.mesh = null
	pod_visual = preload("res://pod_visual.gd").new()
	visual.add_child(pod_visual)
	engines = pod_visual.exhausts
	for side in ["Left", "Right"]:
		engine_audio.append(_audio_loop("res://audio/engine.wav", side + "EngineAudio"))
	wind_audio = _audio_loop("res://audio/wind.wav", "WindAudio")

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if visual_reset_pending:
		visual.position = visual_rest_position
		visual.rotation = visual_rest_rotation
		camera.fov = camera_rest_fov
		camera.position = camera_rest_position
		visual.reset_physics_interpolation()
		camera.reset_physics_interpolation()
		visual_reset_pending = false
	_update_visuals(delta, clampf(applied_thrust / 2.0, 0.0, 1.0), steering, yaw_velocity, actual_speed, maneuver_blend)

func reset_visuals() -> void:
	# Menus/input can request reset between ticks; interpolated nodes move on ticks.
	visual_reset_pending = true
	hover_time = 0.0
	power_blend = 0.0
	throttle_kick = 0.0
	previous_power = 0.0
	engine_levels = Vector2.ZERO
	for engine in engines: engine.visible = false
	for player in engine_audio: player.stop()
	wind_audio.stop()
	reset_physics_interpolation()

func _exit_tree() -> void:
	for player in engine_audio + [wind_audio]:
		player.stop()
		player.stream = null

func _audio_loop(path: String, name_: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = name_
	var stream := load(path).duplicate() as AudioStreamWAV
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

func _update_visuals(delta: float, propulsion: float, steering: float, yaw_rate: float, speed: float, pull_amount: float = 0.0) -> void:
	hover_time += delta
	var movement := clampf(speed / derived.base_speed_mps, 0.0, 1.0)
	var smoothing := 1.0 - exp(-8.0 * delta)
	var activity := propulsion
	# The onset cue is visual only, bounded even during repeated gas taps.
	throttle_kick = minf(1.0,throttle_kick+maxf(activity-previous_power,0.0))
	previous_power = activity
	if activity<0.001: throttle_kick = 0.0
	throttle_kick *= exp(-8.0*delta)
	power_blend = lerpf(power_blend, activity, 1.0 - exp(-18.0 * delta))
	var slope_pitch := 0.0 # Chassis already follows the road.
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
	engine_levels = engine_levels.lerp(Vector2(propulsion, propulsion), 1.0-exp(-14.0*delta))
	pod_visual.animate(engine_levels.x,engine_levels.y,delta)
	_update_audio(movement)
	# A short smooth pullback on power; no shake, roll or camera bob.
	camera.position = camera.position.lerp(camera_rest_position+Vector3(0,0,power_blend*camera_pullback+throttle_kick*camera_kick_pullback),1.0-exp(-8.0*delta))
	camera.fov = lerpf(camera.fov, camera_rest_fov + movement * speed_fov + power_blend * powered_fov + throttle_kick * kick_fov, 1.0-exp(-7.0*delta))
