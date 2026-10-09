# SAM Coupe assembly

## Build and run the active file

Open this folder in VS Code, open an assembly source such as
`assembly\1.asm` or `assembly\main.asm`, save it, and press **F5**.
Choose **SAM Coupe: Build active assembly and run** if prompted.
The active editor determines which file is assembled; open the main source,
not an include-only file such as `assembly\dizzy.asm`.

The launch uses the installed VS Code Python Debugger extension to run a
build/launch helper. It does not provide VS Code Z80 breakpoints or stepping.
Use SimCoupe's own debugger for those.

Requirements:

- Python 3.9+ and `pyz80` on PATH (`python -m pip install pyz80` if missing).
- VS Code's Python and Python Debugger extensions (already installed here).
- The workspace copies of `samdisk\SAMdisk.exe`, `simcoupe\SimCoupe.exe`,
  and `samdisk\samdos2.raw`.

The helper follows the
[assembly tutorial](https://www.pjgcreations.co.uk/sam-coupe-assembly-language-programming/):
pyz80 includes SAMDOS and generates an uncompressed disk plus a symbol map;
SAMdisk converts that sector dump into an Extended DSK; SimCoupe opens and
automatically boots the converted disk in drive 1.
The image is passed as a positional argument (`SimCoupe.exe "<disk>.dsk"`),
matching SimCoupe's file-opening command.
It uses the installed pyz80 rather than the older bundled `pyz80\pyz80.py`.
Relative assembly includes are resolved from the source file's directory.
Any build failure stops the launch.

Outputs are `disks\<source-name>.mgt`, `disks\<source-name>.dsk`, and
`disks\<source-name>.map`. Rebuilding replaces outputs with the same basename,
so source files in different directories should have distinct basenames.
The map stays beside the DSK so SimCoupe can load its symbols.
Close SimCoupe before rebuilding to avoid an open disk image being locked.

For build only, use **Ctrl+Shift+B**, or run:

```powershell
python .\.vscode\sam_build.py .\assembly\main.asm --build-only
```

## Debug in SimCoupe

The included SimCoupe version uses **F9** to open the debugger (older versions
in the tutorial use numpad `/`). For code starting at `32768` / `8000`:
select the code page using **H**, `1`, Enter, then navigate using **A**,
`8000`, Enter. Double-click an instruction to set a breakpoint, exit the
debugger with **Esc**, and reset/reboot the disk to hit it.
See `simcoupe\Manual.md` for this version's stepping keys and debugger commands.

## Tutorial 5, part 1: frame animation

Open `assembly\5-1.asm` and press **F5** to run the non-keyboard animation
demo in the default MODE 4. It uses the palette and two idle frames from
`assembly\dizzy.asm`, drawing Dizzy at X = 68, Y = 100. Each frame is held for
five 50 Hz interrupts (10 animation frames per second). Reset SimCoupe to stop.

`Frame_Delay` controls the speed; the word pointers in `Animation_Frames`
control the sequence. Unlike tutorial 4's masked sprite, these images contain
a width/height header followed by unmasked pixels. Copying each complete
rectangle erases the previous frame on the plain colour-zero background;
it does not preserve scenery. Keep frames the same size when changing the
sequence. This first part uses data-driven drawing, not compiled sprites or
double buffering.

## Tutorial 5, part 2: masked animation

Open `assembly\5-2.asm` and press **F5** to animate the Dizzy idle and jump
sequences using the masked-sprite approach from `assembly\4.asm`. Hold any key
to play the jump sequence; release it to return to idle. Unlike `5-1.asm`, the
new example preserves the background beneath transparent pixels. It saves the
sprite's screen rectangle before animation and restores it between frames to
avoid trails when the sprite changes shape.

The original `assembly\dizzy.asm` images are 13 bytes wide by 22 lines, with
two 4-bit MODE 4 palette indices packed into each byte. The generated
`assembly\dizzy_masked.asm` contains `Image1`–`Image9` converted to 16-byte by
32-line canvases. Every source pixel becomes a mask/data pair: palette index 0
is transparent, other indices are opaque, and the extra canvas area is padded
as transparent. The include also carries Dizzy's palette. Recreate it after
editing the source frames with:

```powershell
python .\.vscode\generate_dizzy_masked.py
```
