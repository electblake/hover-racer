# 2D and 3D interpolation differences

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Check feature coverage before relying on interpolation for particles, server-created bodies or custom rendering. MultiMeshes are supported in both dimensions.

## Constraints and compatibility

The source lists CPUParticles2D support but not GPU 2D particle interpolation. get_global_transform_interpolated is 3D-only. 2D interpolation is implemented server-side; 3D is scene-side, so 3D bodies created directly through servers need manual interpolation.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/2d_and_3d_physics_interpolation.html) (moving alias)

## Sections in the captured source

- 2D Particles
- Other

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
