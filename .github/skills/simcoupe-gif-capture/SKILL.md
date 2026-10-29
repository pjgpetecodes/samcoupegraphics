---
name: simcoupe-gif-capture
description: Use when the user asks to run a tutorial disk in SimCoupe, visually verify animation/input behavior, or capture/update a SAM Coupé demo GIF.
---

# SimCoupe visual verification and GIFs

1. Identify the exact disk and the intended behavior/input sequence in the
   source or tutorial. Check whether the disk is current.
2. Build the entry-point source when needed:

   ```powershell
   python .\.vscode\sam_build.py .\assembly\<blog>\<file>.asm --build-only
   ```

3. Inspect `.vscode\capture_gifs.py` for an existing job. Reuse its key sequence
   and output naming; make a narrowly scoped job change if the requested demo is
   not covered.
4. Capture with:

   ```powershell
   python .\.vscode\capture_gifs.py <disk-id>
   ```

5. Verify the generated GIF exists under the correct
   `assembly\<blog>\gifs` folder, has plausible dimensions and frames, and
   actually shows the intended animation/input. Clean up only the SimCoupe
   process started for the capture.
6. Do not edit WordPress HTML or upload the GIF. If a blog draft still has a
   `TODO-*.gif` URL, leave it unless the user specifically asks to change blog
   content or provides the WordPress upload URL.
