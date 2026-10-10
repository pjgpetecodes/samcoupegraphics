Welcome to the latest in my series of posts on Graphics with the SAM Coupé.

You can find the other posts in this series here;

- Sam Coupe Assembly Language Programming
- Graphics in Assembly for the SAM Coupé
- Making SAM Coupé Sprites Transparent
- Animating SAM Coupé Sprites
- The GitHub Repo

You can find all the files for the series in my GitHub Repo here;

https://github.com/pjgpetecodes/samcoupegraphics

# Controlling Animation with the Keyboard

In the previous tutorial Dizzy played one nine frame loop, drawn on a hidden screen page so it never flickers. Now we want him to react to us. Hold a key, and he jumps. Let go, and he goes back to idling.

We continue directly from `assembly/blog4/6-4.asm`, and `assembly/blog5/7-1.asm` only adds the new parts. It uses the same frames, so it includes the data file that lives in the `blog4` folder.

## Two Sequences

We split the nine frames in the external file into two tables. A two frame idle, and an eight frame jump;

```z80
Idle_Animation: DEFB    2
                DEFW    Dizzy_System_Interleaved_Image1,Dizzy_System_Interleaved_Image2
;
Jump_Animation: DEFB    8
                DEFW    Dizzy_System_Interleaved_Image1,Dizzy_System_Interleaved_Image3
                DEFW    Dizzy_System_Interleaved_Image4,Dizzy_System_Interleaved_Image5
                DEFW    Dizzy_System_Interleaved_Image6,Dizzy_System_Interleaved_Image7
                DEFW    Dizzy_System_Interleaved_Image8,Dizzy_System_Interleaved_Image9
```

`Update_Animation`, `Draw_Frame` and the page flip don't change at all, as they already work from whichever table `Current_Animation` points at.

## Reading the Keyboard

The ROM routine `JREADKEY` returns with the Z flag set when no key is pressed. We add it to the equates, and call a new `Choose_Animation` from the main loop, between the page flip and `Update_Animation`;

```z80
JREADKEY:       EQU     361             ; ROM key routine: Z is set when no key is pressed
```

```z80
Animation_Loop: HALT                    ; Wait for the next 50 Hz interrupt
                CALL    Show_Pending_Frame ; Swap pages if a new frame is ready
                CALL    Choose_Animation ; Idle or jump, depending on the keyboard
                CALL    Update_Animation ; Change frame when the delay expires
                JR      Animation_Loop  ; Repeat forever
```

```z80
Choose_Animation:
                CALL    JREADKEY        ; Z is set when no key is pressed
                LD      HL,Idle_Animation
                JR      Z,Set_Animation ; No key, so play the idle sequence
                LD      HL,Jump_Animation ; A key is down, so play the jump
```

The ROM is paged in whenever we reach this point, because `Draw_Frame` puts it back before it returns, so the ROM routine is safe to call.

## Not Restarting a Sequence

`Choose_Animation` runs on every interrupt, so while a key is held it asks for the jump 50 times a second. If `Set_Animation` restarted the sequence every time, Dizzy would never get past frame 0. So it now compares the requested table with the one already playing, and returns if they match;

```z80
Set_Animation:  EX      DE,HL           ; DE = requested sequence
                LD      HL,(Current_Animation)
                OR      A               ; Clear the carry flag
                SBC     HL,DE
                RET     Z               ; Do not restart a sequence that is already playing
                EX      DE,HL           ; HL = requested sequence again
                LD      (Current_Animation),HL
```

The rest of `Set_Animation` is as before. At the start of the program we ask for `Idle_Animation`, and hold any key to see him jump.

## The Full Assembly

Full Assembly Listing for 7-1.asm

https://github.com/pjgpetecodes/samcoupegraphics/blob/main/assembly/blog5/7-1.asm

## Building and Running

```powershell
python .\.vscode\sam_build.py .\assembly\blog5\7-1.asm --build-only
```

Then run the disk in SimCoupe and hold a key to see the jump sequence. The demo loops forever, so reset the SAM to stop it.

## Where to Go Next

So far Dizzy has stayed in a fixed position on a blank screen. Next we can look at scenery behind him, which means saving and restoring the background rather than just clearing it, and then moving him around.
