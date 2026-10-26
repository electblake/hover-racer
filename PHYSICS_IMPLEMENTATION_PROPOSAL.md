# Vehicle and environment physics implementation proposal

Status: **Implemented after explicit user authorization. Section 14 records the accepted changes; VEHICLE_SPEC.md is the current runtime contract.**

Prepared: 2026-10-25. Project: Hover Racer. Units: SI.

This document preserves the research-stage proposal for comparison. Sections 1–13 describe the original proposed defaults, not all of the final tuning. Section 14 and [VEHICLE_SPEC.md](VEHICLE_SPEC.md) supersede conflicting earlier defaults. The user subsequently authorized full implementation.

## 1. Outcome and scope

Replace authored velocity and heading changes with a `RigidBody3D` vehicle. Let the existing Jolt backend integrate forces, torque, gravity, and collision response. Model the environment through solid contact materials and sampled fluid forces. Keep existing input, resource consumption, ability, and menu systems wherever their contracts do not conflict with physical movement.

The initial implementation includes:

- Mass, momentum, rotational inertia, finite engine thrust, steering torque, and braking forces.
- Four powered hover supports over authored solid or liquid surfaces.
- Solid collision friction and restitution.
- Density-based fluid drag, buoyancy, wind, and water currents.
- Partial immersion using eight vehicle sample volumes.
- Flat liquid surfaces and explicitly authored atmosphere/region data.
- A dedicated physics test course and quantitative acceptance tests.

It does not include a fluid solver, deformable terrain, hull flooding, splashes exerting forces, compressible flow, chemical elements, temperature-driven phase changes, or full hydrodynamic planing. Solid/liquid/gas are material states; different materials within those states have different parameters. Future wave rendering must use the same surface description as physics.

The hover mechanism is fictional. Its force capacity and material coupling are explicit game rules. Newtonian motion, drag, and buoyancy provide the physical consequences of those rules.

## 2. Current project and specification migration

Inspection during the proposal discussion found:

| File | Current role or behaviour | Proposed change |
| --- | --- | --- |
| `project.godot` | Targets 4.7 and explicitly selects Jolt Physics; no explicit physics tick override | Retain Jolt; explicitly select 60 physics ticks/s for the initial baseline |
| `Main.tscn` | `SHIP` is a `CharacterBody3D`; centred box collider is 3.1 x 0.4 x 4.6 m | Convert `SHIP` to `RigidBody3D`; retain initial collider dimensions |
| `vehicle_controller.gd` | Sets speed, rotates yaw, transports/aligns velocity, calls `move_and_slide()` | Replace movement section with force submission and rigid-body contacts |
| `ship.gd` | Mesh offset, cosmetic banking/bobbing, camera/audio presentation | Align visual hull with physical hull; read simulated motion for presentation |
| `vehicle_stats.gd`, `vehicle_tuning.gd` | Seven ratings and derived kinematic values | Keep ratings; derive forces and torque instead of guaranteed accelerations/speed caps |
| `vehicle_maneuver.gd` | Drift engagement and recovery | Retain lifecycle; change its physical effects |
| `test_track.gd`, `vehicle_sandbox.gd`, `vehicle_ability.gd` | References typed as `CharacterBody3D` | Use the new `VehicleController` type and physical telemetry |
| Tests | Include CharacterBody properties, exact authored speeds/rates, and resource/timing contracts | Migrate movement assertions; preserve resource/input regression coverage |

The installed CLI reported `4.7.2.stable.official.ed1daf0bf`. The local physics reference snapshot is dated 2026-10-25 and identifies Godot 4.7 documentation. These are separate observations; the snapshot does not establish the binary version.

`VEHICLE_SPEC.md` remains the current specification until an implementation is approved. This proposal would supersede its body type, floor snapping, speed ceilings, velocity alignment, fixed acceleration/deceleration, and airborne propulsion rules. Preserve its fuel, heat, energy, cooldown, precedence, input rearming, and resource-preserving live rating changes unless explicitly changed below.

Do not keep a second kinematic controller, compatibility properties, or fallback movement path. Preserve the user's fail-fast policy: missing required resources and unsupported configurations fail naturally; no catches, retries, silent substitution, or custom error paths. Physical conditions such as no ray hit, zero immersion, and actuator saturation are normal simulation branches.

