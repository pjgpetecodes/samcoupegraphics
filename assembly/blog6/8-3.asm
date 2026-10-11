;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 8 - Part 3: Sideways Jumps                   |
; | Filename:   blog6\8-3.asm                                                       |
; | Based on:   Tutorial 8 part 2 (blog6\8-2.asm)                                   |
; -----------------------------------------------------------------------------------
;
; The same keyboard controls Dizzy as before. Keys 1 to 5 change palette entry 0,
; which is the colour of the whole background.
; Space rolls. Hold Z or X to walk left or right. Hold Z or X and press Space
; to jump left or right. A roll or a jump always plays to the end.
;
; ***********************************************************************************
; *                                 Program Setup                                   *
; ***********************************************************************************
;
                ORG     0x8000
                DUMP    1,0
                AUTOEXEC
;
LMPR:           EQU     250             ; Lower Memory Page Register
VMPR:           EQU     252             ; Video Memory Page Register
CLUT:           EQU     248             ; Colour Look Up Table port
JCLSBL:         EQU     334             ; ROM clear-screen routine
;
Frame_Delay:    EQU     5               ; Hold each frame for five 50 Hz interrupts
;
; Dizzy only uses part of each 32x32 frame, so the frames are cropped to save memory.
;
Sprite_Bytes:   EQU     13              ; Screen bytes per cropped row
Sprite_Rows:    EQU     22              ; Rows in a cropped frame
Sprite_Start:   EQU     5*128+1         ; Row 5, byte 1 of the screen, where the crop began
;
; ***********************************************************************************
; *                                Application Start                                *
; ***********************************************************************************
;
Start:          DI                      ; Disable interrupts
                LD      (System_SP+1),SP; Save BASIC's stack pointer before paging screen RAM
                CALL    Clear_Screen    ; Clear the displayed screen while the ROM is paged in
                DI                      ; Disable interrupts before paging screen RAM
                IN      A,(VMPR)        ; Read the current screen page
                AND     0b00011110      ; Keep only the page number
                LD      (Display_Page),A ; This page is the one being displayed
                LD      SP,0xFF00       ; Use a safe stack above the program and its 24 frames
                CALL    Clear_Hidden_Page ; Blank the page we will draw on
;
                LD      HL,Idle_Animation ; Start with the idle sequence
                CALL    Set_Animation   ; Draw the first frame on the hidden page
;
Animation_Loop: HALT                    ; Wait for the next 50 Hz interrupt
                CALL    Set_Palette     ; The ROM interrupt resets the palette, so set ours again
                CALL    Show_Pending_Frame ; Swap pages if a new frame is ready
                CALL    Choose_Background ; Keys 1 to 5 pick the background colour
                CALL    Choose_Animation ; Idle, walk or jump, depending on the keyboard
                CALL    Update_Animation ; Change frame when the delay expires
                JR      Animation_Loop  ; Repeat forever
;
Exit:           DI                      ; Not reached while the loop runs, kept from 5.asm
System_SP:      LD      SP,0            ; Restore BASIC's original stack pointer
                EI                      ; Enable interrupts
                RET                     ; Return to BASIC
;
; ***********************************************************************************
; *                                 Set the Palette                                 *
; ***********************************************************************************
; The CLUT port is 248. The colour number goes in the top byte of the port address,
; so B holds the palette entry and the colour value is written with OUT (C),A.
;
Set_Palette:    LD      HL,Palette      ; Point to our 16 colour values
                LD      BC,CLUT         ; B is palette entry 0, C is the CLUT port
                LD      E,16            ; Sixteen entries to write
;
Palette_Loop:  LD      A,(HL)          ; Read the next colour value
                OUT     (C),A           ; Write it to the palette entry in B
                INC     HL              ; Next colour value
                INC     B               ; Next palette entry
                DEC     E               ; Count down the entries
                JR      NZ,Palette_Loop ; Continue until all 16 are set
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                            Change the Background Colour                         *
; ***********************************************************************************
; Every blank pixel is colour 0, so changing palette entry 0 recolours the whole
; background at once without redrawing anything. We change the entry in our table.
;
Choose_Background:
                LD      BC,0xF7FE       ; Keyboard row 1 2 3 4 5 (port 0xFE)
                IN      A,(C)           ; A bit is 0 when its key is down
                LD      HL,Background_Colours
                LD      B,5             ; Check the five keys
;
Background_Key:
                RRA                     ; Move the next key bit into the carry flag
                JR      NC,Set_Background ; Carry clear means this key is down
                INC     HL              ; Try the next colour
                DJNZ    Background_Key  ; Continue until all five keys are checked
                RET                     ; No key was down
;
Set_Background:
                LD      A,(HL)          ; Read the chosen colour value
                LD      (Palette),A     ; Replace entry 0 in our palette table
                RET                     ; Set_Palette writes it to the CLUT next frame
