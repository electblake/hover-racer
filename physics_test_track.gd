extends Node3D
## Authored straight test route: solid -> ice -> liquid/current -> solid; wind above exit.

func _ready() -> void:
	_ground("Road", Vector3(0, -0.5, 25), Vector3(36, 1, 70), preload("res://surfaces/road.tres"), Color("536777"))
	_ground("Ice", Vector3(0, -0.5, -25), Vector3(36, 1, 30), preload("res://surfaces/ice.tres"), Color("a0d8ee"))
	_ground("Basin", Vector3(0, -6.5, -70), Vector3(36, 1, 60), preload("res://surfaces/road.tres"), Color("254754"))
	_ground("Exit", Vector3(0, -0.5, -150), Vector3(36, 1, 100), preload("res://surfaces/road.tres"), Color("536777"))
	var water := FluidRegion3D.new()
	water.name = "WaterCurrent"
	water.medium = preload("res://surfaces/water.tres")
	water.size_m = Vector3(36, 6, 60)
	water.position = Vector3(0, -3, -70)
	water.flow_velocity = Vector3(3, 0, 0)
	add_child(water)
	var water_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(36, 60)
	water_mesh.mesh = plane
	water_mesh.position = Vector3(0, 0, -70)
	var water_material := StandardMaterial3D.new()
	water_material.albedo_color = Color(0.05, 0.4, 0.65, 0.7)
	water_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_material.roughness = 0.15
	water_mesh.material_override = water_material
	add_child(water_mesh)
	var wind := FluidRegion3D.new()
	wind.name = "Crosswind"
	wind.medium = preload("res://surfaces/air.tres")
	wind.size_m = Vector3(36, 25, 60)
	wind.position = Vector3(0, 10, -135)
	wind.flow_velocity = Vector3(20, 0, 0)
	add_child(wind)
	for item in [["SOLID", 30.0], ["ICE / CONTACT FRICTION", -20.0], ["WATER / CURRENT 3 m/s", -65.0], ["CROSSWIND 20 m/s", -130.0]]:
		var label := Label3D.new()
		label.text = item[0]
		label.position = Vector3(-16, 4, item[1])
		label.font_size = 64
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)

func _ground(label: String, location: Vector3, dimensions: Vector3, surface: TrackSurface, color: Color) -> void:
	var body := TrackSurface3D.new()
	body.name = label
	body.surface = surface
	body.position = location
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = dimensions
	shape.shape = box
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = dimensions
	mesh.mesh = box_mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