## 3. Units and governing quantities

One world unit represents one metre. Forward is local -Z; up is +Y. Store mass in kg, force in N, torque in N m, velocity in m/s, angular velocity in rad/s, inertia in kg m^2, density in kg/m^3, and volume in m^3.

```text
weight = mass * gravity
linear momentum = mass * velocity
linear acceleration = net force / mass
torque from an offset force = lever arm cross force
principal-axis angular acceleration = torque / moment of inertia
kinetic energy = 0.5 * mass * speed^2
```

Jolt handles full rigid-body rotation; do not implement general 3D rotation using the scalar principal-axis equation above.

For a 600 kg reference vehicle at gravity 9.8 m/s^2:

- Weight is 5,880 N.
- Momentum at 90 m/s is 54,000 kg m/s.
- Kinetic energy at 90 m/s is 2.43 MJ.
- A 9,000 N engine produces 15 m/s^2 before resistance.
- The existing uniform box approximation has yaw inertia `600 * (3.1^2 + 4.6^2) / 12 = 1538.5 kg m^2`.
- A 5,000 N m yaw torque initially produces approximately 3.25 rad/s^2 about that axis.

Keep engine and steering capacity independent of the current mass. Doubling mass with the same engine halves initial acceleration. Do not multiply every force by current mass to maintain an authored acceleration. The box is an initial mass-distribution approximation; a later compound pod/chassis model must be calibrated independently.

## 4. Godot integration contract

Use `RigidBody3D` with `custom_integrator = false`, `gravity_scale = 1`, unlocked rotation, automatically computed inertia, continuous collision detection, and an explicit low-bounce contact material. Set linear and angular damping to zero with replacement damping mode because resistance is modelled explicitly. Disable sleeping for the actively controlled vehicle.

Submit forces once per simulation tick through `_integrate_forces(state)`. Do not multiply force arguments by delta. Reserve impulses for discrete events; do not express continuous propulsion as a per-frame impulse. Retain normal gravity integration and do not add gravity a second time.

`apply_force(force, position)` takes a world-oriented offset from the body origin, not an absolute world position. The same offset convention applies to `get_velocity_at_local_position()`. Point velocity includes rotation, which matters for hover damping and one-sided water entry.

Use `state.get_space_state()` for queries made during the integration callback. Query endpoints are world coordinates. Explicitly configure masks, body/area query flags, and self-exclusion. Keep these operations on the physics path; do not query from render callbacks. Confirm callback/query behaviour with a focused runtime test before building the full controller.

Use an explicit body mask for solid collisions and a separate mask for fluid volumes. Liquids have no rigid collision plane at their free surface. Their riverbed and banks remain ordinary solid colliders.

Enable contact reporting with an initial `max_contacts_reported = 16`; use contact monitoring where collision signals are needed. Test this budget against actual wall/ground contact cases rather than assuming it is sufficient for every future vehicle.

## 5. Data and scene ownership

Keep existing Resource patterns. Add only the data required for this model:

| Component | Fields / responsibility |
| --- | --- |
| `VehicleStats` | Existing seven ratings; add physical mass and propulsion capability fields for vehicle presets |
| `VehicleTuning` | Force/torque ranges, hover support constants, drag coefficients/areas, sample layout, drift modifiers |
| `TrackSurface` Resource | `PhysicsMaterial`, dimensionless hover lift coupling and lateral coupling |
| `TrackSurface3D` script on static track bodies | Required reference to the surface Resource; collision geometry remains on the body |
| `FluidMedium` Resource | Density in kg/m^3; material identity |
| `FluidRegion3D` script on `Area3D` | Medium, flow vector in m/s, explicit priority, bounds; liquid regions also provide surface height and normal |
| Explicit world atmosphere | Required ambient gas medium and flow, authored in the test/main scene |
| Eight vehicle samples | Local centre, sample dimensions, sealed displacement volume, directional drag areas and coefficients |

