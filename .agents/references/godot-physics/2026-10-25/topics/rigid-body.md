# Rigid bodies and force integration

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Start with RigidBody3D, one or more collision shapes, and a PhysicsMaterial. Set mass, friction and bounce, then control motion through forces and the _integrate_forces callback.

## Constraints and compatibility

Do not drive the body by overwriting its transform or calling look_at every rendered frame. The source includes a physics-compatible look-at example. Shape placement affects the center of mass; this matters when choosing where to apply forces.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/rigid_body.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/rigid_body.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/rigid_body.html) (moving alias)

## Sections in the captured source

- What is a rigid body?
- How to control a rigid body
- The "look at" method

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Node3D](https://docs.godotengine.org/en/4.7/classes/class_node3d.html)
- [PhysicsMaterial](https://docs.godotengine.org/en/4.7/classes/class_physicsmaterial.html)
- [Quaternion](https://docs.godotengine.org/en/4.7/classes/class_quaternion.html)
- [RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html)
- [Shape3D](https://docs.godotengine.org/en/4.7/classes/class_shape3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
