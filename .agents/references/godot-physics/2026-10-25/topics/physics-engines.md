# Physics engines and backend selection

Godot 4.7 documentation snapshot | 2026-10-25

This is a curated comparison of engines discussed in the captured official physics chapter, not a catalog of third-party extensions.

| Engine | Scope in this reference | Starting point |
| --- | --- | --- |
| Godot Physics | Built-in physics; the chapter covers 2D and 3D bodies and contrasts its 3D behavior with Jolt | [Physics introduction](physics-introduction.md) |
| Jolt Physics | Built-in 3D alternative since 4.4; default for new projects from 4.6 | [Jolt guide](using-jolt-physics.md) |
| Godot Jolt extension | Earlier extension, now in maintenance mode; custom joints and configuration differ from the built-in module | [Migration differences](using-jolt-physics.md) |
| Bullet | Historical context: the troubleshooting guide describes the transition away from Bullet in Godot 4 | [Troubleshooting](troubleshooting-physics-issues.md) |

## Choosing a starting path

For 3D engine selection, use Project Settings > Physics > 3D > Physics Engine and save/restart. Do not infer an existing project's engine from the default for new projects. Jolt's 3D setting does not select a 2D backend.

Choose a body separately from the backend: RigidBody for forces and simulation, CharacterBody for authored movement, StaticBody for fixed collision, and Area for overlap/influence. Neither backend guarantees deterministic replay.

Before moving an existing scene to Jolt, review joint properties and world-body conventions, collision margins, internal-edge removal, ray face indices, frozen-body contact reporting, estimated contact impulses, and soft-body/area interactions. The extension's custom Jolt joint nodes are not included in the built-in module. The guide labels separate-thread support experimental.

## Suggested Hover Racer reading path

This is a project-oriented suggestion, not an observation of the current runtime: [rigid-body control](rigid-body.md), [ray casting](ray-casting.md), [3D collision geometry](collision-shapes-3d.md), [Jolt differences](using-jolt-physics.md), [high-speed troubleshooting](troubleshooting-physics-issues.md), then [camera interpolation](interpolation-advanced-physics-interpolation.md).

Use the CharacterBody guide instead when the intended controller is explicitly script-driven. These references do not prescribe or change the project's current controller.

## Evidence and version caveat

The linked Jolt, SoftBody and troubleshooting guides contain the supporting official source links. The SoftBody page explicitly dates the Jolt default to 4.6; some troubleshooting paragraphs still call GodotPhysics the default. Preserve that inconsistency rather than silently rewriting the upstream source.

[All topics](../README.md)
