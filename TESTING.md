# Physical driving verification

The current contract is [VEHICLE_SPEC.md](VEHICLE_SPEC.md). The vehicle is now force-driven `RigidBody3D`; historical kinematic cap/alignment descriptions below are superseded by this section.

Verified 2026-10-25 on Godot 4.7.2: the final coordinated `mise run test` completed import plus **100 tests / 24,188 assertions**, all passing, with no engine/script errors, interpolation warnings or leaked-object warnings in the captured console output (`.godot/audit-final-console.log`). Separate `test:timing:30` and `test:timing:144` runs passed. Coverage includes all-map crash/reset/restart, controller-only setup exit, profile persistence and focus-loss dialogs, live binding hints, stop/turn/rail recovery, overlapping fluids, submerged recovery, Jupiter full laps at 60/120 Hz, and garage integration. This is automated simulation/layout verification plus a rendered SN30 crash-HUD check; physical controller feel was not evaluated.

Ship teardown stops audio players and releases their streams. The Venus test fixture observes actual wind-stream release through a weak reference before finishing, because AudioServer mixer retirement is asynchronous to accelerated simulation frames. The existing task timeout still exposes stalled cleanup.


- `mise run test` is the full import + GUT gate.
- `mise run test:physics` covers mass scaling, rotational inertia, hover settling/payload, unsupported gaps, contact friction, floating displacement, currents, gas without floor support, overlap partitioning, relative-flow drag, asymmetric immersion and high-speed fluid stability.
- `mise run test:hills` includes 140 m/s crest/descent checks at both 60 and 120 Hz, requiring support, less than 2 m clearance and preserved health.
- `mise run test:timing:30`, `test:timing:60`, and `test:timing:144` replay commands at 60/120 physics Hz under differing render rates.
- Movement suites now assert force-driven acceleration, lower partial-throttle equilibrium, finite lateral forces, airbrake speed cost and momentum retention after boost release. Resource, input, menu, ability and collision regressions remain required.
- Venus support tests sample its physical fluid region instead of treating a liquid as a solid ray-hit floor. Physics Lab is independently selectable after Venus.

Play check: W/RT accelerates; A,D/left stick steers; S/LT brakes; Space/A airbrakes before corners. Shift/RB spends Afterburner fuel, Ctrl/LB builds Ramjet heat. E/B activates the diagnostic pulse; R/Y resets. Select Physics Lab for ice/water/current/wind, or Venus for the liquid course. Confirm chassis follows hills, gaps allow falling, and no cosmetic 1.3 m offset separates the visible hull from its collision body.

Headless checks verify simulation and UI layout, not physical controller feel or rendered comfort. Water uses sampled rigid-body forces, not a fluid solver.

---

# Hover Racer controls and verification

The implementation contract is [VEHICLE_SPEC.md](VEHICLE_SPEC.md). The game uses Godot 4.7.2, Jolt, a grounded CharacterBody3D and one physics simulation for player and recorded/AI commands. Units are metres and seconds. The visual hover offset never moves the collision hull.

## Play and tune

Run `mise run play`, choose New Race, and drive with W/S throttle/brake and A/D steering. Shift uses Afterburner, Ctrl uses Ramjet, Space engages drift, E activates the diagnostic pulse, and R respawns. On a controller use RT/LT, left stick, RB/LB, A, B and Y respectively. Esc/Start opens the pause menu. Brake takes priority, then drift/recovery, then Ramjet, then Afterburner. Held special actions must be released after menu/focus changes.

The seven sandbox sliders update ratings immediately without refilling resources. Sandbox edits are temporary and copy the preset before changing it. Enter leaves a rating text field; gameplay is gated while editing. Presets are immutable to the controller: edit `balanced_vehicle.tres` in the Inspector for authored values. Shared constants are in `default_vehicle_tuning.tres`. The default `pulse_ability.tres` costs 40 energy, has a two-second cooldown, and emits an activation event; it is a diagnostic ability with no combat effect.

The HUD displays drive speed in km/h, boost/airbrake state, fuel, heat, battery and hull meters, ability readiness/cooldown, impairment and crash warnings. Ability, respawn and pause hints use the current keyboard/controller bindings, including SN30 face labels. The Controls page also reflects remapping. Crashes remain stopped until the active Respawn control or New Race resets the vehicle.

