class_name VehicleForces
extends RefCounted

const PADS := [Vector3(-1.1, 0, -1.8), Vector3(1.1, 0, -1.8), Vector3(-1.1, 0, 1.8), Vector3(1.1, 0, 1.8)]
var support_fraction := 0.0
var lateral_coupling := 0.0
var lift_n := 0.0
var thrust_n := 0.0
var brake_n := 0.0
var lateral_n := 0.0
var torque_nm := 0.0
var buoyancy_n := 0.0
var drag_n := 0.0
var drag_force := Vector3.ZERO
var immersion := 0.0
var medium_label := "Air"
var normal := Vector3.UP

func sample_support(body: RigidBody3D, state: PhysicsDirectBodyState3D, tuning: VehicleTuning) -> void:
	support_fraction = 0.0
	lateral_coupling = 0.0
	lift_n = 0.0
	var normals := Vector3.ZERO
	var regions := body.get_tree().get_nodes_in_group("fluid_regions")
	regions.sort_custom(func(a, b): return a.medium_priority > b.medium_priority)
	var up := state.transform.basis.y
	for pad in PADS:
		var offset: Vector3 = state.transform.basis * pad
		var start := state.transform.origin + offset
		var end := start - up * tuning.hover_reach_m
		var hit := state.get_space_state().intersect_ray(PhysicsRayQueryParameters3D.create(start, end, 1, [body.get_rid()]))
		var distance := tuning.hover_reach_m
		var surface: TrackSurface
		var hit_normal := Vector3.UP
		if not hit.is_empty() and hit.normal.dot(Vector3.UP) >= cos(deg_to_rad(tuning.floor_angle_degrees)):
			distance = start.distance_to(hit.position)
			surface = hit.collider.surface
			hit_normal = hit.normal
		for region: FluidRegion3D in regions:
			if not region.medium.liquid or up.y <= 0.0: continue
			var depth := (start.y - region.surface_height()) / up.y
			if depth >= -tuning.hover_reach_m and depth < distance and region.contains_horizontal(start - up * depth):
				distance = depth
				surface = region.surface
				hit_normal = Vector3.UP
		if surface == null: continue # A real gap provides neither lift nor attraction.
		var point_speed := state.get_velocity_at_local_position(offset).dot(hit_normal) / hit_normal.dot(up)
		var force := clampf(tuning.hover_trim_n + tuning.hover_spring_n_m * (tuning.hover_height_m - distance) - tuning.hover_damping_ns_m * point_speed, -tuning.hover_attraction_n * surface.lift_coupling, tuning.hover_max_n * surface.lift_coupling)
		state.apply_force(up * force, offset)
		lift_n += force
		support_fraction += 0.25
		lateral_coupling += surface.lateral_coupling * 0.25
		normals += hit_normal
	normal = normals.normalized() if support_fraction > 0.0 else Vector3.UP
	# Finite attitude actuator tracks the support normal; it never overwrites rotation.
	if support_fraction > 0.0:
		var tilt_velocity := state.angular_velocity - normal * state.angular_velocity.dot(normal)
		var tilt_torque := up.cross(normal) * tuning.attitude_stiffness_nm - tilt_velocity * tuning.attitude_damping_nms
		state.apply_torque(tilt_torque.limit_length(tuning.attitude_max_nm) * support_fraction)

func drive(body: RigidBody3D, state: PhysicsDirectBodyState3D, tuning: VehicleTuning, derived: Dictionary, throttle: float, brake: float, steering: float, maneuver: float, boost: String, impaired: bool) -> void:
	var basis := state.transform.basis
	var forward := -basis.z
	var right := basis.x
	var speed := state.linear_velocity.slide(normal).length()
	var output: float = derived.thrust_n
	var reference: float = derived.base_speed_mps
	if boost == "afterburner":
		output = derived.afterburner_thrust_n
		reference += derived.afterburner_bonus_mps
	elif boost == "ramjet":
		output = derived.ramjet_thrust_n
		reference += derived.ramjet_bonus_mps
	var air_k := 0.5 * tuning.atmosphere.density_kg_m3 * tuning.drag_area_cd.z
	var forward_speed := maxf(0.0, state.linear_velocity.dot(forward))
	var no_load_squared: float = reference * reference / (1.0 - air_k * reference * reference / output)
	thrust_n = output * clampf(1.0 - forward_speed * forward_speed / no_load_squared, 0.0, 1.0) * throttle
	if impaired: thrust_n *= tuning.impairment_factor
	if brake > 0.0 or (support_fraction == 0.0 and body.stats.requires_support): thrust_n = 0.0
	state.apply_central_force(forward * thrust_n)
	var grip := lerpf(1.0, tuning.maneuver_grip_multiplier, maneuver)
	# Spend only the momentum left after fluid resistance this tick.
	var resisted_velocity := state.linear_velocity + drag_force * state.step / body.mass
	var side_speed := resisted_velocity.dot(right)
	var capacity: float = derived.lateral_force_n * lateral_coupling * grip
	lateral_n = clampf(-side_speed * derived.lateral_damping_ns_m * grip, -capacity, capacity)
	var tangent := resisted_velocity.slide(normal)
	var requested_brake: float = (derived.brake_force_n * brake + tuning.maneuver_brake_n * maneuver) * lateral_coupling
	brake_n = minf(requested_brake, body.mass * tangent.length() / state.step)
	var remaining_side_speed := side_speed * (1.0 - brake_n * state.step / (body.mass * tangent.length())) if tangent.length() > 0.0 else 0.0
	lateral_n = clampf(lateral_n, -absf(remaining_side_speed) * body.mass / state.step, absf(remaining_side_speed) * body.mass / state.step)
	state.apply_central_force(right * lateral_n - tangent.normalized() * brake_n)
	var authority := lerpf(0.25, 1.0, clampf(speed / tuning.low_speed_authority, 0.0, 1.0)) * lerpf(1.0, tuning.high_speed_yaw_factor, clampf(speed / tuning.high_speed_authority, 0.0, 1.0))
	if impaired: authority *= tuning.impairment_factor
	if support_fraction == 0.0: authority *= tuning.air_yaw_factor
	var capacity_nm: float = derived.yaw_torque_nm * lerpf(1.0, derived.maneuver_yaw_multiplier, maneuver)
	var yaw_rate := state.angular_velocity.dot(basis.y)
	torque_nm = clampf(-steering * capacity_nm * authority - yaw_rate * tuning.yaw_damping_nms, -capacity_nm, capacity_nm)
	state.apply_torque(basis.y * torque_nm)

