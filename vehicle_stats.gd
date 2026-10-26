class_name VehicleStats
extends Resource

@export_range(0.0, 100.0, 1.0) var speed: float = 50.0
@export_range(0.0, 100.0, 1.0) var afterburner: float = 50.0
@export_range(0.0, 100.0, 1.0) var cornering: float = 50.0
@export_range(0.0, 100.0, 1.0) var maneuvering: float = 50.0
@export_range(0.0, 100.0, 1.0) var ramjet: float = 50.0
@export_range(0.0, 100.0, 1.0) var resilience: float = 50.0
@export_range(0.0, 100.0, 1.0) var battery: float = 50.0

@export var mass_kg := 600.0
@export var displacement_m3 := 1.2
@export var requires_support := true
