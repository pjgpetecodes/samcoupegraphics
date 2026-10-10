# Animating sprites without leaving trails

We can now draw a masked Dizzy frame over an existing background. The next
step is to change frames over time. This raises two separate questions:

1. How do we choose and time animation frames?
2. How do we update the screen without leaving old pixels or showing the
   drawing process?

The examples in this tutorial build on the transparency work in
[`../blog3/5.asm`](../blog3/5.asm) and
[`../blog3/5-2.asm`](../blog3/5-2.asm). The animation programs are
[`6-1.asm`](6-1.asm), [`6-2.asm`](6-2.asm), and [`6-3.asm`](6-3.asm).

## Step 1: alternate two raw frames

[`6-1.asm`](6-1.asm) is the simplest animation example. It alternates Dizzy's
two idle frames. An animation is represented by a table of frame addresses:

```z80
Animation_Frames:
                DEFW    Image1,Image2
Animation_End:
```

`Current_Frame` selects an entry from that table. The update routine increments
the frame number, wraps back to zero at the end, and waits several video
interrupts before drawing again. `HALT` lets the processor wait for an
interrupt between updates; with a delay of five 50 Hz interrupts, the frame
changes about ten times per second.

The source frames in [`../blog3/dizzy.asm`](../blog3/dizzy.asm) are raw pixel
rectangles. The drawing routine copies each complete row with `LDIR`. This is
why this first animation is suitable for a plain background: the frame's
colour-zero pixels are copied too. It can look clean when the sprite is drawn
over a cleared screen, but it would erase scenery inside Dizzy's rectangle.

This version does not visibly flicker in the supplied example. It is also a
useful baseline: frame selection and timing can be tested before adding the
extra work needed for transparency.

## Step 2: restore the background and draw masked frames

[`6-2.asm`](6-2.asm) animates the converted mask/data frames instead. It saves
the original 16-by-32-byte screen rectangle in `Background_Buffer`. Before
each new frame, `Restore_Background` copies those saved bytes back to the
screen. Then `Draw_Masked_Sprite` composites the selected frame with the
restored background.

The frame sequences are tables too. Each starts with a frame count followed by
the addresses of its frames. The idle sequence contains two frames; holding a
key selects the longer jump sequence. Releasing the key returns to the idle
sequence.

Restoring the original rectangle is important. Without it, pixels that belong
to one frame but not the next can remain on screen as trails. The buffer is
tightly packed: 16 bytes for each of 32 lines, or 512 bytes total. The screen
rows are 128 bytes apart, so the restore loop copies 16 bytes and skips the
remaining 112 bytes on each line.

There is a visual trade-off. This version restores and redraws the sprite
directly on the displayed screen. The raw-frame example uses a row copy; the
masked version performs a restore and then combines mask and pixel data byte
by byte. Those writes take longer, and the display can show part of the update
while it is in progress. In this example that appears as flicker or tearing.
Masking fixes the background; it does not by itself make an update invisible.

## Step 3: draw on a hidden screen page

[`6-3.asm`](6-3.asm) keeps the masked rendering and background restoration,
but prepares each frame on a second screen page. The visible page remains
unchanged while the program restores the saved rectangle and draws the new
sprite on the hidden page.

When the frame is ready, the program sets `Frame_Pending`. The main loop waits
with `HALT`, then `Show_Pending_Frame` changes the VMPR screen-page selection
at the next frame interrupt. The completed page becomes visible in one change;
the program then prepares the following frame on the other page.

In broad terms, the flow is:

```text
wait for frame interrupt
show the completed page, if one is ready
restore the background on the hidden page
draw the next masked frame there
mark the page ready
```

The second page needs its own background too. At startup, the program clears
both screen page pairs, saves the background rectangle, and keeps track of
which page is currently displayed. For every new frame it selects the other
page for drawing. This is the additional bookkeeping that makes page flipping
work.

## Compare the three versions

| Example | Sprite data | Where it draws | Main point |
| --- | --- | --- | --- |
| `6-1.asm` | Raw, unmasked frames | Displayed screen | Simple frame selection and timing on a plain background |
| `6-2.asm` | Mask/data frames | Displayed screen | Transparency and background restoration; visible updates can flicker |
| `6-3.asm` | Mask/data frames | Hidden page, then flips | Keeps the background and avoids displaying a partial redraw |

Build an example from the workspace root, for example:

```powershell
python .\.vscode\sam_build.py .\assembly\blog4\6-2.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog4\6-3.asm --build-only
```

Run each disk in SimCoupe to compare them. In `6-2.asm`, hold a key to see the
jump sequence and watch the visible update. In `6-3.asm`, the same input
selects the sequence, but each completed frame is prepared off-screen before
the display switches to it.

## Where to go next

We have progressed from copying raw frames, to restoring a background and
compositing masked pixels, to preparing complete frames on a hidden page.
These examples use fixed sprite positions and pre-drawn frames; movement,
collision handling, and more elaborate scene management can build on the same
ideas.