func fluids(body: RigidBody3D, state: PhysicsDirectBodyState3D, tuning: VehicleTuning) -> void:
	drag_n = 0.0
	drag_force = Vector3.ZERO
	buoyancy_n = 0.0
	immersion = 0.0
	medium_label = tuning.atmosphere.label
	var regions := body.get_tree().get_nodes_in_group("fluid_regions")
	regions.sort_custom(func(a, b): return a.medium_priority > b.medium_priority)
	var basis := state.transform.basis
	# Eight hull cells cover a sealed 2 x 0.4 x 1.5 m volume, independent of collider volume.
	var height := absf(basis.x.y) + absf(basis.y.y) * 0.2 + absf(basis.z.y) * 0.75
	for x in [-0.5, 0.5]:
		for y in [-0.1, 0.1]:
			for z in [-0.375, 0.375]:
				var offset := basis * Vector3(x, y, z)
				var point := state.transform.origin + offset
				var intervals: Array[Vector2] = [Vector2(point.y - height * 0.5, point.y + height * 0.5)]
				for region: FluidRegion3D in regions:
					if not region.contains_horizontal(point): continue
					var uncovered: Array[Vector2] = []
					for interval in intervals:
						var lower := maxf(interval.x, region.global_position.y - region.size_m.y * 0.5)
						var upper := minf(interval.y, region.surface_height())
						if lower >= upper:
							uncovered.append(interval)
							continue
						var fraction := (upper - lower) / height
						var centroid := Vector3(offset.x, (upper + lower) * 0.5 - state.transform.origin.y, offset.z)
						_apply_medium(body, state, tuning, region.medium, region.flow_velocity, offset, centroid, fraction)
						if region.medium.liquid: immersion += fraction / 8.0
						medium_label = region.medium.label
						if interval.x < lower: uncovered.append(Vector2(interval.x, lower))
						if upper < interval.y: uncovered.append(Vector2(upper, interval.y))
					intervals = uncovered
				for interval in intervals:
					var centroid := Vector3(offset.x, (interval.x + interval.y) * 0.5 - state.transform.origin.y, offset.z)
					_apply_medium(body, state, tuning, tuning.atmosphere, tuning.wind_velocity, offset, centroid, (interval.y - interval.x) / height)

func _apply_medium(body: RigidBody3D, state: PhysicsDirectBodyState3D, tuning: VehicleTuning, medium: FluidMedium, flow: Vector3, offset: Vector3, centroid: Vector3, fraction: float) -> void:
	var basis := state.transform.basis
	var relative := basis.transposed() * (state.get_velocity_at_local_position(offset) - flow)
	var area := tuning.liquid_drag_area_cd if medium.liquid else tuning.drag_area_cd
	var coefficient := area * (0.5 * medium.density_kg_m3 * fraction / 8.0)
	# Backward-Euler quadratic resistance: finite drag impulse without velocity reversal.
	# This is a specified numerical discretization, not an arbitrary force cap.
	var sample_mass := body.mass / 8.0
	var damping := coefficient * relative.abs() * (state.step / sample_mass)
	var linear_term := Vector3.ONE + area * (medium.linear_resistance_per_area * fraction * state.step / (8.0 * sample_mass))
	var next_relative := Vector3(
		2.0 * relative.x / (linear_term.x + sqrt(linear_term.x * linear_term.x + 4.0 * damping.x)),
		2.0 * relative.y / (linear_term.y + sqrt(linear_term.y * linear_term.y + 4.0 * damping.y)),
		2.0 * relative.z / (linear_term.z + sqrt(linear_term.z * linear_term.z + 4.0 * damping.z)))
	var drag := basis * ((next_relative - relative) * sample_mass / state.step)
	var buoyancy: Vector3 = -state.total_gravity * medium.density_kg_m3 * body.stats.displacement_m3 * fraction / 8.0
	state.apply_force(drag, offset)
	state.apply_force(buoyancy, centroid)
	drag_n += drag.length()
	drag_force += drag
	buoyancy_n += buoyancy.length()
