Welcome to the latest in my series of posts on Graphics with the SAM Coupé.

You can find the other posts in this series here;

- Sam Coupe Assembly Language Programming
- Graphics in Assembly for the SAM Coupé
- Making SAM Coupé Sprites Transparent
- Animating SAM Coupé Sprites
- Controlling SAM Coupé Sprites with the Keyboard
- The GitHub Repo

You can find all the files for the series in my GitHub Repo here;

https://github.com/pjgpetecodes/samcoupegraphics

# Colour Palettes on the SAM Coupé

So far Dizzy has been drawn in whatever colours the SAM gives us when it starts up. That has worked fine, but it means we've been picking colour numbers from the default palette. In this tutorial we take control of the palette, which is one of the best features of the SAM. We'll do it in two steps;

1. Load our own 16 colour palette, and switch to the original Dizzy sprites.
2. Change a palette entry while the program runs, and watch the whole background change.
3. Hold Z or X and press Space to jump sideways, using more frames of Dizzy.

We continue directly from `assembly/blog5/7-3.asm`.

## What is a Palette?

In MODE 4 every pixel is four bits, which gives us the numbers 0 to 15. That number doesn't say what colour the pixel is, though. It is an index into the Colour Look Up Table, or CLUT. The CLUT holds 16 entries, and each entry is a 7 bit value which picks one of the SAM's 128 colours.

This is why the palette is so powerful. If we change an entry in the CLUT, every pixel on the screen which uses that index changes colour at once. We don't need to touch the screen memory at all.

The CLUT is written through port `248` (`0xF8`). The palette entry we want to write, 0 to 15, goes in the top byte of the port address, so we put it in `B`, and then we send the colour value with `OUT (C),A`.

## Step 1: Our Own Palette

### The Dizzy Sprites

In the previous tutorial we used a set of Dizzy frames which had already been recoloured to use only the default colours. This time we use the frames exactly as they came out of the Sprite Editor, from the original Dizzy sprite sheet. These keep the colour numbers Dizzy was originally drawn with, and so they need the palette Dizzy was originally drawn with.

The data is in `assembly/blog6/tidizzy_interleaved.asm`, and it's the first 24 sprites. They are the same frames in the same order as before, so the animation tables only need new label names;

```z80
Idle_Animation: DEFB    2
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved
;
Jump_Animation: DEFB    8
                DEFW    TIDizzy_1_Interleaved,TIDizzy_3_Interleaved
                DEFW    TIDizzy_4_Interleaved,TIDizzy_5_Interleaved
                DEFW    TIDizzy_6_Interleaved,TIDizzy_7_Interleaved
                DEFW    TIDizzy_8_Interleaved,TIDizzy_9_Interleaved
```

The full sprite sheet has 62 sprites, which is 62K of data. That's too much to keep in memory next to our program, so we only include the first 24 for now.

### The Palette Table

Our palette is just 16 bytes of data. Entry 0 is the blank background, and we've made it black, just as the screen was in the previous tutorials;

```z80
Palette:        DEFB    &00, &7F, &6E, &6A, &2A, &39, &1D, &00
                DEFB    &6C, &42, &24, &7E, &59, &77, &70, &07
```

### Writing the Palette

We start with `BC` set to the CLUT port, which means that `B` is palette entry 0. Then we loop through the table, writing a value, and moving on to the next entry by incrementing `B`;

```z80
CLUT:           EQU     248             ; Colour Look Up Table port
```

```z80
Set_Palette:    LD      HL,Palette      ; Point to our 16 colour values
                LD      BC,CLUT         ; B is palette entry 0, C is the CLUT port
                LD      E,16            ; Sixteen entries to write
;
Palette_Loop:   LD      A,(HL)          ; Read the next colour value
                OUT     (C),A           ; Write it to the palette entry in B
                INC     HL              ; Next colour value
                INC     B               ; Next palette entry
                DEC     E               ; Count down the entries
                JR      NZ,Palette_Loop ; Continue until all 16 are set
                RET                     ; Return to the caller
```

### The ROM Resets the Palette

You might expect to call `Set_Palette` once at the start of the program. If we do, the colours appear for a moment and then go back to the default palette!

The reason is that our main loop calls `HALT` to wait for the 50Hz interrupt, and so the ROM's interrupt routine runs fifty times a second. It puts the palette back to how the ROM wants it. We could write our own interrupt handler, but that is a topic for another day. The simple answer is to set our palette again immediately after every `HALT`;

```z80
Animation_Loop: HALT                    ; Wait for the next 50 Hz interrupt
                CALL    Set_Palette     ; The ROM interrupt resets the palette, so set ours again
                CALL    Show_Pending_Frame ; Swap pages if a new frame is ready
                CALL    Choose_Animation ; Idle, walk or jump, depending on the keyboard
                CALL    Update_Animation ; Change frame when the delay expires
                JR      Animation_Loop  ; Repeat forever
```