Ambient atmosphere is a required environment input, not a fallback for missing regional data. Flow belongs to the region: two rivers may share a water Resource but have different currents. Runtime state stays on each vehicle; shared preset Resources remain immutable.

Regions use explicit precedence: at a sample position select the highest-priority authored regional medium, otherwise the explicitly configured atmosphere applies. Author overlapping regions with distinct priorities. A liquid's occupied fraction replaces the corresponding gas fraction; never apply full air and water forces to the same fraction. Solid support sampling and surrounding-medium sampling are independent.

Friction belongs to the contact pair. Fluid resistance depends on both medium and vehicle geometry. Do not store one universal material "grip" value for all three states.

## 6. Hover support

Four support points at local `(+-1.1, 0, +-1.8)` m cast along body down. Start with a 2 m probe reach and a 1.2 m target distance. Choose the nearest eligible authored support surface, including a liquid surface intersection when present. Solid surfaces behind the liquid surface must not also supply lift to the same support.

Use a 50-degree maximum surface slope relative to gravity-up for this first course. A probe that misses or sees an ineligible surface contributes no lift. A tilted vehicle may lose support; do not teleport or rotate it upright.

Per support:

```text
raw_lift = trim_N + stiffness_N_per_m * (target_height - height)
           - damping_Ns_per_m * relative_point_speed_along_body_up
lift = clamp(raw_lift, 0, maximum_lift_N * surface_lift_coupling)
force = body_up * lift
```

Initial per-support values: trim 1,470 N; stiffness 6,000 N/m; damping 1,500 N s/m; maximum 6,000 N. Trim is authored for the reference craft, not recalculated every frame to cancel arbitrary payload. Additional mass causes sag and can exhaust available lift. On slopes, the body-up force needs enough capacity to support the vertical weight component.

Apply force at the support position. Different corner forces naturally create pitch and roll. For stationary flat surfaces, support point speed is the body's point velocity. A future moving liquid surface must supply its vertical surface velocity for relative damping. The initial liquid plane is stationary even when horizontal flow is present.

Hover lift is powered support; buoyancy comes from displaced fluid. They can coexist but must be reported separately. A hull fully above water has zero liquid buoyancy and liquid drag.

## 7. Propulsion, cornering, braking, and drift

### Propulsion and speed

Apply forward thrust at the centre of mass initially. Use explicit force capacity selected by the ordinary/afterburner/ramjet state, multiplied by throttle and the existing impairment factor. Braking cancels propulsion and boosts as today. Throttle is proportional force: partial throttle no longer guarantees reaching the full-throttle terminal speed.

Start with full-throttle forces of 9,000 N ordinary, 13,500 N afterburner, and 21,000 N ramjet at ratings 50. These are total selected outputs, not additive impulses.

There is no hard speed cap or forced excess-speed deceleration. Terminal speed emerges from force balance. Replace HUD "ceiling" with a labelled reference-condition equilibrium estimate; actual speed can exceed it downhill, in a current, or after an impact.

For level air travel, total `0.5 * density * Cd * frontal_area = 1.1 kg/m` gives approximately 90.5, 110.8, and 138.2 m/s for the three forces. This is calibration of the complete craft's drag, not a separate resistance added on top of its sample drag.

At 90 m/s this drag produces about 14.85 m/s^2 deceleration for 600 kg, unlike the current 4 m/s^2 coast setting. This proposal selects constant thrust and quadratic drag as the first baseline. If review requires long coasting with the same top speed, revise the propulsion design to a documented thrust-vs-speed curve before implementation; do not silently introduce a speed clamp.

### Steering and lateral force

Apply steering torque about body up. Initial requested yaw torque is:

```text
clamp(-steering * 5000 - yaw_rate * 3000, -5000, 5000) N m
```

The opposing term represents an active yaw damper, not hidden velocity assignment. Use the current low/high-speed steering authority curve on commanded torque and the current 0.25 airborne authority on yaw actuation. Keep damping behaviour explicit so releasing steering slows rotation. Do not set yaw velocity or heading directly.

Lateral stabilization acts along body right, tangent to the intended support plane once the vehicle has settled. For each hover point, use its own surface coupling and lift engagement. Sum allocated lateral-force contributions and apply the result centrally in the first implementation so ordinary cornering does not introduce unintended roll torque.

