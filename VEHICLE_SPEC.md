# Hover Racer vehicle fundamentals and controls

Implemented physical driving contract, 2026-10-25. This supersedes the former CharacterBody controller specification. The approved changes to the research draft are recorded in [PHYSICS_IMPLEMENTATION_PROPOSAL.md](PHYSICS_IMPLEMENTATION_PROPOSAL.md#14-accepted-implementation-decisions).

## Driving identity

The current twin-engine vehicle uses a **podracer airbrake**: build speed on straights, brake before tight corners, hold the maneuver input for tighter turning at a substantial speed cost, and release it before boosting. Steering changes heading through torque while lateral thrusters change momentum through force. There is no instantaneous direction alignment, imposed speed ceiling, or speed gift on maneuver release.

The local [Galactic Racer reference summary](.agents/references/galactic-racer-vehicles/2026-10-25/REFERENCE_SUMMARY.md) distinguishes stable drifting landspeeders, light speeder bikes, banking skim speeders, and high-speed airbraking podracers. This implementation follows the last identity. It does not claim to reproduce the original game's equations or implement the other three classes' unique maneuvers. All numbers here are Hover Racer tuning decisions.

## Controls and precedence

| Action | Keyboard | Controller | Result |
| --- | --- | --- | --- |
| Throttle | W | RT | Proportional engine thrust; partial throttle has a lower equilibrium speed |
| Brake | S | LT | Ground-coupled braking force, including lateral motion; cancels boosts/maneuver |
| Steer | A / D | Left stick | Finite yaw torque and lateral stabilization |
| Afterburner | Shift | RB | Replenishing fuel-based boost |
| Ramjet | Ctrl | LB | Stronger boost that accumulates heat |
| Airbrake maneuver | Space | A | Increased yaw/grip and an additional braking force |
| Ability | E | B | Diagnostic pulse, costing ability energy |
| Reset | R | Y | Reset position, linear/angular motion, resources and transient states |
| Pause/menu | Escape | Menu/Start | Pause the race; browse maps without changing the active race |

Input priority remains: pause/crash, braking, maneuver/recovery, Ramjet, Afterburner, ordinary thrust. Boosts require throttle, valid support, no brake, no maneuver/recovery, no impairment, and a live vehicle. Ability eligibility is independent of throttle but requires energy, cooldown, no impairment, and a live unpaused vehicle. Special buttons held through menu/focus changes must be released before rearming. Trigger deadzone is 0.05 and steering deadzone 0.15; steering input smooths at 8 units/s.

## Body and ground following

`VehicleController` extends `RigidBody3D`, using Jolt, automatic collider-based inertia, continuous collision detection, and explicit force integration. Project physics runs at 120 Hz with interpolation. Tests also exercise 60 Hz. One world unit is one metre. Force is in newtons, torque in newton-metres, mass in kilograms.

The reference vehicle has mass **600 kg**, a **3.1 x 0.4 x 4.6 m** collision box, and **1.2 m³** sealed displacement. Mass applies at respawn. Fuel is an abstract resource, not variable physical mass. The visual hull now sits at the physical body's origin rather than floating an extra 1.3 m above it.

Four pads at local `(±1.1, 0, ±1.8)` probe 4 m along body-down. Target clearance is **0.8 m**. Each applies trim + spring - damper force, bounded by material coupling and actuator capacity:

| Per-pad parameter | Value |
| --- | ---: |
| Trim | 1,470 N |
| Spring | 120,000 N/m |
| Damping | 6,000 N·s/m |
| Maximum lift | 80,000 N |
| Maximum downward attraction | 80,000 N |

Damping uses point motion relative to the sampled surface plane, including angular velocity. This avoids treating uphill travel as unwanted vertical motion. A finite attitude torque aligns the chassis with the support normal. These powerful bidirectional repulsors are an explicit fictional mechanism needed by the existing sharp crests at racing speeds. The body still has mass/inertia, and force capacity is finite. No hit means no hover force: a true gap launches the vehicle rather than snapping it to a distant floor. Eligible surface normals remain within 50 degrees of world-up.

## Ratings and physical output

All seven ratings remain 0–100 and default to 50. `VehicleTuning.derive()` maps them to the following quantities. Loaded presets are shared immutable Resources; the sandbox duplicates stats before editing them. Per-vehicle resources and timers live on the controller.

| Rating | Physical effect | Range / midpoint |
| --- | --- | --- |
| Speed | Reference equilibrium used to calibrate engine thrust taper | 60–120 / 90 m/s |
| Afterburner | Base thrust, selected boost thrust, braking, reference speed bonus | 12–24 / 18 kN base; 18–36 / 27 kN boost; 24–42 / 33 kN brake; 10–30 / 20 m/s bonus |
| Cornering | Yaw torque, lateral force, slip damping | 7–11 / 9 kN·m; 45–75 / 60 kN; 7–11 / 9 kN·s/m |
| Maneuvering (Airbraking in sandbox) | Maneuver yaw multiplier and release recovery | 1.2–1.8 / 1.5; 0.50–0.15 / 0.325 s |
| Ramjet | Selected boost thrust and reference speed bonus | 24–48 / 36 kN; 30–70 / 50 m/s |
| Resilience | Damage multiplier, impairment duration multiplier, impact threshold | 1–0.5 / 0.75; 1–0.5 / 0.75; 30–60 / 45 m/s |
| Battery | Ability energy capacity | 100–300 / 200 units |

For the balanced vehicle, full-power reference equilibria are **90 / 110 / 140 m/s** for ordinary / Afterburner / Ramjet. These are reference conditions, not hard caps: slopes, wind, different media and external impulses alter actual speeds.

Engine thrust tapers quadratically with forward speed. For base force `F0`, reference speed `v_ref` and still-air quadratic drag coefficient `k`, `v_free² = v_ref² / (1 - k*v_ref²/F0)` and `F_engine = throttle * F0 * clamp(1 - v_forward²/v_free², 0, 1)`. Reference tuning keeps `F0 > k*v_ref²`. Changing mass does not change engine force; heavier vehicles accelerate more slowly.

Still-air forward drag has `k ≈ 0.2963 kg/m`, giving about **4 m/s² coast deceleration at 90 m/s** for 600 kg. It slows quadratically, not by a fixed deceleration. Ending boost preserves excess momentum. Side/up drag differ by projected area.

Yaw command starts at 25% authority at rest, rises to full at 15 m/s, and has a high-speed factor decreasing to 0.65 by 100 m/s. This permits turning away from obstacles without forward motion. Airborne command authority is multiplied by 0.25. An explicit yaw damper uses 6,500 N·m·s. The current craft requires support for propulsion, lateral stabilization and normal braking. Gas alone does not provide a floor or sustained flight.

Fluid resistance is evaluated before drive actuation. Braking and lateral damping share the remaining stopping impulse, preventing their combined forces from reversing slow motion. Vehicle collision masks include other racers.

At 90 m/s the balanced lateral capacity corresponds to about an **81 m steady turn radius**; tighter course corners require lower entry speed. Airbraking adds **14 kN braking**, multiplies lateral grip/damping by **1.3**, and uses the rating-derived yaw multiplier. Entry needs speed at least 15 m/s, exit below 12 m/s, and entry blends over 0.10 s. Releasing the maneuver restores normal handling over its recovery time and continues to exclude boosts until recovery finishes. Brake or loss of support immediately cancels the maneuver.

## Solids, liquids, and gas

`TrackSurface3D` owns an explicit `TrackSurface` and Godot contact material. Baseline road friction is 0.8, ice 0.05, bounce zero. Track materials use the rough-combination flag; the chassis friction is 0.4. Contact friction only applies while colliders actually touch. Visual roughness/textures do not change friction or collision geometry.

Hover lift and lateral coupling are distinct material properties. Road and ice initially both use coupling 1.0, so they differ during chassis contact, not while hovering. Water uses lift coupling 0.85 and lateral coupling 0.35, making handling looser over liquid.

The powered liquid hover field can acquire a free surface within 4 m above or below each pad, so a shallow submerged racer can rise back into hover. It uses the same finite lift limits; deeper immersion relies on buoyancy until the surface comes within reach. Coincident liquid surfaces use descending medium priority for their coupling material.

`FluidRegion3D` describes an axis-aligned box with a medium, explicit flow and priority. Its top is a liquid's flat physical surface. The default authored atmosphere is air at 1.2 kg/m³; test water is 1,000 kg/m³. Gas volumes produce drag/buoyancy, not support. Overlapping regions partition sample intervals in priority order; atmosphere fills unoccupied intervals. A sample fraction is never counted twice.

Eight hull samples approximate immersion. Per-axis drag uses relative point velocity against flow, quadratic density/area resistance, and optional linear low-speed resistance. Water's calibrated linear resistance is 800 N·s/m³ per projected area; this is a game hull-resistance coefficient, not a measured viscosity. Drag uses an implicit quadratic/linear step to avoid explicit-drag reversal at high density/speed. Forces remain applied at sample points, generating rotation during one-sided immersion.

Buoyancy equals displaced-fluid weight and acts at the estimated occupied interval centroid. The unpowered 600 kg craft floats at approximately 0.6 m³ water displacement. The eight-cell method approximates hull clipping and rotated occupancy; it is not computational fluid dynamics, planing, slamming, flooding, or a splash simulation.

Venus uses an actual fluid region at its visible 0.5 m surface, with 1 m/s current. Its old rigid road collider is disabled. Its visual ripples perturb shading only so the physical/visible surface heights agree. The separately selectable **Physics Lab** includes solid, ice, a 3 m/s water current, and a 20 m/s crosswind region. Ordinary canyon maps retain solid materials.

## Resource and lifecycle contracts

- Fuel capacity 100; Afterburner consumes 25/s. Start requires 10 reserve; continued use may drain to zero. Depletion latches until the button is released. Regenerate 20/s after 0.75 s with neither boost active.
- Ramjet generates heat at 0.20/s. Warn at 0.80; crash at 1.0. Cool 0.25/s after 0.50 s without Ramjet. Afterburner does not block cooling. Rearm the heat warning below its threshold.
- Energy capacity is rating-derived. The diagnostic pulse costs 40 and has a 2 s cooldown. Regenerate 10/s after 1 s without spending. Failed requests do not spend energy or reset recovery.
- Health starts at 100. Impact damage uses relative normal approach speed above 10 m/s, coefficient 0.03 times squared excess speed, then the Resilience multiplier. Contacts have a 0.25 s per-collider repeat interval. Hard impacts impair control; ordinary hover support does not damage the vehicle. Collision response remains Jolt's responsibility.
- Live rating changes preserve fuel, heat, health and absolute energy; clamp energy only when capacity falls. They change force curves on the next simulation tick without resetting momentum.
- Crash freezes the vehicle and its resource updates. Reset clears motion, timers, boost/maneuver/input state and damage; restore full resources and reset interpolation. Pause freezes the simulation; merely opening a menu cannot leave gravity active on the ship.

## Verification and limitations

See [TESTING.md](TESTING.md) and the `test:physics` suite for numeric checks. Tests distinguish engine physics from authored hover technology. They cover real gaps, crest adhesion at 140 m/s, mass scaling, inertia, contact friction, buoyancy, currents, overlap partitioning, asymmetric immersion and high-speed water-entry stability. Rendered appearance and physical controller feel still require play testing.

Sustained flight, gas force-field tracks, other vehicle-class maneuvers and exact hydrodynamics are not implemented. They need their own explicit physical/control designs, not silent substitutions for the surface-driving path.
