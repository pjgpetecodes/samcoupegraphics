---
name: dizzy-sprite-data
description: Use when inspecting, extracting, converting, cropping, or adding Dizzy sprite frames and palette data for SAM Coupé assembly examples.
---

# Dizzy sprite and palette data

- Inspect the relevant source data and its consumer before changing generated
  sprite includes. Existing tools include `.vscode\generate_dizzy_masked.py`,
  `.vscode\dizzy_to_sprite_project.py`, and `.vscode\extract_tidizzy.py`.
- Preserve interleaved frame layout: each screen byte is represented by a mask
  byte followed by a pixel byte. Transparent pixels retain the existing mask
  semantics and sprite data remains in the established include format.
- In the Sprite Editor, the 16 palette swatches are CLUT indices; sprite and
  mask data stores those indices, not hardware RGB colours. Sprite, mask, and
  interleaved exports do not include the palette. Keep palette JSON and the
  generated CLUT loader/table as separate data.
- Use the editor's actual palette export verbatim when documenting or integrating
  it. Do not invent loader labels, output syntax, palette values, or claims about
  mode/interrupt handling. Raw assembly import starts with the default palette;
  custom palette JSON must be opened separately.
- Confirm frame dimensions, labels, order, colour-index mapping, and all
  animation-table references agree. Blog 5's original system-palette data and
  Blog 6's original-colour/cropped sprite data serve different tutorial goals;
  do not silently swap them.
- Check memory footprint before adding frame data. Blog 6 crops frames to
  13 bytes by 22 rows to fit its selected sequences.
- Prefer the repository conversion/extraction scripts to hand-transcribing
  sprite bytes. Rebuild every program that consumes changed generated data and
  visually inspect its output in SimCoupe.
- Avoid overwriting original disk images or source sprite artifacts; create
  derived outputs alongside the relevant blog assets.
