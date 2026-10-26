# 2D collision shapes

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Attach CollisionShape2D or CollisionPolygon2D directly to the physics body and assign a shape resource. Prefer primitive shapes for moving bodies, then consider convex geometry when needed.

## Constraints and compatibility

Indirect child collision nodes are ignored. Shapes on one body may overlap without colliding with each other. Review concave-shape restrictions and performance before using detailed level geometry.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/collision_shapes_2d.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/collision_shapes_2d.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/collision_shapes_2d.html) (moving alias)

## Sections in the captured source

- Primitive collision shapes
- Convex collision shapes
- Concave or trimesh collision shapes
- Performance caveats

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [CapsuleShape2D](https://docs.godotengine.org/en/4.7/classes/class_capsuleshape2d.html)
- [CircleShape2D](https://docs.godotengine.org/en/4.7/classes/class_circleshape2d.html)
- [CollisionPolygon2D](https://docs.godotengine.org/en/4.7/classes/class_collisionpolygon2d.html)
- [CollisionShape2D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape2d.html)
- [ConcavePolygonShape2D](https://docs.godotengine.org/en/4.7/classes/class_concavepolygonshape2d.html)
- [ConvexPolygonShape2D](https://docs.godotengine.org/en/4.7/classes/class_convexpolygonshape2d.html)
- [PhysicsBody2D](https://docs.godotengine.org/en/4.7/classes/class_physicsbody2d.html)
- [RectangleShape2D](https://docs.godotengine.org/en/4.7/classes/class_rectangleshape2d.html)
- [SegmentShape2D](https://docs.godotengine.org/en/4.7/classes/class_segmentshape2d.html)
- [SeparationRayShape2D](https://docs.godotengine.org/en/4.7/classes/class_separationrayshape2d.html)
- [Shape2D](https://docs.godotengine.org/en/4.7/classes/class_shape2d.html)
- [WorldBoundaryShape2D](https://docs.godotengine.org/en/4.7/classes/class_worldboundaryshape2d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
