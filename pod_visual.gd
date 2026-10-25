extends Node3D
# Original low-poly twin-engine racer geometry, generated locally.
var exhausts: Array[MeshInstance3D] = []
var turbine_rings: Array[Node3D] = []
var phase := 0.0

func mat(color: Color, emission := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = 0.5
	m.roughness = 0.55
	if emission:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 2.5
	return m

func mesh_part(name_: String, mesh: Mesh, position_: Vector3, material: Material, rotation_: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.name = name_
	part.mesh = mesh
	part.position = position_
	part.rotation = rotation_
	part.material_override = material
	add_child(part)
	return part

func box(name_: String, position_: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh_part(name_,mesh,position_,material)

func rod(name_: String, a: Vector3, b: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	var part := mesh_part(name_,mesh,(a+b)*0.5,material)
	var direction := (b-a).normalized()
	var side := Vector3.UP.cross(direction).normalized()
	if side.is_zero_approx(): side = Vector3.RIGHT
	part.basis = Basis(side,direction,side.cross(direction).normalized())
	return part

func _ready() -> void:
	var gold := mat(Color(0.95,0.58,0.08))
	var blue := mat(Color(0.08,0.32,0.55))
	var metal := mat(Color(0.35,0.40,0.44))
	var dark := mat(Color(0.035,0.055,0.07))
	var cyan := mat(Color(0.1,0.8,1),true)
	for side in [-1.0,1.0]:
		var x: float = side*1.10
		var shell := CylinderMesh.new()
		shell.height = 3.2
		shell.top_radius = 0.39
		shell.bottom_radius = 0.46
		shell.radial_segments = 10
		mesh_part("LeftEnginePod" if side<0 else "RightEnginePod",shell,Vector3(x,0,-0.65),gold,Vector3(PI/2,0,0))
		for z in [-2.12,-1.25,0.65]:
			var collar := CylinderMesh.new()
			collar.height = 0.18
			collar.top_radius = 0.48
			collar.bottom_radius = 0.48
			collar.radial_segments = 10
			mesh_part("EngineCollar",collar,Vector3(x,0,z),blue,Vector3(PI/2,0,0))
		var intake := CylinderMesh.new()
		intake.height = 0.09
		intake.top_radius = 0.35
		intake.bottom_radius = 0.35
		intake.radial_segments = 10
		mesh_part("DarkIntake",intake,Vector3(x,0,-2.29),dark,Vector3(PI/2,0,0))
		var blades := Node3D.new()
		blades.position = Vector3(x,0,-2.35)
		add_child(blades)
		turbine_rings.append(blades)
		for angle in [0.0,PI/3,2*PI/3]:
			var blade := box("IntakeBlade",Vector3.ZERO,Vector3(0.58,0.055,0.035),metal)
			remove_child(blade)
			blades.add_child(blade)
			blade.rotation.z = angle
		box("TopBlueStripe",Vector3(x,0.43,-0.6),Vector3(0.22,0.06,2.3),blue)
		rod("ControlTether",Vector3(x,0.05,0.9),Vector3(side*0.3,0.05,1.65),0.035,metal)
		rod("UpperTether",Vector3(x,0.26,0.5),Vector3(side*0.25,0.22,1.6),0.022,gold)
		var plume := CylinderMesh.new()
		plume.height = 0.8
		plume.top_radius = 0.025
		plume.bottom_radius = 0.22
		plume.radial_segments = 8
		var flame := mesh_part("LeftExhaust" if side<0 else "RightExhaust",plume,Vector3(x,0,1.08),cyan.duplicate(),Vector3(PI/2,0,0))
		flame.visible = false
		exhausts.append(flame)
	box("TrailingCockpit",Vector3(0,0.03,1.45),Vector3(0.75,0.42,1.25),gold)
	box("CockpitCanopy",Vector3(0,0.31,1.46),Vector3(0.5,0.25,0.64),dark)
	box("TailFin",Vector3(0,0.43,1.95),Vector3(0.08,0.65,0.36),blue)
	rod("EnergyLink",Vector3(-0.65,0,-0.45),Vector3(0.65,0,-0.45),0.045,cyan)
	rod("EnergyFork",Vector3(-0.6,0.04,-0.2),Vector3(0.65,-0.04,-0.65),0.02,cyan)

func animate(left: float, right: float, delta: float) -> void:
	phase += delta
	for i in range(2):
		var level: float = left if i==0 else right
		var flame := exhausts[i]
		flame.visible = absf(level)>0.03
		flame.position.z = 1.05 if level>=0 else -2.55
		flame.rotation.x = PI/2 if level>=0 else -PI/2
		flame.scale.y = 0.4+absf(level)*(2.5+0.15*sin(phase*42+i))
		var color := Color(0.08,0.7,1) if level>=0 else Color(1,0.24,0.04)
		var m := flame.material_override as StandardMaterial3D
		m.albedo_color = color
		m.emission = color
		m.emission_energy_multiplier = 1.5+absf(level)*5
		turbine_rings[i].rotate_z(delta*(3+absf(level)*24))
