# CharacterBody movement and collision

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Implement motion in code and move through move_and_collide or move_and_slide. Use collision results to implement sliding, reflection, wall interaction or platformer motion.

## Constraints and compatibility

Character bodies do not automatically respond to gravity and friction. move_and_collide takes a motion displacement; move_and_slide uses the body velocity and handles the timestep internally. Do not multiply that velocity by delta a second time.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_character_body_2d.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/using_character_body_2d.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/using_character_body_2d.html) (moving alias)

## Sections in the captured source

- Introduction
- What is a character body?
- Movement and collision
- move_and_collide
- move_and_slide
- Detecting collisions
- Which movement method to use?
- Examples
- Movement and walls
- Bouncing/reflecting
- Platformer movement

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [CharacterBody2D](https://docs.godotengine.org/en/4.7/classes/class_characterbody2d.html)
- [KinematicCollision2D](https://docs.godotengine.org/en/4.7/classes/class_kinematiccollision2d.html)
- [Polygon2D](https://docs.godotengine.org/en/4.7/classes/class_polygon2d.html)
- [StaticBody2D](https://docs.godotengine.org/en/4.7/classes/class_staticbody2d.html)
- [Vector2](https://docs.godotengine.org/en/4.7/classes/class_vector2.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
