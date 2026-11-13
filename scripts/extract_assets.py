#!/usr/bin/env python3
"""Extract images, audio and fonts from a user-supplied APK into ./assets_extracted.

The output folder is git-ignored. Nothing extracted here may be committed or
redistributed. Stdlib only.
"""
import sys, zipfile, pathlib

KINDS = {
    ".png": "images", ".jpg": "images", ".jpeg": "images", ".webp": "images",
    ".ogg": "audio", ".mp3": "audio", ".wav": "audio",
    ".ttf": "fonts", ".otf": "fonts",
}
# Third-party ad/analytics SDK payloads are skipped.
SKIP = ("assets/audience_network/", "assets/ad-viewer/", "assets/com/appsflyer/", "META-INF/")

def main():
    if len(sys.argv) != 2:
        sys.exit("usage: extract_assets.py <game.apk>")
    out = pathlib.Path(__file__).resolve().parent.parent / "assets_extracted"
    n = 0
    with zipfile.ZipFile(sys.argv[1]) as z:
        for info in z.infolist():
            if info.is_dir() or info.filename.startswith(SKIP):
                continue
            kind = KINDS.get(pathlib.PurePosixPath(info.filename).suffix.lower())
            if not kind:
                continue
            dest = out / kind / info.filename
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_bytes(z.read(info))
            n += 1
    print(f"Extracted {n} files to {out}")

if __name__ == "__main__":
    main()
