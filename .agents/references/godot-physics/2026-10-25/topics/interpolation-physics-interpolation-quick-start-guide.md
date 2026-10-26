# Interpolation quick start

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Enable Project Settings > Physics > Common > Physics Interpolation. Move objects and game logic during _physics_process, including movement caused by parents or other systems.

## Constraints and compatibility

Call reset_physics_interpolation after initial placement or teleportation. Temporarily test at 10 physics ticks per second to expose discontinuities; this is a diagnostic setting, not a suggested shipping simulation rate.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.html) (moving alias)

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
