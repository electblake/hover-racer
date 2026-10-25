# Hover Racer — keyboard and controller controls

Reopen the project after input-map changes, then run Main with F6. Preserve any unsaved editor work separately before reloading external edits.

## Controls

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

Burst on the gas, release it to glide while lining up a turn, then reapply gas to pull toward the new nose direction. Off-throttle turning does not redirect horizontal velocity. Passive drag reduces speed at 26 m/s²: a four-second stop from 104 m/s. Steering does not disable drag. LT/Shift adds 100 m/s² of braking at full input, stopping from top speed in about 0.83 seconds including passive drag. Thrust acceleration is 300 m/s² and horizontal speed is capped at 104 m/s.

One full stick turns at 0.9 rad/s; both turn at 1.8 rad/s. Mesh bank is smoothed up to 36 degrees during normal steering and capped at 50 degrees with sharp-turn assistance. Stronger visual yaw gives a boat-like stern swing (up to about 17 degrees off gas, reduced under power). These visuals do not tilt or offset the physical collider or rotate the camera independently. The existing coasting skip and hover bob remain subtle mesh motion.

The saved course is approximately 918 metres long and 28 metres wide, with six rounded corners, a dogleg, and hills rising 10 and 14 metres. Hover suspension follows road collisions. The canyon slice adds close cliffs, repeated lit posts, ground rocks and three overhead arches while preserving road and camera clearance. Falling off the course resets the ship.

The original local low-poly model has separated gold/blue engine pods, a trailing cockpit, tethers, an energy linkage and rotating intake blades. Its collider is 3.1 × 0.4 × 4.6 metres. Both engines now respond together to RT, including their exhausts. Engine audio stays disabled; original audio assets are retained. Subdued wind follows actual horizontal speed and stops at rest.

The chase camera frames both engines and cockpit. Thrust adds a smooth pullback of 1.1 metres plus a brief onset cue up to 0.4 metres; release returns to the resting position. FOV changes by at most 12 degrees (4 from speed, 6 from sustained gas, 2 from onset). There is no camera shake, roll or bob.

## Verification

```
Godot --headless --fixed-fps 60 --path . --script res://tests/controller_input.gd
Godot --headless --fixed-fps 60 --path . --script res://tests/neutral_coast.gd
Godot --headless --fixed-fps 60 --path . --script res://tests/hill_course.gd
Godot --headless --fixed-fps 60 --path . --script res://tests/canyon_podracer.gd
```

Simulated input tests cover single/additive steering, signs, cancellation, analog magnitudes/deadzones, vertical bindings and sharp-turn diagonal parity, independent off-gas facing/travel, gas reapplication, air braking, speed cap, keyboard and reset. The neutral test verifies the four-second stop and absence of unintended power. Hill tests traverse both actual hills under power at the cap. Canyon tests check 470 clearance samples, model/exhaust, audio mute/wind and restrained camera effects. Physical controller feel, sound balance and comfort need an in-game test.

`tools/build_course.gd` regenerates TestTrack.tscn and course_samples.json, replacing manual course edits. `tools/build_canyon.gd` regenerates the independent CanyonSlice.tscn. Back up before regenerating. Files before the current control change are in `backups/before-trigger-additive-steering`, with `.bak` suffixes.

## Stronger power/coast contrast

Acceleration is 300 (previously 145), with a 104 m/s cap. Straight-line launch reaches 30 m/s in 0.1 seconds and the cap in about 0.35 seconds. Passive slowing is 26 m/s², stopping from the cap in four seconds. Active gas, airbrake, additive steering and independent off-gas heading are unchanged.

Camera power response is faster and more visible: 1.1m sustained pullback, up to 0.4m additional visual onset, with a total bound of 1.5m. Onset is visual only; repeated taps cannot stack velocity boosts or unbounded camera movement. FOV has a 12-degree total bound and decreases clearly on release; camera rotation is stable and shake-free. Exhaust plumes and power pitch are stronger. Engine audio stays disabled and quiet wind remains.

```
Godot --headless --fixed-fps 60 --path . --script res://tests/power_contrast.gd
```

This checks measured launch against the prior acceleration, camera/FOV onset and return, bounded per-frame camera movement, release contrast, repeated-tap caps and reset. Controller comfort still needs in-game testing. Backup: `backups/before-launch-camera-contrast`.

Reference: the official developer article, “Feel the Speed: Game Feel in STAR WARS: Galactic Racer,” discusses responsive physical feedback and hover/speed challenges: https://starwarsgalacticracer.com/news/feel-the-speed-game-feel-in-star-wars-galactic-racer/ . The official gameplay trailer article was also read; trailer playback was not available in this tool session, so the video was not watched.

## Keyboard implementation verification

All five headless suites passed on Godot 4.7.2 with zero failures: controller_input, neutral_coast, power_contrast, hill_course and canyon_podracer. Input tests exercise physical-key events and joypad events, including full/independent steering, cancellation, every vertical key, sharp-turn parity, gas/brake precedence, released inputs, controller analog input after keyboard release, and Y/R reset.

Manual check: run `mise run play`, drive using Space+Left/Right+Down, release Down mid-turn, brake with Shift, and reset with R. Check the independent stick keys and repeat with a physical controller. Physical keyboard rollover and controller feel require this hands-on check.