```text
side_force_request = -lateral_damping_Ns_per_m * sideways_speed
side_force = clamp(side_force_request, -available_lateral_force, available_lateral_force)
```

Start with 3,000 N s/m lateral damping and a total 18,000 N capacity on the baseline surface. Each support owns one quarter of this capacity, multiplied by surface lateral coupling and lift engagement `clamp(lift / trim, 0, 1)`. No hovering/contact engagement means no ground-coupled lateral force. Do not use dry sliding friction as this coupling coefficient.

At 90 m/s and 600 kg, 18,000 N allows only about a 270 m steady turn radius. A 100 m radius requires 48,600 N (8.3 g); a 50 m radius requires 97,200 N (16.5 g). Existing track corner geometry must be checked against these budgets. Turning the nose faster does not create the missing centripetal force.

### Braking and drift

Initial brake capacity is 18,000 N on the baseline surface, apportioned through the same surface engagement model. Apply braking centrally opposite velocity tangent to the sampled support plane. Limit the braking contribution to the impulse needed to remove that tangent motion in one tick; braking alone must not reverse it. Gravity and currents may still cause motion. Airborne ground-coupled brakes supply no force; fluid drag continues.

Retain maneuver engagement, entry/exit thresholds, and recovery. At full drift blend, reduce lateral damping and capacity to 25% and increase available yaw torque using the rating-derived maneuver multiplier. Remove drift speed-retention ceilings and forced deceleration. Energy loss emerges from drag and lateral force; releasing drift grants no impulse.

### Propulsion capability and gas travel

Each vehicle explicitly declares whether it requires surface support for propulsion. The initial reference craft keeps surface-dependent propulsion and reduced airborne yaw control. The gas test region therefore demonstrates wind/drag during a jump, not sustained flight.

A flight-capable vehicle must define powered vertical thrust or aerodynamic lift plus a control model. A normal gas region provides no floor and no hover-ray support. Floating gas tracks would require a separately proposed force-field mechanism. Do not label atmosphere drag/buoyancy as a completed flight model.

## 8. Solid surfaces, friction, and texture

Use `PhysicsMaterial.friction` and `bounce` for real contacts. Let Jolt resolve contact friction; do not add another custom chassis friction force on top. The approximate physical capacity is `mu * normal_contact_force`; contact force is not automatically equal to vehicle weight.

Godot's `rough` property controls how two contact friction values are combined. It does not create surface bumps. Define the chassis/surface material combination deliberately; start with chassis `rough = false`, track `rough = true`, and authored track coefficients. Verify the selected Jolt behaviour in contact tests.

Proposed test materials: baseline solid friction 0.8, ice 0.05, both bounce 0.0. These are game calibration values, not universal measured coefficients. Initially both surfaces use hover lift/lateral coupling 1.0 so a hovering craft behaves identically until contact. A separate authored low-coupling surface tests hover sliding.

Visual albedo/normal maps change appearance only. Physical bumps require collision geometry at a meaningful scale. A texture-to-material mapping may be proposed later, but initial material regions use explicit separate bodies/resources. Keep course generators synchronized with material assignments when implementing them; regeneration must not erase the assignments.

## 9. Fluids: immersion, drag, buoyancy, and flow

Use density-aware relative-flow drag and displaced-volume buoyancy:

```text
relative_velocity = vehicle_point_velocity - fluid_flow_velocity
drag = -0.5 * density * Cd * exposed_area * |relative_velocity| * relative_velocity
buoyancy = -gravity_vector * density * displaced_volume
```

The vector drag expression is an isotropic illustration. Implement per-body-axis coefficients and projected areas for the craft so forward and sideways resistance can differ. Transform point-relative velocity into body axes, compute each opposing drag component, and transform the resulting force back to world axes.

Use eight equal oriented sample boxes covering a nominated sealed hull volume, not automatically the entire collision box. Start with a total sealed displacement of 1.2 m^3. For each box, estimate liquid occupancy from the surface height across its vertical extent; this is a bounded sampled approximation under rotation, not exact clipping geometry. Apply buoyancy at the estimated occupied-volume centroid and drag at the sample centre. Asymmetric immersion then creates torque.

