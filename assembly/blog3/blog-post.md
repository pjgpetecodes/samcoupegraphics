# Sprite masks and interleaved data on the SAM Coupe

At the end of the previous graphics tutorial, our sprite bytes were copied
directly to the screen. We now want to keep the background where Dizzy is
transparent. We will separate his pixel colours from the mask, then combine the
two at runtime into the format the drawing routine expects.

The examples are in [`4.asm`](4.asm), [`4-2.asm`](4-2.asm), [`5.asm`](5.asm),
and [`5-2.asm`](5-2.asm).
They build on the
MODE 4 screen and packed-pixel layout from the
[previous graphics tutorial](https://www.petecodes.co.uk/graphics-in-assembler-for-the-sam-coupe/).
There are two matching paths through these examples: `4.asm` to `5.asm` on a
cleared screen, and `4-2.asm` to `5-2.asm` with stripes behind the sprite.

## Step 1: keep pixels and masks separate

In MODE 4, one byte holds two adjacent pixels. Each pixel is a four-bit colour
index, so a byte such as `0xF0` contains colour `F` followed by colour `0`.
Colour zero is a real screen colour; it does not automatically mean
“transparent.”

[`4.asm`](4.asm) starts with two separate 16-by-32 blocks:
`Sprite1_Pixels` holds Dizzy's colour bytes and `Sprite1_Mask` says which
pixels are transparent. Keeping the blocks separate makes the role of each
one clear. A mask nibble of `F` keeps the matching screen nibble; a mask
nibble of `0` allows the corresponding sprite pixel to replace it.

The program reads the supplied pixel byte and its matching mask byte at
runtime, then writes them into `Sprite1_Interleaved`, mask first and cleaned
pixel data second. The pixel block contains matte pixels with colour index
`F`. If we copied those values straight into the interleaved block, transparent
pixels would still paint the matte colour when the drawing routine ORed them
over the screen.

To prevent that, the interleaving step complements the mask and ANDs it with
the source pixel:

```text
clean_pixel = pixel_data AND NOT mask
```

It stores the original mask and this cleaned pixel byte in the interleaved
block. Drawing then uses:

```text
result = (screen_byte AND mask_byte) OR pixel_byte
```

The mask is ANDed with the existing screen byte, not with the sprite pixel
byte. That preserves the background at transparent pixels and adds only the
opaque sprite colours. The screen is cleared using the existing system
palette, just as in the previous tutorial; no new palette setup is needed for
this masking step. The source bytes are palette indexes, so their displayed
hues come from the system's current palette; this step does not load Dizzy's
original palette.

## Step 2: show the same sprite over stripes

[`4-2.asm`](4-2.asm) is Tutorial 4 with a striped background. Its pixel data,
mask data, interleaving step, and drawing code are the same as `4.asm`; it only
adds code to paint alternating colour-index stripes before drawing Dizzy. The
stripes show through wherever the mask marks a pixel as transparent, while
opaque sprite pixels replace them.

## Step 3: store the same sprite as interleaved data

[`5.asm`](5.asm) continues from Tutorial 4 with the same Dizzy image, mask,
screen position, and masked drawing operation. The difference is how the data
is stored: Tutorial 4 combines separate pixel and mask blocks into an
interleaved buffer at runtime, while Tutorial 5 stores the equivalent
mask/pixel pairs directly in `Sprite1_Interleaved`. The drawing routine can
therefore use the interleaved block immediately, without the runtime
conversion step. The separate pixel and mask values in Tutorial 4 are the
source for these interleaved pairs; transparent matte pixels are already
cleared in the stored pixel bytes.

## Step 4: add stripes to the interleaved version

[`5-2.asm`](5-2.asm) is the striped-background version of Tutorial 5. Its
interleaved Dizzy data and drawing code match `5.asm`; it only adds a call and
routine to paint alternating colour-index stripes across the screen before the
sprite is drawn. Transparent pixels leave the stripes visible, while opaque
pixels replace them. This parallels `4.asm` and `4-2.asm`: each pair has the
same sprite data and masking logic, with stripes as the sole code addition.

Each sprite row stores 16 mask/pixel pairs (32 bytes), for 32 rows total. The
drawing loop processes the 16 screen bytes in a row, then skips the remaining
112 bytes of the 128-byte MODE 4 scanline before drawing the next row.

To build the examples without starting the emulator:

```powershell
python .\.vscode\sam_build.py .\assembly\blog3\4.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog3\4-2.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog3\5.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog3\5-2.asm --build-only
```

Run the four examples in order to compare the data-format change separately
from the background change. There is no animation yet; these examples isolate
how the mask preserves whatever background is already on screen.

## What we have added

We have moved from separate pixel and mask data to an interleaved block, then
compared both formats on a cleared screen and over stripes. The next step is to
animate the frames—and see why drawing a sprite safely is about more than
choosing the right pixel data.
