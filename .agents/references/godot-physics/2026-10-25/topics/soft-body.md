# SoftBody3D and deformable meshes

Godot 4.7 documentation snapshot | 2026-10-25 | `6d86d7c7f3b8`

Curated reading guide; the linked official source is authoritative.

## Starting point

Assign a subdivided mesh directly to SoftBody3D; it supplies both rendered geometry and collision. Begin with the bouncy cube, then follow the cloak example for pinned points and bone attachments.

## Constraints and compatibility

Jolt has more robust soft-body support according to this guide. Physics interpolation does not affect soft bodies in this snapshot. Subdivision, simulation precision and tick rate trade performance for quality. Imported mesh LODs can interfere with deformation.

## Official source

- [Local full source, including examples](../raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/soft_body.md)
- [Commit-pinned repository page](https://github.com/godotengine/godot-docs/blob/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/soft_body.rst)
- [Published stable page](https://docs.godotengine.org/en/stable/tutorials/physics/soft_body.html) (moving alias)

## Sections in the captured source

- Physics engine considerations
- Basic setup
- Cloak simulation
- Using imported meshes

## API starting points

These class links are extracted from the source; API pages are not mirrored.

- [BoneAttachment3D](https://docs.godotengine.org/en/4.7/classes/class_boneattachment3d.html)
- [CollisionShape3D](https://docs.godotengine.org/en/4.7/classes/class_collisionshape3d.html)
- [MeshInstance3D](https://docs.godotengine.org/en/4.7/classes/class_meshinstance3d.html)
- [RigidBody3D](https://docs.godotengine.org/en/4.7/classes/class_rigidbody3d.html)
- [SoftBody3D](https://docs.godotengine.org/en/4.7/classes/class_softbody3d.html)
- [StaticBody3D](https://docs.godotengine.org/en/4.7/classes/class_staticbody3d.html)

[All physics topics](../README.md) | [Physics engines](physics-engines.md)