Distribute the craft's total reference areas among samples; do not assign the whole vehicle frontal area to every sample. Scale directional drag area by immersed fraction for the initial approximation. Allocate the complementary volume/area to gas. All samples together must reproduce the calibrated whole-vehicle air drag.

Illustrative authored densities are air 1.2 kg/m^3 and water 1,000 kg/m^3. The 600 kg craft requires about 0.6 m^3 of water displacement to float unpowered, with a small correction for air buoyancy. A lower-volume hull sinks when lift is absent. Do not cancel gravity simply because a body enters water.

At each sample, water currents and wind affect relative flow. A body moving with uniform flow has no translational relative-flow drag, though rotating samples still experience it. Liquid viscosity and turbulent flow are represented only through calibrated drag coefficients in this first model; density alone does not predict every liquid's resistance.

Liquids are `Area3D` volumes plus a physical free-surface function, initially a horizontal plane. Use the same height/normal contract for rendering and support queries. Leave area gravity/damping overrides disabled for these regions to avoid duplicating explicitly calculated forces. Sample region occupancy during the simulation step rather than relying on enter/exit signals for immersion fractions.

Do not make arbitrary water impact forces "safe" through hidden force clipping. High-density drag may require a higher simulation rate or a reviewed numerical integration scheme. Failure of the high-speed water-entry acceptance tests is an implementation blocker, not permission to silently change the physical model.

Illustrative force submission for one already-sampled medium fraction:

```gdscript
# Inputs are explicit sample geometry, medium data, and flow.
# The scalar drag example below illustrates the isotropic special case.
var offset := state.transform.basis * sample_local_position
var relative_velocity := state.get_velocity_at_local_position(offset) - flow_velocity
var drag_force := (
    -0.5 * density_kg_m3 * drag_coefficient * area_m2
    * relative_velocity.length() * relative_velocity
)
var buoyancy_force := -state.total_gravity * density_kg_m3 * volume_m3
state.apply_force(drag_force, offset)
state.apply_force(buoyancy_force, displaced_centroid_world - state.transform.origin)
```

No full fluid simulation is implied. This model omits added mass, wave-making resistance, slamming pressure, wakes, and planing lift. High-speed water-entry results must be treated as game simulation results, not engineering predictions.

## 10. Ratings and existing gameplay contracts

Proposed mapping at rating `q = rating / 100`:

| Rating | New physical interpretation / proposed range |
| --- | --- |
| Speed | Air drag scale from 2.25 to 0.5625, interpolated through 1.0 at rating 50; higher rating lowers reference air drag |
| Afterburner | Base thrust 6,000-12,000 N; afterburner total thrust 9,000-18,000 N; brake capacity 12,000-24,000 N |
| Cornering | Yaw capacity 3,000-7,000 N m; lateral capacity 12,000-24,000 N; lateral damping 2,000-4,000 N s/m |
| Maneuvering | Keep 1.2-1.8 yaw multiplier and current recovery range; fixed initial 0.25 drift lateral multiplier |
| Ramjet | Selected total thrust 15,000-27,000 N |
| Resilience | Preserve existing damage and impairment multipliers initially |
| Battery | Preserve energy capacity mapping |

The Speed mapping uses two linear segments through rating 50. Its endpoints reproduce roughly 60 and 120 m/s for the reference ordinary engine in still air. Since acceleration and top speed now share force balance, ratings cannot retain their old mathematically independent effects. Drag scale here is air-specific; do not automatically grant the same improvement to underwater hull drag.

Fuel remains an abstract resource meter; do not reduce physical mass as fuel is spent in this first implementation. Preserve heat, regeneration delays, depletion latches, boost precedence, ability costs/cooldowns, and input rearming. Live rating edits change actuator/drag parameters on the next tick without resetting motion or resources. Physical mass/geometry edits take effect on respawn to avoid silently changing momentum mid-run.

Preserve the existing velocity-based collision damage curve initially, but sample relative contact-point motion from the rigid-body contact path and retain per-collider cooldowns. Exclude ordinary support contacts. Do not reinterpret Jolt's reported estimated contact impulses as exact dissipated crash energy. Recalibrating damage against energy is a separate review decision.

