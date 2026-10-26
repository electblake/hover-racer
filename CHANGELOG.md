# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Added modular Test Canyon, Long Canyon, Venus Aureate Sea, and Jupiter Ringrunner maps with menu selection.
- Added a three-times-longer canyon course, reactive gold liquid and acid rain on Venus, and inward gravity, the Great Red Spot, and scenic moons on Jupiter.
- Added live map previews with a steady center-road demo loop, isolated from the paused race.
- Added resource-based vehicle ratings, fuel, heat, battery, pulse ability, and a physics laboratory with ice, water, currents, and wind.
- Added controller setup with named binding profiles and a cosmetic garage with Terra, Magellan, and Juno parts in 27 combinations.
- Added driving, map, garage, controller, lifecycle, and timing regression coverage, plus rendered preview tools and images.
- Added controller diagnostics with live input readings, visual action meters, and persistent button and signed-axis remapping.
- Added a movable vehicle sandbox with saved live tuning settings and a thrust HUD.
- Added thrust envelope timing and configurable steering acceleration and deceleration.
- Added vendored GUT 9.7.1, isolated unit and integration fixtures, and controller diagnostics regression coverage.
- Added a local Godot physics reference snapshot and project physics and testing skills.
- Added a pause menu that opened on startup and toggled with Escape or the controller Menu/Start button.
- Added menu tests for pause isolation, cross-device toggling, key repeat, input release, and viewport layout.
- Added complete keyboard controls with Spacebar thrust, Shift braking, arrow-key steering and turn modifiers, WASD modifiers, independent stick keys, and R reset.
- Added keyboard input regression coverage alongside existing analog controller checks.
- Added mise tasks and a project launch skill for opening the game and Godot editor.

### Changed

- Replaced the vehicle controller with rigid-body hover, propulsion, steering, braking, collision, and fluid forces.
- Updated driving inputs, the resource HUD, and the tuning sandbox for the new vehicle mechanics.
- Moved the map-selection menu left to expose the live preview vehicle and scenery.
- Migrated regression scripts to discoverable GUT suites and expanded mise test tasks.
- Grouped vehicle tuning properties in the Godot Inspector alongside the in-game vehicle sandbox.
- Enabled windowed mode for editor runs so the embedded Game view can sit beside live tuning properties.
- Moved all control instructions and race status UI into the menu, leaving the race view clear when closed.
- Updated the in-game control guide for the keyboard layout while preserving controller bindings and movement physics.
- Updated testing documentation to describe the current controls, handling values, and passing regression suites.

### Removed

- Removed the former controller diagnostics panel and thrust-envelope implementation and tests.

### Fixed

- Fixed steering from rest, braking near a stop, racer collisions, and submerged recovery.
- Preserved race momentum through pause and cleared forces and transient state on respawn.
- Fixed controller-only menu exits, profile-dialog focus loss, and map-switch lifecycle issues.
- Corrected camera reset timing and released audio resources during scene teardown.
