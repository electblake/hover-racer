# Jolt Physics

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Select Jolt Physics in Project Settings > Physics > 3D > Physics Engine, then save and restart. Read the differences from Godot Physics before migrating an existing scene.

## Constraints and compatibility

Built-in since 4.4; new projects use it by default from 4.6. Joint soft-limit properties, world-joint orientation, collision margins, contact reporting, and ray face indices differ. Extension settings and custom Jolt joint nodes are not interchangeable with the built-in module.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_jolt_physics.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_jolt_physics.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html) (moving alias)

## Sections in the captured source

- Introduction
- Notable differences to Godot Physics
- Joint properties
- Single-body joints
- Collision margins
- Baumgarte stabilization
- Ghost collisions
- Memory usage
- Ray-cast face index
- Kinematic RigidBody3D contacts
- Contact impulses
- Area3D and SoftBody3D
- WorldBoundaryShape3D
- Notable differences to the Godot Jolt extension
- Project settings
- Joint nodes
- Thread safety

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Area3D](https://docs.godotengine.org/en/4.7/classes/class_area3d.html)
- [CollisionObject3D](https://docs.godotengine.org/en/4.7/classes/class_collisionobject3d.html)
- [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.7/classes/class_concavepolygonshape3d.html)
- [HeightMapShape3D](https://docs.godotengine.org/en/4.7/classes/class_heightmapshape3d.html)
- [Joint3D](https://docs.godotengine.org/en/4.7/classes/class_joint3d.html)
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html)
- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)
- [RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html)
- [SoftBody3D](https://docs.godotengine.org/en/4.7/classes/class_softbody3d.html)
- [WorldBoundaryShape3D](https://docs.godotengine.org/en/4.7/classes/class_worldboundaryshape3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