Controller Setup provides Xbox Wireless Controller and SN30 Pro presets, a Custom working set, and named saved profiles. Choose a set and press Load. Remap an action, choose Save profile, enter a name and confirm; using an existing name explicitly replaces that profile. Controller profiles preserve keyboard mappings and use the same physical positions on both pads. SN30 Pro uses Windows X-input mode (X + Start); its face labels are B for airbrake, A for ability and X for respawn. Named profiles and active controls persist in `user://vehicle_controls_v2.cfg` and reload on startup. Keyboard remaps remain global. Raw controller inputs are available under Show raw controller inputs; the live meters remain available for testing. Escape cancels capture. Setup supports mouse, keyboard and controller navigation. B/Back or Menu leaves setup outside capture; while capturing, those buttons can be assigned without exiting. Returning to the game menu closes an unfinished profile-name dialog. The `test_controller_setup.gd` integration suite covers presets, named save/load/replacement, restart persistence, naming dialog, input isolation and layout.

## Automated verification

Run `mise run test` for resource import and the full vendored GUT 9.7.1 suite. This is the final verification gate. Windows tasks use `godot_console`; do not substitute a custom runner. GUT reports assertions and unexpected engine errors, with logs in `.godot/test-*.log` and final JUnit output in `.godot/test-results.xml`.

| Task / suite | Coverage |
| --- | --- |
| `test:unit` | Rating defaults, endpoints, clamping, rating isolation |
| `test:power` | Acceleration, analog throttle, ordinary/boost ceilings, depletion latch, boost priority, heat warning and crash |
| `test:coast` | Coasting, proportional braking, no reverse, magnitude-preserving alignment |
| `test:steering` | Steering sign/smoothing/rest authority, maneuver entry/exit hysteresis, recovery and boost exclusion |
| `test:controller` | Physical keyboard bindings, trigger deadzone, opposing inputs, menu rearming and discarded presses |
| `test:menu` | Startup, navigation, pause/resume, reset isolation, responsive layout |
| `test:thrust` | Seven-rating sandbox, preset immutability, live resources and responsive HUD |
| `test:regressions` | Steering at rest, stopping impulses, racer collisions, reset force state, submerged recovery, overlapping surface priority and underwater braking |
| `test:jupiter` | Ring support, lateral gravity, full laps at 60/120 Hz, rail escape, fall/reset and map cleanup |
| `test:fall` | Airborne momentum/gravity/facing, air ability, crash and respawn |
| `test:hills` | Road cross sections/barriers and both actual hills with grounded movement |
| `test:canyon` | 470 scenery/shape clearance samples, model, exhaust, camera and audio behavior |
| `test_vehicle_garage.gd` (full/integration suite) | All 27 cosmetic builds, preview agreement, unchanged physics, exhaust switching, kit presets, reset/map retention, controller access and small layout |
| `test:integration` | All above plus collisions, relative normal damage, landing crash ordering, resource delays, live capacities and shared presets |
| `test:timing:30`, `test:timing:60`, `test:timing:144` | Same recorded commands at three render clocks, each comparing 60 and 120 physics ticks with tolerance |

Tests use fresh game-save namespaces and restore input, pause, viewport and physics rate. They advance actual physics frames rather than calling `_physics_process` directly. Old thrust-envelope tests were replaced with tests of the specified acceleration and resource behavior. The original geometry, remapping, menu and audiovisual regression checks remain, updated where their old expectations conflicted with the new contract.

Headless checks cannot establish physical controller feel or keyboard rollover. Rendered HUD/sandbox and menu inspection is separate from the automated gate. The local physics reference topics used are CharacterBody movement, ray queries and 3D collision shapes; the linked Godot 4.7 API documentation establishes last-movement floor semantics and collision reporting.

## Maps

The map-selection menu displays a live, isolated preview world. A cosmetic racer follows the road center at 12 m/s, looping the selected course while the real race stays paused. Browsing updates the preview immediately; Resume retains the race and New Race starts at the selected spawn. The straight Physics Lab uses a narrow oval tour. Preview rendering and scenery are removed when leaving map selection. `test_menu.gd` verifies cruise speed, route following, loop wrapping, every map, and paused-race isolation; `tools/preview_menu.gd` captures the rendered menu.

