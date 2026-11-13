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

On Windows, `scripts/export_web.ps1 -Engine <engine folder or exe> -Out <folder to serve>` runs the web export into any folder, for example a local web server's document root.

To unpack from the command line instead: `redot --headless --script scripts/extract_cli.gd -- path/to/game.apk`

## License

Source code: MIT ([LICENSE](LICENSE)). Game content is not covered.
