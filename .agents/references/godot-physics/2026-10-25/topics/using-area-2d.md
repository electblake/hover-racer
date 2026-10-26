# Areas, overlaps and local influence

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Use an Area2D with a collision shape to detect entering or leaving objects. Configure collision layers/masks and monitoring behavior before connecting overlap signals.

## Constraints and compatibility

Areas detect and influence; they do not provide solid-body collision response. The guide covers gravity and damping overrides, override modes and priority, point gravity, and examples. Apply the concepts to Area3D only after checking the dimension-specific API.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_area_2d.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_area_2d.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/using_area_2d.html) (moving alias)

## Sections in the captured source

- Introduction
- What is an area?
- Area properties
- Overlap detection
- Area influence
- Point gravity
- Examples

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [Area2D](https://docs.godotengine.org/en/4.7/classes/class_area2d.html)
- [CollisionObject2D](https://docs.godotengine.org/en/4.7/classes/class_collisionobject2d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