;
Clear_Screen:   XOR     A               ; Clear the A register to clear the full screen
                CALL    JCLSBL          ; Call the system clear-screen routine
                DI                      ; Disable interrupts before continuing
                RET                     ; Return to the caller
;
; The ROM only clears the displayed screen, so we blank the hidden page ourselves.
; A MODE 4 screen is 24 KB, so we clear the first 0x6000 bytes of the paged-in RAM.
;
Clear_Hidden_Page:
                LD      A,(Display_Page)
                XOR     0b00000100      ; Select the page that is not displayed
                OR      0b00100000      ; Map RAM into the lower memory area
                OUT     (LMPR),A        ; Page the hidden screen RAM in
                LD      HL,0
                LD      DE,1
                LD      BC,0x5FFF
                LD      (HL),0          ; Colour zero, as the ROM clear uses
                LDIR                    ; Fill the rest of the screen with zeros
                LD      A,0x1F          ; Page ROM 0 back into the lower memory area
                OUT     (LMPR),A
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                         Show a Finished Frame (Page Flip)                       *
; ***********************************************************************************
; Only swap pages once a complete frame has been drawn on the hidden page.
;
Show_Pending_Frame:
                LD      A,(Frame_Pending)
                OR      A
                RET     Z               ; Nothing new to show
                XOR     A
                LD      (Frame_Pending),A
                LD      A,(Display_Page)
                XOR     0b00000100      ; The hidden page becomes the displayed page
                LD      (Display_Page),A
                OR      0b01100000      ; Keep MODE 4
                OUT     (VMPR),A        ; Display the finished frame in a single step
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                           Choose and Update the Animation                       *
; ***********************************************************************************
;
Choose_Animation:
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count to the loop flag
                LD      A,(HL)          ; Zero means the sequence only plays once
                OR      A
                RET     Z               ; A roll or jump is playing, so ignore the keyboard
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
;
Choose_Walk:    LD      BC,0xFEFE       ; Keyboard row Shift Z X C V
                IN      A,(C)
                LD      HL,Walk_Left_Animation
                BIT     1,A             ; Bit 1 is Z
                JR      Z,Change_Animation
                LD      HL,Walk_Right_Animation
                BIT     2,A             ; Bit 2 is X
                JR      Z,Change_Animation
                LD      HL,Idle_Animation ; Nothing held, so idle
;
Change_Animation:
                LD      DE,(Current_Animation)
                OR      A               ; Clear the carry flag
                PUSH    HL              ; The compare destroys HL, so keep the new sequence
                SBC     HL,DE
                POP     HL
                RET     Z               ; Already playing it, so carry on
;
Set_Animation:  LD      (Current_Animation),HL
                XOR     A               ; Start from the first frame
                LD      (Current_Frame),A
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                JR      Draw_Frame      ; Draw the first frame straight away
;
Update_Animation:
                LD      A,(Current_Delay) ; Count down the frame delay
                DEC     A
                LD      (Current_Delay),A
                RET     NZ              ; Only redraw when the delay expires
;
                LD      A,Frame_Delay   ; Restart the frame delay
                LD      (Current_Delay),A
                LD      HL,(Current_Animation)
                LD      B,(HL)          ; The first byte is the number of frames
                LD      A,(Current_Frame)
                INC     A
                CP      B
                JR      C,Store_Frame   ; Still inside the sequence
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count to the loop flag
                LD      A,(HL)
                OR      A
                LD      HL,Idle_Animation
                JR      Z,Set_Animation ; A roll or jump has finished, so go back to idle
                XOR     A               ; Walks and idle loop, so return to frame zero
;
Store_Frame:    LD      (Current_Frame),A
                ; Fall through to draw the new frame
;
; ***********************************************************************************
; *                         Draw the Current Frame (Hidden Page)                    *
; ***********************************************************************************
;
Draw_Frame:     DI                      ; Interrupts stay off while screen RAM is paged in
                LD      A,(Display_Page)
                XOR     0b00000100      ; Always draw on the page that is not displayed
                OR      0b00100000      ; Map RAM into the lower memory area
                OUT     (LMPR),A        ; Page the hidden screen RAM into the lower memory area
;
                CALL    Clear_Sprite    ; Remove the old frame left on this page
;
                LD      A,(Current_Frame)
                LD      E,A
                LD      D,0
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count byte
                INC     HL              ; Skip the loop flag
                ADD     HL,DE
                ADD     HL,DE           ; Each frame pointer occupies two bytes
                LD      E,(HL)
                INC     HL
                LD      D,(HL)          ; DE now points to the selected frame data
                LD      HL,Sprite_Start ; Screen byte of the top-left of the cropped sprite
                CALL    Draw_Sprite     ; Draw the frame using the mask/pixel data
