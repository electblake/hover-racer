# Ray casting and physics-space queries

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use RayCast2D/3D for persistent scene queries, or get_world_2d/3d().direct_space_state for scripted queries. Configure query endpoints, collision masks and exclusions.

## Constraints and compatibility

Access physics space during _physics_process, when space access is safe. Use world-space endpoints for direct queries. The guide covers self-exclusion, masks and converting screen coordinates through a 3D camera.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/ray-casting.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/ray-casting.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/ray-casting.html) (moving alias)

## Sections in the captured source

- Introduction
- Space
- Accessing space
- Raycast query
- Collision exceptions
- Collision Mask
- 3D ray casting from screen

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Camera3D](https://docs.godotengine.org/en/4.7/classes/class_camera3d.html)
- [CanvasItem](https://docs.godotengine.org/en/4.7/classes/class_canvasitem.html)
- [CollisionObject3D](https://docs.godotengine.org/en/4.7/classes/class_collisionobject3d.html)
- [Node](https://docs.godotengine.org/en/4.7/classes/class_node.html)
- [Node3D](https://docs.godotengine.org/en/4.7/classes/class_node3d.html)
- [PhysicsDirectSpaceState2D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate2d.html)
- [PhysicsDirectSpaceState3D](https://docs.godotengine.org/en/4.7/classes/class_physicsdirectspacestate3d.html)
- [PhysicsServer2D](https://docs.godotengine.org/en/4.7/classes/class_physicsserver2d.html)
- [PhysicsServer3D](https://docs.godotengine.org/en/4.7/classes/class_physicsserver3d.html)
- [RID](https://docs.godotengine.org/en/4.7/classes/class_rid.html)
- [RayCast2D](https://docs.godotengine.org/en/4.7/classes/class_raycast2d.html)
- [RayCast3D](https://docs.godotengine.org/en/4.7/classes/class_raycast3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
