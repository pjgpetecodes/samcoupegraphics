# Repository guidance

This repository develops a progressive SAM Coupé graphics tutorial series. Keep
changes consistent with the existing assembly examples, blog drafts, and helper
scripts.

## Sources of truth and preservation

- Treat `assembly\blogN\*.asm` as the executable source, `blog-post.md` as the
  editable article draft, and `blog-post-wordpress.html` as a separate WordPress
  block export that may contain hand-edited content and media URLs.
- Never modify or regenerate a WordPress HTML export unless the user explicitly
  asks for that in the current task. If authorized, make a backup first and
  verify the correct markdown/export pair before writing.
- For WordPress-to-markdown synchronization, inspect the export and identify
  which article it actually contains before choosing a destination. Some exports
  can be stale or copied into another blog folder. Do not overwrite a markdown
  article from an unrelated export. Review imports for lost links, code fences,
  emulator embeds, tables, images, and assembly references.
- Do not overwrite user edits or revert unrelated work. Inspect `git status`
  before editing and preserve existing dirty changes.

## Assembly progression

- Preserve the tutorial's incremental progression: later examples build on
  earlier ones and should add only the requested concepts. Avoid unrelated
  refactors or replacing the established sprite/data set without direction.
- Follow existing Z80/pyz80 syntax, indentation, labels, comments, and include
  conventions. Keep comments useful and accurate, especially around paging,
  interrupt/`HALT` behavior, flags, keyboard ports, and frame-table layout.
- Preserve known SAM Coupé invariants: `LMPR` is port 250, `VMPR` is 252, and
  `CLUT` is 248; page ROM back in before `HALT`; account for the ROM interrupt
  resetting palette values; draw on the hidden page before flipping; keep the
  stack clear of included sprite data; and preserve mask/pixel interleaving.
- Keep blank backgrounds black unless the current post explicitly introduces a
  palette/background change. Check memory footprints when adding frames or
  buffers; the 32 KB above `0x8000` is a constrained program area.
- Build each changed assembly entry point with
  `python .\.vscode\sam_build.py .\assembly\<blog>\<file>.asm --build-only`.
  Includes resolve relative to the source file. Do not rebuild unrelated
  examples. Run SimCoupe for behavior-changing work when available.

## SAM Coupé hardware and Z80

- Treat this as Z80 code running on SAM Coupé hardware, not generic PC graphics.
  Before introducing a register, port, interrupt, display mode, or memory-map
  assumption, check the existing examples and `simcoupe\Manual.md`; if the
  repository does not establish the behavior, verify it with a reliable SAM
  Coupé reference or a focused emulator test.
- In these examples, `LMPR` is port 250, `VMPR` is 252, and the CLUT is port
  248. Preserve unrelated register bits when changing a page or display mode.
  MODE 4 screen clearing uses 24 KB (`0x6000` bytes); the drawing routines use
  the screen's 128-byte row stride.
- Keyboard reads use port `0xFE` with row-select bits in the high byte. The
  tutorial's input is active-low: a pressed key reads as zero. Keep row and bit
  assignments consistent with the relevant code and explain them where the
  article teaches them.
- The CLUT uses the high byte of the port address to select an entry; the
  palette examples write entries through `OUT (C),A`. The ROM interrupt resets
  the custom palette, so these examples reapply it after `HALT`.
- `HALT` relies on the ROM interrupt handler being mapped in. Restore the ROM
  before waiting, and keep interrupts disabled while screen RAM is mapped over
  the lower address space. For double buffering, draw only on the hidden page
  and flip `VMPR` only after a complete frame is ready.
- Use Z80 flag behavior deliberately. Instructions such as `LD` preserve flags;
  arithmetic/bit operations can change them. Comments and branches must agree
  with the actual instruction flags.

## Blog and media workflow

- Match the established post voice and layout in neighboring
  `assembly\blogN\blog-post.md` files. Edit markdown rather than hand-editing
  generated WordPress HTML, unless the user explicitly requests an HTML update.
- The Markdown-to-WordPress converter is
  `.vscode\wp-tools\md_to_wordpress.mjs`; it refuses existing-file overwrites
  unless passed `--force`. Never use `--force` without explicit authorization
  for that output. `wp_sync.mjs --dry` is a preview, not proof that two files
  describe the same post; check article titles and block counts first.
- Use the existing build, GIF, sprite-conversion, and extraction tools rather
  than inventing parallel formats. Keep generated media in the blog's existing
  `gifs` folder and preserve uploaded WordPress URLs when importing content.
- Do not claim a GIF, emulator embed, gist, or assembly build was verified
  unless it was actually checked.

## Validation and reporting

- Run the smallest build or script check that covers the change. For documentation
  or configuration-only changes, validate file structure and any referenced
  commands/scripts without rebuilding the whole project.
- Clearly report what changed, what was verified, and any mismatched or
  unresolved WordPress/blog mapping. Do not silently drop content that an
  importer cannot represent.
