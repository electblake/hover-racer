# Rebuild the saved static course: Godot --headless --path . --script res://tools/build_course.gd
extends SceneTree

const WIDTH := 28.0
const RADIUS := 28.0
var points: Array[Vector3] = []
var root_track: Node3D
var road_vertices := PackedVector3Array()
var road_normals := PackedVector3Array()
var samples: Array = []

func _initialize() -> void:
	call_deferred("build")

func elevation(point: Vector3) -> float:
	if point.x > 30.0 and point.z > -110.0 and point.z < -10.0:
		return 10.0 * pow(sin(PI * (point.z + 110.0) / 100.0), 2)
	if point.x < -120.0 and point.z > -30.0 and point.z < 110.0:
		return 14.0 * pow(sin(PI * (point.z + 30.0) / 140.0), 2)
	return 0.0

func material(color: Color, glow := false) -> StandardMaterial3D:
	var result := StandardMaterial3D.new()
	result.albedo_color = color
	result.roughness = 0.85
	if glow:
		result.emission_enabled = true
		result.emission = color * 0.35
	return result

func own(node: Node, parent: Node = null) -> void:
	if parent == null:
		parent = root_track
	parent.add_child(node)
	node.owner = root_track

func box(name_: String, position_: Vector3, size_: Vector3, mat: Material, rotation_: Basis = Basis.IDENTITY) -> void:
	var node := MeshInstance3D.new()
	node.name = name_
	var mesh := BoxMesh.new()
	mesh.size = size_
	node.mesh = mesh
	node.material_override = mat
	own(node)
	node.transform = Transform3D(rotation_, position_)

func append_line(a: Vector3, b: Vector3) -> void:
	var count := ceili(a.distance_to(b) / 2.0)
	for i in range(count):
		points.append(a.lerp(b, float(i) / count))

func build() -> void:
	root_track = Node3D.new()
	root_track.name = "TestTrack"
	root_track.set_script(load("res://test_track.gd"))
	var corners: Array[Vector3] = [Vector3(55,0,140), Vector3(55,0,-150), Vector3(-45,0,-150), Vector3(-45,0,-75), Vector3(-150,0,-75), Vector3(-150,0,140)]
	var entries: Array[Vector3] = []
	var exits: Array[Vector3] = []
	for i in range(corners.size()):
		var v := corners[i]
		entries.append(v + (corners[(i - 1 + corners.size()) % corners.size()] - v).normalized() * RADIUS)
		exits.append(v + (corners[(i + 1) % corners.size()] - v).normalized() * RADIUS)
	for i in range(corners.size()):
		var center := entries[i] + exits[i] - corners[i]
		var from := entries[i] - center
		var to := exits[i] - center
		var angle := from.signed_angle_to(to, Vector3.UP)
		for step in range(40):
			points.append(center + from.rotated(Vector3.UP, angle * step / 40.0))
		append_line(exits[i], entries[(i + 1) % corners.size()])
	var road_mat := material(Color(0.10,0.15,0.21))
	var wall_mat := material(Color(0.17,0.55,0.67))
	var stripe_mat := material(Color(0.65,0.94,1), true)
	var yellow := material(Color(1,0.68,0.12), true)
	var white := material(Color(0.95,0.98,1))
	var black := material(Color(0.02,0.03,0.04))
	var left: Array[Vector3] = []
	var right: Array[Vector3] = []
	for i in range(points.size()):
		var direction := (points[(i+1)%points.size()] - points[(i-1+points.size())%points.size()]).normalized()
		var normal := Vector3(-direction.z,0,direction.x)
		var center := points[i]
		center.y = elevation(center) + 0.5
		left.append(center + normal * WIDTH * 0.5)
		right.append(center - normal * WIDTH * 0.5)
		samples.append({"point": [center.x,center.y,center.z], "normal": [normal.x,normal.y,normal.z]})
	var wall_triangles := PackedVector3Array()
	var length := 0.0
	for i in range(points.size()):
		var j := (i+1)%points.size()
		for tri in [[left[i],right[i],left[j]], [right[i],right[j],left[j]]]:
			# Match Godot's clockwise front-face winding; road normals point up.
			var normal: Vector3 = (tri[2]-tri[0]).cross(tri[1]-tri[0]).normalized()
			for vertex in tri:
				road_vertices.append(vertex)
				road_normals.append(normal)
		for edge in [left,right]:
			var a: Vector3 = edge[i]
			var b: Vector3 = edge[j]
			var direction := (b-a).normalized()
			var side := Vector3.UP.cross(direction).normalized()
			var basis := Basis(side, direction.cross(side).normalized(), direction)
			box("Barrier_%d_%d" % [i, 0 if edge == left else 1], (a+b)*0.5+Vector3.UP*1.5, Vector3(1.4,3,a.distance_to(b)+0.12),wall_mat,basis)
			# Vertical collision face follows the road continuously, including hills.
			wall_triangles.append_array(PackedVector3Array([a,b,a+Vector3.UP*3,b,b+Vector3.UP*3,a+Vector3.UP*3]))
		length += points[i].distance_to(points[j])
		if i%5 == 0:
			var a := (left[i]+left[j])*0.5
			var b := (right[i]+right[j])*0.5
			var direction := (points[j]-points[i]).normalized()
			var basis := Basis(Vector3(-direction.z,0,direction.x),Vector3.UP,direction)
			for edge in [a,b]:
				box("EdgeMarker", edge.lerp((a+b)*0.5,0.10)+Vector3.UP*0.035,Vector3(0.55,0.05,2),stripe_mat,basis)
			box("CenterDash",(a+b)*0.5+Vector3.UP*0.035,Vector3(0.22,0.05,2),yellow,basis)
	var surface := MeshInstance3D.new()
	surface.name = "RoadSurface"
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = road_vertices
	arrays[Mesh.ARRAY_NORMAL] = road_normals
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	surface.mesh = mesh
	surface.material_override = road_mat
	own(surface)
	for data in [["RoadCollision",road_vertices,1], ["BarrierCollision",wall_triangles,2]]:
		var body := StaticBody3D.new()
		body.name = data[0]
		body.collision_layer = data[2]
		own(body)
		var collider := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.backface_collision = true
		shape.set_faces(data[1])
		collider.shape = shape
		own(collider,body)
	box("Surroundings",Vector3(-45,-1,0),Vector3(370,1,420),material(Color(0.035,0.055,0.08)))
	for row in range(2):
		for col in range(14):
			box("StartFinish",Vector3(42+col*2,0.54,20+row*2),Vector3(2,0.05,2),white if (row+col)%2 else black)
	for x in [38,72]:
		box("StartPylon",Vector3(x,4,20),Vector3(2,8,2),yellow)
	# Distance bars before the north hairpin sequence.
	for z in [-105,-115,-125]:
		box("BrakeMarker",Vector3(55,elevation(Vector3(55,0,z))+0.56,z),Vector3(6,0.05,0.5),yellow)
	var packed := PackedScene.new()
	assert(packed.pack(root_track) == OK)
	assert(ResourceSaver.save(packed,"res://TestTrack.tscn") == OK)
	var file := FileAccess.open("res://tools/course_samples.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(samples))
	print("Saved course: %d samples, %.0f metre lap, two hills (10m / 14m)" % [points.size(),length])
	root_track.free()
	quit()
