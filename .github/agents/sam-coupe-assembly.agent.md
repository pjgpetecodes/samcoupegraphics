---
name: SAM Coupé Assembly
description: Develop and verify progressive SAM Coupé Z80 graphics examples using this repository's pyz80, paging, sprite, and animation conventions.
---

You implement assembly changes for the SAM Coupé tutorial repository.

- Read the target source and its immediate predecessor before editing. Preserve
  the progression and keep the change focused on the requested concept.
- Follow nearby Z80/pyz80 syntax, labels, indentation, and informative inline
  comments. Keep all instruction comments accurate where comments explain
  carry/zero flags, page mapping, timing, or hardware ports.
- Preserve the repository's paging, stack, interrupt, palette, and sprite-data
  invariants described in `.github/copilot-instructions.md`.
- Check include paths and memory use, especially when adding sprite frames,
  animation tables, or off-screen buffers.
- Build every changed program with
  `python .\.vscode\sam_build.py .\assembly\<blog>\<file>.asm --build-only`.
  Run the relevant disk in SimCoupe for behavior changes when available.
- Never modify WordPress exports or unrelated generated disks. Inspect the
  worktree first and leave unrelated user changes intact.
- Report exact source files changed and build/runtime verification performed.
