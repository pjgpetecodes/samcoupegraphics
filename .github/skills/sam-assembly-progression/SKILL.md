---
name: sam-assembly-progression
description: Use when extending, explaining, or validating a SAM Coupé Z80 assembly tutorial example in this repository, especially animation, transparency, palettes, keyboard input, or page flipping.
---

# SAM Coupé assembly progression

1. Inspect the requested `.asm`, its immediate predecessor, its included data,
   and the matching section in the blog markdown.
2. Preserve the established progression. Add only the requested concept and do
   not replace the sprite set, palette strategy, paging scheme, or controls
   unless asked.
3. Check pyz80 syntax, include-relative paths, memory range, stack position,
   register/flag assumptions, interrupts, and whether ROM must be paged in
   before `HALT`.
4. Comment non-obvious hardware and control-flow behavior in the existing
   concise assembly style.
5. Build each changed entry point:

   ```powershell
   python .\.vscode\sam_build.py .\assembly\<blog>\<file>.asm --build-only
   ```

6. Run the resulting disk in SimCoupe when behavior changes. Test the specified
   keys and release/retrigger edge cases rather than relying on a successful
   build alone.
7. Keep changes to source, directly related article markdown, and necessary
   data. Do not rewrite WordPress exports or unrelated disk artifacts.

Hardware conventions and project paths are in `.github/copilot-instructions.md`
and `README.md`.
