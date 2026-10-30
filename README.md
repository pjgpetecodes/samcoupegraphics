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

## Blog 6: colour palettes

Draft post: [`assembly\blog6\blog-post.md`](assembly/blog6/blog-post.md).

`assembly\blog6\8-1.asm` continues from `blog5\7-3.asm`, loads a 16 colour CLUT
palette (re-applied after every `HALT`, because the ROM interrupt resets it) and
switches to the original Dizzy colour numbers in `tidizzy_interleaved.asm`
(the first 24 sprites exported from the Sprite Editor). `8-2.asm` lets keys 1 to 5
change palette entry 0, which recolours the whole background. `8-3.asm` adds sideways jumps (hold Z or X and press Space, frames 26-39) using
`tidizzy_cropped.asm`, the frames cropped to 13 bytes x 22 rows so that 38 of them fit in memory.
The editor-generated CLUT loader and palette table are shared in
`assembly\blog6\sam_palette.asm`. Sequences now carry a loop flag, so rolls and
jumps always play to the end.

## Blog 7: memory paging

Draft post: [`assembly\blog7\blog-post.md`](assembly/blog7/blog-post.md).

`assembly\blog7\9-1.asm` moves the existing 38 cropped Dizzy frames into physical
pages 4-5, leaving code, tables and a 572-byte staging buffer resident in pages
1-2. It uses display pairs 10-11 and 14-15, so it runs on a 256 KB SAM. The
animation controls and palette demonstration stay unchanged; this post does not
add world-space movement or scenery. Build with:

```powershell
python .\.vscode\sam_build.py .\assembly\blog7\9-1.asm --build-only
```

The new WordPress export is a draft for manual publication. Its web-emulator
embed needs the disk uploaded to the site's disk-hosting location first.

## Blog 8: horizontal movement

Draft post: [`assembly\blog8\blog-post.md`](assembly/blog8/blog-post.md).

`assembly\blog8\10-1.asm` adds a byte-aligned X position, updated independently
of animation at 50 Hz. It clamps the 13-byte sprite rectangle to the screen and
remembers the previous X separately for each display page, preventing trails.
There is no scenery, gravity or world collision yet.

```powershell
python .\.vscode\sam_build.py .\assembly\blog8\10-1.asm --build-only
```

## Blog 9: pixel positioning

Draft post: [`assembly\blog9\blog-post.md`](assembly/blog9/blog-post.md).

`assembly\blog9\11-1.asm` continues from Blog 8 and positions the same
26-pixel-wide sprite at pixel resolution, with alternating one- and three-pixel
steps to retain Blog 8's two-pixel average per update while switching parity.
Even positions draw the original 13-byte rows; odd positions use a resident
14-byte-per-row buffer with transparent padding. Page-specific previous
positions retain their old alignment and width when erased. The examples still
have no scenery or collision.

```powershell
python .\.vscode\sam_build.py .\assembly\blog9\11-1.asm --build-only
```

The new WordPress export is a draft for manual publication. Its web-emulator
embed needs the disk uploaded to the site's disk-hosting location first.

## Blog 10: static backgrounds

Draft post: [`assembly\blog10\blog-post.md`](assembly/blog10/blog-post.md).

`12-1.asm` copies one recovered palm; `12-2.asm` copies the source-derived
starting beach. Both use `static-background.asm`, staging one packed row between
banked source and hidden display RAM. Cyan colour zero is intentional here.
There is no moving player, scenery restoration or collision in this lesson.

```powershell
python .\.vscode\sam_build.py .\assembly\blog10\12-1.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog10\12-2.asm --build-only
```

## Blog 11: scenery restoration

Draft post: [`assembly\blog11\blog-post.md`](assembly/blog11/blog-post.md).

`13-1.asm` restores each hidden screen's old sprite rectangle from an immutable
background in pages 6-7, preserving the old X parity and its 13/14-byte width.
It stages rows between source and destination mappings before drawing the new
sprite. Y is intentionally fixed; no collision or gravity is introduced.

