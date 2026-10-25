# Generates standalone scenery; does not rebuild or replace the user's track.
extends SceneTree
var canyon: Node3D
var rng := RandomNumberGenerator.new()

func _initialize() -> void:
	call_deferred("build")
func height_at(z: float) -> float:
	if z>-110 and z< -10: return 10*pow(sin(PI*(z+110)/100),2)
	return 0.0
func material(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.98
	return m
func own(node: Node, parent: Node) -> void:
	parent.add_child(node)
	node.owner = canyon
func rock(name_: String, pos: Vector3, size: Vector3, mat: Material, collision := false) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.65
	mesh.bottom_radius = 1
	mesh.height = 2
	mesh.radial_segments = 5
	var node := MeshInstance3D.new()
	node.name = name_
	node.mesh = mesh
	node.material_override = mat
	own(node,canyon)
	node.position = pos
	node.scale = size*0.5
	node.rotation.y = rng.randf_range(-PI,PI)
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = 2
		own(body,canyon)
		body.position = pos
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		own(shape,body)
func box(name_: String, pos: Vector3, size: Vector3, mat: Material, collision := false) -> void:
	var node := MeshInstance3D.new()
	node.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	own(node,canyon)
	node.position = pos
	if collision:
		var body := StaticBody3D.new()
		body.collision_layer = 2
		own(body,canyon)
		body.position = pos
		var shape := CollisionShape3D.new()
		var bounds := BoxShape3D.new()
		bounds.size = size
		shape.shape = bounds
		own(shape,body)
func build() -> void:
	canyon = Node3D.new()
	canyon.name = "CanyonSlice"
	rng.seed = 43
	var rocks: Array[Material] = []
	for color in [Color(.33,.16,.09),Color(.46,.25,.12),Color(.57,.33,.17),Color(.39,.24,.16)]: rocks.append(material(color))
	var light := material(Color(.15,.82,.92))
	light.emission_enabled = true
	light.emission = Color(.08,.5,.6)
	var dark := material(Color(.12,.09,.07))
	for z in range(-100,76,7):
		var h := height_at(z)
		for side in [-1,1]:
			var x: float = 55.0+side*rng.randf_range(22,24)
			var tall := rng.randf_range(15,25)
			rock("CanyonCliff",Vector3(x,h+tall*.5-2,z),Vector3(13,tall,12),rocks[rng.randi_range(0,3)],true)
			rock("OuterSpire",Vector3(x+side*10,h+16,z+3),Vector3(16,35,16),rocks[rng.randi_range(0,3)])
			box("SpeedPost",Vector3(55+side*16,h+3,z),Vector3(.4,6,.5),dark)
			box("PostLight",Vector3(55+side*15.8,h+4,z),Vector3(.45,1.3,.55),light)
			for index in range(2):
				rock("GroundDebris",Vector3(55+side*rng.randf_range(16,20),h+.35,z+rng.randf_range(-2,2)),Vector3(1.3,.7,1.5),rocks[index])
	# Arch undersides are 15m above each local road datum; tall chase-camera clearance.
	for z in [-85,-35,30]:
		var h := height_at(z)
		for side in [-1,1]:
			rock("ArchPillar",Vector3(55+side*21,h+9,z),Vector3(9,22,9),rocks[1],true)
		box("RockArch",Vector3(55,h+17,z),Vector3(46,4,7),rocks[0],true)
		for i in range(7):
			rock("ArchCrown",Vector3(34+i*7,h+19,z),Vector3(10,7,9),rocks[i%4])
	var packed := PackedScene.new()
	assert(packed.pack(canyon)==OK)
	assert(ResourceSaver.save(packed,"res://CanyonSlice.tscn")==OK)
	print("Saved canyon slice: z -100 to +75; 3 arches; road clear width 28m")
	canyon.free()
	quit()
