# Godot physics reference bundle

Reference date: **2026-10-25** (America/Toronto). Official repository: [godotengine/godot-docs](https://github.com/godotengine/godot-docs). Captured `stable` at commit [`6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d`](https://github.com/godotengine/godot-docs/commit/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d). Repository `conf.py` identifies **Godot 4.7**; this is a documentation version, not a verified installed engine version or patch release.

## Start here

- [Physics engines and backend selection](topics/physics-engines.md)
- [Version, compatibility and capture notes](REFERENCE_SUMMARY.md)
- [All source URLs](SOURCE_URLS.md)
- [Full inventory](REFERENCE_INDEX.md)
- [Machine-readable capture manifest](capture_manifest.json)

## Single-topic guides

- [Physics chapter map](topics/index.md)
- [Physics introduction](topics/physics-introduction.md)
- [Jolt Physics](topics/using-jolt-physics.md)
- [Rigid bodies and force integration](topics/rigid-body.md)
- [Areas, overlaps and local influence](topics/using-area-2d.md)
- [CharacterBody movement and collision](topics/using-character-body-2d.md)
- [Ray casting and physics-space queries](topics/ray-casting.md)
- [Ragdolls and physical bones](topics/ragdoll-system.md)
- [Kinematic character foundations](topics/kinematic-character-2d.md)
- [SoftBody3D and deformable meshes](topics/soft-body.md)
- [2D collision shapes](topics/collision-shapes-2d.md)
- [3D collision shapes](topics/collision-shapes-3d.md)
- [Large worlds and floating-point precision](topics/large-world-coordinates.md)
- [Physics interpolation map](topics/interpolation-index.md)
- [Physics troubleshooting](topics/troubleshooting-physics-issues.md)
- [Interpolation quick start](topics/interpolation-physics-interpolation-quick-start-guide.md)
- [Interpolation timing and theory](topics/interpolation-physics-interpolation-introduction.md)
- [Applying physics interpolation](topics/interpolation-using-physics-interpolation.md)
- [Advanced interpolation and cameras](topics/interpolation-advanced-physics-interpolation.md)
- [2D and 3D interpolation differences](topics/interpolation-2d-and-3d-physics-interpolation.md)

## Capture scope

All 20 RST pages in the physics chapter's recursive toctree were captured: the chapter index, its 14 direct entries, and five interpolation subpages. There are 21 curated topic files including the engine comparison. Every topic guide links to the complete source with its code examples and section outline. Original RST is preserved inside fenced Markdown under `raw.githubusercontent.com/`; this preserves Sphinx roles and directives without pretending they are rendered Markdown.

Images, videos, demo projects and API class pages are not downloaded. They remain references in the original sources. Topic guides are assistant-authored summaries, clearly separate from upstream text. No runtime behavior has been tested. The repository license is captured alongside its version configuration.
