extends "res://tests/support/game_test.gd"
var vehicle: VehicleController
var floor_body: StaticBody3D

func frames(count: int) -> void:
	for frame in range(count): await get_tree().physics_frame

func before_each() -> void:
	super.before_each()
	floor_body = TrackSurface3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(10000, 1, 10000)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -0.5
	add_child_autofree(floor_body)
	vehicle = make_vehicle()
	await frames(10)

func make_vehicle() -> VehicleController:
	var body := VehicleController.new()
	body.player_controlled = false
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.1, 0.4, 4.6)
	collider.shape = box
	body.add_child(collider)
	body.position = Vector3(0, 0.8, 0)
	add_child_autofree(body)
	return body

func after_each() -> void:
	super.after_each()
	Engine.max_fps = 0
	Engine.physics_ticks_per_second = 60
