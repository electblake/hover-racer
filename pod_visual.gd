extends Node3D
# Three cosmetic slots, sharing the same chassis envelope and attachment points.
const KITS := ["Terra", "Magellan", "Juno"]
const SLOTS := ["Nose", "Core", "Engines"]
var selections: Array[int] = [0, 0, 0]
var modules: Array[Node3D] = []
var engine_exhausts: Array = []
var engine_turbines: Array = []
var build_parent: Node3D
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
	build_parent.add_child(part)
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
	for slot in range(3):
		var group := Node3D.new()
		group.name = SLOTS[slot]
		add_child(group)
		modules.append(group)
		for kit in range(3):
			build_parent = Node3D.new()
			build_parent.name = KITS[kit]
			group.add_child(build_parent)
			match slot:
				0: build_nose(kit)
				1: build_core(kit)
				2: build_engines(kit)
	set_parts(0, 0, 0)

func set_parts(nose: int, core: int, engines: int) -> void:
	selections.assign([nose, core, engines])
	for slot in range(3):
		for kit in range(3):
			modules[slot].get_child(kit).visible = selections[slot] == kit
	# Mutate the existing array: ship presentation retains this array reference.
	exhausts.assign(engine_exhausts[engines])
	turbine_rings.assign(engine_turbines[engines])
	animate(0.0, 0.0, 0.0)

func kit_material(kit: int) -> StandardMaterial3D:
	return mat([Color("d9eaf0"), Color("d89c38"), Color("b85c39")][kit])

func build_nose(kit: int) -> void:
	var shell := kit_material(kit)
	var dark := mat(Color("19313b"))
	match kit:
		0:
			var wedge := PrismMesh.new()
			wedge.size = Vector3(0.92, 1.6, 0.28)
			mesh_part("RacingWedge", wedge, Vector3(0, 0, -1.2), shell, Vector3(-PI/2, 0, 0))
			box("CenterStripe", Vector3(0, 0.15, -0.85), Vector3(0.12, 0.035, 0.7), mat(Color("23bfc6")))
		1:
			box("ArmoredProw", Vector3(0, 0, -1.15), Vector3(1.15, 0.36, 1.5), shell)
			box("Bumper", Vector3(0, 0, -1.94), Vector3(1.3, 0.25, 0.18), dark)
			for x in [-0.38, 0.38]:
				box("ArmorRidge", Vector3(x, 0.2, -1.15), Vector3(0.14, 0.08, 1.3), dark)
		2:
			box("ForkBridge", Vector3(0, 0, -0.65), Vector3(1.1, 0.25, 0.36), dark)
			for x in [-0.4, 0.4]:
				box("SalvageFork", Vector3(x, 0, -1.35), Vector3(0.22, 0.32, 1.7), shell)
				box("ForkTip", Vector3(x, 0.02, -2.12), Vector3(0.24, 0.2, 0.18), dark)

func build_core(kit: int) -> void:
	var shell := kit_material(kit)
	var dark := mat(Color("19313b"))
	var glass := mat(Color("123a55"))
	match kit:
		0:
			box("TrailingCockpit", Vector3(0, 0, 0.65), Vector3(0.7, 0.32, 2.2), shell)
			var canopy := SphereMesh.new()
			canopy.radius = 0.33
			canopy.height = 0.66
			var canopy_part := mesh_part("Canopy", canopy, Vector3(0, 0.2, 0.65), glass)
			canopy_part.scale = Vector3(1, 0.65, 1.8)
			box("TailFin", Vector3(0, 0.25, 1.6), Vector3(0.08, 0.5, 0.4), mat(Color("23bfc6")))
		1:
			box("TrailingCockpit", Vector3(0, 0, 0.65), Vector3(1.15, 0.4, 2.2), shell)
			box("ArmoredCabin", Vector3(0, 0.3, 0.65), Vector3(0.85, 0.3, 1.15), dark)
			box("Windshield", Vector3(0, 0.32, 0.05), Vector3(0.65, 0.2, 0.06), glass)
			for x in [-0.5, 0.5]:
				box("RearArmor", Vector3(x, 0.23, 1.5), Vector3(0.16, 0.24, 0.7), dark)
		2:
			box("TrailingCockpit", Vector3(0, -0.07, 0.65), Vector3(0.85, 0.2, 2.2), dark)
			box("PilotSeat", Vector3(0, 0.12, 0.8), Vector3(0.4, 0.35, 0.55), shell)
			for x in [-0.4, 0.4]:
				rod("RollCage", Vector3(x, 0.05, -0.25), Vector3(x, 0.4, 1.3), 0.045, shell)
				box("ExposedRail", Vector3(x, 0, 0.65), Vector3(0.1, 0.3, 2.2), shell)
			rod("RollBar", Vector3(-0.4, 0.4, 1.3), Vector3(0.4, 0.4, 1.3), 0.045, shell)
			box("RearMachinery", Vector3(0, 0.12, 1.5), Vector3(0.6, 0.3, 0.45), shell)

