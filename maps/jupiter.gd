extends Node3D

const RADIUS := 360.0
const WIDTH := 36.0
const SEGMENTS := 720
@export var inward_acceleration := 4.5
var ship: VehicleController
var last_pull := Vector3.ZERO
var camera_rest_yaw := 0.0

func _ready() -> void:
	ship = get_parent().get_parent().get_node("SHIP")
	camera_rest_yaw = ship.get_node("Camera3D").rotation.y
	var road_material := ShaderMaterial.new()
	road_material.shader = preload("res://maps/jupiter_ring.gdshader")
	road_material.set_shader_parameter("racing_surface", true)
	var road := annulus("RingRoad", RADIUS - WIDTH * 0.5, RADIUS + WIDTH * 0.5, 0.5, road_material)
	var support := TrackSurface3D.new()
	support.name = "RoadCollision"
	support.collision_layer = 1
	add_child(support)
	var shape := CollisionShape3D.new()
	shape.shape = road.mesh.create_trimesh_shape()
	support.add_child(shape)
	var dust_material := ShaderMaterial.new()
	dust_material.shader = preload("res://maps/jupiter_ring.gdshader")
	for bounds in [Vector2(263, 292), Vector2(298, 331), Vector2(387, 414), Vector2(424, 470)]:
		annulus("DustRing", bounds.x, bounds.y, -4.0, dust_material)
	build_edges()
	var planet := MeshInstance3D.new()
	planet.name = "Jupiter"
	var sphere := SphereMesh.new()
	sphere.radius = 310
	sphere.height = 620
	sphere.radial_segments = 128
	sphere.rings = 64
	planet.mesh = sphere
	var clouds := ShaderMaterial.new()
	clouds.shader = preload("res://maps/jupiter_clouds.gdshader")
	planet.material_override = clouds
	planet.position = Vector3(0, -130, 0)
	add_child(planet)
	# Fixed scenic moons, enlarged and spaced around the outer ring for drive-by views.
	var moon_names := ["Io", "Europa", "Ganymede", "Callisto"]
	var moon_positions := [Vector3(490, 95, -390), Vector3(-390, 110, -490), Vector3(-490, 135, 390), Vector3(390, 120, 490)]
	var moon_radii := [48.0, 43.0, 65.0, 59.0]
	for i in range(4):
		var moon := MeshInstance3D.new()
		moon.name = moon_names[i]
		var moon_mesh := SphereMesh.new()
		moon_mesh.radius = moon_radii[i]
		moon_mesh.height = moon_radii[i] * 2.0
		moon_mesh.radial_segments = 96
		moon_mesh.rings = 48
		moon.mesh = moon_mesh
		var surface := ShaderMaterial.new()
		surface.shader = preload("res://maps/galilean_moon.gdshader")
		surface.set_shader_parameter("moon_type", i)
		moon.material_override = surface
		moon.position = moon_positions[i]
		add_child(moon)
	build_stars()
	add_sign("StartFinish", "JUPITER / RINGRUNNER\n← INWARD GRAVITY", Vector3(360, 8, -12), Color(0.55, 0.85, 1))
	add_sign("GreatRedSpot", "GREAT RED SPOT\nQUARTER ORBIT", Vector3(0, 10, -360), Color(1, 0.35, 0.12))
	var finish_material := glow_material(Color(0.3, 0.8, 1))
	for i in range(12):
		var mark := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.5, 0.04, 2)
		mark.mesh = box
		mark.material_override = finish_material
		mark.position = Vector3(343.5 + i * 3, 0.53, 0)
		add_child(mark)

func annulus(node_name: String, inner: float, outer: float, height: float, mat: Material) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in range(SEGMENTS):
		var a := TAU * i / SEGMENTS
		var b := TAU * (i + 1) / SEGMENTS
		var p := Vector3(cos(a) * inner, height, sin(a) * inner)
		var q := Vector3(cos(a) * outer, height, sin(a) * outer)
		var r := Vector3(cos(b) * inner, height, sin(b) * inner)
		var s := Vector3(cos(b) * outer, height, sin(b) * outer)
		vertices.append_array(PackedVector3Array([p, q, r, q, s, r]))
		for j in range(6): normals.append(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh
	node.material_override = mat
	add_child(node)
	return node

func glow_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.2
	return mat

func build_edges() -> void:
	var inner_mat := glow_material(Color(1, 0.32, 0.08))
	var outer_mat := glow_material(Color(0.24, 0.65, 1))
	annulus("InnerWarning", 342, 342.8, 0.54, inner_mat)
	annulus("OuterGuide", 377.2, 378, 0.54, outer_mat)
	var walls := PackedVector3Array()
	for radius in [342.0, 378.0]:
		for i in range(SEGMENTS):
			var a := TAU * i / SEGMENTS
			var b := TAU * (i + 1) / SEGMENTS
			var p := Vector3(cos(a) * radius, 0.5, sin(a) * radius)
			var q := Vector3(cos(b) * radius, 0.5, sin(b) * radius)
			walls.append_array(PackedVector3Array([p, q, p + Vector3.UP, q, q + Vector3.UP, p + Vector3.UP]))
	var barrier := TrackSurface3D.new()
	barrier.name = "RingRails"
	barrier.collision_layer = 2
	add_child(barrier)
	var collision := CollisionShape3D.new()
	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(walls)
	collision.shape = shape
	barrier.add_child(collision)
	for radius in [342.0, 378.0]:
		var rail := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = radius - 0.15
		torus.outer_radius = radius + 0.15
		torus.rings = 256
		torus.ring_segments = 8
		rail.mesh = torus
		rail.material_override = inner_mat if radius < RADIUS else outer_mat
		rail.position.y = 1.5
		add_child(rail)

func add_sign(node_name: String, text: String, point: Vector3, color: Color) -> void:
	var label := Label3D.new()
	label.name = node_name
	label.text = text
	label.position = point
	label.font_size = 70
	label.pixel_size = 0.014
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)

func build_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 404
	var stars := MultiMeshInstance3D.new()
	stars.name = "Stars"
	var mesh := SphereMesh.new()
	mesh.radius = 1.4
	mesh.height = 2.8
	mesh.radial_segments = 4
	mesh.rings = 2
	var mat := glow_material(Color(0.75, 0.8, 1))
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 900
	for i in range(900):
		var direction := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.3, 1), rng.randf_range(-1, 1)).normalized()
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, direction * 1500))
	stars.multimesh = multimesh
	add_child(stars)

func gravity_at(point: Vector3) -> Vector3:
	return -Vector3(point.x, 0, point.z).normalized() * inward_acceleration

func _process(delta: float) -> void:
	# A gentle inward glance on the storm approach keeps the landmark in the driving view.
	var longitude := atan2(ship.position.z, ship.position.x)
	var storm_distance := absf(wrapf(longitude + PI * 0.5, -PI, PI))
	var glance := (1.0 - smoothstep(0.25, 1.05, storm_distance)) * 0.45
	var camera: Camera3D = ship.get_node("Camera3D")
	camera.rotation.y = lerpf(camera.rotation.y, camera_rest_yaw + glance, 1.0 - exp(-3.0 * delta))

func _exit_tree() -> void:
	ship.get_node("Camera3D").rotation.y = camera_rest_yaw

func _physics_process(_delta: float) -> void:
	last_pull = Vector3.ZERO
	if ship.gameplay_enabled and not ship.is_crashed:
		last_pull = gravity_at(ship.global_position) * ship.mass
		ship.apply_central_force(last_pull)
