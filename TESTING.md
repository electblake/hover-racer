# Hover Racer — keyboard and controller controls

Reopen the project after input-map changes, then run Main with F6. Preserve any unsaved editor work separately before reloading external edits.

## Controls

The compact **Vehicle sandbox** is restored as an embedded Godot window. Drag its title bar to move it and its outer borders/corners to resize it. The scrollable form exposes acceleration, maximum speed, thrust ADSR, turn speed/boost/acceleration/deceleration, and stick deadzone using linked sliders and spinboxes. Close it with X and reopen it via **Controls → Show vehicle sandbox**. Tuning, visibility, position and size persist in `user://vehicle_sandbox.cfg`. The sandbox hides while the game menu is open.

Sandbox regression coverage includes native embedded-window mouse dragging/resizing, live values, saved tuning and geometry across scene recreation, and closing/reopening. Mouse tests submit viewport-local coordinates to Godot's embedded-window input path.

- The game menu opens paused with **New Race** selected. New Race resets the vehicle and starts driving; **Controls** opens the controls panel. During a race, Escape or controller Menu/Start opens the game menu with **Resume Race** selected. Resume preserves the current run; New Race restarts it with current tuning intact.
- Navigate with arrows/D-pad and confirm with Enter/controller A. Back, Escape, controller B, or Menu/Start returns from Controls to the game menu while remaining paused. Escape/Menu resumes an active race from the game menu; the initial screen stays paused until New Race is selected. The thrust meter appears while racing.
- Driving and reset inputs do not affect the ship while the menu is open. Releasing a held input during pause is respected on resume. Holding Escape does not repeatedly toggle the menu.
- RT: analog gas; both engine pods share throttle.
- LT: analog air brake. Full brake overrides simultaneous gas.
- Left stick horizontal: moderate continuous yaw and bank.
- Right stick horizontal: the same contribution, added to the left stick.
- Both sticks together: twice one stick's turn rate. Opposed horizontal inputs cancel.
- Pull the inside stick down while steering for a sharper turn and stronger bank. Vertical input alone does not turn or propel the ship. Stick-up input participates in radial normalization and cancels pull-down on the same stick.
- Main keyboard controls: Spacebar thrust, Shift air brake, Left/Right arrows full steering (both virtual sticks), Down arrow sharp turn, Up arrow pushes both sticks up. Down pulls both sticks down; the inside stick supplies turn assistance.
- WASD are modifiers: W pushes both sticks up, S pulls both down for sharp turns, A/D pull the left/right stick down independently. Q/E also pull the left/right stick down.
- I/J/K/L control the left stick up/left/down/right. T/F/G/H control the right stick up/left/down/right. Independent horizontal keys contribute half the full steering rate; opposed inputs cancel.
- Left/Right arrows plus a same-direction independent stick key do not exceed full steering. Keyboard diagonals use the same radial normalization as controller diagonals.
- Keyboard keys are digital; controller triggers and sticks retain analog response. Both devices remain available without a mode switch.
- Y/R resets the ship, visuals, camera and audio.

Stick horizontal deadzone is 0.18; trigger deadzone is 0.06, with proportional response outside the deadzone. Holding a steering input rotates continuously; it does not aim at a fixed heading.

## Handling

Tune the vehicle through Godot's Inspector. In `Main.tscn`, select `SHIP`: its exported properties are grouped into Drive, Thrust Envelope, Steering, Visual Banking and Pitch, Input, Camera, and Hover. Hover over the envelope and steering fields for descriptions and units.

For persistent live tuning, run `mise run editor`, enable **Debug > Synchronize Scene Changes**, and press **F5**. Start **New Race**. While it runs, select `SHIP` in the **Local** scene tree, edit its Inspector properties, and save `Main.tscn`. Godot synchronizes those edits to the running vehicle and the saved scene keeps them for the next run. Editing a script's default initializer is not the same as editing an instance property.

For temporary experiments, select `root/Node3D/SHIP` in the **Remote** scene tree. Its Inspector edits affect only the current run; copy any values you want to keep into the Local `SHIP` and save the scene. The embedded Game view also provides 3D selection, pause, frame advance, and slow motion. Use Input mode again to drive after selecting objects.

