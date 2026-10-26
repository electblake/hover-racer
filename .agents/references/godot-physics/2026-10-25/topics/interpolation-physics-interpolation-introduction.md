# Interpolation timing and theory

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Understand the separation between fixed physics ticks and variable rendered frames. Interpolate previous and current physics transforms using the interpolation fraction.

## Constraints and compatibility

Interpolation renders between known states in the past rather than predicting an unknown future state. It smooths visible motion and has a timing/latency tradeoff. Raising rendering FPS alone does not increase physics tick frequency.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_introduction.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_introduction.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html) (moving alias)

## Sections in the captured source

- Physics ticks and rendered frames
- What can we do about frames and ticks being out of sync?
- Lock the tick / frame rate together?
- Adapt the tick rate?
- Lock the tick rate, but use interpolation to smooth frames in between physics ticks
- Linear interpolation
- The physics interpolation fraction
- Calculating the interpolated position
- Smoothed transformations between physics ticks?
- In the past
- Why look into the past? Why not predict the future?
- Fixed timestep interpolation

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Engine](https://docs.godotengine.org/en/4.7/classes/class_engine.html)
- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
