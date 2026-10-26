extends SubViewportContainer
## A separate world keeps the attract loop independent of the paused race.

const SPEED := 12.0
var viewport: SubViewport
var world: Node3D
var racer: VehicleController
var course: Node3D
var route: Curve3D
var distance := 0.0
var map_index := -1
var visual: Node3D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	stretch = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport = SubViewport.new()
	viewport.own_world_3d = true
	viewport.handle_input_locally = false
	viewport.physics_object_picking = false
	add_child(viewport)
	set_process(false)

func show_map(index: int, definition: Resource, parts: Array[int]) -> void:
	show()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if index == map_index:
		visual.set_parts(parts[0], parts[1], parts[2])
		set_process(true)
		return
	if world != null:
		viewport.remove_child(world)
		world.queue_free()
	map_index = index
	distance = 0.0
	world = Node3D.new()
	world.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	viewport.add_child(world)
	racer = VehicleController.new()
	racer.name = "SHIP"
	racer.player_controlled = false
	racer.gameplay_enabled = false
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0, 4.6, 10)
	camera.rotation.x = deg_to_rad(-15)
	racer.add_child(camera)
	world.add_child(racer)
	racer.process_mode = Node.PROCESS_MODE_DISABLED
	racer.collision_layer = 0
	racer.collision_mask = 0
	visual = preload("res://pod_visual.gd").new()
	racer.add_child(visual)
	visual.set_parts(parts[0], parts[1], parts[2])
	# Map scripts resolve their racer through this same hierarchy as the race.
	var holder := Node3D.new()
	world.add_child(holder)
	course = load(definition.scene_path).instantiate()
	course.process_mode = Node.PROCESS_MODE_ALWAYS
	holder.add_child(course)
	var environment := WorldEnvironment.new()
	environment.environment = definition.environment
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation.x = deg_to_rad(-45)
	world.add_child(light)
	route = Curve3D.new()
	route.bake_interval = 0.5
	if index < 3:
		var samples: Array = JSON.parse_string(FileAccess.get_file_as_string(definition.samples_path))
		for sample in samples:
			var point: Array = sample.point
			route.add_point(Vector3(point[0], point[1] + 0.3, point[2]))
	elif index == 3:
		for i in range(720):
			var angle := -TAU * i / 720.0
			route.add_point(Vector3(cos(angle) * 360, 0.8, sin(angle) * 360))
	else:
		# The lab is a straight strip: a narrow oval tours it in both directions.
		for i in range(240):
			var angle := TAU * i / 240.0
			route.add_point(Vector3(sin(angle) * 6, 0.8, -70 + cos(angle) * 110))
	route.add_point(route.get_point_position(0))
	distance = route.get_closest_offset(definition.spawn.origin)
	place_racer()
	set_process(true)

func stop() -> void:
	hide()
	set_process(false)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if world != null:
		viewport.remove_child(world)
		world.queue_free()
		world = null
	map_index = -1

func place_racer() -> void:
	var length := route.get_baked_length()
	var position_ := route.sample_baked(distance)
	var direction := (route.sample_baked(fposmod(distance + 1.0, length)) - route.sample_baked(fposmod(distance - 1.0, length))).normalized()
	racer.transform = Transform3D(Basis.looking_at(direction), position_)
	racer.linear_velocity = direction * SPEED
	racer.actual_speed = SPEED

func _process(delta: float) -> void:
	distance = fposmod(distance + SPEED * delta, route.get_baked_length())
	place_racer()
	visual.animate(0.25, 0.25, delta)
