# Ragdolls and physical bones

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Generate a physical skeleton from Skeleton3D, then tune PhysicalBone3D children under PhysicalBoneSimulator3D. Remove unnecessary simulated bones and adjust shapes and joint limits.

## Constraints and compatibility

Start simulation through the simulator and configure collision layers/masks to prevent unwanted interaction with the character controller. Review the Jolt joint-property differences when using Jolt. Linked demo projects are external to this capture.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/ragdoll_system.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/ragdoll_system.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/ragdoll_system.html) (moving alias)

## Sections in the captured source

- Introduction
- Setting up the ragdoll
- Creating physical bones
- Clean up and optimize the skeleton
- Adjust joints and constraints
- Adjust collision shapes
- Simulate the ragdoll
- Collision layer and mask

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [PhysicalBone3D](https://docs.godotengine.org/en/4.7/classes/class_physicalbone3d.html)
- [PhysicalBoneSimulator3D](https://docs.godotengine.org/en/4.7/classes/class_physicalbonesimulator3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
