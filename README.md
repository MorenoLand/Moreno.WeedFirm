An unofficial, asset-free Godot/Redot client for *Weed Firm: RePlanted*, playable without an emulator on desktop, Linux and the web (WASM).

Fan project, not affiliated with the original developers. See [NOTICE.md](NOTICE.md). No game content is distributed here; you supply your own copy of the free APK.

## Setup

1. Get the free *Weed Firm: RePlanted* APK from a legitimate source.
2. Open the project in Godot 4.4+ or Redot and run it, or use an exported build.
3. On first launch select the APK (or drop it onto the window) and choose how to use it: play straight from the APK (the game reads what it needs on demand, nothing is copied) or unpack it to the app's user data folder for faster loading. Either way it stays on your device and never leaves it.

## Build

Export presets for Web, Linux and Windows are included. With Redot or Godot export templates installed:

`redot --headless --export-release "Web" bin/web/index.html` (likewise `"Linux"` and `"Windows"`)

The web build needs no special server headers (the server must send `.wasm` as `application/wasm`); serve the exported folder over HTTP.

On Windows, `scripts/export_web.ps1 -Engine <engine folder or exe> -Out <folder to serve>` runs the web export into any folder, for example a local web server's document root. Add `-Apk <path to your APK>` to also write a `data.pck` next to it: the page then downloads that bundle on first visit and starts with no APK step. That bundle (a zip with a `.pck` name, since some servers refuse `.zip` downloads) contains the game's own files, so keep it for local use and never publish it.

For a small desktop build, `scripts/export_desktop.ps1 -Engine <engine folder or exe> -Out <folder>` writes a single compressed `WeedFirm.exe` of about 23 MB instead of about 98 MB (it needs UPX and the engine's release export templates). `-Platform Linux` does the same for Linux (not tested). On Windows, pass `-Apk <your game.apk>` (or `-Icon <png>`) to give the exe the game icon; it is read from your own APK at build time and never stored in the repo.

To unpack from the command line instead: `redot --headless --script scripts/extract_cli.gd -- path/to/game.apk`

## License

Source code: MIT ([LICENSE](LICENSE)). Game content is not covered.
