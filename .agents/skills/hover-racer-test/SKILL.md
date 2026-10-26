---
name: hover-racer-test
description: Run, extend, and interpret Hover Racer GUT tests through project mise tasks. Use after gameplay, input, UI, persistence, or scene changes and when checking regressions in this repository.
---

# Test Hover Racer

Run `mise run test` from the repository root for the full gate. It imports resources and runs the vendored GUT 9.7.1 suite with Godot 4.7. `mise.toml` owns executable selection, fixed delta, logs and timeouts; Windows uses `godot_console`. Do not substitute a custom runner.

For focused iteration, use `mise run test:unit`, `mise run test:integration`, or a behavior-specific task listed in [TESTING.md](../../../TESTING.md). Run `mise run test:import` after checkout or asset changes. `test:all` runs the full suite without import. Run the full gate before reporting verification complete.

`.gutconfig.json` discovers `test_*.gd` under `tests/unit/` and `tests/integration/`. Pure logic tests extend `GutTest`; scene tests extend `res://tests/support/game_test.gd`. Use named `test_<behavior>` methods and GUT assertions. Put fixture setup/cleanup in `before_each()`/`after_each()`, calling `super` when extending the project fixture. Each case must pass independently with fresh settings and scene state.

Register nodes with `add_child_autofree()` or `autofree()`. Integration fixtures select a fresh game-save namespace before gameplay loads and restore pause, input and viewport state afterward. Do not read, modify, or restore player settings. Release synthetic keys/buttons and use distinct input event instances for press/release. Advance physics frames for movement and process frames for UI/deferred cleanup; do not directly invoke `_physics_process()` or use wall-clock sleeps.

Use small fixtures for handling, `RefCounted` instances for envelope logic, and actual course scenes for geometry/UI contracts. Assert public behavior and transitions with meaningful tolerances; avoid tests that copy implementation formulas. New test files are discovered automatically. Add a focused mise task only when useful and update the coverage table.

Read the GUT summary and `.godot/test-*.log`. Report failing cases and unexpected engine errors; keep GUT error tracking enabled. The latest run writes `.godot/test-results.xml`; focused runs overwrite that report. Timeouts are failures. Do not retry unchanged failures or relax assertions just to get green output. Dependency provenance and upgrade instructions are in [tests/DEPENDENCIES.md](../../../tests/DEPENDENCIES.md).

Headless tests cover simulation, UI layout and playback state. Rendered appearance, audible mix, controller feel and physical key rollover need separate manual verification through `mise run play`.
