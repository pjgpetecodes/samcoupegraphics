;
; -----------------------------------------------------------------------------------
; | Program:    SAM Coupe Sprites Tutorial 6 - Part 2: Masked Animation              |
; | Filename:   blog4\6-2.asm                                                       |
; | Based on:   Tutorial 5's static masked-sprite renderer                           |
; -----------------------------------------------------------------------------------
;
; Hold any key to play the jump sequence; release it to return to the idle sequence.
; The original screen rectangle is saved and restored between frames, so transparent
; pixels preserve the background without leaving pixels from the previous frame.
;
                ORG     0x8000
                DUMP    1,0
                AUTOEXEC
;
; ***********************************************************************************
; *                                    Equates                                      *
; ***********************************************************************************
;
LMPR:           EQU     250
VMPR:           EQU     252
JCLSBL:         EQU     334
JPALET:         EQU     340
JREADKEY:       EQU     361
;
; The 16-byte-wide, 32-line sprite fits in one 16 KB screen-memory page here.
Sprite_Position:EQU     56 + 80*128     ; X = 112 pixels, Y = 80 lines
Frame_Delay:    EQU     5               ; Five 50 Hz interrupts per animation frame
;
; ***********************************************************************************
; *                                Application Start                                *
; ***********************************************************************************
;
Start:          DI
                XOR     A
                CALL    JCLSBL          ; Clear while ROM and BASIC's stack are available
                DI
                CALL    Set_Palette
                DI
;
                LD      SP,Stack
                IN      A,(VMPR)
                AND     0b00011110      ; Keep the screen-memory page
                OR      0b00100000      ; Map RAM, not ROM, into LMPR
                LD      (Screen_Page),A
;
                CALL    Save_Background
                LD      HL,Idle_Animation
                CALL    Set_Animation
;
Animation_Loop: HALT                    ; Drawing restores the ROM page and enables IRQs
                CALL    Choose_Animation
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
                LD      C,B
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
; *                             Choose and Update Animation                         *
; ***********************************************************************************
;
Choose_Animation:
                CALL    JREADKEY
                JR      Z,Choose_Idle
                LD      HL,Jump_Animation
                JR      Set_Animation
;
Choose_Idle:    LD      HL,Idle_Animation
;
Set_Animation:  EX      DE,HL
                LD      HL,(Current_Animation)
                XOR     A
                SBC     HL,DE
                RET     Z               ; Do not restart an unchanged sequence
                EX      DE,HL
                LD      (Current_Animation),HL
                XOR     A
                LD      (Current_Frame),A
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                CALL    Draw_Animated_Sprite
                RET
;
Update_Animation:
                LD      A,(Current_Delay)
                DEC     A
                LD      (Current_Delay),A
                RET     NZ
;
                LD      A,Frame_Delay
                LD      (Current_Delay),A
                LD      HL,(Current_Animation)
                LD      B,(HL)          ; Number of frames in this sequence
                LD      A,(Current_Frame)
                INC     A
                CP      B
                JR      C,Store_Frame
                XOR     A
;
Store_Frame:    LD      (Current_Frame),A
                CALL    Draw_Animated_Sprite
                RET
;
; ***********************************************************************************
; *                            Draw the Current Masked Frame                        *
; ***********************************************************************************
;
Draw_Animated_Sprite:
                CALL    Restore_Background
                LD      A,(Current_Frame)
                LD      E,A
                LD      D,0
                LD      HL,(Current_Animation)
                INC     HL              ; Skip the frame count byte
                ADD     HL,DE
                ADD     HL,DE           ; Each sprite pointer occupies two bytes
                LD      A,(HL)
                INC     HL
                LD      H,(HL)
                LD      L,A
                LD      DE,Sprite_Position
                EX      DE,HL           ; HL = screen address; DE = sprite data
                CALL    Draw_Masked_Sprite
                RET
;
; Restore the saved screen rectangle so changing silhouettes do not leave trails.
;
Restore_Background:
                DI
                IN      A,(LMPR)
                LD      (Restore_Background_LMPR+1),A
                LD      A,(Screen_Page)
                OUT     (LMPR),A
                LD      HL,Background_Buffer
                LD      DE,Sprite_Position
                LD      A,32
;
Restore_Background_Row:
                PUSH    AF
                LD      BC,16
                LDIR
                EX      DE,HL
                LD      BC,112
                ADD     HL,BC
                EX      DE,HL
                POP     AF
                DEC     A
                JR      NZ,Restore_Background_Row
;
Restore_Background_LMPR:
                LD      A,0
                OUT     (LMPR),A
                EI
                RET
;
; Copy the original rectangle into a tightly packed buffer.
;
Save_Background:
                DI
                IN      A,(LMPR)
                LD      (Save_Background_LMPR+1),A
                LD      A,(Screen_Page)
                OUT     (LMPR),A
                LD      HL,Sprite_Position
                LD      DE,Background_Buffer
                LD      A,32
;
Save_Background_Row:
                PUSH    AF
                LD      BC,16
                LDIR
                LD      BC,112
                ADD     HL,BC
                POP     AF
                DEC     A
                JR      NZ,Save_Background_Row
;
Save_Background_LMPR:
                LD      A,0
                OUT     (LMPR),A
                EI
                RET
;
; HL = screen offset; DE = sprite bytes, 32 rows of 16 mask/data pairs.
;
Draw_Masked_Sprite:
                DI
                IN      A,(LMPR)
                LD      (Draw_Masked_Sprite_LMPR+1),A
                LD      A,(Screen_Page)
                OUT     (LMPR),A
                LD      C,32
;
Draw_Masked_Row:
                PUSH    BC
                LD      B,16
;
Draw_Masked_Byte:
                LD      A,(DE)          ; Keep screen bits selected by the mask
                AND     (HL)
                LD      C,A
                INC     DE
                LD      A,(DE)
                OR      C               ; Add the sprite's opaque pixel bits
                LD      (HL),A
                INC     DE
                INC     HL
                DJNZ    Draw_Masked_Byte
                LD      BC,112          ; 16 bytes copied; skip to the next 128-byte line
                ADD     HL,BC
                POP     BC
                DEC     C
                JR      NZ,Draw_Masked_Row
;
Draw_Masked_Sprite_LMPR:
                LD      A,0
                OUT     (LMPR),A
                EI
                RET
;
; ***********************************************************************************
; *                              Animation Data and Sprites                         *
; ***********************************************************************************
;
Current_Animation: DEFW 0
Current_Frame:  DEFB    0
Current_Delay:  DEFB    0
Screen_Page:    DEFB    0
;
Idle_Animation: DEFB    2
                DEFW    Dizzy_Interleaved_Image1,Dizzy_Interleaved_Image2
;
Jump_Animation: DEFB    7
                DEFW    Dizzy_Interleaved_Image1,Dizzy_Interleaved_Image3
                DEFW    Dizzy_Interleaved_Image4,Dizzy_Interleaved_Image5
                DEFW    Dizzy_Interleaved_Image6,Dizzy_Interleaved_Image7
                DEFW    Dizzy_Interleaved_Image8,Dizzy_Interleaved_Image9
;
                INCLUDE "../blog3/dizzy_palette.asm"
                INCLUDE "../blog3/dizzy_interleaved.asm"
;
Background_Buffer: DEFS 512
Stack_Start:    DEFS    256
Stack:
