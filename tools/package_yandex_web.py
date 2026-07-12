#!/usr/bin/env python3
"""Create a flat Yandex Games Web release ZIP after a Godot Web export."""

from __future__ import annotations

import argparse
import re
import sys
import zipfile
from pathlib import Path


DEFAULT_LIMIT_BYTES = 100_000_000
INVALID_NAME = re.compile(r"[\s]|[^\x00-\x7f]")


def fail(message: str) -> None:
    print(f"Yandex package: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate and package builds/yandex for Yandex Games.")
    parser.add_argument("--build-dir", type=Path, default=Path("builds/yandex"))
    parser.add_argument("--output", type=Path, default=Path("builds/yandex_release.zip"))
    parser.add_argument("--max-size-bytes", type=int, default=DEFAULT_LIMIT_BYTES)
    args = parser.parse_args()

    build_dir = args.build_dir.resolve()
    index_path = build_dir / "index.html"
    if not index_path.is_file():
        fail(f"missing exported HTML: {index_path}")

    html = index_path.read_text(encoding="utf-8")
    for required in ("/sdk.js", "YaGames.init()", "game_api_pause", "game_api_resume"):
        if required not in html:
            fail(f"index.html is missing required Yandex bootstrap text: {required}")

    files = sorted(path for path in build_dir.rglob("*") if path.is_file())
    extensions = {path.suffix.lower() for path in files}
    missing = [extension for extension in (".js", ".pck", ".wasm") if extension not in extensions]
    if missing:
        fail("missing required Godot Web export file types: " + ", ".join(missing))

    for path in files:
        relative = path.relative_to(build_dir)
        if any(INVALID_NAME.search(part) for part in relative.parts):
            fail(f"file or folder name contains spaces or non-ASCII characters: {relative}")

    total_size = sum(path.stat().st_size for path in files)
    max_size = args.max_size_bytes
    if total_size > max_size:
        fail(f"uncompressed build is {total_size} bytes, above configured {max_size} byte limit")

    output_path = args.output.resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output_path, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            archive.write(path, path.relative_to(build_dir).as_posix())

    print("Yandex package: validated %d files, %d uncompressed bytes" % (len(files), total_size))
    print("Yandex package: created %s with files at ZIP root" % output_path)


if __name__ == "__main__":
    main()