Use the menu's < / > buttons, Left/Right keys, or D-pad Left/Right to cycle maps. New Race loads the selection; Resume Race retains the paused map. Map 1 is Test Canyon (924 m). Map 2 is Long Canyon (2,771 m), with longer straights and hills, the same six corners, and corner radii of 35 m versus 28 m. Road width stays 28 m.

Each `maps/map_N.tres` defines its name, scene, spawn, corners, hills and generation outputs. Its `maps/map_N.tscn` combines road and scenery. Add definitions to `MAPS` in `test_track.gd` to extend the selector. The original saved road and scenery remain in `TestTrack.tscn` and `CanyonSlice.tscn`.

Rebuild a map's saved geometry with `godot_console --headless --path . --script res://tools/build_course.gd -- res://maps/map_2.tres`, then `godot_console --headless --path . --script res://tools/build_canyon.gd -- res://maps/map_2.tres`. Substitute `map_1.tres` to rebuild Map 1. The full gate includes `test_maps.gd` for 3D lap length, corner proportions, road continuity, barriers and scenery clearance, and menu coverage for switching and paused-race isolation.

### Map 3: Venus — Aureate Sea

A 1,617 m flat course with a yellow-gold liquid surface, speed-responsive wakes, rain-impact ripples, green acid rain, sulfur haze and alien spires. The surface uses the shared fluid simulation with a level free surface, a gentle current and reactive visual wakes. Its wet-driving modifier uses 18% of dry-road lateral/braking force capacity, producing longer sideways slides and braking distances while preserving liquid hover support. Acid rain is visual and does not apply damage. Map-specific environments restore when changing races. Venus is Map 3; Physics Lab remains available after it.

Rebuild its road with `godot_console --headless --path . --script res://tools/build_course.gd -- res://maps/map_3.tres`. `maps/venus.gd` supplies its scenery/weather and `maps/venus_liquid.gdshader` supplies the liquid. Run `mise run test:venus` for course support, racer-driven wake updates, pause behavior, environment cleanup, wet braking/restart and countersteering at 60/120 Hz, repeated map switches, crash/reset recovery, off-course restart and submerged recovery without resetting. Menu tests also verify every map selector fits a 640×480 viewport. `tools/preview_venus.gd` renders menu/racing screenshots to `previews/venus-menu.png` and `previews/venus-racing.png`.

### Map 4: Jupiter — Ringrunner

A stylized 2,262 m circular ring course, 36 m wide, surrounded by dust bands and stars. Race in the starting direction to keep Jupiter and the inward gravity on your left. The map applies a 4.5 m/s² horizontal inward acceleration as a mass-scaled central force at physics tick rate. Countersteer right to resist the drift. Gravity pauses with the race and is removed when switching maps; ordinary vertical support remains unchanged.

One fixed Great Red Spot is painted into the planet at the quarter-orbit longitude, marked by one viewing sign per circuit. A gentle inward camera glance during the approach exposes the storm; camera yaw restores when leaving the map. Physics Lab follows Jupiter as Map 5. `tests/integration/test_jupiter.gd` checks full-ring support, leftward force direction, actual displacement, pause and cleanup. `tools/preview_jupiter.gd` captures the rendered start and storm approach in `previews/`.


### Pause, controller navigation and lifecycle regression audit

`test_ui_lifecycle_regressions.gd` exercises controller-only exits from Setup, sandbox focus across pause/resume, preserved motion and frozen timers while paused, and repeated crash/respawn/driving on every selected map. Setup now lets unbound navigation events reach the GUI; B/Menu returns to the game menu while an active binding capture still consumes its input.

`test_physics_lifecycle_regressions.gd` verifies cleared force telemetry on respawn, frozen editing without erased momentum or extra thrust, angular reset after tumbling, respawn while gated, and rapid repeated pause transitions. Frozen rigid-body velocities are retained explicitly and restored in the physics integration callback.

The hill clearance test uses a single 2 cm sphere sweep across triangle seams, with the existing support-loss, health and maximum-clearance requirements. Camera-local presentation does not interpolate a second time over the interpolated chassis; viewport resizing and map-specific camera glances remain valid outside physics ticks. Visual reset placement is applied on a physics tick.
