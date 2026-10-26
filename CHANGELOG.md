# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

- Migrated regression scripts to discoverable GUT suites and expanded mise test tasks.
- Grouped vehicle tuning properties in the Godot Inspector alongside the in-game vehicle sandbox.
- Enabled windowed mode for editor runs so the embedded Game view can sit beside live tuning properties.
- Moved all control instructions and race status UI into the menu, leaving the race view clear when closed.
- Updated the in-game control guide for the keyboard layout while preserving controller bindings and movement physics.
- Updated testing documentation to describe the current controls, handling values, and passing regression suites.
