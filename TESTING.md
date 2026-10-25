# Hover Racer — trigger throttle and additive steering

Reopen the project after input-map changes, then run Main with F6. Preserve any unsaved editor work separately before reloading external edits.

## Controls

- RT: analog gas; both engine pods share throttle.
- LT: analog air brake. Full brake overrides simultaneous gas.
- Left stick horizontal: moderate continuous yaw and bank.
- Right stick horizontal: the same contribution, added to the left stick.
- Both sticks together: twice one stick's turn rate. Opposed horizontal inputs cancel.
- Stick vertical axes: unused. The previous absolute-heading/differential-thruster controls are removed.
- Keyboard: W gas, S air brake, A/D left-stick steering, Left/Right arrows right-stick steering. Both keyboard steering sets add just like the sticks.
- Y/R resets the ship, visuals, camera and audio.

Stick horizontal deadzone is 0.18; trigger deadzone is 0.06, with proportional response outside the deadzone. Holding a steering input rotates continuously; it does not aim at a fixed heading.

## Handling

Burst on the gas, release it to glide while lining up a turn, then reapply gas to pull toward the new nose direction. Off-throttle turning does not redirect horizontal velocity. Passive drag reduces speed at 17 m/s²: about a three-second stop from 52 m/s. Steering does not disable drag. LT adds 60 m/s² of braking at full input, stopping from top speed in about 0.68 seconds. Thrust acceleration is 300 m/s² and horizontal speed is capped at 52 m/s.

One full stick turns at 0.9 rad/s; both turn at 1.8 rad/s. Mesh bank is smoothed up to 36 degrees. Stronger visual yaw gives a boat-like stern swing (up to about 17 degrees off gas, reduced under power). These visuals do not tilt or offset the physical collider or rotate the camera independently. The existing coasting skip and hover bob remain subtle mesh motion.

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

Simulated input tests cover single/additive steering, signs, cancellation, analog magnitudes/deadzones, ignored vertical axes, independent off-gas facing/travel, gas reapplication, air braking, speed cap, keyboard and reset. The neutral test verifies the three-second stop and absence of unintended power. Hill tests traverse both actual hills under power at the cap. Canyon tests check 470 clearance samples, model/exhaust, audio mute/wind and restrained camera effects. Physical controller feel, sound balance and comfort need an in-game test.

`tools/build_course.gd` regenerates TestTrack.tscn and course_samples.json, replacing manual course edits. `tools/build_canyon.gd` regenerates the independent CanyonSlice.tscn. Back up before regenerating. Files before the current control change are in `backups/before-trigger-additive-steering`, with `.bak` suffixes.

## Stronger power/coast contrast

Acceleration is now 300 (previously 145), while the cap remains 52. Straight-line launch reaches 30 m/s in 0.1 seconds and the cap in about 0.18 seconds. Passive slowing is 17 (previously 13), stopping from the cap in about 3.07 seconds. Active gas, airbrake, additive steering and independent off-gas heading are unchanged.

Camera power response is faster and more visible: 1.1m sustained pullback, up to 0.4m additional visual onset, with a total bound of 1.5m. Onset is visual only; repeated taps cannot stack velocity boosts or unbounded camera movement. FOV has a 12-degree total bound and decreases clearly on release; camera rotation is stable and shake-free. Exhaust plumes and power pitch are stronger. Engine audio stays disabled and quiet wind remains.

```
Godot --headless --fixed-fps 60 --path . --script res://tests/power_contrast.gd
```

This checks measured launch against the prior acceleration, camera/FOV onset and return, bounded per-frame camera movement, release contrast, repeated-tap caps and reset. Controller comfort still needs in-game testing. Backup: `backups/before-launch-camera-contrast`.

Reference: the official developer article, “Feel the Speed: Game Feel in STAR WARS: Galactic Racer,” discusses responsive physical feedback and hover/speed challenges: https://starwarsgalacticracer.com/news/feel-the-speed-game-feel-in-star-wars-galactic-racer/ . The official gameplay trailer article was also read; trailer playback was not available in this tool session, so the video was not watched.
