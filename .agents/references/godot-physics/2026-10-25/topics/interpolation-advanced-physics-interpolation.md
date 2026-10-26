# Advanced interpolation and cameras

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use physics_interpolation_mode for branches requiring manual control. For camera work, study the global-space example and get_global_transform_interpolated before implementing manual interpolation.

## Constraints and compatibility

In this snapshot both 2D and 3D interpolate local transforms. A child with interpolation disabled can still move smoothly through its interpolated parent. Avoid accidentally applying interpolation twice. The source also covers mouse look and MultiMeshes.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/advanced_physics_interpolation.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/advanced_physics_interpolation.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/advanced_physics_interpolation.html) (moving alias)

## Sections in the captured source

- Exceptions to automatic physics interpolation
- Cameras
- Manual camera interpolation
- Ensure the camera is using global coordinate space
- Typical example
- get_global_transform_interpolated()
- Example manual camera script
- Mouse look
- Disabling interpolation on other nodes
- MultiMeshes

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Camera3D](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html)
- [MultiMesh](https://docs.godotengine.org/en/4.7/classes/class_multimesh.html)
- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [Node3D](https://docs.godotengine.org/en/4.7/classes/class_node3d.html)
- [SceneTree](https://docs.godotengine.org/en/4.7/classes/class_scenetree.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
