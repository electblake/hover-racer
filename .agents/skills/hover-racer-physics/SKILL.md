---
name: hover-racer-physics
description: Ground Hover Racer physics implementation, debugging, tuning, and review in the project's local Godot references. Use for hover forces, handling, collisions, ray queries, physics backends, fixed-step simulation, and physics-related camera jitter.
---

# Hover Racer physics

Start physics work by reading the relevant local topic guides below, before proposing or changing physics behavior. Load only the topics needed for the request; follow each guide's **Local full source** link when exact behavior, caveats, or examples matter. Keep the existing reference bundle as the shared source rather than copying it into this skill.

All links are relative to this skill directory. The repository root is `../../..`.

## Route the task

| Task or symptom | Read first |
| --- | --- |
| Hover lift, suspension forces, thrust, steering torque, damping, rigid-body handling | [Rigid bodies](../../references/godot-physics/2026-10-25/topics/rigid-body.md); add [ray casting](../../references/godot-physics/2026-10-25/topics/ray-casting.md) for ground probes |
| Choosing the body type, layers/masks, materials, collision versus overlap | [Physics introduction](../../references/godot-physics/2026-10-25/topics/physics-introduction.md) |
| Backend choice, Jolt behavior, joints or migration | [Engine comparison](../../references/godot-physics/2026-10-25/topics/physics-engines.md), then [Jolt](../../references/godot-physics/2026-10-25/topics/using-jolt-physics.md) |
| Track geometry, ship collider, seams or contact cost | [3D collision shapes](../../references/godot-physics/2026-10-25/topics/collision-shapes-3d.md); add Jolt for margins/internal edges |
| Ground distance/normal, ray hits, masks, self-hits | [Ray casting](../../references/godot-physics/2026-10-25/topics/ray-casting.md) |
| Checkpoints, boost zones, local gravity/damping, overlap events | [Areas](../../references/godot-physics/2026-10-25/topics/using-area-2d.md); check the 3D API before translating the 2D examples |
| Script-controlled motion, slopes or slide response | [CharacterBody](../../references/godot-physics/2026-10-25/topics/using-character-body-2d.md); [kinematic foundations](../../references/godot-physics/2026-10-25/topics/kinematic-character-2d.md) when comparing motion models |
| High-speed tunneling, unstable contacts, physics overload | [Troubleshooting](../../references/godot-physics/2026-10-25/topics/troubleshooting-physics-issues.md), then the relevant shape/backend guide |
| Visual jitter, teleports, reset streaks | [Interpolation quick start](../../references/godot-physics/2026-10-25/topics/interpolation-physics-interpolation-quick-start-guide.md), then [applying interpolation](../../references/godot-physics/2026-10-25/topics/interpolation-using-physics-interpolation.md) |
| Follow camera jitter, mouse look or manual interpolation | [Advanced interpolation](../../references/godot-physics/2026-10-25/topics/interpolation-advanced-physics-interpolation.md) |
| Tick/frame timing or interpolation coverage | [Timing theory](../../references/godot-physics/2026-10-25/topics/interpolation-physics-interpolation-introduction.md); [2D/3D differences](../../references/godot-physics/2026-10-25/topics/interpolation-2d-and-3d-physics-interpolation.md) for particles or server-created bodies |
| Precision loss far from the origin | [Large world coordinates](../../references/godot-physics/2026-10-25/topics/large-world-coordinates.md) |
| Ragdolls or deformable objects | [Ragdolls](../../references/godot-physics/2026-10-25/topics/ragdoll-system.md) or [SoftBody3D](../../references/godot-physics/2026-10-25/topics/soft-body.md) |
| Explicitly 2D collision work | [2D collision shapes](../../references/godot-physics/2026-10-25/topics/collision-shapes-2d.md) |

For broader exploration use the [bundle topic index](../../references/godot-physics/2026-10-25/README.md) or [interpolation map](../../references/godot-physics/2026-10-25/topics/interpolation-index.md).

## Apply references to the actual project

Inspect the relevant scripts and scenes, [project.godot](../../../project.godot), and configured engine version before choosing an implementation. Determine the body's actual type, motion callback, selected backend, tick rate, collision geometry and query configuration as relevant to the task. Do not infer these from a tutorial or new-project defaults. Keep changes within the requested controller and backend unless the task calls for changing them.

For hovering issues, distinguish an incorrect ground query from an incorrect applied force. For jitter, distinguish simulated contact instability from presentation/camera interpolation. Raising the physics tick rate and enabling interpolation address different problems and have different costs.

Preserve these source-grounded distinctions:

- Use force integration for force-driven rigid bodies; repeatedly overwriting transforms can fight the simulation.
- Direct space queries belong in the physics callback. Collision layers, masks and exclusions affect what a probe sees.
- `move_and_collide` takes displacement; `move_and_slide` uses velocity and handles the timestep internally.
- Change collision shape dimensions rather than scaling physics nodes. Prefer suitable simple geometry for moving bodies.
- Reset interpolation after placement/teleportation. A child's interpolation mode does not cancel movement inherited from its parent.
- Physics is not guaranteed deterministic; verification should check behavior with meaningful tolerances.

When changing gameplay, use the existing [Hover Racer test skill](../hover-racer-test/SKILL.md) and its project tasks for relevant verification. Reading or editing reference documentation alone does not require running gameplay suites. State which local topics informed a material physics decision and distinguish documentation claims from observed test/runtime behavior.

## Version and evidence boundaries

The bundle is dated **2026-10-25** and identifies Godot **4.7** documentation at official `godotengine/godot-docs` commit `6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d`. It does not prove the installed binary's version. See [compatibility notes](../../references/godot-physics/2026-10-25/REFERENCE_SUMMARY.md) and [source provenance](../../references/godot-physics/2026-10-25/SOURCE_URLS.md).

Some troubleshooting paragraphs still call Godot Physics the default; the captured SoftBody and Jolt guides describe the newer Jolt default for new projects. Check actual project settings. Built-in Jolt and the older Jolt extension differ in settings and joint support.

The topic files are curated guides; their linked commit-pinned sources contain the complete original RST and examples. API class pages, media and demos are not mirrored. Use the local sources first; consult matching-version official API documentation for an uncovered detail or version mismatch. Keep any new evidence separate from this pinned snapshot unless a refresh is requested. A missing local file should be reported rather than silently replaced with remembered advice.