Reset is an explicit state transition: queue placement for the physics callback, clear linear/angular velocity and transient force state, restore resource/maneuver state, wake the body, and reset interpolation after placement. Menu gating must freeze or pause simulation where the existing gameplay contract requires motion to stop; merely returning from a force callback does not stop gravity. A crash freezes the body to preserve the current stopped-crash contract, rather than pretending all momentum was physically dissipated.

## 11. Tick order and presentation

Establish one owner for each operation; do not advance the resource state machine in both callbacks.

1. Capture player command in `_physics_process`; AI supplies the same command object.
2. In `_integrate_forces`, consume the command snapshot and pending reset, advance gameplay state once using `state.step`, and derive current capacities.
3. Sample solids, liquid surfaces, media, and immersion from the current body state.
4. Submit hover, propulsion, steering, lateral, braking, drag, and buoyancy forces.
5. Read available contacts for damage and publish a consistently timed telemetry snapshot; document that this is not the yet-unsolved end of this tick.
6. Let Jolt integrate and resolve contacts. Presentation reads simulation results without writing body transforms.

Verify callback ordering and input latency with an integration test. Physics interpolation affects presentation only; it must not alter force calculations. Enable it for the moving body and reset it on teleport. Camera roll/pitch should be deliberately filtered instead of inheriting all chassis motion.

Remove the 1.3 m cosmetic lift offset when placing the visible hull at its physical position. Keep small visual exhaust/power cues, but avoid double-applying simulated pitch/roll as large cosmetic banking. Re-check spawn heights, canyon clearance, and camera clearance at the new physical ride height.

Telemetry should include speed, mass, thrust N, lift N, buoyancy N, drag N, brake N, lateral N, yaw torque N m, angular velocity, slip angle, supporting materials, medium/immersion, and measured acceleration in m/s^2 and g. Keep resources and status signals. Use measured velocity for presentation and normalize engine visuals from actual requested thrust capacity.

## 12. Implementation sequence and affected files

Implement only after review, as one primary controller path:

1. Add physical tuning/preset fields and the required surface/fluid Resources and scripts. Build an isolated `PhysicsTestTrack.tscn` with explicit atmosphere, solid floor, ice, low-coupling strip, water basin/current, and wind region.
2. Convert the vehicle body and movement kernel. Implement reset, freeze/pause, contacts, and type migrations together so no CharacterBody shim is needed.
3. Add four hover supports and force-driven propulsion/steering/braking. Calibrate the reference craft against the analytic checks.
4. Add eight immersion samples, air/water drag, buoyancy, and flow. Verify transitions and numerical stability before applying them to the race maps.
5. Integrate Resources into `Main.tscn`, `TestTrack.tscn`, `CanyonSlice.tscn` and relevant course generators. Reconcile presentation, spawn placement, HUD, and sandbox controls.
6. Migrate tests and update `VEHICLE_SPEC.md` and `TESTING.md` to the approved physical contracts. Run the focused checks and full project test task, then conduct manual course/controller review.

Expected existing files: `vehicle_controller.gd`, `vehicle_stats.gd`, `vehicle_tuning.gd`, `vehicle_maneuver.gd`, `ship.gd`, `vehicle_ability.gd`, `vehicle_sandbox.gd`, `test_track.gd`, relevant `.tres` presets/scenes, `project.godot`, test fixtures and affected tests. Add `track_surface.gd`, `track_surface_3d.gd`, `fluid_medium.gd`, `fluid_region_3d.gd`, test material Resources, and the test course. Keep these additions scoped to their explicit responsibilities; no general environment framework is required.

## 13. Verification and acceptance criteria

Use the existing GUT/mise workflow and read the project test skill before implementation testing. Run real physics frames. `--fixed-fps` alone does not select the physics tick rate; set `Engine.physics_ticks_per_second` explicitly in timestep fixtures and restore it afterward. The following are proposed acceptance tolerances, not reported passes.