;
                LD      A,0x1F          ; Page ROM 0 back into the lower memory area
                OUT     (LMPR),A        ; The ROM's interrupt handler is needed by HALT
                LD      A,1
                LD      (Frame_Pending),A ; Tell the main loop a frame is ready to show
                EI                      ; Enable interrupts
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                         Clear the Sprite's Screen Rectangle                     *
; ***********************************************************************************
;
Clear_Sprite:   LD      HL,Sprite_Start ; Top-left screen byte of the cropped sprite
                LD      C,Sprite_Rows   ; Clear every sprite row
;
Clear_Row:      LD      B,Sprite_Bytes  ; Screen bytes per sprite row
;
Clear_Byte:     LD      (HL),0          ; Colour zero is the blank background
                INC     HL              ; Advance to the next screen byte
                DJNZ    Clear_Byte      ; Continue across the 16-byte row
                LD      DE,128-Sprite_Bytes ; Skip the rest of the 128-byte screen row
                ADD     HL,DE           ; Point to the next screen row
                DEC     C               ; Count down the rows
                JR      NZ,Clear_Row    ; Continue until all 32 rows are cleared
                RET                     ; Return after clearing the rectangle
;
; ***********************************************************************************
; *                               Draw Masked Sprite                                *
; ***********************************************************************************
;
Draw_Sprite:    LD      C,Sprite_Rows    ; Process every sprite row
;
Sprite_Row:     PUSH    BC              ; Preserve row count while B counts bytes
                LD      B,Sprite_Bytes   ; Process the sprite bytes in this row
;
Sprite_Byte:    LD      A,(DE)           ; Read the mask byte
                AND     (HL)            ; Keep screen bits selected by the mask
                LD      C,A             ; Save the masked background byte
                INC     DE              ; Point to the corresponding pixel byte
                LD      A,(DE)           ; Read the cleaned sprite pixels
                OR      C               ; Combine sprite pixels with the background
                LD      (HL),A          ; Write the combined byte to the screen
                INC     DE              ; Point to the next mask/pixel pair
                INC     HL              ; Advance to the next screen byte
                DJNZ    Sprite_Byte     ; Continue across the 16-byte sprite row
                LD      BC,128-Sprite_Bytes ; Skip the rest of the 128-byte screen row
                ADD     HL,BC           ; Point to the next screen row
                POP     BC              ; Restore the sprite row counter
                DEC     C               ; Count down the sprite rows
                JR      NZ,Sprite_Row   ; Continue until all 32 rows are drawn
                RET                     ; Return after drawing the sprite
;
; ***********************************************************************************
; *                               Animation Data                                    *
; ***********************************************************************************
;
Current_Animation: DEFW 0               ; Address of the sequence being played
Current_Frame:  DEFB    0               ; Index into the current sequence
Current_Delay:  DEFB    0               ; Interrupts left before the next frame
Display_Page:   DEFB    0               ; Screen page currently being displayed
Frame_Pending:  DEFB    0               ; Set when the hidden page holds a finished frame
;
; Colours for keys 1 to 5, written to palette entry 0.
;
Background_Colours:
                DEFB    &00, &11, &22, &44, &7F
;
; The 16 colours Dizzy was drawn with. Each value is 7 bits of colour.
; Entry 0 is the blank background, so we make it black.
;
Palette:        DEFB    &00, &7F, &6E, &6A, &2A, &39, &1D, &00
                DEFB    &6C, &42, &24, &7E, &59, &77, &70, &07
;
; Each sequence starts with its frame count and a loop flag (1 loops, 0 plays once),
; followed by the frame addresses.
;
Idle_Animation: DEFB    2,1
                DEFW    TIDizzy_1_Interleaved,TIDizzy_2_Interleaved
;
Roll_Animation: DEFB    8,0
                DEFW    TIDizzy_1_Interleaved,TIDizzy_3_Interleaved
                DEFW    TIDizzy_4_Interleaved,TIDizzy_5_Interleaved
                DEFW    TIDizzy_6_Interleaved,TIDizzy_7_Interleaved
                DEFW    TIDizzy_8_Interleaved,TIDizzy_9_Interleaved
;
Walk_Left_Animation: DEFB 8,1
                DEFW    TIDizzy_10_Interleaved,TIDizzy_11_Interleaved
                DEFW    TIDizzy_12_Interleaved,TIDizzy_13_Interleaved
                DEFW    TIDizzy_14_Interleaved,TIDizzy_15_Interleaved
                DEFW    TIDizzy_16_Interleaved,TIDizzy_17_Interleaved
;
Walk_Right_Animation: DEFB 7,1
                DEFW    TIDizzy_18_Interleaved,TIDizzy_19_Interleaved
                DEFW    TIDizzy_20_Interleaved,TIDizzy_21_Interleaved
                DEFW    TIDizzy_22_Interleaved,TIDizzy_23_Interleaved
                DEFW    TIDizzy_24_Interleaved
;
;
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
;
; The 38 cropped frames come from the Sprite Editor output, and keep the colour numbers they were drawn with.
;
                INCLUDE "tidizzy_cropped.asm"
