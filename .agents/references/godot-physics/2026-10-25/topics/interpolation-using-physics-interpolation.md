# Applying physics interpolation

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Enable interpolation, move direct and indirect transform changes into physics ticks, choose an appropriate tick rate, and reset interpolation after teleportation.

## Constraints and compatibility

Audit movement caused by ancestors, animations and other systems, not just the script on the visible node. Test at a deliberately low tick rate to reveal streaking and inconsistent updates, then restore the chosen simulation rate.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/using_physics_interpolation.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/using_physics_interpolation.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/using_physics_interpolation.html) (moving alias)

## Sections in the captured source

- Turn on the physics interpolation setting
- Move (almost) all game logic from _process to _physics_process
- Ensure that all indirect movement happens during physics ticks
- Choose a physics tick rate
- Call `reset_physics_interpolation()` when teleporting objects
- Testing and debugging tips

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Camera3D](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html)
- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)
- [SceneTree](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
