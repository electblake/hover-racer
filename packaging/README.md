# Windows releases

Build requirements: PowerShell 7.4+, Godot 4.7.2 with matching Windows x64 release export templates, mise, and Inno Setup 6. Publishing also requires authenticated GitHub CLI and push access to `origin` (`electblake/hover-racer`).

The version comes from `config/version` in `project.godot`. The export embeds the game data into `HoverRacer.exe`; the portable ZIP also contains the required graphics libraries and third-party notices. The per-user installer uses a stable application ID and preserves settings in Godot's user-data directory. Neither artifact is signed.

```powershell
pwsh -File scripts/build-windows.ps1 -IsccPath 'C:\path\to\Inno Setup 6\ISCC.exe'
```

This runs the full tests, exports with the release template, writes engine notices, smoke-tests the exported executable, builds Setup, and writes a portable ZIP and SHA-256 checksums into `dist/<version>/`. Build products are ignored by Git.

Before publishing, inspect the rendered export and verify clean installation, launch, upgrade, silent installation, and uninstall in a disposable Windows environment. Commit all release source changes, including the version, changelog, and `packaging/releases/<version>.md`. Then run:

```powershell
pwsh -File scripts/publish-release.ps1 -IsccPath 'C:\path\to\Inno Setup 6\ISCC.exe'
```

This builds the artifacts, creates an annotated `v<version>` tag, pushes the current commit and tag to `origin`, and publishes the installer, portable ZIP, and checksums on GitHub. Each version is published once; native failures stop the script. The checked-in release preset excludes tests, tools, reference captures, and preview images while explicitly retaining JSON course samples. Audio loads through Godot's imported resources.
