extends Resource

@export var title: String
@export var environment: Environment
@export_file("*.tscn") var scene_path: String
@export var spawn := Transform3D(Basis.IDENTITY, Vector3(55, 0.8, 30))
@export var corners: PackedVector3Array
@export var corner_radius := 28.0
@export var hills: Array[Vector4] = []
@export var canyon_start := -100
@export var canyon_end := 76
@export var arches: PackedFloat32Array
@export var surroundings_center := Vector3(-45, -1, 0)
@export var surroundings_size := Vector3(370, 1, 420)
@export_file("*.tscn") var road_path: String
@export_file("*.tscn") var canyon_path: String
@export_file("*.json") var samples_path: String

func elevation(point: Vector3) -> float:
	for hill in hills:
		if absf(point.x - hill.x) < 1.0 and point.z > hill.y and point.z < hill.z:
			return hill.w * pow(sin(PI * (point.z - hill.y) / (hill.z - hill.y)), 2)
	return 0.0
