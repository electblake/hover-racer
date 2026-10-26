# 3D collision shapes

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use primitive shapes for moving bodies when possible. Use convex shapes or convex decomposition for complex moving objects and review concave meshes for static level collision.

## Constraints and compatibility

CollisionShape3D must be a direct child of its body and have a Shape3D resource. Concave/trimesh geometry has restrictions and is more expensive; detailed visual meshes need not be the collision meshes. Review Jolt margins and internal edges for track surfaces.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/collision_shapes_3d.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/collision_shapes_3d.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_3d.html) (moving alias)

## Sections in the captured source

- Primitive collision shapes
- Convex collision shapes
- Concave or trimesh collision shapes
- Performance caveats

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [BoxShape3D](https://docs.godotengine.org/en/4.7/classes/class_boxshape3d.html)
- [CapsuleShape3D](https://docs.godotengine.org/en/4.7/classes/class_capsuleshape3d.html)
- [CollisionShape3D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape3d.html)
- [ConcavePolygonShape3D](https://docs.godotengine.org/en/4.7/classes/class_concavepolygonshape3d.html)
- [ConvexPolygonShape3D](https://docs.godotengine.org/en/4.7/classes/class_convexpolygonshape3d.html)
- [CylinderShape3D](https://docs.godotengine.org/en/4.7/classes/class_cylindershape3d.html)
- [PhysicsBody3D](https://docs.godotengine.org/en/4.7/classes/class_physicsbody3d.html)
- [Shape3D](https://docs.godotengine.org/en/4.7/classes/class_shape3d.html)
- [SphereShape3D](https://docs.godotengine.org/en/4.7/classes/class_sphereshape3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
