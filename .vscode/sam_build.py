"""Build the active SAM assembly file and optionally run it in SimCoupe."""

import argparse
from pathlib import Path
import shutil
import subprocess
import sys


def run(command, cwd):
    print(subprocess.list2cmdline([str(arg) for arg in command]), flush=True)
    subprocess.run(command, cwd=cwd, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("--build-only", action="store_true")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    source = args.source.resolve()
    if not source.is_file() or source.suffix.lower() not in {
        ".asm", ".z80", ".z80s", ".s"
    }:
        parser.error("Open a saved assembly file (.asm, .z80, .z80s or .s) first.")
    if not source.is_relative_to(root):
        parser.error("The assembly file must be inside this workspace.")

    assembler = shutil.which("pyz80")
    if assembler is None:
        parser.error("pyz80 is missing from PATH. Install it with: python -m pip install pyz80")

    samdisk = root / "samdisk" / "SAMdisk.exe"
    simcoupe = root / "simcoupe" / "SimCoupe.exe"
    dos = root / "samdisk" / "samdos2.raw"
    required = [samdisk, dos]
    if not args.build_only:
        required.append(simcoupe)
    for tool in required:
        if not tool.is_file():
            parser.error(f"Required file is missing: {tool}")

    output = root / "disks"
    output.mkdir(exist_ok=True)
    mgt = output / f"{source.stem}.mgt"
    disk = output / f"{source.stem}.dsk"
    symbols = output / f"{source.stem}.map"

    # pyz80 writes an MGT sector dump; SAMdisk converts it to Extended DSK.
    run([
        assembler, "--nozip", f"--mapfile={symbols}",
        "-I", dos, "-o", mgt, source.name
    ], source.parent)
    run([samdisk, "copy", "--force", mgt, disk], root)
    print(f"Built {disk}\nSymbols: {symbols}", flush=True)

    if not args.build_only:
        run([simcoupe, disk], output)


if __name__ == "__main__":
    try:
        main()
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"SAM build/run failed: {error}", file=sys.stderr)
        sys.exit(1)
