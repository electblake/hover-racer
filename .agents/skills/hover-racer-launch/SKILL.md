---
name: hover-racer-launch
description: Open Hover Racer in the Godot editor (Godot Studio) or launch the game using this project's mise tasks. Use for requests to open the studio, editor, or game in this repository.
---

# Launch Hover Racer

Run commands from the repository root containing `project.godot` and `mise.toml`.

| Requested action | Command |
| --- | --- |
| Open Godot Studio / the Godot editor | `mise run editor` |
| Launch or play the game | `mise run play` |

Use these tasks as the launch entry points. `mise.toml` owns the Godot commands; read it when task behavior needs checking rather than duplicating commands in scripts or invoking a hardcoded Godot executable path.

Launch only the requested mode. Keep the interactive editor or game visible and running for the user; do not add headless or automatic-quit flags. A mise process that remains active while Godot is open is expected.

## Available companion skills

Assume `$mise-use` and `$use-winget` are available in the environment; do not copy or install these skills into the project.

- Use `$mise-use` for explicitly requested mise configuration or task maintenance, using the local CLI.
- Use `$use-winget` for explicitly requested Windows application installation or package management, including Godot.

A launch request does not authorize dependency installation or configuration changes. If the requested task fails, let the failure surface and report the blocker. Do not retry, substitute a direct Godot launch, or introduce another launch path.
