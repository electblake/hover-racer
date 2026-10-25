extends CharacterBody3D

@export var max_speed: float = 40.0
@export var acceleration: float = 50.0
@export var braking: float = 20.0
@export var turn_speed: float = 1.8
@export var thrust_grip: float = 5.0

# Left stick makes course corrections; right stick keeps the original yaw rate.
@export var gentle_turn_speed: float = 0.65
@export var bank_degrees: float = 22.0
@export var hover_amplitude: float = 0.10

@onready var visual: MeshInstance3D = $MeshInstance3D
var visual_rest_position: Vector3
var visual_rest_rotation: Vector3
var hover_time := 0.0

func _ready() -> void:
	visual_rest_position = visual.position
	visual_rest_rotation = visual.rotation

func reset_visuals() -> void:
	hover_time = 0.0
	visual.position = visual_rest_position
	visual.rotation = visual_rest_rotation

func _physics_process(delta: float) -> void:
	var throttle := Input.get_action_strength("thrust")
	var brake := Input.get_action_strength("brake")
	var steering := Input.get_axis("steer_right", "steer_left")
	var gentle_steering := Input.get_axis("gentle_right", "gentle_left")

	# Rotation is independent of our movement direction.
	var yaw_rate := clampf(steering * turn_speed + gentle_steering * gentle_turn_speed, -turn_speed, turn_speed)
	rotate_y(yaw_rate * delta)

	if throttle > 0.0:
		var speed := velocity.length()
		speed = move_toward(
			speed, max_speed, acceleration * throttle * delta
		)

		var forward := -global_transform.basis.z
		var direction := forward

		if velocity.length_squared() > 0.001:
			var current_direction := velocity.normalized()
			var angle := current_direction.signed_angle_to(
				forward, Vector3.UP
			)
			var grip := 1.0 - exp(-thrust_grip * throttle * delta)
			direction = current_direction.rotated(
				Vector3.UP, angle * grip
			)

		velocity = direction * speed

	if brake > 0.0:
		velocity = velocity.move_toward(
			Vector3.ZERO, braking * brake * delta
		)

	move_and_slide()

	# Cosmetic hover and banking stay local to the mesh, never the camera or body.
	hover_time += delta
	var movement := clampf(velocity.length() / maxf(max_speed, 0.01), 0.0, 1.0)
	var smoothing := 1.0 - exp(-8.0 * delta)
	visual.rotation.z = lerp_angle(visual.rotation.z, visual_rest_rotation.z + gentle_steering * deg_to_rad(bank_degrees), smoothing)
	visual.position = visual_rest_position + Vector3.UP * sin(hover_time * 3.2) * hover_amplitude * (0.3 + 0.7 * movement)
