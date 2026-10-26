# Large worlds and floating-point precision

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use this guide when physics or rendering precision degrades far from the origin. Assess world scale and required precision before enabling double-precision builds.

## Constraints and compatibility

Large-world support requires compiling the editor and export templates with precision=double. Rebuild GDExtensions for the matching precision and keep multiplayer participants consistent. Some rendering paths, particles and shaders retain limitations; 2D rendering does not gain the same precision benefits.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/large_world_coordinates.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/large_world_coordinates.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/large_world_coordinates.html) (moving alias)

## Sections in the captured source

- Why use large world coordinates?
- How large world coordinates work
- Who are large world coordinates for?
- Enabling large world coordinates
- Compatibility between single-precision and double-precision builds
- Known incompatibilities
- Limitations

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [CPUParticles3D](https://docs.godotengine.org/en/4.7/classes/class_cpuparticles3d.html)
- [GPUParticles3D](https://docs.godotengine.org/en/4.7/classes/class_gpuparticles3d.html)
- [ResourceLoader](https://docs.godotengine.org/en/4.7/classes/class_resourceloader.html)
- [ResourceSaver](https://docs.godotengine.org/en/4.7/classes/class_resourcesaver.html)
- [Vector2](https://docs.godotengine.org/en/4.7/classes/class_vector2.html)
- [Vector3](https://docs.godotengine.org/en/4.7/classes/class_vector3.html)
- [Vector4](https://docs.godotengine.org/en/4.7/classes/class_vector4.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
