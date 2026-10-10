;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 6 - Part 3: Animation Tables             |
; | Filename:   blog4\6-3.asm                                                       |
; | Based on:   Tutorial 6 part 2 (blog4\6-2.asm)                                   |
; -----------------------------------------------------------------------------------
;
; Part 2 toggled between two frames with a compare. Here the frame addresses are held
; in a table, and the program steps through all nine frames in the external file
; blog4\dizzy_system_interleaved.asm. Reset to stop the demo.
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
JCLSBL:         EQU     334             ; ROM clear-screen routine
;
Frame_Delay:    EQU     5               ; Hold each frame for five 50 Hz interrupts
;
; ***********************************************************************************
; *                                Application Start                                *
; ***********************************************************************************
;
Start:          DI                      ; Disable interrupts
                LD      (System_SP+1),SP; Save BASIC's stack pointer before paging screen RAM
                CALL    Clear_Screen    ; Clear the screen while the ROM is paged in
                DI                      ; Disable interrupts before paging screen RAM
                LD      SP,0xC000       ; Use a safe stack outside the screen memory
                IN      A,(VMPR)        ; Read the current screen page
                AND     0b00011110      ; Keep only the page number
                OR      0b00100000      ; Map RAM into the lower memory area
                LD      (Screen_Page),A ; Save the page value for drawing
;
                LD      HL,Dizzy_Animation ; Start the animation sequence
                CALL    Set_Animation
;
Animation_Loop: HALT                    ; Wait for the next 50 Hz interrupt
                CALL    Update_Animation ; Change frame when the delay expires
                JR      Animation_Loop  ; Repeat forever
;
Exit:           DI                      ; Not reached while the loop runs, kept from 5.asm
System_SP:      LD      SP,0            ; Restore BASIC's original stack pointer
                EI                      ; Enable interrupts
                RET                     ; Return to BASIC
;
Clear_Screen:   XOR     A               ; Clear the A register to clear the full screen
                CALL    JCLSBL          ; Call the system clear-screen routine
                DI                      ; Disable interrupts before continuing
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                           Choose and Update the Animation                       *
; ***********************************************************************************
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
                XOR     A               ; After the last frame, return to frame zero
;
Store_Frame:    LD      (Current_Frame),A
                ; Fall through to draw the new frame
;
; ***********************************************************************************
; *                                Draw the Current Frame                           *
; ***********************************************************************************
;
Draw_Frame:     DI                      ; Interrupts stay off while screen RAM is paged in
                LD      A,(Screen_Page)
                OUT     (LMPR),A        ; Page the screen RAM into the lower memory area
;
                CALL    Clear_Sprite    ; Remove the previous frame
;
                LD      A,(Current_Frame)
                LD      E,A
                LD      D,0
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count byte
                ADD     HL,DE
                ADD     HL,DE           ; Each frame pointer occupies two bytes
                LD      E,(HL)
                INC     HL
                LD      D,(HL)          ; DE now points to the selected frame data
                LD      HL,0            ; Top-left screen byte, as in Tutorial 5
                CALL    Draw_Sprite     ; Draw the frame using the mask/pixel data
;
                LD      A,0x1F          ; Page ROM 0 back into the lower memory area
                OUT     (LMPR),A        ; The ROM's interrupt handler is needed by HALT
                EI                      ; Enable interrupts
                RET                     ; Return to the caller
;
; ***********************************************************************************
; *                         Clear the Sprite's Screen Rectangle                     *
; ***********************************************************************************
;
Clear_Sprite:   LD      HL,0            ; Top-left screen byte
                LD      C,32            ; Clear all 32 sprite rows
;
Clear_Row:      LD      B,16            ; 16 screen bytes per row
;
Clear_Byte:     LD      (HL),0          ; Colour zero is the blank background
                INC     HL              ; Advance to the next screen byte
                DJNZ    Clear_Byte      ; Continue across the 16-byte row
                LD      DE,112          ; Skip the rest of the 128-byte screen row
                ADD     HL,DE           ; Point to the next screen row
                DEC     C               ; Count down the rows
                JR      NZ,Clear_Row    ; Continue until all 32 rows are cleared
                RET                     ; Return after clearing the rectangle
;
; ***********************************************************************************
; *                               Draw Masked Sprite                                *
; ***********************************************************************************
;
Draw_Sprite:    LD      C,32             ; Process all 32 sprite rows
;
Sprite_Row:     PUSH    BC              ; Preserve row count while B counts bytes
                LD      B,16             ; Process the 16 sprite bytes in this row
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
                LD      BC,112          ; Skip the rest of the 128-byte screen row
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
Screen_Page:    DEFB    0               ; Screen page used while drawing
;
; Each sequence starts with its frame count, followed by the frame addresses.
;
Dizzy_Animation: DEFB   9
                DEFW    Dizzy_System_Interleaved_Image1,Dizzy_System_Interleaved_Image2
                DEFW    Dizzy_System_Interleaved_Image3,Dizzy_System_Interleaved_Image4
                DEFW    Dizzy_System_Interleaved_Image5,Dizzy_System_Interleaved_Image6
                DEFW    Dizzy_System_Interleaved_Image7,Dizzy_System_Interleaved_Image8
                DEFW    Dizzy_System_Interleaved_Image9
;
; The nine interleaved frames come from the Sprite Editor output.
;
                INCLUDE "dizzy_system_interleaved.asm"
