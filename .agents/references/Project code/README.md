# Wipeout Racer

The game lives in `index.html`. The Electron wrapper packages that exact file with its own Chromium runtime for offline play on 64-bit Windows 10/11.

## Build a portable Windows app

Double-click `build.cmd`, or run from PowerShell:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\build.ps1
```

The first build needs internet access to download a checksum-verified, project-local Node.js toolchain, npm dependencies, Electron, and packaging tools. No administrator access or separate Node.js installation is required. Subsequent builds use the committed npm lockfile. Build tools and output are ignored by Git.

The script runs the game's built-in regression tests in Electron and checks WebGL 2 before packaging. On a build machine without a working graphics session, use `-SkipSmokeTest` to skip that check.

Output: `dist/WipeoutRacer-1.0.0-x64-portable.exe`

Copy that executable to another Windows PC and run it without installing anything. It extracts its bundled runtime into a temporary directory when launched. Chromium profile/cache data uses the current user's application-data directory. The executable is unsigned, so Windows may show an unknown-publisher warning.

Edit `index.html` and rerun the build to package game updates. With the downloaded toolchain on PATH, `npm start` launches the development wrapper. F11 toggles fullscreen; Escape leaves fullscreen. Keyboard, controller, audio, and the game's fullscreen button use the bundled browser runtime.
