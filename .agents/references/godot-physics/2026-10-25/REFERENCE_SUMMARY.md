# Reference summary

- Platform: Godot Engine documentation, version **4.7** as declared by captured `conf.py`.
- Reference date: **2026-10-25**, America/Toronto. Retrieval metadata uses UTC.
- Source: official `godotengine/godot-docs`, `stable` branch resolved to `6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d`.
- Scope: 20 physics chapter pages, version configuration and repository license; 21 curated topic guides.
- Starting URL supplied by user: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html

## Official source findings

The chapter covers collision objects, shapes, materials, layers/masks, fixed physics processing, rigid-body force control, areas, character movement, ray/space queries, ragdolls, soft bodies, large-world precision, interpolation, and troubleshooting. Jolt is a built-in 3D alternative since 4.4; the SoftBody page specifies that new projects use Jolt from 4.6. Existing projects must select it explicitly when migrating.

Physics is not guaranteed deterministic. Jolt differs in joints, margins, contact information, ray face indices and several other behaviors. The older Jolt extension is in maintenance mode and its custom joints are not included in the module. Double-precision worlds require matching editor/export builds and rebuilt GDExtensions. Soft bodies are not interpolated. 3D physics objects created directly through servers need manual interpolation.

## Source inconsistencies and limits

Some troubleshooting paragraphs still describe GodotPhysics as the default. Use the explicit 4.6 default-change statement in SoftBody and the Jolt introduction when deciding what new projects use. No claim is made that the installed Hover Racer engine or selected backend matches this documentation snapshot. No game source or settings were changed.

The published stable site returned HTTP 403 to the earlier Python research fetch. At the user's request the capture uses commit-pinned raw files from the official GitHub repository instead. The mirror skill's `mirror_one` function performed capture; original RST is fenced in Markdown to retain examples and Sphinx markup. API pages and media are not part of the local capture.

## Discovery checks

- `https://docs.godotengine.org/llms.txt`: HTTP 404 during initial discovery.
- `https://raw.githubusercontent.com/llms.txt`: HTTP 404.
- `https://github.com/llms.txt`: available; host-level GitHub guidance, not a Godot physics index. Physics scope is determined by the official repository toctrees, not unrelated GitHub product documentation.

## Navigation

See [README](README.md) for the learning map, [source URLs](SOURCE_URLS.md) for provenance and [capture manifest](capture_manifest.json) for file records and source-text checksums. Curated guidance is separate from official source text. No user runtime evidence was collected.
