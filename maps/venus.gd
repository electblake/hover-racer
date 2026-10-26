extends Node3D

var liquid: ShaderMaterial
var rain: GPUParticles3D
var ship: VehicleController
var elapsed := 0.0
var wake_interval := 0.0
var wake_index := 0
var wakes: Array[Vector4] = []

func _ready() -> void:
	ship = get_parent().get_parent().get_node("SHIP")
	$Road/RoadCollision.collision_layer = 0
	var sea := FluidRegion3D.new()
	sea.name = "AureateSeaPhysics"
	sea.medium = preload("res://surfaces/water.tres")
	sea.surface = preload("res://surfaces/venus_wet.tres")
	sea.size_m = Vector3(1100, 8, 1300)
	sea.position = Vector3(-127.5, -3.5, -50)
	sea.flow_velocity = Vector3(1, 0, 0)
	add_child(sea)
	liquid = ShaderMaterial.new()
	liquid.shader = preload("res://maps/venus_liquid.gdshader")
	$Road/RoadSurface.material_override = liquid
	for i in range(16): wakes.append(Vector4(0, 0, -100, 0))
	liquid.set_shader_parameter("wakes", wakes)
	var basalt := material(Color(0.065, 0.035, 0.085), 0.0)
	var sulfur := material(Color(0.66, 0.82, 0.035), 1.1)
	var crust := material(Color(0.16, 0.10, 0.045), 0.0)
	for node in $Road.get_children():
		if node.name.begins_with("Barrier_"):
			node.material_override = basalt
		elif node.name.begins_with("EdgeMarker") or node.name.begins_with("StartPylon"):
			node.material_override = sulfur
		elif node.name.begins_with("CenterDash") or node.name.begins_with("BrakeMarker") or node.name.begins_with("StartFinish"):
			node.hide()
	$Road/Surroundings.material_override = crust
	build_formations(basalt, sulfur)
	build_rain()
	var title := Label3D.new()
	title.text = "VENUS\nAUREATE SEA"
	title.position = Vector3(55, 11, 5)
	title.font_size = 80
	title.pixel_size = 0.018
	title.modulate = Color(0.9, 1.0, 0.2)
	add_child(title)

func material(color: Color, glow: float) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.6
	result.emission_enabled = glow > 0.0
	result.emission = color
	result.emission_energy_multiplier = glow
	return result

func build_formations(basalt: Material, sulfur: Material) -> void:
	var samples: Array = JSON.parse_string(FileAccess.get_file_as_string("res://maps/map_3_samples.json"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 303
	for i in range(0, samples.size(), 22):
		var p: Array = samples[i].point
		var n: Array = samples[i].normal
		for side in [-1, 1]:
			var spire := MeshInstance3D.new()
			spire.name = "AlienSpire"
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.3
			mesh.bottom_radius = rng.randf_range(3, 6)
			mesh.height = rng.randf_range(14, 32)
			mesh.radial_segments = 5
			spire.mesh = mesh
			spire.material_override = basalt
			spire.position = Vector3(p[0], mesh.height * 0.5 - 2, p[2]) + Vector3(n[0], 0, n[2]) * side * 32.0
			spire.rotation = Vector3(0.12 * side, rng.randf_range(0, TAU), 0.18 * side)
			add_child(spire)
			var crystal := MeshInstance3D.new()
			crystal.name = "SulfurCrystal"
			var crystal_mesh := PrismMesh.new()
			crystal_mesh.size = Vector3(2.0, 5.0, 2.0)
			crystal.mesh = crystal_mesh
			crystal.material_override = sulfur
			crystal.position = spire.position + Vector3(0, mesh.height * 0.5 + 2, 0)
			crystal.rotation.z = PI
			add_child(crystal)

func build_rain() -> void:
	rain = GPUParticles3D.new()
	rain.name = "AcidRain"
	rain.amount = 2200
	rain.lifetime = 1.1
	rain.preprocess = 1.1
	rain.local_coords = false
	rain.visibility_aabb = AABB(Vector3(-65, -38, -65), Vector3(130, 65, 130))
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(48, 1, 48)
	process.direction = Vector3(-0.12, -1, 0.05)
	process.spread = 3.0
	process.initial_velocity_min = 25.0
	process.initial_velocity_max = 30.0
	process.gravity = Vector3(0, -5, 0)
	process.collision_mode = ParticleProcessMaterial.COLLISION_HIDE_ON_CONTACT
	rain.process_material = process
	var streak := BoxMesh.new()
	streak.size = Vector3(0.035, 0.9, 0.035)
	streak.material = material(Color(0.64, 0.95, 0.12), 0.8)
	rain.draw_pass_1 = streak
	add_child(rain)
	var collision := GPUParticlesCollisionHeightField3D.new()
	collision.name = "RainSurface"
	collision.size = Vector3(110, 60, 110)
	collision.follow_camera_enabled = true
	collision.update_mode = GPUParticlesCollisionHeightField3D.UPDATE_MODE_WHEN_MOVED
	add_child(collision)

func _process(delta: float) -> void:
	elapsed += delta
	wake_interval += delta
	rain.global_position = Vector3(ship.global_position.x, 28, ship.global_position.z)
	if wake_interval >= 0.08:
		wake_interval = 0.0
		var strength := clampf(ship.linear_velocity.length() / 35.0, 0.0, 1.0) * clampf(1.0 - absf(ship.global_position.y - 0.8) / 3.0, 0.0, 1.0)
		wakes[wake_index] = Vector4(ship.global_position.x, ship.global_position.z, elapsed, strength)
		wake_index = (wake_index + 1) % wakes.size()
		liquid.set_shader_parameter("wakes", wakes)
	liquid.set_shader_parameter("elapsed", elapsed)
