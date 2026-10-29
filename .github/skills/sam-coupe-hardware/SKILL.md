---
name: sam-coupe-hardware
description: Use when reasoning about or changing SAM Coupé Z80 hardware behavior, including memory paging, display pages, MODE 4, CLUT palettes, keyboard ports, interrupts, HALT, or screen layout.
---

# SAM Coupé hardware workflow

1. Identify the exact machine behavior needed by the code or explanation.
2. Check the closest existing example and `simcoupe\Manual.md` first. Do not
   transfer assumptions from another Z80 machine or emulator.
3. Verify the relevant register/port, address bits, flags, and mapping effects.
   Established tutorial conventions include:
   - `LMPR` port 250, `VMPR` port 252, and CLUT port 248.
   - MODE 4 screen clearing spans `0x6000` bytes; these routines use a
     128-byte screen row stride.
   - Keyboard row selection is in the high byte of an input from port `0xFE`;
     pressed keys read as zero. The examples use `0x7FFE` for Space and
     `0xFEFE` for Shift/Z/X/C/V.
   - The CLUT entry is selected by the high byte of the port address. The
     tutorial reapplies the palette after `HALT` because the ROM interrupt
     resets it.
   - Page ROM back in before waiting for the interrupt; do not leave screen RAM
     mapped over the lower address space while the ROM handler must run.
   - Double buffering draws to the hidden page and changes the displayed page
     only after a complete frame is ready.
4. Verify Z80 flag behavior for every condition used in the proposed code. For
   instance, `LD` does not change flags, while `OR`, `BIT`, and arithmetic
   operations do.
5. If behavior is not proven by the repository, run a small focused SimCoupe
   test or consult authoritative hardware documentation and state the basis.
6. Build the affected assembly entry point and update the corresponding article
   explanation. Keep unrelated tutorial progression and WordPress files intact.

These values are project conventions; confirm them against the target example
before assuming they apply to every hardware configuration.
