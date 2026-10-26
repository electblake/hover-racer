class_name VehicleController
extends RigidBody3D

signal boost_changed(mode: String)
signal maneuver_changed(active: bool)
signal resources_changed(fuel: float, heat: float, energy: float)
signal damage_taken(amount: float)
signal crashed(reason: String)
signal heat_warning
signal telemetry_changed(data: Dictionary)
signal ability_activated

@export var stats: VehicleStats = VehicleStats.new()
@export var tuning: VehicleTuning = VehicleTuning.new()
@export var ability: VehicleAbility = VehicleAbility.new()
@export var player_controlled := true
var command := VehicleCommand.new()
var derived: Dictionary
var fuel := 100.0
var heat := 0.0
var energy := 0.0
var health := 100.0
var impairment_time := 0.0
var ability_cooldown := 0.0
var time_without_boost := 0.0
var time_without_ramjet := 0.0
var time_since_energy_spent := 0.0
var depletion_latch := false
var warning_armed := true
var is_crashed := false
var crash_reason := ""
var boost_mode := "none"
var maneuver_module := VehicleManeuver.new()
var maneuver_blend: float:
	get: return maneuver_module.blend
var reference_speed := 90.0
var actual_speed := 0.0
var steering := 0.0
var yaw_velocity := 0.0
var throttle_input := 0.0
var brake_input := 0.0
var applied_thrust := 0.0
var road_normal := Vector3.UP
var supported := false
var gameplay_enabled := true
var special_armed := {"afterburner": false, "ramjet": false, "maneuver": false, "ability_primary": false}
var collision_timers := {}
var forces := VehicleForces.new()
var reset_velocity_pending := false
var reset_linear_velocity := Vector3.ZERO
var reset_angular_velocity := Vector3.ZERO
var resume_motion_pending := false
var gated_linear_velocity := Vector3.ZERO
var gated_angular_velocity := Vector3.ZERO
var previous_velocity := Vector3.ZERO
var previous_angular_velocity := Vector3.ZERO

func _ready() -> void:
	collision_layer = 4
	collision_mask = 7
	continuous_cd = true
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 16
	linear_damp_mode = DAMP_MODE_REPLACE
	angular_damp_mode = DAMP_MODE_REPLACE
	linear_damp = 0.0
	angular_damp = 0.0
	physics_material_override = PhysicsMaterial.new()
	physics_material_override.friction = 0.4
	physics_material_override.bounce = 0.0
	respawn(global_transform)

func respawn(placement: Transform3D) -> void:
	reset_velocity_pending = true
	resume_motion_pending = false
	gated_linear_velocity = Vector3.ZERO
	gated_angular_velocity = Vector3.ZERO
	forces = VehicleForces.new()
	global_transform = placement
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	previous_velocity = Vector3.ZERO
	previous_angular_velocity = Vector3.ZERO
	mass = stats.mass_kg
	freeze = not gameplay_enabled
	derived = tuning.derive(stats)
	fuel = tuning.fuel_capacity
	heat = 0.0
	energy = derived.energy_capacity
	health = 100.0
	impairment_time = 0.0
	ability_cooldown = 0.0
	time_without_boost = 0.0
	time_without_ramjet = 0.0
	time_since_energy_spent = 0.0
	depletion_latch = false
	warning_armed = true
	is_crashed = false
	crash_reason = ""
	_set_boost("none")
	var was_active := maneuver_module.active()
	maneuver_module = VehicleManeuver.new()
	if was_active: maneuver_changed.emit(false)
	steering = 0.0
	yaw_velocity = 0.0
	throttle_input = 0.0
	brake_input = 0.0
	applied_thrust = 0.0
	actual_speed = 0.0
	reference_speed = derived.base_speed_mps
	road_normal = Vector3.UP
	supported = false
	collision_timers.clear()
	gate_input(gameplay_enabled)
	reset_physics_interpolation()
	_publish()

func gate_input(enabled: bool) -> void:
	if gameplay_enabled and not enabled:
		gated_linear_velocity = linear_velocity
		gated_angular_velocity = angular_velocity
	elif not gameplay_enabled and enabled and not is_crashed:
		resume_motion_pending = true
	gameplay_enabled = enabled
	freeze = not enabled or is_crashed
	for action in special_armed: special_armed[action] = false
	command = VehicleCommand.new()

