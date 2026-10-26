# Physics troubleshooting

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Identify the symptom first: tunneling, unstable stacks, scaled shapes, thin geometry, cylinders, fast vehicles, internal-edge bumps, contact cost, simulation overload or far-origin precision. Then read its dedicated source section.

## Constraints and compatibility

CCD, thicker colliders, simpler geometry and higher tick rates address different problems and have different costs. The page still calls GodotPhysics the default in some paragraphs; the Jolt and SoftBody pages explicitly document the newer Jolt default. Do not treat those older phrases as current default guidance.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/troubleshooting_physics_issues.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/troubleshooting_physics_issues.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/troubleshooting_physics_issues.html) (moving alias)

## Sections in the captured source

- Objects are passing through each other at high speeds
- Stacked objects are unstable and wobbly
- Scaled physics bodies or collision shapes do not collide correctly
- Thin objects are wobbly when resting on the floor
- Cylinder collision shapes are unstable
- VehicleBody simulation is unstable, especially at high speeds
- Collision results in bumps when an object moves across tiles
- Framerate drops when an object touches another object
- Framerate suddenly drops to a very low value beyond a certain amount of physics simulation
- Physics simulation is unreliable when far away from the world origin

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [ProjectSettings](https://docs.godotengine.org/en/4.7/classes/class_projectsettings.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
