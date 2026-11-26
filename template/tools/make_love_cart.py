#!/usr/bin/env python3
"""Pack a LÖVE game (.love archive or directory) into a .love.png cart:
a PNG cover image with the .love zip appended.

    python3 tools/make_love_cart.py dist/game.love docs/screenshots/cart.png dist/game.love.png

Image viewers stop reading at the PNG's end marker; zip readers (LÖVE/PhysFS)
find the archive by scanning from the end of the file. So the same file is both
a viewable picture and a runnable LÖVE game.
"""

import sys
import zipfile
from pathlib import Path


def main(source: str, label: str, out: str) -> None:
    src = Path(source)
    png = Path(label).read_bytes()
    if not png.startswith(b"\x89PNG\r\n\x1a\n"):
        sys.exit(f"{label} is not a PNG")

    out_path = Path(out)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(png)

    # Append mode on a non-zip file writes the archive after the PNG with
    # absolute offsets, so plain zip tools (unzip -t) read it cleanly too.
    with zipfile.ZipFile(out_path, "a", zipfile.ZIP_DEFLATED) as dst:
        if src.is_dir():
            if not (src / "main.lua").is_file():
                sys.exit(f"{src}/main.lua not found")
            for f in sorted(src.rglob("*")):
                if f.is_file():
                    dst.write(f, f.relative_to(src).as_posix())
        elif src.is_file() and zipfile.is_zipfile(src):
            with zipfile.ZipFile(src, "r") as zsrc:
                names = zsrc.namelist()
                if "main.lua" not in names:
                    sys.exit(f"{src} does not contain main.lua")
                for info in zsrc.infolist():
                    if info.is_dir():
                        continue
                    dst.writestr(info.filename, zsrc.read(info.filename))
        else:
            sys.exit(f"{src} must be a .love zip file or a game directory")

    size = out_path.stat().st_size
    print(f"wrote {out_path}: {len(png)} B label + {size - len(png)} B game")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    main(*sys.argv[1:])