| Test | Acceptance target |
| --- | --- |
| Pure translation, gravity/drag disabled in fixture | 6,000 N for 1 s gives 10 m/s change at 600 kg, within 2%; 1,200 kg gives half |
| Principal-axis rotation, damping disabled | Angular velocity change matches torque / measured inertia over test duration within 3% |
| Free motion with all external forces disabled | Linear and angular momentum remain within 1% over 5 s |
| Static hover | From a 0.2 m displacement, settle within 0.05 m of target in 3 s on flat ground, without chassis contact |
| Payload | Extra 120 kg gives about 0.049 m additional static sag with four 6,000 N/m springs, within 0.01 m |
| Terminal speed | Still-air reference ordinary/boost speeds approach analytic equilibrium within 3%; no clamp-induced discontinuity |
| Braking | In no-drag flat fixture, 18,000 N stops 600 kg from 30 m/s in about 1 s and 15 m, within 5%; no reversal caused by braking |
| Lateral force | Initial sideways acceleration matches applied capacity / mass; steering alone never rotates velocity instantly |
| Material contact | Ice contact loses less tangential speed than baseline solid under matched load; airborne/hovering friction alone changes neither |
| Buoyancy | A constrained-orientation unpowered 600 kg hull settles near 0.6 m^3 water displacement, within 3%, accounting for gas buoyancy |
| Uniform flow | Zero relative translational velocity and zero rotation produces zero drag; flow accelerates a stationary hull in the correct direction |
| Partial immersion | One-sided immersion creates the expected yaw/roll torque; dry fractions receive no liquid forces |
| Gas | Denser gas increases drag for identical motion; no floor support appears |
| Timestep | 60/120 Hz runs agree within 5% on speed, stopping distance, and hover settling; no growing energy or oscillation in water entry |
| High-speed travel | Wall impacts and water entry at reference ramjet speed do not tunnel through solids or cause numerical energy growth |
| Gameplay | Existing resource timing, input precedence/rearming, ability, reset, pause and crash contracts pass after type migration |

Fluid convergence tests must include angled entry, one-pod immersion, exits, region boundaries, and a current. Scope the tolerances to explicit fixture geometry and conditions; do not force a full unstable model to pass by weakening assertions. If 60 Hz cannot meet the high-speed fluid target, report the blocker and review a higher rate/integration method before proceeding.

Manual review must cover track corner radii, hover transitions at crests, hill climbing, perceived weight, controller feel, visibility/comfort, and liquid entry. Physics is not guaranteed deterministic, so use tolerances instead of bit-identical replay assertions.

## 14. Accepted implementation decisions

The user authorized implementation and prioritized reliable ground following and integration with Galactic Racer fundamentals. The resulting current contract is [VEHICLE_SPEC.md](VEHICLE_SPEC.md).

1. **Handling:** retain 600 kg reference mass, but choose 18/27/36 kN ordinary/Afterburner/Ramjet peak thrust, 60 kN lateral authority, 9 kN m yaw capacity and 33 kN brakes at balanced ratings. These force budgets suit the existing maps better than the original 18 kN lateral limit. Tight corners still require braking.
2. **Coasting:** replace constant thrust/high drag with low quadratic drag and a calibrated quadratic engine thrust taper. Full-power reference speeds remain 90/110/140 m/s, with approximately 4 m/s² coasting deceleration at 90 m/s. There is no speed clamp; partial throttle has lower equilibrium speed.
3. **Ground following:** use 0.8 m ride height, 4 m probe reach, four 120 kN/m springs, 6 kN s/m dampers and ±80 kN force limits per pad. Relative-to-surface damping fixes uphill motion being mistaken for suspension bounce. Bidirectional hover attraction and finite attitude torque follow sharp crests; true gaps provide no attraction. This powerful fictional actuator model is explicit rather than hidden floor snapping.
4. **Maneuver:** use the current visual vehicle's podracer identity. Space/controller A is an airbrake with 14 kN extra braking, 1.3x lateral grip and rating-controlled yaw/recovery. Preserve fuel Afterburner, heat Ramjet, seven ratings, abilities, input precedence and released-button rearming. Do not claim implementation of the other classes' unique maneuvers.
5. **Water and gas:** implement 1.2 m³ sealed displacement, eight partial-immersion samples, density-based directional drag, low-speed water resistance, buoyancy, currents and wind. Use priority-partitioned occupied intervals and approximate buoyancy centroids. Drag uses an implicit linear/quadratic step to remain dissipative at high fluid resistance. No exact fluid dynamics or sustained gas flight is claimed.
6. **Maps:** keep both canyon maps, preserve the newly authored Venus map and connect its visible liquid plane to a real fluid region. Add a separate Physics Lab for ice, water and crosswind. Surface friction is separate from hover coupling; gas never becomes a floor.
7. **Simulation and lifecycle:** select 120 Hz for play, with 60/120 Hz regression coverage, Jolt CCD and interpolation. Retain explicit freeze on crash, paused simulation and one-shot reset placement/velocity clearing. These are game state transitions, not physical collision outcomes.
8. **Verification:** the added crest test traverses the first canyon hill at an initial 140 m/s with no support loss or damage at 60 and 120 Hz; peak clearance is about 1.1 m. Numeric tests also exercise mass scaling, inertia, payload sag, real gaps, friction, floating equilibrium, flow-relative drag, one-sided immersion and overlapping-fluid displacement. Final suite results belong in TESTING.md.