func build_engines(kit: int) -> void:
	var shell_material := kit_material(kit)
	var accent := mat([Color("23bfc6"), Color("443a29"), Color("e4c18a")][kit])
	var metal := mat(Color(0.35,0.40,0.44))
	var dark := mat(Color(0.035,0.055,0.07))
	var cyan := mat(Color(0.1,0.8,1),true)
	var flames: Array[MeshInstance3D] = []
	var turbines: Array[Node3D] = []
	for side in [-1.0,1.0]:
		var x: float = side*1.10
		var shell := CylinderMesh.new()
		shell.height = 3.2
		shell.top_radius = [0.26, 0.42, 0.32][kit]
		shell.bottom_radius = [0.32, 0.42, 0.38][kit]
		shell.radial_segments = [10, 8, 6][kit]
		mesh_part("LeftEnginePod" if side<0 else "RightEnginePod",shell,Vector3(x,0,-0.4),shell_material,Vector3(PI/2,0,0))
		for z in [-1.9, -0.9, 1.1]:
			var collar := CylinderMesh.new()
			collar.height = 0.18
			collar.top_radius = shell.bottom_radius + 0.025
			collar.bottom_radius = collar.top_radius
			collar.radial_segments = 10
			mesh_part("EngineCollar",collar,Vector3(x,0,z),accent,Vector3(PI/2,0,0))
		var intake := CylinderMesh.new()
		intake.height = 0.09
		intake.top_radius = shell.top_radius * 0.85
		intake.bottom_radius = intake.top_radius
		intake.radial_segments = 10
		mesh_part("DarkIntake",intake,Vector3(x,0,-2.04),dark,Vector3(PI/2,0,0))
		var blades := Node3D.new()
		blades.position = Vector3(x,0,-2.1)
		build_parent.add_child(blades)
		turbines.append(blades)
		for angle in [0.0,PI/3,2*PI/3]:
			var blade := box("IntakeBlade",Vector3.ZERO,Vector3(intake.top_radius * 1.8,0.055,0.035),metal)
			build_parent.remove_child(blade)
			blades.add_child(blade)
			blade.rotation.z = angle
		if kit == 2:
			for z in [-0.6, -0.25, 0.1, 0.45]:
				box("CoolingFin", Vector3(x, 0.35, z), Vector3(0.5, 0.15, 0.08), metal)
		else:
			box("TopStripe",Vector3(x,shell.bottom_radius,-0.4),Vector3(0.16,0.04,2.3),accent)
		rod("EngineMount",Vector3(x,0,0.8),Vector3(side*0.3,0,0.8),0.065,metal)
		var plume := CylinderMesh.new()
		plume.height = 0.8
		plume.top_radius = 0.025
		plume.bottom_radius = 0.22
		plume.radial_segments = 8
		var flame := mesh_part("LeftExhaust" if side<0 else "RightExhaust",plume,Vector3(x,0,1.4),cyan.duplicate(),Vector3(PI/2,0,0))
		flame.visible = false
		flames.append(flame)
	engine_exhausts.append(flames)
	engine_turbines.append(turbines)

func animate(left: float, right: float, delta: float) -> void:
	phase += delta
	for i in range(2):
		var level: float = left if i==0 else right
		var flame := exhausts[i]
		flame.visible = absf(level)>0.03
		flame.position.z = 1.4 if level>=0 else -2.3
		flame.rotation.x = PI/2 if level>=0 else -PI/2
		flame.scale.y = 0.4+absf(level)*(2.5+0.15*sin(phase*42+i))
		var color := Color(0.08,0.7,1) if level>=0 else Color(1,0.24,0.04)
		var m := flame.material_override as StandardMaterial3D
		m.albedo_color = color
		m.emission = color
		m.emission_energy_multiplier = 1.5+absf(level)*5
		turbine_rings[i].rotate_z(delta*(3+absf(level)*24))