func sample_player_command() -> VehicleCommand:
	var sampled := VehicleCommand.new()
	if not gameplay_enabled: return sampled
	sampled.throttle = Input.get_action_strength("throttle")
	sampled.brake = Input.get_action_strength("brake")
	sampled.steering = Input.get_axis("steer_left", "steer_right")
	for action in special_armed:
		if not special_armed[action]:
			if not Input.is_action_pressed(action): special_armed[action] = true
			continue
		sampled.set(action, Input.is_action_pressed(action) and (Input.is_action_just_pressed(action) if action == "ability_primary" else true))
	return sampled

func _physics_process(_delta: float) -> void:
	if reset_velocity_pending:
		reset_linear_velocity = linear_velocity
		reset_angular_velocity = angular_velocity
	if player_controlled: command = sample_player_command()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if is_crashed or not gameplay_enabled: return
	if reset_velocity_pending:
		state.linear_velocity = reset_linear_velocity
		state.angular_velocity = reset_angular_velocity
		reset_velocity_pending = false
	if resume_motion_pending:
		state.linear_velocity = gated_linear_velocity
		state.angular_velocity = gated_angular_velocity
		resume_motion_pending = false
	var delta := state.step
	var input := command
	forces.sample_support(self, state, tuning)
	supported = forces.support_fraction > 0.0
	road_normal = forces.normal
	_process_impacts(state)
	if is_crashed: return
	var ability_request := input.ability_primary
	input.ability_primary = false
	derived = tuning.derive(stats)
	energy = minf(energy, derived.energy_capacity)
	impairment_time = maxf(0.0, impairment_time - delta)
	ability_cooldown = maxf(0.0, ability_cooldown - delta)
	for collider in collision_timers.keys():
		collision_timers[collider] -= delta
		if collision_timers[collider] <= 0.0: collision_timers.erase(collider)
	throttle_input = clampf(input.throttle, 0.0, 1.0)
	brake_input = clampf(input.brake, 0.0, 1.0)
	steering = move_toward(steering, clampf(input.steering, -1.0, 1.0), tuning.steering_smoothing * delta)
	if not input.afterburner: depletion_latch = false
	var drive := linear_velocity.slide(road_normal)
	var speed := drive.length()
	var was_maneuvering := maneuver_module.active()
	maneuver_module.advance(input.maneuver, supported, speed, brake_input > 0.0, delta, derived.maneuver_recovery_s, tuning)
	if was_maneuvering != maneuver_module.active(): maneuver_changed.emit(maneuver_module.active())
	var selected := "none"
	var eligible := throttle_input > 0.0 and supported and brake_input == 0.0 and not maneuver_module.active() and impairment_time == 0.0
	if eligible:
		if input.ramjet: selected = "ramjet"
		elif input.afterburner and not depletion_latch and (fuel > 0.0 if boost_mode == "afterburner" else fuel >= tuning.fuel_reserve): selected = "afterburner"
	_set_boost(selected)
	var spent_fuel := boost_mode == "afterburner"
	var generated_heat := boost_mode == "ramjet"
	var used_boost := spent_fuel or generated_heat
	if spent_fuel:
		fuel = maxf(0.0, fuel - tuning.fuel_consumption * delta)
		if fuel <= 0.000001:
			fuel = 0.0
			depletion_latch = true
			_set_boost("none")
	if generated_heat:
		heat = minf(1.0, heat + tuning.heat_gain * delta)
		if warning_armed and heat >= tuning.heat_warning:
			warning_armed = false
			heat_warning.emit()
		if heat >= 1.0 - 0.000001:
			heat = 1.0
			crash("overheat")
			_publish()
			return
	var bonus := 0.0
	if boost_mode == "afterburner": bonus = derived.afterburner_bonus_mps
	elif boost_mode == "ramjet": bonus = derived.ramjet_bonus_mps
	reference_speed = derived.base_speed_mps + bonus
	forces.fluids(self, state, tuning)
	forces.drive(self, state, tuning, derived, throttle_input, brake_input, steering, maneuver_blend, boost_mode, impairment_time > 0.0)
	applied_thrust = forces.thrust_n / derived.thrust_n
	yaw_velocity = state.angular_velocity.dot(state.transform.basis.y)
	previous_velocity = state.linear_velocity
	previous_angular_velocity = state.angular_velocity
	var spent_energy := ability_request and activate_ability()
	if used_boost: time_without_boost = 0.0
	else:
		fuel = minf(tuning.fuel_capacity, fuel + tuning.fuel_regeneration * _recovery_interval(time_without_boost, tuning.fuel_delay, delta))
		time_without_boost += delta
	if generated_heat: time_without_ramjet = 0.0
	else:
		heat = maxf(0.0, heat - tuning.heat_cooling * _recovery_interval(time_without_ramjet, tuning.heat_delay, delta))
		time_without_ramjet += delta
	if heat < tuning.heat_warning: warning_armed = true
	if not spent_energy:
		energy = minf(derived.energy_capacity, energy + tuning.energy_regeneration * _recovery_interval(time_since_energy_spent, tuning.energy_delay, delta))
		time_since_energy_spent += delta
	actual_speed = linear_velocity.slide(road_normal).length()
	_publish()