From this post onwards the program is split into logically named `INCLUDE`d
files: the short `13-1.asm` main file plus `constants`, `walking`,
`screen_paging`, `dizzy_sprite`, `variables`, `paged_data` and `sam_palette`.
Every cut follows an unconditional `RET`/`JP`/`JR`, so behaviour and
`Resident_End` (`0x88AC`) are unchanged. Each later blog folder is a complete,
self-contained copy of the previous one (with its own `assets` folder) that
changes only the files it needs and adds new files for new features.

```powershell
python .\.vscode\sam_build.py .\assembly\blog11\13-1.asm --build-only
```

## Blog 12: data-driven room composition

Draft post: [`assembly\blog12\blog-post.md`](assembly/blog12/blog-post.md).

`14-1.asm` builds the same starting beach from reusable graphics in pages 8-9
and generated seven-byte draw records. Source clipping is resolved offline;
packed-nibble transparency and original draw order are preserved. The composed
background still feeds Blog 11's restoration. No room transitions or collision
are introduced.

New file: `rooms.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog12\14-1.asm --build-only
```

## Blog 13: horizontal collision

Draft post: [`assembly\blog13\blog-post.md`](assembly/blog13/blog-post.md).

`15-1.asm` adds a stable inset collision box and reads separate static solidity
from pages 12-13. Each requested horizontal step is resolved pixel by pixel,
testing the full leading column to prevent crossing thin obstacles. A static
preview of the cliff room demonstrates blocking; there are no room transitions,
ground support or gravity yet.

New file: `collision.asm` (the horizontal resolver, `Constrain_X`).

```powershell
python .\.vscode\sam_build.py .\assembly\blog13\15-1.asm --build-only
```

## Blog 14: ground contact and walking

Draft post: [`assembly\blog14\blog-post.md`](assembly/blog14/blog-post.md).

`16-1.asm` follows the uneven beach with a stable footprint, bounded small
vertical adjustments and whole-body clearance, while still blocking the cliff.
`16-2.asm` uses the same resolver at the starting beach's real ledge: a yellow
border marks lost support and black marks recovered support. These are static
room previews, not room transitions. Gravity and physical jumping remain later
lessons. Both display pages now retain their previous X and Y for restoration.

`Constrain_X` gains ground following and moves into `walking.asm`, while
`collision.asm` now holds the shared solidity tests; `16-1` uses `_cliff` variants of `constants`, `paged_data` and `rooms`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog14\16-1.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog14\16-2.asm --build-only
```

## Blog 15: gravity and landing

Draft post: [`assembly\blog15\blog-post.md`](assembly/blog15/blog-post.md).

`17-1.asm` accelerates an unsupported player downward and resolves every pixel
before accepting a landing. Airborne movement cannot snap onto nearby platforms.
Water is not a hazard yet; lower solid beach terrain remains landable.

New file: `jump_gravity.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog15\17-1.asm --build-only
```

## Blog 16: physical jumping

Draft post: [`assembly\blog16\blog-post.md`](assembly/blog16/blog-post.md).

`18-1.asm` adds a signed upward impulse on a fresh grounded Space press, with
ceiling collision and no held-key or airborne-press retrigger. `18-2.asm` uses
the identical resolver beneath a clearly artificial ceiling bar; that fixture
is not part of the faithful game scenery. Neither example connects rooms yet.

`18-2` adds `test_ceiling.asm` for its fixture.

```powershell
python .\.vscode\sam_build.py .\assembly\blog16\18-1.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog16\18-2.asm --build-only
```

## Blog 17: connecting the first two rooms

Draft post: [`assembly\blog17\blog-post.md`](assembly/blog17/blog-post.md).

`19-1.asm` adds explicit grounded walking exits between screens 1 and 2,
matching scenery/collision loading, and safe supported entry positions. The
extractor also emits compact collision runs so active masks can reuse pages
12-13 on a 256 KB SAM. The cliff remains solid; there is no upward escape yet.

```powershell
python .\.vscode\sam_build.py .\assembly\blog17\19-1.asm --build-only
```

## Blog 18: collecting the chest

Draft post: [`assembly\blog18\blog-post.md`](assembly/blog18/blog-post.md).

`20-1.asm` renders the source-derived chest on screen 1. A fresh Enter press
collects it only while grounded, stopped and overlapping its rectangle.
Resident collection state prevents duplication across room visits; carrying
it does not unlock the cliff. Inventory and dropping remain separate lessons.

New file: `items_inventory.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog18\20-1.asm --build-only
```

## Blog 19: visible three-item LIFO inventory

Draft post: [`assembly\blog19\blog-post.md`](assembly/blog19/blog-post.md).

`21-1.asm` adds three visible HUD slots, a true LIFO stack, full/empty feedback
and safe transactional dropping. Extra item placements are explicitly teaching
fixtures. `21-2.asm` seeds a carried axe beside the cliff to isolate unsafe-drop
rejection and a safe retry. The requested LIFO order intentionally differs from
the original game's slot rotation. Dropping the chest is not yet a puzzle trigger.

`21-2` uses `_drop_test` variants of `constants` and `variables`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog19\21-1.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog19\21-2.asm --build-only
```

