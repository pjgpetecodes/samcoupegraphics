# SAM Coupe assembly

## Build and run an example

Open an assembly source such as `assembly\blog2\1.asm` or
`assembly\blog3\5-2.asm`, save it, and press **F5**. Choose
**SAM Coupe: Build active assembly and run** if prompted. The active editor
determines which file is assembled; open a program source, not an include-only
file such as `assembly\blog3\dizzy.asm`.

The launch uses the installed VS Code Python Debugger extension to run a
build/launch helper. It does not provide VS Code Z80 breakpoints or stepping.
Use SimCoupe's own debugger for those.

Requirements:

- Python 3.9+ and `pyz80` on PATH (`python -m pip install pyz80` if missing).
- VS Code's Python and Python Debugger extensions.
- The workspace copies of `samdisk\SAMdisk.exe`, `simcoupe\SimCoupe.exe`,
  and `samdisk\samdos2.raw`.

The helper follows the
[assembly tutorial](https://www.pjgcreations.co.uk/sam-coupe-assembly-language-programming/):
pyz80 includes SAMDOS and generates an uncompressed disk plus a symbol map;
SAMdisk converts that sector dump into an Extended DSK; SimCoupe opens and
automatically boots the converted disk in drive 1. Relative assembly includes
are resolved from the source file's directory. Any build failure stops launch.

Outputs are `disks\<source-name>.mgt`, `disks\<source-name>.dsk`, and
`disks\<source-name>.map`. Rebuilding replaces outputs with the same basename.
The map stays beside the DSK so SimCoupe can load its symbols. Close SimCoupe
before rebuilding to avoid an open disk image being locked.

For build only, use **Ctrl+Shift+B**, or run:

```powershell
python .\.vscode\sam_build.py .\assembly\blog3\5-2.asm --build-only
```

## Blog 2: from a square sprite to faster copying

`assembly\blog2` contains the progression from the square sprite through the
end of the existing graphics post: screen writes (`1.asm`, `2.asm`), then
loop-based and unrolled opaque sprite examples (`3.asm`, `3-2.asm`). The final
`3-2.asm` uses pyz80's `FOR 16, LDI` directive to emit repeated copy
instructions. Its sprite data has no mask, so the background area is copied
too; the white pixels around Dizzy are expected at this stage.

## Blog 3: introduce transparency

Draft post: [`assembly\blog3\blog-post.md`](assembly/blog3/blog-post.md).

`assembly\blog3\4.asm` keeps Dizzy's pixel colours and transparency masks in
separate 16-by-32 blocks, then pairs and cleans them at runtime into an
interleaved buffer. Drawing uses `(screen AND mask) OR pixel`, preserving the
background for transparent pixels and removing the source's white matte.
Tutorial 4 uses the existing system palette; it does not add palette setup.
`4-2.asm` adds a full-screen striped background to that example. `5.asm`
continues with the same Dizzy image and drawing routine, but stores the mask and
pixel bytes interleaved instead of building that block at runtime. `5-2.asm`
adds the striped background to this interleaved-data version.

The source Dizzy frames and palette are in `assembly\blog3\dizzy.asm`.
`assembly\blog4\dizzy_interleaved.asm` contains generated interleaved
mask/pixel pairs for `Image1`–`Image9`, padded to 16 bytes by 32 lines.
`assembly\blog4\dizzy_system_interleaved.asm` contains generated Dizzy animation
frames remapped to the existing system palette, and is used by the Blog 4
animation examples. `assembly\blog4\dizzy_palette.asm` holds the original palette
for `dizzy_interleaved.asm`.
Source colour index 0 is marked transparent. Regenerate the includes after
editing the source frames.

```powershell
python .\.vscode\generate_dizzy_masked.py
```

## Blog 4: animation and flicker

Draft post: [`assembly\blog4\blog-post.md`](assembly/blog4/blog-post.md).

`assembly\blog4\6-1.asm` continues from `blog3\5.asm` and alternates two
interleaved Dizzy frames stored in the program (system palette, no palette
setup). `6-2.asm` moves the frames into the external
`blog4\dizzy_system_interleaved.asm` file, `6-3.asm` plays all nine from a table,
`6-4.asm` draws on a hidden screen page and flips pages at the frame interrupt to
avoid visible tearing. All four use the default palette and draw Dizzy at the
top left of a blank screen. Parts 2-4 include the sprite data that sits beside
them in `assembly\blog4`. `blog4\main.asm` is an earlier, independent animation experiment.

## Blog 5: keyboard control

Draft post: [`assembly\blog5\blog-post.md`](assembly/blog5/blog-post.md).

`assembly\blog5\7-1.asm` continues from `blog4\6-4.asm` and adds idle and jump
sequences; pressing any key plays the jump once. `7-2.asm` limits the jump to the
Space bar, and `7-3.asm` adds left and right walking while Z or X is held. All three
use `assembly\blog5\dizzy_system_interleaved.asm`, which holds all 24 Dizzy frames
(`assembly\blog5\dizzy_system_sprites.json` is the same set as a Sprite Editor project).

## Debug in SimCoupe

The included SimCoupe version uses **F9** to open the debugger (older versions
in the tutorial use numpad `/`). For code starting at `32768` / `8000`, select
the code page using **H**, `1`, Enter, then navigate using **A**, `8000`,
Enter. Double-click an instruction to set a breakpoint, exit the debugger with
**Esc**, and reset/reboot the disk to hit it. See `simcoupe\Manual.md` for this
version's stepping keys and debugger commands.
