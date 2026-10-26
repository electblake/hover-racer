class_name VehicleAbility
extends Resource
## Default diagnostic pulse; game abilities override requirements and execute.
signal activated(vehicle: VehicleController)
@export var energy_cost := 40.0
@export var cooldown := 2.0

func requirements_pass(_vehicle: VehicleController) -> bool:
	return true

func execute(vehicle: VehicleController) -> void:
	activated.emit(vehicle)