## Blog 20: physically place the chest to escape

Draft post: [`assembly\blog20\blog-post.md`](assembly/blog20/blog-post.md).

`22-1.asm` activates the recovered supporting chest only from a safe physical
drop overlapping screen 2's source trigger. Carrying does not unlock the exit.
The inventory fixtures are removed, the jump rise is calibrated to the obstacle,
and a leftward jump over the wall reveals the sparse third screen near its
bottom edge. The vertical link preserves the jump and uses the recovered
hundred-row offset rather than spawning Dizzy above a cloud. Screen 4 is not
connected yet.

```powershell
python .\.vscode\sam_build.py .\assembly\blog20\22-1.asm --build-only
```

## Blog 21: completing the four-screen route

Draft post: [`assembly\blog21\blog-post.md`](assembly/blog21/blog-post.md).

`23-1.asm` links screen 3's left edge to screen 4 and back, choosing an upper
(cloud) or lower (ground) entry row from Dizzy's current height. Screen 4's
left edge, the bridge, stays solid. The placed chest persists across the whole
route, and screen 4's coin becomes reachable through the existing pickup.

```powershell
python .\.vscode\sam_build.py .\assembly\blog21\23-1.asm --build-only
```

## Blog 22: animated background scenery

Draft post: [`assembly\blog22\blog-post.md`](assembly/blog22/blog-post.md).

`24-1.asm` animates the starting beach's sea. `Build_Room` registers the room's
wave-frame-0 records instead of baking them into the background; every hidden
frame restores those strips, draws Dizzy, then overlays the current wave frame
(source graphics 55-58, extracted to `assembly\blog22\assets`), advancing one
frame every three interrupts like the original.

New file: `water_animation.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog22\24-1.asm --build-only
```

## Blog 23: detecting hazards

Draft post: [`assembly\blog23\blog-post.md`](assembly/blog23/blog-post.md).

`25-1.asm` adds a five-byte hazard table (room, inclusive left/right/top/bottom)
kept separate from the solid collision mask. `Check_Hazards` overlap-tests the
body box after gravity each update and the border turns red while Dizzy is in
the starting beach's sea. The rectangle is a tutorial adaptation traced from the
visible water; contact has no consequence yet.

New file: `hazards.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog23\25-1.asm --build-only
```

## Blog 24: death and restarting

Draft post: [`assembly\blog24\blog-post.md`](assembly/blog24/blog-post.md).

`26-1.asm` gives hazard contact a consequence. Dizzy has one life, as in the
original, so contact starts a two-second death pause (input and physics skipped,
border flashing, waves still animating) and then `Restart_Game` copies a
boot-time snapshot of the 47-byte `Game_State` block back and re-enters room 1.
The chest, coins, inventory and puzzle state all return to their start.

New file: `death_restart.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog24\26-1.asm --build-only
```

## Blog 25: a moving actor

