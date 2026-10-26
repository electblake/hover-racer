class_name TrackSurface3D
extends StaticBody3D

@export var surface: TrackSurface = preload("res://surfaces/road.tres")

func _ready() -> void:
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = surface.friction
	physics_material_override.bounce = surface.bounce
	physics_material_override.rough = true
