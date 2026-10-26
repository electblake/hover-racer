<!--
source: https://raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.rst
retrieved: 2026-10-25T23:58:19.736328+00:00
final_url: https://raw.githubusercontent.com/godotengine/godot-docs/6d86d7c7f3b8f4f56c71e113022d72fe80b2c84d/tutorials/physics/interpolation/physics_interpolation_quick_start_guide.rst
content_type: text/plain
-->

# Official source: tutorials/physics/interpolation/physics_interpolation_quick_start_guide.rst

Original reStructuredText preserved verbatim below. See the curated topic guides in this bundle for Markdown reading notes.

````rst
.. _doc_physics_interpolation_quick_start_guide:

Quick start guide
=================

- Turn on physics interpolation: :ref:`Project Settings > Physics > Common > Physics Interpolation<class_ProjectSettings_property_physics/common/physics_interpolation>`
- Make sure you move objects and run your game logic in ``_physics_process()``
  rather than ``_process()``. This includes moving objects directly *and
  indirectly* (by e.g. moving a parent, or using another mechanism to automatically
  move nodes).
- Be sure to call :ref:`Node.reset_physics_interpolation<class_Node_method_reset_physics_interpolation>`
  on nodes *after* you first position or teleport them, to prevent "streaking".
- Temporarily try setting :ref:`Project Settings > Physics > Common > Physics Ticks per Second<class_ProjectSettings_property_physics/common/physics_ticks_per_second>`
  to 10 to see the difference with and without interpolation.
````
