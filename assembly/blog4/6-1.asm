;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 5 - Part 1: Animation                     |
; | Filename:   5-1.asm                                                             |
; | Author:     Pete Gallagher - PJG Creations Ltd                                   |
; -----------------------------------------------------------------------------------
;
; Run in MODE 4, as in tutorial 4. Dizzy stays at a fixed position and alternates
; between his two idle frames. There is no keyboard input; reset to stop the demo.
; This version draws sprite data, not compiled sprites.
;
                ORG     0x8000
                DUMP    1,0
                AUTOEXEC
;
; ***********************************************************************************
; *                                    Equates                                      *
; ***********************************************************************************
;
LMPR:           EQU     250             ; Lower Memory Page Register
VMPR:           EQU     252             ; Video Memory Page Register
JCLSBL:         EQU     334             ; ROM clear-screen routine
JPALET:         EQU     340             ; ROM palette routine
;
Sprite_Position:EQU     34 + 100*128     ; X = 68 pixels, Y = 100 lines
Frame_Delay:    EQU     5               ; Hold each frame for five 50 Hz interrupts
Frame_Count:    EQU     (Animation_End-Animation_Frames)/2
;
; ***********************************************************************************
; *                                Application Start                                *
; ***********************************************************************************
;
Start:          DI
                XOR     A
                CALL    JCLSBL          ; Clear while ROM and the BASIC stack are available
                DI
;
                CALL    Set_Palette
                DI
                LD      SP,Stack        ; Keep our stack outside the screen's lower 32 KB
;
                IN      A,(VMPR)
                AND     0b00011110      ; MODE 4 screen memory starts on an even page
                OR      0b00100000      ; Page RAM, rather than ROM0, into section A
                LD      (Screen_Page),A
;
                XOR     A
                LD      (Current_Frame),A
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                CALL    Draw_Animated_Sprite
;
Animation_Loop: HALT                    ; Draw_Image restores ROM and enables interrupts
                CALL    Update_Animation
                JR      Animation_Loop
;
; ***********************************************************************************
; *                                  Set the Palette                                *
; ***********************************************************************************
;
Set_Palette:    LD      HL,Palette
                LD      B,16
                LD      E,0
;
Palette_Loop:   PUSH    HL
                PUSH    BC
                PUSH    DE
                LD      B,(HL)
                LD      C,B             ; Same colour in both flashing phases
                LD      A,0xFF
                CALL    JPALET          ; E = palette index; B and C = SAM colours
                POP     DE
                POP     BC
                POP     HL
                INC     HL
                INC     E
                DJNZ    Palette_Loop
                RET
;
; ***********************************************************************************
; *                                Update the Animation                             *
; ***********************************************************************************
;
Update_Animation:
                LD      A,(Current_Delay)
                DEC     A
                LD      (Current_Delay),A
                RET     NZ              ; Only redraw when this frame's delay expires
;
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                LD      A,(Current_Frame)
                INC     A
                CP      Frame_Count
                JR      C,Store_Frame
                XOR     A               ; After the last frame, return to frame zero
;
Store_Frame:    LD      (Current_Frame),A
                CALL    Draw_Animated_Sprite
                RET
;
; ***********************************************************************************
; *                                Draw the Current Frame                           *
; ***********************************************************************************
;
Draw_Animated_Sprite:
                LD      A,(Current_Frame)
                LD      E,A
                LD      D,0
                LD      HL,Animation_Frames
                ADD     HL,DE
                ADD     HL,DE           ; Each frame pointer occupies two bytes
                LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A             ; HL now points to the selected image header
                LD      DE,Sprite_Position
                CALL    Draw_Image
                RET
;
; HL = image data (width in bytes, height in lines, then pixels).
; DE = destination offset in screen memory.
; Unlike tutorial 4, dizzy.asm has no mask bytes. Copy the entire rectangle,
; including colour-zero pixels, so the previous frame leaves no stray pixels.
; This is suitable for a plain background, not for preserving scenery.
;
Draw_Image:     DI
                IN      A,(LMPR)
                LD      (Restore_LMPR+1),A
                LD      A,(Screen_Page)
                OUT     (LMPR),A
;
                LD      B,0
                LD      C,(HL)          ; Width in bytes (two MODE 4 pixels per byte)
                INC     HL
                LD      A,(HL)          ; Height in screen lines
                INC     HL
;
Draw_Line:      PUSH    BC
                PUSH    DE
                LDIR                    ; Copy one complete row of pixels
                POP     DE
                POP     BC
                PUSH    HL
                LD      HL,128          ; MODE 4 has 128 bytes per screen line
                ADD     HL,DE
                EX      DE,HL
                POP     HL
                DEC     A
                JR      NZ,Draw_Line
;
; ROM's interrupt handler must be visible before EI/HALT, and the stack must
; remain in upper RAM while screen memory occupies sections A and B.
;
Restore_LMPR:   LD      A,0
                OUT     (LMPR),A
                EI
                RET
;
; ***********************************************************************************
; *                               Animation Data and Sprites                         *
; ***********************************************************************************
;
Current_Frame:  DEFB    0
Current_Delay:  DEFB    0
Screen_Page:    DEFB    0
;
; The idle sequence from main.asm. Frame numbers are zero-based.
; Change Frame_Delay to adjust speed, or add pointers here to extend the sequence.
;
Animation_Frames:
                DEFW    Image1,Image2
Animation_End:
;
                INCLUDE "dizzy.asm"
;
Stack_Start:    DEFS    256
Stack:
