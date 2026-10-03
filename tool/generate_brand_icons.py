"""Reproduce native launcher assets from the supplied website brand mark.

Run from the project root with Python and Pillow installed.
"""
from pathlib import Path
import json
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
source = Image.open(ROOT / "assets/brand/brand-mark.png").convert("RGB")

for relative in ["ios/Runner/Assets.xcassets/AppIcon.appiconset", "macos/Runner/Assets.xcassets/AppIcon.appiconset"]:
    folder = ROOT / relative
    for entry in json.loads((folder / "Contents.json").read_text())["images"]:
        if not entry.get("filename"):
            continue
        size = round(float(entry["size"].split("x")[0]) * float(entry["scale"].rstrip("x")))
        source.resize((size, size), Image.Resampling.LANCZOS).save(folder / entry["filename"])

for density, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    target = ROOT / f"android/app/src/main/res/mipmap-{density}/ic_launcher.png"
    source.resize((size, size), Image.Resampling.LANCZOS).save(target)

source.save(ROOT / "windows/runner/resources/app_icon.ico", format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])

launch = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"
for filename, size in {"LaunchImage.png": 100, "LaunchImage@2x.png": 200, "LaunchImage@3x.png": 300}.items():
    source.resize((size, size), Image.Resampling.LANCZOS).save(launch / filename)

print("Native icons generated from the Secure By Design website mark.")