## 15. Evidence and sources

Regression-audit refinements to section 14: yaw retains 25% authority at rest so obstacles do not trap the racer; braking and lateral damping spend only the momentum remaining after fluid drag; racers collide with each other; liquid hover acquisition extends within the finite 4 m field below the free surface and uses priority for coincident materials. Pause/resume preserves momentum, reset clears force telemetry and prior-step propulsion, and camera placement resets on a physics tick. These defaults are detailed in VEHICLE_SPEC.md and covered by the driving/lifecycle suites.

Project evidence: `vehicle_controller.gd`, `ship.gd`, `vehicle_tuning.gd`, `vehicle_stats.gd`, `vehicle_maneuver.gd`, `vehicle_ability.gd`, `vehicle_sandbox.gd`, `test_track.gd`, `Main.tscn`, `project.godot`, `VEHICLE_SPEC.md`, `TESTING.md`, and test fixtures. Existing gameplay/test documentation includes historical controller details; inspect actual scripts rather than assuming every old numerical claim still applies.

Local guides consulted: [rigid bodies](.agents/references/godot-physics/2026-10-25/topics/rigid-body.md), [ray casting](.agents/references/godot-physics/2026-10-25/topics/ray-casting.md), [engine comparison](.agents/references/godot-physics/2026-10-25/topics/physics-engines.md), and [Jolt](.agents/references/godot-physics/2026-10-25/topics/using-jolt-physics.md). The linked full local rigid-body and ray-casting sources informed the integration/query approach.

Official API and physics references researched for this proposal:

- [Godot 4.7 RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html): force-driven body, mass/inertia, damping, integration callback, CCD.
- [Godot 4.7 PhysicsDirectBodyState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectbodystate3d.html): positioned forces, point velocities, state and contacts.
- [Godot 4.7 PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html): body/area spatial queries.
- [Godot 4.7 PhysicsMaterial](https://docs.godotengine.org/en/4.7/classes/class_physicsmaterial.html): contact friction, bounce, and combination behaviour.
- [Godot 4.7 Area3D](https://docs.godotengine.org/en/4.7/classes/class_area3d.html): regional detection and gravity/damping overrides.
- [Godot Jolt guide](https://docs.godotengine.org/en/latest/tutorials/physics/using_jolt_physics.html): backend differences and estimated contact impulses; moving latest alias, also covered by the pinned local guide.
- [NASA drag equation](https://www1.grc.nasa.gov/beginners-guide-to-aeronautics/drag-equation/): density, reference area, speed, and coefficient relationship.
- [OpenStax buoyancy](https://openstax.org/books/university-physics-volume-1/pages/14-4-archimedes-principle-and-buoyancy): displaced-fluid weight and floating equilibrium.

The force capacities, material coefficients, coupling rules, rating mappings, sample layout, and acceptance thresholds are design proposals. They are not prescribed by Godot documentation. The original research draft did not run gameplay tests; implementation verification is now recorded in TESTING.md.