The editor feature override uses windowed mode so Godot can embed the game. In the Game toolbar menu, enable **Embed Game on Next Play** and disable **Make Window Floating on Next Play** to keep the game and Inspector together. Exported games retain the maximized startup mode.

The custom sandbox editor and its autosave loaders have been removed. Existing `user://vehicle_settings.cfg`, `steering_settings.cfg`, `drive_settings.cfg`, and `sandbox_window.cfg` files are left on disk but are no longer read or written by gameplay. Scene properties and script defaults now determine startup tuning. `mise run play` remains available for standalone play; use the editor's F5 run for an attached Remote Inspector.

Steering defaults are 1.8 rad/s turn speed, 3 rad/s sharp-turn boost, 36 rad/s² turn acceleration, 48 rad/s² turn deceleration, and 0.18 radial stick deadzone. Higher acceleration gives faster onset/reversal; higher deceleration stops turning sooner on release. `mise run test:steering` checks runtime property edits, angular acceleration, sustained rate, release, reversal, and reset.

References: [Godot live scene/script synchronization and Remote Inspector](https://docs.godotengine.org/en/latest/tutorials/scripting/debug/overview_of_debugging_tools.html), [embedded Game tools and persistence](https://docs.godotengine.org/en/latest/tutorials/editor/game_embedding.html).

Thrust has an ADSR envelope: 0.12 s attack, 0.18 s decay, 92% sustain, and a smooth 0.28 s release. Analog gas scales the envelope. Full brake overrides propulsion immediately. Passive coasting begins once released thrust reaches zero; reset clears the envelope. Default launch reaches about 14.6 m/s after 0.1 s and the speed cap in about 0.42 s.

The bottom-right segmented meter shows actual applied thrust after braking, not speed or raw gas input. Empty segments are dark, followed by green, yellow and red ranges as thrust rises.

`mise run test:unit` covers envelope timing, retriggering, analog gas and sustain endpoints. `mise run test:thrust` covers authored tuning, ignored legacy settings, temporary runtime edits, live acceleration/speed-cap changes, actual acceleration/meter agreement, brake override, reset, and HUD layout at 640×480, 1280×720 and 1920×1080. Tests use fresh isolated settings and never read or restore player tuning.

Burst on the gas, release it to glide while lining up a turn, then reapply gas to pull toward the new nose direction. Off-throttle turning does not redirect horizontal velocity. Passive drag reduces speed at 26 m/s²: a four-second stop from 104 m/s. Steering does not disable drag. LT/Shift adds 100 m/s² of braking at full input, stopping from top speed in about 0.83 seconds including passive drag. Thrust acceleration is 300 m/s² and horizontal speed is capped at 104 m/s.

One full stick turns at 0.9 rad/s; both turn at 1.8 rad/s. Mesh bank is smoothed up to 36 degrees during normal steering and capped at 50 degrees with sharp-turn assistance. Stronger visual yaw gives a boat-like stern swing (up to about 17 degrees off gas, reduced under power). These visuals do not tilt or offset the physical collider or rotate the camera independently. The existing coasting skip and hover bob remain subtle mesh motion.

The saved course is approximately 918 metres long and 28 metres wide, with six rounded corners, a dogleg, and hills rising 10 and 14 metres. Hover suspension follows road collisions. The canyon slice adds close cliffs, repeated lit posts, ground rocks and three overhead arches while preserving road and camera clearance. Falling off the course resets the ship.

The original local low-poly model has separated gold/blue engine pods, a trailing cockpit, tethers, an energy linkage and rotating intake blades. Its collider is 3.1 × 0.4 × 4.6 metres. Both engines now respond together to RT, including their exhausts. Engine audio stays disabled; original audio assets are retained. Subdued wind follows actual horizontal speed and stops at rest.

The chase camera frames both engines and cockpit. Thrust adds a smooth pullback of 1.1 metres plus a brief onset cue up to 0.4 metres; release returns to the resting position. FOV changes by at most 12 degrees (4 from speed, 6 from sustained gas, 2 from onset). There is no camera shake, roll or bob.

## Verification

Run from the repository root with mise and the Godot 4.7 editor installed on PATH (verified with 4.7.2). Windows test tasks use `godot_console` from the Godot installation for synchronous console output and exit status; interactive tasks still use `godot`.

```powershell
mise run test
```

This imports resources and runs GUT 9.7.1, vendored under `addons/gut` for Godot 4.7. `.gutconfig.json` discovers `test_*.gd` in `tests/unit/` and `tests/integration/`. GUT owns assertions, test lifecycle, engine-error tracking, exit codes, and JUnit output. The full run has a 120-second timeout; focused scripts have 60 seconds. The addon is included in the repository, so no test-time download is needed. See [dependency provenance](tests/DEPENDENCIES.md).

Layout:

```text
tests/
  unit/test_thrust_envelope.gd   # RefCounted logic, no scene
  integration/test_*.gd         # Input, physics, UI, persistence, course
  support/game_test.gd          # Fresh settings and global-state cleanup
```

Use `mise run test:unit` or `mise run test:integration` for a whole layer. `mise run test:all` runs both layers without reimporting. New files matching the naming convention are discovered automatically; a dedicated mise task is optional.

For focused work, run `mise run test:import` after a fresh checkout or asset changes, then select a task:

| Task | Coverage |
| --- | --- |
| `test:unit` | Pure ADSR logic: attack/decay/sustain/release, analog input, retrigger, reset, bounds, 30/60/120 Hz steps |
| `test:thrust` | Authored defaults, ignored legacy settings, temporary runtime edits, live drive limits, physics-driven thrust, HUD, braking, reset, three viewport sizes |
| `test:steering` | Live steering properties, acceleration/deceleration, reversal, reset |
| `test:menu` | Startup pause, Escape/Start, echo suppression, blocked driving/reset, released input on resume, responsive layout |
| `test:controller` | Physical keyboard/joypad bindings, analog/deadzones, additive/opposed steering, sharp turns, braking, speed cap, reset |
| `test:coast` | Neutral/noisy input, monotonic drag, preserved travel direction, four-second stop, audio/exhaust state |
| `test:power` | Launch timing, speed cap, bounded camera/FOV, release and repeated taps |
| `test:fall` | Off-course fall reset, restored heading/momentum/thrust/camera, subsequent acceleration |
| `test:hills` | Saved course cross sections/barriers, both hills at speed, hover clearance, level collider |
| `test:canyon` | 470 clearance positions, ship envelope/model, exhaust, audio resources and playback state |

GUT prints named cases, assertion counts, failures and a final run summary. The most recent run writes `.godot/test-results.xml` in JUnit format; task logs are `.godot/test-*.log`. Assertions and unexpected engine/script errors produce a failing exit status. Do not disable error tracking or use `--quit-after` as a success gate. Focused runs replace the JUnit report, so use the full task for the final verification artifact.

Integration tests inherit `tests/support/game_test.gd`, which selects fresh game settings before each test and restores pause, input and viewport state afterward. Pure unit tests extend `GutTest`. Test methods are named `test_<behavior>`; use `before_each()`/`after_each()` for fresh fixtures, calling `super` when extending the project fixture. Register scene ownership with `add_child_autofree()` so GUT also cleans up after an interrupted test. Existing explicit scene frees allow deferred teardown to complete before the next case.

Gameplay tests advance real physics frames at 60 Hz with fixed delta; unit tests supply explicit deltas. UI/layout work waits for process frames. No direct `_physics_process()` calls or wall-clock sleeps are needed. Reset bindings are checked immediately after input dispatch, before suspension advances the vehicle. Input events use distinct instances for press and release. Tests retain behavioral tolerances and cover transitions without depending on a previous test's state.

Each test-data namespace is separate from player tuning; test settings remain available under `Hover Racer Tests-*` in Godot's user-data directory. GUT may use its own temporary-output directory as reported at startup. Headless tests verify layout and playback state, not rendered appearance, audible mix, controller feel or physical keyboard rollover.

References: [GUT 9.7.1 CLI](https://gut.readthedocs.io/en/v9.7.1/Command-Line.html), [GUT test lifecycle](https://gut.readthedocs.io/en/v9.7.1/Creating-Tests.html), [Godot frame signals](https://docs.godotengine.org/en/stable/classes/class_scenetree.html), and [mise task timeouts](https://mise.jdx.dev/tasks/task-configuration). Agent workflow: [.agents/skills/hover-racer-test/SKILL.md](.agents/skills/hover-racer-test/SKILL.md).

Simulated input tests cover single/additive steering, signs, cancellation, analog magnitudes/deadzones, vertical bindings and sharp-turn diagonal parity, independent off-gas facing/travel, gas reapplication, air braking, speed cap, keyboard and reset. The neutral test verifies the four-second stop and absence of unintended power. Hill tests traverse both actual hills under power at the cap. Canyon tests check 470 clearance samples, model/exhaust, audio mute/wind and restrained camera effects. Physical controller feel, sound balance and comfort need an in-game test.

`tools/build_course.gd` regenerates TestTrack.tscn and course_samples.json, replacing manual course edits. `tools/build_canyon.gd` regenerates the independent CanyonSlice.tscn. Back up before regenerating. Files before the current control change are in `backups/before-trigger-additive-steering`, with `.bak` suffixes.

## Stronger power/coast contrast

Acceleration is 300 (previously 145), with a 104 m/s cap. With the thrust envelope, straight-line launch reaches about 14.6 m/s in 0.1 seconds and the cap in about 0.42 seconds. Passive slowing is 26 m/s², stopping from the cap in four seconds. Active gas, airbrake, additive steering and independent off-gas heading are unchanged.

Camera power response is faster and more visible: 1.1m sustained pullback, up to 0.4m additional visual onset, with a total bound of 1.5m. Onset is visual only; repeated taps cannot stack velocity boosts or unbounded camera movement. FOV has a 12-degree total bound and decreases clearly on release; camera rotation is stable and shake-free. Exhaust plumes and power pitch are stronger. Engine audio stays disabled and quiet wind remains.

```
mise run test:power
```

This checks measured launch against the prior acceleration, camera/FOV onset and return, bounded per-frame camera movement, release contrast, repeated-tap caps and reset. Controller comfort still needs in-game testing. Backup: `backups/before-launch-camera-contrast`.

Reference: the official developer article, “Feel the Speed: Game Feel in STAR WARS: Galactic Racer,” discusses responsive physical feedback and hover/speed challenges: https://starwarsgalacticracer.com/news/feel-the-speed-game-feel-in-star-wars-galactic-racer/ . The official gameplay trailer article was also read; trailer playback was not available in this tool session, so the video was not watched.

## Keyboard implementation verification

All five headless suites passed on Godot 4.7.2 with zero failures: controller_input, neutral_coast, power_contrast, hill_course and canyon_podracer. Input tests exercise physical-key events and joypad events, including full/independent steering, cancellation, every vertical key, sharp-turn parity, gas/brake precedence, released inputs, controller analog input after keyboard release, and Y/R reset.

Manual check: run `mise run play`, close the startup menu with Escape or Menu/Start, drive using Space+Left/Right+Down, release Down mid-turn, brake with Shift, and reset with R. Open the menu while moving and verify the race pauses; close it and verify the race resumes with the thrust meter visible. Check the independent stick keys and repeat with a physical controller. Physical keyboard rollover and controller feel require this hands-on check.

The menu suite and all five existing regression suites passed after the pause-menu change. Movement suites explicitly close the startup menu before exercising physics. Menu tests cover startup visibility, Escape/Menu toggles, keyboard repeat, frozen movement, blocked reset, gas released during pause, and layout at three window sizes using the scaled logical viewport. The running game's default menu layout was also visually inspected.

Controller diagnostics: tests/integration/test_controller_diagnostics.gd covers live input meters, menu isolation, button and signed-axis remapping, keyboard preservation, saved bindings, cancellation, and small viewport layout. Physical controller recognition and feel require manual verification.