func _recovery_interval(timer: float, delay: float, delta: float) -> float:
	return maxf(0.0, timer + delta - delay) - maxf(0.0, timer - delay)

func _set_boost(mode: String) -> void:
	if mode == boost_mode: return
	boost_mode = mode
	boost_changed.emit(mode)

func _process_impacts(state: PhysicsDirectBodyState3D) -> void:
	var impacts := {}
	for index in range(state.get_contact_count()):
		var normal := state.get_contact_local_normal(index)
		var collider := state.get_contact_collider_object(index)
		var other_velocity := state.get_contact_collider_velocity_at_position(index)
		if collider is StaticBody3D:
			other_velocity = collider.constant_linear_velocity + collider.constant_angular_velocity.cross(state.get_contact_collider_position(index) - collider.global_position)
		var relative := previous_velocity + previous_angular_velocity.cross(state.get_contact_local_position(index) - state.transform.origin) - other_velocity
		var impact := maxf(0.0, -relative.dot(normal))
		var id := state.get_contact_collider_id(index)
		if normal.dot(Vector3.UP) > cos(deg_to_rad(tuning.floor_angle_degrees)) and impact < tuning.impact_damage_threshold: continue
		impacts[id] = maxf(impacts.get(id, 0.0), impact)
	for id in impacts:
		if collision_timers.has(id) or impacts[id] <= tuning.impact_damage_threshold: continue
		collision_timers[id] = tuning.impact_repeat_interval
		apply_damage(tuning.impact_damage_coefficient * pow(impacts[id] - tuning.impact_damage_threshold, 2))
		if is_crashed: return
		if impacts[id] >= derived.impairment_threshold_mps: apply_impairment(tuning.impairment_duration)

func apply_damage(raw_damage: float) -> void:
	if is_crashed: return
	var amount: float = raw_damage * derived.damage_multiplier
	health = maxf(0.0, health - amount)
	damage_taken.emit(amount)
	if health == 0.0: crash("health depleted")

func apply_impairment(base_duration: float) -> void:
	if is_crashed: return
	impairment_time = maxf(impairment_time, base_duration * derived.negative_duration_multiplier)

func activate_ability() -> bool:
	if get_tree().paused or not gameplay_enabled or is_crashed or impairment_time > 0.0 or ability_cooldown > 0.0 or energy < ability.energy_cost or not ability.requirements_pass(self): return false
	energy -= ability.energy_cost
	ability_cooldown = ability.cooldown
	time_since_energy_spent = 0.0
	ability.execute(self)
	ability_activated.emit()
	return true

func crash(reason: String) -> void:
	if is_crashed: return
	is_crashed = true
	crash_reason = reason
	reference_speed = derived.base_speed_mps
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true
	actual_speed = 0.0
	applied_thrust = 0.0
	yaw_velocity = 0.0
	_set_boost("none")
	var was_active := maneuver_module.active()
	maneuver_module = VehicleManeuver.new()
	if was_active: maneuver_changed.emit(false)
	crashed.emit(reason)

func telemetry() -> Dictionary:
	return {"speed": actual_speed, "reference_speed": reference_speed, "boost": boost_mode,
		"maneuver_active": maneuver_module.active(), "maneuver_blend": maneuver_blend,
		"fuel": fuel, "heat": heat, "energy": energy, "capacity": derived.energy_capacity,
		"health": health, "impairment_time": impairment_time, "cooldown": ability_cooldown,
		"mass_kg": mass, "thrust_n": forces.thrust_n, "lift_n": forces.lift_n,
		"drag_n": forces.drag_n, "buoyancy_n": forces.buoyancy_n, "immersion": forces.immersion,
		"medium": forces.medium_label, "lateral_n": forces.lateral_n, "brake_n": forces.brake_n,
		"grounded": supported, "crashed": is_crashed, "crash_reason": crash_reason}

func _publish() -> void:
	resources_changed.emit(fuel, heat, energy)
	telemetry_changed.emit(telemetry())