Draft post: [`assembly\blog25\blog-post.md`](assembly/blog25/blog-post.md).

`27-1.asm` adds the source game's bee to the fourth screen (graphics 327-330,
extracted to `assembly\blog25\assets`). It patrols byte X 55-115 on row 100 at
one byte per three-interrupt game frame, choosing left/right-facing frames from
its velocity, and is restored/drawn per display page before Dizzy. It is not yet
harmful. The `27-1` capture job uses unrecorded `("skip", s)` steps to replay
the route to screen 4 before recording.

New file: `bee_actor.asm`.

```powershell
python .\.vscode\sam_build.py .\assembly\blog25\27-1.asm --build-only
```

## Blog 26: enemy contact

Draft post: [`assembly\blog26\blog-post.md`](assembly/blog26/blog-post.md).

`28-1.asm` changes only two files in its copy of Blog 25's folder.
`hazards.asm` adds a labelled `Bee_Hazard` record, and `bee_actor.asm` rewrites
that record's left/right pixels (body box offsets 2-18, rows 109-121, excluding
wings and stinger tip) whenever the bee moves. The existing hazard test and
death/restart sequence then handle contact. Lethality is a tutorial rule. The
`28-1` capture replays the route, jumps the boulder, climbs the rocks and jumps
into the bee.

```powershell
python .\.vscode\sam_build.py .\assembly\blog26\28-1.asm --build-only
```

## Blog 27: the complete four-screen route

Draft post: [`assembly\blog27\blog-post.md`](assembly/blog27/blog-post.md).

`29-1.asm` adds no new code; its folder is a copy of Blog 26's and its symbol
map is identical to `28-1`'s. The article maps each file to the post that
introduced it. The `29-1` capture records the whole route without cuts: chest
pickup, drop beside the screen-2 wall, the climb to screen 3, then screen 4,
where Dizzy jumps the boulder, climbs the rocks and collects the coin while the
bee patrols.

```powershell
python .\.vscode\sam_build.py .\assembly\blog27\29-1.asm --build-only
```

## Extract reference graphics without replacing existing assets

The sprite extractor accepts the known raw MGT-format Treasure Island Dizzy
disk and requires a **new output directory**. It checks the source hash and
sector chain, then writes sprite assembly, a contact sheet and `provenance.json`.
It does not export the original game code or copy the disk into its output.

```powershell
python .\.vscode\extract_tidizzy.py --disk "C:\path\to\TIDizzy.dsk" --output "C:\path\to\new-sprite-output"
python .\.vscode\extract_tidizzy.py --rooms --disk "C:\path\to\TIDizzy.dsk" --output "C:\path\to\new-room-output"
python -m unittest discover -s .\testing -p test_extract_tidizzy.py
```

The existing Blog 5 sprites are preserved: the extractor refuses an existing
destination rather than overwriting it. Sprite extraction does not extract room
layouts, collision rules or game logic. The separate `--rooms` mode exports the
four selected scenery layouts, 34 reusable graphics, commented assembly draw
records, packed previews and static
collision masks with provenance. It excludes HUD, items and moving actors.
The recovered route is native rooms 77, 76, 108, 107 (left, up, left); native
106 is the bridge outside the four-screen slice.

## Debug in SimCoupe

The included SimCoupe version uses **F9** to open the debugger (older versions
in the tutorial use numpad `/`). For code starting at `32768` / `8000`, select
the code page using **H**, `1`, Enter, then navigate using **A**, `8000`,
Enter. Double-click an instruction to set a breakpoint, exit the debugger with
**Esc**, and reset/reboot the disk to hit it. See `simcoupe\Manual.md` for this
version's stepping keys and debugger commands.

## Copilot repository support

Repository-wide guidance is in `.github\copilot-instructions.md`. Focused custom
agents are available for SAM Coupé assembly, hardware, blog/WordPress
synchronization, and SimCoupe visual testing. Reusable skills under
`.github\skills` cover assembly progressions, SAM hardware, WordPress/markdown
sync, GIF capture, and sprite-data maintenance.
