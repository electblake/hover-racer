class_name FluidRegion3D
extends Area3D
## Axis-aligned fluid box; its top is the liquid free surface.
@export var medium: FluidMedium
@export var surface: TrackSurface = preload("res://surfaces/water_surface.tres")
@export var size_m := Vector3(50, 10, 100)
@export var flow_velocity := Vector3.ZERO
@export var medium_priority := 1

func _ready() -> void:
	add_to_group("fluid_regions")
	collision_layer = 8
	collision_mask = 4
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size_m
	shape.shape = box
	add_child(shape)

func contains_horizontal(point: Vector3) -> bool:
	var relative := point - global_position
	return absf(relative.x) <= size_m.x * 0.5 and absf(relative.z) <= size_m.z * 0.5

func surface_height() -> float:
	return global_position.y + size_m.y * 0.5

func occupied_fraction(point: Vector3, height: float) -> float:
	if not contains_horizontal(point): return 0.0
	var bottom := maxf(point.y - height * 0.5, global_position.y - size_m.y * 0.5)
	var top := minf(point.y + height * 0.5, surface_height())
	return clampf((top - bottom) / height, 0.0, 1.0)
