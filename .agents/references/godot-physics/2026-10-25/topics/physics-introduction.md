# Physics introduction

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use Area nodes for overlap detection and local influence, StaticBody for unmoving environment collision, RigidBody for force-driven simulation, and CharacterBody for scripted movement. Add collision shapes and explicitly assign layers and masks.

## Constraints and compatibility

Physics normally ticks at 60 Hz. Put physics logic in _physics_process and use delta where appropriate; use _integrate_forces for direct rigid-body state changes. Physics results are not guaranteed deterministic. Resize shape resources instead of scaling collision nodes.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/physics_introduction.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/physics_introduction.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html) (moving alias)

## Sections in the captured source

- Collision objects
- Physics material
- Collision shapes
- Physics process callback
- Collision layers and masks
- GUI example
- Code example
- Area2D
- StaticBody2D
- RigidBody2D
- Using RigidBody2D
- Contact reporting
- CharacterBody2D
- Character collision response
- :ref:`move_and_collide <class_PhysicsBody2D_method_move_and_collide>`
- :ref:`move_and_slide <class_CharacterBody2D_method_move_and_slide>`

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Area2D](https://docs.godotengine.org/en/4.7/classes/class_area2d.html)
- [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
- [CollisionObject2D](https://docs.godotengine.org/en/4.7/classes/class_collisionobject2d.html)
- [CollisionPolygon2D](https://docs.godotengine.org/en/4.7/classes/class_collisionpolygon2d.html)
- [CollisionShape2D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape2d.html)
- [KinematicCollision2D](https://docs.godotengine.org/en/4.7/classes/class_kinematiccollision2d.html)
- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [PhysicsBody2D](https://docs.godotengine.org/en/4.7/classes/class_physicsbody2d.html)
- [PhysicsDirectBodyState2D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectbodystate2d.html)
- [PhysicsMaterial](https://docs.godotengine.org/en/4.7/classes/class_physicsmaterial.html)
- [RigidBody2D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody2d.html)
- [Shape2D](https://docs.godotengine.org/en/4.7/classes/class_shape2d.html)
- [StaticBody2D](https://docs.godotengine.org/en/4.7/classes/class_staticbody2d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