Sixteen `OUT` instructions is nothing compared to the time we have in each frame.

### The Full Assembly

Full Assembly Listing for 8-1.asm

https://github.com/pjgpetecodes/samcoupegraphics/blob/main/assembly/blog6/8-1.asm

### Download the Disk Image

You can download the disk image for 8-1.asm to run in SimCoupe or on your real SAM [here](https://github.com/pjgpetecodes/samcoupegraphics/raw/refs/heads/main/disks/8-1.dsk);

### The Result

![](https://www.petecodes.co.uk/wp-content/uploads/2026/10/TODO-blog6-step1.gif)

Dizzy is now white with red hands and boots, the colours he was drawn with. Everything else works just as before, with Space to roll, and Z and X to walk.

### See the result in the SAM Coupe Web Emulator

{{emulator:8-1}}

## Step 2: Changing the Palette on the Fly

Now for the fun part. The whole background is colour 0, because that is what we clear the screen to. So if we change palette entry 0, the whole background changes colour without us drawing anything.

We'll let keys 1 to 5 choose the background. We add a table with a colour for each key;

```z80
Background_Colours:
                DEFB    &00, &11, &22, &44, &7F
```

These are black, blue, red, green and white. The number keys are on the keyboard row `0xF7FE`, and bit 0 is key 1, through to bit 4 which is key 5. A key which is down reads as zero.

We shift each bit out in turn with `RRA` into the carry flag, and when we find a key that is down, we use its colour. Otherwise we move on to the next entry in the table;

```z80
Choose_Background:
                LD      BC,0xF7FE       ; Keyboard row 1 2 3 4 5 (port 0xFE)
                IN      A,(C)           ; A bit is 0 when its key is down
                LD      HL,Background_Colours
                LD      B,5             ; Check the five keys
;
Background_Key: RRA                     ; Move the next key bit into the carry flag
                JR      NC,Set_Background ; Carry clear means this key is down
                INC     HL              ; Try the next colour
                DJNZ    Background_Key  ; Continue until all five keys are checked
                RET                     ; No key was down
```

We don't write to the CLUT here. Remember the ROM resets it every frame, so instead we replace the first entry of our own `Palette` table, and `Set_Palette` will write it for us on the next frame;

```z80
Set_Background: LD      A,(HL)          ; Read the chosen colour value
                LD      (Palette),A     ; Replace entry 0 in our palette table
                RET                     ; Set_Palette writes it to the CLUT next frame
```

Then we call it from the main loop;

```z80
                CALL    Choose_Background ; Keys 1 to 5 pick the background colour
                CALL    Choose_Animation ; Idle, walk or jump, depending on the keyboard
```

Notice that Dizzy never flickers when the background changes. We didn't redraw a single pixel, we just told the hardware that colour 0 now means something else.

Dizzy's own black outline is a different palette entry, so it stays black whichever background we pick.

### The Full Assembly

Full Assembly Listing for 8-2.asm

https://github.com/pjgpetecodes/samcoupegraphics/blob/main/assembly/blog6/8-2.asm

### Download the Disk Image

You can download the disk image for 8-2.asm to run in SimCoupe or on your real SAM [here](https://github.com/pjgpetecodes/samcoupegraphics/raw/refs/heads/main/disks/8-2.dsk);

### The Result

![](https://www.petecodes.co.uk/wp-content/uploads/2026/10/TODO-blog6-step2.gif)

Press keys 1 to 5 and the background changes colour instantly.

### See the result in the SAM Coupe Web Emulator

{{emulator:8-2}}

## Step 3: Sideways Jumps

The sprite sheet has more of Dizzy than we've used so far. Frames 26 to 32 are Dizzy jumping to the left, and frames 33 to 39 are Dizzy jumping to the right. We want Space on its own to still roll, but if we're holding Z or X when we press Space, Dizzy should jump in that direction instead.

### Running Out of Memory

There's a problem though. We'd now need 38 frames at 1K each, and our program lives in the top 32K of memory. The bottom half is no use to us, because the screen is paged in there while we draw.

Each frame is 32 by 32 pixels, but Dizzy only fills a small part of it. If we look through all of the frames, he never uses anything outside of screen bytes 1 to 13, or rows 5 to 26. So we crop every frame to a 13 byte by 22 row box. Each frame shrinks from 1024 bytes to 572, and all 38 frames come to around 22K, which fits.

The cropped data is in `assembly/blog6/tidizzy_cropped.asm`, and it replaces the previous data file. We add three constants to describe the box, and use them in `Clear_Sprite` and `Draw_Sprite` instead of the old 32 rows and 16 bytes;

```z80
Sprite_Bytes:   EQU     13              ; Screen bytes per cropped row
Sprite_Rows:    EQU     22              ; Rows in a cropped frame
Sprite_Start:   EQU     5*128+1         ; Row 5, byte 1 of the screen, where the crop began
```

```z80
Draw_Sprite:    LD      C,Sprite_Rows    ; Process every sprite row
;
Sprite_Row:     PUSH    BC              ; Preserve row count while B counts bytes
                LD      B,Sprite_Bytes   ; Process the sprite bytes in this row
```

The skip to the next screen row is now `128-Sprite_Bytes`, and we start drawing at `Sprite_Start` rather than the very top left, so Dizzy stays exactly where he was. As a bonus, we now draw and clear a lot less each frame.

### Sequences That Play Once

Until now the roll was special. `Choose_Animation` and `Update_Animation` both compared the current sequence against `Jump_Animation` to find out if it was the one that plays once. With three sequences like that, we'd be comparing a lot of addresses.

Instead we give every sequence a second header byte. It is 1 if the sequence loops, and 0 if it plays once and then returns to idle. We also rename the old `Jump_Animation` to `Roll_Animation`, to make way for the real jumps;

```z80
Idle_Animation: DEFB    2,1
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved
;
Roll_Animation: DEFB    8,0
```

```z80
Jump_Left_Animation: DEFB 7,0
                DEFW    TIDizzy_26_Interleaved,TIDizzy_27_Interleaved
                DEFW    TIDizzy_28_Interleaved,TIDizzy_29_Interleaved
                DEFW    TIDizzy_30_Interleaved,TIDizzy_31_Interleaved
                DEFW    TIDizzy_32_Interleaved
;
Jump_Right_Animation: DEFB 7,0
                DEFW    TIDizzy_33_Interleaved,TIDizzy_34_Interleaved
                DEFW    TIDizzy_35_Interleaved,TIDizzy_36_Interleaved
                DEFW    TIDizzy_37_Interleaved,TIDizzy_38_Interleaved
                DEFW    TIDizzy_39_Interleaved
```

`Draw_Frame` now skips two header bytes instead of one, and the end of `Update_Animation` just reads the flag;

```z80
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count to the loop flag
                LD      A,(HL)
                OR      A
                LD      HL,Idle_Animation
                JR      Z,Set_Animation ; A roll or jump has finished, so go back to idle
                XOR     A               ; Walks and idle loop, so return to frame zero
```

### Choosing the Jump

`Choose_Animation` uses the same flag to ignore the keyboard while anything that plays once is running. That means letting go of Z or X halfway through a jump won't stop it, Dizzy will always land;

```z80
Choose_Animation:
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count to the loop flag
                LD      A,(HL)          ; Zero means the sequence only plays once
                OR      A
                RET     Z               ; A roll or jump is playing, so ignore the keyboard
```

Then we read the Space row. If Space is up, we carry on to the walking code from before, which now lives in `Choose_Walk`. If Space is down, we look at Z and X to choose which sequence to start;

```z80
                LD      BC,0x7FFE       ; Keyboard row B N M Symbol Space (port 0xFE)
                IN      A,(C)           ; A bit is 0 when its key is down
                BIT     0,A             ; Bit 0 is the Space bar
                JR      NZ,Choose_Walk  ; Space is up, so look at walking
                LD      BC,0xFEFE       ; Keyboard row Shift Z X C V
                IN      A,(C)
                LD      HL,Jump_Left_Animation
                BIT     1,A             ; Bit 1 is Z
                JR      Z,Change_Animation
                LD      HL,Jump_Right_Animation
                BIT     2,A             ; Bit 2 is X
                JR      Z,Change_Animation
                LD      HL,Roll_Animation ; Space on its own is a roll
                JR      Change_Animation
```

If neither Z or X is down, we fall through to the roll, as before.

### The Full Assembly

Full Assembly Listing for 8-3.asm

https://github.com/pjgpetecodes/samcoupegraphics/blob/main/assembly/blog6/8-3.asm

### Download the Disk Image

You can download the disk image for 8-3.asm to run in SimCoupe or on your real SAM [here](https://github.com/pjgpetecodes/samcoupegraphics/raw/refs/heads/main/disks/8-3.dsk);

### The Result

![](https://www.petecodes.co.uk/wp-content/uploads/2026/10/TODO-blog6-step3.gif)

Hold Z or X and press Space and Dizzy jumps in that direction, even if you let go of the keys before he lands. Space on its own still rolls, and keys 1 to 5 still change the background.

### See the result in the SAM Coupe Web Emulator

{{emulator:8-3}}

## Building and Running

```powershell
python .\.vscode\sam_build.py .\assembly\blog6\8-1.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog6\8-2.asm --build-only
python .\.vscode\sam_build.py .\assembly\blog6\8-3.asm --build-only
```

Then run the disks in SimCoupe. The demos loop forever, so reset the SAM to stop them.

## Where to Go Next

The palette gives us lots of tricks, such as flashing colours and fading between scenes, just by changing 16 bytes. We've also nearly run out of memory, even with cropped frames. To use the rest of the sprite sheet, and the SAM's other memory, we'll need to look at memory paging.
