# Cosmetic vehicle parts

Open **Vehicle Garage** from the game menu before a race or while paused. Choose a Nose, Core, and Engine assembly independently, or select a complete kit. Changes apply immediately to the racer and rotating preview. Back returns to the game menu; Escape or controller B/Menu also returns.

| Kit | Mission namesake | Design |
| --- | --- | --- |
| Terra | [NASA Earth Observing System mission](https://terra.nasa.gov/about/mission) | Pointed wedge, compact canopy, slim white/cyan turbines |
| Magellan | [NASA Venus orbiter](https://science.nasa.gov/mission/magellan/) | Broad armored prow and cabin, large gold engine pods |
| Juno | [NASA Jupiter orbiter](https://www.jpl.nasa.gov/missions/juno/) | Split fork, exposed cockpit frame, copper engines with cooling fins |

The names honor the missions; these original fictional racing kits are not spacecraft replicas. They replace the proposal's Dart, Bulwark, and Scavenger names respectively.

Three variants in each of three slots give **27 combinations**. Both engines and their mounts are one assembly. All nine modules use the same coordinates and are compatible with every other slot choice. `pod_visual.gd` authors the geometry and selects one visible module per slot; `vehicle_garage.gd` provides the controls and independent preview world.

Parts are cosmetic. Ratings, tuning resources, mass, collision shape, hover-pad positions, propulsion and handling are unchanged. Exhaust animation follows the selected engine assembly. Selection survives pause/resume, crash/respawn and New Race/map changes within the running game. Selection is session-only and starts with the Terra kit on launch.

The design is informed by the [captured Galactic Racer body-system references](.agents/references/galactic-racer-vehicle-parts/2026-10-25/REFERENCE_SUMMARY.md), condensed from six body slots into three. No source models or textures were copied.

`tests/integration/test_vehicle_garage.gd` checks every combination, preview agreement, unchanged physical configuration, live exhaust references, preset mixing, reset/map retention, controller navigation, and small-window layout. Run `mise run test` for the full gate. Rendered checks can be reproduced with `godot_console --path . --script res://tools/preview_garage.gd`; images go to `previews/garage-*.webp`.

Verification on 2026-10-25: all four garage tests passed, including all 27 combinations; rendered Terra, Magellan, Juno and mixed-build previews were inspected at 1280×720 and the mixed garage at 640×480. The final combined gate, including live map-preview coverage, passed 101/101 tests and 24,244 assertions with no engine errors or leaked-object warnings.
